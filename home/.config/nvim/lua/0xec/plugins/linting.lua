local js_lint_filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
}

local severities = {
  vim.diagnostic.severity.WARN,
  vim.diagnostic.severity.ERROR,
}

local function parse_eslint_json(source)
  return function(output, bufnr)
    local trimmed_output = vim.trim(output)

    if trimmed_output == "" then
      return {}
    end

    local decode_opts = { luanil = { object = true, array = true } }
    local ok, data = pcall(vim.json.decode, output, decode_opts)

    if string.find(trimmed_output, "No ESLint configuration found") then
      vim.notify_once(trimmed_output, vim.log.levels.WARN)
      return {}
    end

    if not ok then
      return {
        {
          bufnr = bufnr,
          lnum = 0,
          col = 0,
          message = "Could not parse linter output due to: " .. data .. "\noutput: " .. output,
        },
      }
    end

    local diagnostics = {}

    for _, result in ipairs(data or {}) do
      for _, message in ipairs(result.messages or {}) do
        table.insert(diagnostics, {
          lnum = message.line and (message.line - 1) or 0,
          end_lnum = message.endLine and (message.endLine - 1) or nil,
          col = message.column and (message.column - 1) or 0,
          end_col = message.endColumn and (message.endColumn - 1) or nil,
          message = message.message,
          code = message.ruleId,
          severity = severities[message.severity],
          source = source,
        })
      end
    end

    return diagnostics
  end
end

return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost", "InsertLeave" },
    config = function()
      local lint = require("lint")
      local js_tooling = require("0xec.util.js_tooling")

      lint.linters.xo = function()
        local project = js_tooling.current_project(0)

        return {
          cmd = function()
            return js_tooling.find_local_or_global_binary(project.root, "xo")
          end,
          stdin = true,
          stream = "stdout",
          ignore_exitcode = true,
          cwd = project.root,
          args = {
            "--reporter",
            "json",
            "--stdin",
            "--stdin-filename",
            function()
              return vim.api.nvim_buf_get_name(0)
            end,
            function()
              return "--cwd=" .. project.root
            end,
          },
          parser = parse_eslint_json("xo"),
        }
      end

      lint.linters.oxlint_project = function()
        local base = lint.linters.oxlint

        if type(base) == "function" then
          base = base()
        end

        local project = js_tooling.current_project(0)
        local linter = vim.deepcopy(base)
        linter.name = "oxlint_project"
        linter.cmd = function()
          return js_tooling.find_local_or_global_binary(project.root, "oxlint")
        end
        linter.cwd = project.root

        return linter
      end

      local group = vim.api.nvim_create_augroup("0xec-lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = group,
        callback = function(args)
          local bufnr = args.buf

          -- Skip the BufWritePost triggered by conform's async re-save after formatting
          if vim.b[bufnr].conform_applying_formatting then
            return
          end

          local filetype = vim.bo[bufnr].filetype

          if not js_lint_filetypes[filetype] then
            return
          end

          local project = js_tooling.current_project(bufnr)

          if project.profile == "xo" then
            lint.try_lint({ "xo" }, { cwd = project.root, ignore_errors = true })
            return
          end

          if project.profile == "oxc" then
            if args.event ~= "BufWritePost" and vim.bo[bufnr].modified then
              return
            end

            lint.try_lint({ "oxlint_project" }, { cwd = project.root, ignore_errors = true })
          end
        end,
      })
    end,
  },
}
