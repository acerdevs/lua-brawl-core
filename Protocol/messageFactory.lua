local ClientHelloMessage = require ("protocol.messages.clientHello.ClientHelloMessage")

local packets = {
    [10100] = ClientHelloMessage
}

local MessageFactory = {}

function MessageFactory.create_message_by_type(m_type)
    if packets[m_type] then
        return packets[m_type]()
    end
    return nil
end