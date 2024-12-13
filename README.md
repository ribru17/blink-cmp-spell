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
            -- ...
          }
        },
      },
    },


    -- It is recommended to put the "label" sorter as the primary sorter for the
    -- spell source
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

## Options

### `max_entries` (`integer`, default `3`)

The maximum number of results to be returned from the spellchecker.

### `enable_in_context` (`function`, default `function() return true end`)

A function that, upon returning false, disables the completion source. This can
be used to disable the spelling source when in a `@nospell` `treesitter`
capture.

## Shoutout

A huge thank you to @f3fora for the code inspiration from
[`cmp-spell`](https://github.com/f3fora/cmp-spell)!
