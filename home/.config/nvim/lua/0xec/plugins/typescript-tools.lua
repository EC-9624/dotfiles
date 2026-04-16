local filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
}

return {
  {
    "pmizio/typescript-tools.nvim",
    ft = filetypes,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
      "saghen/blink.cmp",
    },
    config = function()
      local lsp = require("0xec.util.lsp")

      require("typescript-tools").setup({
        capabilities = lsp.capabilities(),
        on_attach = lsp.on_attach,
        settings = {
          separate_diagnostic_server = true,
          publish_diagnostic_on = "insert_leave",
          expose_as_code_action = {
            "fix_all",
            "add_missing_imports",
            "remove_unused_imports",
            "organize_imports",
          },
          tsserver_max_memory = 12288,
          complete_function_calls = true,
          include_completions_with_insert_text = true,
          jsx_close_tag = {
            enable = true,
            filetypes = { "javascriptreact", "typescriptreact" },
          },
          tsserver_file_preferences = {
            includeCompletionsForModuleExports = true,
            includeInlayEnumMemberValueHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayParameterNameHints = "all",
            includeInlayParameterNameHintsWhenArgumentMatchesName = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = true,
            quotePreference = "auto",
          },
        },
      })
    end,
  },
}
