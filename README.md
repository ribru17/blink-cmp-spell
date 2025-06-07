# blink-cmp-spell

`spell` source for [`blink.cmp`](https://github.com/Saghen/blink.cmp) based on
Neovim's `spellsuggest`.

## Usage

```lua
{
  'saghen/blink.cmp',
  dependencies = { 'ribru17/blink-cmp-spell' },
  opts = {
    -- ...

    sources = {
      default = {
        -- ...
        'spell'
      },
      providers = {
        -- ...
        spell = {
          name = 'Spell',
          module = 'blink-cmp-spell',
          opts = {
            -- EXAMPLE: Only enable source in `@spell` captures, and disable it
            -- in `@nospell` captures.
            enable_in_context = function()
              local curpos = vim.api.nvim_win_get_cursor(0)
              local captures = vim.treesitter.get_captures_at_pos(
                0,
                curpos[1] - 1,
                curpos[2] - 1
              )
              local in_spell_capture = false
              for _, cap in ipairs(captures) do
                if cap.capture == 'spell' then
                  in_spell_capture = true
                elseif cap.capture == 'nospell' then
                  return false
                end
              end
              return in_spell_capture
            end,
          },
        },
      },
    },


    -- It is recommended to put the "label" sorter as the primary sorter for the
    -- spell source.
    -- If you set use_cmp_spell_sorting to true, you may want to skip this step.
    fuzzy = {
      sorts = {
        function(a, b)
          local sort = require('blink.cmp.fuzzy.sort')
          if a.source_id == 'spell' and b.source_id == 'spell' then
            return sort.label(a, b)
          end
        end,
        -- This is the normal default order, which we fall back to
        'score',
        'kind',
        'label',
      },
    },
  },
}
```

> [!NOTE]
> `vim.fn.spellsuggest` is really slow for some languages, for example German.
> You can selectively disable this source, when German is configured in
> 'spelllang' like so:
>
> ```lua
> --- @type table<integer, boolean?>
> local spell_enabled_cache = {}
> 
> vim.api.nvim_create_autocmd('OptionSet', {
>   group = vim.api.nvim_create_augroup('blink_cmp_spell', {}),
>   desc = 'Reset the cache for enabling the spell source for blink.cmp.',
>   pattern = 'spelllang',
>   callback = function()
>     spell_enabled_cache[vim.fn.bufnr()] = nil
>   end,
> })
> 
> {
>   'saghen/blink.cmp',
>   dependencies = { 'ribru17/blink-cmp-spell' },
>   opts = {
>     sources = {
>       providers = {
>         spell = {
>           enabled = function()
>             local bufnr = vim.fn.bufnr()
>             local enabled = spell_cache[bufnr]
>             if type(enabled) ~= 'boolean' then
>               enabled = not vim.list_contains(vim.opt_local.spelllang:get(), 'de')
>               spell_cache[bufnr] = enabled
>             end
>             return enabled
>           end,
>         },
>       },
>     },
>   },
> }
> ```

## Options

### `max_entries` (`integer`, default `3`)

The maximum number of results to be returned from the spellchecker.

### `preselect_current_word` (`boolean`, default `true`)

If true and the spelling of the word is correct, the word is displayed as the first entry
and preselected.

### `keep_all_entries` (`boolean`, default `false`)

If true, all `vim.fn.spellsuggest` results are displayed in `blink`'s menu. Otherwise,
they are filtered to only include fuzzy matches.

### `use_cmp_spell_sorting` (`boolean`, default `false`)

If true, then completion candidates will be sorted using the same algorithm used by
`cmp-spell`. This can be helpful for sorting words that are partially typed. Otherwise,
a custom sorting is used.

> [!NOTE]
> If this option is set to `true`, then it is recommended that the `fuzzy.sorts` table is
> left to its default value.

### `enable_in_context` (`function`, default `function() return true end`)

A function that, upon returning false, disables the completion source. This can
be used to disable the spelling source when in a `@nospell` `treesitter`
capture.



## Shoutout

A huge thank you to @f3fora for the code inspiration from
[`cmp-spell`](https://github.com/f3fora/cmp-spell)!
