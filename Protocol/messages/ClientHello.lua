local PiranhaMessage = require("protocol.piranhamessage")
local ServerHelloMessage = require("protocol.messages.serverHello")
local ClientHelloMessage = {}
ClientHelloMessage.__index = ClientHelloMessage

function ClientHelloMessage.new()
    local self = setmetatable({}, ClientHelloMessage)
    self.id = 10100
    return self
end

function ClientHelloMessage:decode()
    -- decode
end

function ClientHelloMessage:process(con)
    con.messaging:send_message(ServerHelloMessage.new())
end

return ClientHelloMessage