-- WiRe Rewired component registry
-- Centralises component names, labels and installed program paths.

local components = {}

components.order = { "server", "client", "trigger", "sensor", "tablet" }

components.items = {
  server = { label = "WiRe Rewired Server", path = "wire/server.lua" },
  client = { label = "WiRe Rewired Client", path = "wire/client.lua" },
  trigger = { label = "WiRe Rewired Trigger", path = "wire/trigger.lua" },
  sensor = { label = "WiRe Rewired Sensor", path = "wire/sensor.lua" },
  tablet = { label = "WiRe Rewired Tablet", path = "wire/tablet.lua" },
}

function components.isValid(name)
  return type(name) == "string" and components.items[name] ~= nil
end

function components.get(name)
  return components.items[name]
end

function components.label(name)
  local item = components.get(name)
  return item and item.label or tostring(name or "Unknown")
end

function components.path(name)
  local item = components.get(name)
  return item and item.path or nil
end

function components.exists(name)
  local path = components.path(name)
  return path ~= nil and fs.exists(path)
end

return components
