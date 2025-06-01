CODE = {}

ENABLE_TEST = false;

function CODE_TEST_REGISTER (key,f)

    CODE[key] = f

end 

ScriptSupportEvent:registerEvent("Player.InputContent",function(e)

    if e.eventobjid == 1029380338 or e.eventobjid == 1245960258 then 
        if ENABLE_TEST then 
            if CODE[e.content] then 
                if type(CODE[e.content]) == "function" then 
                    local r,err = pcall(CODE[e.content],e.eventobjid);
                    if not r then 
                        print(err);
                    end 
                end
            end 
        else 
            if e.content == "START_TEST" then 
                ENABLE_TEST = true; 
                Player:notifyGameInfo2Self(e.eventobjid,"TEST ENABLED");
            end 
        end
    end 

end)