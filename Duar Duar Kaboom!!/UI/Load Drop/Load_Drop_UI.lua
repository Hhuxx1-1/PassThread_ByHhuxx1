-- version: 2022-04-20
-- mini: 1029380338
-- uipacket: 7508907770055956722
local uiid = "7508907770055956722";
local current_page = {};
local UI = {}
PLAYER_READY = {PLAYERS={},IPLAYER={}};

function PLAYER_READY:REGISTER(playerid)
    local INFO = PLAYERDATA(TABLE_TYPE.string,"INFO",playerid);
    local r, name = Player:getNickname(playerid);name = name:gsub("@", "")
    -- init INFO;
    local r,values = INFO:readAll();
    if r and #values == 0 then 
        INFO:newIndex(1,os.time())--store join time;
        INFO:newIndex(2,name)--store name;
        INFO:newIndex(3,playerid)--store id;
        INFO:newIndex(4,0)--store total kill;
        INFO:newIndex(5,0)--store total dies;
    end 

    -- Store player info
    self.PLAYERS[playerid] = { id = playerid, name = name}; --insert key pair;
    table.insert(self.IPLAYER,{ id = playerid, name = name}) --insert indexed;
end
-- function to unregister;
function PLAYER_READY:UNREGISTER(playerid)
    -- remove player info
    self.PLAYERS[playerid] = nil;
    for i, v in ipairs(self.IPLAYER) do
        if v.id == playerid then
            table.remove(self.IPLAYER, i);
            break;
        end 
    end 
end 

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

local function LoadCharDrop(playerid)
    local char = PLAYERDATA(TABLE_TYPE.number,"Char",playerid);

    local r, values = char:readAll()
    if not r or #values == 0 then

        local freeChar = 5 --> 1 until 5 is free 
        
        for i = 1, #LOAD_DROP_DATA do
            char:newIndex(i, i <= freeChar and 1 or 0) --> 1 is level 1, 0 is not owned
        end
    end

    return char;
end 

local function UpgradeLevelChar(playerid,ix,level)
    local char = LoadCharDrop(playerid);
    char:updateIndex(ix,level+1);
    char:destroy();
end

local PLAYER_CURRENT_LOADOUT = {}
function GIVE_PLAYER_LOADOUT(playerid)
    local d = PLAYER_CURRENT_LOADOUT[playerid];
    -- print("GIVE_PLAYER_LOADOUT : ",d);
    -- set attribute 
    local hp,sp = d.attr.hp , d.attr.sp;
    Player:setAttr(playerid,1,hp) --set Max Hp 
    Player:setAttr(playerid,2,hp) --set Cur Hp 
    Player:setAttr(playerid,29,sp) --set Max SP
    Player:setAttr(playerid,28,sp) --set Cur SP

    -- empty the BACKPACK;
    BACKPACK.Clear(playerid);
    SPAWN_PLAYER(playerid,math.random(150,800),math.random(100,600));
    -- load the loadout;
    for i=1,3  do 
        local load = d.drop[i];
        print("Load : ",load)
        threadpool:delay(i,function()
            if load.quantity > 0 then 
                print("Adding : ",playerid, load.itemid, load.name,  load.iconid, load.quantity)
                BACKPACK.AddItem(playerid, load.itemid, load.name,  load.iconid, load.quantity);
            end 
        end)
    end 
    
end 

function UI.updatePagination(_e,ix,page,playerid)
    page = page or 1;
    current_page[playerid] = page;
    local maxitem_perpage = 18;

    local char = LoadCharDrop(playerid);

    for i = 1, maxitem_perpage do
        local s = 60 + (i*2); 

        local d = LOAD_DROP_DATA[i+(page-1)*maxitem_perpage];    
        if d then 
            local iconid = d.icon[1];
            local id = d.id;
            local level = char:readIndex(tonumber(id));
            -- load into ui;
            _e("selection"..i,s-1):show():setAction(
                function()
                    UI.LoadIndexItem(playerid,tonumber(id));
                end 
            )
            if tonumber(id) == ix then 
                _e("selection"..i,s-1):setTexture([[8_1029380338_1747158697]])
            else
                _e("selection"..i,s-1):setTexture([[8_1029380338_1747158700]])
            end 
            _e("selection"..i,s):setTexture(iconid)
            if level == 0 then
                -- it's not unlocked;
                _e("selection"..i,s):setColor(0x777777);
            else
                _e("selection"..i,s):setColor(0xffffff);
            end 

        else
            -- hide it 
            _e("selection"..i,s-1):hide():unsetAction()
        end 
    end 

    -- check next item in page
    if LOAD_DROP_DATA[1+page*maxitem_perpage] then 
        _e("nextBtn",100):setAction(function()
            UI.updatePagination(_e,ix,page+1,playerid);
        end):show()
        -- next page is exist;
    else
        _e("next",100):unsetAction():hide()
    end 
    -- check prev item in page
    if LOAD_DROP_DATA[-1+(page-1)*maxitem_perpage] then 
        _e("prevBtn",98):setAction(function()
            UI.updatePagination(_e,ix,page-1,playerid);
        end):show()
    else
        _e("prevBtn",98):unsetAction():hide()
    end 

    -- update pagination statuses visual;
    local _o,_oo = "○" , "●";
    local maxItem = #LOAD_DROP_DATA;
    local maxPage = math.ceil(maxItem / maxitem_perpage);
    local _ooo = "";
    for i = 1, maxPage do
        _ooo = _ooo .. (i == page and _oo or _o) .. " ";
    end 
    _e("Pagination_Status",97):setText(_ooo);

    char:destroy();
    
end

-- First create a deep copy function
local function deepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = deepCopy(v) -- Recursively copy sub-tables
        else
            copy[k] = v
        end
    end
    return copy
end

-- Modified function that works on a copy
function UI.LoadDropCharLevel(d, level)
    -- Create a deep copy of the input table
    local result = deepCopy(d)
    
    -- Modify the copy instead of the original
    result.attr.hp = result.attr.hp + (result.attr.lhp * level)
    result.attr.sp = result.attr.sp + (result.attr.lsp * level)  -- Fixed: was using hp instead of sp
    result.drop[1].quantity = result.drop[1].quantity + (result.drop[1].lvalue * level)
    
    if level >= 5 then 
        result.drop[2].quantity = result.drop[2].quantity + (result.drop[2].lvalue * (level - 5))
    else
        result.drop[2].quantity = 0
    end 
    
    if level >= 15 then 
        result.drop[3].quantity = result.drop[3].quantity + (result.drop[3].lvalue * (level - 15))
    else
        result.drop[3].quantity = 0
    end
    
    return result  -- Return the modified copy
end

function UI.LoadIndexItem(playerid,ix)
    -- always set to false whenever change Index
    PLAYER_READY:UNREGISTER(playerid)

    local function loadAttrVisual(hp,sp,_e)
        local dvder = 500
        local l,h = 175,26
        local hpL,spL = hp/dvder*l,sp/dvder*l
        _e("hp_bar",47):setSize(hpL,h);
        _e("sp_bar",51):setSize(spL,h);
    end 

    local function loadDrop(drop,_e)
        for is = 1,3 do 
            local i = 19 + ((is-1)*7);
            _e("slot"..is.."Icon",i):setTexture(drop[is].iconid or "not set");

            if drop[is].quantity > 0 then 
                _e("slot"..is.."Txt",i+1):setText(drop[is].name or "not set");
                _e("slot"..is.."Sub",i+2):setText(drop[is].desc or "not set");
                _e("slot"..is.."Lock",i+3):hide();
            else 
                _e("slot"..is.."Lock",i+3):show();
                _e("slot"..is.."Sub",i+2):setText(drop[is].name or "not set");
                _e("slot"..is.."Txt",i+1):setText("Unlock at lv."..(is <= 2 and 5 or 15));
            end 
        end 
    end

    ix = ix or 1; -- index default is 1 
    local _e = UIZ(uiid, playerid);
    -- fetch content from LOAD DROP DATA;
    local d = LOAD_DROP_DATA[ix];
    -- route to the uiz
    -- set The Appearemnce of Player; 
    Actor:changeCustomModel(playerid,d.skin[1]);
    _e("text_char",53):setText(d.name); --setText is unable to be called;
    _e("icon_char",38):setTexture(d.icon[1]);

    local char = LoadCharDrop(playerid);
    local current_Char_level = char:readIndex(ix)

    -- update the current data with copied table;
    d = UI.LoadDropCharLevel(d,current_Char_level);

    loadAttrVisual(d.attr.hp,d.attr.sp,_e);
    loadDrop(d.drop,_e)

    _e("text_level",104):setText(current_Char_level > 0 and (" Lv. "..current_Char_level) or "Locked");
    _e("text_upgrade",55):setText(current_Char_level > 0 and (" UPGRADE > "..(current_Char_level+1)) or "UNLOCK");
    _e("text_start",59):setText(current_Char_level > 0 and "START" or "Get Free");
    _e("pic_start",58):setTexture(current_Char_level > 0 and [[8_1029380338_1747158729]] or [[8_1029380338_1723033408]]);

    local price_next_level = current_Char_level > 0 and (d.cost.value + (d.cost.value * current_Char_level * d.cost.grow)) or (d.unlockCost.value);
    _e("text_upgrade_price",56):setText(formatText(price_next_level));
    _e("pic_upgrade_price",54):setTexture((current_Char_level > 0 and d.cost.currency or d.unlockCost.currency) == "Coins"  and [[8_1029380338_1747158716]] or [[8_1029380338_1747158724]]);
    -- set the function;
    if current_Char_level > 0 then 
        _e("btn_start",3):setAction(function()
            -- put player into ready
            PLAYER_CURRENT_LOADOUT[playerid] = d;
            PLAYER_READY:REGISTER(playerid);
            Player:hideUIView(playerid,uiid);
        end)
        _e("btn_upgrade_price",4):setAction(function(playerid)
            local price = price_next_level;
            local coins = CURRENCY(d.cost.currency,playerid);
            if coins:spend(price,"Upgrade Character "..d.name.." to level "..(current_Char_level+1)) then
                -- upgrade the saved data;
                UpgradeLevelChar(playerid,ix,current_Char_level);
                UI.LoadIndexItem(playerid,ix)
            else
                Player:notifyGameInfo2Self(playerid,"Not Enough "..d.cost.currency)
            end 
        end)
    else
        _e("btn_start",3):setAction(function()
            -- put player into ready
            Player:notifyGameInfo2Self(playerid,"Character is Locked");
        end)
        _e("btn_upgrade_price",4):setAction(function(playerid)
            local price = price_next_level;
            local coins = CURRENCY(d.cost.currency,playerid);
            if coins:spend(price,"Unlock Character "..d.name.." to level "..(current_Char_level+1)) then
                -- upgrade the saved data;
                UpgradeLevelChar(playerid,ix,current_Char_level);
                UI.LoadIndexItem(playerid,ix)
            else
                Player:notifyGameInfo2Self(playerid,"Not Enough "..d.cost.currency)
            end 
        end)
    end 

    UI.updatePagination(_e,ix,current_page[playerid],playerid)

    char:destroy();
    _e();
end 

ScriptSupportEvent:registerEvent("UI.Show",function(e)
    -- Customui:setText(e.eventobjid,uiid,uiid.."_20","test");
    local r,err =  pcall(UI.LoadIndexItem,e.eventobjid)
    if not r then print("error : ",err); end;
end);

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


ScriptSupportEvent:registerEvent("UI.Hide",function(e)
    -- Customui:setText(e.eventobjid,uiid,uiid.."_20","test");
    if PLAYER_READY.PLAYERS[e.eventobjid] then 
        -- add buff 
        Actor:addBuff(e.eventobjid,27, 3, 1);

        -- add into player backpack the loadout;
        GIVE_PLAYER_LOADOUT(e.eventobjid)
    else
        Player:openUIView(e.eventobjid,uiid)
    end 
end);

ScriptSupportEvent:registerEvent("Game.RunTime",function(e)
    if #PLAYER_READY.IPLAYER > 0 then 
        local playerCount = #PLAYER_READY.IPLAYER
        local i = playerCount - (e.ticks % playerCount)
    
        -- print("Selected Index : "..i)
        local player = PLAYER_READY.IPLAYER[i]
    
        -- Attempt to obtain location of player
        local r, x, y, z = Player:getPosition(player.id);
      
        if r == 0 then 
            local success, err = pcall(function()
                Game:dispatchEvent("UPDATE",{eventobjid = player.id});
            end)
            if not success then print("UPDT:", err) end     
            if y < -10 then 
                Actor:killSelf(player.id);
                Player:reviveToPos(player.id,0,7,0)
            end 
        else 
            -- Player not here
            Chat:sendSystemMsg(player.name.."#R Has Left#n")
            -- Remove the player from PLAYER_READY
            PLAYER_READY:UNREGISTER(player.id);
        end 
    end 
    
end)