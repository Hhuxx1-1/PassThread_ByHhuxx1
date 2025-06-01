local uiid = "7509948711214717170"

local lastCached_Balance = {}
local lastCached_Time ={}

local function formatText(amount)
    amount = tonumber(amount)
    local formatted = ""
    if amount >= 1e12 then
        formatted = string.format("%.2fT", amount / 1e12) -- Display in Trillions
    elseif amount >= 1e9 then
        formatted = string.format("%.2fB", amount / 1e9) -- Display in Billions
    elseif amount >= 1e6 then
        formatted = string.format("%.2fM", amount / 1e6) -- Display in Millions
    elseif amount >= 1e3 then
        formatted = string.format("%.2fk", amount / 1e3) -- Display in Thousands
    else
        formatted = tostring(amount) -- If less than 1000, display the full amount
    end
    return formatted
end

ScriptSupportEvent:registerEvent("UPDATE", function(e)
    local playerid = e.eventobjid
    local diamonds = CURRENCY("Diamonds", playerid)
    
    local targetBalance = diamonds:balance()
    local currentDisplay = lastCached_Balance[playerid]

    -- First time setup
    if currentDisplay == nil then
        lastCached_Balance[playerid] = targetBalance
        UIZ(uiid, playerid)("Text_Value_Diamonds", 6):setText(formatText(targetBalance))
        return
    end

    -- Skip if already synced
    if currentDisplay == targetBalance then return end

    -- Calculate difference and direction
    local diff = targetBalance - currentDisplay
    local step = math.max(1, math.floor(math.abs(diff) / 10))  -- smooth step

    -- Apply direction
    if diff > 0 then
        lastCached_Balance[playerid] = math.min(currentDisplay + step, targetBalance)
    else
        lastCached_Balance[playerid] = math.max(currentDisplay - step, targetBalance)
    end
    Player:openUIView(playerid,uiid);
    -- Update UI
    local _e = UIZ(uiid, playerid)
    _e("Text_Value_Diamonds", 6):setText(formatText(lastCached_Balance[playerid]));

    lastCached_Time[playerid] = os.time();
        
    local delay = 3;

        -- Update the Inner Sub Bar; 
    threadpool:delay(delay,function()
        if os.time() - lastCached_Time[playerid] >= delay  then 
            Player:hideUIView(playerid,uiid);
        end 
    end)

    _e(); --destroy the object;
end)


CODE_TEST_REGISTER("bal",function(playerid)
    local diamonds = CURRENCY("Diamonds",playerid)
    Chat:sendSystemMsg("Balance :"..diamonds:balance());
end)

CODE_TEST_REGISTER("diamond100",function(playerid)
    local diamonds = CURRENCY("Diamonds",playerid)
    if Player:notifyGameInfo2Self(playerid,"Gain 100 Diamonds") == 0 then 
        diamonds:gain(100,"Game Test Gain Coin");
    end 
    Chat:sendSystemMsg("Balance:"..diamonds:balance());
end)

CODE_TEST_REGISTER("diamond-100",function(playerid)
    local diamonds = CURRENCY("Diamonds",playerid)
    if Player:notifyGameInfo2Self(playerid,"Lost 100 Diamonds") == 0 then 
        diamonds:lost(100,"Game Test Lost Coin");
    end 
    Chat:sendSystemMsg("Balance:"..diamonds:balance());
end)

CODE_TEST_REGISTER("diamond-s100",function(playerid)
    local diamonds = CURRENCY("Diamonds",playerid)
    if Player:notifyGameInfo2Self(playerid,"Spend 100 Diamonds") == 0 then 
        if diamonds:spend(100,"Game Test Spend Coin") then 
            Chat:sendSystemMsg("Successfully Spend")
        else 
            Chat:sendSystemMsg("Failed Spend")
        end 
    end 
    Chat:sendSystemMsg("Balance:"..diamonds:balance());
end)

CODE_TEST_REGISTER("diamondHis",function(playerid)
    local diamonds = CURRENCY("Diamonds",playerid)
    Chat:sendSystemMsg("Transaction History is printed")
    for _, entry in ipairs(diamonds:formatHistory()) do
        print(entry)
    end
end)

CODE_TEST_REGISTER("diamondVer",function(playerid)
    local diamonds = CURRENCY("Diamonds",playerid)
    Chat:sendSystemMsg("Diamonds is Being Verified");
    if diamonds:verify(true) then
        Chat:sendSystemMsg("Diamonds is Verified");
    else
        Chat:sendSystemMsg("Diamonds is Not Verified");
    end 
end)


CODE_TEST_REGISTER("diamond1000",function(playerid)
    local diamonds = CURRENCY("Diamonds",playerid)
    if Player:notifyGameInfo2Self(playerid,"Gain 100 Diamonds") == 0 then 
        diamonds:gain(1000,"Game Test Gain Coin");
    end 
    Chat:sendSystemMsg("Balance:"..diamonds:balance());
end)

CODE_TEST_REGISTER("diamond-1000",function(playerid)
    local diamonds = CURRENCY("Diamonds",playerid)
    if Player:notifyGameInfo2Self(playerid,"Lost 100 Diamonds") == 0 then 
        diamonds:lost(1000,"Game Test Lost Coin");
    end 
    Chat:sendSystemMsg("Balance:"..diamonds:balance());
end)

CODE_TEST_REGISTER("diamond-s1000",function(playerid)
    local diamonds = CURRENCY("Diamonds",playerid)
    if Player:notifyGameInfo2Self(playerid,"Spend 100 Diamonds") == 0 then 
        if diamonds:spend(1000,"Game Test Spend Coin") then 
            Chat:sendSystemMsg("Successfully Spend")
        else 
            Chat:sendSystemMsg("Failed Spend")
        end 
    end 
    Chat:sendSystemMsg("Balance:"..diamonds:balance());
end)
