local PiranhaMessage = require("protocol.PiranhaMessage")

local Messaging = {}

function Messaging:new(con)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.connection = con
    return o
end

function Messaging:send_message(message)
    if #message.stream.buffer == 0 then
        message:encode()
    end
    local header = Messaging.writeHeader(message.id, #message.stream.buffer, message.version)
    self.connection:send(header .. message.stream.buffer)
    print("sent message with id " .. message.id .. ", length: " .. #message.stream.buffer)
end

function Messaging.writeHeader(type, length, version)
    local buffer = ""
    buffer = buffer .. string.char(math.floor(type / 256)) .. string.char(type % 256)
    buffer = buffer .. string.char(math.floor(length / 65536)) .. string.char(math.floor(length / 256) % 256) .. string.char(length % 256)
    buffer = buffer .. string.char(math.floor(version / 256)) .. string.char(version % 256)
    return buffer
end

function Messaging.readHeader(buffer)
    return string.byte(buffer, 1) * 256 + string.byte(buffer, 2), string.byte(buffer, 3) * 65536 + string.byte(buffer, 4) * 256 + string.byte(buffer, 5), string.byte(buffer, 6) * 256 + string.byte(buffer, 7)
end

return Messaging