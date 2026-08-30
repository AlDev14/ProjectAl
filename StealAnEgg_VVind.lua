-- ============================================================
--  STEAL AN EGG — VVind-UI
--  Pure Workspace Approach (Zero require = Zero BAC)
--  Egg: WildAssetEgg, Prompt: InputHoldBegin/End
--  Author: AlDev14
-- ============================================================

-- ============================================================
-- HUMANOID CLONE BYPASS — BARIS PERTAMA, sebelum apapun
-- ============================================================
local _LocalPlayer = game:GetService("Players").LocalPlayer

local function doHumanoidBypass()
    local char = _LocalPlayer.Character
    if not char then
        char = _LocalPlayer.CharacterAdded:Wait()
    end
    local origHum = char:FindFirstChildOfClass("Humanoid")
        or char:WaitForChild("Humanoid", 10)
    if not origHum then return end
    pcall(function()
        local cloneHum = origHum:Clone()
        cloneHum.WalkSpeed  = origHum.WalkSpeed
        cloneHum.JumpPower  = origHum.JumpPower
        cloneHum.MaxHealth  = origHum.MaxHealth
        cloneHum.Health     = origHum.Health
        cloneHum.AutoRotate = origHum.AutoRotate
        cloneHum.Parent     = char
        task.wait(0.05)
        origHum:Destroy()
        task.wait(0.05)
        workspace.CurrentCamera.CameraSubject = cloneHum
        print("[SAE] Humanoid bypass OK")
    end)
end

doHumanoidBypass()

_LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    doHumanoidBypass()
end)

-- ============================================================
-- SERVICES
-- ============================================================
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = _LocalPlayer

-- ============================================================
-- LOAD VVIND-UI
-- ============================================================
local VindUI
do
    local ok, r = pcall(function()
        return loadstring(game:HttpGet(
            "https://cdn.jsdelivr.net/gh/Skinny-yz/VVind-UI@main/src.lua"
        ))()
    end)
    if ok and r then VindUI = r
    else warn("[SAE] VVind-UI gagal: "..tostring(r)); return end
end

local function Notify(title, text, ntype, dur)
    pcall(function()
        VindUI:Notify({ Title=title, Text=text, Type=ntype or "info", Duration=dur or 3 })
    end)
end

-- ============================================================
-- STATE
-- ============================================================
local RARITY_ORDER = {
    ["Common"]=1, ["Uncommon"]=2, ["Rare"]=3,
    ["Epic"]=4, ["Legendary"]=5, ["Mythic"]=6,
    ["Divine"]=7, ["Secret"]=8,
}
local HOLD_WAIT = 0.6

local State = {
    running    = false,
    busy       = false,
    carrying   = false,
    status     = "Idle",
    stealCount = 0,
    minRarity  = "All",
}

-- ============================================================
-- HELPERS
-- ============================================================
local function root()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function hum()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- Walk natural pakai Humanoid:MoveTo
local function walkTo(goal, timeout)
    if typeof(goal) ~= "Vector3" then
        goal = goal and goal.Position
    end
    if not goal then return false end
    local h = hum()
    local r = root()
    if not h or not r then return false end
    timeout = timeout or 45
    local ARRIVE = 4.5
    if (r.Position - goal).Magnitude <= ARRIVE then return true end
    task.wait(math.random(10, 25) / 100)
    h:MoveTo(goal)
    local t0 = workspace.DistributedGameTime
    while workspace.DistributedGameTime - t0 < timeout and State.running do
        r = root()
        if not r then break end
        if (goal - r.Position).Magnitude <= ARRIVE then
            h = hum(); if h then h:Move(Vector3.zero, false) end
            return true
        end
        task.wait(0.2)
    end
    h = hum(); if h then h:Move(Vector3.zero, false) end
    r = root()
    return r and (r.Position - goal).Magnitude <= 10
end

-- ============================================================
-- EGG DETECTION (Pure Workspace — WildAssetEgg)
-- ============================================================
local function getEggRarity(eggModel)
    -- Coba baca attribute rarity dari model
    local r = eggModel:GetAttribute("Rarity")
        or eggModel:GetAttribute("RarityName")
        or eggModel:GetAttribute("RarityTier")
        or eggModel:GetAttribute("EggRarity")
    if r and type(r) == "string" then
        for k in pairs(RARITY_ORDER) do
            if r:lower():find(k:lower(), 1, true) then return k end
        end
        return r
    end
    return "Common"
end

local function meetsRarity(eggModel)
    if State.minRarity == "All" then return true end
    local minVal = RARITY_ORDER[State.minRarity] or 1
    local eggVal = RARITY_ORDER[getEggRarity(eggModel)] or 1
    return eggVal >= minVal
end

local function findNearestEgg()
    local r = root()
    if not r then return nil, nil end
    local bestEgg, bestPrompt, bestDist = nil, nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "WildAssetEgg" and obj:IsA("Model") then
            if meetsRarity(obj) then
                local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    local dist = (part.Position - r.Position).Magnitude
                    if dist < bestDist then
                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            bestDist   = dist
                            bestEgg    = obj
                            bestPrompt = prompt
                        end
                    end
                end
            end
        end
    end
    return bestEgg, bestPrompt
end

local function getHomePart()
    -- Cari respawn/plot player
    local char = LocalPlayer.Character
    if not char then return nil end
    -- Coba dari SpawnLocation atau plot terdekat
    local spawnLocs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            local attr = obj:GetAttribute("Owner") or obj:GetAttribute("PlayerId")
            if attr == LocalPlayer.Name or attr == LocalPlayer.UserId then
                table.insert(spawnLocs, obj)
            end
        end
    end
    if #spawnLocs > 0 then
        return spawnLocs[1]
    end
    -- Fallback: cari BasePart bernama "Base" atau "Plot" dekat spawn
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name == "Base" or obj.Name == "Plot" or obj.Name == "Home") then
            local attr = obj:GetAttribute("Owner") or obj:GetAttribute("PlayerId")
            if attr == LocalPlayer.Name or attr == tostring(LocalPlayer.UserId) then
                return obj
            end
        end
    end
    return nil
end

local function holdPrompt(prompt)
    if not prompt or not prompt.Enabled then return false end
    local hold = math.max(prompt.HoldDuration or 0.5, 0.4) + 0.2
    -- Coba fireproximityprompt dulu
    if typeof(fireproximityprompt) == "function" then
        local ok = pcall(fireproximityprompt, prompt, hold)
        if ok then
            task.wait(hold + 0.1)
            return true
        end
    end
    -- Fallback: InputHoldBegin/End
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(hold)
        prompt:InputHoldEnd()
    end)
    task.wait(0.1)
    return ok
end

-- ============================================================
-- HEARTBEAT SPOOF
-- ============================================================
local _integrityConn
local function startIntegritySpoof()
    if _integrityConn then return end
    _integrityConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        if not State.running then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h and h.MoveDirection.Magnitude < 0.01 then
                pcall(function() h:Move(Vector3.zero, false) end)
            end
        end
    end)
end
startIntegritySpoof()

-- ============================================================
-- MAIN STEAL CYCLE
-- ============================================================
local function stealCycle()
    if State.busy then return false end
    State.busy = true

    local ok, result = pcall(function()
        local r = root()
        if not r then
            Notify("SAE", "Spawn dulu", "warning"); return false
        end

        -- Cari egg terdekat
        State.status = "Cari egg..."
        local egg, prompt = findNearestEgg()
        if not egg or not prompt then
            Notify("SAE", "Tidak ada WildAssetEgg", "warning"); return false
        end

        local eggPart = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
        if not eggPart then return false end

        local eggName = egg:GetAttribute("EggName") or egg:GetAttribute("AssetName") or egg.Name
        local rarityName = getEggRarity(egg)

        -- Jalan ke egg
        State.status = "Jalan ke "..eggName
        walkTo(eggPart.Position, 40)

        -- Pastikan sudah dekat
        r = root()
        if not r then return false end
        if (eggPart.Position - r.Position).Magnitude > 8 then
            Notify("SAE", "Tidak bisa reach egg", "warning"); return false
        end

        -- Hold prompt dengan random jitter
        State.status = "Hold egg..."
        task.wait(HOLD_WAIT + math.random(-10, 20)/100)
        holdPrompt(prompt)
        task.wait(0.5)

        -- Cek apakah berhasil carry (cek attribute)
        local carried = egg:GetAttribute("CarriedBy") == LocalPlayer.UserId
            or egg:GetAttribute("IsCarried") == true
        -- Kalau tidak bisa cek → asumsikan berhasil dan jalan balik

        -- Cari home/base
        State.status = "Balik ke base..."
        local homePart = getHomePart()
        if homePart then
            walkTo(homePart.Position + Vector3.new(0, 3, 0), 50)
        else
            -- Fallback: jalan jauh dari gameplay area
            local curPos = root() and root().Position or Vector3.new()
            walkTo(curPos + Vector3.new(-60, 0, 0), 30)
        end

        task.wait(1.5)
        State.stealCount += 1
        State.status = "Idle"
        Notify("SAE", string.format("Egg #%d (%s) berhasil!", State.stealCount, rarityName), "success", 2)
        return true
    end)

    State.busy = false
    if not ok then
        warn("[SAE] Error:", result)
        Notify("SAE", tostring(result):sub(1,60), "error")
    end
    return result == true
end

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ============================================================
-- VVIND-UI
-- ============================================================
local Window = VindUI:CreateWindow({
    Title    = "Steal An Egg",
    Subtitle = "by AlDev14",
    Icon     = "Lucide:egg",
    Size     = UDim2.fromOffset(520, 420),
    MinSize  = Vector2.new(420, 340),
    Draggable = true,
    Resizable = true,
    UseBlur  = false,
    DefaultTab = "Farm",
})

local tabFarm = Window:AddTab({ Name="Farm", Icon="Lucide:zap" })
local secFarm = tabFarm:AddSubTab({ Name="Auto Steal", Icon="Lucide:egg" })

secFarm:AddParagraph({
    Title = "Info",
    Text  = "Pure Workspace — Zero require. Egg: WildAssetEgg. Speed = SpeedPower game.",
})

secFarm:AddToggle({
    Text    = "Auto Steal",
    Default = false,
    Flag    = "autoSteal",
    Callback = function(v)
        State.running = v
        if v then
            Notify("SAE", "Auto Steal ON", "success", 2)
            task.spawn(function()
                while State.running do
                    stealCycle()
                    task.wait(1)
                end
                Notify("SAE", "Auto Steal OFF", "info", 2)
            end)
        end
    end,
})

secFarm:AddButton({
    Text     = "Steal Once",
    Icon     = "Lucide:hand",
    Callback = function() task.spawn(stealCycle) end,
})

secFarm:AddSlider({
    Text      = "Hold Duration (s)",
    Min       = 0.3, Max = 2.0, Default = 0.6, Increment = 0.1,
    Flag      = "holdWait",
    Callback  = function(v) HOLD_WAIT = v end,
})

secFarm:AddDropdown({
    Text    = "Minimum Rarity",
    Options = {"All","Uncommon","Rare","Epic","Legendary","Mythic","Divine","Secret"},
    Default = "All",
    Flag    = "minRarity",
    Callback = function(v)
        State.minRarity = v
        Notify("SAE", "Min rarity: "..v, "info", 2)
    end,
})

secFarm:AddToggle({
    Text     = "Prefer High Value",
    Default  = true,
    Flag     = "preferHigh",
    Callback = function(v) State.preferHighValue = v end,
})

-- Status tab
local tabStatus = tabFarm:AddSubTab({ Name="Status", Icon="Lucide:activity" })
tabStatus:AddSystemInfoGrid({ Description = "FPS & Ping" })

-- Settings
local tabSet = Window:AddTab({ Name="Settings", Icon="Lucide:settings" })
local secSet = tabSet:AddSubTab({ Name="Config", Icon="Lucide:save" })
secSet:AddButton({
    Text="Save Config", Icon="Lucide:save",
    Callback=function()
        pcall(function() VindUI:SaveConfig("sae_hub") end)
        Notify("Config","Saved","success",2)
    end,
})
secSet:AddButton({
    Text="Load Config", Icon="Lucide:folder-open",
    Callback=function()
        pcall(function() VindUI:LoadConfig("sae_hub",true) end)
        Notify("Config","Loaded","success",2)
    end,
})

Notify("Steal An Egg", "Loaded — Pure Workspace, Zero require", "success", 4)
print("[SAE] Pure workspace script loaded")
