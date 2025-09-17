-- lua/plugins/recent-files.lua
return {
  -- 1) Tắt tabline để bỏ thói quen dùng tab
  {
    "nvim-lua/plenary.nvim", -- đảm bảo có plenary (Telescope đã kéo sẵn)
    init = function()
      vim.opt.showtabline = 0
      vim.keymap.set("n", "<leader>tc", "<cmd>tabclose<cr>", { desc = "Close Tab" })
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    opts = function(_, opts)
      local actions = require("telescope.actions")
      opts = opts or {}
      opts.pickers = opts.pickers or {}

      local oldfiles = opts.pickers.oldfiles or {}
      oldfiles.cwd_only = true
      oldfiles.mappings = oldfiles.mappings or {}
      oldfiles.mappings.i = oldfiles.mappings.i or {}
      oldfiles.mappings.n = oldfiles.mappings.n or {}

      -- Force <CR> to open just the current entry, ignoring multi-select
      oldfiles.mappings.i["<CR>"] = actions.file_edit
      oldfiles.mappings.n["<CR>"] = actions.file_edit

      opts.pickers.oldfiles = oldfiles

      return opts
    end,
    keys = function(_, keys)
      return vim.list_extend(keys or {}, {
        { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files (Telescope)" },
      })
    end,
  },
}
