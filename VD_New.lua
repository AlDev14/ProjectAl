-- ============================================================
-- WISNU HUB - Violent District
-- Version: 3.0 (Clean Build)
-- ============================================================
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(1)

-- ============================================================
-- SERVICES
-- ============================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local UserInputService   = game:GetService("UserInputService")
local VirtualInputManager= game:GetService("VirtualInputManager")
local Lighting           = game:GetService("Lighting")
local TweenService       = game:GetService("TweenService")
local Stats              = game:GetService("Stats")
local CoreGui            = game:GetService("CoreGui")

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui", 10) or LocalPlayer:FindFirstChildOfClass("PlayerGui")
local Camera       = workspace.CurrentCamera

-- ============================================================
-- CONFIG (VD)
-- ============================================================
getgenv().VD = getgenv().VD or {}
local VD = getgenv().VD

-- Survivor
VD.AutoSkillcheck       = VD.AutoSkillcheck       or false
VD.AutoSkillcheckMode   = VD.AutoSkillcheckMode   or "Legit"
VD.Surv_AutoParry       = VD.Surv_AutoParry       or false
VD.Surv_ParryRange      = VD.Surv_ParryRange      or 15
VD.Surv_ParrySafety     = VD.Surv_ParrySafety     or true
VD.Surv_ParryAggressive = VD.Surv_ParryAggressive or false
VD.Surv_ParryFace       = VD.Surv_ParryFace       or 0.7
VD.Surv_AutoCrouch      = VD.Surv_AutoCrouch      or false
VD.Surv_AutoDropPallet  = VD.Surv_AutoDropPallet  or false
VD.Surv_AutoDropPalletDist = VD.Surv_AutoDropPalletDist or 6
VD.Surv_AntiKnock       = VD.Surv_AntiKnock       or false
VD.SkipCutscene         = VD.SkipCutscene         or false
VD.SkipCutsceneLoad     = VD.SkipCutsceneLoad     or false
VD.UnlimitedVault       = VD.UnlimitedVault       or false
VD.Moonwalk_Enabled     = VD.Moonwalk_Enabled     or false
VD.Moonwalk_Hotkey      = VD.Moonwalk_Hotkey      or Enum.KeyCode.G
VD.GenBypass_Enabled    = VD.GenBypass_Enabled    or false
VD.GenBypass_Hotkey     = VD.GenBypass_Hotkey     or Enum.KeyCode.G
VD.KillerPredict_Enabled= VD.KillerPredict_Enabled or false
VD.KillerPredict_Interval = VD.KillerPredict_Interval or 3

-- Killer
VD.DoubleDamageGen      = VD.DoubleDamageGen      or false
VD.HitboxExpander       = VD.HitboxExpander       or false
VD.HitboxSize           = VD.HitboxSize           or 15
VD.UnlockSkillsCarry    = VD.UnlockSkillsCarry    or false
VD.AutoStalk            = VD.AutoStalk            or false
VD.MaskSelection_Enabled= VD.MaskSelection_Enabled or false
VD.SpearGravity         = VD.SpearGravity         or 50
VD.SpearSpeed           = VD.SpearSpeed           or 100
VD.SpearAimEnabled      = VD.SpearAimEnabled      or false

-- Silent Aim
VD.Pistol_SilentAim     = VD.Pistol_SilentAim     or false
VD.Pistol_BlockKnocked  = VD.Pistol_BlockKnocked  or false
VD.Pistol_LockAim       = VD.Pistol_LockAim       or false
VD.Pistol_Target        = VD.Pistol_Target        or "Killer"
VD.Pistol_FOVMode       = VD.Pistol_FOVMode       or false
VD.Pistol_ShowFOV       = VD.Pistol_ShowFOV       or false
VD.Pistol_FOV           = VD.Pistol_FOV           or 150
VD.Pistol_TargetPart    = VD.Pistol_TargetPart    or "Torso"
VD.Pistol_HideLaser     = VD.Pistol_HideLaser     or false
VD.Veil_SilentAim       = VD.Veil_SilentAim       or false
VD.Veil_ShowFOV         = VD.Veil_ShowFOV         or false
VD.Veil_FOV             = VD.Veil_FOV             or 200

-- ESP
VD.ESP_Enabled          = VD.ESP_Enabled          or false
VD.ESP_Survivor         = VD.ESP_Survivor         or true
VD.ESP_Killer           = VD.ESP_Killer           or true
VD.ESP_Generator        = VD.ESP_Generator        or true
VD.ESP_Pallet           = VD.ESP_Pallet           or true
VD.ESP_Window           = VD.ESP_Window           or true
VD.ESP_SCP              = VD.ESP_SCP              or true
VD.ESP_Gate             = VD.ESP_Gate             or true
VD.ESP_ShowItem         = VD.ESP_ShowItem         or true
VD.ESP_Distance         = VD.ESP_Distance         or 5000

-- Visual
VD.NoShadow             = VD.NoShadow             or false
VD.LowGraphics          = VD.LowGraphics          or false
VD.Fullbright           = VD.Fullbright           or false
VD.NoFog                = VD.NoFog                or false
VD.ReduceMap            = VD.ReduceMap            or false
VD.RemoveVisualEffects  = VD.RemoveVisualEffects  or false
VD.CustomFOV            = VD.CustomFOV            or false
VD.FOVValue             = VD.FOVValue             or 70

-- Misc
VD.ShowFPS              = VD.ShowFPS              or false
VD.ShowPing             = VD.ShowPing             or false

-- ============================================================
-- HELPERS
-- ============================================================
local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function IsKiller(p)
    return p and p.Team and p.Team.Name:lower():find("killer") ~= nil
end

local function IsDowned(char)
    if not char then return false end
    return char:GetAttribute("Knocked") == true
        or char:GetAttribute("IsHooked") == true
        or char:GetAttribute("IsCarried") == true
end

local function GetGameValue(obj, name)
    if typeof(obj) ~= "Instance" then return nil end
    local attr = obj:GetAttribute(name)
    if attr ~= nil then return attr end
    local child = obj:FindFirstChild(name)
    if child and child:IsA("ValueBase") then return child.Value end
    return nil
end

-- Lighting original values
local OriginalLighting = {
    Brightness      = Lighting.Brightness,
    ClockTime       = Lighting.ClockTime,
    Ambient         = Lighting.Ambient,
    OutdoorAmbient  = Lighting.OutdoorAmbient,
    FogStart        = Lighting.FogStart,
    FogEnd          = Lighting.FogEnd,
    GlobalShadows   = Lighting.GlobalShadows,
}

-- ============================================================
-- REMOTE HELPERS (lazy load)
-- ============================================================
local _remoteCache = {}
local function getCachedRemote(key, finder)
    if _remoteCache[key] and _remoteCache[key].Parent then
        return _remoteCache[key]
    end
    pcall(function() _remoteCache[key] = finder() end)
    return _remoteCache[key]
end

local function getParryRemote()
    return getCachedRemote("parry", function()
        local r = ReplicatedStorage:FindFirstChild("Remotes")
        local items = r and r:FindFirstChild("Items")
        local dagger = items and items:FindFirstChild("Parrying Dagger")
        local rem = dagger and dagger:FindFirstChild("parry")
        if not rem and r then
            for _, v in ipairs(r:GetDescendants()) do
                if v:IsA("RemoteEvent") and v.Name:lower() == "parry" then
                    return v
                end
            end
        end
        return rem
    end)
end

local function getVeilRemote()
    return getCachedRemote("veil", function()
        local r = ReplicatedStorage:WaitForChild("Remotes", 5)
        if not r then return nil end
        local items = r:FindFirstChild("Items")
        local vf = items and items:FindFirstChild("Veil")
        local rem = vf and (vf:FindFirstChild("Activate") or vf:FindFirstChild("Fire") or vf:FindFirstChildWhichIsA("RemoteEvent"))
        if not rem then
            local killers = r:FindFirstChild("Killers")
            local vk = killers and killers:FindFirstChild("Veil")
            rem = vk and (vk:FindFirstChild("Activate") or vk:FindFirstChild("Attack") or vk:FindFirstChildWhichIsA("RemoteEvent"))
        end
        return rem
    end)
end

local function getToFRemote()
    return getCachedRemote("tof", function()
        local r = ReplicatedStorage:FindFirstChild("Remotes")
        local items = r and r:FindFirstChild("Items")
        local tof = items and items:FindFirstChild("Twist of Fate")
        return tof and tof:FindFirstChild("Fire")
    end)
end

-- ============================================================
-- SKILL CHECK
-- ============================================================
local SkillBusy = false
local SkillConn = nil

local function TriggerSkillButton()
    -- Method 1: firesignal pada action button
    if PlayerGui then
        local mob = PlayerGui:FindFirstChild("Survivor-mob")
        local controls = mob and mob:FindFirstChild("Controls")
        local btn = controls and (controls:FindFirstChild("action") or controls:FindFirstChild("check"))
        if btn and btn:IsA("GuiObject") and btn.Visible then
            if type(firesignal) == "function" then
                pcall(function()
                    firesignal(btn.MouseButton1Down)
                    task.wait(0.005)
                    firesignal(btn.MouseButton1Up)
                end)
                return
            end
            pcall(function()
                local p, s = btn.AbsolutePosition, btn.AbsoluteSize
                local ins = game:GetService("GuiService"):GetGuiInset()
                local tid = 8822 + math.random(1, 9999)
                VirtualInputManager:SendTouchEvent(tid, 0, p.X+s.X/2+ins.X, p.Y+s.Y/2+ins.Y)
                task.wait(0.005)
                VirtualInputManager:SendTouchEvent(tid, 2, p.X+s.X/2+ins.X, p.Y+s.Y/2+ins.Y)
            end)
            return
        end
    end
    -- Fallback: Space
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.005)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
end

local function startSkillCheck()
    if SkillConn then SkillConn:Disconnect() end
    SkillConn = RunService.RenderStepped:Connect(function()
        if not VD.AutoSkillcheck or SkillBusy then return end
        local prompt = PlayerGui and PlayerGui:FindFirstChild("SkillCheckPromptGui")
        if not prompt then return end
        local check = prompt:FindFirstChild("Check")
        if not check or not check.Visible then return end
        local line = check:FindFirstChild("Line")
        local goal = check:FindFirstChild("Goal")
        if not line or not goal then return end
        local mode = VD.AutoSkillcheckMode
        if mode == "Random" then mode = (math.random(1,2)==1) and "Instant" or "Legit" end
        if mode == "Instant" then
            line.Rotation = goal.Rotation + 109
            SkillBusy = true
            task.spawn(function()
                TriggerSkillButton()
                task.wait(0.2)
                SkillBusy = false
            end)
        else
            local lr = line.Rotation % 360
            local gr = goal.Rotation % 360
            local s1 = (gr+102)%360; local e1 = (gr+116)%360
            local inside = (s1>e1 and (lr>=s1 or lr<=e1)) or (lr>=s1 and lr<=e1)
            if inside then
                SkillBusy = true
                task.spawn(function()
                    TriggerSkillButton()
                    task.wait(0.05)
                    SkillBusy = false
                end)
            end
        end
    end)
end
if VD.AutoSkillcheck then startSkillCheck() end

-- ============================================================
-- AUTO PARRY
-- ============================================================
local ParryState = { Cooldown = false }
local _parryConn = nil

local function ExecuteParry()
    local remote = getParryRemote()
    if ParryState.Cooldown or not remote then return end
    ParryState.Cooldown = true
    pcall(function()
        for i = 1, 8 do remote:FireServer() end
    end)
    task.delay(0.8, function() ParryState.Cooldown = false end)
end

local PARRY_ANIM_IDS = {
    ["122812055447896"] = true,
    ["80411309607666"]  = true, -- Abyssal crouch
}

local function setupParry(char)
    if _parryConn then _parryConn:Disconnect() end
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    _parryConn = animator.AnimationPlayed:Connect(function(track)
        if not VD.Surv_AutoParry then return end
        local anim = track.Animation
        local id = anim and anim.AnimationId:match("%d+") or ""
        if not PARRY_ANIM_IDS[id] then return end
        -- Abyssal dodge
        if id == "80411309607666" then
            local myChar = LocalPlayer.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local kChar = char
            local kHRP = kChar:FindFirstChild("HumanoidRootPart")
            if myHRP and kHRP and (myHRP.Position - kHRP.Position).Magnitude <= 40 then
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                    task.wait(2)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
                end)
            end
            return
        end
        local myChar = LocalPlayer.Character
        if IsDowned(myChar) then return end
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local kHRP = char:FindFirstChild("HumanoidRootPart")
        if not myHRP or not kHRP then return end
        local dist = (myHRP.Position - kHRP.Position).Magnitude
        if dist > VD.Surv_ParryRange then return end
        -- Face check
        if VD.Surv_ParrySafety then
            local flat = myHRP.Position - kHRP.Position
            local dir = Vector3.new(flat.X, 0, flat.Z)
            if dir.Magnitude > 0 then
                local kLook = Vector3.new(kHRP.CFrame.LookVector.X, 0, kHRP.CFrame.LookVector.Z).Unit
                if kLook:Dot(dir.Unit) < VD.Surv_ParryFace then return end
            end
        end
        ExecuteParry()
    end)
end

-- Setup parry untuk semua killer
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer and IsKiller(p) and p.Character then
        setupParry(p.Character)
    end
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if IsKiller(p) then setupParry(char) end
    end)
end)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if IsKiller(p) then setupParry(char) end
        end)
    end
end

-- Parry Circle Visual
local ParryCirclePart = nil
RunService.Heartbeat:Connect(function()
    if VD.Surv_AutoParry then
        local root = getRoot()
        if not root then return end
        if not ParryCirclePart then
            ParryCirclePart = Instance.new("Part")
            ParryCirclePart.Name = "VD_ParryCircle"
            ParryCirclePart.Shape = Enum.PartType.Cylinder
            ParryCirclePart.Anchored = true
            ParryCirclePart.CanCollide = false
            ParryCirclePart.CastShadow = false
            ParryCirclePart.Material = Enum.Material.Neon
            ParryCirclePart.Color = Color3.fromRGB(255, 80, 80)
            ParryCirclePart.Transparency = 0.5
            ParryCirclePart.Parent = workspace
        end
        local r = (VD.Surv_ParryRange or 15) * 2
        ParryCirclePart.Size = Vector3.new(0.15, r, r)
        local yOff = root.Size.Y/2 + 0.5
        ParryCirclePart.CFrame = CFrame.new(root.Position - Vector3.new(0,yOff,0)) * CFrame.Angles(0,0,math.rad(90))
    elseif ParryCirclePart then
        ParryCirclePart:Destroy(); ParryCirclePart = nil
    end
end)

-- ============================================================
-- SILENT AIM TOF
-- ============================================================
local isChargingPistol = false
local lockedPistolTarget = nil
local currentTouchPistolInput = nil
local pistolLaser = nil
local isAimingVeil = false

local function getTargetPartObject(char)
    if VD.Pistol_TargetPart == "Head" then return char:FindFirstChild("Head")
    elseif VD.Pistol_TargetPart == "Root" then return char:FindFirstChild("HumanoidRootPart")
    else return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
    end
end

local function getPistolTarget()
    local closestDist = (VD.Pistol_ShowFOV and VD.Pistol_FOVMode) and VD.Pistol_FOV or math.huge
    local bestTarget = nil
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    if VD.Pistol_BlockKnocked and IsDowned(myChar) then return nil end
    local cam = Camera
    local mouseLoc = UserInputService:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local valid = (VD.Pistol_Target == "Killer" and IsKiller(p))
                       or (VD.Pistol_Target == "Survivor" and not IsKiller(p))
            if valid then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and not IsDowned(p.Character) then
                    local part = getTargetPartObject(p.Character)
                    if part then
                        local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                        if onScreen or not VD.Pistol_FOVMode then
                            local dist = VD.Pistol_FOVMode
                                and (Vector2.new(screenPos.X, screenPos.Y) - mouseLoc).Magnitude
                                or (part.Position - myHRP.Position).Magnitude
                            if dist < closestDist then closestDist = dist; bestTarget = part end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

local function executeSilentAimFire()
    local targetPart = getPistolTarget()
    local myChar = LocalPlayer.Character
    if VD.Pistol_BlockKnocked and IsDowned(myChar) then return end
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
    local weaponArg = tof
    local rightArm = tof:FindFirstChild("Right Arm")
    if rightArm then
        weaponArg = rightArm:FindFirstChild("EmperorGun") or rightArm:FindFirstChild("gun") or rightArm
    end
    local startPos = myHRP.Position
    local targetPos = targetPart.Position
    local vel = Vector3.new(0,0,0)
    pcall(function() vel = targetPart.AssemblyLinearVelocity end)
    vel = Vector3.new(vel.X, 0, vel.Z)
    local dist = (targetPos - startPos).Magnitude
    local timeToHit = dist / 400
    local predicted = targetPos + (vel * timeToHit)
    local aimDir = ((predicted + Vector3.new(0,-2,0)) - startPos).Unit
    local remote = getToFRemote()
    if remote then pcall(function() remote:FireServer(weaponArg, aimDir) end) end
end

-- Veil target
local function getVeilTarget()
    local myHRP = getRoot()
    if not myHRP then return nil end
    local best, bestDist = nil, 50
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsKiller(p) and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < bestDist then bestDist = d; best = hrp end
            end
        end
    end
    return best
end

local function executeVeilSilentAim()
    local target = getVeilTarget()
    local remote = getVeilRemote()
    if not remote then return end
    pcall(function()
        local ok = pcall(function() remote:FireServer(target) end)
        if not ok then pcall(function() remote:FireServer() end) end
    end)
end

-- FOV Circle Drawing
local PistolFOVCircle = nil
local VeilFOVCircle   = nil
pcall(function()
    PistolFOVCircle = Drawing.new("Circle")
    PistolFOVCircle.Filled = false
    PistolFOVCircle.Color  = Color3.fromRGB(0, 255, 100)
    PistolFOVCircle.Thickness = 1.5
    PistolFOVCircle.Visible = false
    PistolFOVCircle.NumSides = 64

    VeilFOVCircle = Drawing.new("Circle")
    VeilFOVCircle.Filled    = false
    VeilFOVCircle.Color     = Color3.fromRGB(255, 100, 100)
    VeilFOVCircle.Thickness = 1.5
    VeilFOVCircle.Visible   = false
    VeilFOVCircle.NumSides  = 64
end)

-- Pistol Laser
local function CreatePistolLaser()
    if pistolLaser then return end
    pistolLaser = Instance.new("Part")
    pistolLaser.Name = "VD_PistolLaser"
    pistolLaser.Material = Enum.Material.Neon
    pistolLaser.Color = Color3.fromRGB(255, 0, 0)
    pistolLaser.CanCollide = false
    pistolLaser.Anchored   = true
    pistolLaser.CastShadow = false
    pistolLaser.Size = Vector3.new(0.05, 0.05, 1)
end
CreatePistolLaser()

-- Input Handlers
UserInputService.InputBegan:Connect(function(input, gp)
    local isTouch = input.UserInputType == Enum.UserInputType.Touch
    if gp and not isTouch then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if VD.Pistol_SilentAim then isChargingPistol = true; lockedPistolTarget = getPistolTarget() end
        if VD.Veil_SilentAim   then isAimingVeil = true end
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if VD.Pistol_SilentAim and isChargingPistol then executeSilentAimFire() end
        if VD.Veil_SilentAim   and isAimingVeil     then executeVeilSilentAim() end
    end
    if isTouch then
        if VD.Pistol_SilentAim or VD.Veil_SilentAim then
            local mob = PlayerGui and PlayerGui:FindFirstChild("Survivor-mob")
            local ctrl = mob and mob:FindFirstChild("Controls")
            local btn  = ctrl and ctrl:FindFirstChild("Gui-mob")
            if btn and btn.Visible then
                local pos = input.Position
                local abs = btn.AbsolutePosition
                local sz  = btn.AbsoluteSize
                if pos.X >= abs.X and pos.X <= abs.X+sz.X and pos.Y >= abs.Y and pos.Y <= abs.Y+sz.Y then
                    if VD.Pistol_SilentAim then
                        isChargingPistol = true; currentTouchPistolInput = input; lockedPistolTarget = getPistolTarget()
                    end
                    if VD.Veil_SilentAim then isAimingVeil = true; currentTouchPistolInput = input end
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isChargingPistol = false; lockedPistolTarget = nil; isAimingVeil = false
    end
    if input.UserInputType == Enum.UserInputType.Touch and input == currentTouchPistolInput then
        if isChargingPistol then executeSilentAimFire() end
        isChargingPistol = false; isAimingVeil = false; currentTouchPistolInput = nil
    end
end)

-- Render loop (lock aim, laser, FOV)
RunService.RenderStepped:Connect(function()
    -- Lock Aim
    if isChargingPistol and VD.Pistol_LockAim then
        lockedPistolTarget = lockedPistolTarget or getPistolTarget()
        if lockedPistolTarget and lockedPistolTarget.Parent then
            local hum = lockedPistolTarget.Parent:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, lockedPistolTarget.Position), 0.15)
            end
        end
    end
    -- Pistol Laser
    if isChargingPistol and VD.Pistol_SilentAim and pistolLaser then
        local tp = getPistolTarget()
        if tp then
            local myChar = LocalPlayer.Character
            local leftArm = myChar and (myChar:FindFirstChild("Left Arm") or myChar:FindFirstChild("LeftHand"))
            local startPos = leftArm and leftArm.Position or (getRoot() and getRoot().Position or Vector3.new())
            local vel = Vector3.new(0,0,0)
            pcall(function() vel = tp.AssemblyLinearVelocity end)
            vel = Vector3.new(vel.X, 0, vel.Z)
            local d = (tp.Position - startPos).Magnitude
            local predicted = tp.Position + (vel * (d/400))
            local endPos = predicted + Vector3.new(0,-1.2,0)
            local nd = (endPos - startPos).Magnitude
            if nd > 0 then
                pistolLaser.Parent = workspace
                pistolLaser.Transparency = VD.Pistol_HideLaser and 1 or 0
                pistolLaser.Size = Vector3.new(0.05, 0.05, nd)
                pistolLaser.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0,0,-nd/2)
            end
        else
            if pistolLaser and pistolLaser.Parent then pistolLaser.Parent = nil end
        end
    else
        if pistolLaser and pistolLaser.Parent then pistolLaser.Parent = nil end
    end
    -- FOV Circles
    if PistolFOVCircle then
        if VD.Pistol_SilentAim and VD.Pistol_ShowFOV and VD.Pistol_FOVMode then
            local target = getPistolTarget()
            PistolFOVCircle.Visible   = true
            PistolFOVCircle.Radius    = VD.Pistol_FOV
            PistolFOVCircle.Position  = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            PistolFOVCircle.Color     = target and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,100)
        else
            PistolFOVCircle.Visible = false
        end
    end
    if VeilFOVCircle then
        if VD.Veil_SilentAim and VD.Veil_ShowFOV then
            VeilFOVCircle.Visible  = true
            VeilFOVCircle.Radius   = VD.Veil_FOV or 200
            VeilFOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        else
            VeilFOVCircle.Visible = false
        end
    end
end)

-- ============================================================
-- ESP (with map cache)
-- ============================================================
local COLORS = {
    Survivor  = Color3.fromRGB(0, 240, 255),
    Killer    = Color3.fromRGB(255, 0, 60),
    Generator = Color3.fromRGB(255, 200, 0),
    Gate      = Color3.fromRGB(0, 255, 128),
    Pallet    = Color3.fromRGB(180, 0, 255),
    Hook      = Color3.fromRGB(255, 0, 150),
    Window    = Color3.fromRGB(255, 255, 0),
    SCP       = Color3.fromRGB(255, 140, 0),
}

local espHighlights = {}
local _mapCache = { Generators={}, Pallets={}, Hooks={}, Gates={} }
local _mapCacheTime = 0
local _espLastUpdate = 0

local function refreshMapCache()
    local now = workspace.DistributedGameTime
    if now - _mapCacheTime < 5 then return end
    _mapCacheTime = now
    _mapCache = { Generators={}, Pallets={}, Hooks={}, Gates={} }
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    for _, obj in ipairs(map:GetDescendants()) do
        local n = obj.Name
        if n=="Generator" then table.insert(_mapCache.Generators, obj)
        elseif n=="Hook" then table.insert(_mapCache.Hooks, obj)
        elseif n=="Gate" then table.insert(_mapCache.Gates, obj)
        elseif n=="Pallet" or n=="Palletwrong" then table.insert(_mapCache.Pallets, obj)
        end
    end
end

local function clearESP()
    for _, h in ipairs(espHighlights) do pcall(function() h:Destroy() end) end
    espHighlights = {}
end

local function addHighlight(adornee, color)
    if not adornee or not adornee.Parent then return end
    local existing = adornee:FindFirstChild("_VD_HL")
    if existing then
        existing.FillColor = color; existing.OutlineColor = color
        return
    end
    local h = Instance.new("Highlight")
    h.Name = "_VD_HL"
    h.FillTransparency = 0.75
    h.OutlineTransparency = 0.2
    h.FillColor = color
    h.OutlineColor = color
    h.Adornee = adornee
    h.Parent = adornee
    table.insert(espHighlights, h)
end

local function isSCPModel(obj)
    if not obj or not obj:IsA("Model") then return false end
    local hum = obj:FindFirstChild("Humanoid")
    if not hum then return false end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == obj then return false end
    end
    local n = obj.Name:lower()
    return n:find("scp") or n:find("zombie") or n:find("monster") or n:find("infected") or n:find("entity")
end

local function updateESP()
    local now = workspace.DistributedGameTime
    if now - _espLastUpdate < 2.5 then return end
    _espLastUpdate = now
    clearESP()
    if not VD.ESP_Enabled then return end
    local root = getRoot()
    if not root then return end
    local maxDist = VD.ESP_Distance
    refreshMapCache()

    -- Players
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist <= maxDist then
                    if IsKiller(p) and VD.ESP_Killer then
                        addHighlight(p.Character, COLORS.Killer)
                    elseif not IsKiller(p) and VD.ESP_Survivor then
                        addHighlight(p.Character, COLORS.Survivor)
                    end
                end
            end
        end
    end

    -- Generators
    if VD.ESP_Generator then
        for _, gen in ipairs(_mapCache.Generators) do
            if gen and gen.Parent then
                local part = gen:FindFirstChildWhichIsA("BasePart", true)
                if part and (part.Position - root.Position).Magnitude <= maxDist then
                    addHighlight(gen, COLORS.Generator)
                end
            end
        end
    end

    -- Pallets
    if VD.ESP_Pallet then
        for _, pallet in ipairs(_mapCache.Pallets) do
            if pallet and pallet.Parent then
                local part = pallet:FindFirstChildWhichIsA("BasePart", true)
                if part and (part.Position - root.Position).Magnitude <= maxDist then
                    addHighlight(pallet, COLORS.Pallet)
                end
            end
        end
    end

    -- Gates
    if VD.ESP_Gate then
        for _, gate in ipairs(_mapCache.Gates) do
            if gate and gate.Parent then
                local part = gate:FindFirstChildWhichIsA("BasePart", true)
                if part and (part.Position - root.Position).Magnitude <= maxDist then
                    addHighlight(gate, COLORS.Gate)
                end
            end
        end
    end

    -- Windows (vault)
    if VD.ESP_Window then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local hasVault = obj:FindFirstChild("VaultPoint") or obj:FindFirstChild("VaultTrigger")
                if hasVault then
                    local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if part and (part.Position - root.Position).Magnitude <= maxDist then
                        addHighlight(obj, COLORS.Window)
                    end
                end
            end
        end
    end

    -- SCP
    if VD.ESP_SCP then
        for _, obj in ipairs(workspace:GetChildren()) do
            if isSCPModel(obj) then
                local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if part and (part.Position - root.Position).Magnitude <= maxDist then
                    addHighlight(obj, COLORS.SCP)
                end
            end
        end
    end
end

-- ESP update loop
task.spawn(function()
    while true do
        task.wait(2.5)
        pcall(updateESP)
    end
end)

-- ============================================================
-- MOONWALK V3
-- ============================================================
local MoonwalkEnabled = VD.Moonwalk_Enabled
local MoonwalkMoveConn = nil
local MoonwalkGui = nil
local MOON_CONFIG = {
    SIDE_SPEED   = 2.2,
    BACK_SPEED   = 4.0,
    INTERVAL     = 0.045,
    SMOOTH_FACTOR= 0.85,
    GUI_POSITION = UDim2.fromScale(0.78, 0.22),
}
local CurrentDirection = 1
local LastSwitch = 0
local SmoothVelocity = Vector3.new()

local function stopMoonwalkInternal()
    if MoonwalkMoveConn then MoonwalkMoveConn:Disconnect(); MoonwalkMoveConn = nil end
    SmoothVelocity = Vector3.new()
end

local function startMoonwalkInternal()
    stopMoonwalkInternal()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end
    CurrentDirection = 1; LastSwitch = 0
    MoonwalkMoveConn = RunService.RenderStepped:Connect(function()
        if not MoonwalkEnabled then return end
        local c = LocalPlayer.Character
        if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart")
        local h = c:FindFirstChildOfClass("Humanoid")
        if not r or not h or h.Health <= 0 then stopMoonwalkInternal(); return end
        local now = workspace.DistributedGameTime
        if now - LastSwitch >= MOON_CONFIG.INTERVAL then
            CurrentDirection = CurrentDirection * -1; LastSwitch = now
        end
        local look  = r.CFrame.LookVector
        local right = r.CFrame.RightVector
        local target = (look * -MOON_CONFIG.BACK_SPEED) + (right * (CurrentDirection * MOON_CONFIG.SIDE_SPEED))
        SmoothVelocity = SmoothVelocity:Lerp(target, MOON_CONFIG.SMOOTH_FACTOR)
        h:Move(SmoothVelocity, false)
    end)
end

local function destroyMoonwalkGui()
    if MoonwalkGui then MoonwalkGui:Destroy(); MoonwalkGui = nil end
end

local function createMoonwalkGui()
    destroyMoonwalkGui()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    MoonwalkGui = Instance.new("ScreenGui")
    MoonwalkGui.Name = "VD_Moonwalk_V3"
    MoonwalkGui.ResetOnSpawn = false
    MoonwalkGui.Parent = pg
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Parent = MoonwalkGui
    frame.Size = UDim2.fromOffset(180, 80)
    frame.Position = MOON_CONFIG.GUI_POSITION
    frame.BackgroundColor3 = Color3.fromRGB(10,10,25)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(80,80,200); stroke.Thickness = 1.5

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,22)
    title.BackgroundTransparency = 1
    title.Text = "Moonwalk V3"
    title.TextColor3 = Color3.fromRGB(150,150,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12

    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Size = UDim2.new(1,-16,0,30)
    toggleBtn.Position = UDim2.new(0,8,0,28)
    toggleBtn.BackgroundColor3 = MoonwalkEnabled and Color3.fromRGB(50,200,100) or Color3.fromRGB(50,50,130)
    toggleBtn.Text = MoonwalkEnabled and "[.] STOP" or "[>] START"
    toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 13
    toggleBtn.BorderSizePixel = 0
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,6)

    local statusLbl = Instance.new("TextLabel", frame)
    statusLbl.Name = "StatusLbl"
    statusLbl.Size = UDim2.new(1,0,0,16)
    statusLbl.Position = UDim2.new(0,0,1,-20)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = MoonwalkEnabled and "[ON]" or "[OFF]"
    statusLbl.TextColor3 = MoonwalkEnabled and Color3.fromRGB(0,255,150) or Color3.fromRGB(255,80,80)
    statusLbl.Font = Enum.Font.GothamBold
    statusLbl.TextSize = 11

    toggleBtn.MouseButton1Click:Connect(function()
        MoonwalkEnabled = not MoonwalkEnabled
        VD.Moonwalk_Enabled = MoonwalkEnabled
        if MoonwalkEnabled then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(50,200,100)
            toggleBtn.Text = "[.] STOP"
            statusLbl.Text = "[ON]"
            statusLbl.TextColor3 = Color3.fromRGB(0,255,150)
            startMoonwalkInternal()
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,130)
            toggleBtn.Text = "[>] START"
            statusLbl.Text = "[OFF]"
            statusLbl.TextColor3 = Color3.fromRGB(255,80,80)
            stopMoonwalkInternal()
        end
    end)

    -- Drag
    local dragging, dragStart, startPos = false, nil, nil
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = Vector2.new(inp.Position.X, inp.Position.Y); startPos = frame.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local delta = Vector2.new(inp.Position.X, inp.Position.Y) - dragStart
            local vs = MoonwalkGui.AbsoluteSize
            if vs.X > 0 and vs.Y > 0 then
                frame.Position = UDim2.new(
                    math.clamp(startPos.X.Scale + delta.X/vs.X, 0, 0.9), 0,
                    math.clamp(startPos.Y.Scale + delta.Y/vs.Y, 0, 0.9), 0
                )
            end
        end
    end)

    -- Keybind
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == VD.Moonwalk_Hotkey then
            toggleBtn.MouseButton1Click:Fire()
        end
    end)
end

if VD.Moonwalk_Enabled then
    createMoonwalkGui()
    startMoonwalkInternal()
end

-- ============================================================
-- FAST VAULT
-- ============================================================
local VaultTracks = {}
local FastVaultAnimConn = nil
local VAULT_ANIM_ORIG = "83873880822918"
local VAULT_ANIM_FAST = "rbxassetid://136962284480779"
local FAST_VAULT_SPEED = 1.5

local UnlimitedVaultConn = nil

local function setupFastVaultAnim(char)
    if FastVaultAnimConn then FastVaultAnimConn:Disconnect(); FastVaultAnimConn = nil end
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    FastVaultAnimConn = animator.AnimationPlayed:Connect(function(track)
        if not VD.UnlimitedVault then return end
        local anim = track.Animation
        if not anim or not anim.AnimationId then return end
        local id = tostring(anim.AnimationId):match("%d+") or ""
        local animName = (anim.Name or ""):lower()
        local isVault = id == VAULT_ANIM_ORIG or animName:find("vault") or animName:find("window")
        if not isVault then return end
        if VaultTracks[track] then return end
        VaultTracks[track] = true
        pcall(function()
            track:Stop()
            local newAnim = Instance.new("Animation")
            newAnim.AnimationId = VAULT_ANIM_FAST
            local newTrack = animator:LoadAnimation(newAnim)
            newTrack.Priority = Enum.AnimationPriority.Action
            newTrack:Play()
            newTrack:AdjustSpeed(FAST_VAULT_SPEED)
            newTrack.Stopped:Connect(function() VaultTracks[track] = nil end)
        end)
    end)
end

local function EnableUnlimitedVault()
    if VD.UnlimitedVault then return end
    VD.UnlimitedVault = true
    pcall(function()
        local CollectionService = game:GetService("CollectionService")
        for _, v in ipairs(CollectionService:GetTagged("Blocked")) do
            CollectionService:RemoveTag(v, "Blocked")
        end
        if UnlimitedVaultConn then UnlimitedVaultConn:Disconnect() end
        UnlimitedVaultConn = CollectionService:GetInstanceAddedSignal("Blocked"):Connect(function(inst)
            if VD.UnlimitedVault then CollectionService:RemoveTag(inst, "Blocked") end
        end)
    end)
    setupFastVaultAnim(LocalPlayer.Character)
end

local function DisableUnlimitedVault()
    VD.UnlimitedVault = false
    if UnlimitedVaultConn then UnlimitedVaultConn:Disconnect(); UnlimitedVaultConn = nil end
    if FastVaultAnimConn  then FastVaultAnimConn:Disconnect();  FastVaultAnimConn  = nil end
    table.clear(VaultTracks)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if VD.UnlimitedVault then setupFastVaultAnim(char) end
    if VD.Surv_AutoParry  then
        task.wait(0.5)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and IsKiller(p) then setupParry(p.Character) end
        end
    end
end)

-- ============================================================
-- SKIP CUTSCENE
-- ============================================================
local _skipConn = nil
local _skipLoadConn = nil

local function _shouldSkipGui(name)
    local n = name:lower()
    return n:find("cutscene") or n:find("cinematic") or n:find("intro")
        or n:find("transition") or n:find("matchstart") or n:find("roundstart")
        or n:find("gamestart") or n:find("beginning") or n:find("splash")
end

local function setupSkipCutscene()
    if _skipConn then _skipConn:Disconnect() end
    _skipConn = PlayerGui.ChildAdded:Connect(function(child)
        if not VD.SkipCutscene then return end
        if _shouldSkipGui(child.Name) then
            task.wait(0.05)
            pcall(function() child.Enabled = false end)
            pcall(function() child:Destroy() end)
        end
    end)
    for _, child in ipairs(PlayerGui:GetChildren()) do
        if _shouldSkipGui(child.Name) then pcall(function() child.Enabled = false end) end
    end
end

local function setupSkipLoad()
    if _skipLoadConn then _skipLoadConn:Disconnect() end
    _skipLoadConn = PlayerGui.ChildAdded:Connect(function(child)
        if not VD.SkipCutsceneLoad then return end
        local n = child.Name:lower()
        if n:find("load") or n:find("loading") or n:find("splash") then
            task.wait(0.05)
            pcall(function() child.Enabled = false end)
        end
    end)
end

-- ============================================================
-- DOUBLE DAMAGE GENERATOR (hookmetamethod)
-- ============================================================
local _oldNamecall = nil
local _nameCallSetup = false

local function SetupHooks()
    if _nameCallSetup then return end
    _nameCallSetup = true
    if not (hookmetamethod and getrawmetatable and setreadonly) then return end
    pcall(function()
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and method == "FireServer" then
                if VD.DoubleDamageGen then
                    local selfName = tostring(self):lower()
                    if selfName:find("breakgenevent") then
                        local args = {...}
                        local result = old(self, ...)
                        task.spawn(function()
                            for _ = 1, 3 do
                                task.wait(0.05)
                                pcall(function() old(self, table.unpack(args)) end)
                            end
                        end)
                        return result
                    end
                end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
        _oldNamecall = old
    end)
end
SetupHooks()

-- ============================================================
-- HITBOX EXPANDER
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not VD.HitboxExpander then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsKiller(p) and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local sz = VD.HitboxSize or 15
                local target = Vector3.new(sz, sz, sz)
                if hrp.Size ~= target then
                    pcall(function()
                        hrp.Size = target
                        hrp.Transparency = 0.9
                        hrp.Material = Enum.Material.ForceField
                        hrp.CanCollide = false
                    end)
                end
            end
        end
    end
end)

-- ============================================================
-- MASK SELECTION
-- ============================================================
local MaskGui = nil; local MaskKeyConn = nil
local MASK_DATA = {
    { arg="Alex",    label="Swan",    image="rbxassetid://15946083863",     key=Enum.KeyCode.One },
    { arg="Brandon", label="Panther", image="rbxassetid://111928367372122", key=Enum.KeyCode.Two },
    { arg="Cobra",   label="Cobra",   image="rbxassetid://15946288579",     key=Enum.KeyCode.Three },
    { arg="Rabbit",  label="Rabbit",  image="rbxassetid://103750154338014", key=Enum.KeyCode.Four },
    { arg="Richter", label="Rat",     image="rbxassetid://590245826",       key=Enum.KeyCode.Five },
    { arg="Tony",    label="Tiger",   image="rbxassetid://96793004678696",  key=Enum.KeyCode.Six },
}
local function FireMask(arg)
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes")
            :WaitForChild("Killers"):WaitForChild("Masked")
            :WaitForChild("Activatepower"):FireServer(arg)
    end)
end
local function CheckIsMasked()
    local sk = LocalPlayer:GetAttribute("SelectedKiller")
    if sk == nil then
        local v = LocalPlayer:FindFirstChild("SelectedKiller")
        if v then sk = v.Value end
    end
    return sk and tostring(sk):lower():find("masked") ~= nil
end
local function BuildMaskGui()
    if MaskGui and MaskGui.Parent then MaskGui:Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name = "VD_MaskSelection"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 60
    sg.Parent = (gethui and gethui()) or PlayerGui
    local root = Instance.new("Frame", sg)
    root.BackgroundTransparency = 1
    root.Size = UDim2.new(0, 230, 0, 40)
    root.Position = UDim2.new(0.5, -115, 0.16, 0)
    local hdr = Instance.new("Frame", root)
    hdr.Size = UDim2.new(1,0,0,34)
    hdr.BackgroundColor3 = Color3.fromRGB(22,22,28)
    hdr.BorderSizePixel = 0; hdr.ZIndex = 5
    Instance.new("UICorner", hdr).CornerRadius = UDim.new(0,8)
    local hs = Instance.new("UIStroke", hdr)
    hs.Color = Color3.fromRGB(255,153,204); hs.Thickness = 1; hs.Transparency = 0.45
    local tLbl = Instance.new("TextLabel", hdr)
    tLbl.Size = UDim2.new(1,-40,1,0); tLbl.Position = UDim2.new(0,8,0,0)
    tLbl.BackgroundTransparency = 1; tLbl.Text = "MASK SELECTION"
    tLbl.TextColor3 = Color3.fromRGB(255,153,204); tLbl.Font = Enum.Font.GothamBold
    tLbl.TextSize = 13; tLbl.ZIndex = 6; tLbl.TextXAlignment = Enum.TextXAlignment.Left
    local body = Instance.new("Frame", root)
    body.Size = UDim2.new(1,0,0,0); body.Position = UDim2.new(0,0,0,38)
    body.BackgroundColor3 = Color3.fromRGB(18,18,24); body.BorderSizePixel = 0; body.ZIndex = 5
    Instance.new("UICorner", body).CornerRadius = UDim.new(0,8)
    local bs = Instance.new("UIStroke", body)
    bs.Color = Color3.fromRGB(255,153,204); bs.Thickness = 1; bs.Transparency = 0.55
    local bp = Instance.new("UIPadding", body)
    bp.PaddingTop = UDim.new(0,6); bp.PaddingBottom = UDim.new(0,6)
    bp.PaddingLeft = UDim.new(0,6); bp.PaddingRight = UDim.new(0,6)
    local bLayout = Instance.new("UIListLayout", body)
    bLayout.Padding = UDim.new(0,4); bLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local sLbl = Instance.new("TextLabel", body)
    sLbl.LayoutOrder = 1; sLbl.Size = UDim2.new(1,0,0,14)
    sLbl.BackgroundTransparency = 1; sLbl.Text = "Active: None"
    sLbl.TextColor3 = Color3.fromRGB(90,240,140); sLbl.Font = Enum.Font.GothamBold
    sLbl.TextSize = 11; sLbl.TextXAlignment = Enum.TextXAlignment.Left
    local gc = Instance.new("Frame", body)
    gc.LayoutOrder = 2; gc.Size = UDim2.new(1,0,0,130)
    gc.BackgroundTransparency = 1; gc.ZIndex = 6
    local grid = Instance.new("UIGridLayout", gc)
    grid.CellSize = UDim2.new(0,62,0,62); grid.CellPadding = UDim2.new(0,5,0,5)
    grid.FillDirection = Enum.FillDirection.Horizontal
    grid.FillDirectionMaxCells = 3; grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local cards = {}
    local function resetStrokes()
        for _,d in pairs(cards) do d.Stroke.Color = Color3.fromRGB(55,55,65); d.Stroke.Transparency = 0.3 end
    end
    for i, mask in ipairs(MASK_DATA) do
        local card = Instance.new("ImageButton", gc)
        card.LayoutOrder = i; card.Size = UDim2.new(0,62,0,62)
        card.BackgroundColor3 = Color3.fromRGB(30,30,38); card.AutoButtonColor = false
        card.Image = mask.image; card.ScaleType = Enum.ScaleType.Fit; card.ZIndex = 7
        Instance.new("UICorner", card).CornerRadius = UDim.new(0,8)
        local cs = Instance.new("UIStroke", card)
        cs.Color = Color3.fromRGB(55,55,65); cs.Thickness = 1.5
        cs.Transparency = 0.3; cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        local nl = Instance.new("TextLabel", card)
        nl.Size = UDim2.new(1,0,0,14); nl.Position = UDim2.new(0,0,1,-14)
        nl.BackgroundColor3 = Color3.fromRGB(0,0,0); nl.BackgroundTransparency = 0.3
        nl.Text = mask.label; nl.TextColor3 = Color3.fromRGB(235,235,240)
        nl.Font = Enum.Font.GothamBold; nl.TextSize = 9; nl.ZIndex = 8
        Instance.new("UICorner", nl).CornerRadius = UDim.new(0,5)
        local function activate()
            FireMask(mask.arg); sLbl.Text = "Active: " .. mask.label
            resetStrokes(); cs.Color = Color3.fromRGB(255,153,204); cs.Transparency = 0
        end
        card.MouseButton1Click:Connect(activate)
        cards[mask.label] = {Stroke=cs}; mask._activate = activate
    end
    local deactBtn = Instance.new("TextButton", body)
    deactBtn.LayoutOrder = 3; deactBtn.Size = UDim2.new(1,0,0,26)
    deactBtn.BackgroundColor3 = Color3.fromRGB(178,42,58)
    deactBtn.Text = "[7] Deactivate"; deactBtn.TextColor3 = Color3.fromRGB(255,255,255)
    deactBtn.Font = Enum.Font.GothamBold; deactBtn.TextSize = 12; deactBtn.ZIndex = 6
    Instance.new("UICorner", deactBtn).CornerRadius = UDim.new(0,6)
    local function deactivate()
        FireMask("Richard"); sLbl.Text = "Active: None"; resetStrokes()
    end
    deactBtn.MouseButton1Click:Connect(deactivate)
    bLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        body.Size = UDim2.new(1,0,0, bLayout.AbsoluteContentSize.Y + 12)
    end)
    -- Drag
    local drag, ds, sp, mv = false, nil, nil, false
    hdr.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag=true; mv=false; ds=Vector2.new(inp.Position.X, inp.Position.Y); sp=root.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = Vector2.new(inp.Position.X, inp.Position.Y) - ds
            if d.Magnitude > 4 then mv = true end
            local vs = sg.AbsoluteSize; if vs.X <= 0 or vs.Y <= 0 then return end
            root.Position = UDim2.new(math.clamp(sp.X.Scale+d.X/vs.X,-0.1,1), 0, math.clamp(sp.Y.Scale+d.Y/vs.Y,0,0.9), 0)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) and drag then
            drag = false
        end
    end)
    local kc = UserInputService.InputBegan:Connect(function(inp, gp)
        if gp or not sg.Parent then return end
        if UserInputService:GetFocusedTextBox() then return end
        for _, m in ipairs(MASK_DATA) do if inp.KeyCode == m.key then m._activate(); return end end
        if inp.KeyCode == Enum.KeyCode.Seven then deactivate() end
        if inp.KeyCode == Enum.KeyCode.M then body.Visible = not body.Visible end
    end)
    sg.AncestryChanged:Connect(function(_, p) if not p and kc then kc:Disconnect() end end)
    MaskGui = sg
    if MaskKeyConn then MaskKeyConn:Disconnect() end
    MaskKeyConn = kc
end

local function ShowMaskGui()
    if not CheckIsMasked() then return false end
    BuildMaskGui(); return true
end
local function HideMaskGui()
    if MaskKeyConn then MaskKeyConn:Disconnect(); MaskKeyConn = nil end
    if MaskGui and MaskGui.Parent then MaskGui:Destroy(); MaskGui = nil end
end

-- ============================================================
-- VISUAL SETTINGS
-- ============================================================
local function applyVisualSettings()
    Lighting.GlobalShadows = not VD.NoShadow
    if VD.LowGraphics then
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    else
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
    end
    if VD.Fullbright then
        Lighting.Brightness = 2; Lighting.ClockTime = 14
        Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1)
    else
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime  = OriginalLighting.ClockTime
        Lighting.Ambient    = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    end
    if VD.NoFog then
        Lighting.FogEnd = 100000; Lighting.FogStart = 0
    else
        Lighting.FogEnd   = OriginalLighting.FogEnd
        Lighting.FogStart = OriginalLighting.FogStart
    end
    if VD.ReduceMap then
        pcall(function() setfpscap(30) end)
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        local desc = workspace:GetDescendants()
        task.spawn(function()
            for i, v in ipairs(desc) do
                pcall(function()
                    local cls = v.ClassName
                    if cls=="ParticleEmitter" or cls=="Trail" or cls=="Beam" or cls=="Smoke" or cls=="Fire"
                    or cls=="BloomEffect" or cls=="BlurEffect" or cls=="SunRaysEffect"
                    or cls=="ColorCorrectionEffect" or cls=="DepthOfFieldEffect" then
                        if v.Enabled then v.Enabled = false end
                    elseif cls=="SurfaceAppearance" then v:Destroy()
                    elseif v:IsA("BasePart") then
                        if v.Material ~= Enum.Material.SmoothPlastic then v.Material = Enum.Material.SmoothPlastic end
                        if v.CastShadow then v.CastShadow = false end
                    end
                end)
                if i%200==0 then task.wait() end
            end
        end)
        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") or v:IsA("Sky") then pcall(function() v:Destroy() end)
            elseif v:IsA("PostEffect") then pcall(function() v.Enabled = false end) end
        end
    else
        pcall(function() setfpscap(0) end)
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
    end
    if VD.RemoveVisualEffects then
        Lighting.FogStart = 9e9; Lighting.FogEnd = 9e9
        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Clouds") then
                pcall(function() v.Enabled = false end)
            end
        end
    end
end

-- Custom FOV
RunService:BindToRenderStep("VD_FOV", Enum.RenderPriority.Camera.Value+1, function()
    if VD.CustomFOV and workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = VD.FOVValue
    end
end)

-- ============================================================
-- FPS & PING COUNTER
-- ============================================================
local FPSFrame = nil; local FPSLabel = nil; local PingLabel = nil
local fpsCount = 0; local fpsTime = 0

local function createCounter()
    if FPSFrame then return end
    FPSFrame = Instance.new("ScreenGui")
    FPSFrame.Name = "VD_Counter"; FPSFrame.ResetOnSpawn = false
    FPSFrame.IgnoreGuiInset = true
    FPSFrame.Parent = (gethui and gethui()) or CoreGui
    local holder = Instance.new("Frame", FPSFrame)
    holder.Size = UDim2.new(0,130,0,46)
    holder.Position = UDim2.new(0.5,-65,0,8)
    holder.BackgroundColor3 = Color3.fromRGB(20,20,30)
    holder.BackgroundTransparency = 0.2
    holder.BorderSizePixel = 0
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", holder)
    stroke.Color = Color3.fromRGB(255,255,255); stroke.Thickness = 1; stroke.Transparency = 0.5
    FPSLabel = Instance.new("TextLabel", holder)
    FPSLabel.Size = UDim2.new(1,0,0.5,0)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.Font = Enum.Font.GothamBold; FPSLabel.TextSize = 13
    FPSLabel.TextColor3 = Color3.fromRGB(0,255,0); FPSLabel.Text = "FPS: --"
    PingLabel = Instance.new("TextLabel", holder)
    PingLabel.Size = UDim2.new(1,0,0.5,0); PingLabel.Position = UDim2.new(0,0,0.5,0)
    PingLabel.BackgroundTransparency = 1
    PingLabel.Font = Enum.Font.GothamBold; PingLabel.TextSize = 13
    PingLabel.TextColor3 = Color3.fromRGB(255,255,0); PingLabel.Text = "Ping: --ms"
    -- Drag
    local drag, ds, sp = false, nil, nil
    holder.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag=true; ds=Vector2.new(inp.Position.X, inp.Position.Y); sp=holder.Position
        end
    end)
    holder.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag=false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = Vector2.new(inp.Position.X, inp.Position.Y) - ds
            local vp = Camera.ViewportSize
            holder.Position = UDim2.new(sp.X.Scale+d.X/vp.X, 0, sp.Y.Scale+d.Y/vp.Y, 0)
        end
    end)
end

RunService.Heartbeat:Connect(function()
    if not VD.ShowFPS then return end
    fpsCount = fpsCount + 1
    local now = workspace.DistributedGameTime
    if now - fpsTime >= 1 then
        local fps = math.floor(fpsCount / math.max(now-fpsTime, 0.001))
        if FPSLabel then
            FPSLabel.Text = "FPS: " .. fps
            FPSLabel.TextColor3 = fps >= 55 and Color3.fromRGB(0,255,0) or fps >= 30 and Color3.fromRGB(255,255,0) or Color3.fromRGB(255,80,80)
        end
        local ping = 0
        pcall(function() ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
        if PingLabel then
            PingLabel.Text = "Ping: " .. math.floor(ping) .. "ms"
            PingLabel.TextColor3 = ping < 100 and Color3.fromRGB(0,255,0) or ping < 200 and Color3.fromRGB(255,255,0) or Color3.fromRGB(255,80,80)
        end
        fpsCount = 0; fpsTime = now
    end
end)

-- ============================================================
-- AVATAR COPY
-- ============================================================
local _originalDesc = nil
pcall(function()
    _originalDesc = Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
end)

local function applyAvatarByInput(input)
    input = tostring(input or ""):gsub("^%s+",""):gsub("%s+$","")
    if input == "" then return end
    task.spawn(function()
        local userId = nil
        if input:match("^%d+$") then
            userId = tonumber(input)
        else
            local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(input) end)
            if ok and id and id > 0 then userId = id
            else return end
        end
        local ok2, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
        if not ok2 or not desc then return end
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local ok3 = pcall(function() hum:ApplyDescription(desc) end)
        if not ok3 then
            -- Manual method
            local ok4, info = pcall(function() return Players:GetCharacterAppearanceInfoAsync(userId) end)
            if not ok4 or not info then return end
            local bc = char:FindFirstChildOfClass("BodyColors")
            if bc and info.bodyColors then
                pcall(function()
                    local b = info.bodyColors
                    if b.headColor3        then bc.HeadColor3      = b.headColor3        end
                    if b.torsoColor3       then bc.TorsoColor3     = b.torsoColor3       end
                    if b.leftArmColor3     then bc.LeftArmColor3   = b.leftArmColor3     end
                    if b.rightArmColor3    then bc.RightArmColor3  = b.rightArmColor3    end
                    if b.leftLegColor3     then bc.LeftLegColor3   = b.leftLegColor3     end
                    if b.rightLegColor3    then bc.RightLegColor3  = b.rightLegColor3    end
                end)
            end
            for _, asset in ipairs(info.assets or {}) do
                local atype = (asset.assetType and asset.assetType.name) or ""
                local id = tostring(asset.id)
                if atype == "Shirt" then
                    local old = char:FindFirstChildOfClass("Shirt"); if old then pcall(function() old:Destroy() end) end
                    pcall(function() local s=Instance.new("Shirt",char); s.ShirtTemplate="rbxassetid://"..id end)
                elseif atype == "Pants" then
                    local old = char:FindFirstChildOfClass("Pants"); if old then pcall(function() old:Destroy() end) end
                    pcall(function() local p=Instance.new("Pants",char); p.PantsTemplate="rbxassetid://"..id end)
                elseif atype == "Face" then
                    local head = char:FindFirstChild("Head")
                    local face = head and head:FindFirstChild("face")
                    if face and face:IsA("Decal") then pcall(function() face.Texture = "rbxassetid://"..id end) end
                end
            end
        end
    end)
end

-- ============================================================
-- LOAD FLUENTPRO
-- ============================================================
print("[VD Hub] Loading UI...")
pcall(function()
    if not getgenv().protectgui then getgenv().protectgui = function(g) return g end end
    if not getgenv().syn then getgenv().syn = {protect_gui=function(g) return g end} end
end)

local _src = nil
local _ok1 = pcall(function()
    _src = game:HttpGet("https://raw.githubusercontent.com/AlDev14/modded-ui/refs/heads/main/FluentUI.lua")
end)
if not _ok1 or not _src or _src=="" then warn("[VD Hub] HttpGet failed"); return end

local _fn, _err = loadstring(_src)
if not _fn then warn("[VD Hub] loadstring error: "..tostring(_err)); return end

local ok, Fluent = pcall(_fn)
if not ok or not Fluent then warn("[VD Hub] FluentPro error: "..tostring(Fluent)); return end
print("[VD Hub] UI loaded OK")
print("[VD Hub] Fluent type=" .. type(Fluent))
print("[VD Hub] CreateWindow=" .. tostring(type(Fluent.CreateWindow)))

-- ============================================================
-- UI - WINDOW
-- ============================================================
local Window = Fluent:CreateWindow({
    Title    = "VD Hub",
    SubTitle = "Violent District",
    TabWidth = 140,
    Size     = UDim2.fromOffset(580, 420),
    Theme    = "Darker",
    Acrylic  = false,
    Search   = true,
})
if not Window then warn("[VD Hub] Window failed"); return end
print("[VD Hub] Window OK type=" .. type(Window))
print("[VD Hub] AddTab=" .. tostring(type(Window.AddTab)))

local tabSurv   = Window:AddTab({ Title="Survivor",    Icon="solar/user-bold" })
local tabKiller = Window:AddTab({ Title="Killer",      Icon="solar/swords-bold" })
local tabAim    = Window:AddTab({ Title="Aim",         Icon="solar/crosshair-bold" })
local tabESP    = Window:AddTab({ Title="ESP",         Icon="solar/eye-bold" })
local tabMisc   = Window:AddTab({ Title="Misc",        Icon="solar/widget-bold" })
local tabUI     = Window:AddTab({ Title="UI Settings", Icon="solar/settings-bold" })

print("[VD Hub] tabSurv=" .. tostring(tabSurv~=nil))
print("[VD Hub] tabKiller=" .. tostring(tabKiller~=nil))
print("[VD Hub] tabAim=" .. tostring(tabAim~=nil))
if not (tabSurv and tabKiller and tabAim and tabESP and tabMisc and tabUI) then
    warn("[VD Hub] Tabs failed"); return
end
print("[VD Hub] All tabs OK")

local function N(t,c,d,tp) Fluent:Notify({Title=t,Content=c,Duration=d or 2,Type=tp or "Info"}) end

-- ============================================================
-- UI - SURVIVOR
-- ============================================================
local secSkill = tabSurv:AddSection("Skill Check", "solar/check-circle-bold")
print("[VD Hub] secSkill=" .. tostring(secSkill~=nil) .. " AddToggle=" .. tostring(secSkill and type(secSkill.AddToggle)))
secSkill:AddToggle("SkillCheck", {
    Title="Auto Skill Check", Default=VD.AutoSkillcheck,
    Callback=function(v) VD.AutoSkillcheck=v; if v then startSkillCheck() else if SkillConn then SkillConn:Disconnect() end end end
})
secSkill:AddDropdown("SkillCheckMode", {
    Title="Mode", Values={"Instant","Legit","Random"}, Default=2,
    Callback=function(v) VD.AutoSkillcheckMode=v end
})

local secParry = tabSurv:AddSection("Auto Parry")
secParry:AddToggle("Parry_Enable", {
    Title="Auto Parry", Default=VD.Surv_AutoParry,
    Callback=function(v) VD.Surv_AutoParry=v end
})
secParry:AddSlider("Parry_Range", {
    Title="Parry Range", Min=5, Max=30, Default=VD.Surv_ParryRange, Rounding=1,
    Callback=function(v) VD.Surv_ParryRange=v end
})
secParry:AddToggle("Parry_Safety", {
    Title="Safety Mode", Default=VD.Surv_ParrySafety,
    Callback=function(v) VD.Surv_ParrySafety=v end
})
secParry:AddToggle("Parry_Aggressive", {
    Title="Aggressive", Default=VD.Surv_ParryAggressive,
    Callback=function(v) VD.Surv_ParryAggressive=v end
})
secParry:AddSlider("Parry_Face", {
    Title="Face Threshold", Min=0, Max=1, Default=VD.Surv_ParryFace, Rounding=0.1,
    Callback=function(v) VD.Surv_ParryFace=v end
})

local secMiscSurv = tabSurv:AddSection("Survivor Misc")
secMiscSurv:AddToggle("SkipCutscene", {
    Title="Skip Cutscene", Default=VD.SkipCutscene,
    Callback=function(v) VD.SkipCutscene=v; if v then setupSkipCutscene() else if _skipConn then _skipConn:Disconnect() end end end
})
secMiscSurv:AddToggle("SkipLoadScreen", {
    Title="Skip Loading Screen", Default=VD.SkipCutsceneLoad,
    Callback=function(v) VD.SkipCutsceneLoad=v; if v then setupSkipLoad() else if _skipLoadConn then _skipLoadConn:Disconnect() end end end
})
secMiscSurv:AddToggle("AutoCrouch", {
    Title="Auto Dodge/Crouch", Default=VD.Surv_AutoCrouch,
    Callback=function(v) VD.Surv_AutoCrouch=v end
})
secMiscSurv:AddToggle("AutoDropPallet", {
    Title="Auto Drop Pallet", Default=VD.Surv_AutoDropPallet,
    Callback=function(v) VD.Surv_AutoDropPallet=v end
})
secMiscSurv:AddSlider("AutoDropPalletDist", {
    Title="Drop Distance", Min=2, Max=15, Default=VD.Surv_AutoDropPalletDist, Rounding=1,
    Callback=function(v) VD.Surv_AutoDropPalletDist=v end
})
secMiscSurv:AddToggle("AntiKnock", {
    Title="Anti Knock", Default=VD.Surv_AntiKnock,
    Callback=function(v) VD.Surv_AntiKnock=v end
})
secMiscSurv:AddToggle("FastVault", {
    Title="Fast Vault", Default=VD.UnlimitedVault,
    Callback=function(v) if v then EnableUnlimitedVault() else DisableUnlimitedVault() end end
})
secMiscSurv:AddToggle("MoonwalkToggle", {
    Title="Moonwalk V3", Default=VD.Moonwalk_Enabled,
    Callback=function(v)
        VD.Moonwalk_Enabled=v; MoonwalkEnabled=v
        if v then createMoonwalkGui(); startMoonwalkInternal()
        else destroyMoonwalkGui(); stopMoonwalkInternal() end
    end
})

-- ============================================================
-- UI - KILLER
-- ============================================================
local secKillerFeat = tabKiller:AddSection("Killer Features")
secKillerFeat:AddToggle("UnlockCarry", {
    Title="Unlock Skills While Carrying", Default=VD.UnlockSkillsCarry,
    Callback=function(v) VD.UnlockSkillsCarry=v end
})
secKillerFeat:AddToggle("DoubleDamage", {
    Title="Double Damage Generator", Default=VD.DoubleDamageGen,
    Callback=function(v) VD.DoubleDamageGen=v end
})
secKillerFeat:AddToggle("AutoStalkToggle", {
    Title="Auto Stalk", Default=VD.AutoStalk,
    Callback=function(v) VD.AutoStalk=v end
})

local secSpear = tabKiller:AddSection("Spear & Veil Aim")
secSpear:AddDropdown("AttackAimMode", {
    Title="Aimlock Mode", Values={"Normal","Spear"}, Default=1,
    Callback=function(v) VD.SpearAimEnabled=(v=="Spear") end
})
secSpear:AddSlider("SpearGravity", {
    Title="Spear Gravity", Min=10, Max=200, Default=VD.SpearGravity, Rounding=0,
    Callback=function(v) VD.SpearGravity=v end
})
secSpear:AddSlider("SpearSpeed", {
    Title="Spear Speed", Min=20, Max=300, Default=VD.SpearSpeed, Rounding=0,
    Callback=function(v) VD.SpearSpeed=v end
})
secSpear:AddToggle("VeilToggle", {
    Title="Silent Aim Veil", Default=VD.Veil_SilentAim,
    Callback=function(v) VD.Veil_SilentAim=v end
})
secSpear:AddToggle("VeilFOV", {
    Title="Veil FOV Circle", Default=VD.Veil_ShowFOV,
    Callback=function(v) VD.Veil_ShowFOV=v end
})
secSpear:AddSlider("VeilFOVRadius", {
    Title="Veil FOV Radius", Min=30, Max=500, Default=VD.Veil_FOV, Rounding=5,
    Callback=function(v) VD.Veil_FOV=v end
})

local secHitbox = tabKiller:AddSection("Hitbox Expander")
secHitbox:AddToggle("HitboxExpToggle", {
    Title="Killer Hitbox", Default=VD.HitboxExpander,
    Callback=function(v) VD.HitboxExpander=v end
})
secHitbox:AddSlider("HitboxSizeSlider", {
    Title="Hitbox Size", Min=2, Max=50, Default=VD.HitboxSize, Rounding=0,
    Callback=function(v) VD.HitboxSize=v end
})

local secMaskSec = tabKiller:AddSection("Mask Selection")
secMaskSec:AddToggle("MaskSelToggle", {
    Title="Mask Selection GUI", Default=VD.MaskSelection_Enabled,
    Callback=function(v) VD.MaskSelection_Enabled=v; if v then ShowMaskGui() else HideMaskGui() end end
})
secMaskSec:AddParagraph({Title="Keys", Content="1-6: mask | 7: deactivate | M: minimize"})

-- ============================================================
-- UI - AIM
-- ============================================================
local secToF = tabAim:AddSection("Silent Aim ToF")
secToF:AddToggle("SA_ToF", {
    Title="Silent Aim ToF", Default=VD.Pistol_SilentAim,
    Callback=function(v) VD.Pistol_SilentAim=v end
})
secToF:AddToggle("SA_BlockKnocked", {
    Title="Block when Knocked", Default=VD.Pistol_BlockKnocked,
    Callback=function(v) VD.Pistol_BlockKnocked=v end
})
secToF:AddToggle("SA_LockAim", {
    Title="Lock Aim", Default=VD.Pistol_LockAim,
    Callback=function(v) VD.Pistol_LockAim=v end
})
secToF:AddToggle("SA_FOVMode", {
    Title="FOV Mode", Default=VD.Pistol_FOVMode,
    Callback=function(v) VD.Pistol_FOVMode=v end
})
secToF:AddToggle("SA_ShowFOV", {
    Title="Show FOV Circle", Default=VD.Pistol_ShowFOV,
    Callback=function(v) VD.Pistol_ShowFOV=v end
})
secToF:AddSlider("SA_FOVRadius", {
    Title="FOV Radius", Min=30, Max=500, Default=VD.Pistol_FOV, Rounding=5,
    Callback=function(v) VD.Pistol_FOV=v end
})
secToF:AddDropdown("SA_Target", {
    Title="Target", Values={"Killer","Survivor","SCP"}, Default=VD.Pistol_Target,
    Callback=function(v) VD.Pistol_Target=v end
})
secToF:AddDropdown("SA_TargetPart", {
    Title="Target Part", Values={"Torso","Head","Root"}, Default=VD.Pistol_TargetPart,
    Callback=function(v) VD.Pistol_TargetPart=v end
})
secToF:AddToggle("SA_HideLaser", {
    Title="Hide Laser", Default=VD.Pistol_HideLaser,
    Callback=function(v) VD.Pistol_HideLaser=v; if pistolLaser then pistolLaser.Transparency=v and 1 or 0 end end
})

-- ============================================================
-- UI - ESP
-- ============================================================
local secESP = tabESP:AddSection("ESP Settings")
secESP:AddToggle("ESP_Main", {
    Title="Enable ESP", Default=VD.ESP_Enabled,
    Callback=function(v) VD.ESP_Enabled=v; if not v then clearESP() end end
})
secESP:AddToggle("ESP_Surv", { Title="Survivor", Default=VD.ESP_Survivor, Callback=function(v) VD.ESP_Survivor=v end })
secESP:AddToggle("ESP_Kill", { Title="Killer", Default=VD.ESP_Killer, Callback=function(v) VD.ESP_Killer=v end })
secESP:AddToggle("ESP_Gen",  { Title="Generator", Default=VD.ESP_Generator, Callback=function(v) VD.ESP_Generator=v end })
secESP:AddToggle("ESP_Pal",  { Title="Pallet", Default=VD.ESP_Pallet, Callback=function(v) VD.ESP_Pallet=v end })
secESP:AddToggle("ESP_Win",  { Title="Window (Vault)", Default=VD.ESP_Window, Callback=function(v) VD.ESP_Window=v end })
secESP:AddToggle("ESP_Gate", { Title="Gate", Default=VD.ESP_Gate, Callback=function(v) VD.ESP_Gate=v end })
secESP:AddToggle("ESP_SCP",  { Title="SCP / Zombie", Default=VD.ESP_SCP, Callback=function(v) VD.ESP_SCP=v end })
secESP:AddSlider("ESP_Dist", {
    Title="Max Distance", Min=20, Max=10000, Default=VD.ESP_Distance, Rounding=0,
    Callback=function(v) VD.ESP_Distance=v end
})
secESP:AddButton({ Title="Refresh ESP", Callback=function() _espLastUpdate=0; pcall(updateESP) end })

-- ============================================================
-- UI - MISC
-- ============================================================
local secVisual = tabMisc:AddSection("Visual Settings")
secVisual:AddToggle("NoShadow", { Title="No Shadow", Default=VD.NoShadow, Callback=function(v) VD.NoShadow=v; applyVisualSettings() end })
secVisual:AddToggle("LowGfx", { Title="Low Graphics", Default=VD.LowGraphics, Callback=function(v) VD.LowGraphics=v; applyVisualSettings() end })
secVisual:AddToggle("Fullbright", { Title="Fullbright", Default=VD.Fullbright, Callback=function(v) VD.Fullbright=v; applyVisualSettings() end })
secVisual:AddToggle("NoFog", { Title="No Fog", Default=VD.NoFog, Callback=function(v) VD.NoFog=v; applyVisualSettings() end })
secVisual:AddToggle("PotatoMode", { Title="Potato Mode", Default=VD.ReduceMap, Callback=function(v) VD.ReduceMap=v; applyVisualSettings() end })
secVisual:AddToggle("RemoveVFX", { Title="Remove Visual Effects", Default=VD.RemoveVisualEffects, Callback=function(v) VD.RemoveVisualEffects=v; applyVisualSettings() end })
secVisual:AddToggle("CustomFOVToggle", { Title="Custom FOV", Default=VD.CustomFOV, Callback=function(v) VD.CustomFOV=v end })
secVisual:AddSlider("FOVSlider", { Title="FOV Value", Min=60, Max=120, Default=VD.FOVValue, Rounding=1, Callback=function(v) VD.FOVValue=v end })

local secPerf = tabMisc:AddSection("Performance")
secPerf:AddToggle("ShowFPSToggle", {
    Title="Show FPS & Ping Counter", Default=false,
    Callback=function(v)
        VD.ShowFPS=v; VD.ShowPing=v
        if v then if not FPSFrame then createCounter() end
        else if FPSFrame then FPSFrame:Destroy(); FPSFrame=nil; FPSLabel=nil; PingLabel=nil end end
    end
})

local secAvatar = tabMisc:AddSection("Avatar Copy")
local _avatarInput = ""
secAvatar:AddInput("AvatarInput", {
    Title="Username / User ID", Placeholder="e.g. Roblox",
    Callback=function(v) _avatarInput=v end, Finished=true,
})
secAvatar:AddButton({ Title="Apply Avatar", Callback=function() applyAvatarByInput(_avatarInput) end })
secAvatar:AddButton({ Title="Restore Avatar", Callback=function()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum and _originalDesc then pcall(function() hum:ApplyDescription(_originalDesc) end) end
end})
secAvatar:AddParagraph({Title="Info", Content="Client-side only. Target tidak perlu di server yang sama."})

-- ============================================================
-- UI SETTINGS
-- ============================================================
pcall(function()
    if Fluent.InterfaceManager and tabUI then
        Fluent.InterfaceManager:SetLibrary(Fluent)
        Fluent.InterfaceManager:SetFolder("VDHub/Interface")
        local ok, err = pcall(function() Fluent.InterfaceManager:BuildInterfaceSection(tabUI) end)
        if ok then pcall(function() Fluent.InterfaceManager:LoadSettings() end) end
    end
end)
pcall(function()
    if Fluent.SaveManager and tabUI then
        Fluent.SaveManager:SetLibrary(Fluent)
        Fluent.SaveManager:SetFolder("VDHub/Config")
        Fluent.SaveManager:IgnoreThemeSettings()
        local ok2 = pcall(function() Fluent.SaveManager:BuildConfigSection(tabUI) end)
        if ok2 then pcall(function() Fluent.SaveManager:LoadAutoloadConfig() end) end
    end
end)

-- ============================================================
-- FINISH
-- ============================================================
    local function createFloatingButton()
        Fluent.FloatingButtonManager:SetLibrary(Fluent)

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "WisnuHub_FloatingBtn"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = CoreGui

        local btn = Instance.new("ImageButton")
        btn.Size = UDim2.new(0, 50, 0, 50)
        btn.AnchorPoint = Vector2.new(0, 0)
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.Parent = screenGui

        local viewport = Camera.ViewportSize
        btn.Position = UDim2.new(0, viewport.X - 50 - 16, 0, viewport.Y - 50 - 16)

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundTransparency = 1
        bg.BorderSizePixel = 0
        bg.Parent = btn

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = bg

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.5
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 1
        stroke.Parent = bg

        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 32, 0, 32)
        icon.Position = UDim2.new(0.5, -16, 0.5, -16)
        icon.BackgroundTransparency = 1
        icon.Image = "rbxassetid://80668677085388"
        icon.ScaleType = Enum.ScaleType.Fit
        icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
        icon.Parent = bg

        local dragging = false
        local dragStartMouse = Vector2.new()
        local dragStartPos = Vector2.new()

        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStartMouse = input.Position
                dragStartPos = Vector2.new(btn.Position.X.Offset, btn.Position.Y.Offset)
            end
        end)

        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = input.Position - dragStartMouse
                local newX = math.clamp(dragStartPos.X + delta.X, 0, Camera.ViewportSize.X - btn.Size.X.Offset)
                local newY = math.clamp(dragStartPos.Y + delta.Y, 0, Camera.ViewportSize.Y - btn.Size.Y.Offset)
                btn.Position = UDim2.new(0, newX, 0, newY)
            end
        end)

        btn.MouseButton1Click:Connect(function()
            if Window.Root.Visible then
                Window:Minimize()
            else
                Window:Show()
            end
        end)

        pcall(function()
            Fluent.FloatingButtonManager:AddButton("WisnuHubBtn", btn, false, true)
        end)
    end
    createFloatingButton()

print("[VD Hub] Ready!")
N("VD Hub", "Violent District loaded!", 4, "Success")
