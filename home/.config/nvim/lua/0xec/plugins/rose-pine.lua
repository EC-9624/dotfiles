return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        variant = "moon",
        dark_variant = "moon",
        extend_background_behind_borders = true,
        styles = {
          transparency = true,
        },
        highlight_groups = {
          TelescopePromptBorder = { fg = "muted", bg = "none" },
          TelescopeResultsBorder = { fg = "muted", bg = "none" },
          TelescopePreviewBorder = { fg = "muted", bg = "none" },
          TelescopePromptTitle = { fg = "base", bg = "iris", bold = true },
          TelescopeResultsTitle = { fg = "base", bg = "foam", bold = true },
          TelescopePreviewTitle = { fg = "base", bg = "gold", bold = true },
          TelescopeSelection = { fg = "text", bg = "overlay", bold = true },
          TelescopeSelectionCaret = { fg = "rose", bg = "overlay" },

          OilFile = { fg = "text" },
          OilLink = { fg = "iris" },
          OilOrphanLink = { fg = "love" },
          OilLinkTarget = { fg = "muted" },
          OilSocket = { fg = "pine" },
        },
      })

      vim.cmd.colorscheme("rose-pine-moon")
    end,
  },
}
