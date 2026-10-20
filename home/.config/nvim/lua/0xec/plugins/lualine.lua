return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = function()
		local lazy_status = require("lazy.status")
		local colors = require("0xec.theme").colors

		local function mode(background)
			return {
				a = { fg = colors.base, bg = background, gui = "bold" },
				b = { fg = colors.text, bg = colors.none },
				c = { fg = colors.subtle, bg = colors.none },
			}
		end

		local my_lualine_theme = {
			normal = mode(colors.gold),
			insert = mode(colors.foam),
			visual = mode(colors.iris),
			replace = mode(colors.love),
			command = mode(colors.highlight_high),
			inactive = {
				a = { fg = colors.muted, bg = colors.none, gui = "bold" },
				b = { fg = colors.muted, bg = colors.none },
				c = { fg = colors.muted, bg = colors.none },
			},
		}

		local diff = {
			"diff",
			colored = true,
			symbols = { added = " ", modified = " ", removed = " " },
			diff_color = {
				added = { fg = colors.foam },
				modified = { fg = colors.gold },
				removed = { fg = colors.love },
			},
		}

		local filename = {
			"filename",
			file_status = true,
			path = 1,
			shorting_target = 100,
		}

		local branch = {
			"branch",
			icon = { "", color = { fg = colors.foam } },
			color = { fg = colors.text, bg = colors.overlay },
		}

		local oil_extension = {
			sections = {
				lualine_a = {
					{
						function()
							return "Oil"
						end,
						color = { fg = colors.base, bg = colors.foam, gui = "bold" },
					},
				},
				lualine_b = {
					{
						function()
							local oil = require("oil")
							local dir = oil.get_current_dir()

							if not dir then
								return ""
							end

							return vim.fn.fnamemodify(dir, ":~")
						end,
						color = { fg = colors.text, bg = colors.none },
					},
				},
				lualine_c = {
					{
						function()
							return "Browse files"
						end,
						color = { fg = colors.subtle, bg = colors.none },
					},
				},
			},
			filetypes = { "oil" },
		}

		return {
			icons_enabled = true,
			options = {
				theme = my_lualine_theme,
				globalstatus = true,
				component_separators = { left = "│", right = "│" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { branch, diff },
				lualine_c = {
					filename,
					{
						"diagnostics",
						sources = { "nvim_diagnostic" },
						sections = { "error", "warn", "info", "hint" },
						symbols = { error = " ", warn = " ", info = " ", hint = "󰌶 " },
						diagnostics_color = {
							error = { fg = colors.love },
							warn = { fg = colors.gold },
							info = { fg = colors.foam },
							hint = { fg = colors.iris },
						},
					},
				},
				lualine_x = {
					{
						lazy_status.updates,
						cond = lazy_status.has_updates,
						color = { fg = colors.gold },
					},
					"lsp_status",
					{
						"filetype",
						fmt = function(ft)
							local map = {
								typescriptreact = "tsx",
								javascriptreact = "jsx",
							}
							return map[ft] or ft
						end,
					},
				},
				lualine_y = { "encoding", { "fileformat", icons_enabled = false } },
				lualine_z = { "progress", "location" },
			},
			extensions = { oil_extension },
		}
	end,
}
