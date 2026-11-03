#!/usr/bin/env python3
"""Print blockers for your open GitLab MRs (failed pipelines, conflicts, unresolved threads, rebase needed)."""
import json, subprocess
def api(path):
    try: return json.loads(subprocess.run(["glab","api",path],capture_output=True,text=True,timeout=60).stdout or "null")
    except Exception: return None
REASONS = {"conflict":"merge conflicts","need_rebase":"needs rebase","discussions_not_resolved":"unresolved review threads",
           "ci_must_pass":"pipeline must pass","not_approved":"waiting for approval","requested_changes":"changes requested",
           "blocked_status":"blocked by another MR"}
mrs = api("merge_requests?scope=created_by_me&state=opened&per_page=50") or []
for m in mrs:
    if m.get("draft"): continue
    d = api(f"projects/{m['project_id']}/merge_requests/{m['iid']}") or {}
    issues = []
    p = (d.get("head_pipeline") or {}).get("status")
    if p in ("failed","canceled"): issues.append(f"pipeline {p}")
    if d.get("has_conflicts"): issues.append("merge conflicts")
    r = REASONS.get(d.get("detailed_merge_status",""))
    if r and r not in issues and not (r=="pipeline must pass" and p in ("failed","canceled")): issues.append(r)
    if issues: print(f"• MR {m['references']['full']} {m['title']}: {', '.join(issues)}")
