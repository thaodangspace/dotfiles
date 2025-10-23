-- lua/plugins/recent-files.lua
return {
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
