local servers = {
  bashls = {},
  cssls = {},
  gopls = {},
  html = {},
  intelephense = {},
  jsonls = {},
  lua_ls = {
    settings = {
      Lua = {
        diagnostics = {
          globals = { "vim" },
        },
        workspace = {
          checkThirdParty = false,
          library = vim.api.nvim_get_runtime_file("", true),
        },
      },
    },
  },
  svelte = {},
  terraformls = {},
  yamlls = {},
  tailwindcss = {
    filetypes = {
      "astro",
      "css",
      "html",
      "javascript",
      "javascriptreact",
      "svelte",
      "typescript",
      "typescriptreact",
    },
  },
  astro = {},
}

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "saghen/blink.cmp",
    },
    config = function()
      local lsp = require("0xec.util.lsp")

      vim.api.nvim_create_user_command("LspInfo", "checkhealth vim.lsp", {
        desc = "Show LSP configuration and client health",
      })

      vim.diagnostic.config({
        float = {
          border = "rounded",
        },
      })

      for server, config in pairs(servers) do
        vim.lsp.config(server, vim.tbl_deep_extend("force", {
          capabilities = lsp.capabilities(),
          on_attach = lsp.on_attach,
        }, config))
      end
    end,
  },
}
