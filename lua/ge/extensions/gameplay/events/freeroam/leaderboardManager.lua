local M = {}

local leaderboardFile = "career/rls_career/races_leaderboard.json"
local leaderboard = {}

local level
local currentConfig

local function loadLeaderboard()
    if MPCoreNetwork.isMPSession() then
        TriggerServerEvent("sendLeaderboard", "please")
        return
    end
    if not career_career or not career_career.isActive() then
        return
    end
    local saveSlot, savePath = career_saveSystem.getCurrentSaveSlot()
    local file = savePath .. '/' .. leaderboardFile
    leaderboard = jsonReadFile(file)
end

local function saveLeaderboard(currentSavePath)
    if not leaderboard then
        leaderboard = {}
    end
    if not MPCoreNetwork.isMPSession() or nil then -- if MP false do old stuff
        career_saveSystem.jsonWriteFileSafe(currentSavePath .. "/" .. leaderboardFile, leaderboard, true)
    elseif MPCoreNetwork.isMPSession() then -- we're in MP
        TriggerServerEvent("getLeaderboard", jsonEncode(leaderboard))
    end
end

local function retrieveServerLeaderboard(leaderboardData) -- called by sever on join
    print("Received leaderboard data from server: " .. leaderboardData)
    leaderboard = jsonDecode(leaderboardData)
    print("Leaderboard Data: " .. tostring(leaderboard))
end

local function updateConfig(data) -- because it breaks in MP when using onVehicleSwitched...?
    getPlayerVehicle(0):queueLuaCommand([[
    local config = v.config.partConfigFilename
    obj:queueGameEngineLua("gameplay_events_freeroam_leaderboardManager.returnConfig('" .. config .."')")
    ]])
end

local function isBestTime(entry)
    level = getCurrentLevelIdentifier()
    if not leaderboard then
        leaderboard = {}
    end
    local leaderboardEntry = leaderboard[level] or {}
    if not leaderboardEntry then
        return true
    end

    if not MPCoreNetwork.isMPSession() then
        leaderboardEntry = leaderboardEntry[tostring(entry.inventoryId)] or {}
    else
        leaderboardEntry = leaderboardEntry[currentConfig] or {}
    end
    if not leaderboardEntry then
        return true
    end

    leaderboardEntry = leaderboardEntry[entry.raceLabel] or {}
    if not leaderboardEntry then
        return true
    end

    if entry.driftScore and entry.driftScore > 0 then
        if not leaderboardEntry.driftScore then
            return true
        end
        return entry.driftScore > leaderboardEntry.driftScore
    end

    if not leaderboardEntry.time then
        return true
    end
    return entry.time < leaderboardEntry.time
end

local function addLeaderboardEntry(entry)
    level = getCurrentLevelIdentifier()

    if career_career and career_career.isActive() then
        career_modules_inventory.saveFRETimeToVehicle(entry.raceLabel, entry.inventoryId, entry.time, entry.driftScore)
    end
    if not leaderboard then
        leaderboard = {}
    end
    if not leaderboard[level] then
        leaderboard[level] = {}
    end

    local leaderboardEntry
    if not MPCoreNetwork.isMPSession() then
        if not leaderboard[level][tostring(entry.inventoryId)] then
            leaderboard[level][tostring(entry.inventoryId)] = {}
        end
        leaderboardEntry = leaderboard[level][tostring(entry.inventoryId)]
    else
        if not leaderboard[level][currentConfig] then
            leaderboard[level][currentConfig] = {}
        end
        leaderboardEntry = leaderboard[level][currentConfig]
    end
    if isBestTime(entry) then
        local raceLabel = entry.raceLabel
        leaderboardEntry[raceLabel] = leaderboardEntry[raceLabel] or {}
        leaderboardEntry[raceLabel].time = entry.time
        leaderboardEntry[raceLabel].splitTimes = entry.splitTimes
        leaderboardEntry[raceLabel].driftScore = entry.driftScore
        if MPCoreNetwork.isMPSession() then
            saveLeaderboard()
        end
        return true
    end
    return false
end

local function clearLeaderboardForVehicle(inventoryId)
    if MPCoreNetwork.isMPSession() then
        return
    end
    level = getCurrentLevelIdentifier()
    if not leaderboard then
        leaderboard = {}
    end
    if not leaderboard[level] or not leaderboard[level][tostring(inventoryId)] then
        return
    end
    leaderboard[level][tostring(inventoryId)] = nil
end

local function onExtensionLoaded()
    print("Initializing Leaderboard Manager")
    level = getCurrentLevelIdentifier()
    if level then
        loadLeaderboard()
    end
end

local function onWorldReadyState(state)
    if state == 2 then
        level = getCurrentLevelIdentifier()
        loadLeaderboard()
    end
    if AddEventHandler then
        AddEventHandler("retrieveServerLeaderboard", retrieveServerLeaderboard)
    end
    if AddEventHandler then
        AddEventHandler("updateConfig", updateConfig)
    end
end

local function onSaveCurrentSaveSlot(currentSavePath)
    saveLeaderboard(currentSavePath)
end

local function getLeaderboardEntry(inventoryId, raceLabel)
    level = getCurrentLevelIdentifier()
    if not leaderboard then
        leaderboard = {}
    end
    if MPCoreNetwork.isMPSession() then
        updateConfig()
        if not leaderboard[level] or not leaderboard[level][currentConfig] then
            return {}
        else
            return leaderboard[level][currentConfig][raceLabel] or {}
        end
    end
    if not leaderboard[level] or not leaderboard[level][tostring(inventoryId)] then
        return {}
    end
    return leaderboard[level][tostring(inventoryId)][raceLabel]
end

local function onCareerActive(active)
    if active then
        loadLeaderboard()
    else
        leaderboard = {}
    end
end

local function returnConfig(config)
    print("The current config is: " .. config)
    currentConfig = config
end

function M.getLeaderboard()
    return leaderboard
end

M.retrieveServerLeaderboard = retrieveServerLeaderboard
M.updateConfig = updateConfig
M.returnConfig = returnConfig
M.loadLeaderboard = loadLeaderboard

M.onVehicleRemoved = clearLeaderboardForVehicle
M.onCareerActive = onCareerActive

M.onExtensionLoaded = onExtensionLoaded
M.onWorldReadyState = onWorldReadyState

M.onSaveCurrentSaveSlot = onSaveCurrentSaveSlot
M.addLeaderboardEntry = addLeaderboardEntry

M.isBestTime = isBestTime
M.getLeaderboardEntry = getLeaderboardEntry

return M
