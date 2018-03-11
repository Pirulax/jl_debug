addCommandHandler("togdebug", 
    function(player, cmd)
        if (hasObjectPermissionTo(player, "function.togDebug")) then
            setElementData(player, "perm:togDebug", true)--> We need to set this, since we dont have 'hasObjectPermissionTo' on client-side
            setElementData(player, "debug:state", not getElementData(player, "debug:state"))--> We just set the state of the debug to NOT the current state.
        end
    end
)

local aDebugMessagesToSend = {}
addEventHandler("onDebugMessage", root,
    function(msg, lvl, file, line, r, g, b)
        aDebugMessagesToSend[#aDebugMessagesToSend+1] = {--> We send out messages to clients every 1sec.
            msg = msg, 
            lvl = lvl,
            file = file,
            line = line,
            color = {r, g, b},
        }
    end
)

setTimer(
    function()
        if (#aDebugMessagesToSend>1) then --> only if thers message to send
            for _, player in pairs(getElementsByType("player")) do
                if (getElementData(player, "debug:state")) then
                    triggerClientEvent("jlDebug:serverDebugMsg", player, aDebugMessagesToSend)
                end
            end
            aDebugMessagesToSend = {}--> we clear the table.
        end
    end, 1000--> 1 sec.
)