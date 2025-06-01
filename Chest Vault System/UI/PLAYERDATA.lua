PLAYERDATA = {}
local instances = {} -- Track all created instances

TABLE_TYPE = {
    number = 17,
    string = 18,
    boolean = 19,
}

local function bitXOR(a, b)
    local result = 0
    local bit = 1
    while a > 0 or b > 0 do
        local aBit = a % 2
        local bBit = b % 2
        if aBit ~= bBit then
            result = result + bit
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bit = bit * 2
    end
    return result
end

local function xorCrypt(data, key)
    local output = {}
    local keyLen = #key
    local keyIndex = 1
    
    for i = 1, #data do
        local byte = string.byte(data, i)
        local keyByte = string.byte(key, keyIndex)
        output[i] = string.char(bitXOR(byte, keyByte))
        
        keyIndex = keyIndex + 1
        if keyIndex > keyLen then
            keyIndex = 1
        end
    end
    
    return table.concat(output)
end

-- Create a player data handler object
local PlayerDataHandler = {}
PlayerDataHandler.__index = PlayerDataHandler

function PlayerDataHandler.new(tableType, tableName, playerid)
    local self = setmetatable({}, PlayerDataHandler)
    self.tableType = tableType
    self.tableName = tableName
    self.playerid = playerid
    self.logEnabled = false
    self.instanceId = #instances + 1
    instances[self.instanceId] = self
    return self
end

-- Encryption method
function PlayerDataHandler:Encrypt(val, key)
    if type(val) ~= "string" then
        val = tostring(val)
    end
    self:_log(string.format("Encrypting value (length: %d)", #val))
    local encrypted = xorCrypt(val, key)
    return encrypted
end

-- Decryption method
function PlayerDataHandler:Decrypt(val, key)
    if type(val) ~= "string" then
        return val -- Can't decrypt non-string values
    end
    self:_log(string.format("Decrypting value (length: %d)", #val))
    local decrypted = xorCrypt(val, key)
    return decrypted
end

-- Encodes a table into the string format
function PlayerDataHandler:EncodeTable(tbl)
    if type(tbl) ~= "table" then
        self:_log("EncodeTable: Input is not a table")
        return nil
    end
    
    local parts = {}
    
    -- Handle array-like tables
    if #tbl > 0 then
        for i, v in ipairs(tbl) do
            table.insert(parts, tostring(v))
        end
        return table.concat(parts, " | ")
    else
        -- Handle key-value tables
        for k, v in pairs(tbl) do
            table.insert(parts, tostring(k) .. " ? " .. tostring(v))
        end
        return table.concat(parts, " | ")
    end
end

-- Decodes a string back into a table
function PlayerDataHandler:DecodeTable(str)
    if type(str) ~= "string" then
        self:_log("DecodeTable: Input is not a string")
        return nil
    end
    
    local result = {}
    local isKeyValue = false
    
    -- Split by " | " first
    local segments = {}
    for segment in str:gmatch("([^|]+)") do
        table.insert(segments, segment:match("^%s*(.-)%s*$"))
    end
    
    -- Process each segment
    for _, segment in ipairs(segments) do
        local key, value = segment:match("^(.*)%s?%?%s?(.*)$")
        
        if key and value then
            -- Key-value pair found
            isKeyValue = true
            key = key:match("^%s*(.-)%s*$")
            value = value:match("^%s*(.-)%s*$")
            
            -- Convert numeric values to numbers
            if tonumber(value) then
                value = tonumber(value)
            elseif value == "true" then
                value = true
            elseif value == "false" then
                value = false
            end
            
            result[key] = value
        else
            -- Simple value
            local cleanValue = segment:match("^%s*(.-)%s*$")
            
            -- Convert numeric values to numbers
            if tonumber(cleanValue) then
                table.insert(result, tonumber(cleanValue))
            elseif cleanValue == "true" then
                table.insert(result, true)
            elseif cleanValue == "false" then
                table.insert(result, false)
            else
                table.insert(result, cleanValue)
            end
        end
    end
    
    self:_log(string.format("Decoded table (%s): %d items", 
          isKeyValue and "key-value" or "array", #result + (isKeyValue and 0 or 0)))
    
    return result
end


-- Add a destructor method to clean up
function PlayerDataHandler:destroy()
    instances[self.instanceId] = nil
    -- Clear all references
    for k in pairs(self) do
        self[k] = nil
    end
    return true
end

-- Enable/disable logging
function PlayerDataHandler:enableLog(enable)
    self.logEnabled = enable == nil or enable  -- Default to true if no parameter
    local status = self.logEnabled and "enabled" or "disabled"
    print(string.format("[PlayerData] Logging %s for player %d, table '%s'", 
          status, self.playerid, self.tableName))
    return self  -- Return self for method chaining
end

-- Internal logging function
function PlayerDataHandler:_log(message)
    if self.logEnabled then
        print(string.format("#c00008b[%s log]\n[Player %d] %s #n", 
              self.tableName, self.playerid, message))
    end
end

-- Internal logging function
function PlayerDataHandler:_error(message)
    if self.logEnabled then
        print(string.format("#c8B0000[%s error]\n[Player %d] %s #n", 
              self.tableName, self.playerid, message))
    end
end

function PlayerDataHandler:Length()
    self:_log("Getting Length")
    local r, length = Valuegroup:getGrouplengthByName(self.tableType, self.tableName, self.playerid);
    self:_log(string.format("Length is %d", length))
    return r , length
end

function PlayerDataHandler:readAll()
    self:_log("Reading all values")
    local r, values = Valuegroup:getAllGroupItem(self.tableType, self.tableName, self.playerid)
    if r then
        self:_log(string.format("Read %d values: %s", #values, table.concat(values, ", ")))
    else
        self:_log("Failed to read values")
    end
    return r, values
end

function PlayerDataHandler:newIndex(index, inVal)
    self:_log(string.format("Setting index %d to value: %s", index, tostring(inVal)))
    local r = Valuegroup:setValueNoByName(self.tableType, self.tableName, index, inVal, self.playerid)
    self:_log(r and "Success" or "Failed")
    return r
end

function PlayerDataHandler:updateIndex(index, inVal)
    self:_log(string.format("Setting index %d to value: %s", index, tostring(inVal)))
    local r = Valuegroup:setValueNoByName(self.tableType, self.tableName, index, inVal, self.playerid)
    self:_log(r and "Success" or "Failed")
    return r
end

function PlayerDataHandler:insertIndex(index,newVal)
    self:_log(string.format("Updating index %d to value: %s", index, tostring(newVal)))
    local r = Valuegroup:insertValueByName(self.tableType, self.tableName, index, newVal, self.playerid)
    self:_log(r and "Success" or "Failed")
    return r 
end

function PlayerDataHandler:readRandomIndex()
    self:_log("Reading random index")
    local r, value = Valuegroup:getRandomValueByName(self.tableType,self.tableName,self.playerid);
    self:_log(string.format("Read random value: %s", tostring(value)))
    return r, value
end

function PlayerDataHandler:readIndex(index)
    self:_log(string.format("Reading index %d", index))
    local r, value = Valuegroup:getValueNoByName(self.tableType, self.tableName, index, self.playerid)
    if value then 
        self:_log(string.format("Read value: %s", tostring(value)))
    else
        self:_error(string.format("Failed to read value at index %d",tostring(index)));
    end 
    return value
end

function PlayerDataHandler:replaceVal(oldVal, newVal)
    self:_log(string.format("Updating value '%s' to '%s'", tostring(oldVal), tostring(newVal)))
    local r = Valuegroup:replaceValueByName(self.tableType, self.tableName, oldVal, newVal, self.playerid)
    self:_log(r and "Success" or "Failed")
    return r
end

function PlayerDataHandler:autoIndex(addVal)
    self:_log(string.format("Auto-adding value: %s", tostring(addVal)))
    local r = Valuegroup:insertInGroupByName(self.tableType, self.tableName, addVal, self.playerid)
    self:_log(r and "Success" or "Failed")
    return r
end

function PlayerDataHandler:deleteIndex(index)
    self:_log(string.format("Deleting index %d", index))
    local r = Valuegroup:deleteNoByName(self.tableType, self.tableName, index, self.playerid)
    self:_log(r and "Success" or "Failed")
    return r
end

function PlayerDataHandler:deleteValue(value)
    self:_log(string.format("Deleting value '%s'", tostring(value)))
    local r = Valuegroup:deleteValueByName(self.tableType, self.tableName, value, self.playerid)
    self:_log(r and "Success" or "Failed")
    return r
end

function PlayerDataHandler:sort(sortType)
    self:_log(string.format("Sorting table '%s' by '%s'", self.tableName, sortType))
    local r = Valuegroup:sortGroupByName(self.tableType,self.tableName,sortType,self.playerid)
    self:_log(r and "Success" or "Failed")
    return r
end

function PlayerDataHandler:hasValue(value)
    self:_log(string.format("Checking if value '%s' exists", tostring(value)))
    local r = Valuegroup:hasValueByName(self.tableType, self.tableName, value, self.playerid)
    self:_log(r and "Success" or "Failed")
    return r 
end

function PlayerDataHandler:hasIndex(index)
    self:_log(string.format("Checking if index %d exists", index))
    local r = Valuegroup:hasNoByName(self.tableType, self.tableName, index, self.playerid)
    self:_log(r and "Success" or "Failed")
    return r
end

function PlayerDataHandler:countValue(value)
    self:_log(string.format("Counting value '%s'", tostring(value)))
    local r , count = Valuegroup:getValueCountByName(self.tableType, self.tableName, value, self.playerid) 
    self:_log(r and "Success" or "Failed")
    return count
end

function PlayerDataHandler:lookFirst(value)
    self:_log(string.format("look First value '%s'", tostring(value)))
    local r , index = Valuegroup:getGroupNoByValue(self.tableType, self.tableName, value, self.playerid)
    self:_log(r and "Success" or "Failed")
    return r , index 
end

-- Metatable for the PLAYERDATA global table
setmetatable(PLAYERDATA, {
    __call = function(_, tableType, tableName, playerid)
        return PlayerDataHandler.new(tableType, tableName, playerid)
    end,
    
    __tostring = function()
        local count = 0
        for _ in pairs(instances) do count = count + 1 end
        return string.format("PLAYERDATA manager (%d active instances)", count)
    end,
    
    __len = function()
        local count = 0
        for _ in pairs(instances) do count = count + 1 end
        return count
    end
})

-- Function to clear all instances from memory
function PLAYERDATA.clearAll()
    local count = 0
    for id, instance in pairs(instances) do
        instance:destroy()
        count = count + 1
    end
    return count
end

-- Function to get instance count
function PLAYERDATA.instanceCount()
    local count = 0
    for _ in pairs(instances) do count = count + 1 end
    return count
end