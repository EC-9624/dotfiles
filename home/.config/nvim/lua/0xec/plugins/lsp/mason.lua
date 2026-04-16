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
  "yamlls",
  "tailwindcss",
  "astro",
}

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
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = servers,
      automatic_enable = servers,
    },
  },
}
