_T,_S = 0,0;

ScriptSupportEvent:registerEvent("Game.RunTime",function(e)
    _T = e.ticks;
    if e.second then _S  = e.second end
end);