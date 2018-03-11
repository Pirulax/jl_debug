local sx, sy = guiGetScreenSize()

local fDebug = {}
local sSettings = {
    unknownFile = "Unknown",
    unknownLine = "Unknown",
    msgPattern = "dupmsg [lvl][side] file:line -> msg",
    noDup = "",
    dup = "dupCountx",
    lvl = {
        [0] = "Custom",
        [1] = "Erorr",
        [2] = "Warning",
        [3] = "Info"
    },
    side = {
        [1] = "Server",
        [2] = "Client"
    },
}

--> this is set when the resource starts.
local uFont

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

local iMaxRow = 5
local iCurrentRow = 0
local textRenderTarget


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

    sDbgMsgs[sMsgDup[k].line].text = debug.parseMessage(aDbgMsgData, iSide, sMsgDup[k].count)
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

debug.render = function ()
    dxDrawImage(iSettings.x, iSettings.y, iSettings.w, iSettings.h, textRenderTarget)
end

addEventHandler("onClientElementDataChange", localPlayer,
    function (sDataName)
        if (sDataName=="debug:state") then
            ((getElementData(localPlayer, sDataName) and addEventHandler) or (removeEventHandler))("onClientRender", root, debug.render)
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
        end
        uFont = dxCreateFont((fileExists(sSettings.fontPath) and sSettings.fontPath) or ("file/fonts/roboto.ttf") , iSettings.fontSize or 10, false) or "default"
    end)

addEventHandler("onClientResourceStop", resourceRoot,
    function()
        --> Save the settings
        uHandle = uHandle or fileCreate(sPath)
        fileSetPos(uHandle, 0)
        fileWrite(uHandle, toJSON({sSettings = sSettings, iSettings = iSettings}))
        fileFlush(uHandle)
        fileClose(uHandle)
    end)
