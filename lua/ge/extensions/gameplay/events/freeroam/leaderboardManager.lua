local M = {}

local leaderboardFile = "career/rls_career/races_leaderboard.json"
local leaderboardFileMP = "rlsmp/leaderboards/races_leaderboard.json" --KN8R: Make this file exist.
local leaderboard = {}
local leaderboardMP = {}

local level

local function loadLeaderboard()
    if not MPCoreNetwork.isMPSession() or nil then -- if MP false do old stuff
        print("Doing old stuff, not MP")
        if not career_career or not career_career.isActive() then
            return
        end
        local saveSlot, savePath = career_saveSystem.getCurrentSaveSlot()
        local file = savePath .. '/' .. leaderboardFile
        leaderboard = jsonReadFile(file)
    elseif MPCoreNetwork.isMPSession() then -- we're in MP baby!
        --MP.TriggerServerEvent("sendUserLeaderboard") -- get the leaderboard from the server, this should be done onPlayerJoin
        leaderboard = jsonReadFile(leaderboardFileMP)
    end
end

local function saveLeaderboard(currentSavePath)
    if not MPCoreNetwork.isMPSession() or nil then -- if MP false do old stuff
        if not leaderboard then
            leaderboard = {}
        end
        career_saveSystem.jsonWriteFileSafe(currentSavePath .. "/" .. leaderboardFile, leaderboard, true)
    elseif MPCoreNetwork.isMPSession() then -- we're in MP
        print("We're in MP write to a different file")
        if not leaderboard then
            leaderboard = {}
        end
        career_saveSystem.jsonWriteFileSafe(leaderboardFileMP, leaderboardMP, true)
        MP.TriggerServerEvent("getUserLeaderboard", true)
    end
end

local function getLeaderboardMP(leaderboarddata)
    if leaderboarddata then 
        print("Leaderboard data was received: " .. leaderboarddata)
    else
        print("Leaderboard data was not received!")
    end
    return
end

local function sendLeaderboardMP(leaderboardData)
    print("The server has asked for leaderboard data")
    MP.TriggerServerEvent(getUserLeaderboard, leaderboardData)
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

    leaderboardEntry = leaderboardEntry[tostring(entry.inventoryId)] or {}
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
    if not leaderboard[level][tostring(entry.inventoryId)] then
        leaderboard[level][tostring(entry.inventoryId)] = {}
    end
    local leaderboardEntry = leaderboard[level][tostring(entry.inventoryId)]
    if isBestTime(entry) then
        local raceLabel = entry.raceLabel
        leaderboardEntry[raceLabel] = leaderboardEntry[raceLabel] or {}
        leaderboardEntry[raceLabel].time = entry.time
        leaderboardEntry[raceLabel].splitTimes = entry.splitTimes
        leaderboardEntry[raceLabel].driftScore = entry.driftScore
        return true
    end
    return false
end

local function clearLeaderboardForVehicle(inventoryId)
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
end

local function onSaveCurrentSaveSlot(currentSavePath)
    saveLeaderboard(currentSavePath)
end

local function getLeaderboardEntry(inventoryId, raceLabel)
    level = getCurrentLevelIdentifier()
    if not leaderboard then
        leaderboard = {}
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

M.onVehicleRemoved = clearLeaderboardForVehicle
M.onCareerActive = onCareerActive

M.onExtensionLoaded = onExtensionLoaded
M.onWorldReadyState = onWorldReadyState

M.onSaveCurrentSaveSlot = onSaveCurrentSaveSlot
M.addLeaderboardEntry = addLeaderboardEntry

M.isBestTime = isBestTime
M.getLeaderboardEntry = getLeaderboardEntry

return M
