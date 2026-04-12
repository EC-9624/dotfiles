local servers = {
  "bashls",
  "cssls",
  "gopls",
  "html",
  "intelephense",
  "jsonls",
  "lua_ls",
  "svelte",
  "terraformls",
  "ts_ls",
  "yamlls",
}

local function map_lsp(bufnr, lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, {
    buffer = bufnr,
    silent = true,
    desc = desc,
  })
end

local function on_attach(_, bufnr)
  map_lsp(bufnr, "gd", vim.lsp.buf.definition, "LSP definition")
  map_lsp(bufnr, "gr", vim.lsp.buf.references, "LSP references")
  map_lsp(bufnr, "gI", vim.lsp.buf.implementation, "LSP implementation")
  map_lsp(bufnr, "K", vim.lsp.buf.hover, "LSP hover")
  map_lsp(bufnr, "<leader>rn", vim.lsp.buf.rename, "LSP rename")
  map_lsp(bufnr, "<leader>ca", vim.lsp.buf.code_action, "LSP code action")
  map_lsp(bufnr, "[d", function()
    vim.diagnostic.jump({ count = -1, float = true })
  end, "Previous diagnostic")
  map_lsp(bufnr, "]d", function()
    vim.diagnostic.jump({ count = 1, float = true })
  end, "Next diagnostic")
end

local capabilities = vim.lsp.protocol.make_client_capabilities()

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ui = {
        border = "rounded",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.api.nvim_create_user_command("LspInfo", "checkhealth vim.lsp", {
        desc = "Show LSP configuration and client health",
      })

      for _, server in ipairs(servers) do
        vim.lsp.config(server, {
          capabilities = capabilities,
          on_attach = on_attach,
        })
      end

      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        on_attach = on_attach,
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
      })
    end,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = servers,
      automatic_enable = true,
    },
  },
}
