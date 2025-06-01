local uiid = "7510065272332163314";

ScriptSupportEvent:registerEvent("UI.Show",function(e)
    local playerid = e.eventobjid;
    -- close statuses UI and backpack UI;
    local statusesUI = "7504000963193805042"
    local backpackUI = "7504602816960993522"
    if Player:hideUIView(playerid,statusesUI) == 0 
    and Player:hideUIView(playerid,backpackUI) == 0 
    then 
       BACKPACK.Clear(playerid);
        --    set plaer Location;
        local r, _x, _y, _z = Player:getPosition(playerid);
        if Player:setPosition(playerid, _x, 200, _z) == 0 
        or Player:reviveToPos(playerid, _x, 200, _z) == 0
        and Player:setActionAttrState(playerid,1, false) == 0
        then 
            
            -- mount Camera original _x,_y,_z position;
            Player:SetCameraMountPos(playerid, {x=_x,y=_y+2,z=_z});

            local _e = UIZ(uiid,playerid);
            _e("respawnButton",2):setAction(function()
                Player:ResetCameraAttr(playerid)
                Player:hideUIView(playerid,uiid);
                GIVE_PLAYER_LOADOUT(playerid)
            end)
            _e("changeButton",5):setAction(function()
                Player:ResetCameraAttr(playerid)
                Player:hideUIView(playerid,uiid);
                PLAYER_READY:UNREGISTER(playerid);
                Player:openUIView(playerid,"7508907770055956722")
            end)
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