-- ============================================================
--  STEAL AN EGG — VVind-UI
--  Auto Farm: smooth lerp movement (anti-BAC)
--  Remote: EggCmds (Shared.Remotes new system)
--  Author: AlDev14
-- ============================================================

-- AC Bypass removed — memanggil filtergc/debug bisa justru trigger AC
-- Biarkan game scan berjalan normal

-- ============================================================
-- HUMANOID CLONE BYPASS
-- Harus dijalankan PERTAMA sebelum game modules load
-- Reference AC ke Humanoid asli jadi invalid
-- ============================================================
local _LocalPlayer = game:GetService("Players").LocalPlayer

local function doHumanoidBypass()
    local char = _LocalPlayer.Character
    if not char then
        char = _LocalPlayer.CharacterAdded:Wait()
    end
    local origHum = char:FindFirstChildOfClass("Humanoid")
        or char:WaitForChild("Humanoid", 10)
    if not origHum then
        print("[SAE] Bypass: Humanoid not found")
        return
    end
    pcall(function()
        local cloneHum = origHum:Clone()
        -- Copy semua properties penting
        cloneHum.WalkSpeed    = origHum.WalkSpeed
        cloneHum.JumpPower    = origHum.JumpPower
        cloneHum.MaxHealth    = origHum.MaxHealth
        cloneHum.Health       = origHum.Health
        cloneHum.AutoRotate   = origHum.AutoRotate
        cloneHum.DisplayName  = origHum.DisplayName
        -- Pasang clone dulu
        cloneHum.Parent = char
        task.wait(0.05)
        -- Hapus yang asli
        origHum:Destroy()
        print("[SAE] Humanoid bypass OK")
    end)
end

-- Jalankan bypass langsung
doHumanoidBypass()

-- Re-apply setiap respawn
_LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.3)
    doHumanoidBypass()
end)

-- Load VVind-UI
local VindUI
do
    local ok, r = pcall(function()
        return loadstring(game:HttpGet(
            "https://cdn.jsdelivr.net/gh/Skinny-yz/VVind-UI@main/src.lua"
        ))()
    end)
    if ok and r then VindUI = r
    else warn("[SAE] VVind-UI gagal load: "..tostring(r)); return end
end

-- Services
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local VirtualUser       = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local HOLD_WAIT    = 0.6  -- simulate hold duration

-- Notify helper
local function Notify(title, text, ntype, dur)
    pcall(function()
        VindUI:Notify({ Title=title, Text=text, Type=ntype or "info", Duration=dur or 3 })
    end)
end

-- State
local State = {
    running   = false,
    busy      = false,
    carrying  = false,
    status    = "Idle",
    lastSteal = 0,
    stealCount = 0,
}

-- ============================================================
-- GAME MODULES (new Shared.Remotes system)
-- ============================================================
local EggCmds, PlotCmds, Guard, Lookup, Network

local function loadModules()
    local function soft(inst)
        if not inst then return nil end
        local ok, r = pcall(require, inst)
        return ok and r or nil
    end

    -- Coba Network dulu (selalu ada)
    local pkgs = ReplicatedStorage:FindFirstChild("Packages")
    Network = soft(pkgs and pkgs:FindFirstChild("Networking"))

    -- Coba multiple path untuk Library
    local Lib = ReplicatedStorage:FindFirstChild("Library")
        or ReplicatedStorage:FindFirstChild("Lib")
        or ReplicatedStorage:FindFirstChild("Shared")

    if not Lib then
        -- Tunggu sebentar
        task.wait(2)
        Lib = ReplicatedStorage:FindFirstChild("Library")
            or ReplicatedStorage:FindFirstChild("Lib")
    end

    if Lib then
        local Client = Lib:FindFirstChild("Client")
        local Util   = Lib:FindFirstChild("Util")
        if Client then
            EggCmds  = soft(Client:FindFirstChild("EggCmds"))
            PlotCmds = soft(Client:FindFirstChild("PlotCmds"))
            -- Guard tidak di-require — bisa trigger internal check
    -- Guard    = soft(Client:FindFirstChild("ToolGameplayGuard"))
        end
        if Util then
            Lookup = soft(Util:FindFirstChild("GuardAreaLookupUtil"))
                or soft(Util:FindFirstChild("AreaLookup"))
        end
    end

    -- Fallback: cari di PlayerScripts
    if not EggCmds then
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        if ps then
            local Game = ps:FindFirstChild("Game")
            local Eggs = Game and (Game:FindFirstChild("Eggs") or Game:FindFirstChild("EggCmds"))
            if Eggs then
                EggCmds = soft(Eggs:FindFirstChild("EggCmds"))
                    or soft(Eggs)
            end
            local Plots = Game and Game:FindFirstChild("Plots")
            if Plots then
                PlotCmds = soft(Plots:FindFirstChild("PlotCmds"))
            end
            -- Guard tidak di-require (bisa trigger internal AC)
        end
    end

    -- Fallback: pakai EggWorld dari Shared.Remotes langsung
    if not EggCmds and Network then
        -- Build minimal EggCmds dari Shared.Remotes namespace
        local ok, EggWorld = pcall(function()
            return Network.namespace({name="EggWorld"})
        end)
        if ok and EggWorld then
            EggCmds = {
                RequestCarryAreaEgg = function(uid)
                    if EggWorld.AskFieldEggCarry then
                        return EggWorld.AskFieldEggCarry:InvokeServer(uid)
                    end
                end,
                RequestPlaceEgg = function(uid, cf)
                    if EggWorld.AskPlaceEgg then
                        return EggWorld.AskPlaceEgg:InvokeServer(uid, cf)
                    end
                end,
                GetAreaEggSnapshot = function() return nil end,
                RequestAreaEggSnapshot = function() return nil end,
                GetAreaEggRecord = function() return nil end,
            }
            print("[SAE] EggCmds built from Shared.Remotes EggWorld")
        end
    end

    print("[SAE] Modules:", 
        "EggCmds="..tostring(EggCmds~=nil),
        "PlotCmds="..tostring(PlotCmds~=nil),
        "Guard="..tostring(Guard~=nil),
        "Network="..tostring(Network~=nil))

    return EggCmds ~= nil
end

local modulesOK = loadModules()
if not modulesOK then
    Notify("SAE", "Modules partial - coba steal tetap jalan", "warning", 5)
    warn("[SAE] Some modules unavailable - partial mode")
end

-- ============================================================
-- MOVEMENT — Humanoid:MoveTo (natural walk, anti-BAC)
-- Speed dikontrol game (SpeedPower system)
-- ============================================================
local function root()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function hum()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- walkTo: pakai Humanoid:Move fisik, tidak set CFrame
-- timeout = detik maksimal jalan
local function walkTo(goal, timeout)
    if typeof(goal) ~= "Vector3" then
        goal = goal and goal.Position
    end
    if not goal then return false end

    local h = hum()
    local r = root()
    if not h or not r then return false end

    timeout = timeout or 45
    local ARRIVE_DIST = 4.5

    -- Kalau sudah dekat, tidak perlu jalan
    if (r.Position - goal).Magnitude <= ARRIVE_DIST then return true end

    -- Random delay kecil sebelum mulai jalan (natural behavior)
    task.wait(math.random(10, 25) / 100)

    -- Pakai MoveTo saja tanpa manual Move loop (lebih natural)
    h:MoveTo(goal)

    local t0 = workspace.DistributedGameTime
    while workspace.DistributedGameTime - t0 < timeout and State.running do
        r = root()
        if not r then break end

        local dist = (goal - r.Position).Magnitude
        if dist <= ARRIVE_DIST then
            h = hum()
            if h then h:Move(Vector3.zero, false) end
            return true
        end

        task.wait(0.2)  -- poll lebih jarang, lebih natural
    end

    h = hum()
    if h then h:Move(Vector3.zero, false) end
    r = root()
    return r and (r.Position - goal).Magnitude <= 10
end

-- ============================================================
-- GAME HELPERS
-- ============================================================
local SeparationLine = nil

local function getSeparationLine()
    if SeparationLine and SeparationLine.Parent then return SeparationLine end
    local objs = Workspace:FindFirstChild("__OBJECTS")
    if objs then
        local areas = objs:FindFirstChild("Areas")
        SeparationLine = areas and areas:FindFirstChild("SeparationLine")
    end
    return SeparationLine
end

local function onGameplaySide(pos)
    local line = getSeparationLine()
    if not line or not pos then return false end
    if Lookup and type(Lookup.IsInGameplaySide) == "function" then
        return Lookup.IsInGameplaySide(line, pos) == true
    end
    local rel = line.CFrame:PointToObjectSpace(pos)
    return rel.Z > 0
end

local function inGameplay()
    -- Tidak pakai Guard module — cek posisi manual
    local line = getSeparationLine()
    local r = root()
    if not line or not r then return false end
    return onGameplaySide(r.Position)
end

local function crossToArena()
    if inGameplay() then return true end
    local line = getSeparationLine()
    if not line then return false end
    local safePos = line.Position - Vector3.new(55, 0, 0)
    local playPos = line.Position + Vector3.new(55, 4, 0)
    State.status = "Masuk arena"
    walkTo(safePos, 20)
    walkTo(playPos, 25)
    task.wait(0.2)
    return inGameplay()
end

-- Rarity helpers
local function getEggRarity(rec)
    if not rec then return "Common" end
    local r = rec.Rarity or rec.RarityName or rec.RarityTier
    if r and type(r) == "string" then
        for k in pairs(RARITY_ORDER) do
            if r:lower():find(k:lower(), 1, true) then return k end
        end
    end
    return "Common"
end

local function meetsRarity(rec)
    if State.minRarity == "All" then return true end
    local eggRar = getEggRarity(rec)
    local minVal = RARITY_ORDER[State.minRarity] or 1
    local eggVal = RARITY_ORDER[eggRar] or 1
    return eggVal >= minVal
end

local function listEggs()
    if not EggCmds then return {} end
    local snap
    pcall(function()
        if type(EggCmds.GetAreaEggSnapshot) == "function" then
            snap = EggCmds.GetAreaEggSnapshot()
        end
        if not snap and type(EggCmds.RequestAreaEggSnapshot) == "function" then
            snap = EggCmds.RequestAreaEggSnapshot()
        end
    end)
    local hrp = root()
    local list = {}
    for _, rec in pairs((snap and snap.Records) or {}) do
        if type(rec) == "table" and rec.State == "Slot" and type(rec.Uid) == "string" then
            local pos = rec.BottomCFrame and rec.BottomCFrame.Position
            if pos and onGameplaySide(pos) then
                if meetsRarity(rec) then
                    local dist = hrp and (pos - hrp.Position).Magnitude or math.huge
                    table.insert(list, { rec=rec, dist=dist })
                end
            end
        end
    end
    table.sort(list, function(a,b) return a.dist < b.dist end)
    return list
end

local function eggIsCarried(uid)
    if EggCmds and type(EggCmds.GetAreaEggRecord) == "function" and uid then
        local rec = EggCmds.GetAreaEggRecord(uid)
        if rec and rec.State == "Carried" then return true end
    end
    return State.carrying
end

local function waitCarrying(uid, timeout)
    timeout = timeout or 5
    local t0 = workspace.DistributedGameTime
    while workspace.DistributedGameTime - t0 < timeout and State.running do
        if eggIsCarried(uid) then return true end
        task.wait(0.08)
    end
    return eggIsCarried(uid)
end

local function findPromptNear(pos, uid)
    local function check(inst)
        if not inst:IsA("ProximityPrompt") or not inst.Enabled then return false end
        local part = inst.Parent
        return part and part:IsA("BasePart") and pos and (part.Position - pos).Magnitude < 10
    end
    if uid then
        local model = Workspace:FindFirstChild(uid, true)
        if model then
            local p = model:FindFirstChildWhichIsA("ProximityPrompt", true)
            if p then return p end
        end
    end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if check(v) then return v end
    end
    return nil
end

-- ============================================================
-- MAIN STEAL CYCLE
-- ============================================================
local function stealCycle()
    if State.busy then return false end
    State.busy = true

    local ok, result = pcall(function()
        -- 1. Masuk arena
        if not crossToArena() then
            Notify("SAE", "Gagal masuk arena", "warning")
            return false
        end

        -- 2. Refresh snapshot
        pcall(function()
            if EggCmds and EggCmds.RequestAreaEggSnapshot then
                EggCmds.RequestAreaEggSnapshot()
            end
        end)
        task.wait(0.15)

        -- 3. Cari telur terdekat
        local eggs = listEggs()
        if #eggs == 0 then
            Notify("SAE", "Tidak ada telur di arena", "warning")
            return false
        end
        local egg = eggs[1].rec
        local uid = egg.Uid
        local pos  = egg.BottomCFrame and egg.BottomCFrame.Position
        if not pos then return false end

        -- 4. Smooth lerp ke telur
        State.status = "Jalan ke telur"
        walkTo(pos, TRAVEL_SPEED)

        -- 5. Simulate hold dengan random jitter (lebih natural)
        State.status = "Hold egg..."
        -- Random delay: simulate player reaction time
        task.wait(HOLD_WAIT + math.random(-10, 20) / 100)

        -- Coba ProximityPrompt
        local prompt = findPromptNear(pos, uid)
        if prompt and prompt.Enabled then
            if typeof(fireproximityprompt) == "function" then
                pcall(fireproximityprompt, prompt, prompt.HoldDuration or 0.5)
                task.wait((prompt.HoldDuration or 0.5) + 0.1)
            else
                pcall(function()
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration or 0.5)
                    prompt:InputHoldEnd()
                end)
            end
        end

        -- Coba EggCmds.RequestCarryAreaEgg
        if not waitCarrying(uid, 1.5) then
            pcall(function() EggCmds.RequestCarryAreaEgg(uid) end)
            waitCarrying(uid, 2)
        end

        if not eggIsCarried(uid) then
            Notify("SAE", "Gagal grab telur", "warning")
            return false
        end
        State.carrying = true

        -- 6. Balik ke plot (smooth lerp)
        State.status = "Balik ke base"
        local home = PlotCmds and PlotCmds.GetRespawnPointCFrame
            and PlotCmds.GetRespawnPointCFrame(LocalPlayer)
        if home then
            local line = getSeparationLine()
            if line and inGameplay() then
                walkTo(line.Position - line.CFrame.LookVector * 38 + Vector3.new(0, 3, 0))
            end
            walkTo(home.Position + Vector3.new(0, 3, 0))
        end

        task.wait(1.5)
        State.carrying = false
        State.stealCount += 1
        State.status = "Idle"
        Notify("SAE", "Telur ke-"..State.stealCount.." berhasil!", "success", 2)
        return true
    end)

    State.busy = false
    if not ok then
        warn("[SAE] Error:", result)
        Notify("SAE", tostring(result):sub(1, 60), "error")
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
-- HEARTBEAT SPOOF — jaga Humanoid tetap normal di tiap frame
-- Agar tidak trigger CharacterClient: Integrity check
-- ============================================================
local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local _savedWalkSpeed = nil
local _integrityConn = nil

local function startIntegritySpoof()
    if _integrityConn then return end
    _integrityConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local h = char:FindFirstChildOfClass("Humanoid")
        if not h then return end

        -- Simpan WalkSpeed asli game (set oleh SpeedPower)
        -- Jangan pernah override — hanya baca dan cache
        if h.WalkSpeed > 0 then
            _savedWalkSpeed = h.WalkSpeed
        end

        -- Kalau ada BodyMover yang tidak kita buat → hapus (mencegah velocity injection)
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") then
                if obj.Name ~= "SV_Speed" then  -- bukan punya kita
                    pcall(function() obj:Destroy() end)
                end
            end
        end

        -- Kalau tidak sedang gerak (idle) → pastikan MoveDirection nol
        -- Ini prevent "drift" yang bisa trigger integrity
        if not State.running and h.MoveDirection.Magnitude < 0.01 then
            pcall(function() h:Move(Vector3.zero, false) end)
        end
    end)
end

local function stopIntegritySpoof()
    if _integrityConn then
        _integrityConn:Disconnect()
        _integrityConn = nil
    end
end

-- Start spoof saat script load
startIntegritySpoof()
print("[SAE] Integrity spoof active")

-- Restart spoof kalau karakter respawn
LocalPlayer.CharacterAdded:Connect(function()
    stopIntegritySpoof()
    task.wait(1)
    startIntegritySpoof()
end)

-- Carry state listener
if EggCmds and EggCmds.AreaEggCarryStateChanged then
    pcall(function()
        EggCmds.AreaEggCarryStateChanged:Connect(function(payload)
            if payload and payload.IsCarrying ~= nil then
                State.carrying = payload.IsCarrying
            end
        end)
    end)
end

-- ============================================================
-- VVIND-UI
-- ============================================================
local Window = VindUI:CreateWindow({
    Title      = "Steal An Egg",
    Subtitle   = "by AlDev14",
    Icon       = "Lucide:egg",
    Size       = UDim2.fromOffset(520, 420),
    MinSize    = Vector2.new(420, 340),
    Draggable  = true,
    Resizable  = true,
    UseBlur    = false,
    DefaultTab = "Farm",
})

-- TAB FARM
local tabFarm = Window:AddTab({ Name = "Farm", Icon = "Lucide:zap" })
local secFarm = tabFarm:AddSubTab({ Name = "Auto Steal", Icon = "Lucide:egg" })

secFarm:AddParagraph({
    Title = "Info",
    Text  = "Karakter jalan fisik pakai movement game (anti-BAC). Speed farm = SpeedPower character di game.",
})

secFarm:AddToggle({
    Text     = "Auto Steal",
    Default  = false,
    Flag     = "autoSteal",
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
    Callback = function()
        task.spawn(stealCycle)
    end,
})

-- Travel Speed dikontrol game (SpeedPower), tidak ada slider manual

secFarm:AddSlider({
    Text      = "Hold Duration (s)",
    Min       = 0.3,
    Max       = 2.0,
    Default   = 0.6,
    Increment = 0.1,
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

-- Status display
local statusSec = tabFarm:AddSubTab({ Name = "Status", Icon = "Lucide:activity" })
statusSec:AddSystemInfoGrid({ Description = "FPS & Ping" })

task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            -- update status paragraph if possible
        end)
    end
end)

-- TAB SETTINGS
local tabSet = Window:AddTab({ Name = "Settings", Icon = "Lucide:settings" })
local secSet = tabSet:AddSubTab({ Name = "Config", Icon = "Lucide:save" })

secSet:AddButton({
    Text = "Save Config",
    Icon = "Lucide:save",
    Callback = function()
        pcall(function() VindUI:SaveConfig("sae_hub") end)
        Notify("Config", "Saved", "success", 2)
    end,
})
secSet:AddButton({
    Text = "Load Config",
    Icon = "Lucide:folder-open",
    Callback = function()
        pcall(function() VindUI:LoadConfig("sae_hub", true) end)
        Notify("Config", "Loaded", "success", 2)
    end,
})

-- Window auto-shown by VVind-UI
Notify("Steal An Egg", "Loaded — AlDev14", "success", 4)
print("[SAE] VVind-UI script loaded")
