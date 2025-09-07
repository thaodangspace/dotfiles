-- ~/.config/nvim/lua/plugins/codeium.lua
return {
  {
    "Exafunction/codeium.vim",
    event = "BufEnter",
    config = function()
      -- map mặc định:
      --   <Tab>       : accept suggestion
      --   <C-]>       : cycle next
      --   <C-[>       : cycle previous
      --   <C-x>       : clear
      --
      -- bạn có thể custom keymap như sau:
      vim.g.codeium_disable_bindings = 1
      vim.keymap.set("i", "<C-g>", function()
        return vim.fn["codeium#Accept"]()
      end, { expr = true })
      vim.keymap.set("i", "<C-;>", function()
        return vim.fn
      end, { expr = true })
      vim.keymap.set("i", "<C-,>", function()
        return vim.fn["codeium#CycleCompletions"](-1)
      end, { expr = true })
      vim.keymap.set("i", "<C-x>", function()
        return vim.fn["codeium#Clear"]()
      end, { expr = true })
    end,
  },
}
