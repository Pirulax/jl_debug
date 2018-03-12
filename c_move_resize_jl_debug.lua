local bMove = false
local iMove = {
    x = 0,
    y = 0,
}

local bResize = false
local iiResizeData = {}

local iMinSize = {
    w = 50,
    h = 50,
}

local bShowCursor = false
local cx, cy = 0, 0

local iCirclePositions = {}
local pw, ph , px, py = 0, 0, 0, 0

local uCircleTexture

function resizeFunction(_, _, cx, cy)
    if (iResizeData.moveTo=="top_left")then
        pw = (iResizeData.x - cx) + iResizeData.w
        ph = (iResizeData.y - cy) + iResizeData.h

        px = cx
        py = cy
    elseif (iResizeData.moveTo=="top_right") then
        pw = (cx - iResizeData.x) + iResizeData.w
        ph = (iResizeData.y - cy) + iResizeData.h

        py = cx
        py = cy
    elseif (iResizeData.moveTo=="bottom_left") then    
        pw = (iResizeData.x - cx) + iResizeData.w
        ph = (cy - iResizeData.y) + iResizeData.h

        px = cx
    elseif (iResizeData.moveTo=="bottom_right") then
        pw = (cx - iResizeData.x) + iResizeData.w
        ph = (cy - iResizeData.y) + iResizeData.h
    elseif (iResizeData.moveTo=="left") then
        pw = (iResizeData.x - cx) + iResizeData.w

        px = cx
    elseif (iResizeData.moveTo=="right") then
        pw = (cx - iResizeData.x) + iResizeData.w  
    elseif (iResizeData.moveTo=="top") then
        ph = (iResizeData.y - cy) + iResizeData.h

        py = cy
    elseif (iResizeData.moveTo=="bottom") then
        ph = (cy - iResizeData.y) + iResizeData.h
    end
    iSettings.x, iSettings.y, iSettings.w, iSettings.h = px, py, pw, ph
end 

function clickHandler(button, state, cx, cy)
    if not (bDebugEnabled) then return end
    if not (bEditDebug) then return end
    if (button=="left") and (state=="down") then
        for moveName,pos in pairs(iCirclePositions) do
            if (isCursorOnBox(pos.x ,pos.y, 8, 8)) then
                iResizeData = {
                    x = cx,
                    y = cy,
                    w = pw,
                    h = ph,
                    moveTo = moveName,
                }
                addEventHandler("onClientCursorMove", root, resizeFunction)
                bResize = true
                return
            end
        end

        if (isCursorOnBox(px, py, pw, ph)) then
            iMove = {
                offsetX = cx - px,
                offsetY = cy - py, 
            }
            bMove = true
        end   
    elseif (button=="left") and (state=="up") then
        calculateCirclePositions()
        calculateMaxRows()
        recreateRTarget()
        if (bResize) then
            removeEventHandler("onClientCursorMove", root, resizeFunction)
        end 
        bMove = false
        bResize = false
    end
end

function calculateCirclePositions()
    pw, ph, px, py = iSettings.w, iSettings.h, iSettings.x, iSettings.y
    iCirclePositions = {
        top_left = {x = px - 4, y = py - 4},
        top_right = {x = px + pw - 4, y = py - 4},
        bottom_left = {x = px - 4, y = py + ph - 4},
        bottom_right = {x = px + pw - 4, y = py + ph - 4},
    
        top = {x = px + pw/2 + - 4, y = py - 4},
        bottom = {x = px + pw/2 + - 4, y = py + ph - 4},
        left = {x = px - 4, y = py + ph/2 - 4},
        right = {x = px + pw - 4, y = py + ph/2 - 4}
    }
end

function isCursorOnBox(x, y, w, h)
    if (bShowCursor) then   
        return (cx >= x and cx <= x+w and cy >= y and cy <= y+h)
    end	
end

function drawResizeAndMove()
    bShowCursor = isCursorShowing()
    if (bShowCursor) then
        cx, cy = getCursorPosition()
        cx, cy = cx*sx, cy*sy
    end
    if (bMove) then
        iSettings.x, iSettings.y = cx-iMove.offsetX, cy-iMove.offsetY
    elseif not (bResize) then
        for _, pos in pairs(iCirclePositions) do
            dxDrawImage(pos.x, pos.y, 8, 8, uCircleTexture)
        end
    end
end

function loadSelf()
    uCircleTexture = dxCreateTexture("files/images/circle.dds", "dxt5", false, "wrap")
    calculateCirclePositions()
end

bindKey("m", "down", function() showCursor(not isCursorShowing()) end)
--> Event handlers
