-- lua/plugins/colorscheme.lua
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    -- luôn lấy bản mới để tránh lệch API
    version = false,
    opts = {
      transparent_background = true,
      flavour = "mocha", -- tuỳ chọn: latte, frappe, macchiato, mocha
      integrations = {
        bufferline = true, -- rất quan trọng: bật integration cho bufferline
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

  -- 2) Nói với LazyVim dùng catppuccin làm colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },

  -- 3) (Khuyến nghị) Để bufferline dùng highlight từ Catppuccin
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
