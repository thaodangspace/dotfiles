return {
  "folke/snacks.nvim",
  opts = {
    explorer = {
      enabled = false,
    },
    terminal = {
      win = {
        border = "rounded",
      },
    },
  },
  keys = {
    -- Disable the default <leader>e explorer keymap
    { "<leader>e", false },
  },
}
