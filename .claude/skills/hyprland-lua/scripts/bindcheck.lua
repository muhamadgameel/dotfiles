-- bindcheck.lua - load a keybind file outside Hyprland, against a stand-in for hl that records.
--
--   XDG_RUNTIME_DIR=<scratch dir> lua bindcheck.lua <keybinds.lua>
--
-- Prints every hl.bind call (keys, action, options), sorted: diff the output for two versions
-- of the file to see which binds a change touched. If the file returns a palette, each line of
-- the list it wrote must run the action it names, or this exits with an error.

local path = assert(arg[1], "usage: XDG_RUNTIME_DIR=<scratch dir> lua bindcheck.lua <keybinds.lua>")
local runtime = os.getenv("XDG_RUNTIME_DIR") or ""
-- The file writes its list there; the live one must stay the running config's.
assert(not runtime:find("^/run/user/"), "point XDG_RUNTIME_DIR at a scratch directory first")

local calls, dispatched = {}, {}

local function show(value)
  if type(value) == "function" then
    return "<function>"
  elseif type(value) ~= "table" then
    return tostring(value)
  elseif value.dispatcher then
    return value.dispatcher
  end
  local keys, parts = {}, {}
  for key in pairs(value) do
    keys[#keys + 1] = key
  end
  table.sort(keys, function(a, b)
    return tostring(a) < tostring(b)
  end)
  for _, key in ipairs(keys) do
    parts[#parts + 1] = tostring(key) .. "=" .. show(value[key])
  end
  return "{" .. table.concat(parts, ",") .. "}"
end

-- hl.dsp.anything.at.all(...) gives a value that says how it was made.
local function node(name)
  return setmetatable({}, {
    __index = function(_, key)
      return node(name .. "." .. key)
    end,
    __call = function(_, ...)
      local parts = {}
      for i = 1, select("#", ...) do
        parts[i] = show((select(i, ...)))
      end
      return { dispatcher = name .. "(" .. table.concat(parts, ",") .. ")" }
    end,
  })
end

hl = {
  dsp = node("hl.dsp"),
  bind = function(keys, action, opts)
    calls[#calls + 1] = { keys = keys, action = action, opts = opts or {} }
  end,
  dispatch = function(action)
    dispatched[#dispatched + 1] = action
  end,
}
package.loaded["settings.theme"] = {
  apps = setmetatable({}, {
    __index = function(_, key)
      return "<" .. key .. ">"
    end,
  }),
}

local module = dofile(path)

local lines = {}
for _, call in ipairs(calls) do
  lines[#lines + 1] = call.keys .. "\t" .. show(call.action) .. "\t" .. show(call.opts)
end
table.sort(lines)
print(table.concat(lines, "\n"))

if type(module) ~= "table" or not module.run then
  return
end

local index, previous = 0, ""
for line in io.lines(runtime .. "/hypr-palette") do
  local description, keys = line:match("^(.-)\t(.*)$")
  assert(description and description ~= "", "bad line: " .. line)
  assert(previous <= line, "not sorted at: " .. line)
  previous = line

  module.run(index)
  assert(#dispatched == index + 1, "nothing ran for: " .. line)
  local ran = dispatched[#dispatched]
  if keys == "" then
    assert(type(ran) == "table" and ran.dispatcher:find("^hl%.dsp%.exec_cmd%("), "not a command: " .. line)
  else
    local bound
    for _, call in ipairs(calls) do
      if call.keys == keys and call.opts.description == description then
        assert(not bound, "two binds on " .. keys)
        bound = call
      end
    end
    assert(bound, "no bind for: " .. line)
    assert(rawequal(ran, bound.action), "runs another bind's action: " .. line)
  end
  index = index + 1
end
io.stderr:write(("%d hl.bind calls; palette: %d lines, each runs its own action\n"):format(#calls, index))
