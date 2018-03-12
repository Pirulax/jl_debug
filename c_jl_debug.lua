local sx, sy = guiGetScreenSize()
local _dxText = dxDrawText
local dxDrawText = function(text, x, y, w, h, ...) _dxText(text, x, y, x+(w or 0), y+(h or 0), ...) end
local dxDrawShadowedText = function(text, x, y, w, h, color, ...)
    dxDrawText(text, x+1.75, y+1.75, w, h, tocolor(0, 0, 0, 255), ...)
    dxDrawText(text, x, y, w, h, color, ...)
end

local iColorWhite = tocolor(255, 255, 255)

local fDebug = {}
local sSettings = {
    unknownFile = "Unknown",
    unknownLine = "Unknown",
    msgPattern = "dup [lvl][side] file:line -> msg",
    noDup = "",
    dup = "dupCountx",
    lvl = {
        [0] = "Custom",
        [1] = "Error",
        [2] = "Warning",
        [3] = "Info"
    },
    side = {
        [1] = "Server",
        [2] = "Client"
    },
    fontPath = "files/fonts/roboto.ttf"
}
local bTextShadow = true
--> this is set when the resource starts.
local uFont
local iFontHeight

local iSettings = {
    w = 500,
    h = 200,
    x = 50,
    y = sy-210,
}

local bMove = false
local iMove = {
    x = 0,
    y = 0,
}

local bResize = false
local iResize = {}

local sMsgDup = {}
local sDbgMsgs = {}

local iMaxRows = 5
local iCurrentRow = 1
local textRenderTarget

local bDebugEnabled = false


local sPath = "settings.json"
local uHandle = fileExists(sPath) and fileOpen(sPath)

--> aDbgMsgData -> {msg = msg, lvl = lvl, file = file, line = line, color={r, g, b}}
--> side -> client or server
debug.addMessage = function (aDbgMsgData, iSide)
    aDbgMsgData.file = aDbgMsgData.file or sSettings.unknownFile
    aDbgMsgData.line = aDbgMsgData.line or sSettings.unknownLine
    local k = aDbgMsgData.file..aDbgMsgData.line..aDbgMsgData.msg --> the key for the MsgDups table
    createIndexIfNil(sMsgDup, k, {
        count = 0,
        line = #sDbgMsgs+1,
    })
    sMsgDup[k].count = sMsgDup[k].count+1

    sDbgMsgs[sMsgDup[k].line] = debug.parseMessage(aDbgMsgData, iSide, sMsgDup[k].count)

   debug.reloadRTarget()
end

debug.parseMessage = function (aDbgMsgData, iSide, iDupCount)
    aDbgMsgData.side = sSettings.side[iSide]
    aDbgMsgData.dup = ((iDupCount>1 and sSettings.dup) or (sSettings.noDup)):gsub("dupCount", iDupCount)
    aDbgMsgData.lvl = sSettings.lvl[aDbgMsgData.lvl]

    print("dupmsg", aDbgMsgData.dup)
    local str = sSettings.msgPattern
    for k, v in pairs(aDbgMsgData) do
        str = str:gsub(k, v)
    end
    return str
end 

debug.render = function()
    dxDrawImage(iSettings.x, iSettings.y, iSettings.w, iSettings.h, textRenderTarget)
    dxDrawRectangle(iSettings.x, iSettings.y, iSettings.w, iSettings.h, tocolor(0, 0, 0, 80))
end

do
    local sText = 0
    local addY = 0
    debug.reloadRTarget = function ()
        dxSetRenderTarget(textRenderTarget, true)
        dxDrawRectangle(0, 0, iSettings.w, iSettings.h, tocolor(0, 0, 0, 0))
        sText = sDbgMsgs[iCurrentRow]
        addY = 2
        for i = iCurrentRow, iCurrentRow+iMaxRows do       
            if not (sText) then print("breaked at", i, "Dbgmsgs size", #sDbgMsgs) break end
            dxDrawShadowedText(sText, 0, addY, 0, 0, iColorWhite, 1, uFont, "left", "top", false, false, false, true)
            addY = addY+iFontHeight+2
            for _ in string.gmatch(sText, "\n") do addY = addY+iFontHeight+2 end     
            _, sText = next(sDbgMsgs, i)   
        end
        dxSetRenderTarget()
        return true
    end
end

--TODO REPORT BUG
debug.tog = function(sDataName)
    if (sDataName=="debug:state") then
        bDebugEnabled = getElementData(localPlayer, sDataName)
        local func = ((bDebugEnabled and addEventHandler) or (removeEventHandler)) --> MTA is retarded, so i need to use this form..
        func("onClientRender", root, debug.render)
    end
end

--> event handlers
addEventHandler("onClientElementDataChange", localPlayer,debug.tog)

addEventHandler("onClientResourceStart", resourceRoot,
    function ()
        if (uHandle) then
            local tbl = fromJSON(fileRead(uHandle, fileGetSize(uHandle)))
            --> Because there are 2 tables in the loaded file we need to go thru them one by one.
            for sSettingsTblName, sSettingsTbl in pairs({sSettings = sSettings, iSettings = iSettings}) do
                if (tbl) then
                    if (tbl[sSettingsTblName]) then
                        for k, v in pairs(sSettingsTbl) do                                
                            if (type(tbl[sSettingsTblName][k])==type(v)) then
                                v = tbl[sSettingsTblName][k]
                            end
                        end
                    else
                        outputDebugString("Failed to load "..sSettingsTblName.." tbl.", 1)
                    end
                end
            end
            tbl = tbl.vars
            bTextShadow = tbl.bTextShadow
        end
        if not (fileExists(sSettings.fontPath)) then outputDebugString("Changed font from the set to 'files/fonts/roboto.ttf', because the set font is probably deleted.", 1) sSettings.fontPath = "files/fonts/roboto.ttf" end
        uFont = dxCreateFont(sSettings.fontPath , iSettings.fontSize or 10, false) or "default"
        iFontHeight = dxGetFontHeight(1, uFont)
        textRenderTarget = dxCreateRenderTarget(iSettings.w, iSettings.h, true)
        debug.tog("debug:state")
        
    end
)

addEventHandler("onClientResourceStop", resourceRoot,
    function()
        --> Save the settings
        uHandle = uHandle or fileCreate(sPath)
        fileSetPos(uHandle, 0)
        fileWrite(uHandle, toJSON({sSettings = sSettings, iSettings = iSettings, vars = {bTextShadow = bTextShadow}}))
        fileFlush(uHandle)
        fileClose(uHandle)
    end
)

addEventHandler("onClientDebugMessage", root,
    function(msg, lvl, file, line, r, g, b)
        debug.addMessage({
            msg = msg, 
            lvl = lvl,
            file = file,
            line = line,
            color = {r, g, b},   
        }, 2)
    end
    
)

addEvent("jlDebug:serverDebugMsg", true)
addEventHandler("jlDebug:serverDebugMsg", localPlayer, 
    function (aDebugMessages)
        for _,v in pairs(aDebugMessages) do
            debug.addMessage(v, 1)
        end
    end
)

--> scrolling
bindKey("mouse_wheel_down", "down", 
    function() 
        if (bDebugEnabled) then
            if (iCurrentRow<#sDbgMsgs-iMaxRows) then
                iCurrentRow = iCurrentRow+1
            end
        end
    end
)

bindKey("mouse_wheel_up", "down", 
    function() 
        if (bDebugEnabled) then
            if (iCurrentRow>0) then
                iCurrentRow = iCurrentRow-1
            end
        end
    end
)


--> command handlers
addCommandHandler("cleard", 
    function()
        sDbgMsgs = {}
        sMsgDup = {}
        --> just to clear the rTarget, and because thers no text at all, we dont need to refresh it.
        dxSetRenderTarget(textRenderTarget, true);dxSetRenderTarget()       
        iCurrentRow = 1
        outputChatBox("#073b84[Info]:#FFFFFF Successfully cleared the debug.", 255, 255, 255, true)
    end)

--> TODO REMOVE
addCommandHandler("printtexttodebug",
    function(_, ...)
        outputDebugString(table.concat({...}, " "))
    end, false)