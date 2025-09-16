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
    opts = function(_, opts)
      local util = require("conform.util")

      -- Use prettierd when a project-level Prettier config exists; otherwise fallback to prettier CLI
      opts.formatters = vim.tbl_deep_extend("force", opts.formatters or {}, {
        prettierd = {
          condition = util.root_file(
            ".prettierrc",
            ".prettierrc.json",
            ".prettierrc.json5",
            ".prettierrc.yml",
            ".prettierrc.yaml",
            ".prettierrc.toml",
            ".prettierrc.js",
            ".prettierrc.cjs",
            ".prettierrc.mjs",
            "prettier.config.js",
            "prettier.config.cjs",
            "prettier.config.mjs",
            "prettier.config.ts",
            "package.json"
          ),
        },
      })

      opts.formatters_by_ft = vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
        javascript = { "prettierd", "prettier" },
        javascriptreact = { "prettierd", "prettier" },
        typescript = { "prettierd", "prettier" },
        typescriptreact = { "prettierd", "prettier" },
        vue = { "prettierd", "prettier" },
        html = { "prettierd", "prettier" },
        css = { "prettierd", "prettier" },
      })
    end,
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
