local uiid = "7505650200570697970";

local arrow = uiid.."_2";
-- Construct with Playerid as Key and must Has Value of Table with key x,y,z;
local ArrowPos = {
    [1029380338] = {x=20,y=10,z=10};
};

function setArrow(playerid,x,y,z)
    -- set Arrow for player;
    ArrowPos[playerid] = {x=x,y=y,z=z};
end

function UpdateArrow(playerid)

    -- Wrap Function for get Angle Different Between Player and target table contain x,y,z position as key x,y,z;
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
    end;

    -- Check if Target from ArrowPos[playerid] is exist;
    if ArrowPos[playerid] then

        -- validate if it contain key x,y,z and it is number;
        if  type(ArrowPos[playerid].x)  == "number" 
        and type(ArrowPos[playerid].y)  == "number" 
        and type(ArrowPos[playerid].z ) == "number" 
        then
            -- execute the update;
            -- get the Yaw Degree by using Wrap function getAngleDiff;
            local yaw = getAngleDiff(playerid, ArrowPos[playerid]);
            -- handle negative yaw;
            if yaw < 0 then 
                yaw = yaw + 360
            end 
            -- update the UI Element Orentiation;
            if     Customui:rotateElement(playerid, uiid, arrow, yaw) ~= 0 then 
                print("#R Error at API Customui:rotateElement. Could be Wrong UIID or Element ID");
            else

                -- Show Distance;
                local function CalculateDistance(pos1, pos2)
                    local dx = pos2.x - pos1.x
                    local dy = pos2.y - pos1.y
                    local dz = pos2.z - pos1.z
                    return math.sqrt(dx * dx + dy * dy + dz * dz)
                end
                local _,px, py, pz = Actor:getPosition(playerid) 
                -- Set the Distance Text;
                Customui:setText( playerid,uiid,uiid.."_3",
                                  string.format("%.1f m away", CalculateDistance({x=px, y=py, z=pz}, ArrowPos[playerid]))
                                )
            end 
        end 

    else
        Player:notifyGameInfo2Self(playerid,"Missing Target Position");
    end 

end

-- Update each tick for All Player;
ScriptSupportEvent:registerEvent("Game.RunTime", function(e)
    local result, num, array = World:getAllPlayers(1)
    local playerList = (result == 0 and num > 0) and array or {}
    
    for i, playerid in ipairs(playerList) do 
        UpdateArrow(playerid)
    end 
end)

-- Example of Setting the Location;
ScriptSupportEvent:registerEvent("Block.Add",function(e)
    local result, num, array = World:getAllPlayers(1)
    local playerList = (result == 0 and num > 0) and array or {}
    
    for i, playerid in ipairs(playerList) do 
        setArrow(playerid,e.x,e.y,e.z);
        Chat:sendSystemMsg(playerid,"[System] :#W Compass Target Updated");
    end 
end)