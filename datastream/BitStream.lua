
local BitStream = {}
BitStream.__index = BitStream

function BitStream.new(buff)
    local self = setmetatable({}, BitStream)
    self.buffer = buff or b''
    self.bitIndex = 0
    self.offset = 0
    return self
end

function BitStream:readBit()
    if self.offset > #self.buffer then
        print("Out of range!")
        return 0
    end
    local value = (self.buffer[self.offset] >> self.bitIndex) & 1
    self.bitIndex += 1
    if (self.bitIndex == 8) then
        self.bitIndex = 0
        self.offset += 1
    end
    return value
end

function BitStream:readBytes(length)
    local data = {}
    local i = 0
    while i < length do
        local value = 0
        local p = 0
        while p < 8 and i < length do
            value |= self:readBit() << p
            i += 1
            p += 1
        end
        data[#data + 1] = value
    end
    return string.char(unpack(data))
end

function BitStream:readPositiveInt(bitsCount)
    local data = self:readBytes(bitsCount)
    return string.unpack("<I4", data)
end

function BitStream:readInt(bitsCount)
    local v2 = 2 * self:readPositiveInt(1) - 1
    return v2 * self:readPositiveInt(bitsCount)
end

function BitStream:readPositiveVIntMax255()
    local v2 = self:readPositiveInt(3)
    return self:readPositiveInt(v2)
end

function BitStream:readPositiveVIntMax65535()
    local v2 = self:readPositiveInt(4)
    return self:readPositiveInt(v2)
end

function BitStream:readPositiveVIntMax255OftenZero()
    if self:readBoolean() then return 0 end
    return self:readPositiveVIntMax255()
end

function BitStream:readPositiveVIntMax65535OftenZero()
    if self:readBoolean() then return 0 end
    return self:readPositiveVIntMax65535()
end

function BitStream:readBoolean()
    return self:readPositiveInt(1) == 1
end

function BitStream:writeBit(data)
    if (self.bitIndex == 0) then
        self.offset += 1
        self.buffer = self.buffer .. string.char(0xff)
    end
    
    local value = self.buffer[self.offset]
    value = value & ~(1 << self.bitIndex)
    value = value | (data << self.bitIndex)
    self.buffer[self.offset] = value
    
    self.bitIndex = (self.bitIndex + 1) % 8
end

function BitStream:writeBits(bits, count)
    local i = 0
    local position = 0
    while i < count do
        local value = 0
        
        local p = 0
        while p < 8 and i < count do
            value = (bits[position] >> p) & 1
            self:writeBit(value)
            p += 1
            i += 1
        end
        position += 1
    end
end

function BitStream:writePositiveInt(value, bitsCount)
    self:writeBits(string.unpack("<I4", value), bitsCount)
end

function BitStream:writeInt(value, bitsCount)
    local val = value
    if val <= -1 then
        self:writePositiveInt(0, 1)
        val = -value
    elseif val >= 0 then
        self:writePositiveInt(1, 1)
        val = value
    end
    self:writePositiveInt(val, bitsCount)
end

function BitStream:writePositiveVInt(value, count)
    local v3 = 1
    local v7 = value
    
    if v7 ~= 0 then
        if (v7 < 1) then
            v3 = 0
        else
            local v8 = v7
            v3 = 0
            
            v3 += 1
            v8 = v8 >> 1
            
            while (v8 ~= 0) do
                v3 += 1
                v8 = v8 >> 1
            end
        end
    end
    self:writePositiveInt(v3 - 1, count)
    self:writePositiveInt(v7, v3)
end

function BitStream:writePositiveVIntMax255(value)
    self:writePositiveVInt(value, 3)
end

function BitStream:writePositiveVIntMax65535(value)
    self:writePositiveVInt(value, 4)
end

function BitStream:writePositiveVIntMax255OftenZero(value)
    if value == 0 then
        self:writePositiveInt(1, 1)
        return
    end
    self:writePositiveInt(0, 1)
    self:writePositiveVInt(value, 3)
end

function BitStream:writePositiveVIntMax65535OftenZero(value)
    if value == 0 then
        self:writePositiveInt(1, 1)
        return
    end
    self:writePositiveInt(0, 1)
    self:writePositiveVInt(value, 4)
end

function BitStream:writeBoolean(value)
    if value then self:writePositiveInt(1, 1)
    else self:writePositiveInt(0, 1) end
end

return BitStream
 
