return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "css",
        "html",
        "javascript",
        "markdown",
        "tsx",
        "typescript",
        "vue",
      })
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "prettier", "prettierd", "typescript-language-server", "vtsls" })
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        deno_fmt = {
          append_args = { "--no-config" },
        },
      },
      formatters_by_ft = {
        typescript = { "deno_fmt" },
        javascript = { "deno_fmt" },
        html = { "deno_fmt" },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      -- Provide a stub so LazyVim's typescript extra can safely extend `.settings`
      opts.servers.tsserver = opts.servers.tsserver or { settings = { typescript = {}, javascript = {} } }

      -- Prefer vtsls; enrich with sensible defaults
      opts.servers.vtsls = vim.tbl_deep_extend("force", opts.servers.vtsls or {}, {
        settings = {
          vtsls = {
            enableMoveToFileCodeAction = true,
            autoUseWorkspaceTsdk = true,
          },
        },
      })

      -- Ensure tsserver does not start if vtsls is used
      opts.setup = opts.setup or {}
      opts.setup.tsserver = function()
        return true -- skip default setup (disables tsserver)
      end
    end,
  },
}
