-- ===== Item usage Monitor ===== 
CUSTOM_ACTION = {};
CUSTOM_ACTION.record_useitem = {}; --store itemid;
CUSTOM_ACTION.time_useitem = {}; -- store os.time(); 
CUSTOM_ACTION.ITEM_USE  = {};
CUSTOM_ACTION.ITEM_USED = {};

function CUSTOM_ACTION_REGISTER_USE(id,func)
    CUSTOM_ACTION.ITEM_USE[id] = func;
end

function CUSTOM_ACTION_REGISTER_USED(id,func)
    CUSTOM_ACTION.ITEM_USED[id] = func;
end

ScriptSupportEvent:registerEvent("Player.UseItem",function(e)
    local playerid,itemid,itemnum,itemix = e.eventobjid, e.itemid, e.itemnum, e.itemix or -1;
    -- Chat:sendSystemMsg("Use Item : "..playerid.." itemid : "..itemid.." num : "..itemnum.." ix : "..itemix);
    CUSTOM_ACTION.record_useitem[playerid] = itemid;
    CUSTOM_ACTION.time_useitem[playerid] = tonumber(_T);
    local r, data_item = BACKPACK.getActualId(playerid)
    -- print("Called ITEM USE : ",r,data_item,itemid,CUSTOM_ACTION.ITEM_USED);
    if r and data_item.itemid == itemid  and CUSTOM_ACTION.ITEM_USE[itemid] then
        -- the action is registered;
        local r,err = pcall(function()
            CUSTOM_ACTION.ITEM_USE[itemid](playerid,itemid);    
        end)
    end 
end)

-- ScriptSupportEvent:registerEvent("Player.BackPackChange",function(e)
--     local playerid,itemid,itemnum,itemix = e.eventobjid, e.itemid, e.itemnum, e.itemix;
--     Chat:sendSystemMsg("Backpack Change : "..playerid.." itemid : "..itemid.." num : "..itemnum.." ix : "..itemix);
-- end)

ScriptSupportEvent:registerEvent("Player.ShortcutChange",function(e)
    local playerid,itemid= e.eventobjid, e.itemid
    -- Chat:sendSystemMsg("Shortcut Change: "..playerid.." itemid : "..itemid);
    if CUSTOM_ACTION.record_useitem[playerid] == itemid then 
        -- item num is number duration of item used in second 
        -- while time_use item is epoch time from the past;
        -- we can use it to calculate the time difference and store it in itemnum 
        local time_diff = math.abs(CUSTOM_ACTION.time_useitem[playerid] - _T);
        -- same as used item  
        if time_diff > 0 then 
            -- Game:dispatchEvent("CUSTOM_ACTION",{eventobjid = playerid , itemid = itemid, itemnum = time_diff});
            -- Chat:sendSystemMsg("Usage Item : "..playerid.." itemid : "..itemid.." time_diff : "..time_diff);
            CUSTOM_ACTION.record_useitem[playerid] = nil;
            CUSTOM_ACTION.time_useitem[playerid] = nil;
            local r, data_item = BACKPACK.getActualId(playerid)
            -- print("Called ITEM USED : ",r,data_item,itemid,CUSTOM_ACTION.ITEM_USED);
            if r and data_item.itemid == itemid and CUSTOM_ACTION.ITEM_USED[itemid] 
            then
                -- the action is registered;
                local r,err = pcall(function()
                    CUSTOM_ACTION.ITEM_USED[itemid](playerid,itemid,time_diff);
                end)
            end
        end;
    end 
end)