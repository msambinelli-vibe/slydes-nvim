# slides.nvim

Neovim support for the Slydes presentation language (`*.sly`).

## Features

- A dedicated Tree-sitter grammar and highlighting queries.
- Folding for metadata, sections, individual slides, fenced code, formulas,
  `columns`, `column`, and arbitrary indented containers.
- A lightweight markup preview: heading, emphasis, strong, strikethrough,
  code-span, and list punctuation is concealed outside Insert mode while the
  formatted text remains highlighted.
- Image and LaTeX formula previews through `snacks.nvim` and the Kitty graphics
  protocol.
- Rich in-buffer rendering for headings, code, slide separators, lists,
  checkboxes, quotes, callouts, tables, links, and indentation-scoped `:::`
  containers.
- Commands for compiling and validating the current presentation.
- No default keymaps.

## Requirements

- Neovim 0.11 or newer.
- The `main` branch of `nvim-treesitter`.
- `snacks.nvim` for images and formulas.
- A terminal with Kitty graphics support, such as Kitty or Ghostty.
- ImageMagick for image conversion.
- `tectonic` or `pdflatex` for formula previews.
- The `slydes` compiler in `PATH`, or an explicit `compiler` setting.

## Installation with lazy.nvim

```lua
{
  dir = "/path/to/slydes-org/slides-nvim",
  ft = "sly",
  dependencies = {
    { "nvim-treesitter/nvim-treesitter", branch = "main" },
    "folke/snacks.nvim",
  },
  build = function()
    require("slides").install_parser():wait()
  end,
  opts = {
    compiler = "slydes",
  },
}
```

The parser is generated and committed in `tree-sitter-sly/src/parser.c`, so
installation only needs a C compiler; it does not need the Tree-sitter CLI.
The plugin also ships `ftdetect/sly.lua`, allowing lazy.nvim to identify
`*.sly` before the plugin itself has been loaded.

If the plugin was installed without the build callback, run:

```vim
:SlydesInstallParser
```

## Snacks configuration

Snacks discovers Slydes because the plugin supplies `queries/sly/images.scm`.
Its image and math support must be enabled:

```lua
{
  "folke/snacks.nvim",
  opts = {
    image = {
      enabled = true,
      doc = {
        enabled = true,
        inline = true,
        float = true,
      },
      math = {
        enabled = true,
      },
    },
  },
}
```

Run `:checkhealth snacks` and `:SlydesHealth` if previews do not appear. In
particular, a global `image.math.enabled = false` prevents formula rendering in
Slydes too.

## Configuration

```lua
require("slides").setup({
  compiler = "slydes",
  folding = true,
  markup_preview = true,
  render = {},
  snacks = true,
  notify_missing_parser = true,
})
```

Rich rendering remains enabled in Normal, Insert, and Command-line modes. The
window's `concealcursor` still controls whether markup under the cursor is
temporarily revealed for editing. It is implemented by `slides.nvim` itself and
does not require `render-markdown.nvim`. The default appearance deliberately
uses familiar `RenderMarkdown*`-style concepts while exposing Sly-specific
highlight groups and container kinds.

Every renderer can be customized through `render`. The following example shows
the main extension points; omitted values retain their defaults:

```lua
require("slides").setup({
  render = {
    debounce = 80,
    render_modes = { "n", "no", "i", "c" },
    heading = {
      icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      border = true,
      padding = 1,
      width = "full",
    },
    slide = { icon = "─", width = "full" },
    checkbox = {
      custom = {
        blocked = { raw = "[!]", icon = "󰀪 ", highlight = "DiagnosticWarn" },
      },
    },
    link = {
      custom = {
        { pattern = "^https://github.com", icon = " " },
      },
    },
    container = {
      header_background = "SlyContainerHead",
      body_background = "SlyContainerBody",
      kinds = {
        definition = {
          icon = "󰙅 ",
          highlight = "DiagnosticInfo",
          header_background = "CursorLine",
          body_background = "NormalFloat",
        },
      },
    },
  },
})
```

Set `image_conceal = false` at the top level to keep the source of inline images
visible. By default, Snacks conceals `![description](path)` whenever its image
preview is being displayed.

The line ending a slide (`---`, including its attributes) is rendered as the
full-width thematic separator. A `::: name` line becomes a named block header,
and its indentation-scoped body receives a distinct background and a
quote-like continuation bar. Header and body backgrounds can be configured
globally or per container kind.
GitHub and Obsidian callout names are available by default. LaTeX formulas and
images remain under Snacks so terminal graphics and formula conversion have a
single owner.

The markup delimiters are visible in Insert mode and concealed in Normal and
Command-line modes. This makes editing predictable while preserving a clean
reading view.

## Commands

| Command | Action |
| --- | --- |
| `:SlydesInstallParser` | Build and install the bundled Tree-sitter parser. |
| `:SlydesBuild` | Compile the current file with `slydes`. |
| `:SlydesCheck` | Run `slydes --check` on the current file. |
| `:SlydesToggleMarkup` | Toggle markup concealment in the current window. |
| `:SlydesToggleRender` | Toggle rich rendering in the current Sly buffer. |
| `:SlydesImageHover` | Ask Snacks to preview the image or formula at the cursor. |
| `:SlydesHealth` | Report parser, terminal-image, and math status. |

The plugin intentionally defines no keymaps. Users can map these commands using
their existing conventions.

## Development

The Tree-sitter grammar lives in `tree-sitter-sly`. Regenerate and test it with:

```sh
cd tree-sitter-sly
tree-sitter generate
tree-sitter test
```

The `tests/fixture.sly`, `tests/headless.lua`, and `tests/snacks.lua` files cover
parsing, captures, folding, commands, and Snacks query integration.
