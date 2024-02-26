-- MADE BY MLGWARFARE ON DISCORD
local HttpService = game:GetService("HttpService")
local savemodule = require(game:GetService("ReplicatedStorage").Library.Client.Save)
local SaveFile = savemodule.Get(game.Players.LocalPlayer)
local UnlockedAreas = SaveFile.UnlockedZones

local lplr = game:GetService("Players").LocalPlayer
local Character = lplr.Character or lplr.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local Enabled = true
local Mouse = lplr:GetMouse()
local MapContainer = workspace:WaitForChild("Map")
local AreaModules = game:GetService("ReplicatedStorage"):WaitForChild("__DIRECTORY"):WaitForChild("Zones")
local AreaUnlocker = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Zones_RequestPurchase")
local CurrentArea = 0 -- index to get next area
local AreaToUnlock = ""
local FieldPart = nil -- instance
local AreaList = {}

local Webhook = nil -- Initialize webhook URL variable

-- Function to send a message to Discord webhook
local function SendWebhookMessage(message)
    if Webhook then
        local payload = {
            content = message
        }
        local headers = {
            ["Content-Type"] = "application/json"
        }
        HttpService:PostAsync(Webhook, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson, false, headers)
    else
        warn("Webhook URL not provided.")
    end
end

-- Function to set the webhook URL
local function SetWebhook(url)
    Webhook = url
end

-- Function to get the webhook URL
local function GetWebhook()
    return Webhook
end

-- Grab new hrp
local c,c2
-- Enable/disable
c2 = Mouse.KeyDown:Connect(function(Key)
    if Key == "p" then Enabled = not Enabled end
end)

-- Get list of areas
for _,v in pairs(AreaModules:GetDescendants()) do
    if not v:IsA("ModuleScript") then continue end
    local Info = string.split(v.Name," | ")
    AreaList[tonumber(Info[1])] = Info[2]
end

-- Auto get orbs/lootbags
local OrbRemote = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Orbs: Collect")
local LootbagRemote = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Lootbags_Claim")
local OrbFolder = workspace:WaitForChild("__THINGS"):WaitForChild("Orbs")
local LootbagFolder = workspace:WaitForChild("__THINGS"):WaitForChild("Lootbags")

OrbFolder.ChildAdded:Connect(function(Orb)
    task.wait(1.5)
    Orb:PivotTo(HRP.CFrame)
    OrbRemote:FireServer({Orb.Name})
    task.wait()
    Orb:Destroy()
end)
LootbagFolder.ChildAdded:Connect(function(Lootbag)
    task.wait(4)
    Lootbag:PivotTo(HRP.CFrame)
    LootbagRemote:FireServer({Lootbag.Name})
    task.wait()
    Lootbag:Destroy()
end)

c = lplr.CharacterAdded:Connect(function(Char)
    Character = Char
    HRP = Character:WaitForChild("HumanoidRootPart")
end)

local function Unlock()
    return AreaUnlocker:InvokeServer(AreaToUnlock)
end

-- Find current area
for Area,_ in next, UnlockedAreas do
    local AreaNum = table.find(AreaList,Area)
    if AreaNum > CurrentArea then
        CurrentArea = AreaNum
        AreaToUnlock = AreaList[AreaNum+1]
        FieldPart = MapContainer:WaitForChild(AreaNum.." | "..Area):WaitForChild("INTERACT"):WaitForChild("BREAK_ZONES"):WaitForChild("BREAK_ZONE")
        HRP.CFrame = FieldPart.CFrame
        task.wait(.2) -- Wait for the game to load in everything
    end
end

while true do
    if Enabled then
        -- Attempt to buy new area
        if Unlock() then -- Unlock succeeded
            task.wait(3)
            CurrentArea += 1
            AreaToUnlock = AreaList[CurrentArea+1]
            FieldPart = MapContainer:WaitForChild(CurrentArea.." | "..AreaList[CurrentArea]):WaitForChild("INTERACT"):WaitForChild("BREAK_ZONES"):WaitForChild("BREAK_ZONE")
            HRP.CFrame = FieldPart.CFrame
            SendWebhookMessage("New area unlocked: "..AreaToUnlock) -- Notify Discord
        else
            HRP.CFrame = FieldPart.CFrame
        end
    else
        break
    end
    task.wait(15)
end

c:Disconnect()
c2:Disconnect()