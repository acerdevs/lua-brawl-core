local ByteStream = require("datastream.bytestream")

local PiranhaMessage = {}
PiranhaMessage.__index = PiranhaMessage

function PiranhaMessage:new()
    local self = setmetatable({}, PiranhaMessage)
    self.id = 0
    self.version = 0
    self.stream = ByteStream:new()
    return self
end

function PiranhaMessage:encode() end
function PiranhaMessage:decode() end
function PiranhaMessage:process(con) end

return PiranhaMessage
#