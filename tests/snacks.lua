local root = assert(vim.env.SLIDES_NVIM_TEST_ROOT, "SLIDES_NVIM_TEST_ROOT is required")

require("nvim-treesitter").setup({ install_dir = "/tmp/slides-nvim-test/site" })
require("snacks").setup({
  image = {
    enabled = true,
    doc = { enabled = true, inline = false, float = false },
    math = { enabled = true },
  },
})
require("slides").setup({ notify_missing_parser = false })

vim.cmd.edit(root .. "/tests/fixture.sly")
assert(vim.tbl_contains(Snacks.image.langs(), "sly"), "Snacks must discover the sly image query")

local matches
Snacks.image.doc.find(0, function(found)
  matches = found
end)
assert(
  vim.wait(1000, function()
    return matches ~= nil
  end),
  "Snacks image query timed out"
)

local types = {}
for _, match in ipairs(matches) do
  types[match.type] = (types[match.type] or 0) + 1
end
assert((types.image or 0) >= 1, "Snacks did not find the Slydes image")
assert((types.math or 0) >= 2, "Snacks did not find the Slydes formulas")

print("slides.nvim Snacks checks: ok")
