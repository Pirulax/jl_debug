sx, sy = guiGetScreenSize()
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

iSettings = {
    w = 500,
    h = 200,
    x = 50,
    y = sy-210,
}

local sMsgDup = {}
local sDbgMsgs = {}

local iRowHeight = 0--This is also set when the res strts
local iMaxRows = 5
local iCurrentRow = 1
local textRenderTarget

bEditDebug = false
bDebugEnabled = false


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

    sDbgMsgs[sMsgDup[k].line] = debug.sParseMessage(aDbgMsgData, iSide, sMsgDup[k].count)

   debug.reloadRTarget()
end

debug.sParseMessage = function (aDbgMsgData, iSide, iDupCount)
    aDbgMsgData.side = sSettings.side[iSide]
    aDbgMsgData.dup = ((iDupCount>1 and sSettings.dup) or (sSettings.noDup)):gsub("dupCount", iDupCount)
    aDbgMsgData.lvl = sSettings.lvl[aDbgMsgData.lvl]
    print(aDbgMsgData.lvl)
    local str = sSettings.msgPattern
    for k, v in pairs(aDbgMsgData) do
        str = str:gsub(k, v)
    end
    return str
end 

debug.render = function()
    if (bEditDebug) then 
        drawResizeAndMove() 
    else
        dxDrawImage(iSettings.x, iSettings.y, iSettings.w, iSettings.h, textRenderTarget)
    end  
end

do
    local sText = 0
    local addY = 0
    debug.reloadRTarget = function ()
        dxSetRenderTarget(textRenderTarget, true)
        dxDrawRectangle(iSettings.x, iSettings.y, iSettings.w, iSettings.h, tocolor(0, 0, 0, 80))
        sText = sDbgMsgs[iCurrentRow]
        addY = 2
        for i = iCurrentRow, iCurrentRow+iMaxRows do       
            if not (sText) then print("breaked at", i, "Dbgmsgs size", #sDbgMsgs) break end
            if (bTextShadow) then dxDrawText(sText, 2+1.75, addY+1.75, 0, 0, tocolor(0, 0, 0, 255), 1, uFont, "left", "top", false, false, false, true) end
            dxDrawText(sText, 2, addY, 0, 0, iColorWhite, 1, uFont, "left", "top", false, false, false, true)
            addY = addY+iRowHeight
            for _ in string.gmatch(sText, "\n") do addY = addY+iRowHeight end     
            _, sText = next(sDbgMsgs, i)   
        end
        dxSetRenderTarget()
        return true
    end
end

debug.tog = function(sDataName)
    bDebugEnabled = getElementData(localPlayer, "debug:state")
    local func = ((bDebugEnabled and addEventHandler) or (removeEventHandler)) --> MTA is retarded, so i need to use this form..
    func("onClientRender", root, debug.render)
    func("onClientClick", root, clickHandler)
    loadSelf()    
end

function calculateMaxRows()
    iMaxRows = math.floor(iSettings.h/iRowHeight)-1
end

function recreateRTarget(bSkipReload)
    if (isElement(textRenderTarget)) then destroyElement(textRenderTarget) end--> we destroy the old rtaget, so we free up vram
    textRenderTarget = dxCreateRenderTarget(iSettings.w, iSettings.h, true)
    if not (bSkipReload) then debug.reloadRTarget() end
end

--> event handlers
addEventHandler("onClientElementDataChange", localPlayer,
    function(sDataName)
        if (sDataName=="debug:state") then
            debug.tog()
        end
    end)

addEventHandler("onClientResourceStart", resourceRoot,
    function ()
        if (uHandle) then
            local tbl = fromJSON(fileRead(uHandle, fileGetSize(uHandle)))
            --> Because there are 2 tables in the loaded file we need to go thru them one by one.
            if (tbl) then
                for sSettingsTblName, sSettingsTbl in pairs({sSettings = sSettings, iSettings = iSettings}) do              
                    if (tbl[sSettingsTblName]) then
                        for k, v in pairs(sSettingsTbl) do                                
                            if (type(tbl[sSettingsTblName][k])==type(v)) then
                                sSettingsTbl[k] = tbl[sSettingsTblName][k]
                            else
                                outputDebugString(string.format("Failed to set value %s[Types: %s, %s]"), k, type(tbl[sSettingsTblName][k]), type(v))
                            end
                        end
                    else
                        outputDebugString("Failed to load "..sSettingsTblName.." tbl.", 1)
                    end           
                end
            else
                outputDebugString("Failed to load settings file.")
            end
            --> we set the variables outside the loop, since we cant(actually, its possible with loadstring, but lets do it the harder way.) set it with loop.
            tbl = tbl.vars
            bTextShadow = tbl.bTextShadow
        end
        --> if the font specified doesnt exists we load the roboto font, since it exists always, because its included in the meta.
        if not (fileExists(sSettings.fontPath)) then outputDebugString("Changed font from the set to 'files/fonts/roboto.ttf', because the set font is probably deleted.", 1) sSettings.fontPath = "files/fonts/roboto.ttf" end
        uFont = dxCreateFont(sSettings.fontPath , iSettings.fontSize or 10, false) or "default"   
        iRowHeight = dxGetFontHeight(1, uFont)  
        debug.tog()
        calculateMaxRows()
        recreateRTarget(true)   
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
                print "down" 
            end
        end
    end
)

bindKey("mouse_wheel_up", "down", 
    function() 
        if (bDebugEnabled) then
            if (iCurrentRow>1) then
                iCurrentRow = iCurrentRow-1
                print "up"
            end
        end
    end
)

debug.togEditMode = function()
    if (bDebugEnabled) then if (isCursorShowing()) then bEditDebug = not bEditDebug end end
end
bindKey("lctrl", "both", debug.togEditMode)
bindKey("rctrl", "both", debug.togEditMode)

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