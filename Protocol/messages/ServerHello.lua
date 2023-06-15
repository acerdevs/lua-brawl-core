local PiranhaMessage = require("protocol.piranhamessage")
local ServerHelloMessage = {}
ServerHelloMessage.__index = ServerHelloMessage

function ServerHelloMessage:new()
    local self = {}
    setmetatable(self, ServerHelloMessage)
    self.id = 20100
    return self
end

function ServerHelloMessage:encode()
    self.stream:writeInt(24) -- session key
    for i = 1, 24 do
        self.stream:writeByte(1)
    end
end

return ServerHelloMessage