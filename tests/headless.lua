local root = assert(vim.env.SLIDES_NVIM_TEST_ROOT, "SLIDES_NVIM_TEST_ROOT is required")

require("nvim-treesitter").setup({ install_dir = "/tmp/slides-nvim-test/site" })
require("slides").setup({ snacks = false, notify_missing_parser = false })

assert(vim.filetype.match({ filename = "presentation.sly" }) == "sly", "*.sly must resolve to the sly filetype")

vim.cmd.edit(root .. "/tests/fixture.sly")
assert(vim.bo.filetype == "sly", "expected the sly filetype")

local parser = vim.treesitter.get_parser(0, "sly")
local tree = parser:parse()[1]
assert(tree and not tree:root():has_error(), "fixture must parse without errors")

local captures = {}
local query = assert(vim.treesitter.query.get("sly", "highlights"))
assert(#vim.api.nvim_get_runtime_file("queries/sly/highlights.scm", true) > 0, "missing runtime highlight query")
for id in query:iter_captures(tree:root(), 0) do
  captures[query.captures[id]] = true
end
assert(captures["markup.strong"], "missing strong-emphasis highlight")
assert(captures["markup.italic"], "missing italic-emphasis highlight")
assert(captures["markup.strikethrough"], "missing strikethrough highlight")
assert(captures["markup.math"], "missing formula highlight")

local images = assert(vim.treesitter.query.get("sly", "images"))
local image_count = 0
for _ in images:iter_matches(tree:root(), 0) do
  image_count = image_count + 1
end
assert(image_count >= 3, "expected image plus inline and display formulas")

vim.cmd("normal! zx")
assert(vim.wo.foldmethod == "expr", "folding must use foldexpr")
assert(vim.fn.foldlevel(1) >= 1, "metadata must be foldable")
assert(vim.fn.foldlevel(9) >= 2, "slides inside sections must be nested folds")
assert(vim.fn.foldlevel(13) >= 3, "column structures must be nested folds")

assert(vim.fn.exists(":SlydesBuild") == 2, "missing :SlydesBuild")
assert(vim.fn.exists(":SlydesImageHover") == 2, "missing :SlydesImageHover")

print("slides.nvim headless checks: ok")
