-- lua/plugins/colorscheme.lua
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    version = false,
    opts = {
      transparent_background = true,
      flavour = "mocha",
      integrations = {
        bufferline = true,
        treesitter = true,
        cmp = true,
        gitsigns = true,
        telescope = { enabled = true },
        which_key = true,
        mason = true,
        noice = true,
        notify = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },

  {
    "akinsho/bufferline.nvim",
    optional = true,
    opts = function(_, opts)
      local catppuccin_hl = require("catppuccin.groups.integrations.bufferline").get()
      opts = opts or {}
      opts.highlights = catppuccin_hl
      return opts
    end,
  },
}
