-- SSH remote log filtering — runs log-filter locally against a remote copy
-- No server-side script required. Only needs: ssh access + cat/tail on the server.
--
-- Configuration — edit defaults here or override with env vars:
--   export SSH_LOG_HOST="deploy@my-server.com"
--   export SSH_LOG_PATH="/var/www/myapp/storage/logs/laravel.log"
--   export SSH_LOG_LOCAL="~/logs/remote-laravel.log"   (persistent copy destination)
--
-- Recommended ~/.ssh/config entry (prevents re-auth between terminal opens):
--   Host your-server.example.com
--     User deploy
--     IdentityFile ~/.ssh/id_ed25519
--     ControlMaster auto
--     ControlPath ~/.ssh/cm-%r@%h:%p
--     ControlPersist 10m

-- local SSH_HOST = os.getenv("SSH_LOG_HOST") or "deploy@your-server.example.com"
-- local LOG_PATH = os.getenv("SSH_LOG_PATH") or "/var/www/app/storage/logs/laravel.log"
-- local LOCAL_COPY = os.getenv("SSH_LOG_LOCAL") or (vim.fn.expand("~") .. "/logs/remote-laravel.log")
local SSH_HOST = os.getenv("SSH_LOG_HOST") or "PROD"
local LOG_PATH = os.getenv("SSH_LOG_PATH") or ""
local LOCAL_COPY = os.getenv("SSH_LOG_LOCAL") or (vim.fn.expand("~") .. "PROD.log")

-- Browse mode: copies remote log to a temp file, opens local log-filter on it
local function ssh_browse(level)
	local tmp = vim.fn.tempname() .. ".log"
	local fetch = string.format("ssh %s 'cat %s' > %s", SSH_HOST, LOG_PATH, tmp)
	local filter = level and ("-l " .. level) or ""
	local open = string.format("log-filter %s %s", filter, tmp)
	Snacks.terminal({ "bash", "-c", fetch .. " && " .. open }, {
		win = { position = "float", height = 0.85, width = 0.9 },
	})
end

-- Follow mode: streams tail -f from the server with inline ANSI coloring
local function ssh_follow(level)
	local tail = "tail -f " .. LOG_PATH
	if level then
		tail = tail .. " | grep --line-buffered -i " .. level
	end
	-- Color awk runs on the server side (only uses awk — no extra deps)
	local color = [[awk '/\.(ERROR|CRITICAL|ALERT|EMERGENCY):/{printf "\033[31m%s\033[0m\n",$0;next}]]
		.. [[/\.WARNING:/{printf "\033[33m%s\033[0m\n",$0;next}]]
		.. [[/\.INFO:/{printf "\033[32m%s\033[0m\n",$0;next}]]
		.. [[/\.DEBUG:/{printf "\033[36m%s\033[0m\n",$0;next}{print}']]
	local remote_cmd = tail .. " | " .. color
	Snacks.terminal({ "ssh", SSH_HOST, remote_cmd }, {
		win = { position = "float", height = 0.85, width = 0.9 },
	})
end

-- Copy remote log to a persistent local path, then open it as a buffer
local function ssh_copy_local()
	local dir = vim.fn.fnamemodify(LOCAL_COPY, ":h")
	vim.fn.mkdir(dir, "p")
	vim.notify("Copying remote log to " .. LOCAL_COPY .. " …", vim.log.levels.INFO)
	vim.fn.jobstart({ "scp", SSH_HOST .. ":" .. LOG_PATH, LOCAL_COPY }, {
		on_exit = function(_, code)
			vim.schedule(function()
				if code == 0 then
					vim.notify("Done → " .. LOCAL_COPY, vim.log.levels.INFO)
					vim.cmd("edit " .. vim.fn.fnameescape(LOCAL_COPY))
				else
					vim.notify("scp failed (exit " .. code .. ")", vim.log.levels.ERROR)
				end
			end)
		end,
	})
end

return {
	-- Syntax highlighting for any .log buffer (local or copied from server)
	{
		"fei6409/log-highlight.nvim",
		event = "BufRead *.log",
		opts = {},
	},

	-- Extend snacks.nvim (already managed by LazyVim) with SSH log keybindings
	{
		"folke/snacks.nvim",
		keys = {
			{
				"<leader>ls",
				function()
					ssh_browse()
				end,
				desc = "SSH Log: Browse remote laravel.log",
			},
			{
				"<leader>lS",
				function()
					ssh_follow()
				end,
				desc = "SSH Log: Follow remote laravel.log",
			},
			{
				"<leader>lE",
				function()
					ssh_follow("ERROR")
				end,
				desc = "SSH Log: Follow remote ERRORs",
			},
			{
				"<leader>lc",
				function()
					ssh_copy_local()
				end,
				desc = "SSH Log: Copy remote log to local file",
			},
			{
				"<leader>lF",
				function()
					vim.ui.input({ prompt = "Log level (ERROR/WARNING/INFO/DEBUG): " }, function(lvl)
						if lvl and lvl ~= "" then
							ssh_browse(lvl)
						end
					end)
				end,
				desc = "SSH Log: Browse remote log filtered by level",
			},
		},
	},
}
