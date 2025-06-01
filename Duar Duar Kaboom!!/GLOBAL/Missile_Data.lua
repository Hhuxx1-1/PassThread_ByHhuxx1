-- Bom;
local error = MISSILE:REGISTER(4098)
:SET_CREATE(function(e)
    Actor:playSoundEffectById(e.toobjid,10664 , 100, 1, false)
    Actor:playBodyEffectById(e.toobjid,1333, 1)
    threadpool:delay(3,function()
        local r,posX,posY,posZ = Actor:getPosition(e.toobjid);
        print(e);
        MISSILE.f.ExplodeByRadius(posX,posY,posZ, 5, 500, 45, 1009, 10538, e.helperobjid);
        Actor:killSelf(e.toobjid);
    end)
end)
:SET_HIT(function()
    
end)
;
-- Box;
local error = MISSILE:REGISTER(12298)
:SET_CREATE(function(e)
    Actor:playBodyEffectById(e.toobjid,1226, 0.7);
    -- use threadpool to delay its deletetion randomly;
    threadpool:delay(math.random(4, 7),function()
        Actor:killSelf(e.toobjid);
    end)
end)
:SET_HIT(function()
    
end)
;
-- Normal Bullet;
local error = MISSILE:REGISTER(15003)
:SET_HIT(function(e)
    -- print("Hit Event : ",e);
    if math.random() < 0.6 then 
        MISSILE.f.ExplodeByRadius(e.x,e.y,e.z, 1, 1, 0, 0, 0, e.helperobjid);
    end 
end)
:SET_CREATE(function(e)
    -- print("Create Event : ",e);
    -- create line 
    local r,x,y,z = Actor:getFaceDirection(e.eventobjid)
	local size , color = 0.25 , 0xff0000;
	local id = 1;
	local info=Graphics:makeGraphicsLineToPos(e.x+x,e.y+y-1.5,e.z+z, size, color, id)
	local offset , dir =  0 , {x=0,y=0,z=0}--Offset direction
	Graphics:createGraphicsLineByActorToPos(e.toobjid, info, dir, offset)
end)
;
-- Explosive Bullet;
local error = MISSILE:REGISTER(4109)
:SET_HIT(function(e)
    -- print("Hit Event : ",e);
    MISSILE.f.ExplodeByRadius(e.x,e.y,e.z, 2, 200, 20, 1009, 10660, e.helperobjid);
end)
:SET_CREATE(function(e)
    -- print("Create Event : ",e);
    -- create line 
    local r,x,y,z = Actor:getFaceDirection(e.eventobjid)
	local size , color = 0.25 , 0xff0000;
	local id = 1;
	local info=Graphics:makeGraphicsLineToPos(e.x+x,e.y+y-1.5,e.z+z, size, color, id)
	local offset , dir =  0 , {x=0,y=0,z=0}--Offset direction
	Graphics:createGraphicsLineByActorToPos(e.toobjid, info, dir, offset)
end)
;

-- Missile Rpg;
local error = MISSILE:REGISTER(4102)
:SET_HIT(function(e)
    print(e);
    MISSILE.f.ExplodeByRadius(e.x,e.y,e.z,  math.random(4,6), 500, 45, 1009, 10660, e.helperobjid);
end)
:SET_CREATE(function(e)
    Actor:playSoundEffectById(e.toobjid, 10637, 100, 1, false)
    Actor:playBodyEffectById(e.toobjid,1194, 1)
end)
;

-- Quick Grenade;
local error = MISSILE:REGISTER(4103)
:SET_HIT(function(e)
    print(e);
    threadpool:delay(1,function()
        local r,posX,posY,posZ = Actor:getPosition(e.eventobjid);
        MISSILE.f.ExplodeByRadius(posX,posY,posZ,  math.random(4,6), 500, 45, 1009, 10660, e.helperobjid);
        Actor:killSelf(e.eventobjid);
    end)
end)
:SET_CREATE(function(e)

end)
;

-- Quick Grenade;
local error = MISSILE:REGISTER(4107)
:SET_HIT(function(e)
    print(e);
    threadpool:delay(1,function()
        local r,posX,posY,posZ = Actor:getPosition(e.eventobjid);
        MISSILE.f.ExplodeByRadius(posX,posY,posZ,  math.random(4,6), 500, 45, 1009, 10660, e.helperobjid);
        Actor:killSelf(e.eventobjid);
    end)
end)
:SET_CREATE(function(e)

end)
;