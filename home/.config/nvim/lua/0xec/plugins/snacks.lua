local filtered_messages = { "No information available" }

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    bufdelete = { enabled = true },
    dim = { enabled = true },
    gitbrowse = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 3000,
      style = "fancy",
    },
    rename = { enabled = true },
    scratch = { enabled = true },
    statuscolumn = { enabled = true },
    toggle = { enabled = true },
    words = { enabled = true },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        local notify = Snacks.notifier.notify

        Snacks.notifier.notify = function(message, level, opts)
          for _, filtered in ipairs(filtered_messages) do
            if message == filtered then
              return nil
            end
          end

          return notify(message, level, opts)
        end
      end,
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "OilActionsPost",
      callback = function(event)
        local action = event.data.actions

        if action.type == "move" then
          Snacks.rename.on_rename_file(action.src_url, action.dest_url)
        end
      end,
    })
  end,
}
