local uiid = [[7504000963193805042]];
local Element_staminaMain = [[7504000963193805042_5]];
local Element_staminaSub = [[7504000963193805042_18]];
local Element_Health = [[7504000963193805042_12]];
local LastStaminaUpdate,LastHealthUpdate = {},{};

local function setArmor(playerid,v)
    Player:setAttr(playerid,19,v);
    Player:setAttr(playerid,20,v);
end

local function UpdateStamina(currentStamina,MaxStamina,playerid)
    
    -- Update The UI Visual;
    local length = 274;
    local height = 60;
    local percentage = currentStamina/MaxStamina;

    if currentStamina > 0 then 
        setArmor(playerid,math.min(currentStamina+1,50))
    end 

    local w = length * percentage;
    if Customui:SmoothScaleTo(playerid, uiid, Element_staminaMain, 0.1, w , height) == 0 then 
        LastStaminaUpdate[playerid] = os.time();
        
        local delay = 3;

        -- Update the Inner Sub Bar; 
        threadpool:delay(delay,function()
            if os.time() - LastStaminaUpdate[playerid] >= delay  then 
                Customui:SmoothScaleTo(playerid, uiid,Element_staminaSub, 1, w , height);
                if percentage < 1 then 
                    threadpool:delay(2,function()
                        -- Regenerate Stamina;
                        Actor:addBuff(playerid,50000000, 1, -1);
                    end)
                else 
                    Actor:removeBuff(playerid,50000000)
                end 
            else
                Actor:removeBuff(playerid,50000000)    
            end 
        end)

    end 
end 

local function UpdateHealth(currentHP,maxHP,playerid)
    -- update the UI Visual of Health;
    local length = 250;
    local height = 60;
    local percentage = currentHP/maxHP;
    local w = length * percentage;
    Customui:setSize(playerid,uiid,Element_Health,w,height);
end

ScriptSupportEvent:registerEvent([[Player.ChangeAttr]],function(e)
    local playerid = e.eventobjid;
    local attrType = e.playerattr;
    -- Chat:sendSystemMsg("Attr Change = "..attrType.." Value is = "..e.playerattrval);
    -- print(e);
    if attrType == 2 then -- Health
        local _,maxHP = Player:getAttr(playerid,1); local _,currentHP = Player:getAttr(playerid, 2);
        UpdateHealth(currentHP,maxHP,playerid);
    end;

    if attrType == 28 then -- Stamina 
        local _,currentStamina = Player:getAttr(playerid,28); local _,maxStamina = Player:getAttr(playerid, 29);
        UpdateStamina(currentStamina,maxStamina,playerid);
    end;
end)

ScriptSupportEvent:registerEvent([[Player.BeHurt]],function(e)
    -- print(e);
    local playerid = e.eventobjid;
    local dmg = e.hurtlv; -- is negative number;

    local _,currentStamina = Player:getAttr(playerid,28);
    local _,maxStamina = Player:getAttr(playerid,29);
    local _,currentHP = Player:getAttr(playerid,2);
    local _,maxHP = Player:getAttr(playerid,1);

    if currentStamina >  maxStamina/2 then 
        -- substract it;
        local r,armor = Player:getAttr(playerid,19)
        Player:setAttr(playerid,28,math.max(currentStamina + (dmg - armor) ,0));
        Player:setAttr(playerid,2,math.min(currentHP - dmg/10,maxHP))
         Actor:addBuff(playerid,50000002, 1, 20);
    elseif currentStamina >  maxStamina/10 then 

        Player:setAttr(playerid,28,math.max(currentStamina + dmg, 0));
        Player:setAttr(playerid,2,math.min(currentHP - dmg/2,maxHP))
         Actor:addBuff(playerid,50000002, 1, 20);

    else 
        -- set Armor to 1;
        setArmor(playerid,1);
    end 
end)
