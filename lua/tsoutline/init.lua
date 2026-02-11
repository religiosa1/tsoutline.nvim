---@module "plenary"

-- local configModule = require("tsoutline/config")
local outline = require("tsoutline/outline")

local M = {}

---@param opts? TsOutlineConfig | {}
function M.tsoutline(opts)
  -- config =
  --     vim.tbl_deep_extend("force", configModule.default(), M.config, config or {})

  local ft = vim.bo.filetype
  if ft == "typescript" or ft == "typescriptreact" then
    return Snacks.picker({
      title = "Outline (treesitter)",
      items = outline(),
      format = "lsp_symbol",
      tree = true,
      auto_confirm = false,
      show_empty = true,
      jump = { tagstack = true, reuse_win = true },
    })
  else
    Snacks.picker.lsp_symbols({
      title = "Outline (LSP)",
      filter = { default = { "Class", "Function", "Method", "Constructor", "Enum" } },
    })
  end
end

---@param opts TsOutlineConfig | {}
function M.setup(opts)
  vim.api.nvim_create_user_command("TsOutline", function()
    M.tsoutline(opts)
  end, {})
end

return M
