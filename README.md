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
  snacks = true,
  notify_missing_parser = true,
})
```

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
