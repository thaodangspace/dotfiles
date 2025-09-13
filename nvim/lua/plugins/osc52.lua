return {
  {
    "ojroques/nvim-osc52",
    event = { "TextYankPost", "VeryLazy" },
    config = function()
      require("osc52").setup({
        max_length = 0, -- 0 = không giới hạn (tmux sẽ tự cắt nếu cần)
        silent = true, -- không echo thông báo
        trim = false,
      })

      -- Tự động copy vào clipboard OS qua OSC52 mỗi khi yank
      local function yank_to_clipboard()
        if vim.v.event.operator == "y" and vim.v.event.regname == "" then
          require("osc52").copy_register('"') -- yank mặc định
        end
      end
      vim.api.nvim_create_autocmd("TextYankPost", {
        callback = yank_to_clipboard,
      })

      -- (Tùy chọn) Gán clipboard provider để :yank vào +/* cũng dùng OSC52
      local function copy(lines, _)
        require("osc52").copy(table.concat(lines, "\n"))
      end
      local function paste()
        return { vim.fn.getreg('"'), vim.fn.getregtype('"') }
      end
      vim.g.clipboard = {
        name = "osc52",
        copy = { ["+"] = copy, ["*"] = copy },
        paste = { ["+"] = paste, ["*"] = paste },
      }
    end,
  },
}
