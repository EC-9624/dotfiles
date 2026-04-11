return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  keys = {
    {
      "<leader>ff",
      function()
        require("telescope.builtin").find_files()
      end,
      desc = "Find files",
    },
    {
      "<leader>fg",
      function()
        require("telescope.builtin").live_grep()
      end,
      desc = "Live grep",
    },
    {
      "<leader>fd",
      function()
        require("telescope.builtin").find_files({
          find_command = { "rg", "--files", "--hidden", "-g", "!.git" },
        })
      end,
      desc = "Find dotfiles",
    },
    {
      "<leader>sd",
      function()
        require("telescope.builtin").live_grep({
          additional_args = function()
            return { "--hidden", "-g", "!.git" }
          end,
        })
      end,
      desc = "Live grep dotfiles",
    },
    {
      "<leader>fb",
      function()
        require("telescope.builtin").buffers()
      end,
      desc = "Find buffers",
    },
    {
      "<leader>fh",
      function()
        require("telescope.builtin").help_tags()
      end,
      desc = "Find help",
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
  },
  config = function()
    local telescope = require("telescope")
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
  end,
}
