return {
  "nvim-telescope/telescope.nvim",
  opts = {
    defaults = {
      file_ignore_patterns = {
        "%.git/",
        "node_modules/",
        "%.DS_Store",
      },
    },
    pickers = {
      find_files = {
        hidden = true,
        -- Show dotfiles but still respect .gitignore
        find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
      },
      live_grep = {
        additional_args = function()
          return { "--hidden" }
        end,
      },
    },
  },
}