return {
  {
    "L3MON4D3/LuaSnip",
    version = "2.*",
    event = "InsertEnter",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local luasnip = require("luasnip")

      luasnip.config.setup({
        history = true,
        delete_check_events = "TextChanged",
      })

      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
