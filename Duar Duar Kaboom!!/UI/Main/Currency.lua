CURRENCY = {}

-- Currency handler metatable
local CurrencyHandler = {}
CurrencyHandler.__index = CurrencyHandler

-- Your proven XOR implementation (unchanged)
local function bxor(a, b)
    local result = 0
    local bit = 1    
    while a > 0 or b > 0 do
        local a_bit = a % 2
        local b_bit = b % 2        
        if a_bit ~= b_bit then            
            result = result + bit
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bit = bit * 2
    end
    return result
end

local function crypt(input, key)
    local output = {}
    local keyLen = #key
    for i = 1, #input do
        local inputByte = input:byte(i)
        local keyByte = key:byte((i - 1) % keyLen + 1)
        local encryptedByte = bxor(inputByte, keyByte)
        table.insert(output, string.format("%02x", encryptedByte))
    end
    return table.concat(output, " ")
end

local function readcode(encryptedText, key)
    if not encryptedText or encryptedText == "" then return false end
    
    local decryptedBytes = {}
    for hexByte in encryptedText:gmatch("%S+") do
        table.insert(decryptedBytes, tonumber(hexByte, 16))
    end
    
    local decryptedStr = ""
    local keyLen = #key
    for i = 1, #decryptedBytes do
        local keyByte = key:byte((i - 1) % keyLen + 1)
        local decryptedByte = bxor(decryptedBytes[i], keyByte)
        decryptedStr = decryptedStr .. string.char(decryptedByte)
    end 
    return decryptedStr
end

-- Modified CurrencyHandler.new to include crypto
function CurrencyHandler.new(currencyName, playerid)
    local self = setmetatable({}, CurrencyHandler)
    self.currencyName = currencyName
    self.playerid = playerid
    self.storage = PLAYERDATA(TABLE_TYPE.string, currencyName, playerid)
    self.cryptoKey = "DUAR" .. playerid -- Unique key per player
    return self
end

-- Update the helper methods
function CurrencyHandler:encrypt(data)
    local serialized = self.storage:EncodeTable(data)
    return crypt(serialized, self.cryptoKey)
end

-- function CurrencyHandler:decrypt(data)
--     local decrypted = readcode(data, self.cryptoKey)
--     return decrypted and self.storage:DecodeTable(decrypted) or nil
-- end

function CurrencyHandler:decrypt(data)
    local ok, decrypted = pcall(readcode, data, self.cryptoKey)
    if not ok or type(decrypted) ~= "string" then
        return nil -- Can't decrypt
    end

    local ok2, decoded = pcall(self.storage.DecodeTable, self.storage, decrypted)
    if not ok2 or type(decoded) ~= "table" then
        return nil -- Can't decode
    end

    return decoded
end

-- Initialize or load currency data
function CurrencyHandler:load()
    local success, data = self.storage:readAll()
    if not success or #data == 0 then
        -- Initialize new currency with 0 balance and empty history
        local initialData = {0} -- First index is current balance
        self.storage:newIndex(1, self.storage:EncodeTable(initialData))
        return initialData
    end
    return data
end

-- Get current balance
function CurrencyHandler:balance()
    local data = self:load()
    -- return number of first index
    return tonumber(data[1]) or 0
end

-- Add funds with transaction record
function CurrencyHandler:gain(amount, reason)
    if amount <= 0 then return false end
    
    local data = self:load()
    data[1] = (data[1] or 0) + amount
    
    -- Record transaction (timestamp, type, amount, reason)
    local record = {
        os.time(), -- timestamp
        "GAIN",
        amount,
        reason or "No reason given"
    }
    
    self.storage:updateIndex(1, data[1]) -- Balance remains plaintext
    self.storage:autoIndex(self:encrypt(record)) -- Encrypt history
    return true
end

-- Spend funds (must have sufficient balance)
function CurrencyHandler:spend(amount, reason)
    if amount <= 0 or self:balance() < amount then return false end
    
    local data = self:load()
    data[1] = data[1] - amount
    
    -- Record transaction
     local record = {
        os.time(),
        "SPEND",
        amount,
        reason or "No reason given"
    }
    
    self.storage:updateIndex(1, data[1]) -- Balance remains plaintext
    self.storage:autoIndex(self:encrypt(record)) -- Encrypt history
    return true
end

-- Force remove funds (even if balance goes negative)
function CurrencyHandler:lost(amount, reason)
    if amount <= 0 then return false end
    
    local data = self:load()
    data[1] = data[1] - amount
    
    -- Record transaction
     local record = {
        os.time(),
        "LOST",
        amount,
        reason or "No reason given"
    }
    
    self.storage:updateIndex(1, data[1]) -- Balance remains plaintext
    self.storage:autoIndex(self:encrypt(record)) -- Encrypt history
    return true
end

-- Get transaction history (excluding current balance)
function CurrencyHandler:history()
    local data = self:load()
    local history = {}
    
    for i = 2, #data do
        local entry = self:decrypt(data[i]) -- Decrypt on read
        if entry then
            table.insert(history, entry)
        else
            -- Invalid data: optionally reset it
            self.storage:deleteIndex(i)
        end
    end
    
    return history
end

-- Read and decrypt history
function CurrencyHandler:formatHistory()
    local history = self:history()
    local formatted = {}
    
    for _, entry in ipairs(history) do
        -- No need to decrypt here - history() already does it
        -- print("Entry : ",entry);
        local timestamp, action, amount, reason = entry[1], entry[2], entry[3], entry[4]
        local date = os.date("%Y-%m-%d %H:%M:%S", tonumber(timestamp))
        table.insert(formatted, string.format("[%s] %s: %d (%s)", date, action, amount, reason))
    end
    
    return formatted
end

-- verify
function CurrencyHandler:verify(autoRepair)
    local currentBalance = self:balance()
    local calculatedBalance = 0
    local history = self:history()
    
    -- Calculate correct balance
    for process, entry in ipairs(history) do
        local action, amount = entry[2], tonumber(entry[3])
        
        if action == "GAIN" then
            calculatedBalance = calculatedBalance + amount
        else -- SPEND or LOST
            calculatedBalance = calculatedBalance - amount
        end

        if math.fmod(process,10) == 0 then 
            threadpool:wait(0.05); -- Avoid Freezing 
        end 
    end
    
    -- Compare and optionally repair
    local matched = math.abs(currentBalance - calculatedBalance) < 0.001
    if not matched and autoRepair then
        self.storage:updateIndex(1, calculatedBalance)
    end
    
    return matched, calculatedBalance
end

-- Make CURRENCY callable
setmetatable(CURRENCY, {
    __call = function(_, currencyName, playerid)
        return CurrencyHandler.new(currencyName, playerid)
    end
})