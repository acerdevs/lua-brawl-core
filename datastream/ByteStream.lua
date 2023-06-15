local ByteStream = {}
ByteStream.__index = ByteStream

function ByteStream.new(buffer)
    local self = setmetatable({}, ByteStream)
    self.buffer = buffer or ""
    self.offset = 0
    self.bitIdx = 0
    self.currentByte = 0
    return self
end

function ByteStream:readBytes(length)
    local array = self.buffer:sub(self.offset + 1, self.offset + length)
    self.offset = self.offset + length
    return array
end

function ByteStream:readByte()
    self.bitIdx = 0
    return string.byte(self:readBytes(1))
end

function ByteStream:readInt()
    self.bitIdx = 0
    return string.unpack(">I4", self:readBytes(4))
end

function ByteStream:readBoolean()
    if self.bitIdx == 0 then
        self.currentByte = string.byte(self:readBytes(1))
    end
    local result = bit32.band(bit32.lshift(1, self.bitIdx), self.currentByte) ~= 0
    self.bitIdx = bit32.band(self.bitIdx + 1, 7)
    return result
end

function ByteStream:readString(max)
    max = max or 900000
    local length = self:readInt()
    if length < 0 and length > max then
        return nil
    end
    return self:readBytes(length)
end

function ByteStream:writeBytes(array)
    self.bitIdx = 0
    self.buffer = self.buffer .. array
    self.offset = self.offset + #array
end

function ByteStream:writeInt(value)
    self:writeBytes(string.pack(">I4", value))
end

function ByteStream:writeByte(value)
    self:writeBytes(string.char(value))
end

function ByteStream:writeString(value)
    local array = value
    self:writeInt(#array)
    self:writeBytes(array)
end

function ByteStream:writeBoolean(value)
    if self.bitIdx == 0 then
        self.buffer = self.buffer .. string.char(0)
    end
    if value then
        self.buffer = self.buffer:sub(1, self.offset) .. string.char(bit32.bor(string.byte(self.buffer:sub(self.offset + 1, self.offset + 1)), bit32.lshift(1, self.bitIdx))) .. self.buffer:sub(self.offset + 2)
    end
    self.bitIdx = bit32.band(self.bitIdx + 1, 7)
end

function ByteStream.convert_unsigned_to_signed(unsigned)
    return string.unpack(">i4", string.pack(">I4", unsigned))
end

function ByteStream:readVInt()
    local byte = self:readByte()
    if bit32.band(byte, 0x40) ~= 0 then
        local result = bit32.band(byte, 0x3f)
        if bit32.band(byte, 0x80) ~= 0 then
            byte = self:readByte()
            result = bit32.bor(result, bit32.lshift(bit32.band(byte, 0x7f), 6))
            if bit32.band(byte, 0x80) ~= 0 then
                byte = self:readByte()
                result = bit32.bor(result, bit32.lshift(bit32.band(byte, 0x7f), 13))
                if bit32.band(byte, 0x80) ~= 0 then
                    byte = self:readByte()
                    result = bit32.bor(result, bit32.lshift(bit32.band(byte, 0x7f), 20))
                    if bit32.band(byte, 0x80) ~= 0 then
                        byte = self:readByte()
                        result = bit32.bor(result, bit32.lshift(bit32.band(byte, 0x7f), 27))
                        return ByteStream.convert_unsigned_to_signed(bit32.bor(result, 0x80000000))
                    end
                    return ByteStream.convert_unsigned_to_signed(bit32.bor(result, 0xF8000000))
                end
                return ByteStream.convert_unsigned_to_signed(bit32.bor(result, 0xFFF00000))
            end
            return ByteStream.convert_unsigned_to_signed(bit32.bor(result, 0xFFFFE000))
        end
        return ByteStream.convert_unsigned_to_signed(bit32.bor(result, 0xFFFFFFC0))
    else
        local result = bit32.band(byte, 0x3f)
        if bit32.band(byte, 0x80) ~= 0 then
            byte = self:readByte()
            result = bit32.bor(result, bit32.lshift(bit32.band(byte, 0x7f), 6))
            if bit32.band(byte, 0x80) ~= 0 then
                byte = self:readByte()
                result = bit32.bor(result, bit32.lshift(bit32.band(byte, 0x7f), 13))
                if bit32.band(byte, 0x80) ~= 0 then
                    byte = self:readByte()
                    result = bit32.bor(result, bit32.lshift(bit32.band(byte, 0x7f), 20))
                    if bit32.band(byte, 0x80) ~= 0 then
                        byte = self:readByte()
                        result = bit32.bor(result, bit32.lshift(bit32.band(byte, 0x7f), 27))
                    end
                end
            end
        end
        return result
    end
end

function ByteStream:writeVInt(value)
    local tmp = bit32.band(bit32.rshift(value, 25), 0x40)
    local flipped = bit32.bxor(value, bit32.rshift(value, 31))
    tmp = bit32.bor(tmp, bit32.band(value, 0x3F))
    value = bit32.rshift(value, 6)
    flipped = bit32.rshift(flipped, 6)
    if flipped == 0 then
        self:writeByte(tmp)
        return
    end
    self:writeByte(bit32.bor(tmp, 0x80))
    flipped = bit32.rshift(flipped, 7)
    local r = 0
    if flipped ~= 0 then
        r = 0x80
    end
    self:writeByte(bit32.bor(bit32.band(value, 0x7F), r))
    value = bit32.rshift(value, 7)
    while flipped ~= 0 do
        flipped = bit32.rshift(flipped, 7)
        r = 0
        if flipped ~= 0 then
            r = 0x80
        end
        self:writeByte(bit32.bor(bit32.band(value, 0x7F), r))
        value = bit32.rshift(value, 7)
    end
end

return ByteStream

--[[
local bs = ByteStream.new()
bs:writeVInt(0xFFFFFFFF)
print(bs.buffer:byte(1, #bs.buffer))
print(bs:readVInt())
]]