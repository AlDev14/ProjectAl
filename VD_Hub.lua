-- ============================================================
-- VD HUB - Violent District
-- Version: 1.1 (Namespaced)
-- ============================================================
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(1)

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local UserInputService   = game:GetService("UserInputService")
local VirtualInputManager= game:GetService("VirtualInputManager")
local Lighting           = game:GetService("Lighting")
local TweenService       = game:GetService("TweenService")
local CoreGui            = game:GetService("CoreGui")
local LocalPlayer        = Players.LocalPlayer
local PlayerGui          = LocalPlayer:WaitForChild("PlayerGui", 10) or LocalPlayer:FindFirstChildOfClass("PlayerGui")
local Camera             = workspace.CurrentCamera

-- ============================================================
-- LOAD UI
-- ============================================================
pcall(function()
    if not getgenv().protectgui then getgenv().protectgui = function(g) return g end end
    if not getgenv().syn then getgenv().syn = {protect_gui=function(g) return g end} end
end)

print("[VD Hub] Loading FluentUI...")
local _src = nil
pcall(function()
    _src = game:HttpGet("https://raw.githubusercontent.com/AlDev14/modded-ui/refs/heads/main/FluentUI.lua")
end)
if not _src or _src == "" then warn("[VD Hub] HttpGet failed"); return end
local _fn, _err = loadstring(_src)
if not _fn then warn("[VD Hub] loadstring error: "..tostring(_err)); return end
local ok, Fluent = pcall(_fn)
if not ok or not Fluent then warn("[VD Hub] FluentUI error: "..tostring(Fluent)); return end
print("[VD Hub] FluentUI OK")



-- ============================================================
-- SC (skillcheck.lua)
-- ============================================================
local SC = (function()
-- ============================================================
-- AUTO SKILL CHECK
-- Violent District - Delta Executor
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui", 10)

-- Config
local SkillCheck = {
    Enabled = false,
    Mode    = "Legit",  -- "Instant" | "Legit" | "Random"
}

-- State
local busy = false
local conn = nil

-- Cari tombol skill check di PlayerGui
local function GetActionButton()
    if not PlayerGui then return nil end
    local mob  = PlayerGui:FindFirstChild("Survivor-mob")
    local ctrl = mob and mob:FindFirstChild("Controls")
    return ctrl and (ctrl:FindFirstChild("action") or ctrl:FindFirstChild("check"))
end

-- Trigger tombol (Delta pakai firesignal)
local function TriggerButton()
    local btn = GetActionButton()
    if btn and btn:IsA("GuiObject") and btn.Visible then
        pcall(function()
            firesignal(btn.MouseButton1Down)
            task.wait(0.005)
            firesignal(btn.MouseButton1Up)
        end)
        return
    end
    -- Fallback: keyboard Space
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.005)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
end

-- Main loop
local function startSkillCheck()
    if conn then conn:Disconnect() end
    conn = RunService.RenderStepped:Connect(function()
        if not SkillCheck.Enabled or busy then return end

        -- Cari GUI skillcheck
        local prompt = PlayerGui:FindFirstChild("SkillCheckPromptGui")
        if not prompt then return end
        local check = prompt:FindFirstChild("Check")
        if not check or not check.Visible then return end
        local line = check:FindFirstChild("Line")
        local goal = check:FindFirstChild("Goal")
        if not line or not goal then return end

        -- Tentukan mode
        local mode = SkillCheck.Mode
        if mode == "Random" then
            mode = (math.random(1, 2) == 1) and "Instant" or "Legit"
        end

        if mode == "Instant" then
            -- Set langsung ke zona perfect
            line.Rotation = goal.Rotation + 109
            busy = true
            task.spawn(function()
                TriggerButton()
                task.wait(0.2)
                busy = false
            end)

        else -- Legit
            local lr = line.Rotation % 360
            local gr = goal.Rotation % 360
            local s1 = (gr + 102) % 360
            local e1 = (gr + 116) % 360
            local inside = (s1 > e1 and (lr >= s1 or lr <= e1))
                        or (lr >= s1 and lr <= e1)
            if inside then
                busy = true
                task.spawn(function()
                    TriggerButton()
                    task.wait(0.05)
                    busy = false
                end)
            end
        end
    end)
end

local function stopSkillCheck()
    if conn then conn:Disconnect(); conn = nil end
    busy = false
end

-- Return module
    -- Expose API
    return {
        SkillCheck = SkillCheck,
        startSkillCheck = startSkillCheck,
        stopSkillCheck = stopSkillCheck,
        conn = conn,
        busy = busy,
    }
end)()


-- ============================================================
-- Parry (autoparry.lua)
-- ============================================================
local Parry = (function()
-- ============================================================
-- AUTO PARRY
-- Violent District - Delta Executor
-- Source: WisnuVip.txt (full implementation)
-- ============================================================

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local UserInputService    = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui", 10)

-- Config
local Config = {
    Enabled         = false,
    Radius          = 15,
    Safety          = true,   -- cegah parry saat vaulting/repairing/dll
    Aggressive      = false,  -- track killer sampai dalam range
    FaceThreshold   = 0.7,    -- dot product minimum killer facing kita
    AutoCrouch      = false,  -- auto crouch saat Abyssal S1
}

-- State
local State = {
    Cooldown       = false,
    CooldownThread = nil,
}

local Attached = {}  -- track killer char yang sudah di-attach

-- ============================================================
-- ANIMATION IDs yang memicu parry (dari WisnuVip)
-- ============================================================
local VALID_PARRY_IDS = {
    ["122812055447896"] = "Veil lunge",
    ["133963973694098"] = "Mayers Basic",
    ["117042998468241"] = "Mayers lunge",
    ["135002183282873"] = "Cure lunge",
    ["121216847022485"] = "Cure Basic",
    ["132817836308238"] = "Jeff Basic",
    ["129784271201071"] = "Jeff lunge",
    ["82666958311998"]  = "Jeff Frenzy",
    ["78432063483146"]  = "Abyssal Basic",
    ["118907603246885"] = "Abyssal lunge",
    ["139369275981139"] = "Jason Basic",
    ["110355011987939"] = "Jason lunge",
    ["111920872708571"] = "Masked Basic",
    ["105374834496520"] = "Masked lunge",
    ["138720291317243"] = "Masked Tony",
    ["106871536134254"] = "Masked Alex",
    ["130593238885843"] = "Masked Cobra",
    ["115244153053858"] = "Masked Cobra lunge",
    ["74968262036854"]  = "Hidden Basic",
    ["113255068724446"] = "Hidden lunge",
    ["98163597193511"]  = "Hidden S1",
    ["80411309607666"]  = "Abyssal S1", -- khusus: trigger crouch bukan parry
}

-- ============================================================
-- HELPERS
-- ============================================================
local function IsKiller(p)
    return p and p.Team and p.Team.Name:lower():find("killer") ~= nil
end

local function IsDowned(char)
    if not char then return false end
    return char:GetAttribute("Knocked") == true
        or char:GetAttribute("IsHooked") == true
        or char:GetAttribute("IsCarried") == true
end

local function IsSafeToParry(char)
    if not Config.Safety then return true end
    if not char then return false end
    local obj = char:FindFirstChild("CheckInterractable")
    if obj then
        if obj:GetAttribute("isVaulting")   == true then return false end
        if obj:GetAttribute("isRepairing")  == true then return false end
        if obj:GetAttribute("isUnhooking")  == true then return false end
        if obj:GetAttribute("isHealing")    == true then return false end
        if obj:GetAttribute("isSliding")    == true then return false end
    end
    return true
end

-- ============================================================
-- TRIGGER CROUCH (Abyssal S1)
-- ============================================================
local function TriggerCrouch()
    pcall(function()
        -- Cari crouch button
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local btn = nil
        if pg then
            local mob = pg:FindFirstChild("Survivor-mob")
            local ctrl = mob and mob:FindFirstChild("Controls")
            local crouch = ctrl and ctrl:FindFirstChild("crouch")
            local icon = crouch and crouch:FindFirstChild("icon")
            if icon and icon:IsA("GuiObject") and icon.Visible
            and icon.Parent and icon.Parent:IsA("GuiButton") then
                btn = icon.Parent
            end
        end
        if btn then
            pcall(function()
                firesignal(btn.MouseButton1Click)
                task.wait(2)
                firesignal(btn.MouseButton1Click)
            end)
        else
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
            task.wait(2)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
        end
    end)
end

-- ============================================================
-- TRIGGER MOBILE PARRY BUTTON
-- ============================================================
local function tapMobileParryButton()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    local mob = pg:FindFirstChild("Survivor-mob")
    local parryBtn = mob
        and mob:FindFirstChild("Controls")
        and mob.Controls:FindFirstChild("Gui-mob")
    if parryBtn and parryBtn.Visible then
        pcall(function()
            firesignal(parryBtn.MouseButton1Down)
            task.wait(0.01)
            firesignal(parryBtn.MouseButton1Up)
        end)
    else
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
        end)
    end
end

-- ============================================================
-- EXECUTE PARRY
-- ============================================================
local _parryRemoteCache = nil
local function getParryRemote()
    if _parryRemoteCache and _parryRemoteCache.Parent then return _parryRemoteCache end
    pcall(function()
        local r = ReplicatedStorage:FindFirstChild("Remotes")
        local items = r and r:FindFirstChild("Items")
        local dagger = items and items:FindFirstChild("Parrying Dagger")
        _parryRemoteCache = dagger and dagger:FindFirstChild("parry")
        -- fallback scan
        if not _parryRemoteCache and r then
            for _, v in ipairs(r:GetDescendants()) do
                if v:IsA("RemoteEvent") and v.Name:lower() == "parry" then
                    _parryRemoteCache = v; break
                end
            end
        end
    end)
    return _parryRemoteCache
end

local function ExecuteParry()
    if State.Cooldown then return end
    local remote = getParryRemote()
    pcall(function()
        if remote then
            for i = 1, 10 do remote:FireServer() end
        end
        task.spawn(tapMobileParryButton)
    end)
end

-- ============================================================
-- LISTEN PARRY COOLDOWN (dari server)
-- ============================================================
local function ListenToParryResult()
    task.spawn(function()
        local r = ReplicatedStorage:WaitForChild("Remotes", 5)
        local items = r and r:WaitForChild("Items", 5)
        local dagger = items and items:WaitForChild("Parrying Dagger", 5)
        local resultRemote = dagger and dagger:FindFirstChild("parryResult")
        if not resultRemote then return end
        resultRemote.OnClientEvent:Connect(function(arg1, arg2)
            local cdDur = tonumber(arg2) or ((arg1 == true) and 90 or 60)
            State.Cooldown = true
            if State.CooldownThread then task.cancel(State.CooldownThread) end
            State.CooldownThread = task.delay(cdDur, function()
                State.Cooldown = false
            end)
        end)
    end)
end

-- ============================================================
-- ATTACH SENSOR KE KILLER
-- ============================================================
local function AttachParrySensor(kChar)
    if not kChar or Attached[kChar] then return end
    Attached[kChar] = true

    local hum = kChar:FindFirstChild("Humanoid")
        or kChar:WaitForChild("Humanoid", 5)
    if not hum then return end

    local animator = hum:FindFirstChildOfClass("Animator")
        or hum:WaitForChild("Animator", 5)
    if not animator then return end

    -- Re-attach kalau Animator diganti
    hum.ChildAdded:Connect(function(child)
        if child:IsA("Animator") then
            Attached[kChar] = nil
            AttachParrySensor(kChar)
        end
    end)

    -- Cleanup saat killer respawn/keluar
    kChar.AncestryChanged:Connect(function(_, parent)
        if not parent then Attached[kChar] = nil end
    end)

    animator.AnimationPlayed:Connect(function(track)
        local animId = track.Animation and track.Animation.AnimationId or ""
        local id = animId:match("%d+")
        local attackName = VALID_PARRY_IDS[id]
        if not attackName then return end

        -- Abyssal S1  crouch bukan parry
        if id == "80411309607666" and Config.AutoCrouch then
            local myChar = LocalPlayer.Character
            if IsDowned(myChar) then return end
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local kHRP  = kChar:FindFirstChild("HumanoidRootPart")
            if myHRP and kHRP and (myHRP.Position - kHRP.Position).Magnitude <= 40 then
                task.spawn(TriggerCrouch)
            end
            return
        end

        if not Config.Enabled then return end
        if State.Cooldown then return end

        local myChar = LocalPlayer.Character
        if IsDowned(myChar) or not IsSafeToParry(myChar) then return end

        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local kHRP  = kChar:FindFirstChild("HumanoidRootPart")
        if not myHRP or not kHRP then return end

        local dist = (myHRP.Position - kHRP.Position).Magnitude

        if Config.Aggressive then
            -- Track killer sampai dalam range 12 studs
            local aggressiveRadius = 12
            local detectionRadius  = Config.Radius + 5
            if dist > detectionRadius then return end
            if dist <= aggressiveRadius then
                ExecuteParry()
            else
                local tracker
                local startTime = workspace.DistributedGameTime
                tracker = RunService.Heartbeat:Connect(function()
                    local elapsed = workspace.DistributedGameTime - startTime
                    if elapsed >= 1.5 or State.Cooldown or IsDowned(myChar) then
                        if tracker then tracker:Disconnect() end
                        return
                    end
                    if (myHRP.Position - kHRP.Position).Magnitude <= aggressiveRadius then
                        ExecuteParry()
                        if tracker then tracker:Disconnect() end
                    end
                end)
            end
        else
            -- Mode normal: cek distance + face direction
            if dist > Config.Radius then return end
            local flat1 = Vector3.new(myHRP.Position.X, 0, myHRP.Position.Z)
            local flat2 = Vector3.new(kHRP.Position.X,  0, kHRP.Position.Z)
            local delta = flat1 - flat2
            if delta.Magnitude > 0 then
                local dir    = delta.Unit
                local kLook  = Vector3.new(kHRP.CFrame.LookVector.X, 0, kHRP.CFrame.LookVector.Z).Unit
                if kLook:Dot(dir) < Config.FaceThreshold then return end
            end
            ExecuteParry()
        end
    end)
end

-- ============================================================
-- SETUP SEMUA PLAYER
-- ============================================================
local function TryAttach(p)
    if p ~= LocalPlayer and IsKiller(p) and p.Character then
        AttachParrySensor(p.Character)
    end
end

local function SetupPlayer(p)
    if p == LocalPlayer then return end
    p.CharacterAdded:Connect(function() task.wait(0.5); TryAttach(p) end)
    p:GetPropertyChangedSignal("Team"):Connect(function() TryAttach(p) end)
    TryAttach(p)
end

-- ============================================================
-- PARRY CIRCLE VISUAL
-- ============================================================
local ParryCircle = nil
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if Config.Enabled and hrp then
        if not ParryCircle then
            ParryCircle = Instance.new("Part")
            ParryCircle.Name = "VD_ParryCircle"
            ParryCircle.Shape = Enum.PartType.Cylinder
            ParryCircle.Anchored = true
            ParryCircle.CanCollide = false
            ParryCircle.CastShadow = false
            ParryCircle.Material = Enum.Material.Neon
            ParryCircle.Color = Color3.fromRGB(255, 80, 80)
            ParryCircle.Transparency = 0.5
            ParryCircle.Parent = workspace
        end
        local r = Config.Radius * 2
        ParryCircle.Size = Vector3.new(0.15, r, r)
        local yOff = hrp.Size.Y / 2 + 0.5
        ParryCircle.CFrame = CFrame.new(hrp.Position - Vector3.new(0, yOff, 0))
            * CFrame.Angles(0, 0, math.rad(90))
    elseif ParryCircle then
        ParryCircle:Destroy()
        ParryCircle = nil
    end
end)

-- ============================================================
-- INIT
-- ============================================================
-- Listen cooldown dari server
ListenToParryResult()

-- Setup semua player yang sudah ada
for _, p in ipairs(Players:GetPlayers()) do
    SetupPlayer(p)
end
Players.PlayerAdded:Connect(SetupPlayer)

-- Return module
    -- Expose API
    return {
        Config = Config,
        State = State,
        Attached = Attached,
        ExecuteParry = ExecuteParry,
        AttachParrySensor = AttachParrySensor,
        SetupPlayer = SetupPlayer,
        ListenToParryResult = ListenToParryResult,
        ParryCircle = ParryCircle,
    }
end)()


-- ============================================================
-- GenBP (genbypass.lua)
-- ============================================================
local GenBP = (function()
-- ============================================================
-- GEN BYPASS (Boost Repair)
-- Violent District - Delta Executor
-- Source: WisnuVip.txt (full implementation)
-- ============================================================

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local UserInputService    = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui", 10)

-- Config
local GenBypass = {
    Enabled    = false,
    Button     = nil,
    UI         = nil,
    Cache      = {},
    CacheTimer = 0,
    Processed  = {},
    Hotkey     = Enum.KeyCode.G,
}

-- ============================================================
-- CACHE GENERATORS (refresh tiap 5 detik)
-- ============================================================
local function GB_GetAllGenerators()
    local now = workspace.DistributedGameTime
    if now - GenBypass.CacheTimer < 5 then return GenBypass.Cache end
    GenBypass.Cache      = {}
    GenBypass.CacheTimer = now
    local mapFolder = workspace:FindFirstChild("Map")
    if not mapFolder then return GenBypass.Cache end
    pcall(function()
        for _, v in pairs(mapFolder:GetDescendants()) do
            if not v:IsA("Model") then continue end
            if v.Name ~= "Generator" then continue end
            -- Pastikan generator asli (bukan prop)
            local isReal = v:GetAttribute("RepairProgress") ~= nil
                or v:GetAttribute("kickcount") ~= nil
                or v:GetAttribute("ProgressRepair") ~= nil
            if isReal then table.insert(GenBypass.Cache, v) end
        end
    end)
    return GenBypass.Cache
end

-- ============================================================
-- DAPATKAN REPAIR POINTS DI GENERATOR
-- ============================================================
local function GB_GetPoints(genModel)
    local points = {}
    pcall(function()
        for _, obj in pairs(genModel:GetChildren()) do
            if obj.Name:find("GeneratorPoint") and obj:IsA("BasePart") then
                table.insert(points, obj)
            end
        end
    end)
    return points
end

-- ============================================================
-- TUNGGU SAMPAI POINT MULAI REPAIR
-- ============================================================
local function GB_WaitRepairing(point, timeout)
    local start = workspace.DistributedGameTime
    while workspace.DistributedGameTime - start < (timeout or 1) do
        if point:GetAttribute("IsRepairing") == true then return true end
        task.wait(0.05)
    end
    return false
end

-- ============================================================
-- REMOTE REPAIR
-- ============================================================
local _repairRemote = nil
local function getRepairRemote()
    if _repairRemote and _repairRemote.Parent then return _repairRemote end
    pcall(function()
        local r = ReplicatedStorage:FindFirstChild("Remotes")
        local gen = r and r:FindFirstChild("Generator")
        _repairRemote = gen and gen:FindFirstChild("RepairEvent")
    end)
    return _repairRemote
end

-- ============================================================
-- DO REPAIR (logic utama gen bypass)
-- ============================================================
local function GB_DoRepair(targetPoint)
    local genModel = targetPoint.Parent
    if GenBypass.Processed[genModel] then return end
    GenBypass.Processed[genModel] = true

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then GenBypass.Processed[genModel] = nil; return end

    local RepairEvent = getRepairRemote()
    if not RepairEvent then
        GenBypass.Processed[genModel] = nil
        return
    end

    local originalCFrame = hrp.CFrame

    pcall(function()
        for _, point in pairs(GB_GetPoints(genModel)) do
            if point ~= targetPoint and point.Parent then
                hrp.Anchored = true
                hrp.CFrame   = point.CFrame
                task.wait(0.15)
                pcall(function() RepairEvent:FireServer(point, true) end)
                -- Kalau tidak mulai repair, coba sekali lagi
                if not GB_WaitRepairing(point, 0.8) then
                    pcall(function() RepairEvent:FireServer(point, false) end)
                    task.wait(0.1)
                    hrp.CFrame = point.CFrame
                    task.wait(0.15)
                    pcall(function() RepairEvent:FireServer(point, true) end)
                    GB_WaitRepairing(point, 0.5)
                end
                hrp.Anchored = false
                task.wait(0.05)
            end
        end
    end)

    -- Restore posisi + stop repair di target point
    pcall(function()
        if hrp and hrp.Parent then
            hrp.Anchored = false
            hrp.CFrame   = originalCFrame
        end
    end)
    task.wait(0.1)
    pcall(function() RepairEvent:FireServer(targetPoint, false) end)
    GenBypass.Processed[genModel] = nil
end

-- ============================================================
-- CARI GENERATOR POINT TERDEKAT
-- ============================================================
local function GB_GetNearestPoint()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end
    local bestPoint, bestDist = nil, math.huge
    for _, gen in pairs(GB_GetAllGenerators()) do
        for _, point in pairs(GB_GetPoints(gen)) do
            local d = (hrp.Position - point.Position).Magnitude
            if d < bestDist then bestDist = d; bestPoint = point end
        end
    end
    return bestPoint, bestDist
end

-- ============================================================
-- MOBILE BUTTON
-- ============================================================
local function GB_UpdateButton()
    if GenBypass.Button then
        GenBypass.Button.Visible = GenBypass.Enabled and UserInputService.TouchEnabled
    end
end

local function GB_CreateButton()
    local oldUI = PlayerGui:FindFirstChild("BypassGenUI")
    if oldUI then oldUI:Destroy() end

    GenBypass.UI = Instance.new("ScreenGui")
    GenBypass.UI.Name = "BypassGenUI"
    GenBypass.UI.ResetOnSpawn = false
    GenBypass.UI.IgnoreGuiInset = true
    GenBypass.UI.Parent = PlayerGui

    GenBypass.Button = Instance.new("ImageButton")
    GenBypass.Button.Name = "BypassGenButton"
    GenBypass.Button.Size = UDim2.new(0, 60, 0, 60)
    GenBypass.Button.Position = UDim2.new(0.88, 0, 0.55, 0)
    GenBypass.Button.AnchorPoint = Vector2.new(0.5, 0.5)
    GenBypass.Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    GenBypass.Button.BackgroundTransparency = 0.15
    GenBypass.Button.AutoButtonColor = true
    GenBypass.Button.Visible = false
    GenBypass.Button.ZIndex = 10
    GenBypass.Button.Parent = GenBypass.UI
    Instance.new("UICorner", GenBypass.Button).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", GenBypass.Button)
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2; stroke.Transparency = 0.2
    local lbl = Instance.new("TextLabel", GenBypass.Button)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "BYPASS"
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBlack
    lbl.ZIndex = 11

    -- Tap button  repair generator terdekat
    GenBypass.Button.MouseButton1Click:Connect(function()
        if not GenBypass.Enabled then return end
        local bestPoint, bestDist = GB_GetNearestPoint()
        if bestPoint and bestDist <= 8 then
            task.spawn(function() GB_DoRepair(bestPoint) end)
        end
    end)
end

-- ============================================================
-- PC HOTKEY
-- ============================================================
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == GenBypass.Hotkey and GenBypass.Enabled then
        local bestPoint, bestDist = GB_GetNearestPoint()
        if bestPoint and bestDist <= 8 then
            task.spawn(function() GB_DoRepair(bestPoint) end)
        end
    end
end)

-- ============================================================
-- ENABLE / DISABLE
-- ============================================================
local function setGenBypass(v)
    GenBypass.Enabled = v
    GB_UpdateButton()
end

-- ============================================================
-- INIT
-- ============================================================
GB_CreateButton()
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    GB_CreateButton()
    GB_UpdateButton()
end)

-- Return module
    -- Expose API
    return {
        GenBypass = GenBypass,
        GB_GetAllGenerators = GB_GetAllGenerators,
        GB_GetPoints = GB_GetPoints,
        GB_WaitRepairing = GB_WaitRepairing,
        GB_DoRepair = GB_DoRepair,
        GB_GetNearestPoint = GB_GetNearestPoint,
        GB_CreateButton = GB_CreateButton,
        GB_UpdateButton = GB_UpdateButton,
        setGenBypass = setGenBypass,
    }
end)()


-- ============================================================
-- Dodge (autododge.lua)
-- ============================================================
local Dodge = (function()
-- ============================================================
-- AUTO DODGE / CROUCH (Abyssal S1)
-- Violent District - Delta Executor
-- ============================================================

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui", 10)

-- Config
local Config = {
    Enabled      = false,
    MaxDistance  = 40,  -- jarak max dari killer untuk trigger
}

-- State
local Attached = {}

-- ============================================================
-- HELPERS
-- ============================================================
local function IsKiller(p)
    return p and p.Team and p.Team.Name:lower():find("killer") ~= nil
end

local function IsDowned(char)
    if not char then return false end
    return char:GetAttribute("Knocked") == true
        or char:GetAttribute("IsHooked") == true
        or char:GetAttribute("IsCarried") == true
end

-- ============================================================
-- TRIGGER CROUCH
-- ============================================================
local function TriggerCrouch()
    pcall(function()
        -- Cari crouch button di mobile
        local pg   = LocalPlayer:FindFirstChild("PlayerGui")
        local btn  = nil
        if pg then
            local mob   = pg:FindFirstChild("Survivor-mob")
            local ctrl  = mob and mob:FindFirstChild("Controls")
            local crouch = ctrl and ctrl:FindFirstChild("crouch")
            local icon  = crouch and crouch:FindFirstChild("icon")
            if icon and icon:IsA("GuiObject") and icon.Visible
            and icon.Parent and icon.Parent:IsA("GuiButton") then
                btn = icon.Parent
            end
        end

        if btn then
            -- Mobile: firesignal
            pcall(function()
                firesignal(btn.MouseButton1Click)
                task.wait(2)
                firesignal(btn.MouseButton1Click)
            end)
        else
            -- PC: LeftControl
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
            task.wait(2)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
        end
    end)
end

-- ============================================================
-- ABYSSAL S1 ANIMATION ID
-- ============================================================
local ABYSSAL_S1_ID = "80411309607666"

-- ============================================================
-- ATTACH SENSOR KE KILLER
-- ============================================================
local function AttachDodgeSensor(kChar)
    if not kChar or Attached[kChar] then return end
    Attached[kChar] = true

    local hum = kChar:FindFirstChild("Humanoid")
        or kChar:WaitForChild("Humanoid", 5)
    if not hum then return end

    local animator = hum:FindFirstChildOfClass("Animator")
        or hum:WaitForChild("Animator", 5)
    if not animator then return end

    -- Re-attach kalau Animator diganti
    hum.ChildAdded:Connect(function(child)
        if child:IsA("Animator") then
            Attached[kChar] = nil
            AttachDodgeSensor(kChar)
        end
    end)

    -- Cleanup saat killer keluar
    kChar.AncestryChanged:Connect(function(_, parent)
        if not parent then Attached[kChar] = nil end
    end)

    -- Listen animasi
    animator.AnimationPlayed:Connect(function(track)
        if not Config.Enabled then return end

        local anim = track.Animation
        local id   = anim and anim.AnimationId:match("%d+") or ""
        if id ~= ABYSSAL_S1_ID then return end

        local myChar = LocalPlayer.Character
        if IsDowned(myChar) then return end

        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local kHRP  = kChar:FindFirstChild("HumanoidRootPart")
        if not myHRP or not kHRP then return end

        local dist = (myHRP.Position - kHRP.Position).Magnitude
        if dist > Config.MaxDistance then return end

        task.spawn(TriggerCrouch)
    end)
end

-- ============================================================
-- SETUP SEMUA PLAYER
-- ============================================================
local function TryAttach(p)
    if p ~= LocalPlayer and IsKiller(p) and p.Character then
        AttachDodgeSensor(p.Character)
    end
end

local function SetupPlayer(p)
    if p == LocalPlayer then return end
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        TryAttach(p)
    end)
    p:GetPropertyChangedSignal("Team"):Connect(function()
        TryAttach(p)
    end)
    TryAttach(p)
end

-- Init
for _, p in ipairs(Players:GetPlayers()) do
    SetupPlayer(p)
end
Players.PlayerAdded:Connect(SetupPlayer)

-- Return module
    -- Expose API
    return {
        Config = Config,
        Attached = Attached,
        AttachDodgeSensor = AttachDodgeSensor,
    }
end)()


-- ============================================================
-- FVault (fastvault.lua)
-- ============================================================
local FVault = (function()
-- ============================================================
-- FAST VAULT (Anti Slow Vault)
-- Violent District - Delta Executor
-- Source: W424final.txt
-- ============================================================

local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer

-- Config
local Config = {
    Enabled   = false,
    Speed     = 1.5,   -- multiplier kecepatan animasi vault
    -- Map animasi vault lama  animasi vault cepat
    ReplaceMap = {
        ["rbxassetid://83873880822918"] = "rbxassetid://136962284480779"
    }
}

-- State
local VaultTracks        = {}
local UnlimitedVaultConn = nil
local FastVaultAnimConn  = nil

-- ============================================================
-- NORMALIZE ANIMATION ID
-- ============================================================
local function normalizeId(id)
    local num = tostring(id):match("%d+")
    return num and ("rbxassetid://" .. num)
end

-- ============================================================
-- HOOK VAULT ANIMATION (Fast Vault)
-- Deteksi animasi vault  replace dengan versi cepat
-- ============================================================
local function hookVault(char)
    if FastVaultAnimConn then
        FastVaultAnimConn:Disconnect()
        FastVaultAnimConn = nil
    end
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return end

    FastVaultAnimConn = animator.AnimationPlayed:Connect(function(track)
        if not Config.Enabled then return end

        local anim = track.Animation
        if not anim or not anim.AnimationId then return end

        local id = normalizeId(anim.AnimationId)
        if not id then return end

        -- Cek apakah ini animasi vault yang perlu di-replace
        local replaceId = Config.ReplaceMap[id]

        -- Kalau tidak ada di map, cek nama animasi
        if not replaceId then
            local animName = (anim.Name or ""):lower()
            if animName:find("vault") or animName:find("window") then
                -- Pakai animasi default fast jika nama cocok
                replaceId = "rbxassetid://136962284480779"
            end
        end

        if not replaceId then return end
        if VaultTracks[track] then return end

        VaultTracks[track] = true
        pcall(function()
            track:Stop()
            local newAnim = Instance.new("Animation")
            newAnim.AnimationId = replaceId
            local newTrack = animator:LoadAnimation(newAnim)
            newTrack.Priority = Enum.AnimationPriority.Action
            newTrack:Play()
            newTrack:AdjustSpeed(Config.Speed)
            newTrack.Stopped:Connect(function()
                VaultTracks[track] = nil
            end)
        end)
    end)
end

-- ============================================================
-- UNLIMITED VAULT (no cooldown via CollectionService)
-- ============================================================
local function EnableUnlimitedVault()
    -- Hapus tag "Blocked" dari semua instance (cegah slow vault)
    pcall(function()
        for _, v in ipairs(CollectionService:GetTagged("Blocked")) do
            CollectionService:RemoveTag(v, "Blocked")
        end
    end)
    -- Listen tag baru dan langsung hapus
    if UnlimitedVaultConn then UnlimitedVaultConn:Disconnect() end
    UnlimitedVaultConn = CollectionService:GetInstanceAddedSignal("Blocked"):Connect(function(inst)
        if Config.Enabled then
            CollectionService:RemoveTag(inst, "Blocked")
        end
    end)
end

local function DisableUnlimitedVault()
    if UnlimitedVaultConn then
        UnlimitedVaultConn:Disconnect()
        UnlimitedVaultConn = nil
    end
    if FastVaultAnimConn then
        FastVaultAnimConn:Disconnect()
        FastVaultAnimConn = nil
    end
    table.clear(VaultTracks)
end

-- ============================================================
-- ENABLE / DISABLE
-- ============================================================
local function Enable()
    Config.Enabled = true
    EnableUnlimitedVault()
    hookVault(LocalPlayer.Character)
end

local function Disable()
    Config.Enabled = false
    DisableUnlimitedVault()
end

-- ============================================================
-- INIT - re-hook saat respawn
-- ============================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if Config.Enabled then
        EnableUnlimitedVault()
        hookVault(char)
    end
end)

if LocalPlayer.Character then
    hookVault(LocalPlayer.Character)
end

-- Return module
    -- Expose API
    return {
        Config = Config,
        VaultTracks = VaultTracks,
        hookVault = hookVault,
        EnableUnlimitedVault = EnableUnlimitedVault,
        DisableUnlimitedVault = DisableUnlimitedVault,
        Enable = Enable,
        Disable = Disable,
        normalizeId = normalizeId,
    }
end)()


-- ============================================================
-- SAS (selfheal_noaura_silent.lua)
-- ============================================================
local SAS = (function()
-- ============================================================
-- SELF HEAL + SILENT ACTIONS + ANTI AURA
-- Violent District - Delta Executor
-- Source: lua (4).txt (Quantum Hub)
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Config
local Config = {
    SelfHeal       = false,  -- redirect heal remote ke diri sendiri
    SilentActions  = false,  -- blokir notifikasi noise ke killer
    AntiAura       = false,  -- blokir aura/radar detect remote
}

-- ============================================================
-- HEAL REMOTE (lazy load)
-- ============================================================
local _healRemote = nil
local function getHealRemote()
    if _healRemote and _healRemote.Parent then return _healRemote end
    pcall(function()
        local r = ReplicatedStorage:FindFirstChild("Remotes")
        _healRemote = r and (
            r:FindFirstChild("HealEvent",   true) or
            r:FindFirstChild("RequestHeal", true) or
            r:FindFirstChild("ReviveEvent", true)
        )
    end)
    return _healRemote
end

-- ============================================================
-- HOOKMETAMETHOD SETUP
-- ============================================================
local _hooked = false
local _oldNamecall = nil
local _auraCache = {}

local function setupHooks()
    if _hooked then return end
    if not (hookmetamethod and getrawmetatable and setreadonly) then return end

    pcall(function()
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        _oldNamecall = old
        setreadonly(mt, false)

        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args   = {...}

            if not checkcaller() and method == "FireServer" then
                local n = tostring(self):lower()

                --  SELF HEAL 
                -- Intercept HealEvent dan arahkan ke diri sendiri
                if Config.SelfHeal and n:find("healevent") then
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    local hum  = char and char:FindFirstChildOfClass("Humanoid")
                    if root and hum and hum.Health > 0 then
                        args[1] = root
                        if args[2] == nil then args[2] = true end
                        return old(self, table.unpack(args))
                    end
                end

                --  SILENT ACTIONS 
                -- Blokir remote yang mengirim notifikasi noise ke killer
                if Config.SilentActions then
                    local noiseWords = {
                        "noise","scream","vaultalert","spotted","alert",
                        "ping","loud","notify","notification","sound"
                    }
                    local firstArg = type(args[1])=="string" and args[1]:lower() or ""
                    for _, w in ipairs(noiseWords) do
                        if n:find(w) or firstArg:find(w) then
                            return  -- blokir
                        end
                    end
                end

                --  ANTI AURA 
                -- Blokir remote tracker/aura yang mention player kita
                if Config.AntiAura then
                    local key = tostring(self)
                    if _auraCache[key] == nil then
                        local score = 0
                        local auraWords = {
                            "aura","reveal","highlight","sense","spotted",
                            "vision","radar","detect","tracking","hunter"
                        }
                        for _, w in ipairs(auraWords) do
                            if n:find(w) then score = score + 2 end
                        end
                        -- Cek apakah remote mention LocalPlayer
                        local mentions = false
                        for i = 1, math.min(3, #args) do
                            if args[i] == LocalPlayer or args[i] == LocalPlayer.Character then
                                mentions = true; break
                            end
                        end
                        _auraCache[key] = (score >= 4 and mentions)
                    end
                    if _auraCache[key] then
                        return  -- blokir
                    end
                end
            end

            return old(self, ...)
        end)

        setreadonly(mt, true)
        _hooked = true
    end)
end

-- Setup saat module di-load
setupHooks()

-- Clear aura cache saat respawn (remote keys bisa berubah)
LocalPlayer.CharacterAdded:Connect(function()
    _auraCache = {}
    -- Re-cache heal remote
    _healRemote = nil
end)

-- Return module
    -- Expose API
    return {
        Config = Config,
        _auraCache = _auraCache,
        _hooked = _hooked,
        _oldCall = _oldCall,
        setupHooks = setupHooks,
    }
end)()


-- ============================================================
-- MW (moonwalk.lua)
-- ============================================================
local MW = (function()
-- ============================================================
-- MOONWALK V3
-- Violent District - Delta Executor
-- Source: WisnuVip.txt
-- ============================================================

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui", 10)

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
    SIDE_SPEED    = 2.2,
    BACK_SPEED    = 4.0,
    INTERVAL      = 0.045,
    SMOOTH_FACTOR = 0.85,
    KEYBIND       = Enum.KeyCode.G,
    GUI_POSITION  = UDim2.fromScale(0.78, 0.22),
}

-- State
local MoonwalkEnabled  = false
local MoonwalkMoveConn = nil
local MoonwalkGui      = nil
local CurrentDirection = 1
local LastSwitch       = 0
local SmoothVelocity   = Vector3.new()

-- ============================================================
-- STOP
-- ============================================================
local function stopMoonwalkInternal()
    if MoonwalkMoveConn then
        MoonwalkMoveConn:Disconnect()
        MoonwalkMoveConn = nil
    end
    SmoothVelocity = Vector3.new()
end

-- ============================================================
-- START
-- ============================================================
local function startMoonwalkInternal()
    stopMoonwalkInternal()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    CurrentDirection = 1
    LastSwitch = 0

    MoonwalkMoveConn = RunService.RenderStepped:Connect(function()
        if not MoonwalkEnabled then return end

        local c = LocalPlayer.Character
        if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart")
        local h = c:FindFirstChildOfClass("Humanoid")
        if not r or not h or h.Health <= 0 then
            stopMoonwalkInternal()
            return
        end

        -- Gunakan DistributedGameTime (Delta-safe, tick() = 0 di Delta)
        local now = workspace.DistributedGameTime
        if now - LastSwitch >= CONFIG.INTERVAL then
            CurrentDirection = CurrentDirection * -1
            LastSwitch = now
        end

        local look  = r.CFrame.LookVector
        local right = r.CFrame.RightVector
        local target = (look * -CONFIG.BACK_SPEED) + (right * (CurrentDirection * CONFIG.SIDE_SPEED))

        SmoothVelocity = SmoothVelocity:Lerp(target, CONFIG.SMOOTH_FACTOR)
        h:Move(SmoothVelocity, false)
    end)
end

-- ============================================================
-- DESTROY GUI
-- ============================================================
local function destroyMoonwalkGui()
    if MoonwalkGui then
        MoonwalkGui:Destroy()
        MoonwalkGui = nil
    end
end

-- ============================================================
-- CREATE GUI
-- ============================================================
local function createMoonwalkGui()
    destroyMoonwalkGui()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end

    MoonwalkGui = Instance.new("ScreenGui")
    MoonwalkGui.Name = "VD_Moonwalk_V3"
    MoonwalkGui.ResetOnSpawn = false
    MoonwalkGui.Parent = pg

    local frame = Instance.new("Frame", MoonwalkGui)
    frame.Name = "MainFrame"
    frame.Size = UDim2.fromOffset(180, 110)
    frame.Position = CONFIG.GUI_POSITION
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
    frame.BackgroundTransparency = 0.15
    frame.Active = true
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    -- Glow
    local glow = Instance.new("Frame", frame)
    glow.Name = "Glow"
    glow.Size = UDim2.fromScale(1, 1)
    glow.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
    glow.BackgroundTransparency = 0.9
    glow.BorderSizePixel = 0
    Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 12)

    -- Title
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,-50,0,24)
    title.Position = UDim2.fromOffset(0,4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = Color3.fromRGB(150,200,255)
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Text = "Moonwalk V3"

    -- Minimize button
    local minimizeBtn = Instance.new("TextButton", frame)
    minimizeBtn.Size = UDim2.fromOffset(20,20)
    minimizeBtn.Position = UDim2.new(1,-46,0,4)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(40,40,60)
    minimizeBtn.Text = "-"
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 14
    minimizeBtn.TextColor3 = Color3.new(1,1,1)
    minimizeBtn.BorderSizePixel = 0
    Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0,6)

    -- Close button
    local closeBtn = Instance.new("TextButton", frame)
    closeBtn.Size = UDim2.fromOffset(20,20)
    closeBtn.Position = UDim2.new(1,-24,0,4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180,30,30)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 11
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.BorderSizePixel = 0
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)

    -- Status label
    local statusLbl = Instance.new("TextLabel", frame)
    statusLbl.Name = "StatusLbl"
    statusLbl.Size = UDim2.new(1,0,0,16)
    statusLbl.Position = UDim2.fromOffset(0,30)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Font = Enum.Font.GothamBold
    statusLbl.TextSize = 10
    statusLbl.TextColor3 = Color3.fromRGB(255,80,80)
    statusLbl.TextXAlignment = Enum.TextXAlignment.Center
    statusLbl.Text = "[OFF]"

    -- Keybind label
    local keybindLbl = Instance.new("TextLabel", frame)
    keybindLbl.Size = UDim2.new(1,0,0,14)
    keybindLbl.Position = UDim2.fromOffset(0,46)
    keybindLbl.BackgroundTransparency = 1
    keybindLbl.Font = Enum.Font.Gotham
    keybindLbl.TextSize = 9
    keybindLbl.TextColor3 = Color3.fromRGB(140,140,160)
    keybindLbl.TextXAlignment = Enum.TextXAlignment.Center
    keybindLbl.Text = "Hotkey: G"

    -- Toggle button
    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Size = UDim2.fromOffset(160,28)
    toggleBtn.Position = UDim2.fromOffset(10,70)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,130)
    toggleBtn.Text = "[>] START"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 11
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.BorderSizePixel = 0
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,6)

    -- Speed bar
    local speedBar = Instance.new("Frame", frame)
    speedBar.Name = "SpeedBar"
    speedBar.Size = UDim2.fromOffset(160,6)
    speedBar.Position = UDim2.fromOffset(10,102)
    speedBar.BackgroundColor3 = Color3.fromRGB(30,30,50)
    speedBar.BorderSizePixel = 0
    Instance.new("UICorner", speedBar).CornerRadius = UDim.new(1,0)
    local speedFill = Instance.new("Frame", speedBar)
    speedFill.Name = "SpeedFill"
    speedFill.Size = UDim2.fromScale(0,1)
    speedFill.BackgroundColor3 = Color3.fromRGB(80,120,255)
    speedFill.BorderSizePixel = 0
    Instance.new("UICorner", speedFill).CornerRadius = UDim.new(1,0)

    --  Toggle button click 
    local minimized = false
    toggleBtn.MouseButton1Click:Connect(function()
        MoonwalkEnabled = not MoonwalkEnabled
        if MoonwalkEnabled then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(50,200,100)
            toggleBtn.Text = "[.] STOP"
            statusLbl.Text = "[ON]"
            statusLbl.TextColor3 = Color3.fromRGB(0,255,150)
            glow.BackgroundColor3 = Color3.fromRGB(0,255,150)
            glow.BackgroundTransparency = 0.85
            game:GetService("TweenService"):Create(speedFill, TweenInfo.new(0.3), {Size=UDim2.fromScale(1,1)}):Play()
            startMoonwalkInternal()
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,130)
            toggleBtn.Text = "[>] START"
            statusLbl.Text = "[OFF]"
            statusLbl.TextColor3 = Color3.fromRGB(255,80,80)
            glow.BackgroundColor3 = Color3.fromRGB(80,120,255)
            glow.BackgroundTransparency = 0.9
            game:GetService("TweenService"):Create(speedFill, TweenInfo.new(0.3), {Size=UDim2.fromScale(0,1)}):Play()
            stopMoonwalkInternal()
        end
    end)

    --  Minimize 
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        speedBar.Visible = not minimized
        toggleBtn.Visible = not minimized
        statusLbl.Visible = not minimized
        keybindLbl.Visible = not minimized
        frame.Size = minimized and UDim2.fromOffset(180,32) or UDim2.fromOffset(180,110)
        minimizeBtn.Text = minimized and "+" or "-"
    end)

    --  Close 
    closeBtn.MouseButton1Click:Connect(function()
        MoonwalkEnabled = false
        stopMoonwalkInternal()
        destroyMoonwalkGui()
    end)

    --  Drag 
    local drag, ds, sp = false, nil, nil
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag=true; ds=Vector2.new(inp.Position.X, inp.Position.Y); sp=frame.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag=false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = Vector2.new(inp.Position.X, inp.Position.Y) - ds
            local vs = MoonwalkGui.AbsoluteSize
            if vs.X > 0 and vs.Y > 0 then
                frame.Position = UDim2.new(
                    math.clamp(sp.X.Scale + d.X/vs.X, 0, 0.9), 0,
                    math.clamp(sp.Y.Scale + d.Y/vs.Y, 0, 0.9), 0
                )
            end
        end
    end)
end

-- ============================================================
-- KEYBIND (G)
-- ============================================================
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == CONFIG.KEYBIND and MoonwalkGui then
        local toggleBtn = MoonwalkGui:FindFirstChild("MainFrame")
            and MoonwalkGui.MainFrame:FindFirstChild("ToggleBtn")
        if toggleBtn then
            toggleBtn.MouseButton1Click:Fire()
        end
    end
end)

-- ============================================================
-- RESPAWN HANDLER
-- ============================================================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if MoonwalkEnabled then
        startMoonwalkInternal()
    end
end)

-- ============================================================
-- PUBLIC API
-- ============================================================
local function Enable()
    createMoonwalkGui()
    MoonwalkEnabled = true
    startMoonwalkInternal()
end

local function Disable()
    MoonwalkEnabled = false
    stopMoonwalkInternal()
    destroyMoonwalkGui()
end

    -- Expose API
    return {
        CONFIG = CONFIG,
        MoonwalkEnabled = MoonwalkEnabled,
        startMoonwalkInternal = startMoonwalkInternal,
        stopMoonwalkInternal = stopMoonwalkInternal,
        createMoonwalkGui = createMoonwalkGui,
        destroyMoonwalkGui = destroyMoonwalkGui,
        Enable = Enable,
        Disable = Disable,
    }
end)()


-- ============================================================
-- KP (killerprediction.lua)
-- ============================================================
local KP = (function()
-- ============================================================
-- KILLER PREDICTION (Spectator Only)
-- Violent District - Delta Executor
-- Source: SourceKu.lua.txt
-- ============================================================

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Config
local Config = {
    Enabled  = false,
    Interval = 3,  -- update setiap N detik
}

-- GUI
local PredGui   = nil
local PredLabel = nil

-- ============================================================
-- HELPERS
-- ============================================================
local function GetGameValue(obj, name)
    if typeof(obj) ~= "Instance" then return nil end
    local attr = obj:GetAttribute(name)
    if attr ~= nil then return attr end
    local child = obj:FindFirstChild(name)
    if child and child:IsA("ValueBase") then return child.Value end
    return nil
end

local function isSpectator()
    local team = LocalPlayer.Team and LocalPlayer.Team.Name or ""
    return team == "Spectators" or team == "Spectator"
end

-- ============================================================
-- CREATE GUI
-- ============================================================
local function createPredGui()
    if PredGui then return end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end

    PredGui = Instance.new("ScreenGui")
    PredGui.Name = "VD_KillerPrediction"
    PredGui.ResetOnSpawn = false
    PredGui.IgnoreGuiInset = true
    PredGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    PredGui.Parent = pg

    PredLabel = Instance.new("TextLabel", PredGui)
    PredLabel.Name = "NextKillerDisplay"
    PredLabel.Size = UDim2.new(0, 200, 0, 60)
    PredLabel.Position = UDim2.new(0.5, 0, 0, 25)
    PredLabel.AnchorPoint = Vector2.new(0.5, 0)
    PredLabel.BackgroundTransparency = 0.15
    PredLabel.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    PredLabel.BorderSizePixel = 0
    PredLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    PredLabel.Font = Enum.Font.GothamBold
    PredLabel.TextSize = 12
    PredLabel.TextWrapped = true
    PredLabel.TextXAlignment = Enum.TextXAlignment.Center
    PredLabel.TextYAlignment = Enum.TextYAlignment.Center
    PredLabel.RichText = true
    PredLabel.Text = "<b>KILLER PREDICTION</b>\nWaiting..."
    Instance.new("UICorner", PredLabel).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", PredLabel)
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.6
end

local function destroyPredGui()
    if PredGui then PredGui:Destroy(); PredGui = nil; PredLabel = nil end
end

-- ============================================================
-- UPDATE DISPLAY
-- ============================================================
local function updateDisplay()
    if not Config.Enabled then return end
    if not isSpectator() then
        -- Bukan spectator, sembunyikan label
        if PredLabel then PredLabel.Visible = false end
        return
    end

    if not PredGui then createPredGui() end
    if PredLabel then PredLabel.Visible = true end

    -- Sort player berdasarkan AllowKiller + KillerChance
    local players = Players:GetPlayers()
    table.sort(players, function(a, b)
        local aAllow  = GetGameValue(a, "AllowKiller")  or false
        local bAllow  = GetGameValue(b, "AllowKiller")  or false
        if aAllow ~= bAllow then return aAllow == true end
        local aChance = GetGameValue(a, "KillerChance") or 0
        local bChance = GetGameValue(b, "KillerChance") or 0
        return aChance > bChance
    end)

    local predicted = players[1]
    if PredLabel then
        if predicted and predicted ~= LocalPlayer then
            local killerType = GetGameValue(predicted, "SelectedKiller")
                or GetGameValue(predicted, "KillerType")
                or "Unknown"
            PredLabel.Text = '<font size="14"><b>KILLER PREDICTION</b></font>\n'
                .. '<font color="rgb(160,160,160)" size="12">' .. predicted.Name .. '</font>\n'
                .. '<font color="rgb(255,200,100)" size="11">Killer: ' .. tostring(killerType) .. '</font>'
        else
            PredLabel.Text = '<font size="14"><b>KILLER PREDICTION</b></font>\n'
                .. '<font color="rgb(160,160,160)" size="12">No player found</font>'
        end
    end
end

-- ============================================================
-- ENABLE / DISABLE
-- ============================================================
local _running = false

local function Enable()
    Config.Enabled = true
    _running = true
    createPredGui()
    task.spawn(function()
        while _running and Config.Enabled do
            pcall(updateDisplay)
            task.wait(Config.Interval)
        end
    end)
end

local function Disable()
    Config.Enabled = false
    _running = false
    destroyPredGui()
end

-- Cleanup saat bukan spectator lagi
Players:GetPropertyChangedSignal("LocalPlayer"):Connect(function()
    if not isSpectator() and PredLabel then
        PredLabel.Visible = false
    end
end)

    -- Expose API
    return {
        Config = Config,
        PredGui = PredGui,
        PredLabel = PredLabel,
        createPredGui = createPredGui,
        destroyPredGui = destroyPredGui,
        updateDisplay = updateDisplay,
        Enable = Enable,
        Disable = Disable,
    }
end)()


-- ============================================================
-- SAToF (silenttof.lua)
-- ============================================================
local SAToF = (function()
-- ============================================================
-- SILENT AIM TOF (Twist of Fate)
-- Violent District - Delta Executor
-- Source: silent oxio pistol.txt
-- ============================================================

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local UserInputService    = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    Enabled        = false,
    BlockKnocked   = false,  -- blokir aim saat knocked/hooked
    LockAim        = false,  -- lock kamera ke target saat hold RMB
    FOVMode        = false,  -- gunakan FOV circle untuk filter target
    ShowFOV        = false,  -- tampilkan FOV circle
    FOV            = 150,    -- radius FOV
    Target         = "Killer", -- "Killer" | "Survivor" | "SCP"
    TargetPart     = "Torso",  -- "Head" | "Torso" | "Root"
    HideLaser      = false,  -- sembunyikan laser merah
}

-- ============================================================
-- STATE
-- ============================================================
local isCharging          = false
local lockedTarget        = nil
local currentTouchInput   = nil
local pistolLaser         = nil

-- ============================================================
-- HELPERS
-- ============================================================
local function IsDowned(char)
    if not char then return false end
    return char:GetAttribute("Knocked") == true
        or char:GetAttribute("IsHooked") == true
        or char:GetAttribute("IsCarried") == true
end

local function IsKiller(p)
    return p and p.Team and p.Team.Name:lower():find("killer") ~= nil
end

local function getTargetPart(char)
    if Config.TargetPart == "Head" then
        return char:FindFirstChild("Head")
    elseif Config.TargetPart == "Root" or Config.TargetPart == "HumanoidRootPart" then
        return char:FindFirstChild("HumanoidRootPart")
    else
        return char:FindFirstChild("Torso")
            or char:FindFirstChild("UpperTorso")
            or char:FindFirstChild("HumanoidRootPart")
    end
end

-- ============================================================
-- CARI TARGET TERDEKAT
-- ============================================================
local function getPistolTarget()
    local closestDist = (Config.ShowFOV and Config.FOVMode) and Config.FOV or math.huge
    local bestTarget  = nil
    local myChar      = LocalPlayer.Character
    local myHRP       = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    if Config.BlockKnocked and IsDowned(myChar) then return nil end

    local mouseLoc = UserInputService:GetMouseLocation()

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local valid = (Config.Target == "Killer"   and IsKiller(p))
                       or (Config.Target == "Survivor" and not IsKiller(p))
            if valid then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and not IsDowned(p.Character) then
                    local part = getTargetPart(p.Character)
                    if part then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen or not Config.FOVMode then
                            local dist = Config.FOVMode
                                and (Vector2.new(screenPos.X, screenPos.Y) - mouseLoc).Magnitude
                                or (part.Position - myHRP.Position).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                bestTarget  = part
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

-- ============================================================
-- CARI TOF REMOTE (cached)
-- ============================================================
local _tofRemote = nil
local function getToFRemote()
    if _tofRemote and _tofRemote.Parent then return _tofRemote end
    pcall(function()
        local r     = ReplicatedStorage:FindFirstChild("Remotes")
        local items = r and r:FindFirstChild("Items")
        local tof   = items and items:FindFirstChild("Twist of Fate")
        _tofRemote  = tof and tof:FindFirstChild("Fire")
    end)
    return _tofRemote
end

-- ============================================================
-- EXECUTE SILENT AIM FIRE
-- ============================================================
local function executeSilentAimFire()
    local targetPart = getPistolTarget()
    local myChar     = LocalPlayer.Character
    if Config.BlockKnocked and IsDowned(myChar) then return end
    if not targetPart or not myChar then return end

    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    -- Cari ToF di Character atau Backpack
    local tof = myChar:FindFirstChild("Twist of Fate")
    if not tof then
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        tof = bp and bp:FindFirstChild("Twist of Fate")
    end
    if not tof then return end

    -- Cari weapon arg (gun/arm)
    local weaponArg = tof
    local rightArm  = tof:FindFirstChild("Right Arm")
    if rightArm then
        weaponArg = rightArm:FindFirstChild("EmperorGun")
            or rightArm:FindFirstChild("gun")
            or rightArm
    end

    -- Bullet prediction (bulletSpeed 400)
    local startPos   = myHRP.Position
    local targetPos  = targetPart.Position
    local vel        = Vector3.new(0,0,0)
    pcall(function() vel = targetPart.AssemblyLinearVelocity end)
    vel = Vector3.new(vel.X, 0, vel.Z)
    local distance   = (targetPos - startPos).Magnitude
    local timeToHit  = distance / 400
    local predicted  = targetPos + (vel * timeToHit)
    local aimDir     = ((predicted + Vector3.new(0,-2,0)) - startPos).Unit

    -- Fire remote
    local remote = getToFRemote()
    if remote then
        pcall(function() remote:FireServer(weaponArg, aimDir) end)
    end
end

-- ============================================================
-- PISTOL LASER VISUAL
-- ============================================================
local function createLaser()
    if pistolLaser then return end
    pistolLaser = Instance.new("Part")
    pistolLaser.Name = "VD_PistolLaser"
    pistolLaser.Material = Enum.Material.Neon
    pistolLaser.Color = Color3.fromRGB(255, 0, 0)
    pistolLaser.CanCollide = false
    pistolLaser.Anchored   = true
    pistolLaser.CastShadow = false
    pistolLaser.Size = Vector3.new(0.05, 0.05, 1)
    pistolLaser.Transparency = 0
end
createLaser()

-- ============================================================
-- FOV CIRCLE DRAWING
-- ============================================================
local FOVCircle = nil
pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Filled      = false
    FOVCircle.Color       = Color3.fromRGB(0, 255, 100)
    FOVCircle.Thickness   = 1.5
    FOVCircle.Visible     = false
    FOVCircle.NumSides    = 64
end)

-- ============================================================
-- INPUT HANDLERS
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gp)
    local isTouch = input.UserInputType == Enum.UserInputType.Touch
    if gp and not isTouch then return end
    if not Config.Enabled then return end

    -- RMB: mulai charging
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isCharging   = true
        lockedTarget = getPistolTarget()
    end

    -- LMB: fire saat charging
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if isCharging then executeSilentAimFire() end
    end

    -- Touch: cek area Gui-mob
    if isTouch then
        local pg  = LocalPlayer:FindFirstChild("PlayerGui")
        local mob = pg and pg:FindFirstChild("Survivor-mob")
        local ctrl = mob and mob:FindFirstChild("Controls")
        local btn  = ctrl and ctrl:FindFirstChild("Gui-mob")
        if btn and btn.Visible then
            local pos = input.Position
            local abs = btn.AbsolutePosition
            local sz  = btn.AbsoluteSize
            if pos.X >= abs.X and pos.X <= abs.X+sz.X
            and pos.Y >= abs.Y and pos.Y <= abs.Y+sz.Y then
                isCharging        = true
                currentTouchInput = input
                lockedTarget      = getPistolTarget()
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not Config.Enabled then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isCharging   = false
        lockedTarget = nil
    end
    if input.UserInputType == Enum.UserInputType.Touch
    and input == currentTouchInput then
        if isCharging then executeSilentAimFire() end
        isCharging        = false
        currentTouchInput = nil
        lockedTarget      = nil
    end
end)

-- ============================================================
-- RENDER LOOP (Lock Aim + Laser + FOV Circle)
-- ============================================================
RunService.RenderStepped:Connect(function()
    if not Config.Enabled then
        if pistolLaser and pistolLaser.Parent then pistolLaser.Parent = nil end
        if FOVCircle then FOVCircle.Visible = false end
        return
    end

    -- Lock Aim
    if isCharging and Config.LockAim then
        lockedTarget = lockedTarget or getPistolTarget()
        if lockedTarget and lockedTarget.Parent then
            local hum = lockedTarget.Parent:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                Camera.CFrame = Camera.CFrame:Lerp(
                    CFrame.lookAt(Camera.CFrame.Position, lockedTarget.Position),
                    0.15
                )
            end
        end
    end

    -- Pistol Laser
    if isCharging and pistolLaser then
        local tp = getPistolTarget()
        if tp then
            local myChar = LocalPlayer.Character
            local leftArm = myChar and (myChar:FindFirstChild("Left Arm") or myChar:FindFirstChild("LeftHand"))
            local startPos = leftArm and leftArm.Position or (myChar and myChar:GetPivot().Position or Vector3.new())
            local vel = Vector3.new(0,0,0)
            pcall(function() vel = tp.AssemblyLinearVelocity end)
            vel = Vector3.new(vel.X, 0, vel.Z)
            local d = (tp.Position - startPos).Magnitude
            local predicted = tp.Position + (vel * (d/400))
            local endPos    = predicted + Vector3.new(0,-1.2,0)
            local nd = (endPos - startPos).Magnitude
            if nd > 0 then
                pistolLaser.Parent       = workspace
                pistolLaser.Transparency = Config.HideLaser and 1 or 0
                pistolLaser.Size         = Vector3.new(0.05, 0.05, nd)
                pistolLaser.CFrame       = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -nd/2)
            end
        else
            if pistolLaser and pistolLaser.Parent then pistolLaser.Parent = nil end
        end
    else
        if pistolLaser and pistolLaser.Parent then pistolLaser.Parent = nil end
    end

    -- FOV Circle
    if FOVCircle then
        if Config.ShowFOV and Config.FOVMode then
            local target = getPistolTarget()
            FOVCircle.Visible   = true
            FOVCircle.Radius    = Config.FOV
            FOVCircle.Position  = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            FOVCircle.Color     = target and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,100)
        else
            FOVCircle.Visible = false
        end
    end
end)

-- Return module
    -- Expose API
    return {
        Config = Config,
        isCharging = isCharging,
        lockedTarget = lockedTarget,
        pistolLaser = pistolLaser,
        FOVCircle = FOVCircle,
        getPistolTarget = getPistolTarget,
        executeSilentAimFire = executeSilentAimFire,
        createLaser = createLaser,
    }
end)()


-- ============================================================
-- Spear (spearaim.lua)
-- ============================================================
local Spear = (function()
-- ============================================================
-- SILENT AIM SPEAR (Killer)
-- Violent District - Delta Executor
-- Source: W424final.txt
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    Enabled = false,
    Gravity = 50,   -- gravitasi spear (kompensasi drop)
    Speed   = 100,  -- kecepatan spear
    FOV     = 250,  -- radius FOV screen (pixel)
    AimPart       = "HumanoidRootPart",  -- bagian tubuh target
    ShowSnapline  = true,   -- tampilkan garis dari center ke target
}

-- State
local _conn    = nil
local _holding = false

-- Snapline Drawing
local SnapLine = nil
pcall(function()
    SnapLine = Drawing.new("Line")
    SnapLine.Visible   = false
    SnapLine.Color     = Color3.fromRGB(255, 80, 80)
    SnapLine.Thickness = 1.5
    SnapLine.Transparency = 0.2
end)

-- ============================================================
-- HELPERS
-- ============================================================
local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function IsKiller(p)
    return p and p.Team and p.Team.Name:lower():find("killer") ~= nil
end

-- ============================================================
-- HITUNG POSISI AIM DENGAN KOMPENSASI DROP GRAVITASI
-- ============================================================
local function SpearAimbotCalc(targetPos)
    local root = getRoot()
    if not root then return nil end
    local startPos = root.Position + Vector3.new(0, 2, 0)
    local distance = (targetPos - startPos).Magnitude
    local t        = distance / Config.Speed
    local drop     = 0.5 * Config.Gravity * t * t
    return targetPos + Vector3.new(0, drop, 0)
end

-- ============================================================
-- CARI TARGET SURVIVOR TERDEKAT DI FOV
-- ============================================================
local function getClosestSpearTarget()
    local center   = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local closest  = nil
    local shortest = Config.FOV

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            -- Target = Survivor (bukan killer)
            if not IsKiller(p) then
                local hrp = p.Character:FindFirstChild(Config.AimPart)
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local screenPos, visible = Camera:WorldToViewportPoint(hrp.Position)
                    if visible then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist < shortest then
                            shortest = dist
                            closest  = hrp
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- ============================================================
-- INPUT HANDLERS (Hold RMB untuk aktifkan aim)
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not Config.Enabled then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        _holding = true
    end
    -- Mobile: cari attack button killer
    if input.UserInputType == Enum.UserInputType.Touch then
        local pg   = LocalPlayer:FindFirstChild("PlayerGui")
        local mob  = pg and pg:FindFirstChild("Killer-mob")
        local ctrl = mob and mob:FindFirstChild("Controls")
        local btn  = ctrl and ctrl:FindFirstChild("attack")
        if btn and btn.Visible then
            local pos = input.Position
            local abs = btn.AbsolutePosition
            local sz  = btn.AbsoluteSize
            if pos.X >= abs.X and pos.X <= abs.X+sz.X
            and pos.Y >= abs.Y and pos.Y <= abs.Y+sz.Y then
                _holding = true
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2
    or input.UserInputType == Enum.UserInputType.Touch then
        _holding = false
    end
end)

-- ============================================================
-- RENDER LOOP - Lock kamera ke aimPos
-- ============================================================
local function start()
    if _conn then _conn:Disconnect() end
    _conn = RunService.RenderStepped:Connect(function()
        if not Config.Enabled or not _holding then
            if SnapLine then SnapLine.Visible = false end
            return
        end

        local target = getClosestSpearTarget()
        if not target then return end

        local aimPos = SpearAimbotCalc(target.Position)
        if not aimPos then return end

        Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPos)

        -- Snapline: center screen  posisi target di screen
        if SnapLine then
            local screenPos, visible = Camera:WorldToViewportPoint(target.Position)
            if visible then
                SnapLine.Visible = Config.ShowSnapline
                SnapLine.From    = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                SnapLine.To      = Vector2.new(screenPos.X, screenPos.Y)
            else
                SnapLine.Visible = false
            end
        end
    end)
end

local function stop()
    if _conn then _conn:Disconnect(); _conn = nil end
    _holding = false
    if SnapLine then SnapLine.Visible = false end
end

-- Auto start saat enabled
start()

-- Return module
    -- Expose API
    return {
        Config = Config,
        SnapLine = SnapLine,
        SpearAimbotCalc = SpearAimbotCalc,
        getClosestSpearTarget = getClosestSpearTarget,
        Start = Start,
        Stop = Stop,
    }
end)()


-- ============================================================
-- Mask (maskedselection.lua)
-- ============================================================
local Mask = (function()
-- ============================================================
-- MASK SELECTION (The Masked Killer)
-- Violent District - Delta Executor
-- Source: SourceKu.lua.txt
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local CoreGui     = game:GetService("CoreGui")

-- ============================================================
-- MASK DATA (Swan/Panther/Cobra/Rabbit/Rat/Tiger)
-- ============================================================
local MASK_DATA = {
    { arg="Alex",    label="Swan",    image="rbxassetid://15946083863",     key=Enum.KeyCode.One },
    { arg="Brandon", label="Panther", image="rbxassetid://111928367372122", key=Enum.KeyCode.Two },
    { arg="Cobra",   label="Cobra",   image="rbxassetid://15946288579",     key=Enum.KeyCode.Three },
    { arg="Rabbit",  label="Rabbit",  image="rbxassetid://103750154338014", key=Enum.KeyCode.Four },
    { arg="Richter", label="Rat",     image="rbxassetid://590245826",       key=Enum.KeyCode.Five },
    { arg="Tony",    label="Tiger",   image="rbxassetid://96793004678696",  key=Enum.KeyCode.Six },
}
local MASK_DEFAULT_ARG = "Richard"

-- State
local MaskGui       = nil
local MaskKeyConn   = nil
local MaskIsOpen    = true
local MaskMinBtn    = nil
local MaskBodyFrame = nil

-- ============================================================
-- FIRE MASK REMOTE
-- ============================================================
local function FireMask(argName)
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes", 5)
            :WaitForChild("Killers", 5)
            :WaitForChild("Masked", 5)
            :WaitForChild("Activatepower", 5)
            :FireServer(argName)
    end)
end

-- ============================================================
-- CEK APAKAH PLAYER MAIN THE MASKED
-- ============================================================
local function CheckIsMasked()
    local sk = LocalPlayer:GetAttribute("SelectedKiller")
    if sk == nil then
        local v = LocalPlayer:FindFirstChild("SelectedKiller")
        if v then sk = v.Value end
    end
    if sk == nil then return false end
    return tostring(sk):lower():find("masked") ~= nil
end

-- ============================================================
-- UI SCALE
-- ============================================================
local function GetScale()
    local cam = workspace.CurrentCamera
    local vp  = cam and cam.ViewportSize or Vector2.new(1280, 720)
    return math.clamp(math.min(vp.X, vp.Y) / 720, 0.7, 1.25)
end

-- ============================================================
-- TOGGLE POPUP
-- ============================================================
local function setMaskPopupState(open)
    MaskIsOpen = open
    if MaskBodyFrame then MaskBodyFrame.Visible = open end
    if MaskMinBtn    then MaskMinBtn.Text = open and "-" or "+" end
end
local function toggleMaskPopup() setMaskPopupState(not MaskIsOpen) end

-- ============================================================
-- BUILD GUI
-- ============================================================
local function BuildMaskGui()
    if MaskGui and MaskGui.Parent then MaskGui:Destroy() end

    local scale    = GetScale()
    local PANEL_W  = math.floor(230 * scale)
    local HEADER_H = math.floor(34  * scale)
    local CARD_SIZE= math.floor(62  * scale)
    local CARD_GAP = math.floor(6   * scale)
    local PAD      = math.floor(8   * scale)
    local BTN_H    = math.floor(28  * scale)

    local sg = Instance.new("ScreenGui")
    sg.Name = "MaskSelectionGUI"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 60
    sg.Parent = (gethui and gethui()) or CoreGui

    local root = Instance.new("Frame", sg)
    root.Size = UDim2.new(0,PANEL_W,0,HEADER_H)
    root.Position = UDim2.new(0.5,-PANEL_W/2,0.16,0)
    root.BackgroundTransparency = 1

    -- Header
    local hdr = Instance.new("Frame", root)
    hdr.Size = UDim2.new(1,0,0,HEADER_H)
    hdr.BackgroundColor3 = Color3.fromRGB(22,22,28)
    hdr.BorderSizePixel = 0; hdr.ZIndex = 5
    Instance.new("UICorner",hdr).CornerRadius = UDim.new(0,8)
    local hs = Instance.new("UIStroke",hdr)
    hs.Color = Color3.fromRGB(255,153,204); hs.Thickness=1; hs.Transparency=0.45

    local tLbl = Instance.new("TextLabel",hdr)
    tLbl.Size = UDim2.new(1,-HEADER_H-PAD,1,0)
    tLbl.Position = UDim2.new(0,PAD,0,0)
    tLbl.BackgroundTransparency = 1; tLbl.Text = "MASK SELECTION"
    tLbl.TextColor3 = Color3.fromRGB(255,153,204); tLbl.Font = Enum.Font.GothamBold
    tLbl.TextSize = math.floor(13*scale); tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.ZIndex = 6

    local minBtn = Instance.new("TextButton",hdr)
    minBtn.Size = UDim2.new(0,HEADER_H-8,0,HEADER_H-8)
    minBtn.Position = UDim2.new(1,-(HEADER_H-4),0.5,-(HEADER_H-8)/2)
    minBtn.BackgroundColor3 = Color3.fromRGB(255,153,204)
    minBtn.AutoButtonColor = false; minBtn.Text = "-"
    minBtn.TextColor3 = Color3.fromRGB(22,22,28)
    minBtn.Font = Enum.Font.GothamBold; minBtn.TextSize = math.floor(16*scale)
    minBtn.BorderSizePixel = 0; minBtn.ZIndex = 7
    Instance.new("UICorner",minBtn).CornerRadius = UDim.new(0,6)
    MaskMinBtn = minBtn

    -- Body
    local body = Instance.new("Frame",root)
    body.Size = UDim2.new(1,0,0,0)
    body.Position = UDim2.new(0,0,0,HEADER_H+PAD*0.5)
    body.BackgroundColor3 = Color3.fromRGB(18,18,24)
    body.BorderSizePixel = 0; body.ZIndex = 5
    Instance.new("UICorner",body).CornerRadius = UDim.new(0,8)
    local bs = Instance.new("UIStroke",body)
    bs.Color = Color3.fromRGB(255,153,204); bs.Thickness=1; bs.Transparency=0.55
    MaskBodyFrame = body

    local bp = Instance.new("UIPadding",body)
    bp.PaddingTop=UDim.new(0,PAD); bp.PaddingBottom=UDim.new(0,PAD)
    bp.PaddingLeft=UDim.new(0,PAD); bp.PaddingRight=UDim.new(0,PAD)
    local bLayout = Instance.new("UIListLayout",body)
    bLayout.Padding = UDim.new(0,math.floor(PAD*0.6))
    bLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local statusLbl = Instance.new("TextLabel",body)
    statusLbl.LayoutOrder=1; statusLbl.Size=UDim2.new(1,0,0,math.floor(16*scale))
    statusLbl.BackgroundTransparency=1; statusLbl.Text="Active Mask: None"
    statusLbl.TextColor3=Color3.fromRGB(90,240,140); statusLbl.Font=Enum.Font.GothamBold
    statusLbl.TextSize=math.floor(11*scale); statusLbl.TextXAlignment=Enum.TextXAlignment.Left
    statusLbl.ZIndex=6

    -- Grid cards
    local gc = Instance.new("Frame",body)
    gc.LayoutOrder=2; gc.Size=UDim2.new(1,0,0,(CARD_SIZE*2)+CARD_GAP)
    gc.BackgroundTransparency=1; gc.ZIndex=6
    local grid = Instance.new("UIGridLayout",gc)
    grid.CellSize=UDim2.new(0,CARD_SIZE,0,CARD_SIZE)
    grid.CellPadding=UDim2.new(0,CARD_GAP,0,CARD_GAP)
    grid.FillDirection=Enum.FillDirection.Horizontal
    grid.FillDirectionMaxCells=3
    grid.HorizontalAlignment=Enum.HorizontalAlignment.Center
    grid.SortOrder=Enum.SortOrder.LayoutOrder

    local cards = {}
    local function resetStrokes()
        for _,d in pairs(cards) do
            d.Stroke.Color=Color3.fromRGB(55,55,65); d.Stroke.Transparency=0.3
        end
    end

    for i, mask in ipairs(MASK_DATA) do
        local card = Instance.new("ImageButton",gc)
        card.LayoutOrder=i; card.Size=UDim2.new(0,CARD_SIZE,0,CARD_SIZE)
        card.BackgroundColor3=Color3.fromRGB(30,30,38)
        card.AutoButtonColor=false; card.BorderSizePixel=0
        card.Image=mask.image; card.ScaleType=Enum.ScaleType.Fit; card.ZIndex=7
        Instance.new("UICorner",card).CornerRadius=UDim.new(0,8)
        local cs=Instance.new("UIStroke",card)
        cs.Color=Color3.fromRGB(55,55,65); cs.Thickness=1.5
        cs.Transparency=0.3; cs.ApplyStrokeMode=Enum.ApplyStrokeMode.Border

        local nb=Instance.new("TextLabel",card)
        nb.Size=UDim2.new(0,math.floor(16*scale),0,math.floor(16*scale))
        nb.Position=UDim2.new(0,3,0,3)
        nb.BackgroundColor3=Color3.fromRGB(0,0,0); nb.BackgroundTransparency=0.35
        nb.Text=tostring(i); nb.TextColor3=Color3.fromRGB(255,255,255)
        nb.Font=Enum.Font.GothamBold; nb.TextSize=math.floor(10*scale)
        nb.BorderSizePixel=0; nb.ZIndex=8
        Instance.new("UICorner",nb).CornerRadius=UDim.new(0,4)

        local nl=Instance.new("TextLabel",card)
        nl.Size=UDim2.new(1,0,0,math.floor(16*scale))
        nl.Position=UDim2.new(0,0,1,-math.floor(16*scale))
        nl.BackgroundColor3=Color3.fromRGB(0,0,0); nl.BackgroundTransparency=0.3
        nl.Text=mask.label; nl.TextColor3=Color3.fromRGB(235,235,240)
        nl.Font=Enum.Font.GothamBold; nl.TextSize=math.floor(9*scale)
        nl.BorderSizePixel=0; nl.ZIndex=8
        Instance.new("UICorner",nl).CornerRadius=UDim.new(0,5)

        local function activate()
            FireMask(mask.arg)
            statusLbl.Text = "Active: " .. mask.label
            resetStrokes()
            cs.Color=Color3.fromRGB(255,153,204); cs.Transparency=0
        end
        card.MouseButton1Click:Connect(activate)
        cards[mask.label]={Stroke=cs}; mask._activate=activate
    end

    -- Deactivate button
    local deactBtn=Instance.new("TextButton",body)
    deactBtn.LayoutOrder=3; deactBtn.Size=UDim2.new(1,0,0,BTN_H)
    deactBtn.BackgroundColor3=Color3.fromRGB(178,42,58); deactBtn.Text="[7] Deactivate"
    deactBtn.TextColor3=Color3.fromRGB(255,255,255); deactBtn.Font=Enum.Font.GothamBold
    deactBtn.TextSize=math.floor(12*scale); deactBtn.BorderSizePixel=0; deactBtn.ZIndex=6
    Instance.new("UICorner",deactBtn).CornerRadius=UDim.new(0,6)
    local function deactivate()
        FireMask(MASK_DEFAULT_ARG); statusLbl.Text="Active: None"; resetStrokes()
    end
    deactBtn.MouseButton1Click:Connect(deactivate)

    -- Auto resize body
    bLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        body.Size=UDim2.new(1,0,0,bLayout.AbsoluteContentSize.Y+PAD*2)
    end)

    -- Drag
    local drag,ds,sp,mv=false,nil,nil,false
    hdr.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true;mv=false
            ds=Vector2.new(inp.Position.X,inp.Position.Y); sp=root.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=Vector2.new(inp.Position.X,inp.Position.Y)-ds
            if d.Magnitude>4 then mv=true end
            local vs=sg.AbsoluteSize; if vs.X<=0 or vs.Y<=0 then return end
            root.Position=UDim2.new(
                math.clamp(sp.X.Scale+d.X/vs.X,-0.15,1.05),sp.X.Offset,
                math.clamp(sp.Y.Scale+d.Y/vs.Y,0,0.92),sp.Y.Offset)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if (inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch) and drag then
            local wc=not mv; drag=false
            if wc then toggleMaskPopup() end
        end
    end)

    -- Keybind: 1-6 = mask, 7 = deactivate, M = minimize
    local kc=UserInputService.InputBegan:Connect(function(inp,gp)
        if gp or not sg.Parent then return end
        if UserInputService:GetFocusedTextBox() then return end
        for _,m in ipairs(MASK_DATA) do
            if inp.KeyCode==m.key then m._activate(); return end
        end
        if inp.KeyCode==Enum.KeyCode.Seven then deactivate() end
        if inp.KeyCode==Enum.KeyCode.M then toggleMaskPopup() end
    end)
    sg.AncestryChanged:Connect(function(_,p) if not p and kc then kc:Disconnect() end end)
    MaskGui=sg
    if MaskKeyConn then MaskKeyConn:Disconnect() end
    MaskKeyConn=kc
    setMaskPopupState(true)
end

-- ============================================================
-- PUBLIC API
-- ============================================================
local function Show()
    if not CheckIsMasked() then return false end
    BuildMaskGui(); return true
end

local function Hide()
    if MaskKeyConn then MaskKeyConn:Disconnect(); MaskKeyConn=nil end
    if MaskGui and MaskGui.Parent then MaskGui:Destroy(); MaskGui=nil end
end

    -- Expose API
    return {
        MASK_DATA = MASK_DATA,
        MaskGui = MaskGui,
        MaskKeyConn = MaskKeyConn,
        FireMask = FireMask,
        CheckIsMasked = CheckIsMasked,
        BuildMaskGui = BuildMaskGui,
        Show = Show,
        Hide = Hide,
    }
end)()


-- ============================================================
-- DDmg (doubledmg.lua)
-- ============================================================
local DDmg = (function()
-- ============================================================
-- DOUBLE DAMAGE GENERATOR (Killer)
-- Violent District - Delta Executor
-- Source: lua (4).txt (Quantum Hub)
-- ============================================================

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- Config
local Config = {
    Enabled = false,
    Repeat  = 4,    -- berapa kali extra fire
    Delay   = 0.08, -- jeda antar extra fire
}

-- State
local _hooked  = false
local _oldCall = nil

-- ============================================================
-- SETUP HOOKMETAMETHOD
-- ============================================================
local function setupHook()
    if _hooked then return end
    if not (hookmetamethod and getrawmetatable and setreadonly and newcclosure and checkcaller) then
        warn("[DoubleDmg] hookmetamethod tidak tersedia di executor ini")
        return
    end

    pcall(function()
        local mt  = getrawmetatable(game)
        local old = mt.__namecall
        _oldCall  = old
        setreadonly(mt, false)

        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args   = {...}

            if not checkcaller()
            and method == "FireServer"
            and Config.Enabled then
                local n = tostring(self):lower()

                -- Deteksi BreakGenEvent (generator kick)
                if n:find("breakgenevent") then
                    -- Pastikan player adalah killer
                    local team = LocalPlayer.Team
                    if team and team.Name:lower():find("killer") then
                        local saved = table.clone(args)
                        local result = old(self, table.unpack(saved))
                        -- Fire extra N kali dengan delay
                        task.spawn(function()
                            for _ = 1, Config.Repeat do
                                task.wait(Config.Delay)
                                pcall(function() old(self, table.unpack(saved)) end)
                            end
                        end)
                        return result
                    end
                end
            end

            return old(self, ...)
        end)

        setreadonly(mt, true)
        _hooked = true
        print("[DoubleDmg] Hook aktif")
    end)
end

-- Setup saat module di-load
setupHook()

-- Return module
    -- Expose API
    return {
        Config = Config,
        _hooked = _hooked,
        setupHook = setupHook,
    }
end)()


-- ============================================================
-- Stalk (autostalk.lua)
-- ============================================================
local Stalk = (function()
-- ============================================================
-- AUTO STALK (Myers Killer)
-- Violent District - Delta Executor
-- Source: W424final.txt
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Config
local Config = {
    Enabled    = false,
    StalkRange = 150,  -- jarak max stalk (studs)
}

-- State
local _conn = nil

-- ============================================================
-- HELPERS
-- ============================================================
local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- CARI SURVIVOR TERDEKAT DALAM RANGE
-- ============================================================
local function getClosestSurvivor()
    local root = getRoot()
    if not root then return nil end
    local closest, shortest = nil, math.huge

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            -- Health > 30 agar tidak stalk yang sudah mau mati
            if hum and hrp and hum.Health > 30 then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist <= Config.StalkRange and dist < shortest then
                    shortest = dist
                    closest  = p
                end
            end
        end
    end
    return closest
end

-- ============================================================
-- STALK REMOTE (lazy load)
-- ============================================================
local _stalkRemote = nil
local function getStalkRemote()
    if _stalkRemote and _stalkRemote.Parent then return _stalkRemote end
    pcall(function()
        local r = ReplicatedStorage:FindFirstChild("Remotes")
        local k = r and r:FindFirstChild("Killers")
        local s = k and k:FindFirstChild("Stalker")
        _stalkRemote = s and s:FindFirstChild("StartStalking")
    end)
    return _stalkRemote
end

-- ============================================================
-- START / STOP
-- ============================================================
local function Start()
    if _conn then return end
    Config.Enabled = true
    _conn = RunService.Heartbeat:Connect(function()
        if not Config.Enabled then return end
        local target = getClosestSurvivor()
        if not target or not target.Character then return end
        local remote = getStalkRemote()
        if remote then
            pcall(function() remote:FireServer(target) end)
        end
    end)
end

local function Stop()
    Config.Enabled = false
    if _conn then _conn:Disconnect(); _conn = nil end
    _stalkRemote = nil
end

    -- Expose API
    return {
        Config = Config,
        getClosestSurvivor = getClosestSurvivor,
        getStalkRemote = getStalkRemote,
        Start = Start,
        Stop = Stop,
    }
end)()


-- ============================================================
-- Hitbox (hitboxexpander.lua)
-- ============================================================
local Hitbox = (function()
-- ============================================================
-- HITBOX EXPANDER (Killer)
-- Violent District - Delta Executor
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Config
local Config = {
    Enabled = false,
    Size    = 15,  -- ukuran hitbox (studs)
}

-- State
local _conn         = nil
local _origSizes    = {}  -- simpan ukuran asli HRP

-- ============================================================
-- RESTORE semua HRP ke ukuran asli
-- ============================================================
local function restoreAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp and _origSizes[hrp] then
                pcall(function()
                    hrp.Size        = _origSizes[hrp]
                    hrp.Transparency = 1
                    hrp.Material    = Enum.Material.Plastic
                    hrp.CanCollide  = false
                end)
                _origSizes[hrp] = nil
            end
        end
    end
end

-- ============================================================
-- START / STOP
-- ============================================================
local function Start()
    if _conn then return end
    Config.Enabled = true

    _conn = RunService.Heartbeat:Connect(function()
        if not Config.Enabled then return end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    -- Simpan ukuran asli sekali
                    if not _origSizes[hrp] then
                        _origSizes[hrp] = hrp.Size
                    end
                    local target = Vector3.new(Config.Size, Config.Size, Config.Size)
                    if hrp.Size ~= target then
                        pcall(function()
                            hrp.Size         = target
                            hrp.Transparency = 0.9
                            hrp.Material     = Enum.Material.ForceField
                            hrp.Color        = Color3.fromRGB(255, 0, 0)
                            hrp.Massless     = false
                            hrp.CanCollide   = false
                        end)
                    end
                end
            end
        end
    end)
end

local function Stop()
    Config.Enabled = false
    if _conn then _conn:Disconnect(); _conn = nil end
    restoreAll()
end

-- Cleanup saat player lain keluar
Players.PlayerRemoving:Connect(function(p)
    if p.Character then
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then _origSizes[hrp] = nil end
    end
end)

    -- Expose API
    return {
        Config = Config,
        _origSizes = _origSizes,
        restoreAll = restoreAll,
        Start = Start,
        Stop = Stop,
    }
end)()


-- ============================================================
-- ESP (esp.lua)
-- ============================================================
local ESP = (function()
-- ============================================================
-- ESP (Violent District)
-- Simple highlight only, no text spam
-- Generator: highlight + progress %
-- Gate: highlight + countdown timer
-- Window/Pallet: highlight only, no text
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Config
local Config = {
    Enabled   = false,
    Survivor  = true,
    Killer    = true,
    Generator = true,
    Gate      = true,
    Pallet    = true,
    Window    = true,
    SCP       = false,
    Distance  = 5000,
}

-- Colors
local COLORS = {
    Survivor  = Color3.fromRGB(0,   240, 255),
    Killer    = Color3.fromRGB(255, 0,   60),
    Generator = Color3.fromRGB(255, 200, 0),
    Gate      = Color3.fromRGB(0,   255, 128),
    Pallet    = Color3.fromRGB(180, 0,   255),
    Window    = Color3.fromRGB(255, 255, 0),
    SCP       = Color3.fromRGB(255, 140, 0),
}

-- Map cache
local _mapCache     = { Generators={}, Pallets={}, Gates={} }
local _mapCacheTime = 0

-- Gate tracking (progress rate)
local _gateData = {}  -- [gate] = { prev=0, prevTime=0, rate=0 }

-- Highlight pool
local _highlights = {}
local _billboards = {}
local _updateConn = nil

-- ============================================================
-- MAP CACHE
-- ============================================================
local function refreshMapCache()
    local now = workspace.DistributedGameTime
    if now - _mapCacheTime < 5 then return end
    _mapCacheTime = now
    _mapCache = { Generators={}, Pallets={}, Gates={} }
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    for _, obj in ipairs(map:GetDescendants()) do
        local n = obj.Name
        if n == "Generator" and obj:IsA("Model") then
            table.insert(_mapCache.Generators, obj)
        elseif (n == "Gate") and obj:IsA("Model") then
            table.insert(_mapCache.Gates, obj)
        elseif (n == "Pallet" or n == "Palletwrong") and obj:IsA("Model") then
            table.insert(_mapCache.Pallets, obj)
        end
    end
end

-- ============================================================
-- HELPERS
-- ============================================================
local function IsKiller(p)
    return p and p.Team and p.Team.Name:lower():find("killer") ~= nil
end

local function isSCP(obj)
    if not obj or not obj:IsA("Model") then return false end
    if not obj:FindFirstChildOfClass("Humanoid") then return false end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == obj then return false end
    end
    local n = obj.Name:lower()
    return n:find("scp") or n:find("zombie") or n:find("monster")
        or n:find("infected") or n:find("entity") ~= nil
end

local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- HIGHLIGHT
-- ============================================================
local function addHighlight(adornee, color)
    if not adornee or not adornee.Parent then return end
    local existing = adornee:FindFirstChild("_VD_ESP")
    if existing then
        existing.FillColor    = color
        existing.OutlineColor = color
        return
    end
    local h = Instance.new("Highlight")
    h.Name              = "_VD_ESP"
    h.FillTransparency  = 0.75
    h.OutlineTransparency = 0.1
    h.FillColor         = color
    h.OutlineColor      = color
    h.Adornee           = adornee
    h.DepthMode         = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent            = adornee
    table.insert(_highlights, h)
end

-- ============================================================
-- BILLBOARD (text label di atas object)
-- ============================================================
local function addBillboard(adornee, text, color, yOffset)
    if not adornee or not adornee.Parent then return end
    local part = adornee:IsA("BasePart") and adornee
        or adornee.PrimaryPart
        or adornee:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end

    local existing = part:FindFirstChild("_VD_BB")
    local lbl
    if existing then
        lbl = existing:FindFirstChild("Label")
        if lbl then lbl.Text = text; lbl.TextColor3 = color end
        return
    end

    local bb = Instance.new("BillboardGui")
    bb.Name         = "_VD_BB"
    bb.AlwaysOnTop  = true
    bb.Size         = UDim2.new(0, 120, 0, 22)
    bb.StudsOffset  = Vector3.new(0, yOffset or 3, 0)
    bb.LightInfluence = 0
    bb.Parent       = part

    lbl = Instance.new("TextLabel", bb)
    lbl.Name                = "Label"
    lbl.Size                = UDim2.fromScale(1, 1)
    lbl.BackgroundColor3    = Color3.fromRGB(10, 10, 10)
    lbl.BackgroundTransparency = 0.35
    lbl.BorderSizePixel     = 0
    lbl.Text                = text
    lbl.TextColor3          = color
    lbl.Font                = Enum.Font.GothamBold
    lbl.TextSize            = 11
    lbl.TextScaled          = false
    lbl.TextWrapped         = false
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4)

    table.insert(_billboards, bb)
end

-- ============================================================
-- CLEAR ESP
-- ============================================================
local function clearESP()
    for _, h in ipairs(_highlights) do pcall(function() h:Destroy() end) end
    for _, b in ipairs(_billboards) do pcall(function() b:Destroy() end) end
    _highlights = {}
    _billboards = {}
end

-- ============================================================
-- GATE TIMER KALKULASI
-- ============================================================
local function getGateText(gate)
    local progress = gate:GetAttribute("GateProgress")
        or gate:GetAttribute("Progress")
        or gate:GetAttribute("OpenProgress")
        or 0

    local now = workspace.DistributedGameTime

    if not _gateData[gate] then
        _gateData[gate] = { prev=progress, prevTime=now, rate=0 }
    end

    local data  = _gateData[gate]
    local dt    = now - data.prevTime

    if dt >= 0.5 then
        local delta = progress - data.prev
        data.rate    = delta / dt
        data.prev    = progress
        data.prevTime = now
    end

    if progress >= 100 then
        return "[OPEN]", COLORS.Gate
    elseif data.rate > 0.1 then
        -- Sedang dibuka - hitung sisa waktu
        local remaining = (100 - progress) / data.rate
        return string.format("[%.0f%% ~%.0fs]", progress, remaining), Color3.fromRGB(255, 200, 0)
    elseif progress > 0 then
        -- Ada progress tapi tidak sedang dibuka
        return string.format("[%.0f%% HOLD]", progress), Color3.fromRGB(255, 150, 0)
    else
        -- Belum dimulai
        return "[READY]", COLORS.Gate
    end
end

-- ============================================================
-- UPDATE ESP
-- ============================================================
local _lastUpdate = 0

local function updateESP()
    local now = workspace.DistributedGameTime
    if now - _lastUpdate < 2 then return end
    _lastUpdate = now

    if not Config.Enabled then clearESP(); return end

    clearESP()
    refreshMapCache()

    local root   = getRoot()
    local maxDist = Config.Distance

    -- Players
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                if not root or (hrp.Position - root.Position).Magnitude <= maxDist then
                    if IsKiller(p) and Config.Killer then
                        addHighlight(p.Character, COLORS.Killer)
                    elseif not IsKiller(p) and Config.Survivor then
                        addHighlight(p.Character, COLORS.Survivor)
                    end
                end
            end
        end
    end

    -- Generators (highlight + progress %)
    if Config.Generator then
        for _, gen in ipairs(_mapCache.Generators) do
            if gen and gen.Parent then
                local part = gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart", true)
                if part and (not root or (part.Position - root.Position).Magnitude <= maxDist) then
                    local prog = gen:GetAttribute("RepairProgress")
                        or gen:GetAttribute("ProgressRepair")
                        or gen:GetAttribute("Progress") or 0
                    if prog < 100 then
                        addHighlight(gen, COLORS.Generator)
                        addBillboard(gen, string.format("[%.0f%%]", prog), COLORS.Generator, 3.5)
                    end
                end
            end
        end
    end

    -- Gates (highlight + timer)
    if Config.Gate then
        for _, gate in ipairs(_mapCache.Gates) do
            if gate and gate.Parent then
                local part = gate.PrimaryPart or gate:FindFirstChildWhichIsA("BasePart", true)
                if part and (not root or (part.Position - root.Position).Magnitude <= maxDist) then
                    local text, color = getGateText(gate)
                    addHighlight(gate, color)
                    addBillboard(gate, text, color, 4)
                end
            end
        end
    end

    -- Pallets (highlight only, no text)
    if Config.Pallet then
        for _, pallet in ipairs(_mapCache.Pallets) do
            if pallet and pallet.Parent then
                local part = pallet.PrimaryPart or pallet:FindFirstChildWhichIsA("BasePart", true)
                if part and (not root or (part.Position - root.Position).Magnitude <= maxDist) then
                    addHighlight(pallet, COLORS.Pallet)
                end
            end
        end
    end

    -- Windows (highlight only, vault windows)
    if Config.Window then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local hasVault = obj:FindFirstChild("VaultPoint")
                    or obj:FindFirstChild("VaultTrigger")
                if hasVault then
                    local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if part and (not root or (part.Position - root.Position).Magnitude <= maxDist) then
                        addHighlight(obj, COLORS.Window)
                    end
                end
            end
        end
    end

    -- SCP
    if Config.SCP then
        for _, obj in ipairs(workspace:GetChildren()) do
            if isSCP(obj) then
                local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if part and (not root or (part.Position - root.Position).Magnitude <= maxDist) then
                    addHighlight(obj, COLORS.SCP)
                end
            end
        end
    end
end

-- ============================================================
-- START / STOP
-- ============================================================
local function Start()
    Config.Enabled = true
    if _updateConn then return end
    _updateConn = RunService.Heartbeat:Connect(function()
        pcall(updateESP)
    end)
end

local function Stop()
    Config.Enabled = false
    if _updateConn then _updateConn:Disconnect(); _updateConn = nil end
    clearESP()
    _gateData = {}
end

    -- Expose API
    return {
        Config = Config,
        COLORS = COLORS,
        _mapCache = _mapCache,
        _gateData = _gateData,
        _highlights = _highlights,
        _billboards = _billboards,
        refreshMapCache = refreshMapCache,
        updateESP = updateESP,
        addHighlight = addHighlight,
        addBillboard = addBillboard,
        clearESP = clearESP,
        getGateText = getGateText,
        Start = Start,
        Stop   = Stop,
        GetLastUpdate = function() return _lastUpdate end,
        SetLastUpdate = function(v) _lastUpdate = v end,
    }
end)()


-- ============================================================
-- Morphs (morphs.lua)
-- ============================================================
local Morphs = (function()
-- ============================================================
-- MORPHS (Visual)
-- Violent District - Delta Executor
-- Source: WisnuVip.txt + kalkulasi Korblox
-- ============================================================

local Players    = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- KORBLOX MORPH
-- Logic: sembunyikan Right Leg asli, pasang skull mesh di bawahnya
-- Kalkulasi ukuran: proportional dari Right Leg size
-- ============================================================
local KorbloxConn = nil

local function ApplyKorblox(char)
    if not char then return end
    -- Tunggu Right Leg ready
    local rightLeg = char:WaitForChild("Right Leg", 5)
    if not rightLeg then return end
    task.wait(0.1)

    pcall(function()
        -- 1. Sembunyikan head
        local head = char:FindFirstChild("Head")
        if head then
            head.Transparency = 1
            local face = head:FindFirstChild("face")
            if face then face:Destroy() end
        end

        -- 2. Sembunyikan Right Leg asli
        rightLeg.Transparency = 1

        -- 3. Kalkulasi ukuran skull berdasarkan Right Leg
        -- Right Leg R6 standard = 1x2x1
        -- Skull harus pas di area kaki bawah
        local legSize  = rightLeg.Size
        local skulkW   = math.max(legSize.X, legSize.Z) * 1.5  -- lebar skull = 1.5x lebar kaki
        local skullSize = Vector3.new(skulkW, skulkW, skulkW)

        -- 4. Buat skull mesh
        local existing = char:FindFirstChild("KorbloxSkull")
        if existing then existing:Destroy() end

        local mesh = Instance.new("MeshPart")
        mesh.Name        = "KorbloxSkull"
        mesh.Size        = skullSize
        mesh.CanCollide  = false
        mesh.Anchored    = false
        mesh.Massless    = true
        mesh.MeshId      = "rbxassetid://902942096"
        mesh.TextureID   = "rbxassetid://902843398"
        -- Posisi: bawah Right Leg (di area kaki)
        mesh.CFrame      = rightLeg.CFrame
            * CFrame.new(0, -legSize.Y/2 + skullSize.Y/2 - 0.1, 0)
        mesh.Parent      = char

        -- 5. Weld ke Right Leg agar ikut bergerak
        local weld = Instance.new("WeldConstraint")
        weld.Part0  = rightLeg
        weld.Part1  = mesh
        weld.Parent = mesh
    end)
end

local function EnableKorblox()
    -- Apply ke character saat ini
    local char = LocalPlayer.Character
    if char then task.spawn(ApplyKorblox, char) end

    -- Re-apply saat respawn
    if KorbloxConn then KorbloxConn:Disconnect() end
    KorbloxConn = LocalPlayer.CharacterAdded:Connect(function(c)
        task.wait(1)
        ApplyKorblox(c)
    end)
end

local function DisableKorblox()
    if KorbloxConn then KorbloxConn:Disconnect(); KorbloxConn = nil end

    -- Restore character
    local char = LocalPlayer.Character
    if not char then return end
    pcall(function()
        -- Hapus skull
        local skull = char:FindFirstChild("KorbloxSkull")
        if skull then skull:Destroy() end

        -- Restore Right Leg
        local rightLeg = char:FindFirstChild("Right Leg")
        if rightLeg then rightLeg.Transparency = 0 end

        -- Restore Head
        local head = char:FindFirstChild("Head")
        if head then head.Transparency = 0 end
    end)
end

-- ============================================================
-- RETURN MODULE
-- ============================================================
    -- Expose API
    return {
        Korblox = Korblox,
    }
end)()


-- ============================================================
-- Visuals (visuals.lua)
-- ============================================================
local Visuals = (function()
-- ============================================================
-- VISUALS (Misc)
-- Violent District - Delta Executor
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting   = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- Simpan nilai original
local _orig = {
    GlobalShadows  = Lighting.GlobalShadows,
    Brightness     = Lighting.Brightness,
    ClockTime      = Lighting.ClockTime,
    Ambient        = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd         = Lighting.FogEnd,
    FogStart       = Lighting.FogStart,
}

-- Config
local Config = {
    NoShadow   = false,
    Fullbright = false,
    ReduceMap  = false,
    ShowCounter = false,
}

-- ============================================================
-- NO SHADOW
-- ============================================================
local function applyNoShadow(v)
    Lighting.GlobalShadows = not v
end

-- ============================================================
-- FULLBRIGHT
-- ============================================================
local function applyFullbright(v)
    if v then
        Lighting.Brightness     = 2
        Lighting.ClockTime      = 14
        Lighting.Ambient        = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.FogEnd         = 100000
        Lighting.FogStart       = 0
    else
        Lighting.Brightness     = _orig.Brightness
        Lighting.ClockTime      = _orig.ClockTime
        Lighting.Ambient        = _orig.Ambient
        Lighting.OutdoorAmbient = _orig.OutdoorAmbient
        Lighting.FogEnd         = _orig.FogEnd
        Lighting.FogStart       = _orig.FogStart
    end
end

-- ============================================================
-- REDUCE MAP (Potato Mode)
-- ============================================================
local function applyReduceMap(v)
    if v then
        -- FPS cap
        pcall(function() setfpscap(30) end)
        -- Rendering quality
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        -- Shadows
        Lighting.GlobalShadows = false
        Lighting.ShadowSoftness = 0
        -- Batch process descendants
        local desc = workspace:GetDescendants()
        task.spawn(function()
            for i, v2 in ipairs(desc) do
                pcall(function()
                    local cls = v2.ClassName
                    if cls == "ParticleEmitter" or cls == "Trail" or cls == "Beam"
                    or cls == "Smoke" or cls == "Fire" or cls == "Sparkles"
                    or cls == "BloomEffect" or cls == "BlurEffect"
                    or cls == "SunRaysEffect" or cls == "ColorCorrectionEffect"
                    or cls == "DepthOfFieldEffect" then
                        if v2.Enabled then v2.Enabled = false end
                    elseif cls == "SurfaceAppearance" then
                        v2:Destroy()
                    elseif v2:IsA("BasePart") then
                        if v2.Material ~= Enum.Material.SmoothPlastic then
                            v2.Material = Enum.Material.SmoothPlastic
                        end
                        if v2.CastShadow then v2.CastShadow = false end
                    end
                end)
                if i % 200 == 0 then task.wait() end
            end
        end)
        -- Lighting effects
        for _, obj in ipairs(Lighting:GetDescendants()) do
            if obj:IsA("Atmosphere") or obj:IsA("Sky") or obj:IsA("Clouds") then
                pcall(function() obj:Destroy() end)
            elseif obj:IsA("PostEffect") then
                pcall(function() obj.Enabled = false end)
            end
        end
        -- Terrain
        pcall(function()
            local t = workspace:FindFirstChildOfClass("Terrain")
            if t then
                t.WaterWaveSize   = 0
                t.WaterWaveSpeed  = 0
                t.WaterReflectance= 0
                t.Decoration      = false
            end
        end)
    else
        pcall(function() setfpscap(0) end)
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        end)
        Lighting.GlobalShadows = _orig.GlobalShadows
    end
end

-- ============================================================
-- FPS & PING COUNTER
-- ============================================================
local _counterGui   = nil
local _fpsLabel     = nil
local _pingLabel    = nil
local _fpsCount     = 0
local _fpsTime      = 0
local _heartbeatConn = nil

local function destroyCounter()
    if _counterGui then _counterGui:Destroy(); _counterGui = nil end
    _fpsLabel = nil; _pingLabel = nil
end

local function createCounter()
    destroyCounter()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end

    _counterGui = Instance.new("ScreenGui")
    _counterGui.Name = "VD_Counter"
    _counterGui.ResetOnSpawn = false
    _counterGui.IgnoreGuiInset = true
    _counterGui.Parent = pg

    local holder = Instance.new("Frame", _counterGui)
    holder.Size = UDim2.new(0, 130, 0, 46)
    holder.Position = UDim2.new(0.5, -65, 0, 8)
    holder.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    holder.BackgroundTransparency = 0.2
    holder.BorderSizePixel = 0
    holder.Active = true
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", holder)
    stroke.Color = Color3.fromRGB(255,255,255); stroke.Thickness=1; stroke.Transparency=0.5

    _fpsLabel = Instance.new("TextLabel", holder)
    _fpsLabel.Size = UDim2.new(1,0,0.5,0)
    _fpsLabel.BackgroundTransparency = 1
    _fpsLabel.Font = Enum.Font.GothamBold
    _fpsLabel.TextSize = 13
    _fpsLabel.TextColor3 = Color3.fromRGB(0,255,0)
    _fpsLabel.Text = "FPS: --"

    _pingLabel = Instance.new("TextLabel", holder)
    _pingLabel.Size = UDim2.new(1,0,0.5,0)
    _pingLabel.Position = UDim2.new(0,0,0.5,0)
    _pingLabel.BackgroundTransparency = 1
    _pingLabel.Font = Enum.Font.GothamBold
    _pingLabel.TextSize = 13
    _pingLabel.TextColor3 = Color3.fromRGB(255,255,0)
    _pingLabel.Text = "Ping: --ms"

    -- Drag
    local drag, ds, sp = false, nil, nil
    holder.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=Vector2.new(inp.Position.X,inp.Position.Y); sp=holder.Position
        end
    end)
    holder.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=Vector2.new(inp.Position.X,inp.Position.Y)-ds
            local vp=workspace.CurrentCamera.ViewportSize
            holder.Position=UDim2.new(
                sp.X.Scale+d.X/vp.X,0,
                sp.Y.Scale+d.Y/vp.Y,0)
        end
    end)
end

local function startCounter()
    createCounter()
    if _heartbeatConn then _heartbeatConn:Disconnect() end
    _fpsCount = 0
    _fpsTime  = workspace.DistributedGameTime

    _heartbeatConn = RunService.Heartbeat:Connect(function()
        if not Config.ShowCounter then return end
        _fpsCount = _fpsCount + 1
        local now = workspace.DistributedGameTime
        if now - _fpsTime >= 1 then
            local fps = math.floor(_fpsCount / math.max(now - _fpsTime, 0.001))
            if _fpsLabel then
                _fpsLabel.Text = "FPS: " .. fps
                _fpsLabel.TextColor3 = fps>=55 and Color3.fromRGB(0,255,0)
                    or fps>=30 and Color3.fromRGB(255,255,0)
                    or Color3.fromRGB(255,80,80)
            end
            local ping = 0
            pcall(function()
                ping = game:GetService("Stats").Network
                    .ServerStatsItem["Data Ping"]:GetValue()
            end)
            if _pingLabel then
                _pingLabel.Text = "Ping: " .. math.floor(ping) .. "ms"
                _pingLabel.TextColor3 = ping<100 and Color3.fromRGB(0,255,0)
                    or ping<200 and Color3.fromRGB(255,255,0)
                    or Color3.fromRGB(255,80,80)
            end
            _fpsCount = 0
            _fpsTime  = now
        end
    end)
end

local function stopCounter()
    if _heartbeatConn then _heartbeatConn:Disconnect(); _heartbeatConn=nil end
    destroyCounter()
end

-- ============================================================
-- RETURN MODULE
-- ============================================================
    -- Expose API
    return {
        Config = Config,
        _orig = _orig,
        applyNoShadow = applyNoShadow,
        applyFullbright = applyFullbright,
        applyReduceMap = applyReduceMap,
        startCounter = startCounter,
        stopCounter = stopCounter,
        SetNoShadow = SetNoShadow,
        SetFullbright = SetFullbright,
        SetReduceMap = SetReduceMap,
        StartCounter = StartCounter,
        StopCounter = StopCounter,
    }
end)()


-- ============================================================
-- UI (FluentUI)
-- ============================================================
local Window = Fluent:CreateWindow({
    Title       = "VD Hub",
    SubTitle    = "Violent District",
    TabWidth    = 140,
    Size        = UDim2.fromOffset(580, 420),
    Theme       = "Darker",
    Acrylic     = false,
    Search      = true,
    MinimizeKey = Enum.KeyCode.RightShift,
})
if not Window then warn("[VD Hub] Window failed"); return end
print("[VD Hub] Building tabs...")

local tabSurv   = Window:AddTab({ Title="Survivor",    Icon="solar/user-bold" })
local tabKiller = Window:AddTab({ Title="Killer",      Icon="solar/swords-bold" })
local tabAim    = Window:AddTab({ Title="Aim",         Icon="solar/crosshair-bold" })
local tabESP    = Window:AddTab({ Title="ESP",         Icon="solar/eye-bold" })
local tabVisual = Window:AddTab({ Title="Visual",      Icon="solar/sun-bold" })
local tabUI     = Window:AddTab({ Title="UI Settings", Icon="solar/settings-bold" })

if not (tabSurv and tabKiller and tabAim and tabESP and tabVisual and tabUI) then
    warn("[VD Hub] Tabs failed"); return
end

local function N(t,c,tp,d)
    pcall(function() Fluent:Notify({Title=t,Content=c,Type=tp or "Info",Duration=d or 2}) end)
end

-- ===== SURVIVOR =====
print("[VD Hub] Building Survivor...")
local s1 = tabSurv:AddSection("Skill Check")
s1:AddToggle("SkillCheck",{
    Title="Auto Skill Check", Default=false,
    Callback=function(v)
        SC.SkillCheck.Enabled=v
        if v then SC.startSkillCheck()
        else if SC.conn then SC.conn:Disconnect(); SC.conn=nil end end
    end
})
s1:AddDropdown("SCMode",{
    Title="Mode", Values={"Instant","Legit","Random"}, Default="Legit",
    Callback=function(v) SC.SkillCheck.Mode=v end
})

local s2 = tabSurv:AddSection("Auto Parry")
s2:AddToggle("Parry",{Title="Auto Parry",Default=false,Callback=function(v) Parry.Config.Enabled=v end})
s2:AddSlider("ParryRange",{Title="Range",Min=5,Max=30,Default=15,Rounding=1,Callback=function(v) Parry.Config.Radius=v end})
s2:AddToggle("ParrySafety",{Title="Safety Mode",Default=true,Callback=function(v) Parry.Config.Safety=v end})
s2:AddToggle("ParryAgg",{Title="Aggressive",Default=false,Callback=function(v) Parry.Config.Aggressive=v end})
s2:AddSlider("ParryFace",{Title="Face Threshold",Min=0,Max=1,Default=0.7,Rounding=0.1,Callback=function(v) Parry.Config.FaceThreshold=v end})

local s3 = tabSurv:AddSection("Survivor Misc")
s3:AddToggle("AutoDodge",{Title="Auto Dodge/Crouch",Default=false,Callback=function(v) Dodge.Config.Enabled=v end})
s3:AddToggle("FastVault",{Title="Fast Vault",Default=false,Callback=function(v) if v then FVault.Enable() else FVault.Disable() end end})
s3:AddToggle("SelfHeal",{Title="Self Heal",Default=false,Callback=function(v) SAS.Config.SelfHeal=v end})
s3:AddToggle("SilentAction",{Title="Silent Actions",Default=false,Callback=function(v) SAS.Config.SilentActions=v end})
s3:AddToggle("AntiAura",{Title="Anti Aura",Default=false,Callback=function(v) SAS.Config.AntiAura=v end})
s3:AddToggle("Moonwalk",{Title="Moonwalk V3",Default=false,Callback=function(v) if v then MW.Enable() else MW.Disable() end end})
s3:AddToggle("GenBypass",{Title="Gen Bypass",Default=false,Callback=function(v) GenBP.GenBypass.Enabled=v; GenBP.GB_UpdateButton() end})
s3:AddToggle("KillerPred",{Title="Killer Prediction",Default=false,Callback=function(v) if v then KP.Enable() else KP.Disable() end end})

-- ===== KILLER =====
print("[VD Hub] Building Killer...")
local k1 = tabKiller:AddSection("Killer Features")
k1:AddToggle("DoubleDmg",{Title="Double Damage Gen",Default=false,Callback=function(v) DDmg.Config.Enabled=v end})
k1:AddToggle("AutoStalk",{Title="Auto Stalk",Default=false,Callback=function(v) if v then Stalk.Start() else Stalk.Stop() end end})
k1:AddSlider("StalkRange",{Title="Stalk Range",Min=50,Max=300,Default=150,Rounding=0,Callback=function(v) Stalk.Config.StalkRange=v end})

local k2 = tabKiller:AddSection("Hitbox Expander")
k2:AddToggle("HitboxTog",{Title="Hitbox Expander",Default=false,Callback=function(v) if v then Hitbox.Start() else Hitbox.Stop() end end})
k2:AddSlider("HitboxSz",{Title="Size",Min=2,Max=50,Default=15,Rounding=0,Callback=function(v) Hitbox.Config.Size=v end})

local k3 = tabKiller:AddSection("Spear Aim")
k3:AddToggle("SpearTog",{Title="Spear Aim",Default=false,Callback=function(v) Spear.Config.Enabled=v end})
k3:AddSlider("SpearGrav",{Title="Gravity",Min=10,Max=200,Default=50,Rounding=0,Callback=function(v) Spear.Config.Gravity=v end})
k3:AddSlider("SpearSpd",{Title="Speed",Min=20,Max=300,Default=100,Rounding=0,Callback=function(v) Spear.Config.Speed=v end})
k3:AddToggle("Snapline",{Title="Show Snapline",Default=true,Callback=function(v) Spear.Config.ShowSnapline=v end})

local k4 = tabKiller:AddSection("Mask Selection")
k4:AddToggle("MaskTog",{Title="Mask Selection GUI",Default=false,Callback=function(v) if v then Mask.Show() else Mask.Hide() end end})

-- ===== AIM =====
print("[VD Hub] Building Aim...")
local a1 = tabAim:AddSection("Silent Aim ToF")
a1:AddToggle("SAToF",{Title="Silent Aim ToF",Default=false,Callback=function(v) SAToF.Config.Enabled=v end})
a1:AddToggle("SABlock",{Title="Block when Knocked",Default=false,Callback=function(v) SAToF.Config.BlockKnocked=v end})
a1:AddToggle("SALock",{Title="Lock Aim",Default=false,Callback=function(v) SAToF.Config.LockAim=v end})
a1:AddToggle("SAFOVMode",{Title="FOV Mode",Default=false,Callback=function(v) SAToF.Config.FOVMode=v end})
a1:AddToggle("SAShowFOV",{Title="Show FOV Circle",Default=false,Callback=function(v) SAToF.Config.ShowFOV=v end})
a1:AddSlider("SAFOV",{Title="FOV Radius",Min=30,Max=500,Default=150,Rounding=5,Callback=function(v) SAToF.Config.FOV=v end})
a1:AddDropdown("SATarget",{Title="Target",Values={"Killer","Survivor"},Default="Killer",Callback=function(v) SAToF.Config.Target=v end})
a1:AddDropdown("SAPart",{Title="Target Part",Values={"Torso","Head","Root"},Default="Torso",Callback=function(v) SAToF.Config.TargetPart=v end})
a1:AddToggle("SALaser",{Title="Hide Laser",Default=false,Callback=function(v) SAToF.Config.HideLaser=v end})

-- ===== ESP =====
print("[VD Hub] Building ESP...")
local e1 = tabESP:AddSection("ESP Settings")
e1:AddToggle("ESPMain",{Title="Enable ESP",Default=false,Callback=function(v) ESP.Config.Enabled=v; if v then ESP.Start() else ESP.Stop() end end})
e1:AddToggle("ESPSurv",{Title="Survivor",Default=true,Callback=function(v) ESP.Config.Survivor=v end})
e1:AddToggle("ESPKill",{Title="Killer",Default=true,Callback=function(v) ESP.Config.Killer=v end})
e1:AddToggle("ESPGen",{Title="Generator + Progress",Default=true,Callback=function(v) ESP.Config.Generator=v end})
e1:AddToggle("ESPGate",{Title="Gate + Timer",Default=true,Callback=function(v) ESP.Config.Gate=v end})
e1:AddToggle("ESPPallet",{Title="Pallet",Default=true,Callback=function(v) ESP.Config.Pallet=v end})
e1:AddToggle("ESPWin",{Title="Window (Vault)",Default=true,Callback=function(v) ESP.Config.Window=v end})
e1:AddToggle("ESPSCP",{Title="SCP",Default=false,Callback=function(v) ESP.Config.SCP=v end})
e1:AddSlider("ESPDist",{Title="Max Distance",Min=100,Max=10000,Default=5000,Rounding=0,Callback=function(v) ESP.Config.Distance=v end})
e1:AddButton({Title="Refresh ESP",Callback=function() ESP.SetLastUpdate(0) end})

-- ===== VISUAL =====
print("[VD Hub] Building Visual...")
local v1 = tabVisual:AddSection("Visual Settings")
v1:AddToggle("NoShadow",{Title="No Shadow",Default=false,Callback=function(v) Visuals.SetNoShadow(v) end})
v1:AddToggle("Fullbright",{Title="Fullbright",Default=false,Callback=function(v) Visuals.SetFullbright(v) end})
v1:AddToggle("ReduceMap",{Title="Reduce Map (Potato)",Default=false,Callback=function(v) Visuals.SetReduceMap(v) end})
v1:AddToggle("FPSCounter",{Title="FPS & Ping Counter",Default=false,Callback=function(v) if v then Visuals.StartCounter() else Visuals.StopCounter() end end})

local v2 = tabVisual:AddSection("Morphs")
v2:AddToggle("Korblox",{Title="Korblox",Default=false,Callback=function(v) if v then Morphs.Korblox.Enable() else Morphs.Korblox.Disable() end end})

-- ===== UI SETTINGS =====
print("[VD Hub] Building UI Settings...")
pcall(function()
    if Fluent.InterfaceManager and tabUI then
        Fluent.InterfaceManager:SetLibrary(Fluent)
        Fluent.InterfaceManager:SetFolder("VDHub/Interface")
        pcall(function() Fluent.InterfaceManager:BuildInterfaceSection(tabUI) end)
        pcall(function() Fluent.InterfaceManager:LoadSettings() end)
    end
end)
pcall(function()
    if Fluent.SaveManager and tabUI then
        Fluent.SaveManager:SetLibrary(Fluent)
        Fluent.SaveManager:SetFolder("VDHub/Config")
        Fluent.SaveManager:IgnoreThemeSettings()
        pcall(function() Fluent.SaveManager:BuildConfigSection(tabUI) end)
        pcall(function() Fluent.SaveManager:LoadAutoloadConfig() end)
    end
end)
print("[VD Hub] Ready!")
N("VD Hub", "Violent District loaded!", "Success", 4)
