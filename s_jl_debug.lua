local sStates = {
    [true] = "#056315on.",
    [false] = "#db1106off."
}

addCommandHandler("togdebug", 
    function(uPlayer)
        if (hasObjectPermissionTo(uPlayer, "function.togDebug")) then
            local bNewState = not getElementData(uPlayer, "debug:state")
            setElementData(uPlayer, "perm:togDebug", true)--> We need to set this, since we dont have 'hasObjectPermissionTo' on client-side
            setElementData(uPlayer, "debug:state", bNewState)--> We just set the state of the debug to NOT the current state.
            outputChatBox("#073b84[Info]:#FFFFFF You turned the debug "..sStates[bNewState], uPlayer, 255, 255, 255, true)
        end
    end, false, false
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
        if (#aDebugMessagesToSend>0) then --> only if thers message to send
            for _, player in pairs(getElementsByType("player")) do
                if (getElementData(player, "debug:state")) then
                    triggerClientEvent("jlDebug:serverDebugMsg", player, aDebugMessagesToSend)
                end
            end
            aDebugMessagesToSend = {}--> we clear the table.
        end
    end, 1000, 0 --> 1 sec.
)