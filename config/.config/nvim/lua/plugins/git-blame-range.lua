-- git-blame-range — quién tocó estas líneas.
-- Llama al script ~/.local/bin/git-blame-range en una terminal flotante de Snacks.
--
-- Keymaps (todos bajo <leader>g — group "git"):
--   <leader>gB   blame de la línea actual         (normal mode)
--   <leader>gB   blame del rango seleccionado     (visual mode)
--   <leader>gL   git log -L del rango             (visual mode) / línea actual (normal)
--   <leader>gW   blame + log (the "whole story")  (normal/visual)

local function run(file, start_line, end_line, mode)
	local flag = ({ blame = "--blame", log = "--log", both = "--both" })[mode] or "--blame"
	local cmd = string.format(
		"git-blame-range %s %d:%d %s --pager; echo; read -n1 -r -p 'enter para cerrar...'",
		vim.fn.shellescape(file),
		start_line,
		end_line,
		flag
	)
	Snacks.terminal({ "bash", "-c", cmd }, {
		win = { position = "float", height = 0.85, width = 0.9, border = "rounded" },
	})
end

local function current_file()
	local f = vim.fn.expand("%:p")
	if f == "" then
		vim.notify("No hay archivo en el buffer.", vim.log.levels.WARN)
		return nil
	end
	return f
end

local function visual_range()
	-- Funciona desde un mapping visual (`<cmd>`) — usa los marks '< y '>
	local s = vim.fn.line("'<")
	local e = vim.fn.line("'>")
	if s == 0 or e == 0 then
		s = vim.fn.line(".")
		e = s
	end
	if s > e then
		s, e = e, s
	end
	return s, e
end

local function blame_normal(mode)
	local f = current_file()
	if not f then
		return
	end
	local l = vim.fn.line(".")
	run(f, l, l, mode)
end

local function blame_visual(mode)
	local f = current_file()
	if not f then
		return
	end
	local s, e = visual_range()
	run(f, s, e, mode)
end

return {
	{
		"folke/snacks.nvim",
		keys = {
			-- which-key group label
			{ "<leader>g", group = "git" },

			{
				"<leader>gB",
				function()
					blame_normal("blame")
				end,
				mode = "n",
				desc = "Blame line (range)",
			},
			{
				"<leader>gB",
				function()
					blame_visual("blame")
				end,
				mode = "x",
				desc = "Blame selection",
			},

			{
				"<leader>gL",
				function()
					blame_normal("log")
				end,
				mode = "n",
				desc = "Log -L line",
			},
			{
				"<leader>gL",
				function()
					blame_visual("log")
				end,
				mode = "x",
				desc = "Log -L selection",
			},

			{
				"<leader>gW",
				function()
					blame_normal("both")
				end,
				mode = "n",
				desc = "Blame + log line",
			},
			{
				"<leader>gW",
				function()
					blame_visual("both")
				end,
				mode = "x",
				desc = "Blame + log selection",
			},
		},
	},
}
