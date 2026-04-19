local js_fts = { "javascript", "javascriptreact", "typescript", "typescriptreact" }

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo", "ConformFormat" },
    config = function()
      local conform = require("conform")

      conform.setup({
        formatters = {
          prettier = {
            prepend_args = { "--bracket-spacing=false" },
          },
        },
        formatters_by_ft = {
          javascript = { "prettierd", "prettier", stop_after_first = true },
          javascriptreact = { "prettierd", "prettier", stop_after_first = true },
          typescript = { "prettierd", "prettier", stop_after_first = true },
          typescriptreact = { "prettierd", "prettier", stop_after_first = true },
          astro = { "prettierd" },
          css = { "prettierd" },
          html = { "prettierd" },
          json = { "prettierd" },
          svelte = { "prettierd" },
          yaml = { "prettierd" },
          lua = { "stylua" },
        },
        format_on_save = function(bufnr)
          if vim.bo[bufnr].buftype ~= "" then return end
          local is_js = vim.tbl_contains(js_fts, vim.bo[bufnr].filetype)
          return { lsp_format = is_js and "never" or "fallback", timeout_ms = 5000 }
        end,
      })

      vim.api.nvim_create_user_command("ConformFormat", function(opts)
        conform.format({
          formatters = #opts.fargs > 0 and opts.fargs or nil,
          async = true,
          timeout_ms = 30000,
        })
      end, {
        nargs = "*",
        desc = "Format buffer (async). Usage: :ConformFormat [formatter_name ...]",
        complete = function()
          local names = {}
          local seen = {}
          for name, _ in pairs(conform.formatters) do
            if not seen[name] then
              table.insert(names, name)
              seen[name] = true
            end
          end
          for _, info in ipairs(conform.list_all_formatters()) do
            if not seen[info.name] then
              table.insert(names, info.name)
              seen[info.name] = true
            end
          end
          table.sort(names)
          return names
        end,
      })
    end,
  },
}
