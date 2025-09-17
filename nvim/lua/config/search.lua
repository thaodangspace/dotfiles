-- Enhanced search functionality
local M = {}

-- Function to get word under cursor and start search
local function search_current_word()
  local word = vim.fn.expand("<cword>")
  if word and word ~= "" then
    vim.cmd("/" .. vim.fn.escape(word, "/\\"))
  else
    vim.cmd("/")
  end
end

-- Function for normal search
local function normal_search()
  vim.fn.feedkeys("/", "n")
end

-- Function to search files in project
local function search_files()
  vim.cmd("Telescope find_files")
end

-- Function to grep text in project
local function grep_text()
  vim.cmd("Telescope live_grep")
end

-- Function to grep selected text in project
local function grep_selected()
  vim.cmd('normal! "zy')
  local selected = vim.fn.getreg("z")
  if selected and selected ~= "" then
    vim.cmd("Telescope live_grep default_text=" .. vim.fn.escape(selected, ' "'))
  else
    vim.cmd("Telescope live_grep")
  end
end

-- Function to search current word forward
local function search_word_forward()
  local word = vim.fn.expand("<cword>")
  if word and word ~= "" then
    vim.fn.setreg("/", "\\<" .. word .. "\\>")
    vim.cmd("normal! n")
  end
end

-- Function to search current word backward
local function search_word_backward()
  local word = vim.fn.expand("<cword>")
  if word and word ~= "" then
    vim.fn.setreg("/", "\\<" .. word .. "\\>")
    vim.cmd("normal! N")
  end
end

local function setup_keymaps()
  -- Set up keymaps
  local keymap = vim.keymap.set

  -- Enhanced search with current word
  keymap("n", "/", search_current_word, { desc = "Search with current word" })
  keymap("n", "?", normal_search, { desc = "Normal search" })
  keymap("n", "<S-Space>", search_word_backward, { desc = "Search current word backward" })

  -- Project-wide search
  keymap("n", "<Space><Space>", search_files, { desc = "Search files in project" })
  keymap("n", "<Space>/", grep_text, { desc = "Grep text in project" })
  keymap("v", "<Space>/", grep_selected, { desc = "Grep selected text in project" })

  -- Visual mode search
  keymap("v", "/", "y/\\V<C-R>=escape(@\",'/\\')<CR><CR>", { desc = "Search selected text" })

  -- Alternative mappings
  keymap("n", "<leader>*", search_word_forward, { desc = "Search word forward" })
  keymap("n", "<leader>#", search_word_backward, { desc = "Search word backward" })

  -- Clear search highlighting
  keymap("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlighting" })
end

-- Enhanced search options
local function setup_options()
  vim.opt.ignorecase = true -- Case insensitive search
  vim.opt.smartcase = true -- Case sensitive if uppercase present
  vim.opt.incsearch = true -- Show matches while typing
  vim.opt.hlsearch = true -- Highlight search results
  vim.opt.wrapscan = true -- Wrap around file when searching
end

function M.setup()
  setup_options()
  setup_keymaps()
end

return M
