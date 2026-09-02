-- ============================================================
--  STEAL AN EGG — Rebuild v2.0
--  Clean architecture, no external dependencies
-- ============================================================

-- ============================================================
-- SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")
local LocalPlayer       = Players.LocalPlayer

-- ============================================================
-- MODULE LOADER
-- ============================================================
local EggState, PlotState, Assets, RarityModule, AreaEggSlotIdentity, GameRemotes
local ModulesLoaded = false

local function tryRequire(...)
    for _, path in ipairs({...}) do
        local ok, result = pcall(function()
            local cur = ReplicatedStorage
            for seg in string.gmatch(path, "[^.]+") do
                cur = cur:FindFirstChild(seg)
                if not cur then return nil end
            end
            return require(cur)
        end)
        if ok and result then return result end
    end
    return nil
end

local function loadModules()
    if ModulesLoaded then return true end
    EggState            = tryRequire("Client.EggState",  "Shared.EggState")
    PlotState           = tryRequire("Client.PlotState", "Shared.PlotState")
    Assets              = tryRequire("Data.Assets",      "Shared.Assets", "Assets")
    RarityModule        = tryRequire("Data.Rarity",      "Shared.Rarity", "Rarity")
    AreaEggSlotIdentity = tryRequire("Shared.Util.AreaEggSlotIdentity", "Util.AreaEggSlotIdentity")
    GameRemotes         = tryRequire("Shared.Remotes",   "Remotes")
    ModulesLoaded       = EggState ~= nil and PlotState ~= nil
    return ModulesLoaded
end

-- ============================================================
-- STATE
-- ============================================================
local State = {
    -- Farm
    running           = false,
    busy              = false,
    stealCount        = 0,
    lockedRecord      = nil,
    -- Movement
    speed             = 120,
    antiGuard         = true,
    -- Farm rarity filter
    targetRarities    = {},
    minEarningRate    = 0,
    minModelWeight    = 0,
    maxModelWeight    = 999999999,
    -- Float
    floatEnabled      = false,
    floatHeight       = 3,
    -- Animation
    animEnabled       = true,
    -- Auto Place (independent loop)
    placeEnabled      = false,
    placeInterval     = 5,
    placeMinRarity    = "All",
    -- Auto Hatch (independent loop)
    hatchEnabled      = false,
    hatchInterval     = 3,
    -- Auto Sell (independent loop)
    sellEnabled       = false,
    sellInterval      = 5,
    sellAll           = false,
    sellMaxRarity     = "Epic",
    -- Bat Aura (independent loop)
    batAura           = false,
    batInterval       = 0.1,
    -- ESP
    espEnabled        = false,
}

-- Base teleport koordinat
local START_POS = Vector3.new(547.89, 70.58, -357.39)

-- ============================================================
-- HELPERS
-- ============================================================
local function root()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function hum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function formatNumber(n)
    n = tonumber(n) or 0
    if n >= 1e9  then return string.format("%.1fB", n/1e9)
    elseif n >= 1e6 then return string.format("%.1fM", n/1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
    else return tostring(math.floor(n)) end
end

-- ============================================================
-- ASSET HELPERS
-- ============================================================
local function getAssetData(record)
    if not Assets or not record or not record.AssetCategory then return {} end
    local ok, d = pcall(function()
        return (Assets.Directory or Assets)[record.AssetCategory] or {}
    end)
    return ok and d or {}
end

local function getEarningRate(record)
    return tonumber(getAssetData(record).EarningRate) or 0
end

local function getModelWeight(record)
    return tonumber(getAssetData(record).ModelWeight) or 0
end

local function getRarityName(record)
    local d = getAssetData(record)
    return (d.Rarity and d.Rarity._id) or "Unknown"
end

local function getRarityColor(record)
    local d = getAssetData(record)
    if d.Rarity and typeof(d.Rarity.Color) == "Color3" then
        return d.Rarity.Color
    end
    if RarityModule and RarityModule.Rarities then
        local rn = d.Rarity and d.Rarity._id
        local rm = rn and RarityModule.Rarities[rn]
        if rm and typeof(rm.Color) == "Color3" then return rm.Color end
    end
    return Color3.fromRGB(255, 255, 255)
end

local function getRarityNumber(record)
    local d = getAssetData(record)
    if d.Rarity and d.Rarity.RarityNumber then return d.Rarity.RarityNumber end
    if RarityModule and RarityModule.Rarities then
        local rn = d.Rarity and d.Rarity._id
        local rm = rn and RarityModule.Rarities[rn]
        if rm then return rm.RarityNumber or 0 end
    end
    return 0
end

local function getRarityNumberByName(name)
    if name == "All" then return -1 end
    if RarityModule and RarityModule.Rarities and RarityModule.Rarities[name] then
        return RarityModule.Rarities[name].RarityNumber or 1
    end
    local map = {
        Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6,
        SuperRare=7, Exotic=8, Limited=9, Divine=10, Secret=11, Titan=12,
        Cosmic=13, Celestial=14, Transcendent=15, Prismatic=16, Rainbow=17,
        Eternal=18, Brainrot=19, Mythical=20, Exclusive=21
    }
    return map[name] or 1
end

-- ============================================================
-- RARITY FILTER
-- ============================================================
local function isRarityAllowed(record)
    local t = State.targetRarities
    if not t then return true end
    local hasAny = false
    if type(t) == "table" then
        for _ in pairs(t) do hasAny = true; break end
    end
    if not hasAny then return true end

    local name = getRarityName(record)
    if not name or name == "Unknown" then return true end -- unknown = skip filter

    -- Debug: print sekali per uid baru
    -- print("[RarityFilter] egg=" .. tostring(record.AssetCategory) .. " rarity=" .. name)

    -- VVind multi-dropdown return {[name]=true}
    if t[name] == true then return true end
    -- Case-insensitive fallback
    local nameLower = name:lower()
    for k, v in pairs(t) do
        if v == true and type(k) == "string" and k:lower() == nameLower then
            return true
        end
    end
    -- Array fallback
    for _, v in ipairs(t) do
        if type(v) == "string" and v:lower() == nameLower then return true end
    end
    return false
end

local function isValueAllowed(record)
    if State.minEarningRate > 0 and getEarningRate(record) < State.minEarningRate then
        return false
    end
    local w = getModelWeight(record)
    if State.minModelWeight > 0 and w < State.minModelWeight then return false end
    if w > State.maxModelWeight then return false end
    return true
end

-- ============================================================
-- HUMANOID BYPASS — tanpa clone/destroy
-- Pakai WalkSpeed Heartbeat + re-detect kalau di-reset game
-- ============================================================
local _speedConn = nil
local _camConn   = nil

local function doHumanoidBypass()
    local char = LocalPlayer.Character
    if not char then char = LocalPlayer.CharacterAdded:Wait() end

    local origHum  = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not origHum or not rootPart then return end

    -- Teleport ke StartPosition
    pcall(function()
        rootPart.CFrame                  = CFrame.new(START_POS)
        rootPart.AssemblyLinearVelocity  = Vector3.new(0, 35, 0)
        rootPart.AssemblyAngularVelocity = Vector3.zero
    end)

    -- Set WalkSpeed via Heartbeat (re-set tiap frame kalau game reset)
    if _speedConn then _speedConn:Disconnect() end
    _speedConn = RunService.Heartbeat:Connect(function()
        if not State.running then return end
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h and h.WalkSpeed ~= State.speed then
            h.WalkSpeed = State.speed
        end
    end)

    -- Camera lock
    if _camConn then _camConn:Disconnect() end
    _camConn = RunService.Heartbeat:Connect(function()
        local c = LocalPlayer.Character
        if not c then return end
        local h2 = c:FindFirstChildOfClass("Humanoid")
        if h2 then
            pcall(function() Workspace.CurrentCamera.CameraSubject = h2 end)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    if State.running then
        task.wait(0.3)
        doHumanoidBypass()
    end
end)

-- ============================================================
-- FLOAT SYSTEM
-- ============================================================
local _floatConn = nil
local function updateFloat()
    if _floatConn then _floatConn:Disconnect(); _floatConn = nil end
    if not State.floatEnabled then return end
    _floatConn = RunService.Heartbeat:Connect(function()
        if not State.floatEnabled then return end
        local c = LocalPlayer.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        -- Raycast ke bawah cari ground
        local origin    = hrp.Position
        local direction = Vector3.new(0, -50, 0)
        local params    = RaycastParams.new()
        params.FilterDescendantsInstances = {c}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local result = Workspace:Raycast(origin, direction, params)
        local groundY = result and result.Position.Y or (origin.Y - 3)
        local targetY = groundY + State.floatHeight
        -- Lock Y, cancel vertical velocity
        if math.abs(hrp.Position.Y - targetY) > 0.1 then
            hrp.CFrame = CFrame.new(hrp.Position.X, targetY, hrp.Position.Z)
                * CFrame.fromMatrix(Vector3.zero, hrp.CFrame.RightVector, Vector3.new(0,1,0))
        end
        local vel = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
    end)
end

-- ============================================================
-- ANIMATION TOGGLE
-- ============================================================
local _animTracks = {}
local function stopAllAnims()
    local c = LocalPlayer.Character
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        track:Stop(0)
        table.insert(_animTracks, track)
    end
    -- Animator juga
    local animator = hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            track:Stop(0)
            table.insert(_animTracks, track)
        end
    end
end

local function resumeAllAnims()
    for _, track in ipairs(_animTracks) do
        pcall(function() track:Play() end)
    end
    _animTracks = {}
end

local function updateAnim()
    if State.animEnabled then
        resumeAllAnims()
    else
        stopAllAnims()
    end
end
-- ============================================================
local function walkTo(goal, timeout, isReturning)
    local h2 = hum()
    local r  = root()
    if not h2 or not r then return false end
    if typeof(goal) == "Instance" then goal = goal.Position end

    timeout = timeout or 20
    local targetDist = isReturning and 2 or 4
    local speed      = isReturning and (State.antiGuard and 1000 or State.speed) or State.speed

    if (r.Position - goal).Magnitude <= targetDist then
        h2.WalkSpeed = 16; return true
    end

    h2.WalkSpeed = speed
    h2:MoveTo(goal)

    local t0       = workspace.DistributedGameTime
    local lastPos  = r.Position
    local stuckT   = t0

    while workspace.DistributedGameTime - t0 < timeout and State.running do
        task.wait(0.02)
        r  = root(); h2 = hum()
        if not r or not h2 then break end

        local dist = (r.Position - goal).Magnitude

        if dist <= targetDist then
            h2.WalkSpeed = 0
            h2:Move(Vector3.zero, false)
            r.AssemblyLinearVelocity  = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
            -- Hard snap ke base saat returning
            if isReturning then
                pcall(function() r.CFrame = CFrame.new(START_POS) end)
            end
            break
        end

        -- Brake
        local brake = math.clamp(speed * 0.3, 15, 80)
        if dist <= brake then
            h2.WalkSpeed = math.max(16, speed * (dist/brake)^2)
        else
            h2.WalkSpeed = speed
        end
        h2:MoveTo(goal)

        -- Stuck detection
        local now = workspace.DistributedGameTime
        if now - stuckT >= 2 then
            if (r.Position - lastPos).Magnitude < 0.5 then
                h2:MoveTo(goal)
                h2.Jump = true
            end
            lastPos = r.Position
            stuckT  = now
        end
    end

    h2 = hum()
    if h2 then h2.WalkSpeed = 16 end
    return true
end

-- ============================================================
-- EGG FINDER
-- ============================================================
local function findBestEgg()
    if not EggState then return nil, nil end
    local ok, fieldEggs = pcall(function() return EggState.ReadFieldEggs() end)
    if not ok or not fieldEggs or not fieldEggs.Records then return nil, nil end

    local r = root()
    if not r then return nil, nil end

    -- Coba locked record dulu
    if State.lockedRecord then
        for _, rec in ipairs(fieldEggs.Records) do
            if rec.Uid == State.lockedRecord.Uid then
                if isRarityAllowed(rec) and isValueAllowed(rec) then
                    local model = Workspace:FindFirstChild("AreaEggSlotsClient", true)
                        and Workspace.AreaEggSlotsClient:FindFirstChild(rec.Uid)
                        or Workspace:FindFirstChild(rec.Uid, true)
                    if model then return rec, model end
                end
                break
            end
        end
        State.lockedRecord = nil
    end

    local bestRec, bestModel, bestDist = nil, nil, math.huge

    for _, rec in ipairs(fieldEggs.Records) do
        if not isRarityAllowed(rec) then continue end
        if not isValueAllowed(rec)  then continue end

        local model = Workspace:FindFirstChild("AreaEggSlotsClient", true)
            and Workspace.AreaEggSlotsClient:FindFirstChild(rec.Uid)
            or Workspace:FindFirstChild(rec.Uid, true)

        if model then
            local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local d = (part.Position - r.Position).Magnitude
                if d < bestDist then
                    bestDist  = d
                    bestRec   = rec
                    bestModel = model
                end
            end
        end
    end

    if bestRec then State.lockedRecord = bestRec end
    return bestRec, bestModel
end

-- ============================================================
-- AUTO PLACE
-- ============================================================
-- ============================================================
-- AUTO PLACE — independent loop
-- ============================================================
local function runAutoPlace()
    if not EggState or not PlotState then return end
    pcall(function()
        local myPlot = PlotState.ResolvePlot()
        if not myPlot or not myPlot.CenterPoint or not myPlot.PetArea then
            warn("[AutoPlace] ResolvePlot gagal / PetArea/CenterPoint nil")
            return
        end

        -- LocalCFrame = posisi PetArea relatif ke CenterPoint
        local localCFrame = myPlot.CenterPoint.CFrame:ToObjectSpace(
            CFrame.new(myPlot.PetArea.Position)
        )

        local net = ReplicatedStorage:FindFirstChild("Packages")
            and ReplicatedStorage.Packages:FindFirstChild("Networking")
        local placeRemote = net and net:FindFirstChild("RF/EggWorld/AskPlaceEgg")

        if not placeRemote then
            warn("[AutoPlace] RF/EggWorld/AskPlaceEgg not found")
            return
        end

        local ok, owned = pcall(function() return EggState.ReadOwnedEgg() end)
        if not ok or type(owned) ~= "table" or #owned == 0 then
            print("[AutoPlace] owned egg kosong:", ok, type(owned))
            return
        end

        local minRarNum = getRarityNumberByName(State.placeMinRarity)
        local placed, skipped, failed = 0, 0, 0

        for _, rec in ipairs(owned) do
            if not rec.Uid then continue end
            if minRarNum > 0 and getRarityNumber(rec) < minRarNum then
                skipped += 1
                continue
            end

            local ok3, res = pcall(function()
                return placeRemote:InvokeServer({ Uid = rec.Uid, LocalCFrame = localCFrame })
            end)

            if ok3 and res == true then
                placed += 1
            else
                -- fallback PlantEgg
                local ok4 = pcall(function() EggState.PlantEgg(rec.Uid, localCFrame) end)
                if ok4 then placed += 1 else failed += 1 end
            end
            task.wait(0.05)
        end

        print(string.format("[AutoPlace] placed=%d skipped=%d failed=%d", placed, skipped, failed))
    end)
end

task.spawn(function()
    while true do
        task.wait(State.placeInterval)
        if State.placeEnabled then
            if not EggState then loadModules() end
            pcall(runAutoPlace)
        end
    end
end)

-- ============================================================
-- AUTO HATCH — independent loop
-- ============================================================
local function runAutoHatch()
    if not EggState then return end
    pcall(function()
        local EggWorld = GameRemotes and GameRemotes.EggWorld
        local ok, owned = pcall(function() return EggState.ReadOwnedEgg() end)
        if not ok or type(owned) ~= "table" then return end

        for _, rec in ipairs(owned) do
            if not rec.Uid then continue end
            if EggWorld and EggWorld.AskHatch then
                pcall(function() EggWorld.AskHatch:InvokeServer(rec.Uid) end)
                task.wait(0.05)
            end
            if EggWorld and EggWorld.AskFinishHatch then
                pcall(function() EggWorld.AskFinishHatch:InvokeServer(rec.Uid) end)
                task.wait(0.02)
            end
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(State.hatchInterval)
        if State.hatchEnabled then
            if not EggState then loadModules() end
            pcall(runAutoHatch)
        end
    end
end)

-- ============================================================
-- AUTO SELL — independent loop
-- ============================================================
-- Auto Sell via PetSatchel.SellPet / SellEveryPet (confirmed Shared.Remotes decompile)
local function getSellRemote(name)
    local net = ReplicatedStorage:FindFirstChild("Packages")
        and ReplicatedStorage.Packages:FindFirstChild("Networking")
    return net and net:FindFirstChild("RE/PetSatchel/" .. name)
end

local function runAutoSell()
    pcall(function()
        -- Sell All (pet mode)
        if State.sellAll then
            local remote = getSellRemote("SellEveryPet")
            if remote then
                remote:FireServer()
                print("[AutoSell] SellEveryPet fired")
            else
                warn("[AutoSell] SellEveryPet remote not found")
            end
            return
        end

        -- Sell per egg by rarity filter
        if not EggState then loadModules() end
        if not EggState then warn("[AutoSell] EggState nil"); return end

        local maxNum = getRarityNumberByName(State.sellMaxRarity)
        local ok, owned = pcall(function() return EggState.ReadOwnedEgg() end)
        if not ok or type(owned) ~= "table" or #owned == 0 then
            print("[AutoSell] owned egg kosong")
            return
        end

        local remote = getSellRemote("SellPet")
        if not remote then
            warn("[AutoSell] SellPet remote not found")
            return
        end

        local sold, skipped = 0, 0
        for _, rec in ipairs(owned) do
            if not rec.Uid then continue end
            local rarNum = getRarityNumber(rec)
            if rarNum <= maxNum then
                pcall(function() remote:FireServer(rec.Uid) end)
                sold += 1
                task.wait(0.05)
            else
                skipped += 1
            end
        end
        print(string.format("[AutoSell] sold=%d skipped=%d (maxRarity=%s)", sold, skipped, State.sellMaxRarity))
    end)
end

task.spawn(function()
    while true do
        task.wait(State.sellInterval)
        if State.sellEnabled then
            if not EggState then loadModules() end
            pcall(runAutoSell)
        end
    end
end)

-- ============================================================
-- BAT AURA — independent loop (spam FireServer, bukan proximity)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(State.batInterval)
        if State.batAura and GameRemotes and GameRemotes.BatSwing then
            pcall(function() GameRemotes.BatSwing.Trigger:FireServer() end)
        end
    end
end)

-- ============================================================
-- FARM CYCLE
-- ============================================================
local function farmCycle()
    if State.busy or not State.running then return end
    State.busy = true

    pcall(function()
        if not loadModules() then task.wait(0.5); return end
        local r = root(); local h2 = hum()
        if not r or not h2 then return end

        -- 1. Cari telur
        local rec, model = findBestEgg()
        if not rec or not model then
            State.lockedRecord = nil
            task.wait(0.3); return
        end

        local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        if not part then State.lockedRecord = nil; return end

        -- 2. Jalan ke telur
        if not walkTo(part.Position, 15, false) then return end
        if not State.running then return end

        -- 3. Claim
        local slotKey = nil
        pcall(function()
            if AreaEggSlotIdentity and rec.AreaId and rec.NestId then
                slotKey = AreaEggSlotIdentity.SlotKey(rec.AreaId, rec.NestId)
            end
        end)

        for _ = 1, 2 do
            pcall(function() EggState.CarryFieldEgg(rec.Uid, slotKey) end)
            local prompt = model:FindFirstChild("CarryAreaEgg", true)
                or model:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                pcall(function()
                    prompt.Enabled = true
                    if typeof(fireproximityprompt) == "function" then
                        fireproximityprompt(prompt, 0)
                    end
                end)
            end
            task.wait(0.01)
        end
        State.lockedRecord = nil

        -- 4. Kembali ke base
        walkTo(START_POS, 10, true)
        if not State.running then return end

        State.stealCount += 1
        Notify("SAE", "Steal #" .. State.stealCount, 1.5)
    end)

    local h2 = hum()
    if h2 then h2.WalkSpeed = 16 end
    State.busy = false
end

-- ============================================================
-- ESP SYSTEM (VD Style)
-- ============================================================
local EspHighlights = {}
local EspBillboards = {}

local function clearESP(uid)
    if EspHighlights[uid] then
        pcall(function() EspHighlights[uid]:Destroy() end)
        EspHighlights[uid] = nil
    end
    if EspBillboards[uid] then
        pcall(function() EspBillboards[uid]:Destroy() end)
        EspBillboards[uid] = nil
    end
end

local function createESP(model, uid, rarityCol, dispName, rarityName, earning)
    -- Highlight
    if not EspHighlights[uid] or not EspHighlights[uid].Parent then
        local h = Instance.new("Highlight")
        h.Name                = "SAE_HL"
        h.FillColor           = rarityCol
        h.OutlineColor        = rarityCol
        h.FillTransparency    = 0.7
        h.OutlineTransparency = 0.2
        h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent              = model
        EspHighlights[uid]    = h
    else
        EspHighlights[uid].FillColor    = rarityCol
        EspHighlights[uid].OutlineColor = rarityCol
    end

    -- Billboard
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end

    local bb = EspBillboards[uid]
    if not bb or not bb.Parent then
        bb = Instance.new("BillboardGui")
        bb.Name        = "SAE_ESP"
        bb.AlwaysOnTop = true
        bb.Size        = UDim2.new(0, 200, 0, 25)
        bb.StudsOffset = Vector3.new(0, 2, 0)
        bb.Adornee     = part
        bb.Parent      = part

        local box = Instance.new("Frame")
        box.Name                   = "Box"
        box.AutomaticSize          = Enum.AutomaticSize.X
        box.Size                   = UDim2.new(0, 0, 0, 15)
        box.Position               = UDim2.new(0.5, 0, 0, 0)
        box.AnchorPoint            = Vector2.new(0.5, 0)
        box.BackgroundColor3       = Color3.fromRGB(15, 15, 15)
        box.BackgroundTransparency = 0
        box.BorderSizePixel        = 0
        box.ZIndex                 = 2
        box.Parent                 = bb
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)

        local grad = Instance.new("UIGradient")
        grad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,    1),
            NumberSequenceKeypoint.new(0.15, 0.35),
            NumberSequenceKeypoint.new(0.85, 0.35),
            NumberSequenceKeypoint.new(1,    1),
        })
        grad.Parent = box

        local pad = Instance.new("UIPadding", box)
        pad.PaddingLeft  = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)

        local layout = Instance.new("UIListLayout", box)
        layout.FillDirection       = Enum.FillDirection.Horizontal
        layout.VerticalAlignment   = Enum.VerticalAlignment.Center
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.Padding             = UDim.new(0, 3)
        layout.SortOrder           = Enum.SortOrder.LayoutOrder

        local txt = Instance.new("TextLabel", box)
        txt.Name                   = "Text"
        txt.AutomaticSize          = Enum.AutomaticSize.X
        txt.Size                   = UDim2.new(0, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Font                   = Enum.Font.GothamMedium
        txt.TextSize               = 10
        txt.ZIndex                 = 3
        txt.LayoutOrder            = 1
        txt.RichText               = true
        txt.TextXAlignment         = Enum.TextXAlignment.Center
        txt.TextYAlignment         = Enum.TextYAlignment.Center

        local line = Instance.new("Frame")
        line.Name            = "Line"
        line.Size            = UDim2.new(0, 1, 0, 10)
        line.Position        = UDim2.new(0.5, 0, 0, 15)
        line.AnchorPoint     = Vector2.new(0.5, 0)
        line.BorderSizePixel = 0
        line.ZIndex          = 1
        line.Parent          = bb
        local lg = Instance.new("UIGradient")
        lg.Rotation    = 90
        lg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        lg.Parent = line

        EspBillboards[uid] = bb
    end

    -- Update content
    local hex = string.format("#%02X%02X%02X",
        math.floor(rarityCol.R * 255),
        math.floor(rarityCol.G * 255),
        math.floor(rarityCol.B * 255)
    )
    local box2 = bb:FindFirstChild("Box")
    if box2 then
        local line2 = bb:FindFirstChild("Line")
        if line2 then line2.BackgroundColor3 = rarityCol end
        local txt2 = box2:FindFirstChild("Text")
        if txt2 then
            txt2.Text = string.format(
                "<font color='#FFFFFF'>%s</font> <font color='%s'>%s</font> <font color='#B4FFB4'>$%s</font>",
                dispName, hex, rarityName, formatNumber(earning)
            )
        end
    end
end

local function updateESP()
    if not State.espEnabled then
        for uid in pairs(EspHighlights) do clearESP(uid) end
        for uid in pairs(EspBillboards) do clearESP(uid) end
        return
    end
    if not EggState then loadModules() end
    if not EggState then return end

    local ok, fieldEggs = pcall(function() return EggState.ReadFieldEggs() end)
    if not ok or not fieldEggs or not fieldEggs.Records then return end

    local active = {}
    for _, rec in ipairs(fieldEggs.Records) do
        local uid = rec.Uid
        if not uid then continue end
        active[uid] = true

        local model = Workspace:FindFirstChild("AreaEggSlotsClient", true)
            and Workspace.AreaEggSlotsClient:FindFirstChild(uid)
            or Workspace:FindFirstChild(uid, true)
        if not model then continue end

        local d        = getAssetData(rec)
        local col      = getRarityColor(rec)
        local name     = getRarityName(rec)
        local earning  = getEarningRate(rec)
        local dispName = d.DisplayName or rec.AssetCategory or uid

        pcall(createESP, model, uid, col, dispName, name, earning)
    end

    for uid in pairs(EspHighlights) do
        if not active[uid] then clearESP(uid) end
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        pcall(updateESP)
    end
end)

-- ============================================================
-- VVIND UI
-- ============================================================
local VindUI
do
    local ok, r = pcall(function()
        return loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/Skinny-yz/VVind-UI/refs/heads/main/src.lua"
        ))()
    end)
    if ok and r then VindUI = r
    else warn("[SAE] VVind gagal: " .. tostring(r)); return end
end

local function Notify(title, text, ntype, dur)
    pcall(function()
        VindUI:Notify({ Title = title, Text = text, Type = ntype or "info", Duration = dur or 3 })
    end)
end

local RARITIES = {
    "Common","Uncommon","Rare","Epic","Legendary","Mythic",
    "SuperRare","Exotic","Limited","Divine","Secret","Titan",
    "Cosmic","Celestial","Transcendent","Prismatic","Rainbow",
    "Eternal","Brainrot","Mythical","Exclusive"
}

local Window = VindUI:CreateWindow({
    Title     = "Steal An Egg",
    Subtitle  = "v2.0 — Test",
    Icon      = "Lucide:egg",
    Size      = UDim2.fromOffset(520, 400),
    MinSize   = Vector2.new(420, 340),
    Draggable = true,
    Resizable = true,
    UseBlur   = false,
})

local tabFarm   = Window:AddTab({ Name = "Farm",   Icon = "Lucide:wheat" })
local tabStore  = Window:AddTab({ Name = "Store",  Icon = "Lucide:shopping-bag" })
local tabConfig = Window:AddTab({ Name = "Config", Icon = "Lucide:settings" })

-- ── FARM ─────────────────────────────────────────────────────
local secMain = tabFarm:AddSubTab({ Name = "Auto Steal", Icon = "Lucide:zap" })

secMain:AddToggle({
    Text     = "Auto Steal",
    Default  = false,
    Flag     = "Toggle_AutoSteal",
    Callback = function(v)
        State.running = v
        if v then
            loadModules()
            doHumanoidBypass()
            Notify("SAE", "Farm started!", "success", 2)
            task.spawn(function()
                while State.running do
                    farmCycle()
                    task.wait(0.05)
                end
            end)
        else
            State.running      = false
            State.busy         = false
            State.lockedRecord = nil
            if _camConn then _camConn:Disconnect(); _camConn = nil end
            if _speedConn then _speedConn:Disconnect(); _speedConn = nil end
            Notify("SAE", "Farm stopped.", "info", 2)
            task.delay(0.3, function()
                pcall(function()
                    local h2 = hum(); if h2 then h2.Health = 0 end
                end)
            end)
        end
    end,
})

secMain:AddToggle({
    Text     = "Anti-Guard",
    Default  = true,
    Flag     = "Toggle_AntiGuard",
    Callback = function(v) State.antiGuard = v end,
})

secMain:AddToggle({
    Text     = "Bat Aura",
    Default  = false,
    Flag     = "Toggle_BatAura",
    Callback = function(v) State.batAura = v end,
})

secMain:AddToggle({
    Text     = "Float (3 stud)",
    Default  = false,
    Flag     = "Toggle_Float",
    Callback = function(v)
        State.floatEnabled = v
        updateFloat()
    end,
})

secMain:AddSlider({
    Text      = "Float Height",
    Min       = 1,
    Max       = 10,
    Default   = 3,
    Increment = 1,
    Flag      = "Slider_FloatHeight",
    Callback  = function(v) State.floatHeight = v end,
})

secMain:AddToggle({
    Text     = "Animation",
    Default  = true,
    Flag     = "Toggle_Anim",
    Callback = function(v)
        State.animEnabled = v
        updateAnim()
    end,
})

secMain:AddSlider({
    Text      = "Walk Speed",
    Min       = 16,
    Max       = 500,
    Default   = 120,
    Increment = 1,
    Flag      = "Slider_WalkSpeed",
    Callback  = function(v) State.speed = v end,
})

-- ── AUTO PLACE ────────────────────────────────────────────────
local secPlace = tabFarm:AddSubTab({ Name = "Auto Place", Icon = "Lucide:map-pin" })

secPlace:AddToggle({
    Text     = "Enable Auto Place",
    Default  = false,
    Flag     = "Toggle_Place",
    Callback = function(v)
        State.placeEnabled = v
        if v then loadModules() end
    end,
})

secPlace:AddSlider({
    Text      = "Interval (s)",
    Min       = 1,
    Max       = 30,
    Default   = 5,
    Increment = 1,
    Flag      = "Slider_PlaceInterval",
    Callback  = function(v) State.placeInterval = v end,
})

secPlace:AddDropdown({
    Text     = "Min Rarity to Place",
    Options  = RARITIES,
    Default  = "Common",
    Flag     = "Dropdown_PlaceRarity",
    Callback = function(v) State.placeMinRarity = v end,
})

secPlace:AddButton({
    Text     = "Place Now",
    Callback = function()
        loadModules(); pcall(runAutoPlace)
        Notify("Place", "Triggered!", "success", 2)
    end,
})

-- ── AUTO HATCH ────────────────────────────────────────────────
local secHatch = tabFarm:AddSubTab({ Name = "Auto Hatch", Icon = "Lucide:layers" })

secHatch:AddToggle({
    Text     = "Enable Auto Hatch",
    Default  = false,
    Flag     = "Toggle_Hatch",
    Callback = function(v)
        State.hatchEnabled = v
        if v then loadModules() end
    end,
})

secHatch:AddSlider({
    Text      = "Interval (s)",
    Min       = 1,
    Max       = 30,
    Default   = 3,
    Increment = 1,
    Flag      = "Slider_HatchInterval",
    Callback  = function(v) State.hatchInterval = v end,
})

secHatch:AddButton({
    Text     = "Hatch Now",
    Callback = function()
        loadModules(); pcall(runAutoHatch)
        Notify("Hatch", "Triggered!", "success", 2)
    end,
})

-- ── ESP ───────────────────────────────────────────────────────
local secESP = tabFarm:AddSubTab({ Name = "ESP", Icon = "Lucide:eye" })

secESP:AddToggle({
    Text     = "Egg ESP",
    Default  = false,
    Flag     = "Toggle_EggESP",
    Callback = function(v)
        State.espEnabled = v
        if not v then
            for uid in pairs(EspHighlights) do clearESP(uid) end
        end
    end,
})

-- ── FARM RARITY FILTER ────────────────────────────────────────
local secRarity = tabFarm:AddSubTab({ Name = "Rarity Filter", Icon = "Lucide:filter" })

secRarity:AddDropdown({
    Text     = "Target Rarities",
    Options  = RARITIES,
    Default  = {},
    Multi    = true,
    Flag     = "Dropdown_FarmRarities",
    Callback = function(v) State.targetRarities = v end,
})

-- ── FARM VALUE FILTER ─────────────────────────────────────────
local secVal = tabFarm:AddSubTab({ Name = "Value Filter", Icon = "Lucide:sliders" })

secVal:AddInput({
    Text     = "Min Earning Rate",
    Default  = "0",
    Flag     = "Input_MinEarning",
    Callback = function(v) State.minEarningRate = tonumber(v) or 0 end,
})

secVal:AddInput({
    Text     = "Min Weight",
    Default  = "0",
    Flag     = "Input_MinWeight",
    Callback = function(v) State.minModelWeight = tonumber(v) or 0 end,
})

secVal:AddInput({
    Text     = "Max Weight",
    Default  = "0",
    Flag     = "Input_MaxWeight",
    Callback = function(v)
        local n = tonumber(v) or 0
        State.maxModelWeight = n == 0 and 999999999 or n
    end,
})

-- ── STORE — AUTO SELL ─────────────────────────────────────────
local secSell = tabStore:AddSubTab({ Name = "Auto Sell", Icon = "Lucide:tag" })

secSell:AddToggle({
    Text     = "Enable Auto Sell",
    Default  = false,
    Flag     = "Toggle_Sell",
    Callback = function(v)
        State.sellEnabled = v
        if v then loadModules() end
    end,
})

secSell:AddSlider({
    Text      = "Interval (s)",
    Min       = 1,
    Max       = 60,
    Default   = 5,
    Increment = 1,
    Flag      = "Slider_SellInterval",
    Callback  = function(v) State.sellInterval = v end,
})

secSell:AddToggle({
    Text     = "Sell Every Pet",
    Default  = false,
    Flag     = "Toggle_SellAll",
    Callback = function(v) State.sellAll = v end,
})

secSell:AddDropdown({
    Text     = "Sell Max Rarity",
    Options  = RARITIES,
    Default  = "Epic",
    Flag     = "Dropdown_SellMax",
    Callback = function(v) State.sellMaxRarity = v end,
})

secSell:AddButton({
    Text     = "Sell Now",
    Callback = function()
        loadModules(); pcall(runAutoSell)
        Notify("Sell", "Triggered!", "success", 2)
    end,
})

-- ── CONFIG ─────────────────────────────────────────────────────
local secCfg = tabConfig:AddSubTab({ Name = "Configuration", Icon = "Lucide:save" })

secCfg:AddButton({
    Text     = "Save Config",
    Callback = function()
        pcall(function() VindUI:SaveConfig("SAE_test_config") end)
        Notify("Config", "Saved!", "success", 2)
    end,
})

secCfg:AddButton({
    Text     = "Load Config",
    Callback = function()
        pcall(function() VindUI:LoadConfig("SAE_test_config") end)
        Notify("Config", "Loaded!", "success", 2)
    end,
})

Notify("Steal An Egg", "v2.0 Test loaded!", "success", 3)
