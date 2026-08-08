-- WiRe Rewired shared protocol metadata
--
-- IMPORTANT: the proven packet/encryption implementation still lives inside
-- the working Server/Client/Trigger/Sensor/Tablet programs. This module records
-- common names for new development code without changing that compatibility path.

local protocol = {
  name = "WiRe",
  product = "WiRe Rewired",
  version = "3.1.0-dev",
  channel = "development",
}

protocol.programs = {
  device = "WiRe",
  trigger = "WiReTrigger",
  server = "WiReServer",
}

protocol.commands = {
  OPEN = true,
  CLOSED = true,
  ON = true,
  OFF = true,
  LOCKED = true,
  UNLOCK = true,
  WiReQRY = true,
}

protocol.triggerRequests = {
  LISTGROUPS = true,
  LISTDEVICES = true,
  SERVERINFO = true,
}

function protocol.legacyNetwork(colour)
  return "WiRe" .. tostring(colour or "")
end

return protocol
