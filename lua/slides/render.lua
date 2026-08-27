local M = {}

local namespace = vim.api.nvim_create_namespace("slydes.render")
local states = {}

local defaults = {
  enabled = true,
  debounce = 80,
  render_modes = { "n", "no", "c" },
  heading = {
    icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
    foregrounds = { "SlyHeading1", "SlyHeading2", "SlyHeading3", "SlyHeading4", "SlyHeading5", "SlyHeading6" },
    backgrounds = {
      "SlyHeading1Bg",
      "SlyHeading2Bg",
      "SlyHeading3Bg",
      "SlyHeading4Bg",
      "SlyHeading5Bg",
      "SlyHeading6Bg",
    },
    border = true,
    border_char = "─",
    padding = 1,
    width = "full",
  },
  code = {
    background = "SlyCode",
    border = "─",
    border_highlight = "SlyCodeBorder",
    language_highlight = "SlyCodeLanguage",
    language_icons = {
      lua = " ",
      python = " ",
      rust = " ",
      javascript = " ",
      typescript = " ",
      html = " ",
      css = " ",
      bash = " ",
      sh = " ",
      text = "󰈙 ",
    },
    inline = "SlyCodeInline",
    padding = 1,
    width = "full",
  },
  slide = {
    icon = "─",
    highlight = "SlySlideDelimiter",
    width = "full",
  },
  bullet = {
    icons = { "●", "○", "◆", "◇" },
    highlight = "SlyBullet",
    padding = 1,
  },
  checkbox = {
    unchecked = { raw = "[ ]", icon = "󰄱 ", highlight = "SlyUnchecked" },
    checked = { raw = "[x]", icon = "󰱒 ", highlight = "SlyChecked" },
    custom = {
      todo = { raw = "[-]", icon = "󰥔 ", highlight = "SlyTodo" },
    },
  },
  quote = {
    icon = "▋",
    highlight = "SlyQuote",
  },
  callout = {
    note = { raw = "NOTE", icon = "󰋽 ", title = "Note", highlight = "SlyInfo" },
    tip = { raw = "TIP", icon = "󰌶 ", title = "Tip", highlight = "SlySuccess" },
    important = { raw = "IMPORTANT", icon = "󰅾 ", title = "Important", highlight = "SlyHint" },
    warning = { raw = "WARNING", icon = "󰀪 ", title = "Warning", highlight = "SlyWarn" },
    caution = { raw = "CAUTION", icon = "󰳦 ", title = "Caution", highlight = "SlyError" },
    info = { raw = "INFO", icon = "󰋽 ", title = "Info", highlight = "SlyInfo" },
    todo = { raw = "TODO", icon = "󰗡 ", title = "Todo", highlight = "SlyInfo" },
    abstract = { raw = "ABSTRACT", icon = "󰨸 ", title = "Abstract", highlight = "SlyInfo" },
    summary = { raw = "SUMMARY", icon = "󰨸 ", title = "Summary", highlight = "SlyInfo" },
    tldr = { raw = "TLDR", icon = "󰨸 ", title = "Tldr", highlight = "SlyInfo" },
    hint = { raw = "HINT", icon = "󰌶 ", title = "Hint", highlight = "SlySuccess" },
    success = { raw = "SUCCESS", icon = "󰄬 ", title = "Success", highlight = "SlySuccess" },
    check = { raw = "CHECK", icon = "󰄬 ", title = "Check", highlight = "SlySuccess" },
    done = { raw = "DONE", icon = "󰄬 ", title = "Done", highlight = "SlySuccess" },
    question = { raw = "QUESTION", icon = "󰘥 ", title = "Question", highlight = "SlyWarn" },
    help = { raw = "HELP", icon = "󰘥 ", title = "Help", highlight = "SlyWarn" },
    faq = { raw = "FAQ", icon = "󰘥 ", title = "Faq", highlight = "SlyWarn" },
    attention = { raw = "ATTENTION", icon = "󰀪 ", title = "Attention", highlight = "SlyWarn" },
    failure = { raw = "FAILURE", icon = "󰅖 ", title = "Failure", highlight = "SlyError" },
    fail = { raw = "FAIL", icon = "󰅖 ", title = "Fail", highlight = "SlyError" },
    missing = { raw = "MISSING", icon = "󰅖 ", title = "Missing", highlight = "SlyError" },
    danger = { raw = "DANGER", icon = "󱐌 ", title = "Danger", highlight = "SlyError" },
    error = { raw = "ERROR", icon = "󱐌 ", title = "Error", highlight = "SlyError" },
    bug = { raw = "BUG", icon = "󰨰 ", title = "Bug", highlight = "SlyError" },
    example = { raw = "EXAMPLE", icon = "󰉹 ", title = "Example", highlight = "SlyHint" },
    quote = { raw = "QUOTE", icon = "󱆨 ", title = "Quote", highlight = "SlyQuote" },
    cite = { raw = "CITE", icon = "󱆨 ", title = "Cite", highlight = "SlyQuote" },
  },
  table = {
    border = { "┌", "┬", "┐", "├", "┼", "┤", "└", "┴", "┘", "│", "─" },
    align = { left = "◄", center = "◆", right = "►", default = "─" },
    highlight = "SlyTableBorder",
    head = "SlyTableHead",
    row = "SlyTableRow",
    padding = 1,
  },
  link = {
    icon = "󰌹 ",
    highlight = "SlyLink",
    custom = {
      { pattern = "^https?://", icon = "󰖟 " },
      { pattern = "^mailto:", icon = "󰇮 " },
      { pattern = "%.pdf$", icon = " " },
    },
  },
  container = {
    icon = "▋",
    continuation = "│",
    highlight = "SlyContainer",
    kinds = {
      theorem = { icon = "󰔷 ", highlight = "SlyTheorem" },
      lemma = { icon = "󰘧 ", highlight = "SlyLemma" },
      proof = { icon = "󰡱 ", highlight = "SlyProof" },
      code = { icon = " ", highlight = "SlyCodeBorder" },
      figure = { icon = "󰋩 ", highlight = "SlyFigure" },
      columns = { icon = "󰕰 ", highlight = "SlyColumns" },
      column = { icon = "󰆼 ", highlight = "SlyColumns" },
    },
  },
}

local highlight_links = {
  SlyHeading1 = "Title",
  SlyHeading2 = "DiagnosticInfo",
  SlyHeading3 = "DiagnosticHint",
  SlyHeading4 = "DiagnosticOk",
  SlyHeading5 = "DiagnosticWarn",
  SlyHeading6 = "DiagnosticError",
  SlyHeading1Bg = "CursorLine",
  SlyHeading2Bg = "CursorLine",
  SlyHeading3Bg = "CursorLine",
  SlyHeading4Bg = "CursorLine",
  SlyHeading5Bg = "CursorLine",
  SlyHeading6Bg = "CursorLine",
  SlyCode = "CursorLine",
  SlyCodeBorder = "Comment",
  SlyCodeLanguage = "Type",
  SlyCodeInline = "Visual",
  SlySlideDelimiter = "Comment",
  SlyBullet = "Special",
  SlyUnchecked = "DiagnosticWarn",
  SlyChecked = "DiagnosticOk",
  SlyTodo = "DiagnosticInfo",
  SlyQuote = "Comment",
  SlyInfo = "DiagnosticInfo",
  SlySuccess = "DiagnosticOk",
  SlyHint = "DiagnosticHint",
  SlyWarn = "DiagnosticWarn",
  SlyError = "DiagnosticError",
  SlyTableBorder = "Comment",
  SlyTableHead = "Title",
  SlyTableRow = "Normal",
  SlyLink = "Underlined",
  SlyContainer = "Special",
  SlyTheorem = "DiagnosticInfo",
  SlyLemma = "DiagnosticHint",
  SlyProof = "Comment",
  SlyFigure = "Special",
  SlyColumns = "Type",
}

local function setup_highlights()
  for name, target in pairs(highlight_links) do
    vim.api.nvim_set_hl(0, name, { default = true, link = target })
  end
end

local function normalize_buf(buf)
  if buf == nil or buf == 0 then
    return vim.api.nvim_get_current_buf()
  end
  return buf
end

local function indent_width(line)
  local prefix = line:match("^[ \t]*") or ""
  return vim.fn.strdisplaywidth(prefix), #prefix
end

local function usable_width(buf)
  local width = vim.o.columns
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    local info = vim.fn.getwininfo(win)[1]
    local textoff = info and info.textoff or 0
    width = math.min(width, math.max(1, vim.api.nvim_win_get_width(win) - textoff))
  end
  return width
end

local function component_width(value, available)
  if value == "full" then
    return available
  elseif type(value) == "number" and value > 0 and value < 1 then
    return math.max(1, math.floor(available * value))
  elseif type(value) == "number" then
    return math.min(available, math.max(1, math.floor(value)))
  end
  return available
end

local function mode_enabled(config)
  local mode = vim.api.nvim_get_mode().mode
  for _, allowed in ipairs(config.render_modes) do
    if mode == allowed or mode:sub(1, #allowed) == allowed then
      return true
    end
  end
  return false
end

local function renderer(buf, config)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local width = usable_width(buf)
  local counts = {}

  local function count(kind)
    counts[kind] = (counts[kind] or 0) + 1
  end

  local function mark(kind, row, col, opts)
    opts.priority = opts.priority or 120
    local ok = pcall(vim.api.nvim_buf_set_extmark, buf, namespace, row, col, opts)
    if ok then
      count(kind)
    end
  end

  local function replace(kind, row, start_col, end_col, text, highlight)
    if end_col <= start_col then
      return
    end
    mark(kind, row, start_col, {
      end_row = row,
      end_col = end_col,
      conceal = "",
      virt_text = { { text, highlight } },
      virt_text_pos = "overlay",
    })
  end

  local skip = {}

  -- Fenced code blocks.
  local row = 1
  while row <= #lines do
    local whitespace, language = lines[row]:match("^([ \t]*)```%s*([%w_+%-]*)%s*$")
    if whitespace then
      local close = row + 1
      while close <= #lines and not lines[close]:match("^[ \t]*```%s*$") do
        close = close + 1
      end
      if close <= #lines then
        local indent = vim.fn.strdisplaywidth(whitespace)
        local block_width = component_width(config.code.width, math.max(1, width - indent))
        local icon = config.code.language_icons[language] or " "
        local label = language ~= "" and (icon .. language) or icon .. "code"
        local fill = math.max(1, block_width - vim.fn.strdisplaywidth(label) - config.code.padding * 2)
        local top = (" "):rep(config.code.padding) .. label .. " " .. config.code.border:rep(fill)
        replace("code_block", row - 1, #whitespace, #lines[row], top, config.code.language_highlight)
        for body = row + 1, close - 1 do
          skip[body] = true
          mark("code_background", body - 1, 0, {
            line_hl_group = config.code.background,
          })
        end
        replace(
          "code_border",
          close - 1,
          #whitespace,
          #lines[close],
          config.code.border:rep(block_width),
          config.code.border_highlight
        )
        skip[row], skip[close] = true, true
        row = close + 1
      else
        row = row + 1
      end
    else
      row = row + 1
    end
  end

  -- Pipe tables. A delimiter row determines the column alignments.
  local function cells(line)
    local value = vim.trim(line)
    if not value:find("|", 1, true) then
      return nil
    end
    value = value:gsub("^|", ""):gsub("|$", "")
    local result = {}
    for cell in (value .. "|"):gmatch("(.-)|") do
      result[#result + 1] = vim.trim(cell)
    end
    return #result > 1 and result or nil
  end

  local function alignments(parts)
    local result = {}
    for _, part in ipairs(parts or {}) do
      local compact = part:gsub("%s", "")
      if not compact:match("^:?-+:?$") then
        return nil
      end
      result[#result + 1] = compact:sub(1, 1) == ":" and compact:sub(-1) == ":" and "center"
        or compact:sub(-1) == ":" and "right"
        or compact:sub(1, 1) == ":" and "left"
        or "default"
    end
    return result
  end

  row = 1
  while row < #lines do
    local header = cells(lines[row])
    local alignment = header and alignments(cells(lines[row + 1])) or nil
    if header and alignment and #header == #alignment then
      local last = row + 1
      local rows = { header }
      while last + 1 <= #lines do
        local next_cells = cells(lines[last + 1])
        if not next_cells or #next_cells ~= #header then
          break
        end
        rows[#rows + 1] = next_cells
        last = last + 1
      end
      local widths = {}
      for column = 1, #header do
        widths[column] = 3
        for _, values in ipairs(rows) do
          widths[column] = math.max(widths[column], vim.fn.strdisplaywidth(values[column]))
        end
      end
      local border = config.table.border
      local function border_line(left, middle, right, indicator)
        local pieces = {}
        for column, cell_width in ipairs(widths) do
          local char = indicator and config.table.align[alignment[column]] or border[11]
          pieces[column] = char:rep(cell_width + config.table.padding * 2)
        end
        return left .. table.concat(pieces, middle) .. right
      end
      local top = border_line(border[1], border[2], border[3])
      mark(
        "table_border",
        row - 1,
        0,
        { virt_lines = { { { top, config.table.highlight } } }, virt_lines_above = true }
      )
      local function formatted(values)
        local rendered = {}
        for column, value in ipairs(values) do
          local missing = widths[column] - vim.fn.strdisplaywidth(value)
          local left, right = 0, missing
          if alignment[column] == "right" then
            left, right = missing, 0
          elseif alignment[column] == "center" then
            left, right = math.floor(missing / 2), math.ceil(missing / 2)
          end
          rendered[column] = (" "):rep(config.table.padding + left) .. value .. (" "):rep(config.table.padding + right)
        end
        return border[10] .. table.concat(rendered, border[10]) .. border[10]
      end
      replace("table_header", row - 1, 0, #lines[row], formatted(header), config.table.head)
      replace(
        "table_alignment",
        row,
        0,
        #lines[row + 1],
        border_line(border[4], border[5], border[6], true),
        config.table.highlight
      )
      for index = 2, #rows do
        local source_row = row + index
        replace("table_row", source_row - 1, 0, #lines[source_row], formatted(rows[index]), config.table.row)
      end
      local bottom = border_line(border[7], border[8], border[9])
      mark("table_border", last - 1, 0, { virt_lines = { { { bottom, config.table.highlight } } } })
      for table_row = row, last do
        skip[table_row] = true
      end
      row = last + 1
    else
      row = row + 1
    end
  end

  -- Indentation-scoped Sly containers.
  local containers = {}
  for line_number, line in ipairs(lines) do
    local visual_indent, byte_indent = indent_width(line)
    if not line:match("^%s*$") then
      while #containers > 0 and visual_indent <= containers[#containers].indent do
        table.remove(containers)
      end
    end
    for _, container in ipairs(containers) do
      mark("container_continuation", line_number - 1, math.min(container.byte_indent, #line), {
        virt_text = { { config.container.continuation, container.highlight } },
        virt_text_pos = "overlay",
      })
    end
    local kind = line:match("^[ \t]*:::%s*([%w_-]+)")
    if kind then
      local custom = config.container.kinds[kind] or {}
      local highlight = custom.highlight or config.container.highlight
      local icon = custom.icon or ""
      local _, finish = line:find(":::%s*[%w_-]+")
      replace(
        "container",
        line_number - 1,
        byte_indent,
        finish or #line,
        config.container.icon .. " " .. icon .. kind,
        highlight
      )
      containers[#containers + 1] = {
        indent = visual_indent,
        byte_indent = byte_indent,
        highlight = highlight,
      }
    end
  end

  local callouts = {}
  for name, callout in pairs(config.callout) do
    callouts[callout.raw:upper()] = vim.tbl_extend("force", { name = name }, callout)
  end

  for line_number, line in ipairs(lines) do
    if not skip[line_number] then
      local zero_row = line_number - 1
      local whitespace = line:match("^[ \t]*") or ""
      local indent = vim.fn.strdisplaywidth(whitespace)

      -- ATX headings and setext section titles.
      local hashes, title = line:match("^[ \t]*(#+)%s+(.+)$")
      if hashes then
        local level = math.min(#hashes, 6)
        local icon = config.heading.icons[level]
        local foreground = config.heading.foregrounds[level]
        local background = config.heading.backgrounds[level]
        local padding = (" "):rep(config.heading.padding)
        replace("heading", zero_row, #whitespace, #whitespace + #hashes + 1, padding .. icon, foreground)
        mark("heading_background", zero_row, 0, {
          line_hl_group = background,
        })
        if config.heading.border and level <= 2 then
          local border_width = component_width(config.heading.width, math.max(1, width - indent))
          mark("heading_border", zero_row, 0, {
            virt_lines = { { { config.heading.border_char:rep(border_width), foreground } } },
          })
        end
      elseif lines[line_number + 1] and lines[line_number + 1]:match("^===+%s*{?.*$") and line:match("%S") then
        local foreground = config.heading.foregrounds[1]
        mark("section_heading_icon", zero_row, 0, {
          virt_text = { { config.heading.icons[1], foreground } },
          virt_text_pos = "inline",
        })
        replace(
          "section_marker",
          line_number,
          0,
          #lines[line_number + 1],
          config.heading.border_char:rep(width),
          foreground
        )
        mark("section_heading", zero_row, 0, {
          line_hl_group = config.heading.backgrounds[1],
        })
      end

      -- Slide ends are the Sly equivalent of thematic breaks.
      if line:match("^[ \t]*%-%-%-%s*{?.*$") then
        local slide_width = component_width(config.slide.width, math.max(1, width - indent))
        replace("slide", zero_row, #whitespace, #line, config.slide.icon:rep(slide_width), config.slide.highlight)
      end

      -- Block quotes and GitHub / Obsidian callouts.
      local quote_start, _, _, quote_marks, quote_body = line:find("^([ \t]*)(>+)%s?(.*)$")
      if quote_start then
        local marker_start = #(line:match("^[ \t]*") or "")
        for index = 0, #quote_marks - 1 do
          replace(
            "quote",
            zero_row,
            marker_start + index,
            marker_start + index + 1,
            config.quote.icon,
            config.quote.highlight
          )
        end
        local callout_name, callout_title = quote_body:match("^%[!([%w_-]+)%]%s*(.*)$")
        local callout = callout_name and callouts[callout_name:upper()] or nil
        if callout then
          local body_start = line:find("%[!" .. vim.pesc(callout_name) .. "%]", marker_start + #quote_marks + 1)
          local body_end = body_start and body_start + #callout_name + 2 or nil
          local rendered = callout.icon .. (callout_title ~= "" and callout_title or callout.title)
          if body_start and body_end then
            replace("callout", zero_row, body_start - 1, body_end, rendered, callout.highlight)
          end
        end
      end

      -- Lists and checkbox states.
      local marker_start, marker_end, marker = line:find("^[ \t]*([%-%+%*])%s+")
      if not marker_start then
        marker_start, marker_end, marker = line:find("^[ \t]*(%d+%.)%s+")
      end
      if marker_start then
        local marker_col = #whitespace
        local after_marker = line:sub(marker_end + 1)
        local state_raw = after_marker:match("^(%[[^%]]%])")
        local checkbox
        for _, candidate in ipairs({ config.checkbox.unchecked, config.checkbox.checked }) do
          if state_raw and candidate.raw:lower() == state_raw:lower() then
            checkbox = candidate
          end
        end
        for _, candidate in pairs(config.checkbox.custom) do
          if state_raw and candidate.raw:lower() == state_raw:lower() then
            checkbox = candidate
          end
        end
        if checkbox then
          replace("checkbox", zero_row, marker_col, marker_end + #state_raw, checkbox.icon, checkbox.highlight)
        elseif marker:match("^%d") then
          replace("ordered_list", zero_row, marker_col, marker_end - 1, marker, config.bullet.highlight)
        else
          local level = math.floor(indent / math.max(vim.bo[buf].shiftwidth, 2)) + 1
          local icon = config.bullet.icons[((level - 1) % #config.bullet.icons) + 1]
          replace(
            "bullet",
            zero_row,
            marker_col,
            marker_end - 1,
            icon .. (" "):rep(config.bullet.padding),
            config.bullet.highlight
          )
        end
      end

      -- Inline code spans.
      local search = 1
      while true do
        local start_col, end_col, content = line:find("`([^`]+)`", search)
        if not start_col then
          break
        end
        replace("code_inline", zero_row, start_col - 1, end_col, " " .. content .. " ", config.code.inline)
        search = end_col + 1
      end

      -- Links, excluding image syntax.
      search = 1
      while true do
        local start_col, end_col, label, destination = line:find("%[([^%]]-)%]%(([^%)%s]+)%)", search)
        if not start_col then
          break
        end
        if start_col == 1 or line:sub(start_col - 1, start_col - 1) ~= "!" then
          local icon = config.link.icon
          for _, custom in ipairs(config.link.custom) do
            if destination:match(custom.pattern) then
              icon = custom.icon
              break
            end
          end
          replace("link", zero_row, start_col - 1, end_col, icon .. label, config.link.highlight)
        end
        search = end_col + 1
      end
    end
  end

  return counts
end

local function render(buf)
  local state = states[buf]
  if not state or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
  if not state.enabled or not mode_enabled(state.config) then
    state.counts = {}
    return
  end
  state.counts = renderer(buf, state.config)
end

local function schedule(buf)
  local state = states[buf]
  if not state then
    return
  end
  state.generation = state.generation + 1
  local generation = state.generation
  vim.defer_fn(function()
    local current = states[buf]
    if current and current.generation == generation then
      render(buf)
    end
  end, state.config.debounce)
end

function M.attach(buf, opts)
  buf = normalize_buf(buf)
  local config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  local state = states[buf]
  if state then
    state.config = config
    state.enabled = config.enabled
    schedule(buf)
    return
  end
  states[buf] = { config = config, enabled = config.enabled, generation = 0, counts = {} }
  local group = vim.api.nvim_create_augroup("slydes.render." .. buf, { clear = true })
  vim.api.nvim_create_autocmd({ "InsertEnter", "InsertLeave", "ModeChanged", "BufWinEnter" }, {
    group = group,
    buffer = buf,
    callback = function()
      schedule(buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "WinResized", "ColorScheme" }, {
    group = group,
    callback = function()
      setup_highlights()
      schedule(buf)
    end,
  })
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      schedule(buf)
    end,
    on_detach = function()
      states[buf] = nil
    end,
  })
  setup_highlights()
  schedule(buf)
end

function M.toggle(buf)
  buf = normalize_buf(buf)
  local state = states[buf]
  if not state then
    return false
  end
  state.enabled = not state.enabled
  render(buf)
  return state.enabled
end

function M.refresh(buf)
  buf = normalize_buf(buf)
  schedule(buf)
end

function M.status(buf)
  buf = normalize_buf(buf)
  local state = states[buf]
  return state and vim.deepcopy(state.counts) or {}
end

function M.clear(buf)
  buf = normalize_buf(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
  end
end

M.defaults = defaults
M.namespace = namespace

return M
