---@module 'blink.cmp'

local defaults = {
  max_entries = 3,
  enable_in_context = function()
    return true
  end,
}

--- @class blink-cmp-spell.Source : blink.cmp.Source
local M = {}

function M.new(opts)
  opts = opts or {}
  return setmetatable({
    max_entries = opts.max_entries or defaults.max_entries,
    enable_in_context = opts.enable_in_context or defaults.enable_in_context,
  }, { __index = M })
end

function M:enabled()
  return vim.wo.spell
end

local function candidates(input, max_entries)
  if #vim.spell.check(input) == 0 then
    return {}
  end

  local entries = vim.fn.spellsuggest(input, max_entries)
  local cands = {}
  local text = vim.lsp.protocol.CompletionItemKind.Text

  for i, entry in ipairs(entries) do
    cands[i] = {
      label = entry,
      insertText = entry,
      kind = text,
      filterText = input,
      sortText = ('_'):rep(i),
    }
  end
  return cands
end

function M:get_completions(context, callback)
  vim.schedule(function()
    local input = string.sub(
      context.line,
      context.bounds.start_col,
      context.bounds.start_col + context.bounds.length - 1
    )
    if self.enable_in_context(context) then
      callback {
        items = candidates(input, self.max_entries),
        is_incomplete_forward = true,
        is_incomplete_backward = true,
      }
    else
      callback {
        items = {},
        is_incomplete_forward = true,
        is_incomplete_backward = true,
      }
    end
  end)
end

return M
