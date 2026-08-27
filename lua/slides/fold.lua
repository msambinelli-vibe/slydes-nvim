local M = {}

local cache = {}

local function indent(line)
  local prefix = line:match("^[ \t]*") or ""
  local spaces = 0
  for char in prefix:gmatch(".") do
    spaces = spaces + (char == "\t" and 4 or 1)
  end
  return spaces
end

local function is_blank(line)
  return line:match("^%s*$") ~= nil
end

local function is_section_marker(line)
  return line:match("^===+%s*{?.*$") ~= nil
end

local function is_slide_end(line)
  return line:match("^%-%-%-%s*{?.*$") ~= nil
end

local function trim_blank_end(lines, first, last)
  while last > first and is_blank(lines[last]) do
    last = last - 1
  end
  return last
end

local function first_content(lines, first, last)
  while first <= last and is_blank(lines[first]) do
    first = first + 1
  end
  return first
end

local function add_range(ranges, kind, first, last, level, label)
  if first < last then
    ranges[#ranges + 1] = {
      kind = kind,
      first = first,
      last = last,
      level = level,
      label = label,
    }
  end
end

local function scan(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local ranges = {}
  local section_starts = {}
  local metadata_end

  if vim.trim(lines[1] or "") == "+++" then
    for line = 2, #lines do
      if vim.trim(lines[line]) == "+++" then
        metadata_end = line
        add_range(ranges, "metadata", 1, line, 1, "metadata")
        break
      end
    end
  end

  for line = 1, #lines - 1 do
    if indent(lines[line]) == 0 and not is_blank(lines[line]) and is_section_marker(lines[line + 1]) then
      section_starts[#section_starts + 1] = line
    end
  end

  for index, first in ipairs(section_starts) do
    local last = (section_starts[index + 1] or (#lines + 1)) - 1
    last = trim_blank_end(lines, first, last)
    add_range(ranges, "section", first, last, 1, vim.trim(lines[first]))
  end

  local section_title = {}
  local after_section = {}
  for _, first in ipairs(section_starts) do
    section_title[first] = true
    after_section[first + 1] = true
  end

  local boundary = (metadata_end or 0) + 1
  for line = boundary, #lines do
    if section_title[line] then
      boundary = line + 2
    elseif is_slide_end(lines[line]) and indent(lines[line]) == 0 then
      local first = first_content(lines, boundary, line)
      if first <= line then
        local in_section = false
        for _, start in ipairs(section_starts) do
          if start < first then
            in_section = true
          else
            break
          end
        end
        local label = vim.trim(lines[first]):gsub("^#+%s*", "")
        add_range(ranges, "slide", first, line, in_section and 2 or 1, label)
      end
      boundary = line + 1
    end
  end

  local containers = {}
  for line, text in ipairs(lines) do
    local whitespace, kind = text:match("^([ \t]*):::%s*([%w_-]+)")
    if whitespace and kind then
      local current_indent = indent(whitespace)
      local last = #lines
      for candidate = line + 1, #lines do
        local next_line = lines[candidate]
        if not is_blank(next_line) and indent(next_line) <= current_indent then
          last = candidate - 1
          break
        end
      end
      last = trim_blank_end(lines, line, last)
      if last > line then
        containers[#containers + 1] = {
          first = line,
          last = last,
          indent = current_indent,
          kind = kind,
        }
      end
    end
  end

  for _, container in ipairs(containers) do
    local base = 0
    for _, range in ipairs(ranges) do
      if range.first <= container.first and range.last >= container.last then
        base = math.max(base, range.level)
      end
    end
    local parents = 0
    for _, other in ipairs(containers) do
      if other.first < container.first and other.last >= container.last and other.indent < container.indent then
        parents = parents + 1
      end
    end
    add_range(ranges, "container", container.first, container.last, base + parents + 1, container.kind)
  end

  local values, starts, ends = {}, {}, {}
  for line = 1, #lines do
    values[line] = 0
  end
  for _, range in ipairs(ranges) do
    starts[range.first] = math.max(starts[range.first] or 0, range.level)
    ends[range.last] = math.min(ends[range.last] or math.huge, range.level)
    for line = range.first, range.last do
      values[line] = math.max(values[line], range.level)
    end
  end

  return {
    tick = vim.api.nvim_buf_get_changedtick(buf),
    values = values,
    starts = starts,
    ends = ends,
    ranges = ranges,
  }
end

local function state(buf)
  if not cache[buf] or cache[buf].tick ~= vim.api.nvim_buf_get_changedtick(buf) then
    cache[buf] = scan(buf)
  end
  return cache[buf]
end

function M.foldexpr()
  local info = state(0)
  local line = vim.v.lnum
  if info.starts[line] then
    return ">" .. info.starts[line]
  end
  if info.ends[line] then
    return "<" .. info.ends[line]
  end
  return info.values[line] or 0
end

function M.foldtext()
  local info = state(0)
  local first = vim.v.foldstart
  local label = vim.trim(vim.fn.getline(first)):gsub("^#+%s*", "")
  local kind = "block"
  for _, range in ipairs(info.ranges) do
    if range.first == first then
      kind = range.kind
      label = range.label ~= "" and range.label or label
      break
    end
  end
  return ("  %s: %s  ·  %d lines "):format(kind, label, vim.v.foldend - first + 1)
end

function M.clear(buf)
  cache[buf or 0] = nil
end

return M
