UIZ = {}
local UIZ_BUTTON_ACTION = {}
local BUTTON_COOLDOWN_TICKS = 5  -- 5 ticks = 0.25 seconds (adjust as needed)
local LAST_PRESS_TICK = {}         -- Stores last press tick per player-element combo

-- Handle button press with tick-based anti-spam
function UIZ_BUTTON(playerid, elementid)
    -- Initialize player data
    UIZ_BUTTON_ACTION[playerid] = UIZ_BUTTON_ACTION[playerid] or {}
    LAST_PRESS_TICK[playerid] = LAST_PRESS_TICK[playerid] or {}

    -- Get current tick
    local currentTick = _T

    -- Check cooldown
    if LAST_PRESS_TICK[playerid][elementid] then
        local ticksSinceLastPress = currentTick - LAST_PRESS_TICK[playerid][elementid]
        if ticksSinceLastPress < BUTTON_COOLDOWN_TICKS then
            return  -- Block if pressed too soon
        end
    end

    -- Update last press time
    LAST_PRESS_TICK[playerid][elementid] = currentTick

    -- Execute action
    local action = UIZ_BUTTON_ACTION[playerid][elementid]
    if type(action) == "function" then
        local success, err = pcall(action, playerid, elementid)
        if not success then
            Player:notifyGameInfo2Self(playerid, "Error: "..tostring(err))
        end
    end
end

local _debug = false;

setmetatable(UIZ, {
    __call = function(t, uiid, playerid)
        local _elements = {} -- Stores element_name -> element_id mappings
        local _current_player = playerid
        
        local function element_func(name_or_id, id)
            -- Clear case
            if name_or_id == nil and id == nil then
                _elements = {}
                return
            end
            
            -- ID only case: element(1)
            if type(name_or_id) == "number" or type(name_or_id) == "string" and id == nil then
                return uiid.."_"..tostring(name_or_id)
            end
            
            -- Set case: element("textBox1", 2)
            if id ~= nil then
                _elements[name_or_id] = uiid.."_"..tostring(id)
                local proxy = {
                    _uiid = uiid,
                    _element_id = _elements[name_or_id],
                    _playerid = _current_player
                }
                -- Attach all API methods
                for method_name, method in pairs({
                    setText = function(_, text)
                        return Customui:setText(_current_player, uiid, _elements[name_or_id], text) == 0
                    end,
                    setTexture = function(_, texture)
                        return Customui:setTexture(_current_player, uiid, _elements[name_or_id], texture) == 0
                    end,
                    setFontSize = function(_, size)
                        return Customui:setFontSize(_current_player, uiid, _elements[name_or_id], size) == 0
                    end,
                    setSize = function(_, width, height)
                        return Customui:setSize(_current_player, uiid, _elements[name_or_id], width, height) == 0
                    end,
                    setColor = function(_, a)
                        a = a or 0xffffff
                        return Customui:setColor(_current_player, uiid, _elements[name_or_id], a) == 0
                    end,
                    show = function(_)
                        return Customui:showElement(_current_player, uiid, _elements[name_or_id]) == 0
                    end,
                    hide = function(_)
                        return Customui:hideElement(_current_player, uiid, _elements[name_or_id]) == 0
                    end,
                    rotate = function(_, angle)
                        return Customui:rotateElement(_current_player, uiid, _elements[name_or_id], angle) == 0
                    end,
                    setState = function(_, state)
                        return Customui:setState(_current_player, uiid, _elements[name_or_id], state) == 0
                    end,
                    setAlpha = function(_, alpha)
                        return Customui:setAlpha(_current_player, uiid, _elements[name_or_id], alpha) == 0
                    end,
                    setPosition = function(_, x, y)
                        return Customui:setPosition(_current_player, uiid, _elements[name_or_id], x, y) == 0
                    end,
                    setAction = function(_,func)
                        UIZ_BUTTON_ACTION[playerid] = UIZ_BUTTON_ACTION[playerid] or {}
                        UIZ_BUTTON_ACTION[playerid][_elements[name_or_id]] = func;
                        return true;
                    end,
                    unsetAction = function(_)
                        UIZ_BUTTON_ACTION[playerid] = UIZ_BUTTON_ACTION[playerid] or {}
                        UIZ_BUTTON_ACTION[playerid][_elements[name_or_id]] = nil;
                        return true;
                    end
                }) do
                    proxy[method_name] = function(self, ...)
                        -- handle error;
                        local result = method(self, ...) and self or false;
                        if _debug then 
                            if not result then 
                                print(method_name.." Failed to Execute at "..tostring(self._uiid)..":"..tostring(self._element_id))
                            else
                                -- handle debugging
                                print(method_name.." Executed at "..tostring(self._element_id),"With Parameters : ",{...})
                            end 
                        end 
                        return result;
                    end
                end
                
                return proxy
            end
            
            -- Get case: element("textBox1")
            if _elements[name_or_id] then
                return uiid.."_".._elements[name_or_id]
            end
            
            return nil
        end
        
        return element_func
    end
})

