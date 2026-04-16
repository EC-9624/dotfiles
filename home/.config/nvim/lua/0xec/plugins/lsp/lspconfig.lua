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

      vim.diagnostic.config({
        float = {
          border = "rounded",
        },
      })

      vim.api.nvim_create_user_command("LspInfo", "checkhealth vim.lsp", {
        desc = "Alias to :checkhealth vim.lsp",
      })

      vim.api.nvim_create_user_command("LspLog", function()
        vim.cmd("tabnew " .. vim.lsp.log.get_filename())
      end, {
        desc = "Open the Nvim LSP client log",
      })

      vim.api.nvim_create_user_command("LspBuf", function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
          print("No LSP clients attached to current buffer")
          return
        end
        for _, c in ipairs(clients) do
          print(("• %s  (id=%d)  root=%s"):format(c.name, c.id, c.root_dir or "—"))
        end
      end, {
        desc = "Show LSP clients attached to current buffer",
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
