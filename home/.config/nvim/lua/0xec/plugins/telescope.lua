return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
  },
  config = function()
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")
    local action_layout = require("telescope.actions.layout")

    telescope.setup({
      defaults = {
        layout_strategy = "horizontal",
        layout_config = {
          width = 0.95,
          preview_width = 0.45,
        },
        mappings = {
          i = {
            ["<M-p>"] = action_layout.toggle_preview,
          },
          n = {
            ["<M-p>"] = action_layout.toggle_preview,
          },
        },
      },
      pickers = {
        find_files = {
          previewer = false,
          path_display = { "truncate" },
        },
        live_grep = {
          path_display = { "truncate" },
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      },
    })

    pcall(telescope.load_extension, "fzf")

    vim.keymap.set("n", "<leader>ff", function()
      builtin.find_files()
    end, { desc = "Find files" })
    vim.keymap.set("n", "<leader>fg", function()
      builtin.live_grep()
    end, { desc = "Live grep" })
    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find help" })
  end,
}
