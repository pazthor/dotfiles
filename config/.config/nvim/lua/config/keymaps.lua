-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here





-- custom functions
-- edit sudo files inside nvim
-- ~/.config/nvim/lua/config/keymaps.lua

vim.api.nvim_create_user_command("Wsudo", function()
  vim.cmd("write !sudo tee % >/dev/null")
  vim.cmd("edit!")
end, {
  desc = "Write current file with sudo",
})
