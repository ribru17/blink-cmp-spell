---@module 'blink.cmp'

---@class blink-cmp-spell.Config
local defaults = {
  max_entries = 3,
  ---@param ctx? blink.cmp.Context
  ---@diagnostic disable: unused-local
  enable_in_context = function(ctx)
    return true
  end,
  keep_all_entries = false,
  preselect_correct_word = true,
}

---@class blink-cmp-spell.Source:  blink.cmp.Source
local M = {}

M.max_entries = 0 ---@type integer
M.enable_in_context = function() ---@type function(ctx? blink.cmp.Context): boolean
  return true
end
M.keep_all_entries = false ---@type boolean
M.preselect_correct_word = true ---@type boolean

---@param opts? blink-cmp-spell.Config
function M.new(opts)
  local config = vim.tbl_deep_extend('keep', opts or {}, defaults)
  vim.validate({
    max_entries = { config.max_entries, 'number' },
    enable_in_context = { config.enable_in_context, 'function' },
    keep_all_entries = { config.keep_all_entries, 'boolean' },
    preselect_correct_word = { config.preselect_correct_word, 'boolean' },
  })

  return setmetatable({
    max_entries = config.max_entries,
    enable_in_context = config.enable_in_context,
    keep_all_entries = config.keep_all_entries,
    preselect_correct_word = config.preselect_correct_word,
  }, { __index = M })
end

---@return boolean
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

---@param input string
---@param src blink-cmp-spell.Source
---@return table
local function candidates(input, src)
  local items = {}
  local entries = vim.fn.spellsuggest(input, src.max_entries)
  local offset
  local loglen
  if src.preselect_correct_word and vim.tbl_isempty(vim.spell.check(input)) then
    offset = 1
    loglen = len_to_loglen(#entries + offset)

    items[offset] = {
      label = input,
      filterText = input,
      sortText = number_to_text(input, offset, loglen),
      preselct = true,
    }
  else
    offset = 0
    loglen = len_to_loglen(#entries + offset)
  end

  for k, v in ipairs(entries) do
    items[k + offset] = {
      label = v,
      filterText = src.keep_all_entries and input or v,
      sortText = src.keep_all_entries and number_to_text(input, k + offset, loglen) or v,
      preselct = false,
    }
  end

  return items
end

---@param context blink.cmp.Context
---@param callback blink.cmp.CompletionResponse
function M:get_completions(context, callback)
  vim.schedule(function()
    local input =
      string.sub(context.line, context.bounds.start_col, context.bounds.start_col + context.bounds.length - 1)
    if self.enable_in_context(context) then
      callback({
        items = candidates(input, self),
        is_incomplete_forward = true,
        is_incomplete_backward = true,
      })
    else
      callback({
        items = {},
        is_incomplete_forward = true,
        is_incomplete_backward = true,
      })
    end
  end)
end

return M
