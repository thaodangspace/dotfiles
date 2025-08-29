return {
  "folke/snacks.nvim",
  opts = {
    explorer = {
      enabled = false,
    },
    terminal = {
      win = {
        border = "rounded",
        position = "float",
      },
    },
  },
  keys = {
    -- Disable the default <leader>e explorer keymap
    { "<leader>e", false },
    {
      "<leader>t",
      function()
        Snacks.terminal.toggle()
      end,
      desc = "Toggle Terminal",
    },
  },
}
