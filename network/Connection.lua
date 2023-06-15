local socket = require("socket")
local Messaging = require("network.messaging")
local MessageFactory = require("protocol.messageFactory")

local Connection = {}
Connection.__index = Connection

function Connection.new(sock)
    local self = setmetatable({}, Connection)
    self.socket = sock
    self.messaging = Messaging.new(self)
    return self
end

function Connection:send(buffer)
    self.socket:send(buffer)
end

function Connection:receive_message()
    local header = self.socket:receive(7)
    if header ~= nil then
        local message_type, length, version = Messaging.readHeader(header)
        local payload = self.socket:receive(length)
        print(string.format("received message %d, length %d, version %d", message_type, length, version))
        local message = MessageFactory.create_message_by_type(message_type)
        if message ~= nil then
            message.stream.buffer = payload
            message:decode()
            message:process(self)
        end
        return 0
    end
    return -1
end

return Connection