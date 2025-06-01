MISSILE = {
    f = {},
    d = {},

    -- Internal tracker for last accessed itemid for method chaining
    __lastItem = nil,
}

-- Metatable magic to allow MISSILE:REGISTER(...) to route to MISSILE.f.REGISTER(self, ...)
setmetatable(MISSILE, {
    __index = function(self, key)
        if MISSILE.f[key] then
            return function(_, ...)
                return MISSILE.f[key](MISSILE, ...)
            end
        end
    end
})

-- Define functional methods
MISSILE.f.REGISTER = function(self, itemid)
    if not self.d[itemid] then
        self.d[itemid] = {}
    end
    self.__lastItem = itemid
    return self  -- allow chaining
end

MISSILE.f.SET_CREATE = function(self, func)
    local itemid = self.__lastItem
    if not itemid then return "No itemid context for SET()" end
    if type(func) ~= "function" then return "SET requires a function" end
    self.d[itemid].onCreate = func
    return self -- Allow Chaining
end

MISSILE.f.SET_HIT = function(self,func)
    local itemid = self.__lastItem
    if not itemid then return "No itemid context for SET_HIT()" end
    if type(func) ~= "function" then return "SET_HIT requires a function" end
    self.d[itemid].onHit = func
    return self -- Allow Chaining
end

MISSILE.f.RUN_CREATE = function(self, e)
    local id = e.itemid
    local entry = self.d[id]
    if entry and entry.onCreate then
        local ok, err = pcall(entry.onCreate, e)
        if not ok then
            print("Missile RUN error: " .. tostring(err))
        end
    else
        print("Missile with itemid " .. tostring(id) .. " not registered or no onCreate function.")
    end
end

MISSILE.f.RUN_HIT = function(self, e)
    local id = e.itemid
    local entry = self.d[id]
    if entry and entry.onHit then
        local ok, err = pcall(entry.onHit, e)
        if not ok then
            print("Missile RUN error: " .. tostring(err))
        end
    else
        print("Missile with itemid " .. tostring(id) .. " not registered or no onCreate function.")
    end
end 

ScriptSupportEvent:registerEvent("Missile.Create", function(e)
    MISSILE:RUN_CREATE(e);
end)

ScriptSupportEvent:registerEvent("Actor.Projectile.Hit",function(e)
    MISSILE:RUN_HIT(e);
end)

MISSILE.f.breakBlock = function(x, y, z, initXYZ, playerid, knockback ,drop)

    local function CalculateDirBetween2Pos(pos1, pos2)
        -- Optimized direction calculation
        local dx, dy, dz = pos2.x - pos1.x, pos2.y - pos1.y, pos2.z - pos1.z
        local inv_magnitude = 1 / math.sqrt(dx * dx + dy * dy + dz * dz)
        return {
            x = dx * inv_magnitude,
            y = dy * inv_magnitude,
            z = dz * inv_magnitude
        }
    end

    -- print(drop);
    local errorCode, BlockID = Block:getBlockID(x, y, z)
    if errorCode == 0 and BlockID ~= 0 and Block:destroyBlock(x, y, z, false) == 0 then
        -- More efficient random selection with better visual distribution
        if drop  then 
            local r,px,py,pz = Player:getPosition(playerid);
            local dir = CalculateDirBetween2Pos( {x = px, y = py, z = pz},initXYZ)

            local code, projectileID = World:spawnProjectile(
                playerid, 12298, 
                initXYZ.x+0.5, initXYZ.y+0.5, initXYZ.z+0.5,
                initXYZ.x+0.5+(dir.x*2),initXYZ.y+(dir.y*2),initXYZ.z+(dir.z*2),
                knockback+300
            )
            
            if code == 0 then  -- Only proceed if projectile spawned successfully
                if Actor:changeCustomModel(projectileID, "block_"..BlockID) ~= 0 then
                    Actor:killSelf(projectileID)
                end
            end
        else 

            if math.random() <= 0.2 then  -- 20% chance to spawn effect (adjust as needed)
                
                local dir = CalculateDirBetween2Pos(initXYZ, {x = x, y = y, z = z})
                
                -- Slightly randomized offsets for better visual effect
                local offsetX, offsetZ = (math.random() - 0.5) * 0.8, (math.random() - 0.5) * 0.8
                local targetX, targetY, targetZ = x + offsetX, y + 2, z + offsetZ
                
                local code, projectileID = World:spawnProjectile(
                    playerid, 12298, 
                    initXYZ.x + dir.x, initXYZ.y + dir.y, initXYZ.z + dir.z,
                    targetX, targetY, targetZ,
                    knockback
                )
                
                if code == 0 then  -- Only proceed if projectile spawned successfully
                    if Actor:changeCustomModel(projectileID, "block_"..BlockID) ~= 0 then
                        Actor:killSelf(projectileID)
                    end
                end
            end
        end 
    end
end

MISSILE.f.dealsDamageFromPlayerToAreaRadius = function(centerXYZ,radius,damage,knockback,playerDamageDealer,selfEffect)

    local radius_multiplier = 1.5;
    local airRessist = 12.733;
    local radius = radius * radius_multiplier;

    local function DEALS_DAMAGE_2_AREA(playerID, x, y, z, dx, dy, dz, amount, dtype)
        local r, areaID = Area:createAreaRect({x = x, y = y, z = z}, {x = dx*radius_multiplier, y = dy*radius_multiplier, z = dz*radius_multiplier})

        local function mergeAndRemoveDealer(Dealer,table1, table2)
            local mergedTable = {}
            local index = 1
            if table1 then
                for _, value in ipairs(table1) do
                    if value ~= Dealer then
                        mergedTable[index] = value
                        index = index + 1
                    end 
                end
            end
            if table2 then
                for _, value in ipairs(table2) do
                    if value ~= Dealer then
                        mergedTable[index] = value
                        index = index + 1
                    end 
                end
            end
            return mergedTable
        end

        -- Obtain the Both Affected Object;
        local r1, players = Area:getAreaPlayers(areaID)
        local r2, creatures = Area:getAreaCreatures(areaID)

        -- merge into target;
        local target = mergeAndRemoveDealer(selfEffect == false and playerDamageDealer or 0 ,players,creatures);

        local function CalculateDistance(pos1, pos2)
            local dx = pos2.x - pos1.x
            local dy = pos2.y - pos1.y
            local dz = pos2.z - pos1.z
            return math.sqrt(dx * dx + dy * dy + dz * dz)
        end

        local function CalculateDirBetween2Pos(pos1, pos2)
            local dx = pos2.x - pos1.x
            local dy = pos2.y - pos1.y
            local dz = pos2.z - pos1.z
            local magnitude = math.sqrt(dx * dx + dy * dy + dz * dz)
            return { x = dx / magnitude, y = dy / magnitude, z = dz / magnitude }
        end

        for i, a in ipairs(target) do
            -- calculate the distance between a -- as object within center of x,y,z; 
            local err,ax,ay,az = Actor:getPosition(a)
            if err == 0 then 
                local distance = CalculateDistance({x=x,y=y,z=z},{x=ax,y=ay,z=az});
                if distance <= radius then 
                    local l = (radius - distance)/radius;
                    if a == playerID then
                        -- Smaller the damage for self; 
                        l = l * 0.25;
                    else 
                        -- higher the damage for other;
                        l = l * 2.5;
                    end 
                    Actor:playerHurt(playerID, a, 25 + amount*l, dtype)
                    local dir = CalculateDirBetween2Pos({x=x,y=y,z=z},{x=ax,y=ay,z=az});
                    
                    Actor:appendSpeed(a, dir.x*knockback/airRessist,(dir.y*knockback)/airRessist,dir.z*knockback/airRessist)
                end 
            end
        end

        Area:destroyArea(areaID)
    end 

    -- handle damage
    DEALS_DAMAGE_2_AREA(playerDamageDealer,centerXYZ.x,centerXYZ.y,centerXYZ.z,radius,radius,radius,damage,1,knockback);

end

MISSILE.f.playEffect = function(x,y,z,effectID,soundID,scale,duration,pitch)
    if not scale then scale = 1 end ;
    if not duration then duration = 3 end ;

    -- handle special effect;
    World:playParticalEffect(x, y, z, effectID, scale)
    threadpool:delay(duration,function() World:stopEffectOnPosition(x, y, z, effectID, scale) end);

    -- handle sound effect;
    if not pitch then pitch = 1 end
    World:playSoundEffectOnPos({x=x, y=y, z=z}, soundID, 150, pitch, false);
end 

MISSILE.f.ExplodeByRadius = function(x, y, z, radius, damage, knockback, effectID, soundID, playerid,selfSatchel)
    local initXYZ = {x = x, y = y, z = z}
    local forceDrop = false 
    if radius <= 1 then 
        forceDrop = true
    end 
    -- Step 1: Break blocks in a circular/spherical radius
    for dx = -radius, radius do
        for dy = radius, -radius,-1 do
            for dz = -radius, radius do
                local distSq = dx*dx + dy*dy + dz*dz
                if distSq < radius * radius then
                    local bx, by, bz = x + dx, y + dy, z + dz
                    local ok, err = pcall(MISSILE.f.breakBlock, bx, by, bz, initXYZ, playerid,knockback,forceDrop)
                    if not ok then
                        print("[MISSILE.breakBlock] Error at ("..bx..","..by..","..bz.."): " .. tostring(err))
                    end
                end
            end
        end
    end

    -- Step 2: Deal area damage
    local ok1, err1 = pcall(MISSILE.f.dealsDamageFromPlayerToAreaRadius,{x = x, y = y, z = z}, radius, damage, knockback, playerid,selfSatchel)
    if not ok1 then
        print("[MISSILE.dealsDamageFromPlayerToAreaRadius] Error: " .. tostring(err1))
    end

    -- Step 3: Play explosion effect and sound
    local ok2, err2 = pcall(MISSILE.f.playEffect, x, y, z, effectID, soundID, 1.5, 4)
    if not ok2 then
        print("[MISSILE.playEffect] Error: " .. tostring(err2))
    end
end
