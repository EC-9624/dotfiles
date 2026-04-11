return {
	"stevearc/oil.nvim",
  keys = {
    { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
    {
      "<leader>-",
      function()
        require("oil").toggle_float()
      end,
      desc = "Toggle Oil float",
    },
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("oil").setup({
      default_file_explorer = true,
      columns = { "icon" },
      win_options = {
        signcolumn = "no",
        wrap = false,
        cursorcolumn = false,
        foldcolumn = "0",
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = "nvic",
      },
      float = {
        padding = 1,
        border = "rounded",
        win_options = {
          winblend = 0,
        },
      },
      confirmation = {
        border = "rounded",
        win_options = {
          winblend = 0,
        },
      },
      progress = {
        border = "rounded",
        minimized_border = "rounded",
        win_options = {
          winblend = 0,
        },
      },
      keymaps_help = {
        border = "rounded",
      },
      keymaps = {
        ["<C-h>"] = false,
        ["<C-l>"] = false,
        ["<C-c>"] = false,
        ["<C-r>"] = "actions.refresh",
        ["<M-h>"] = "actions.select_split",
        ["q"] = "actions.close",
      },
      delete_to_trash = true,
      view_options = {
        show_hidden = true,
      },
      skip_confirm_for_simple_edits = true,
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "oil",
      callback = function()
        vim.opt_local.cursorline = true
      end,
    })
  end,
}
