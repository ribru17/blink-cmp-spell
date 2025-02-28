---@module 'blink.cmp'

local defaults = {
  max_entries = 3,
  preselect_current_word = true,
  keep_all_entries = false,
  use_cmp_spell_sorting = false,
  enable_in_context = function()
    return true
  end,
}

--- @class blink-cmp-spell.Source : blink.cmp.Source
---@field max_entries integer
---@field preselect_current_word boolean
---@field keep_all_entries boolean
---@field use_cmp_spell_sorting boolean
---@field enable_in_context fun(ctx: blink.cmp.Context): boolean
local M = {}

function M.new(opts)
  ---@type blink-cmp-spell.Source
  local config = vim.tbl_deep_extend('keep', opts or {}, defaults)
  vim.validate {
    max_entries = { config.max_entries, 'number' },
    enable_in_context = { config.enable_in_context, 'function' },
    preselect_current_word = { config.preselect_current_word, 'boolean' },
    keep_all_entries = { config.keep_all_entries, 'boolean' },
    use_cmp_spell_sorting = { config.use_cmp_spell_sorting, 'boolean' },
  }

  return setmetatable(config, { __index = M })
end

function M:enabled()
  return vim.wo.spell
end

---@param len integer
---@return integer
local function len_to_loglen(len)
  return math.ceil(math.log10(len + 1))
end

---@param input string
---@param number integer
---@param loglen integer
---@return string
local function number_to_text(input, number, loglen)
  return string.format(input .. '%0' .. loglen .. 'd', number)
end

function M:candidates(input, max_entries)
  local cands = {}
  local text_kind = vim.lsp.protocol.CompletionItemKind.Text
  local offset = 0
  local loglen = 0

  local entries = vim.fn.spellsuggest(input, max_entries)

  if
    self.preselect_current_word and vim.tbl_isempty(vim.spell.check(input))
  then
    offset = 1
    loglen = len_to_loglen(#entries + offset)

    cands[offset] = {
      label = input,
      insertText = input,
      filterText = input,
      kind = text_kind,
      sortText = self.use_cmp_spell_sorting
          and number_to_text(input, offset, loglen)
        or '_',
      preselect = true,
    }

    if not self.keep_all_entries then
      return cands
    end
  else
    offset = 0
    loglen = len_to_loglen(#entries + offset)
  end

  for i, entry in ipairs(entries) do
    i = i + offset
    cands[i] = {
      label = entry,
      insertText = entry,
      kind = text_kind,
      filterText = input,
      sortText = ('_'):rep(i),
      preselect = false,
    }

    if self.use_cmp_spell_sorting then
      cands[i].filterText = self.keep_all_entries and input or entry
      cands[i].sortText = self.keep_all_entries
          and number_to_text(input, i, loglen)
        or entry
    end
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
        items = self:candidates(input, self.max_entries),
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
