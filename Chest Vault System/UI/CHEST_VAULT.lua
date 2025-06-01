local uiid = "7510120612985772274"
local init = {x = 20,y = 7 ,z = 10}
local slots = {}

local function initSlots()
    local c = 1;
    for ix = 0 , 9 do 
        for iz = 0 , 3 do 
            slots[c] = {x = init.x + ix , y = init.y , z = init.z + iz}
            c = c + 1
            WorldContainer:addStorageBox(init.x+ix,init.y ,init.z+iz)
            WorldContainer:addStorageBox(init.x+ix,init.y+1 ,init.z+iz)
        end 
    end 
end
-- Chest Vault is Global Table with list of methods;
CHEST_VAULT = {}
CHEST_VAULT_CURRENT = {};
-- function to read chest Data;
function CHEST_VAULT.VERIFY(slot,playerid)
    if WorldContainer:checkStorage(slot.x,slot.y,slot.z) == 0 then 
        print("current slot : ",slot);
        local data = {}
        for digit = 1 , 10 do 
            local r, itemid, num = WorldContainer:getStorageItem(slot.x,slot.y,slot.z, digit);
            print("digit : ",digit,r,itemid,num)
            if r == 0 then
                data[digit] = num-1; --avoid 0;
            end 
        end 
        -- concat data into string;
        local datastr = "";
        for digit = 1 , 10 do
            datastr = datastr .. data[digit]
        end;
        print("digit str : ",datastr);
        -- convert datastr into number;
        local dataint = tonumber(datastr);
        print("digit int : ",dataint);
        -- compare dataint with playerid;
        if dataint == playerid then
            -- it is same chest with player last chest;
            return true
        else 
            if dataint == nil or dataint == 0 then 
                -- it is empty chest 
                return true;
            else 
                return false;
            end 
        end 
    end 
end 

function CHEST_VAULT.CLAIM(slot,playerid)
    -- convert playerid into string;
    local datastr = tostring(playerid);
    -- convert datastr into table;
    local data = {}
    for digit = 1 , #datastr do
        if WorldContainer:setStorageItem(slot.x,slot.y,slot.z, digit ,1 --[[bedrock itemid]],tonumber(string.sub(datastr,digit,digit))+1) ~= 0 then 
            return false;
        end 
    end 

    -- clear the Chest above current Slot which is y+1;
    if WorldContainer:clearStorageBox(slot.x,slot.y+1,slot.z) == 0 then 
        return true;
    end 
end


function CHEST_VAULT.LOAD(playerid)
    -- find empty slot or same slot of player;
    local currentSlot = nil;
    for i , slot in ipairs(slots) do 
        if CHEST_VAULT.VERIFY(slot,playerid) then 
            currentSlot=slot;
            break;
        end 
    end 

    if currentSlot == nil then Player:notifyGameInfo2Self(playerid,"No Slot available") end 
    print(currentSlot)
    -- now rewrite the currentSlot as playerid;
    if not CHEST_VAULT.CLAIM(currentSlot,playerid) then return false end 
    
    -- read from PLAYERDATA Vault;
    local vault = PLAYERDATA(TABLE_TYPE.string,"VAULT",playerid);
    local r, values = vault:readAll();
    if r == 0 and #values > 0 then
        for ixSlot, dataSlot in ipairs(values) do 
            -- Data slot is encoded table;
            local decodedTable = vault:DecodeTable(dataSlot)
            -- it must has key itemid and n as quantity;
            if decodedTable["itemid"] and decodedTable["n"] then
                -- check both itemid and n is not 0
                if tonumber(decodedTable["itemid"]) ~= 0 and tonumber(decodedTable["n"]) ~= 0 then 
                -- we are going to write on the slot above;
                    if WorldContainer:setStorageItem(currentSlot.x,currentSlot.y+1,currentSlot.z, ixSlot-1,tonumber(decodedTable.itemid),tonumber(decodedTable.n)) ~= 0 then 
                        print("Error Occured");
                        return false;
                    end 
                end
            end 

        end 
    end 

    -- now open that slot;
    if Player:openBoxByPos(playerid,currentSlot.x,currentSlot.y+1,currentSlot.z) == 0 then 
        CHEST_VAULT_CURRENT[playerid] = currentSlot;
    end 
end

function CHEST_VAULT.CLEAR(playerid)
    local slot = CHEST_VAULT_CURRENT[playerid];
    if WorldContainer:clearStorageBox(slot.x,slot.y+1,slot.z) == 0 
    and  WorldContainer:clearStorageBox(slot.x,slot.y,slot.z) == 0 
    then 
        CHEST_VAULT_CURRENT[playerid] = nil;
    end 
end

function CHEST_VAULT.SAVE_EXIT(playerid)
    -- read the current data y+1;
    local slot = CHEST_VAULT_CURRENT[playerid];
    local storageSlot = 30 ;
    local vault = PLAYERDATA(TABLE_TYPE.string,"VAULT",playerid);
    for ix = 0 , storageSlot - 1 do 
        local r, itemid , n = WorldContainer:getStorageItem(slot.x,slot.y+1,slot.z, ix);
        -- encode the data into string table;
        local encodedTable = vault:EncodeTable({itemid = itemid, n = n});
        -- write to the vault;
        vault:newIndex(ix+1,encodedTable);
    end 

    CHEST_VAULT.CLEAR(playerid);
end

ScriptSupportEvent:registerEvent("UI.Show",function(e)
    local playerid = e.eventobjid;
    local CustomUI = e.CustomUI;
    if CustomUI == uiid then 
        -- set the Button Action;
        local _e = UIZ(uiid,playerid);
        _e("Vault_Input",10):hide();
        _e("Vault_Base",2):show();
        _e("Continue",6):setAction(function()
            CHEST_VAULT.LOAD(playerid);
            -- hide the element;
            _e("Vault_Base",2):hide();
            _e("Vault_Input",10):show();
        end)
    end 
end)

ScriptSupportEvent:registerEvent("UI.Hide",function(e)
    local playerid = e.eventobjid;
    local CustomUI = e.CustomUI;
    if CustomUI == uiid then 
        -- set the Button Action;
        local _e = UIZ(uiid,playerid);
        _e("Continue",6):unsetAction()
        _e();
        if CHEST_VAULT_CURRENT[playerid] then 
            CHEST_VAULT.SAVE_EXIT(playerid);
        end 
    end 
end)

ScriptSupportEvent:registerEvent("UI.Button.Click",function(e)
    local playerid = e.eventobjid;
    local CustomUI = e.CustomUI;
    local elementBtn = e.uielement;
    -- check from PROMPT 
    if CustomUI == uiid then 
        -- print("This UI Clicked")
        if UIZ_BUTTON then 
            -- print("UIZ_BUTTON : " , playerid,elementBtn)
            -- PROMPT is exist 
            UIZ_BUTTON(playerid,elementBtn)
        end     
    end 
end)

ScriptSupportEvent:registerEvent("Game.Start",function()
    initSlots();
end)