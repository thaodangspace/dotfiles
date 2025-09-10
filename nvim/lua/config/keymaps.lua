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

-- Search text trong folder chứa file hiện tại
vim.keymap.set("n", "<leader>sf", function()
  local cwd = vim.fn.expand("%:p:h") -- folder của file hiện tại
  builtin.find_files({ cwd = cwd })
end, { desc = "Find files in current file's folder" })

vim.keymap.set("n", "<leader>sg", function()
  local cwd = vim.fn.expand("%:p:h")
  builtin.live_grep({ cwd = cwd })
end, { desc = "Live grep in current file's folder" })
