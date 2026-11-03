#!/usr/bin/env python3
"""Isolated toolkit regressions: no writes to the real HOME or repository index."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ToolkitTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dot toolkit ")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.home = self.base / "home"
        self.repo = self.home / "Code/repo with spaces [x]"
        self.repo.mkdir(parents=True)
        shutil.copytree(ROOT / "bin", self.repo / "bin", ignore=lambda _, names: [n for n in names if n not in {"dot", "sdot"}])
        shutil.copytree(ROOT / "scripts/config", self.repo / "scripts/config")
        self.stubs = self.base / "stubs"
        self.stubs.mkdir()
        self.env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        self.env.pop("DOTFILES_PATH", None)
        self.env.update(HOME=str(self.home), PATH=f"{self.stubs}:/usr/bin:/bin",
                        GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1",
                        LC_ALL="C")
        self.run_cmd(["git", "init", "-q", str(self.repo)])
        self.git("config", "user.name", "Toolkit Test")
        self.git("config", "user.email", "toolkit@example.invalid")
        self.stub("hostname", "printf 'test-host\\n'\n")

    def run_cmd(self, args, *, code=0, input="", env=None, cwd=None):
        result = subprocess.run([str(a) for a in args], env=env or self.env,
                                cwd=cwd or self.home, input=input,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, code,
                         f"{args!r}\nstdout: {result.stdout}\nstderr: {result.stderr}")
        return result

    def git(self, *args, **kwargs):
        return self.run_cmd(["git", "-C", self.repo, *args], **kwargs)

    def config(self, command, *args, **kwargs):
        return self.run_cmd([self.repo / "scripts/config" / command, *args], **kwargs)

    def dot(self, *args, **kwargs):
        return self.run_cmd([self.repo / "bin/dot", *args], **kwargs)

    def write(self, path, contents="original\n", executable=False):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents)
        if executable:
            path.chmod(0o755)
        return path

    def command(self, context, name, body="printf '<%s>\\n' \"$@\"\n"):
        return self.write(self.repo / "scripts" / context / name,
                          "#!/usr/bin/env bash\n##? Example help\n" + body, True)

    def stub(self, name, body):
        return self.write(self.stubs / name, "#!/usr/bin/env bash\n" + body, True)

    def tracked(self, name, contents="original\n"):
        path = self.write(self.repo / "config" / name, contents)
        self.git("add", "--", str(path))
        return path

    def monitors(self):
        return self.tracked(".config/hypr/monitors-local.default.conf")

    def snapshot(self):
        # Include inode metadata and bytes to catch even transient dry-run writes.
        result = {}
        for path in self.home.rglob("*"):
            stat = path.lstat()
            value = os.readlink(path) if path.is_symlink() else path.read_bytes() if path.is_file() else None
            result[str(path)] = (stat.st_mode, stat.st_size, stat.st_mtime_ns, value)
        return result

    def test_context_shortcut_arguments_and_status(self):
        self.command("demo", "args")
        args = ["two words", "", "*", "[abc]", "$(touch nope)", "-x", "a\nb"]
        expected = "".join(f"<{a}>\n" for a in args)
        self.assertEqual(self.dot("demo", "args", *args).stdout, expected)
        self.assertEqual(self.dot("args", *args).stdout, expected)
        self.command("demo", "fail", "exit 23\n")
        self.dot("fail", code=23)
        self.command("else", "args")
        self.assertIn("ambiguous", self.dot("args", code=1).stderr)
        self.dot("missing", code=1)
        self.dot("demo", "missing", code=1)

    def test_literal_names_and_discovery_rules(self):
        self.command("demo", "a.b")
        self.command("demo", "axb")
        self.command("demo", "a[1]")
        self.dot("a.b")
        self.dot("a[1]")
        self.dot("a.*", code=1)
        self.command("c[1]", "literal")
        self.dot("c[1]", "literal")
        self.command("demo", "_private")
        self.command("_private", "secret")
        hidden = self.command("demo", "disabled")
        hidden.chmod(0o644)
        (self.repo / "scripts/demo/symlink").symlink_to("a.b")
        (self.repo / "scripts/demo/directory").mkdir()
        for name in ["_private", "secret", "disabled", "symlink", "directory"]:
            self.dot(name, code=1)
            self.dot("demo", name, code=1)
        self.dot("demo", "../../bin/dot", code=1)

    def test_help_and_missing_fzf(self):
        self.assertIn("Usage:", self.dot("--help").stdout)
        self.assertIn("Usage:", self.dot("config", "adopt", "-h").stdout)
        # A deliberately restricted PATH ensures this works even on machines with fzf.
        minimal = self.base / "minimal"
        minimal.mkdir()
        for name in ["bash", "readlink", "realpath", "find", "sort"]:
            (minimal / name).symlink_to(shutil.which(name))
        env = dict(self.env, PATH=str(minimal))
        self.dot("--help", env=env)
        self.command("demo", "ok", "exit 0\n")
        self.dot("ok", env=env)
        self.assertIn("requires fzf", self.dot(env=env, code=1).stderr)

    def test_picker_arguments_scope_and_cancellation(self):
        self.command("demo", "args")
        self.stub("fzf", 'cat >/dev/null\nprintf "demo/args\\0"\n')
        self.write(self.home / "glob-file")
        result = self.dot("demo", input='* "two words" $(nope)\n')
        self.assertEqual(result.stdout, '<*>\n<"two>\n<words">\n<$(nope)>\n')
        self.command("demo", "failure", "exit 17\n")
        self.stub("fzf", 'cat >/dev/null\nprintf "demo/failure\\0"\n')
        self.dot(code=17)
        self.stub("fzf", "exit 130\n")
        self.dot(code=1)
        self.stub("fzf", 'cat >/dev/null\nprintf "demo/args\\0"\n')
        self.dot("config", code=1)  # out-of-scope selection is rejected

    def test_override_relative_symlinks_and_sdot(self):
        self.command("demo", "hello")
        launcher = self.home / "launch"
        launcher.mkdir()
        (launcher / "first").symlink_to(os.path.relpath(self.repo / "bin/dot", launcher))
        (launcher / "dot").symlink_to("first")
        self.run_cmd([launcher / "dot", "hello", "a b"])
        (launcher / "sdot").symlink_to(os.path.relpath(self.repo / "bin/sdot", launcher))
        self.write(self.home / ".bashrc", "exit 99\n")
        self.run_cmd([launcher / "sdot", "hello", "a b"])
        self.command("demo", "fail", "exit 22\n")
        self.run_cmd([launcher / "sdot", "fail"], code=22)
        other = self.base / "alternate"
        self.write(other / "scripts/demo/override", "#!/usr/bin/env bash\nprintf override", True)
        self.assertEqual(self.dot("override", env=dict(self.env, DOTFILES_PATH=str(other))).stdout, "override")

    def test_round_trip_and_mapping(self):
        home = self.write(self.home / ".config/app/file with spaces")
        self.config("adopt", home)
        expected = self.repo / "config/.config/app/file with spaces"
        self.assertTrue(home.is_symlink())
        self.assertEqual(os.readlink(home), str(expected))
        self.assertEqual(home.read_text(), "original\n")
        self.assertEqual(len(list(home.parent.glob("*.bak.*"))), 1)
        self.assertIn("A  config/.config/app/file with spaces", self.git("status", "--porcelain").stdout.replace('"', ''))
        preview = self.config("adopt-verify", home).stdout
        self.assertIn(f"Repo path:   {expected}", preview)
        self.config("link-config", home, code=2)
        self.config("unadopt", home, code=1)  # staged changes retain Git's protection
        self.assertTrue(home.is_symlink())
        self.git("commit", "-qm", "Adopt file")
        self.config("unadopt", home)
        self.assertFalse(home.is_symlink())
        self.assertEqual(home.read_text(), "original\n")
        self.assertFalse(expected.exists())
        self.assertIn("D  ", self.git("status", "--porcelain").stdout)

    def test_invalid_paths_and_foreign_links(self):
        outside = self.write(self.base / "outside")
        repo_file = self.tracked("app/file")
        for name in ["adopt", "unadopt", "link-config", "adopt-verify"]:
            self.config(name, outside, code=1)
            self.config(name, repo_file, code=1)
            self.config(name, self.home, code=1)
        (self.home / "escape").symlink_to(self.base, target_is_directory=True)
        (self.home / "repo-alias").symlink_to(self.repo, target_is_directory=True)
        self.config("adopt-verify", self.home / "escape/outside", code=1)
        self.config("adopt-verify", self.home / "repo-alias/config/app/file", code=1)
        home = self.home / "app/file"
        home.parent.mkdir()
        for target in [outside, self.base / "missing", self.repo / "config/other"]:
            home.symlink_to(target)
            self.config("unadopt", home, code=1)
            self.config("link-config", "--force", home, code=1)
            self.config("adopt", home, code=1)
            self.assertEqual(os.readlink(home), str(target))
            home.unlink()
        home.symlink_to(os.path.relpath(repo_file, home.parent))
        self.config("link-config", home, code=2)
        self.config("adopt-verify", home)

    def test_link_decline_backup_and_collisions(self):
        self.tracked("app/file", "repo\n")
        home = self.write(self.home / "app/file", "home\n")
        self.config("link-config", home, input="n\n", code=2)
        self.config("link-config", home, input="", code=2)
        self.assertEqual(home.read_text(), "home\n")
        self.assertEqual(list(home.parent.glob("*.bak.*")), [])
        self.stub("date", "printf 'fixed\\n'\n")
        self.write(Path(str(home) + ".bak.fixed"), "old backup\n")
        self.config("link-config", "--force", home)
        self.assertEqual(Path(str(home) + ".bak.fixed").read_text(), "old backup\n")
        self.assertEqual(Path(str(home) + ".bak.fixed.1").read_text(), "home\n")
        self.config("link-config", home, code=2)
        self.config("link-config", home, home, code=1)
        home.unlink()
        home.mkdir()
        self.config("link-config", "--force", home, code=1)

    def test_verify_missing_path_and_source_only_library(self):
        before = self.snapshot()
        self.config("adopt-verify", "~/.config/new/file")
        self.config("adopt-verify", "./new/../relative")
        self.assertEqual(before, self.snapshot())
        self.assertFalse(os.access(self.repo / "scripts/config/_paths.sh", os.X_OK))
        script = 'before=$(set +o); source "$1"; [[ "$before" == "$(set +o)" ]]'
        result = self.run_cmd(["bash", "-c", script, "bash", self.repo / "scripts/config/_paths.sh"])
        self.assertEqual(result.stdout + result.stderr, "")
        self.assertEqual(before, self.snapshot())

    def test_bootstrap_counts_spaces_newlines_and_monitors(self):
        self.monitors()
        self.tracked("app/with space")
        self.tracked("app/with\nnewline")
        self.tracked("cache/__pycache__/ignored")
        result = self.config("bootstrap")
        self.assertIn("linked=4 skipped=0 failed=0", result.stdout)
        result = self.config("bootstrap")
        self.assertIn("linked=0 skipped=4 failed=0", result.stdout)
        path = self.home / "app/with space"
        path.unlink()
        path.write_text("different")
        self.assertIn("linked=0 skipped=4 failed=0", self.config("bootstrap", input="n\n").stdout)
        path.unlink()
        path.symlink_to(self.base / "foreign")
        self.assertIn("linked=0 skipped=3 failed=1", self.config("bootstrap", code=1).stdout)
        path.unlink()
        specific = self.tracked(".config/hypr/monitors-local.test-host.conf")
        self.config("bootstrap")
        monitor = self.home / ".config/hypr/monitors-local.conf"
        self.assertEqual(os.readlink(monitor), str(specific))

    def test_bootstrap_dry_run_and_discovery_errors(self):
        self.monitors()
        self.tracked("app/with spaces")
        before = self.snapshot()
        self.assertIn("would link:", self.config("bootstrap", "--dry-run").stdout)
        self.assertEqual(before, self.snapshot())
        self.stub("git", "printf 'config/partial\\0'\necho discovery-failed >&2\nexit 42\n")
        for name, args in [("bootstrap", []), ("bootstrap", ["--dry-run"]), ("drift", []), ("drift", ["--quiet"])]:
            result = self.config(name, *args, code=1)
            self.assertIn("cannot discover", result.stderr)
            self.assertNotIn("No drift", result.stdout)
            self.assertNotIn("would link", result.stdout)
            self.assertEqual(before, self.snapshot())

    def test_drift_null_delimited_and_find_errors(self):
        for name in ["app/with spaces", "app/with\nnewline"]:
            self.tracked(name)
            self.config("link-config", self.home / name)
        self.assertIn("No drift", self.config("drift").stdout)
        candidate = self.write(self.home / "app/new file")
        self.assertIn(str(candidate), self.config("drift", code=1).stdout)
        self.write(self.repo / ".driftignore", "app/new*\n")
        self.assertEqual(self.config("drift", "--quiet").stdout, "")
        self.stub("find", "exit 44\n")
        self.assertIn("cannot inspect", self.config("drift", code=1).stderr)

    def test_just_recipe_preserves_paths(self):
        if not shutil.which("just"):
            self.skipTest("just is not installed")
        shutil.copy2(ROOT / "Justfile", self.repo / "Justfile")
        home = self.write(self.home / "app/with spaces")
        self.run_cmd(["just", "--justfile", self.repo / "Justfile", "verify", home])
        self.run_cmd(["just", "--justfile", self.repo / "Justfile", "verify"])
        self.run_cmd(["just", "--justfile", self.repo / "Justfile", "adopt", home])
        self.assertTrue(home.is_symlink())
        self.run_cmd(["just", "--justfile", self.repo / "Justfile", "bootstrap", "--dry-run", "--force"])

    def test_monitor_backup_fallback_and_failure(self):
        fallback = self.monitors()
        monitor = self.write(self.home / ".config/hypr/monitors-local.conf", "personal layout\n")
        self.config("bootstrap")
        self.assertEqual(os.readlink(monitor), str(fallback))
        backups = list(monitor.parent.glob("monitors-local.conf.bak.*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "personal layout\n")
        fallback.unlink()
        result = self.config("bootstrap", code=1)
        self.assertIn("failed=2", result.stdout)
        self.assertIn("monitor source not found", result.stderr)

    def test_drift_broken_foreign_links_and_backups(self):
        self.tracked("app/file")
        home = self.home / "app/file"
        home.parent.mkdir()
        home.symlink_to(self.base / "missing")
        self.assertIn("not linked:", self.config("drift", code=1).stdout)
        home.unlink()
        outside = self.write(self.base / "outside")
        home.symlink_to(outside)
        self.assertIn("not linked:", self.config("drift", code=1).stdout)
        home.unlink()
        self.config("link-config", home)
        self.write(home.parent / "file.bak.previous")
        self.assertIn("leftover:", self.config("drift", code=1).stdout)

    def test_dispatch_discovery_error(self):
        self.stub("find", "printf 'demo/partial\\0'\nexit 33\n")
        self.assertIn("cannot discover", self.dot("partial", code=1).stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
