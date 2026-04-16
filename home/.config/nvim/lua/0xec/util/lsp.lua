local M = {}

local function map_lsp(bufnr, lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, {
    buffer = bufnr,
    silent = true,
    desc = desc,
  })
end

function M.on_attach(client, bufnr)
  if client.name == "typescript-tools" then
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end

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

function M.capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok, blink = pcall(require, "blink.cmp")

  if ok then
    return blink.get_lsp_capabilities(capabilities)
  end

  return capabilities
end

return M
