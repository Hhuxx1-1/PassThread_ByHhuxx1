local function getAngleDiff(playerid, target)
    local _,px, py, pz = Actor:getPosition(playerid) 
    local _,dx, dy, dz = Player:getAimPos(playerid)
    local dirX1, dirZ1 = (dx - px)*10, (dz - pz)*10;
    local tx,ty,tz   = target.x,target.y,target.z; 
    local mag1 = math.sqrt(dirX1^2 + dirZ1^2)
    dirX1, dirZ1 = dirX1 / mag1, dirZ1 / mag1 

    local carX,carZ = (tx - px), (tz - pz);
    local mag2 = math.sqrt(carX^2 + carZ^2);
    carX, carZ = carX / mag2, carZ / mag2 
    local dot, det = carX * dirX1 + carZ * dirZ1, carX * dirZ1 - carZ * dirX1

    return math.atan2(det, dot) * (180 / math.pi)
end

local isCreated = {};

function HINT_IS_CREATED(playerid)
    if not isCreated[playerid] then 
        return true;
    else 
        return false;
    end 
end

HINT_ARROW = {};

function HINT_ARROW:Show(playerid)
    local hint = HX_Q.CURRENT_QUEST[playerid].hint;
    if hint then 
        local hx,hy,hz = hint.x,hint.y,hint.z;
        local r, x, y, z = Actor:getPosition(playerid);
        local size=0.7;   local color=0xffc800;
        local info=Graphics:makeGraphicsArrowToPos(hx,hy,hz, size, color, 1);
        local dir={x=0,y=10,z=0};  local offset=10;
        Graphics:createGraphicsArrowByActorToPos(playerid, info, dir, offset)
        
        local yaw = getAngleDiff(playerid,hint);
        Chat:sendSystemMsg("yaw,"..yaw);
        -- Apply the absolute rotation to make player face the target
        local durationinsecond = 1  -- or any desired duration
        Player:SetCameraRotTransformBy(playerid, {x = yaw, y = 0}, 1, durationinsecond)
        isCreated[playerid] = true; 
    else 
        Player:notifyGameInfo2Self(playerid,"Hint Unavailable");
    end 
end

function HINT_ARROW:Hide(playerid)
    Graphics:removeGraphicsByObjID(playerid, 1, 4);
    isCreated[playerid] = nil; 
end

function HINT_ARROW:Toogle(playerid)
    if not isCreated[playerid] then 
        HINT_ARROW:Show(playerid);
    else 
        HINT_ARROW:Hide(playerid);    
    end 
end 

ScriptSupportEvent:registerEvent("UI.Button.Click",function(e)
    local playerid,uiid,elementid =  e.eventobjid,e.CustomUI,e.uielement 
    if elementid == "7431847660104653042_1" then 
        HINT_ARROW:Toogle(playerid)
    end 
end)

ScriptSupportEvent:registerEvent("UI.Hide",function(e)
    local playerid , uiid = e.eventobjid,e.CustomUI;
    HINT_ARROW:Hide(playerid)
end)