-- ========== HANDLE UI UPDATE ============= ---------
local uiid = "7504602816960993522";
local _e = {
        base = uiid.."_1"
    ,   container = uiid.."_2"
    ,   slot = {
            { btn = uiid.."_3" , pic = uiid.."_4" , info = uiid.."_5" }
        ,   { btn = uiid.."_6" , pic = uiid.."_7" , info = uiid.."_8" }
        ,   { btn = uiid.."_9" , pic = uiid.."_10" , info = uiid.."_11" }
        ,   { btn = uiid.."_12" , pic = uiid.."_13" , info = uiid.."_14" }
        ,   { btn = uiid.."_15" , pic = uiid.."_16" , info = uiid.."_17" }
    }
}

local config = {
    slotwide = 530/5;
}

-- Backpack System (5 slots)
BACKPACK = {
    MAX_SLOTS = 5,
    EMPTY_SLOT = {
        itemid = 0,
        name = "empty",
        iconid = "empty",
        quantity = 0
    }
}

LAST_LENGTH_CONTENT = {};
CURRENT_EQUIP_INDEX = {};

-- Initialize a player's backpack
function BACKPACK.Init(playerid)
    local backpack = PLAYERDATA(TABLE_TYPE.string, "Backpack", playerid)
    -- backpack:enableLog(true)
    
    -- Initialize empty slots if needed
    local r, values = backpack:readAll()
    if not r or #values == 0 then
        for i = 1, BACKPACK.MAX_SLOTS do
            backpack:newIndex(i, backpack:EncodeTable(BACKPACK.EMPTY_SLOT))
        end
    end
    
    return backpack
end

-- Get first empty slot index
function BACKPACK.FindEmptySlot(backpack)
    local r, values = backpack:readAll()
    if not r then return nil end
    
    for i, encoded in ipairs(values) do
        local slot = backpack:DecodeTable(encoded)
        if slot.itemid == 0 then
            return i
        end
    end
    return nil
end

-- Get current backpack state
function BACKPACK.GetContents(playerid)
    local backpack = BACKPACK.Init(playerid)
    local r, encoded = backpack:readAll()
    local contents = {}
    local emptySlots = {}
    
    if r then
        -- Separate items and empty slots
        for i, enc in ipairs(encoded) do
            local slot = backpack:DecodeTable(enc)
            if slot.itemid == 0 then
                table.insert(emptySlots, slot)
            else
                table.insert(contents, slot)
            end
        end
    end
    
    -- Combine items first, then empty slots
    for _, empty in ipairs(emptySlots) do
        table.insert(contents, empty)
    end
    
    backpack:destroy()
    return contents
end

-- UI Integration
function BACKPACK.UpdateUI(playerid)
    local contents = BACKPACK.GetContents(playerid)
    
    local lengthContent = 0;
    -- First update all UI elements based on sorted contents
    for i = 1, BACKPACK.MAX_SLOTS do
        local slot = contents[i] or BACKPACK.EMPTY_SLOT
        if slot.itemid == 0 then
            Customui:hideElement(playerid, uiid, _e.slot[i].btn)
        else
            Customui:showElement(playerid, uiid, _e.slot[i].btn);

            Customui:setText(playerid, uiid, _e.slot[i].info, slot.quantity)
            Customui:setTexture(playerid, uiid, _e.slot[i].pic, slot.iconid)
            -- handle equipped or not here 
            if i == CURRENT_EQUIP_INDEX[playerid] then 
                Customui:setTexture(playerid, uiid, _e.slot[i].btn,[[8_1029380338_1747302199]])
            else
                Customui:setTexture(playerid, uiid, _e.slot[i].btn,[[8_1029380338_1747302204]])
            end 
            -- increase lengthContent
            lengthContent = lengthContent + 1;
        end
    end

    -- set the length of the content 
    Customui:setSize(playerid,uiid,_e.base,config.slotwide*lengthContent,100);
    LAST_LENGTH_CONTENT[playerid] = lengthContent;

    -- Now ensure the actual storage maintains this order
    local backpack = BACKPACK.Init(playerid)
    for i = 1, BACKPACK.MAX_SLOTS do
        backpack:newIndex(i, backpack:EncodeTable(contents[i] or BACKPACK.EMPTY_SLOT))
    end
    backpack:destroy()
end

-- Add item to backpack
function BACKPACK.AddItem(playerid, itemid, name, iconid, quantity)
    local backpack = BACKPACK.Init(playerid)
    local contents = BACKPACK.GetContents(playerid)
    
    -- First try to stack with existing items
    for i, slot in ipairs(contents) do
        -- Check if slot has the same item and isn't at max stack
        if slot.itemid == itemid then
            local newQuantity = slot.quantity + quantity
            
            -- Update the existing stack
            contents[i].quantity = newQuantity
            
            -- Write back the updated contents
            for i = 1, BACKPACK.MAX_SLOTS do
                backpack:newIndex(i, backpack:EncodeTable(contents[i] or BACKPACK.EMPTY_SLOT))
            end
            
            if CURRENT_EQUIP_INDEX[playerid] == nil then 
                BACKPACK.EquipIndex(playerid, 1)
            end
            
            backpack:destroy()
            BACKPACK.UpdateUI(playerid)
            return true
        end
    end
    
    -- If no existing stack found, use original logic to add to empty slot
    for i, slot in ipairs(contents) do
        if slot.itemid == 0 then  -- Empty slot
            local newItem = {
                itemid = itemid,
                name = name,
                iconid = iconid,
                quantity = quantity
            }
            
            contents[i] = newItem
            break
        end
    end
    
    -- Write back the updated contents
    for i = 1, BACKPACK.MAX_SLOTS do
        backpack:newIndex(i, backpack:EncodeTable(contents[i] or BACKPACK.EMPTY_SLOT))
    end
    
    if CURRENT_EQUIP_INDEX[playerid] == nil then 
        BACKPACK.EquipIndex(playerid, 1)
    end
    
    backpack:destroy()
    BACKPACK.UpdateUI(playerid)
    return true
end

-- Remove item (or reduce quantity)
function BACKPACK.RemoveItem(playerid, slotIndex, amount)
    amount = amount or 1
    local backpack = BACKPACK.Init(playerid)
    local contents = BACKPACK.GetContents(playerid)
    
    if not contents[slotIndex] or contents[slotIndex].itemid == 0 then
        backpack:destroy()
        return false
    end
    
    -- Reduce quantity
    contents[slotIndex].quantity = contents[slotIndex].quantity - amount
    
    -- If emptied, move to end
    if contents[slotIndex].quantity <= 0 then
        local emptiedItem = table.remove(contents, slotIndex)
        emptiedItem = BACKPACK.EMPTY_SLOT
        table.insert(contents, emptiedItem)
    end
    
    -- Write back the sorted contents
    for i = 1, BACKPACK.MAX_SLOTS do
        backpack:newIndex(i, backpack:EncodeTable(contents[i] or BACKPACK.EMPTY_SLOT))
    end
    
    backpack:destroy()
    BACKPACK.UpdateUI(playerid) -- Refresh UI
    return true
end

function BACKPACK.EquipIndex(playerid, index)
    local backpack = BACKPACK.Init(playerid)
    local contents = BACKPACK.GetContents(playerid)
    
    -- Validate slot
    if not contents[index] or contents[index].itemid == 0 then
        backpack:destroy()
        return false
    end
    
    -- Equip to all weapon slots
    for i = 1000, 1008 do 
        Backpack:setGridItem(playerid, i, contents[index].itemid, 1, nil)
    end

    CURRENT_EQUIP_INDEX[playerid] = index -- Update last equipped index

    backpack:destroy()
    -- updateUI
    BACKPACK.UpdateUI(playerid);
    return true
end

function BACKPACK.Unequip(playerid)
    Backpack:clearPack(playerid, 1)
    Backpack:clearPack(playerid, 2)
    CURRENT_EQUIP_INDEX[playerid] = nil -- Clear equipment memory
    BACKPACK.UpdateUI(playerid);
    return true
end

-- Clear Backpack function;
function BACKPACK.Clear(playerid)
    local backpack = BACKPACK.Init(playerid)
    for i = 1, BACKPACK.MAX_SLOTS do
        backpack:newIndex(i, backpack:EncodeTable(BACKPACK.EMPTY_SLOT))
    end 
    BACKPACK.Unequip(playerid);
    CURRENT_EQUIP_INDEX[playerid] = nil;
    return nil;
end 

function BACKPACK.getActualId(playerid)
    local currentIndex = CURRENT_EQUIP_INDEX[playerid] or 1
    local contents = BACKPACK.GetContents(playerid)
    if contents[currentIndex] and contents[currentIndex].itemid ~= 0 then
        return true,contents[currentIndex];
    end
    return false;
end 

function BACKPACK.AutoEquip(playerid)
    local currentIndex = CURRENT_EQUIP_INDEX[playerid] or 1
    local contents = BACKPACK.GetContents(playerid)
    
    -- Check current index first
    if contents[currentIndex] and contents[currentIndex].itemid ~= 0 then
        return BACKPACK.EquipIndex(playerid, currentIndex)
    end
    
    -- Search backwards for nearest non-empty slot
    for i = currentIndex - 1, 1, -1 do
        if contents[i] and contents[i].itemid ~= 0 then
            CURRENT_EQUIP_INDEX[playerid] = i
            return BACKPACK.EquipIndex(playerid, i)
        end
    end
    
    -- If nothing found, unequip
    return BACKPACK.Unequip(playerid)
end

function BACKPACK.ConsumeIndex(playerid, index, amount)
    amount = amount or 1
    local backpack = BACKPACK.Init(playerid)
    local contents = BACKPACK.GetContents(playerid)
    
    -- Validation
    if not contents[index] or 
       contents[index].itemid == 0 or 
       contents[index].quantity < amount then
        backpack:destroy()
        return false
    end
    
    -- Update quantity
    contents[index].quantity = contents[index].quantity - amount
    
    -- Handle depletion
    if contents[index].quantity <= 0 then
        contents[index] = BACKPACK.EMPTY_SLOT
    end
    
    -- Save changes
    for i = 1, BACKPACK.MAX_SLOTS do
        backpack:newIndex(i, backpack:EncodeTable(contents[i] or BACKPACK.EMPTY_SLOT))
    end
    
    backpack:destroy()
    BACKPACK.UpdateUI(playerid);
    -- put auto equip here;
    if contents[index].quantity <= 0 then
        BACKPACK.AutoEquip(playerid);
    end 
    return true
end



-- Event Handlers
ScriptSupportEvent:registerEvent("UI.Show", function(e)
    BACKPACK.UpdateUI(e.eventobjid)
end)


-- Handle Interactivity;
ScriptSupportEvent:registerEvent("Player.SelectShortcut", function(e)
    local playerid = e.eventobjid
    local pressedSlot = e.CurEventParam.EventShortCutIdx + 1  -- Convert from 0-based to 1-based
    local maxSlots = LAST_LENGTH_CONTENT[playerid] or BACKPACK.MAX_SLOTS
    
    -- Proper circular navigation (1-2-3-1-2-3 when maxSlots=3)
    local targetSlot = ((pressedSlot - 1) % maxSlots) + 1
    
    BACKPACK.EquipIndex(playerid, targetSlot)
end)


ScriptSupportEvent:registerEvent("UI.Button.Click",function(e)
    local playerid,ui,_element = e.eventobjid,e.CustomUI,e.uielement;

    local function QuickBarClick()
        for i,element in ipairs(_e.slot) do 
            if element.btn == _element then 
                return i;
            end 
        end 
    end 

    local slot = QuickBarClick();
    if slot then
        BACKPACK.EquipIndex(playerid,slot);
    end 

end)

ScriptSupportEvent:registerEvent("Player.AttackHit",function(e)
    local playerid,objiid,targetid = e.eventobjid,e.toobjid,e.targetactorid;
    -- print("TargetAttackHit : ",e);
end)

-- CODE_TEST_REGISTER("h1",function(playerid)
--     BACKPACK.AddItem(playerid, 4099, "Bomb", [[1004099]], 3)
--     BACKPACK.AddItem(playerid, 15014, "Ak",  [[1015014]], 64)
--     BACKPACK.AddItem(playerid, 4101, "Bazooka",  [[1004101]], 2)
-- end)

-- CODE_TEST_REGISTER("r1",function(playerid)
--     BACKPACK.RemoveItem(playerid, 1, 3) -- Remove all health potions
-- end)

-- CODE_TEST_REGISTER("e1",function(playerid)
--      BACKPACK.EquipIndex(playerid, 1)
-- end)

-- CODE_TEST_REGISTER("e2",function(playerid)
--      BACKPACK.EquipIndex(playerid, 2)
-- end)

-- CODE_TEST_REGISTER("c1",function(playerid)
--     BACKPACK.ConsumeIndex(playerid,1,1)
-- end)

-- CODE_TEST_REGISTER("c2",function(playerid)
--     BACKPACK.ConsumeIndex(playerid,2,1)
-- end)