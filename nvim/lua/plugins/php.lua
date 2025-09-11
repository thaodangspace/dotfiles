return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "php", "phpdoc" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        intelephense = {
          filetypes = { "php" },
          settings = {
            intelephense = {
              files = {
                maxSize = 5000000,
              },
              environment = {
                includePaths = { "vendor", "src" },
                phpVersion = "8.4.0",
              },
              stubs = {
                "apache", "bcmath", "bz2", "calendar", "com_dotnet", "Core", "ctype", "curl", "date",
                "dba", "dom", "enchant", "exif", "FFI", "fileinfo", "filter", "fpm", "ftp", "gd",
                "gettext", "gmp", "hash", "iconv", "imap", "intl", "json", "ldap", "libxml", "mbstring",
                "meta", "mysqli", "oci8", "odbc", "openssl", "pcntl", "pcre", "PDO", "pdo_ibm",
                "pdo_mysql", "pdo_pgsql", "pdo_sqlite", "pgsql", "Phar", "posix", "pspell", "readline",
                "Reflection", "session", "shmop", "SimpleXML", "snmp", "soap", "sockets", "sodium",
                "SPL", "sqlite3", "standard", "superglobals", "sysvmsg", "sysvsem", "sysvshm", "tidy",
                "tokenizer", "xml", "xmlreader", "xmlrpc", "xmlwriter", "xsl", "Zend OPcache", "zip", "zlib"
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
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "intelephense", "php-cs-fixer", "pint" })
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        ["php-cs-fixer"] = {
          command = "php-cs-fixer",
          args = {
            "fix",
            "--rules=@PSR12",
            "--using-cache=no",
            "$FILENAME",
          },
          stdin = false,
        },
        pint = {
          command = "pint",
          args = { "$FILENAME" },
          stdin = false,
        },
      },
      formatters_by_ft = {
        php = { "php-cs-fixer" },
      },
    },
  },
}

