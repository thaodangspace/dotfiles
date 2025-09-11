return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      -- Enhanced telescope search with current word
      {
        "<leader>sw",
        function()
          local word = vim.fn.expand("<cword>")
          require("telescope.builtin").grep_string({ search = word })
        end,
        desc = "Search current word (Telescope)",
      },
      {
        "<leader>sg",
        function()
          local word = vim.fn.expand("<cword>")
          require("telescope.builtin").live_grep({ default_text = word })
        end,
        desc = "Live grep with current word",
      },
      -- Quick file search with current word as default
      {
        "<leader>sf",
        function()
          local word = vim.fn.expand("<cword>")
          require("telescope.builtin").find_files({ default_text = word })
        end,
        desc = "Find files with current word",
      },
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        search = {
          enabled = true,
          highlight = { backdrop = true },
          jump = { history = true, register = true, nohlsearch = true },
        },
        char = {
          enabled = true,
          jump_labels = true,
        },
      },
    },
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash jump",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash treesitter",
      },
    },
  },
}