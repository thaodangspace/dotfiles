return {
  "folke/snacks.nvim",
  opts = {
    terminal = {
      border = "double",
      win = {
        position = "float",
      },
    },
  },
  keys = {
    {
      "<leader>t",
      function()
        Snacks.terminal.toggle()
      end,
      desc = "Toggle Terminal",
    },
  },
}
