local M = {}

local defaults = {
  compiler = "slydes",
  folding = true,
  markup_preview = true,
  render = {},
  snacks = true,
  notify_missing_parser = true,
}

M.config = vim.deepcopy(defaults)
M._did_bootstrap = false
M._missing_parser_notified = false

local function plugin_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  return vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(source)))
end

function M.register_parser()
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then
    return false
  end
  parsers.sly = {
    install_info = {
      path = plugin_root() .. "/tree-sitter-sly",
      generate = false,
      queries = "queries",
    },
    tier = 3,
  }
  vim.treesitter.language.register("sly", "sly")
  return true
end

function M.install_parser()
  if not M.register_parser() then
    vim.notify("slides.nvim requires nvim-treesitter", vim.log.levels.ERROR)
    return
  end
  local ok, treesitter = pcall(require, "nvim-treesitter")
  if not ok then
    vim.notify("slides.nvim requires nvim-treesitter", vim.log.levels.ERROR)
    return
  end
  return treesitter.install({ "sly" }, { force = true, summary = true })
end

local function parser_available()
  return #vim.api.nvim_get_runtime_file("parser/sly.*", false) > 0
end

local function attach_snacks(buf)
  if not M.config.snacks then
    return
  end
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    local snacks = rawget(_G, "Snacks")
    if snacks and snacks.image and snacks.image.doc then
      snacks.image.doc.attach(buf)
    end
  end)
end

function M.attach(buf)
  buf = buf or 0
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  vim.bo[buf].commentstring = ""

  if parser_available() then
    pcall(vim.treesitter.start, buf, "sly")
  elseif M.config.notify_missing_parser and not M._missing_parser_notified then
    M._missing_parser_notified = true
    vim.schedule(function()
      vim.notify("Slydes parser is not installed; run :SlydesInstallParser", vim.log.levels.WARN)
    end)
  end

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if M.config.folding then
      vim.wo[win].foldmethod = "expr"
      vim.wo[win].foldexpr = "v:lua.require'slides.fold'.foldexpr()"
      vim.wo[win].foldtext = "v:lua.require'slides.fold'.foldtext()"
      vim.wo[win].foldlevel = 99
    end
    if M.config.markup_preview then
      vim.wo[win].conceallevel = 2
      vim.wo[win].concealcursor = "nc"
    end
  end

  attach_snacks(buf)
  require("slides.render").attach(buf, M.config.render)
end

local function run_compiler(check_only)
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Save the .sly buffer before compiling", vim.log.levels.WARN)
    return
  end
  local command = { M.config.compiler }
  if check_only then
    command[#command + 1] = "--check"
  end
  command[#command + 1] = file
  vim.system(command, { text = true }, function(result)
    vim.schedule(function()
      local message = vim.trim(result.code == 0 and result.stdout or result.stderr)
      vim.notify(
        message ~= "" and message or "Slydes finished",
        result.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
      )
    end)
  end)
end

function M.toggle_markup_preview()
  local win = vim.api.nvim_get_current_win()
  vim.wo[win].conceallevel = vim.wo[win].conceallevel == 0 and 2 or 0
end

function M.health()
  local findings = {}
  findings[#findings + 1] = parser_available() and "Tree-sitter parser: installed" or "Tree-sitter parser: missing"
  local snacks = rawget(_G, "Snacks")
  if snacks and snacks.image then
    findings[#findings + 1] = snacks.image.supports_terminal() and "Snacks image terminal: supported"
      or "Snacks image terminal: unsupported"
    local math = snacks.image.config and snacks.image.config.math
    findings[#findings + 1] = math and math.enabled and "Snacks math: enabled" or "Snacks math: disabled"
  else
    findings[#findings + 1] = "Snacks image: unavailable"
  end
  vim.notify(table.concat(findings, "\n"), vim.log.levels.INFO, { title = "slides.nvim" })
end

function M._bootstrap()
  if M._did_bootstrap then
    return
  end
  M._did_bootstrap = true

  vim.filetype.add({ extension = { sly = "sly" } })
  M.register_parser()
  vim.api.nvim_create_autocmd("User", {
    pattern = "TSUpdate",
    callback = M.register_parser,
    desc = "Register the Slydes Tree-sitter parser",
  })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "sly",
    callback = function(args)
      M.attach(args.buf)
    end,
    desc = "Attach slides.nvim to Slydes buffers",
  })

  vim.api.nvim_create_user_command(
    "SlydesInstallParser",
    M.install_parser,
    { desc = "Install the Slydes Tree-sitter parser" }
  )
  vim.api.nvim_create_user_command("SlydesBuild", function()
    run_compiler(false)
  end, { desc = "Compile the current Slydes presentation" })
  vim.api.nvim_create_user_command("SlydesCheck", function()
    run_compiler(true)
  end, { desc = "Validate the current Slydes presentation" })
  vim.api.nvim_create_user_command(
    "SlydesToggleMarkup",
    M.toggle_markup_preview,
    { desc = "Toggle Slydes markup concealment" }
  )
  vim.api.nvim_create_user_command("SlydesToggleRender", function()
    local enabled = require("slides.render").toggle(0)
    vim.notify("Slydes rendering " .. (enabled and "enabled" or "disabled"), vim.log.levels.INFO)
  end, { desc = "Toggle rich Slydes rendering" })
  vim.api.nvim_create_user_command("SlydesImageHover", function()
    local snacks = rawget(_G, "Snacks")
    if snacks and snacks.image then
      snacks.image.hover()
    else
      vim.notify("Snacks.image is not available", vim.log.levels.WARN)
    end
  end, { desc = "Preview the Slydes image or formula under the cursor" })
  vim.api.nvim_create_user_command("SlydesHealth", M.health, { desc = "Check slides.nvim dependencies" })
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  M._bootstrap()
end

return M
