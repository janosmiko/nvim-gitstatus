# nvim-gitstatus

A simple [Neovim](https://neovim.io/) plugin providing a
[lualine](https://github.com/nvim-lualine/lualine.nvim)
component to display `git status` results in the status line.

![screenshot](https://github.com/user-attachments/assets/e375c61a-bfe7-454f-99c8-a67a8d033777)

> [!CAUTION]
> This plugin is still in early development. It has not been tested extensively
> and may not work as expected.

## Prerequisites

- [Neovim](https://neovim.io/) ≥ 0.10.0.
- [Git](https://git-scm.com/).
- [lualine](https://github.com/nvim-lualine/lualine.nvim)
  for status line integration.

## Installation

Using [lazy.nvim](https://lazy.folke.io/):

```lua
{
  "abccsss/nvim-gitstatus",
  event = "VeryLazy",
  config = true,
}
```

## Setup

Add the component `"gitstatus"` to your lualine configuration. For example:

```lua
require("lualine").setup {
  options = {
    -- lualine options here
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = {
      {
        "gitstatus",
        sections = {
          { "branch", format = " {}" },
          { "is_dirty", format = "*" },
        },
        sep = "",
      }
    },
    lualine_c = {
      "gitstatus",
      sections = {
        { "ahead", format = "{}↑" },
        { "behind", format = "{}↓" },
        { "conflicted", format = "{}!" },
        { "staged", format = "{}=" },
        { "untracked", format = "{}+" },
        { "modified", format = "{}*" },
        { "renamed", format = "{}~" },
        { "deleted", format = "{}-" },
      },
      sep = " ",
    },
    -- other sections here
  },
  -- other options here
}
```

Each item in the `sections` table is either a string or a table with the
following fields:

- `[1]: string` - The variable name to display, which must be one of the
  following:

  - `branch` - The current branch name.
  - `upstream_branch` - The remote branch name.
  - `is_dirty` - A boolean value indicating whether the working directory is
    dirty. Useful for e.g. showing a `*` next to the branch name.
  - `up_to_date` - A boolean value indicating whether the local branch is up to
    date with the remote branch.
  - `up_to_date_and_clean` - Equal to `up_to_date and not is_dirty`. Useful for
    showing a symbol when nothing else is displayed.
  - `ahead` - The number of commits ahead of the remote branch.
  - `behind` - The number of commits behind the remote branch.
  - `conflicted` - The number of conflicted items.
  - `deleted` - The number of deleted items.
  - `modified` - The number of modified items.
  - `renamed` - The number of renamed items.
  - `staged` - The number of staged items, including additions, modifications,
    and deletions.
  - `stashed` - The number of stashed items.
  - `untracked` - The number of new items.

- `format: string` (optional) - The format string to use. The variable value is
  inserted at `{}`. If not provided, the variable value is displayed as is.

- `hl: string` (optional) - The highlight group to use, which is one of the
  following:

  - A hex code of the form `"#rrggbb"`.
  - The name of a highlight group. Only the foreground colour of the highlight
    group is used.

  The second option is preferred, as it adapts to different colour schemes.

If the value of a variable is `0` or `false` or an empty string,
the entire section is omitted.

The `sep` field is either a string or a table with the following fields:

- `[1]: string` - the separator between sections.
- `hl: string` (optional) - the highlight group for the separator. See above
  for the syntax.

## Options

The plugin comes with the following default options:

```lua
{
  --- Interval to automatically run `git fetch`, in milliseconds.
  --- Set to `false` to disable auto fetch.
  auto_fetch_interval = 30000,

  --- Timeout in milliseconds for `git status` to complete before it is killed.
  git_status_timeout = 1000,
},
```
