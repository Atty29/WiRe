-- WiRe Rewired legacy configuration bridge
--
-- Provides a narrow compatibility layer while the original monolithic Client
-- is being dismantled. Only the Client configuration file is intercepted.
-- All other filesystem access passes directly through to ComputerCraft's fs API.
--
-- This lets the existing Client keep its proven behaviour while actual config
-- reads/writes are owned by the shared configuration service.

local bridge = {}

local function loadModule(candidates)
  for i = 1, #candidates do
    if fs.exists(candidates[i]) then
      local ok, module = pcall(dofile, candidates[i])
      if ok and type(module) == "table" then return module end
    end
  end
  return nil
end

local config = loadModule({ "wire/shared/config.lua", "shared/config.lua" })
local componentConfig = loadModule({ "wire/shared/component_config.lua", "shared/component_config.lua" })

local function reader(raw)
  local closed = false
  local pos = 1
  return {
    readAll = function()
      if closed then error("attempt to use a closed file", 2) end
      pos = #raw + 1
      return raw
    end,
    readLine = function()
      if closed then error("attempt to use a closed file", 2) end
      if pos > #raw then return nil end
      local s, e = raw:find("\n", pos, true)
      local line
      if s then
        line = raw:sub(pos, s - 1)
        pos = e + 1
      else
        line = raw:sub(pos)
        pos = #raw + 1
      end
      return line
    end,
    close = function() closed = true end,
  }
end

local function writer(path)
  local closed = false
  local chunks = {}
  local function ensureOpen()
    if closed then error("attempt to use a closed file", 3) end
  end
  return {
    write = function(value)
      ensureOpen()
      chunks[#chunks + 1] = tostring(value or "")
    end,
    writeLine = function(value)
      ensureOpen()
      chunks[#chunks + 1] = tostring(value or "") .. "\n"
    end,
    flush = function() ensureOpen() end,
    close = function()
      ensureOpen()
      closed = true
      local raw = table.concat(chunks)
      local ok, value = pcall(textutils.unserialize, raw)
      if not ok or type(value) ~= "table" then
        error("WiRe Rewired config bridge refused invalid Client configuration", 2)
      end
      local saved, err = config.save(path, value)
      if saved == false then error("WiRe Rewired config bridge save failed: " .. tostring(err), 2) end
    end,
  }
end

function bridge.install(component)
  if component ~= "client" or not config or not componentConfig then
    return function() end
  end

  local def = componentConfig.definition("client")
  if not def then return function() end end

  local originalOpen = fs.open
  fs.open = function(path, mode)
    if path ~= def.path then return originalOpen(path, mode) end

    if mode == "r" then
      local value, err = config.load(def.path, def.defaults(), {
        requireExisting = true,
        migrate = def.migrate,
        saveMigrated = true,
      })
      if not value then return nil end
      return reader(textutils.serialize(value))
    elseif mode == "w" then
      return writer(def.path)
    end

    return originalOpen(path, mode)
  end

  return function()
    fs.open = originalOpen
  end
end

return bridge
