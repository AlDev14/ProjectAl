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
    if not record then return {} end
    -- Coba Assets.Directory dulu
    if Assets and record.AssetCategory then
        local ok, d = pcall(function()
            return (Assets.Directory or Assets)[record.AssetCategory] or {}
        end)
        if ok and d and next(d) then return d end
    end
    -- Fallback: bangun dari field record langsung (record punya Rarity, EarningRate, dll)
    return {
        EarningRate = record.EarningRate,
        ModelWeight = record.ModelWeight,
        DropWeight  = record.DropWeight,
        DisplayName = record.AssetCategory,
        Rarity      = record.Rarity,
        _id         = record.AssetCategory,
    }
end

local function getEarningRate(record)
    if record and record.EarningRate then return tonumber(record.EarningRate) or 0 end
    return tonumber(getAssetData(record).EarningRate) or 0
end

local function getModelWeight(record)
    if record and record.ModelWeight then return tonumber(record.ModelWeight) or 0 end
    return tonumber(getAssetData(record).ModelWeight) or 0
end

local function getRarityName(record)
    -- Cek record.Rarity langsung (paling reliable, gak butuh Assets)
    if record and record.Rarity then
        if type(record.Rarity) == "table" and record.Rarity._id then
            return record.Rarity._id
        end
        if type(record.Rarity) == "string" then return record.Rarity end
    end
    local d = getAssetData(record)
    return (d.Rarity and d.Rarity._id) or "Unknown"
end

local function getRarityColor(record)
    if record and record.Rarity and type(record.Rarity) == "table" then
        if typeof(record.Rarity.Color) == "Color3" then return record.Rarity.Color end
    end
    local d = getAssetData(record)
    if d.Rarity and typeof(d.Rarity.Color) == "Color3" then return d.Rarity.Color end
    if RarityModule and RarityModule.Rarities then
        local rn = getRarityName(record)
        local rm = RarityModule.Rarities[rn]
        if rm and typeof(rm.Color) == "Color3" then return rm.Color end
    end
    return Color3.fromRGB(255, 255, 255)
end

local function getRarityNumber(record)
    if record and record.Rarity and type(record.Rarity) == "table" then
        if type(record.Rarity.RarityNumber) == "number" then
            return record.Rarity.RarityNumber
        end
    end
    local d = getAssetData(record)
    if d.Rarity and d.Rarity.RarityNumber then return d.Rarity.RarityNumber end
    if RarityModule and RarityModule.Rarities then
        local rn = getRarityName(record)
        local rm = RarityModule.Rarities[rn]
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
-- FLOAT SYSTEM — client-side visual only (RenderStepped)
-- Smooth Y biar gak jumping, cuma lo yang lihat
-- ============================================================
local _floatConn = nil
local _floatSmoothY = nil
local function updateFloat()
    if _floatConn then _floatConn:Disconnect(); _floatConn = nil end
    _floatSmoothY = nil
    if not State.floatEnabled then return end
    _floatConn = RunService.RenderStepped:Connect(function()
        if not State.floatEnabled then return end
        local c = LocalPlayer.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        -- Smooth Y dari physics position biar gak jumpy
        local physY = hrp.Position.Y
        if not _floatSmoothY then _floatSmoothY = physY end
        _floatSmoothY = _floatSmoothY * 0.85 + physY * 0.15
        -- Apply offset visual-only
        local rot = hrp.CFrame - hrp.CFrame.Position
        hrp.CFrame = CFrame.new(hrp.Position.X, _floatSmoothY + State.floatHeight, hrp.Position.Z) * rot
    end)
end

-- ============================================================
-- ANIMATION TOGGLE — Heartbeat loop biar gak re-apply
-- ============================================================
local _animTracks = {}
local _animConn   = nil

local function stopAllAnims()
    local c = LocalPlayer.Character
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            pcall(function() track:Stop(0) end)
        end
    end
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        pcall(function() track:Stop(0) end)
    end
end

local function updateAnim()
    if _animConn then _animConn:Disconnect(); _animConn = nil end
    if State.animEnabled then return end
    -- Stop sekali dulu
    stopAllAnims()
    -- Loop terus stop animasi baru yang di-apply game
    _animConn = RunService.Heartbeat:Connect(function()
        if State.animEnabled then
            if _animConn then _animConn:Disconnect(); _animConn = nil end
            return
        end
        stopAllAnims()
    end)
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
            print("[AutoPlace] owned egg kosong:", ok, type(owned), #(owned or {}))
            return
        end

        -- Debug: print field pertama owned egg biar tau format
        if owned[1] then
            print("[AutoPlace] record sample fields:")
            for k, v in pairs(owned[1]) do
                print("  ." .. tostring(k) .. " = " .. tostring(type(v) == "table" and "{table}" or v))
            end
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
-- CUSTOM UI — no external dependency
-- ============================================================
local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local LP           = Players.LocalPlayer
local PG           = LP:WaitForChild("PlayerGui")

-- Hapus UI lama
pcall(function()
    local old = PG:FindFirstChild("SAE_UI")
    if old then old:Destroy() end
end)

local SG = Instance.new("ScreenGui")
SG.Name = "SAE_UI"
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true
SG.DisplayOrder = 999999
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = (type(gethui)=="function" and pcall(gethui) and gethui()) or
            (type(syn)=="table" and syn.protect_gui and syn.protect_gui(SG) and SG) or
            PG

-- ============================================================
-- HELPERS
-- ============================================================
local function mkFrame(props)
    local f = Instance.new("Frame")
    for k,v in pairs(props or {}) do f[k]=v end
    f.BorderSizePixel = 0
    return f
end
local function mkLabel(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Font = Enum.Font.GothamBold
    l.TextColor3 = Color3.fromRGB(235,235,240)
    for k,v in pairs(props or {}) do l[k]=v end
    return l
end
local function mkBtn(props)
    local b = Instance.new("TextButton")
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    for k,v in pairs(props or {}) do b[k]=v end
    return b
end
local function corner(r, p)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
    return c
end
local function stroke(t, col, p)
    local s = Instance.new("UIStroke")
    s.Thickness = t or 1
    s.Color = col or Color3.fromRGB(70,70,80)
    s.Parent = p
end
local function listLayout(p, pad)
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, pad or 4)
    l.Parent = p
    return l
end

-- ============================================================
-- COLORS
-- ============================================================
local C = {
    BG      = Color3.fromRGB(15,15,20),
    BG2     = Color3.fromRGB(22,22,30),
    BG3     = Color3.fromRGB(30,30,40),
    Accent  = Color3.fromRGB(80,160,255),
    AccentD = Color3.fromRGB(50,110,200),
    Text    = Color3.fromRGB(235,235,240),
    TextDim = Color3.fromRGB(140,140,155),
    Green   = Color3.fromRGB(80,220,120),
    Red     = Color3.fromRGB(220,80,80),
    Stroke  = Color3.fromRGB(55,55,70),
}

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local W = 400
local H = 320

local Main = mkFrame({
    Size = UDim2.fromOffset(W, H),
    Position = UDim2.new(0.5,-W/2,0.5,-H/2),
    BackgroundColor3 = C.BG,
    Parent = SG,
})
corner(10, Main)
stroke(1.5, C.Stroke, Main)

-- Title bar
local TitleBar = mkFrame({
    Size = UDim2.new(1,0,0,36),
    BackgroundColor3 = C.BG2,
    Parent = Main,
})
corner(10, TitleBar)
-- Fix bottom corners of titlebar
mkFrame({
    Size = UDim2.new(1,0,0.5,0),
    Position = UDim2.new(0,0,0.5,0),
    BackgroundColor3 = C.BG2,
    Parent = TitleBar,
})

local TitleLbl = mkLabel({
    Size = UDim2.new(1,-80,1,0),
    Position = UDim2.new(0,12,0,0),
    Text = "Steal An Egg  v2.0",
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = TitleBar,
})

local CloseBtn = mkBtn({
    Size = UDim2.fromOffset(24,24),
    Position = UDim2.new(1,-30,0.5,-12),
    Text = "×",
    TextSize = 18,
    TextColor3 = C.TextDim,
    BackgroundColor3 = C.BG3,
    Parent = TitleBar,
})
corner(6, CloseBtn)

-- ============================================================
-- DRAG
-- ============================================================
do
    local drag, ds, mp = false
    TitleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; mp = Main.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then drag=false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - ds
            Main.Position = UDim2.new(mp.X.Scale, mp.X.Offset+d.X, mp.Y.Scale, mp.Y.Offset+d.Y)
        end
    end)
end

-- ============================================================
-- TABS
-- ============================================================
local TabBar = mkFrame({
    Size = UDim2.new(1,-2,0,28),
    Position = UDim2.new(0,1,0,37),
    BackgroundColor3 = C.BG2,
    Parent = Main,
})
local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0,2)
TabLayout.Parent = TabBar

local Content = mkFrame({
    Size = UDim2.new(1,0,1,-68),
    Position = UDim2.new(0,0,0,68),
    BackgroundTransparency = 1,
    Parent = Main,
})

local tabs = {}
local activeTab = nil

local function mkTab(name)
    local btn = mkBtn({
        Size = UDim2.fromOffset(88, 28),
        Text = name,
        TextSize = 12,
        TextColor3 = C.TextDim,
        BackgroundColor3 = C.BG2,
        LayoutOrder = #tabs+1,
        Parent = TabBar,
    })

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,-4,1,-4)
    scroll.Position = UDim2.new(0,2,0,2)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = C.Stroke
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.Visible = false
    scroll.Parent = Content

    local layout = listLayout(scroll, 4)
    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingLeft = UDim.new(0,6)
    pad.PaddingRight = UDim.new(0,6)
    pad.PaddingTop = UDim.new(0,4)

    local t = {btn=btn, scroll=scroll}
    table.insert(tabs, t)

    btn.MouseButton1Click:Connect(function()
        for _, tab in ipairs(tabs) do
            tab.scroll.Visible = false
            tab.btn.TextColor3 = C.TextDim
            tab.btn.BackgroundColor3 = C.BG2
        end
        scroll.Visible = true
        btn.TextColor3 = C.Text
        btn.BackgroundColor3 = C.BG3
        activeTab = t
    end)

    return t
end

-- ============================================================
-- ELEMENT BUILDERS
-- ============================================================
local function addSection(tab, title)
    local f = mkFrame({
        Size = UDim2.new(1,-2,0,22),
        BackgroundColor3 = C.BG3,
        Parent = tab.scroll,
    })
    corner(4, f)
    local l = mkLabel({
        Size = UDim2.new(1,-8,1,0),
        Position = UDim2.new(0,8,0,0),
        Text = title,
        TextSize = 11,
        TextColor3 = C.Accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = f,
    })
    return f
end

local function addToggle(tab, title, default, cb)
    local f = mkFrame({
        Size = UDim2.new(1,-2,0,30),
        BackgroundColor3 = C.BG2,
        Parent = tab.scroll,
    })
    corner(6, f)

    local lbl = mkLabel({
        Size = UDim2.new(1,-50,1,0),
        Position = UDim2.new(0,10,0,0),
        Text = title,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = f,
    })

    local state = default or false
    local pill = mkFrame({
        Size = UDim2.fromOffset(36,18),
        Position = UDim2.new(1,-44,0.5,-9),
        BackgroundColor3 = state and C.Green or C.BG3,
        Parent = f,
    })
    corner(9, pill)
    stroke(1, C.Stroke, pill)

    local dot = mkFrame({
        Size = UDim2.fromOffset(14,14),
        Position = state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        Parent = pill,
    })
    corner(7, dot)

    local function setState(v)
        state = v
        pill.BackgroundColor3 = v and C.Green or C.BG3
        dot.Position = v and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
        pcall(cb, v)
    end

    local clickBtn = mkBtn({
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = f,
    })
    clickBtn.MouseButton1Click:Connect(function() setState(not state) end)

    return { Set = setState, Get = function() return state end }
end

local function addSlider(tab, title, min, max, default, step, cb)
    local f = mkFrame({
        Size = UDim2.new(1,-2,0,44),
        BackgroundColor3 = C.BG2,
        Parent = tab.scroll,
    })
    corner(6, f)

    local val = default or min
    local lbl = mkLabel({
        Size = UDim2.new(1,-8,0,18),
        Position = UDim2.new(0,10,0,4),
        Text = title .. ": " .. tostring(val),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = f,
    })

    local track = mkFrame({
        Size = UDim2.new(1,-20,0,6),
        Position = UDim2.new(0,10,0,26),
        BackgroundColor3 = C.BG3,
        Parent = f,
    })
    corner(3, track)

    local fill = mkFrame({
        Size = UDim2.new((val-min)/(max-min),0,1,0),
        BackgroundColor3 = C.Accent,
        Parent = track,
    })
    corner(3, fill)

    local function setVal(v)
        v = math.clamp(math.floor(v/step+0.5)*step, min, max)
        val = v
        fill.Size = UDim2.new((v-min)/(max-min),0,1,0)
        lbl.Text = title .. ": " .. tostring(v)
        pcall(cb, v)
    end

    local dragging = false
    local hitbox = mkBtn({
        Size = UDim2.new(1,0,0,16),
        Position = UDim2.new(0,0,0,20),
        BackgroundTransparency = 1,
        Text = "",
        Parent = f,
    })
    hitbox.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    hitbox.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local abs = track.AbsolutePosition
            local sz  = track.AbsoluteSize
            local pct = math.clamp((i.Position.X - abs.X) / sz.X, 0, 1)
            setVal(min + pct*(max-min))
        end
    end)

    return { Set = setVal, Get = function() return val end }
end

local function addButton(tab, title, cb)
    local f = mkBtn({
        Size = UDim2.new(1,-2,0,28),
        Text = title,
        TextSize = 12,
        TextColor3 = C.Text,
        BackgroundColor3 = C.AccentD,
        Parent = tab.scroll,
    })
    corner(6, f)
    f.MouseButton1Click:Connect(function() pcall(cb) end)
    f.MouseEnter:Connect(function() f.BackgroundColor3 = C.Accent end)
    f.MouseLeave:Connect(function() f.BackgroundColor3 = C.AccentD end)
    return f
end

local function addDropdown(tab, title, options, default, multi, cb)
    local state = default or (multi and {} or options[1])
    local open = false

    local f = mkFrame({
        Size = UDim2.new(1,-2,0,30),
        BackgroundColor3 = C.BG2,
        Parent = tab.scroll,
    })
    corner(6, f)

    local lbl = mkLabel({
        Size = UDim2.new(1,-8,0,14),
        Position = UDim2.new(0,10,0,2),
        Text = title,
        TextSize = 10,
        TextColor3 = C.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = f,
    })

    local valLbl = mkLabel({
        Size = UDim2.new(1,-30,0,14),
        Position = UDim2.new(0,10,0,14),
        Text = multi and "Select..." or tostring(state),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = f,
    })

    local arrow = mkLabel({
        Size = UDim2.fromOffset(16,16),
        Position = UDim2.new(1,-22,0.5,-8),
        Text = "▼",
        TextSize = 10,
        TextColor3 = C.TextDim,
        Parent = f,
    })

    -- Popup (parent ke SG biar gak ketimpa)
    local popup = mkFrame({
        Size = UDim2.fromOffset(f.AbsoluteSize.X, 0),
        BackgroundColor3 = C.BG2,
        Visible = false,
        ZIndex = 10,
        Parent = SG,
    })
    corner(6, popup)
    stroke(1, C.Stroke, popup)

    local popScroll = Instance.new("ScrollingFrame")
    popScroll.Size = UDim2.new(1,0,1,0)
    popScroll.BackgroundTransparency = 1
    popScroll.BorderSizePixel = 0
    popScroll.ScrollBarThickness = 3
    popScroll.ScrollBarImageColor3 = C.Stroke
    popScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    popScroll.CanvasSize = UDim2.new(0,0,0,0)
    popScroll.ZIndex = 10
    popScroll.Parent = popup
    listLayout(popScroll, 2)

    local selected = {}
    if multi and type(state) == "table" then
        for k,v in pairs(state) do
            if v then selected[k] = true end
        end
    end

    local optBtns = {}
    for _, opt in ipairs(options) do
        local ob = mkBtn({
            Size = UDim2.new(1,0,0,24),
            Text = opt,
            TextSize = 11,
            TextColor3 = C.Text,
            BackgroundColor3 = C.BG3,
            ZIndex = 11,
            Parent = popScroll,
        })
        corner(4, ob)
        table.insert(optBtns, {btn=ob, opt=opt})

        ob.MouseButton1Click:Connect(function()
            if multi then
                selected[opt] = not selected[opt]
                ob.BackgroundColor3 = selected[opt] and C.AccentD or C.BG3
                ob.TextColor3 = selected[opt] and C.Text or C.TextDim
                local arr = {}
                for k,v in pairs(selected) do if v then table.insert(arr,k) end end
                local display = #arr == 0 and "Select..." or table.concat(arr, ", "):sub(1,30)
                valLbl.Text = display
                pcall(cb, selected)
            else
                state = opt
                valLbl.Text = opt
                for _, o in ipairs(optBtns) do
                    o.btn.BackgroundColor3 = o.opt == opt and C.AccentD or C.BG3
                end
                open = false
                popup.Visible = false
                arrow.Text = "▼"
                pcall(cb, opt)
            end
        end)
    end

    -- Toggle popup
    local maxH = math.min(#options * 26, 160)
    local clickArea = mkBtn({
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = f,
    })
    clickArea.MouseButton1Click:Connect(function()
        open = not open
        if open then
            local abs = f.AbsolutePosition
            local sz  = f.AbsoluteSize
            popup.Size = UDim2.fromOffset(sz.X, maxH)
            popup.Position = UDim2.fromOffset(abs.X, abs.Y + sz.Y + 2)
            popup.Visible = true
            arrow.Text = "▲"
        else
            popup.Visible = false
            arrow.Text = "▼"
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function() popup.Visible = false end)

    return {
        Get = function() return multi and selected or state end,
        Set = function(v)
            if not multi then state = v; valLbl.Text = v end
        end,
    }
end

local function addInput(tab, title, default, cb)
    local f = mkFrame({
        Size = UDim2.new(1,-2,0,44),
        BackgroundColor3 = C.BG2,
        Parent = tab.scroll,
    })
    corner(6, f)

    mkLabel({
        Size = UDim2.new(1,-8,0,16),
        Position = UDim2.new(0,10,0,4),
        Text = title,
        TextSize = 11,
        TextColor3 = C.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = f,
    })

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1,-20,0,18)
    box.Position = UDim2.new(0,10,0,22)
    box.BackgroundColor3 = C.BG3
    box.BorderSizePixel = 0
    box.Text = tostring(default or "")
    box.TextSize = 11
    box.TextColor3 = C.Text
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.Parent = f
    corner(4, box)

    box.FocusLost:Connect(function() pcall(cb, box.Text) end)
    return box
end

local function Notify(title, text, dur)
    task.spawn(function()
        local nf = mkFrame({
            Size = UDim2.fromOffset(240, 52),
            Position = UDim2.new(1,-250,1,-60),
            BackgroundColor3 = C.BG2,
            Parent = SG,
        })
        corner(8, nf)
        stroke(1, C.Accent, nf)

        mkLabel({
            Size = UDim2.new(1,-10,0,20),
            Position = UDim2.new(0,8,0,6),
            Text = title,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = nf,
        })
        mkLabel({
            Size = UDim2.new(1,-10,0,16),
            Position = UDim2.new(0,8,0,26),
            Text = text,
            TextSize = 10,
            TextColor3 = C.TextDim,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = nf,
        })
        task.wait(dur or 3)
        nf:Destroy()
    end)
end

-- ============================================================
-- BUILD TABS
-- ============================================================
local RARITIES = {
    "Common","Uncommon","Rare","Epic","Legendary","Mythic",
    "SuperRare","Exotic","Limited","Divine","Secret","Titan",
    "Cosmic","Celestial","Transcendent","Prismatic","Rainbow",
    "Eternal","Brainrot","Mythical","Exclusive"
}

local tFarm   = mkTab("Farm")
local tStore  = mkTab("Store")
local tConfig = mkTab("Config")

-- Activate Farm tab
tFarm.scroll.Visible = true
tFarm.btn.TextColor3 = C.Text
tFarm.btn.BackgroundColor3 = C.BG3

-- ── FARM ─────────────────────────────────────────────────────
addSection(tFarm, "Auto Steal")
addToggle(tFarm, "Auto Steal", false, function(v)
    State.running = v
    if v then
        loadModules()
        doHumanoidBypass()
        Notify("SAE", "Farm started!", 2)
        task.spawn(function()
            while State.running do
                farmCycle()
                task.wait(0.05)
            end
        end)
    else
        State.running = false; State.busy = false; State.lockedRecord = nil
        if _camConn   then _camConn:Disconnect();   _camConn   = nil end
        if _speedConn then _speedConn:Disconnect(); _speedConn = nil end
        Notify("SAE", "Farm stopped.", 2)
    end
end)
addToggle(tFarm, "Anti-Guard", true,  function(v) State.antiGuard = v end)
addToggle(tFarm, "Bat Aura",   false, function(v) State.batAura   = v end)
addToggle(tFarm, "Animation",  true,  function(v) State.animEnabled=v; updateAnim() end)
addToggle(tFarm, "Float (visual)", false, function(v) State.floatEnabled=v; updateFloat() end)
addSlider(tFarm, "Walk Speed", 16, 500, 120, 1,  function(v) State.speed = v end)
addSlider(tFarm, "Float Height",1, 10,  3,   1,  function(v) State.floatHeight = v end)

addSection(tFarm, "Auto Place")
addToggle(tFarm, "Enable Auto Place", false, function(v)
    State.placeEnabled = v; if v then loadModules() end
end)
addSlider(tFarm, "Place Interval (s)", 1, 30, 5, 1, function(v) State.placeInterval = v end)
addDropdown(tFarm, "Min Rarity Place", RARITIES, "Common", false,
    function(v) State.placeMinRarity = v end)
addButton(tFarm, "Place Now", function()
    loadModules(); pcall(runAutoPlace); Notify("Place","Triggered!",2)
end)

addSection(tFarm, "Auto Hatch")
addToggle(tFarm, "Enable Auto Hatch", false, function(v)
    State.hatchEnabled = v; if v then loadModules() end
end)
addSlider(tFarm, "Hatch Interval (s)", 1, 30, 3, 1, function(v) State.hatchInterval = v end)
addButton(tFarm, "Hatch Now", function()
    loadModules(); pcall(runAutoHatch); Notify("Hatch","Triggered!",2)
end)

addSection(tFarm, "ESP")
addToggle(tFarm, "Egg ESP", false, function(v)
    State.espEnabled = v
    if not v then for uid in pairs(EspHighlights) do clearESP(uid) end end
end)

addSection(tFarm, "Rarity Filter")
addDropdown(tFarm, "Target Rarities", RARITIES, {}, true, function(v)
    State.targetRarities = v
end)

addSection(tFarm, "Value Filter")
addInput(tFarm, "Min Earning Rate", "0", function(v) State.minEarningRate = tonumber(v) or 0 end)
addInput(tFarm, "Min Weight",       "0", function(v) State.minModelWeight = tonumber(v) or 0 end)
addInput(tFarm, "Max Weight",       "0", function(v)
    local n = tonumber(v) or 0
    State.maxModelWeight = n == 0 and 999999999 or n
end)

-- ── STORE ─────────────────────────────────────────────────────
addSection(tStore, "Auto Sell")
addToggle(tStore, "Enable Auto Sell", false, function(v)
    State.sellEnabled = v; if v then loadModules() end
end)
addToggle(tStore, "Sell Every Pet", false, function(v) State.sellAll = v end)
addSlider(tStore, "Sell Interval (s)", 1, 60, 5, 1, function(v) State.sellInterval = v end)
addDropdown(tStore, "Sell Max Rarity", RARITIES, "Epic", false,
    function(v) State.sellMaxRarity = v end)
addButton(tStore, "Sell Now", function()
    loadModules(); pcall(runAutoSell); Notify("Sell","Triggered!",2)
end)

-- ── CONFIG ────────────────────────────────────────────────────
addSection(tConfig, "Configuration")
addButton(tConfig, "Save Config", function()
    pcall(function()
        if writefile then writefile("SAE_test.json", game:GetService("HttpService"):JSONEncode({
            speed=State.speed, antiGuard=State.antiGuard,
            sellMaxRarity=State.sellMaxRarity, placeMinRarity=State.placeMinRarity,
        })) end
    end)
    Notify("Config","Saved!",2)
end)
addButton(tConfig, "Load Config", function()
    pcall(function()
        if readfile and isfile and isfile("SAE_test.json") then
            local d = game:GetService("HttpService"):JSONDecode(readfile("SAE_test.json"))
            if d.speed then State.speed = d.speed end
            if d.antiGuard ~= nil then State.antiGuard = d.antiGuard end
            if d.sellMaxRarity then State.sellMaxRarity = d.sellMaxRarity end
            if d.placeMinRarity then State.placeMinRarity = d.placeMinRarity end
        end
    end)
    Notify("Config","Loaded!",2)
end)

-- ============================================================
-- CLOSE + FLOAT TOGGLE BUTTON
-- ============================================================
CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)

-- Floating toggle button
local fb = mkBtn({
    Size = UDim2.fromOffset(36,36),
    Position = UDim2.new(0,8,0.5,-18),
    Text = "S",
    TextSize = 14,
    TextColor3 = C.Text,
    BackgroundColor3 = C.BG2,
    Parent = SG,
})
corner(18, fb)
stroke(1.5, C.Accent, fb)
fb.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

-- Drag float btn
do
    local drag, ds, fp, dist = false
    fb.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag=true; ds=i.Position; fp=fb.Position; dist=0
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then drag=false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then
            local d = i.Position-ds; dist=d.Magnitude
            fb.Position = UDim2.new(fp.X.Scale,fp.X.Offset+d.X,fp.Y.Scale,fp.Y.Offset+d.Y)
        end
    end)
end

Notify("Steal An Egg","v2.0 loaded!",3)
