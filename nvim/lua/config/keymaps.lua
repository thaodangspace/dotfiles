-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>fh", "<cmd>Telescope find_files hidden=true<cr>", { desc = "Find Hidden Files" })
-- Copy all file content to system clipboard
vim.keymap.set("n", "<leader>ya", 'gg"+yG', { desc = "Yank all to clipboard" })
-- <leader>yy : Yank current visual selection (or current line) to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>yy", [["+y]], { desc = "Yank to system clipboard" })
