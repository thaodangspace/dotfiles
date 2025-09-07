-- ~/.config/nvim/lua/plugins/codeium.lua
return {
  {
    "Exafunction/codeium.vim",
    event = "BufEnter",
    config = function()
      --   <Tab>       : accept suggestion
      --   <C-]>       : cycle next
      --   <C-[>       : cycle previous
      --   <C-x>       : clear
      --
    end,
  },
}
