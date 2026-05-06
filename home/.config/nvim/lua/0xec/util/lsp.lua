local M = {}

local function map_lsp(bufnr, lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, {
		buffer = bufnr,
		silent = true,
		desc = desc,
	})
end

local function apply_source_action(kind)
	vim.lsp.buf.code_action({
		apply = true,
		context = {
			only = { kind },
			diagnostics = vim.diagnostic.get(0),
		},
	})
end

local function code_action()
	local line = vim.api.nvim_win_get_cursor(0)[1] - 1
	local diagnostics = vim.diagnostic.get(0, { lnum = line })

	if #diagnostics > 0 then
		vim.lsp.buf.code_action({
			context = {
				only = { "quickfix" },
				diagnostics = diagnostics,
			},
		})
		return
	end

	vim.lsp.buf.code_action()
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

			if client.name == "ts_ls" then
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
			map_lsp(bufnr, "<leader>ca", code_action, "LSP code action")

			if client.name == "ts_ls" then
				map_lsp(bufnr, "<leader>co", function()
					apply_source_action("source.organizeImports.ts")
				end, "TS organize imports")
				map_lsp(bufnr, "<leader>cM", function()
					apply_source_action("source.addMissingImports.ts")
				end, "TS add missing imports")
				map_lsp(bufnr, "<leader>cu", function()
					apply_source_action("source.removeUnused.ts")
				end, "TS remove unused")
				map_lsp(bufnr, "<leader>cf", function()
					apply_source_action("source.fixAll.ts")
				end, "TS fix all")
			end

			if client.name == "oxlint" then
				map_lsp(bufnr, "<leader>cx", function()
					client:exec_cmd({
						title = "Apply Oxlint automatic fixes",
						command = "oxc.fixAll",
						arguments = { { uri = vim.uri_from_bufnr(bufnr) } },
					})
				end, "Oxlint fix all")
			end

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
