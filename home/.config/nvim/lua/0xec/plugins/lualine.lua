return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status")

    local colors = {
      base = "#191724",
      surface = "#1f1d2e",
      overlay = "#26233a",
      muted = "#6e6a86",
      subtle = "#908caa",
      text = "#e0def4",
      love = "#eb6f92",
      gold = "#f6c177",
      foam = "#9ccfd8",
      iris = "#c4a7e7",
      pine = "#524f67",
      none = "NONE",
    }

    local my_lualine_theme = {
      normal = {
        a = { fg = colors.base, bg = colors.gold, gui = "bold" },
        b = { fg = colors.text, bg = colors.none },
        c = { fg = colors.subtle, bg = colors.none },
      },
      insert = {
        a = { fg = colors.base, bg = colors.foam, gui = "bold" },
        b = { fg = colors.text, bg = colors.none },
        c = { fg = colors.subtle, bg = colors.none },
      },
      visual = {
        a = { fg = colors.base, bg = colors.iris, gui = "bold" },
        b = { fg = colors.text, bg = colors.none },
        c = { fg = colors.subtle, bg = colors.none },
      },
      replace = {
        a = { fg = colors.base, bg = colors.love, gui = "bold" },
        b = { fg = colors.text, bg = colors.none },
        c = { fg = colors.subtle, bg = colors.none },
      },
      command = {
        a = { fg = colors.base, bg = colors.pine, gui = "bold" },
        b = { fg = colors.text, bg = colors.none },
        c = { fg = colors.subtle, bg = colors.none },
      },
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
      path = 0,
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

    lualine.setup({
      icons_enabled = true,
      options = {
        theme = my_lualine_theme,
        globalstatus = true,
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { branch },
        lualine_c = { diff, filename },
        lualine_x = {
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
            color = { fg = "#ff9e64" },
          },
          { "filetype" },
        },
      },
      extensions = { oil_extension },
    })
  end,
}
