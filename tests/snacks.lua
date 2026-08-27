local root = assert(vim.env.SLIDES_NVIM_TEST_ROOT, "SLIDES_NVIM_TEST_ROOT is required")

require("nvim-treesitter").setup({ install_dir = "/tmp/slides-nvim-test/site" })
vim.cmd("filetype plugin on")
require("snacks").setup({
  image = {
    enabled = true,
    doc = { enabled = true, inline = true, float = true },
    math = { enabled = true },
  },
})
Snacks.image.terminal._terminal = {
  terminal = "kitty",
  version = "test",
  supported = true,
  placeholders = true,
}
Snacks.image.terminal._env = {
  name = "kitty",
  supported = true,
  placeholders = true,
}
require("slides").setup({ notify_missing_parser = false })

vim.cmd.edit(root .. "/tests/fixture.sly")
assert(vim.bo.filetype == "sly", "expected the sly filetype")
assert(vim.tbl_contains(Snacks.image.langs(), "sly"), "Snacks must discover the sly image query")

local buf = vim.api.nvim_get_current_buf()
assert(vim.b[buf].snacks_image_conceal == true, "Slydes images must be concealed by the inline preview")
assert(
  vim.wait(1000, function()
    return vim.b[buf].snacks_image_attached == true
  end),
  "Snacks image preview did not attach"
)
local inline_group = "snacks.image.inline." .. buf
assert(
  vim.tbl_contains(
    vim.tbl_map(function(autocmd)
      return autocmd.group_name
    end, vim.api.nvim_get_autocmds({ event = "BufWinEnter", buffer = buf })),
    inline_group
  ),
  "Snacks inline preview attached to the wrong buffer"
)

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
