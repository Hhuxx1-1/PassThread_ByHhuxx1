local DIED = {}
function CustomRespawnPlayer(playerid,x,z)
    local r, _x, _, _z = Player:getPosition(playerid)
    if r == 0 then 
        x = x or _x;
        z = z or _z;
    end 
    if r == ErrorCode.OK then
        if Player:reviveToPos(playerid, x, 160, z) == ErrorCode.OK then
            threadpool:delay(2, function()
                DIED[playerid] = true ; -- Turn it back On;
                Player:setActionAttrState(playerid,1, true);
                if Backpack:setGridItem(playerid, 8004, 12822, 1, 100) == ErrorCode.OK then
                    Actor:setFacePitch(playerid, 90)
                    threadpool:delay(5, function()
                        local r, nx, ny, nz = Player:getPosition(playerid)
                        local r, blockID = Block:getBlockID(nx, ny-1, nz)
                        -- Chat:sendSystemMsg("5: r:"..r.." BlockId="..blockID)
                        
                        if blockID == 0 then
                            Backpack:setGridItem(playerid, 8004, 4100, 1)
                            local r , objid = World:spawnCreature(nx,ny,nz, 3400, 1)
                            if r == ErrorCode.OK then 
                                -- Replace while loop with recursive delayed checks
                                local function CheckEquipAndMove()
                                    if Player:isEquipByResID(playerid, 4100) == 0 then
                                        local r, x, y, z = Actor:getFaceDirection(playerid);
                                        local r, nx, ny, nz = Player:getPosition(playerid)
                                        local r, blockID1 = Block:getBlockID(nx, ny-1, nz);
                                        local r, blockID2 = Block:getBlockID(nx+x, ny, nz+z);
                                        local r, blockID3 = Block:getBlockID(nx+x, ny+1, nz+z);
                                        local r, blockID4 = Block:getBlockID(nx+x, ny-1, nz+z);
                                        if blockID1 == 0 and blockID2 == 0 and blockID3 == 0 and blockID4 == 0 then 
                                            Actor:appendSpeed(objid[1], x/5, math.abs(y)*-1, z/5)
                                            Player:mountActor(playerid, objid[1], 1);
                                            threadpool:delay(0.1, CheckEquipAndMove); -- Check again after delay
                                        else
                                            Backpack:clearPack(playerid, 3);
                                            Player:mountActor(playerid, 0);
                                            World:despawnCreature(objid[1]);
                                        end 
                                    end
                                end
                                
                                CheckEquipAndMove() -- Start the checking process
                            end 
                        end
                    end)
                end
            end)
        end
    end
end
function SPAWN_PLAYER(playerid,x,z)
    DIED[playerid] = false ; -- toogle the execution of event Player.Die;

    -- when Die in this event is called, it will be ignored by Player.Die;
    Actor:killSelf(playerid)
    CustomRespawnPlayer(playerid,x,z)
end

ScriptSupportEvent:registerEvent([[Player.Die]], function(e)
    print(DIED);
    if DIED[e.eventobjid] then 
        -- open Respawn UI;
        local RespawnUI = "7510065272332163314";
        Player:openUIView(e.eventobjid,RespawnUI)
    end 
end)