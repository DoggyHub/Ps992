if game.PlaceId ~= 8737899170 then return end

local ReplicatedStorage = game.ReplicatedStorage
local LocalPlayer = game.Players.LocalPlayer
local ZoneCmds = require(ReplicatedStorage.Library.Client.ZoneCmds)
local CurrencyCmds = require(ReplicatedStorage.Library.Client.CurrencyCmds)
local ZonesUtil = require(ReplicatedStorage.Library.Util.ZonesUtil)
local WorldsUtil = require(ReplicatedStorage.Library.Util.WorldsUtil)
local CalcGatePrice = require(ReplicatedStorage.Library.Balancing.CalcGatePrice)

local function getRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function teleportToZone(targetZoneNumber)
    local zoneName, zoneData = ZonesUtil.GetZoneFromNumber(targetZoneNumber)
    if not zoneName or not zoneData then return end
    
    local zone = workspace.Map[zoneData.ZoneNumber .. " | " .. zoneName]
    if not zone then return end
    
    local target = zone.INTERACT and zone.INTERACT.BREAK_ZONES.BREAK_ZONE or zone.BREAK_ZONES and zone.BREAK_ZONES.BREAK_ZONE or zone.BREAK_ZONE
    
    local root = getRoot()
    if target and root then
        root.CFrame = target.CFrame * CFrame.new(0, 5, 0)
    end
end

local function initialTeleport()
    local _, data = ZoneCmds.GetMaxOwnedZone()
    if not data then return end
    
    local zone = workspace.Map[data.ZoneNumber .. " | " .. data.ZoneName]
    local part = zone:FindFirstChild("PERSISTENT") and zone.PERSISTENT:FindFirstChild("Teleport")
    local root = getRoot()
    
    if part and root then
        repeat
            root.CFrame = part.CFrame * CFrame.new(0, 5, 0)
            task.wait()
        until (root.CFrame.Position - (part.CFrame * CFrame.new(0, 5, 0)).Position).Magnitude < 5
        task.wait(0.325)
    end
    
    teleportToZone(data.ZoneNumber)
end

initialTeleport()

spawn(function()
    while true do
        local _, current = ZoneCmds.GetMaxOwnedZone()
        if current then
            local _, next = ZonesUtil.GetZoneFromNumber(current.ZoneNumber + 1)
            if next and CurrencyCmds.CanAfford(WorldsUtil.GetWorldCurrencyId(), CalcGatePrice(next)) then
                ReplicatedStorage.Network.Zones_RequestPurchase:InvokeServer(next)
                teleportToZone(current.ZoneNumber + 1)
            end
        end
        task.wait()
    end
end)

spawn(function()
    while true do
        task.wait(1.5)
        local _, current = ZoneCmds.GetMaxOwnedZone()
        if current then
            teleportToZone(current.ZoneNumber)
        end
    end
end)
