local sx, sy = guiGetScreenSize()
local _dxText = dxDrawText
local dxDrawText = function(text, x, y, w, h, ...) dxDrawText(text, x, y, x+w, y+h, ...) end
local dxDrawShadowedText = function(text, x, y, ...)
    dxDrawText(text, x-2, y+2, ...)
    dxDrawText(text, x, y, ...)
end

local iColorWhite = tocolor(255, 255, 255)

local fDebug = {}
local sSettings = {
    unknownFile = "Unknown",
    unknownLine = "Unknown",
    msgPattern = "dupmsg [lvl][side] file:line -> msg",
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
local iCurrentRow = 0
local textRenderTarget

local bDebugEnabled = false

addEvent("jlDebug:serverDebugMsg", true)
addEventHandler("jlDebug:serverDebugMsg", localPlayer, 
    function (aDebugMessages)
        for _,v in pairs(aDebugMessages) do
            debug.addMessage(v, 1)
            (print or io.write)('done')
        end
    end
)

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
end

debug.parseMessage = function (aDbgMsgData, iSide, iDupCount)
    aDbgMsgData.side = sSettings.side[iSide]
    aDbgMsgData.dupmsg = ((iDupCount>1 and sSettings.dip) or (sSettings.noDup)):gsub("dupCount", iDupCount)
    aDbgMsgData.lvl = sSettings.lvl[aDbgMsgData.lvl]

    local str = sSettings.msgPattern
    for k, v in pairs(aDbgMsgData) do
        str = str:gsub(k, v)
    end
    return str
end 

deubg.render = function()
    dxDrawImage(iSettings.x, iSettings.y, iSettings.w, iSettings.h, textRenderTarget)
end

do
    local i = 0
    local sText = 0
    local addY = 0
    debug.reloadRTarget = function ()
        dxSetRenderTarget(textRenderTarget, true)
        i = iCurrentRow
        sText = 0
        addY = 2
        while ((i or iCurrentRow+iMaxRows+1)<iCurrentRow+iMaxRows) do
            i, sText = next(sDbgMsgs, i)
            dxDrawShadowedText(sText, 0, addY, 0, 0, iColorWhite, 1, uFont, "top", "left", false, false, true)
            addY = addY+iFontHeight+2
            for _ in string.gmatch(sText, "\n") do addY = addY+iFontHeight+2 end
        end
        dxSetRenderTarget()
    end
end

addEventHandler("onClientElementDataChange", localPlayer,
    function (sDataName)
        if (sDataName=="debug:state") then
            bDebugEnabled = getElementData(localPlayer, sDataName)
            ((bDebugEnabled and addEventHandler) or (removeEventHandler))("onClientRender", root, debug.render)
        end
    end)


local sPath = "settings.json"
local uHandle = fileExists(sPath) and fileOpen(sPath)
addEventHandler("onClientResourceStart", resourceRoot,
    function ()
        if (uHandle) then
            local tbl = toJSON(fileRead(uHandle, fileGetSize(uHandle)))
            --> Because there are 2 tables in the loaded file we need to go thru them one by one.
            for sSettingsTblName, sSettingsTbl in pairs({sSettings = sSettings, iSettings = iSettings}) do
                if (tbl) then
                    for k, v in pairs(sSettingsTbl) do                                
                        if (type(tbl[sSettingsTblName][k])==type(v)) then
                            v = tbl[sSettingsTblName][k]
                        end
                    end
                end
            end
            tbl = tbl.vars
            bTextShadow = tbl.bTextShadow
        end
        uFont = dxCreateFont((fileExists(sSettings.fontPath) and sSettings.fontPath) or ("file/fonts/roboto.ttf") , iSettings.fontSize or 10, false) or "default"
        iFontHeight = dxGetFontHeight(1, uFont)
        textRenderTarget = dxCreateRenderTarget(iSettings.w, iSettings.h, true)
    end)

addEventHandler("onClientResourceStop", resourceRoot,
    function()
        --> Save the settings
        uHandle = uHandle or fileCreate(sPath)
        fileSetPos(uHandle, 0)
        fileWrite(uHandle, toJSON({sSettings = sSettings, iSettings = iSettings, vars = {bTextShadow = bTextShadow}}))
        fileFlush(uHandle)
        fileClose(uHandle)
    end)


bindKey("mouse_wheel_down", "down", 
    function() 
        if (bDebugEnabled) then
            if (iCurrentRow<#sDbgMsgs-iMaxRows) then
                iCurrentRow = iCurrentRow+1
            end
        end
	end)

bindKey("mouse_wheel_up", "down", 
    function() 
        if (bDebugEnabled) then
            if (iCurrentRow>0) then
                iCurrentRow = iCurrentRow-1
            end
        end
	end)
