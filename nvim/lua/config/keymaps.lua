-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- local builtin = require("telescope.builtin")
local ok, builtin = pcall(require, "telescope.builtin")
if not ok then
  return
end

vim.keymap.set("n", "<leader>fh", "<cmd>Telescope find_files hidden=true<cr>", { desc = "Find Hidden Files" })
-- Copy all file content to system clipboard
vim.keymap.set("n", "<leader>ya", 'gg"+yG', { desc = "Yank all to clipboard" })
