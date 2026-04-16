local js_filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
}

local function project_formatters(bufnr)
  local js_tooling = require("0xec.util.js_tooling")
  local project = js_tooling.current_project(bufnr)

  if project.profile == "xo" then
    return { "xo", stop_after_first = true }
  end

  return { "oxfmt", "biome", "prettierd", stop_after_first = true }
end

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    config = function()
      local conform = require("conform")
      local js_tooling = require("0xec.util.js_tooling")

      conform.setup({
        formatters = {
          xo = {
            command = function(_, ctx)
              local project = js_tooling.project_for_path(ctx.filename)
              return js_tooling.find_local_or_global_binary(project.root, "xo")
            end,
            args = function(_, ctx)
              local project = js_tooling.project_for_path(ctx.filename)

              return {
                "--fix",
                "--stdin",
                "--stdin-filename",
                ctx.filename,
                "--cwd=" .. project.root,
              }
            end,
            cwd = function(_, ctx)
              return js_tooling.project_for_path(ctx.filename).root
            end,
            require_cwd = true,
            stdin = true,
            exit_codes = { 0, 1 },
          },
        },
        formatters_by_ft = {
          javascript = project_formatters,
          javascriptreact = project_formatters,
          typescript = project_formatters,
          typescriptreact = project_formatters,
          astro = { "prettierd", stop_after_first = true },
          css = { "prettierd", stop_after_first = true },
          html = { "prettierd", stop_after_first = true },
          json = { "prettierd", stop_after_first = true },
          lua = { "stylua" },
          svelte = { "prettierd", stop_after_first = true },
          yaml = { "prettierd", stop_after_first = true },
        },
        format_on_save = function(bufnr)
          if vim.bo[bufnr].buftype ~= "" then
            return
          end

          local filetype = vim.bo[bufnr].filetype
          local lsp_format = js_filetypes[filetype] and "never" or "fallback"

          return {
            lsp_format = lsp_format,
            timeout_ms = 2000,
          }
        end,
      })
    end,
  },
}
