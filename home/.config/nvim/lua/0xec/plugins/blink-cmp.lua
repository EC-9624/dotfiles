return {
  "saghen/blink.cmp",
  version = "1.*",
  event = "InsertEnter",
  dependencies = {
    "L3MON4D3/LuaSnip",
    "rafamadriz/friendly-snippets",
  },
  opts = {
    keymap = {
      preset = "default",
      ["<Tab>"] = {
        function(cmp)
          if cmp.snippet_active() then
            return cmp.snippet_forward()
          end

          return cmp.select_next()
        end,
        "fallback",
      },
      ["<S-Tab>"] = {
        function(cmp)
          if cmp.snippet_active() then
            return cmp.snippet_backward()
          end

          return cmp.select_prev()
        end,
        "fallback",
      },
    },
    appearance = {
      nerd_font_variant = "mono",
    },
    snippets = {
      preset = "luasnip",
    },
    signature = {
      enabled = true,
      window = {
        border = "rounded",
      },
    },
    completion = {
      menu = {
        auto_show = true,
        border = "rounded",
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
        window = {
          border = "rounded",
        },
      },
      ghost_text = {
        enabled = true,
      },
      list = {
        selection = {
          preselect = true,
        },
      },
      accept = {
        auto_brackets = {
          enabled = true,
        },
      },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
      providers = {
        lsp = {
          score_offset = 20,
        },
        snippets = {
          score_offset = 10,
        },
        buffer = {
          min_keyword_length = 3,
        },
      },
    },
  },
}
