local root = assert(vim.env.SLIDES_NVIM_TEST_ROOT, "SLIDES_NVIM_TEST_ROOT is required")

require("nvim-treesitter").setup({ install_dir = "/tmp/slides-nvim-test/site" })
vim.cmd("filetype plugin on")
require("slides").setup({ snacks = false, notify_missing_parser = false })

vim.cmd.edit(root .. "/tests/render_fixture.sly")
assert(vim.bo.filetype == "sly", "expected the sly filetype")

assert(
  vim.wait(1000, function()
    return next(require("slides.render").status(0)) ~= nil
  end),
  "Slydes renderer timed out"
)

local counts = require("slides.render").status(0)
for _, kind in ipairs({
  "heading",
  "section_heading",
  "section_marker",
  "code_block",
  "code_background",
  "code_inline",
  "slide",
  "bullet",
  "checkbox",
  "quote",
  "callout",
  "table_header",
  "table_alignment",
  "table_row",
  "link",
  "container",
  "container_header_background",
  "container_body_background",
  "container_continuation",
}) do
  assert((counts[kind] or 0) > 0, "missing rich rendering for " .. kind)
end

assert(
  vim.tbl_contains(require("slides.render").defaults.render_modes, "i"),
  "rendering must stay enabled in Insert mode"
)
assert(
  vim.api.nvim_get_hl(0, { name = "SlyContainerHead", link = true }).link == "CursorLine",
  "container headers must use their own background"
)
assert(
  vim.api.nvim_get_hl(0, { name = "SlyContainerBody", link = true }).link == "NormalFloat",
  "container bodies must use the darker block background"
)

assert(vim.fn.exists(":SlydesToggleRender") == 2, "missing :SlydesToggleRender")
assert(require("slides.render").toggle(0) == false, "renderer should toggle off")
assert(next(require("slides.render").status(0)) == nil, "renderer marks should clear when disabled")
assert(require("slides.render").toggle(0) == true, "renderer should toggle on")

print("slides.nvim rich rendering checks: ok")
