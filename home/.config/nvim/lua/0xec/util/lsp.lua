local M = {}

local function map_lsp(bufnr, lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, {
		buffer = bufnr,
		silent = true,
		desc = desc,
	})
end

local ts_clients = {
	ts_ls = true,
	effect_tsgo = true,
}

--- ts_ls names its source actions `source.*.ts`; effect_tsgo (TypeScript-Go) uses the
--- unprefixed kinds. Pass both so the mapping works with whichever client owns the buffer.
local function apply_source_action(kinds)
	vim.lsp.buf.code_action({
		apply = true,
		context = {
			only = kinds,
		},
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

			if ts_clients[client.name] then
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
			end

			map_lsp(bufnr, "gd", function()
				Snacks.picker.lsp_definitions()
			end, "Go to definition")
			map_lsp(bufnr, "gD", vim.lsp.buf.declaration, "Go to declaration")
			map_lsp(bufnr, "gr", function()
				Snacks.picker.lsp_references()
			end, "Go to references")
			map_lsp(bufnr, "gI", function()
				Snacks.picker.lsp_implementations()
			end, "Go to implementation")
			map_lsp(bufnr, "gy", function()
				Snacks.picker.lsp_type_definitions()
			end, "Go to type definition")
			map_lsp(bufnr, "K", function()
				vim.lsp.buf.hover({ border = "none" })
			end, "Show hover documentation")
			map_lsp(bufnr, "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
			map_lsp(bufnr, "<leader>ca", vim.lsp.buf.code_action, "Code actions")

			if ts_clients[client.name] then
				map_lsp(bufnr, "<leader>co", function()
					apply_source_action({ "source.organizeImports.ts", "source.organizeImports" })
				end, "Code: organize imports (TypeScript)")
				map_lsp(bufnr, "<leader>cu", function()
					apply_source_action({ "source.removeUnused.ts", "source.removeUnusedImports" })
				end, "Code: remove unused (TypeScript)")
				map_lsp(bufnr, "<leader>cf", function()
					apply_source_action({ "source.fixAll.ts", "source.fixAll" })
				end, "Code: fix all (TypeScript)")
			end

			-- effect_tsgo has no add-missing-imports source action.
			if client.name == "ts_ls" then
				map_lsp(bufnr, "<leader>cM", function()
					apply_source_action({ "source.addMissingImports.ts" })
				end, "Code: add missing imports (TypeScript)")
			end

			if client.name == "oxlint" then
				map_lsp(bufnr, "<leader>cx", function()
					client:exec_cmd({
						title = "Apply Oxlint automatic fixes",
						command = "oxc.fixAll",
						arguments = { { uri = vim.uri_from_bufnr(bufnr) } },
					})
				end, "Code: fix all (Oxlint)")
			end

			map_lsp(bufnr, "<leader>ds", function()
				Snacks.picker.lsp_symbols()
			end, "Document symbols")
			map_lsp(bufnr, "<leader>ws", function()
				Snacks.picker.lsp_workspace_symbols()
			end, "Workspace symbols")
			map_lsp(bufnr, "[d", function()
				vim.diagnostic.jump({ count = -1, float = true })
			end, "Previous diagnostic and details")
			map_lsp(bufnr, "]d", function()
				vim.diagnostic.jump({ count = 1, float = true })
			end, "Next diagnostic and details")
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
