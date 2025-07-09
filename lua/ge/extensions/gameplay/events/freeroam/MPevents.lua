local M = {}

local im = ui_imgui
local ffi = require("ffi")

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

-- Dialog state
local dialogState = {
    isOpen = false,
    raceName = "",
    laps = 0,
    result = nil
}

-- Action dialog state
local actionDialogState = {
    isOpen = false,
    action = "",
    playerName = "",
    playerId = "",
    reason = "",
    result = nil
}

local vehicleVisibilityHidden = false

local targetedHidingState = {
    vehicleIds = {},
    hidden = false
}

local function findVehicles(group)
    local vehicles = {}
    for i, objName in ipairs(group:getObjects()) do
        local obj = scenetree.findObject(objName)
        if obj then
            if obj:getClassName() == "BeamNGVehicle" then
                table.insert(vehicles, obj)
            end
            if obj:getClassName() == "SimGroup" then
                local childVehicles = findVehicles(obj)
                for _, vehicle in ipairs(childVehicles) do
                    table.insert(vehicles, vehicle)
                end
            end
        end
    end
    return vehicles
end

local function isVehicleHidden(vehicleId)
    for _, id in ipairs(targetedHidingState.vehicleIds) do
        if id == vehicleId then
            return true
        end
    end
    return false
end

-- ============================================================================
-- DIALOG FUNCTIONS
-- ============================================================================

local function showRaceJoinDialog(raceName, laps)
    local result = nil

    -- Center the window on screen
    local viewport = im.GetMainViewport()
    local center = im.ImVec2(viewport.WorkPos.x + viewport.WorkSize.x * 0.5,
        viewport.WorkPos.y + viewport.WorkSize.y * 0.5)
    im.SetNextWindowPos(center, im.Cond_Appearing, im.ImVec2(0.5, 0.5))

    local windowFlags = im.WindowFlags_AlwaysAutoResize + im.WindowFlags_NoCollapse + im.WindowFlags_NoResize
    local isOpen = im.BoolPtr(true)

    if im.Begin("Race Join Invitation", isOpen, windowFlags) then
        im.Text("Race is starting at " .. (raceName or "Unknown Race") .. " for " .. (laps or "Unknown") .. " Laps.")
        im.Text("Do you want to join?")

        im.Separator()

        if im.Button("Join", im.ImVec2(100, 0)) then
            result = "join"
            dialogState.result = "join"
            dialogState.isOpen = false
        end

        im.SameLine()

        if im.Button("Decline", im.ImVec2(100, 0)) then
            result = "decline"
            dialogState.result = "decline"
            dialogState.isOpen = false
        end

        im.End()
    end

    -- Check if window was closed via X button
    if not isOpen[0] then
        dialogState.result = "decline"
        dialogState.isOpen = false
    end

    return result
end

local function openRaceJoinDialog(raceName, laps)
    dialogState.isOpen = true
    dialogState.raceName = raceName or "Unknown Race"
    dialogState.laps = laps or "Unknown"
    dialogState.result = nil
end

local function isDialogOpen()
    return dialogState.isOpen
end

local function getDialogResult()
    return dialogState.result
end

local function clearDialogResult()
    dialogState.result = nil
end

local function handleRaceInvitation(raceName, laps)
    openRaceJoinDialog(raceName, laps)
end

-- ============================================================================
-- ACTION DIALOG FUNCTIONS
-- ============================================================================

local function showActionDialog(action, playerName, playerId)
    local result = nil

    local viewport = im.GetMainViewport()
    local center = im.ImVec2(viewport.WorkPos.x + viewport.WorkSize.x * 0.5,
        viewport.WorkPos.y + viewport.WorkSize.y * 0.5)
    im.SetNextWindowPos(center, im.Cond_Appearing, im.ImVec2(0.5, 0.5))

    local windowFlags = im.WindowFlags_AlwaysAutoResize + im.WindowFlags_NoCollapse + im.WindowFlags_NoResize
    local isOpen = im.BoolPtr(true)

    im.PushStyleColor2(im.Col_WindowBg, im.ImVec4(0.13, 0.13, 0.13, 0.95))
    im.PushStyleColor2(im.Col_Button, im.ImVec4(0.13, 0.13, 0.13, 0.9))
    im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.43, 0.49, 1))
    im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.43, 0.49, 1))
    im.PushStyleColor2(im.Col_Text, im.ImVec4(1, 1, 1, 1))
    im.PushStyleColor2(im.Col_FrameBg, im.ImVec4(0.08, 0.08, 0.08, 0.9))
    im.PushStyleColor2(im.Col_FrameBgHovered, im.ImVec4(0.15, 0.15, 0.15, 0.9))
    im.PushStyleColor2(im.Col_FrameBgActive, im.ImVec4(0.20, 0.20, 0.20, 0.9))
    
    im.PushStyleVar2(im.StyleVar_WindowPadding, im.ImVec2(15, 15))
    im.PushStyleVar2(im.StyleVar_ItemSpacing, im.ImVec2(8, 8))
    im.PushStyleVar1(im.StyleVar_WindowBorderSize, 0)

    if im.Begin(action .. " Player", isOpen, windowFlags) then
        im.PushStyleColor2(im.Col_Text, im.ImVec4(0.95, 0.43, 0.49, 1))
        im.Text(action .. " Player")
        im.PopStyleColor()
        
        im.Separator()
        im.Spacing()

        im.Text("Player: " .. (playerName or "Unknown"))
        im.Text("ID: " .. (playerId or "Unknown"))
        im.Spacing()

        im.Text("Reason:")
        im.SetNextItemWidth(300)
        local reasonBuffer = im.ArrayChar(256)
        for i = 1, #actionDialogState.reason do
            reasonBuffer[i-1] = string.byte(actionDialogState.reason, i)
        end
        
        if im.InputText("##reason", reasonBuffer, 256) then
            actionDialogState.reason = ffi.string(reasonBuffer)
        end

        im.Spacing()
        im.Separator()
        im.Spacing()

        local buttonWidth = 120
        local buttonHeight = 30
        
        local windowWidth = im.GetWindowWidth()
        local totalButtonWidth = buttonWidth * 2 + im.GetStyle().ItemSpacing.x
        local startX = (windowWidth - totalButtonWidth) * 0.5
        im.SetCursorPosX(startX)

        im.PushStyleColor2(im.Col_Button, im.ImVec4(0.8, 0.2, 0.2, 0.9))
        im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.9, 0.3, 0.3, 1))
        im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.7, 0.1, 0.1, 1))
        
        if im.Button(action, im.ImVec2(buttonWidth, buttonHeight)) then
            result = "confirm"
            actionDialogState.result = "confirm"
            actionDialogState.isOpen = false
        end
        
        im.PopStyleColor(3)
        im.SameLine()

        -- Cancel button
        if im.Button("Cancel", im.ImVec2(buttonWidth, buttonHeight)) then
            result = "cancel"
            actionDialogState.result = "cancel"
            actionDialogState.isOpen = false
        end

        im.End()
    end

    im.PopStyleVar(3)
    im.PopStyleColor(8)

    if not isOpen[0] then
        actionDialogState.result = "cancel"
        actionDialogState.isOpen = false
    end

    return result
end

local function openActionDialog(action, playerName, playerId)
    actionDialogState.isOpen = true
    actionDialogState.action = action or "Action"
    actionDialogState.playerName = playerName or "Unknown"
    actionDialogState.playerId = playerId or "Unknown"
    actionDialogState.reason = ""
    actionDialogState.result = nil
end

local function isActionDialogOpen()
    return actionDialogState.isOpen
end

local function getActionDialogResult()
    return actionDialogState.result
end

local function getActionDialogReason()
    return actionDialogState.reason
end

local function clearActionDialogResult()
    actionDialogState.result = nil
end

-- ============================================================================
-- VEHICLE HIDING FUNCTIONS
-- ============================================================================

local function toggleOtherVehicleVisibility()
    local playerVehicle = be:getPlayerVehicle(0)
    local playerVehicleId = playerVehicle and playerVehicle:getID() or nil

    local missionGroup = scenetree.findObject("MissionGroup")
    if not missionGroup then
        return false
    end

    local allVehicles = findVehicles(missionGroup)

    if not vehicleVisibilityHidden then
        for _, vehicle in ipairs(allVehicles) do
            local vehicleId = vehicle:getID()
            if vehicle and vehicleId ~= playerVehicleId then
                vehicle:setMeshAlpha(0, '')
                vehicle:queueLuaCommand("obj:setGhostEnabled(true)")
                log('I', 'MPevents', 'Hidden vehicle ID: ' .. tostring(vehicleId))
            end
        end

        vehicleVisibilityHidden = true
        log('I', 'MPevents', 'Hidden all vehicles except player vehicle')

    else
        for _, vehicle in ipairs(allVehicles) do
            local vehicleId = vehicle:getID()
            if vehicle and vehicleId ~= playerVehicleId then
                vehicle:setMeshAlpha(1.0, '')
                vehicle:queueLuaCommand("obj:setGhostEnabled(false)")
                log('I', 'MPevents', 'Restored vehicle ID: ' .. tostring(vehicleId))
            end
        end

        vehicleVisibilityHidden = false
        log('I', 'MPevents', 'Restored all vehicle visibility')
    end

    return vehicleVisibilityHidden
end

local function hideVehicle(vehicleId)
    for _, id in ipairs(targetedHidingState.vehicleIds) do
        if id == vehicleId then
            return false
        end
    end

    table.insert(targetedHidingState.vehicleIds, vehicleId)
    return true
end

local function showVehicle(vehicleId)
    if not vehicleId then
        return false
    end

    for i, id in ipairs(targetedHidingState.vehicleIds) do
        if id == vehicleId then
            table.remove(targetedHidingState.vehicleIds, i)
            return true
        end
    end

    return false
end

local function toggleTargetedVehicleVisibility()
    local missionGroup = scenetree.findObject("MissionGroup")
    if not missionGroup then
        return false
    end

    local allVehicles = findVehicles(missionGroup)

    if not targetedHidingState.hidden then
        for _, vehicle in ipairs(allVehicles) do
            local vehicleId = vehicle:getID()
            if vehicle and isVehicleHidden(vehicleId) then
                vehicle:setMeshAlpha(0, '')
                vehicle:queueLuaCommand("obj:setGhostEnabled(true)")
                log('I', 'MPevents', 'Hidden targeted vehicle ID: ' .. tostring(vehicleId))
            end
        end

        targetedHidingState.hidden = true
        log('I', 'MPevents', 'Hidden ' .. #targetedHidingState.vehicleIds .. ' targeted vehicles')

    else
        for _, vehicle in ipairs(allVehicles) do
            local vehicleId = vehicle:getID()
            if vehicle and isVehicleHidden(vehicleId) then
                vehicle:setMeshAlpha(1.0, '')
                vehicle:queueLuaCommand("obj:setGhostEnabled(false)")
                log('I', 'MPevents', 'Restored targeted vehicle ID: ' .. tostring(vehicleId))
            end
        end

        targetedHidingState.hidden = false
        log('I', 'MPevents', 'Restored targeted vehicle visibility')
    end

    return targetedHidingState.hidden
end

local function MP_hideVehicles(vehicleList)
    if not vehicleList or vehicleList == "" then
        return
    end

    local vehicleIds = {}
    for id in string.gmatch(vehicleList, "([^,]+)") do
        local trimmedId = id:match("^%s*(.-)%s*$")
        if trimmedId and trimmedId ~= "" then
            local numericId = tonumber(trimmedId)
            if numericId then
                table.insert(vehicleIds, numericId)
            end
        end
    end

    for _, vehicleId in ipairs(vehicleIds) do
        local gameVehicleID = MPVehicleGE.getGameVehicleID(vehicleId)
        if gameVehicleID and not MPVehicleGE.isOwn(gameVehicleID) then
            hideVehicle(gameVehicleID)
        end
    end

    log('I', 'MPevents', 'Hidden ' .. #vehicleIds .. ' vehicles from MP list')
end

local function MP_showVehicles(vehicleList)
    if not vehicleList or vehicleList == "" then
        return
    end

    local vehicleIds = {}
    for id in string.gmatch(vehicleList, "([^,]+)") do
        local trimmedId = id:match("^%s*(.-)%s*$")
        if trimmedId and trimmedId ~= "" then
            local numericId = tonumber(trimmedId)
            if numericId then
                table.insert(vehicleIds, numericId)
            end
        end
    end

    for _, vehicleId in ipairs(vehicleIds) do
        local gameVehicleID = MPVehicleGE.getGameVehicleID(vehicleId)
        if gameVehicleID then
            showVehicle(gameVehicleID)
        end
    end

    log('I', 'MPevents', 'Shown ' .. #vehicleIds .. ' vehicles from MP list')
end

local function MP_hideVehicle(vehicleId)
    local gameVehicleID = MPVehicleGE.getGameVehicleID(vehicleId)
    if not MPVehicleGE.isOwn(gameVehicleID) then
        hideVehicle(gameVehicleID)
    end
end

local function MP_showVehicle(vehicleId)
    local gameVehicleID = MPVehicleGE.getGameVehicleID(vehicleId)
    showVehicle(gameVehicleID)
end

local function addModButtons()
    local buttons = UI.getCustomPlayerlistButtons()
    buttons["Kick"] = nil
    buttons["Kick"] = function(name, id)
        openActionDialog("Kick", name, id)
    end
    buttons["Ban"] = nil
    buttons["Ban"] = function(name, id)
        openActionDialog("Ban", name, id)
    end
end

-- ============================================================================
-- Hooks
-- ============================================================================

local function onUpdate(dt)
    if dialogState.isOpen then
        showRaceJoinDialog(dialogState.raceName, dialogState.laps)
    end
    
    if actionDialogState.isOpen then
        showActionDialog(actionDialogState.action, actionDialogState.playerName, actionDialogState.playerId)
    end
    
    if actionDialogState.result == "confirm" then
        local reason = getActionDialogReason()
        if actionDialogState.action == "Kick" then
            local data = {
                action = "kick",
                playerName = actionDialogState.playerName,
                playerId = actionDialogState.playerId,
                reason = reason
            }
            TriggerServerEvent("playerAction", jsonEncode(data))
            print("Kicking player: " .. actionDialogState.playerName .. " (ID: " .. actionDialogState.playerId .. ") - Reason: " .. reason)
        elseif actionDialogState.action == "Ban" then
            local data = {
                action = "ban",
                playerName = actionDialogState.playerName,
                playerId = actionDialogState.playerId,
                reason = reason
            }
            TriggerServerEvent("playerAction", jsonEncode(data))
            print("Banning player: " .. actionDialogState.playerName .. " (ID: " .. actionDialogState.playerId .. ") - Reason: " .. reason)
        end
        clearActionDialogResult()
    elseif actionDialogState.result == "cancel" then
        clearActionDialogResult()
    end
end

M.addModButtons = addModButtons
-- Dialog System
M.openRaceJoinDialog = openRaceJoinDialog
M.isDialogOpen = isDialogOpen
M.getDialogResult = getDialogResult
M.clearDialogResult = clearDialogResult
M.handleRaceInvitation = handleRaceInvitation

-- Action Dialog System
M.openActionDialog = openActionDialog
M.isActionDialogOpen = isActionDialogOpen
M.getActionDialogResult = getActionDialogResult
M.getActionDialogReason = getActionDialogReason
M.clearActionDialogResult = clearActionDialogResult

-- Vehicle Hiding
M.hideOthers = toggleOtherVehicleVisibility
M.hideVehicle = hideVehicle
M.showVehicle = showVehicle
M.toggleTargetedVehicleVisibility = toggleTargetedVehicleVisibility

-- Multiplayer Functions
M.MP_hideVehicles = MP_hideVehicles
M.MP_showVehicles = MP_showVehicles
M.MP_hideVehicle = MP_hideVehicle
M.MP_showVehicle = MP_showVehicle

M.onUpdate = onUpdate

return M