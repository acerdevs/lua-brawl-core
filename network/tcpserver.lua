local socket = require("socket")
local select = require("select")
local connection = require("network.connection")

local TcpServer = {}
TcpServer.__index = TcpServer

function TcpServer.new(addr)
    local self = setmetatable({}, TcpServer)
    self.addr = addr
    self.socket = socket.socket()
    self.socket:setblocking(0)
    self.inputs = {self.socket}
    return self
end

function TcpServer:disconnect(socket)
    if socket in self.inputs then
        print("disconnect!")
        socket:close()
        self.inputs[socket] = nil
    end
end

function TcpServer:start_accept()
    self.socket:bind(self.addr)
    self.socket:listen()
    print("TCP server started!")
    while true do
        local read_fds, write_fds, except_fds = select.select(self.inputs, {}, self.inputs) -- {} - output
        for i in read_fds do
            if i == self.socket then
                local client, addr = self.socket:accept()
                client:setblocking(0)
                print(f"new connection from {addr[0]}:{addr[1]}")
                self.inputs[client] = connection.new(client)
            else
                if i in self.inputs then
                    local result = self.inputs[client]:receive_message()
                    if result == -1 then
                        self:disconnect(i)
                    end
                end
            end
        end
    end
end

return TcpServer