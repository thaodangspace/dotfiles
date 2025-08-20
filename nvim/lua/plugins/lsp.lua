return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        intelephense = {
          settings = {
            intelephense = {
              files = {
                maxSize = 5000000,
              },
              environment = {
                includePaths = { "vendor", "src" },
              },
              telemetry = {
                enabled = false,
              },
            },
          },
        },
      },
    },
  },
}
