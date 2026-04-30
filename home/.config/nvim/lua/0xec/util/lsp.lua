local M = {}

local function map_lsp(bufnr, lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, {
		buffer = bufnr,
		silent = true,
		desc = desc,
	})
end

function M.setup()
	local group = vim.api.nvim_create_augroup("0xec-lsp-attach", { clear = true })

	vim.api.nvim_create_autocmd("LspAttach", {
		group = group,
		callback = function(args)
			local client_id = args.data and args.data.client_id or nil
			local client = client_id and vim.lsp.get_client_by_id(client_id) or nil
			local bufnr = args.buf

			if not client then
				return
			end

			if client.name == "typescript-tools" then
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
			end

			map_lsp(bufnr, "gd", function()
				Snacks.picker.lsp_definitions()
			end, "LSP definition")
			map_lsp(bufnr, "gD", vim.lsp.buf.declaration, "LSP declaration")
			map_lsp(bufnr, "gr", function()
				Snacks.picker.lsp_references()
			end, "LSP references")
			map_lsp(bufnr, "gI", function()
				Snacks.picker.lsp_implementations()
			end, "LSP implementation")
			map_lsp(bufnr, "gy", function()
				Snacks.picker.lsp_type_definitions()
			end, "LSP type definition")
			map_lsp(bufnr, "K", vim.lsp.buf.hover, "LSP hover")
			map_lsp(bufnr, "<leader>rn", vim.lsp.buf.rename, "LSP rename")
			map_lsp(bufnr, "<leader>ca", vim.lsp.buf.code_action, "LSP code action")
			map_lsp(bufnr, "<leader>ds", function()
				require("telescope.builtin").lsp_document_symbols()
			end, "LSP document symbols")
			map_lsp(bufnr, "<leader>ws", function()
				require("telescope.builtin").lsp_dynamic_workspace_symbols()
			end, "LSP workspace symbols")
			map_lsp(bufnr, "[d", function()
				vim.diagnostic.jump({ count = -1, float = true })
			end, "Previous diagnostic")
			map_lsp(bufnr, "]d", function()
				vim.diagnostic.jump({ count = 1, float = true })
			end, "Next diagnostic")
		end,
	})
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
