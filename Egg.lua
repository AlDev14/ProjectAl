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
local ProximityPromptService = game:GetService("ProximityPromptService")
local LocalPlayer       = Players.LocalPlayer

-- ============================================================
-- INSTANT INTERACT — hook PromptButtonHoldBegan
-- Set HoldDuration=0 untuk CarryAreaEgg (open source: Lutosys/opensrc)
-- ============================================================
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
    if player == LocalPlayer and prompt.Name == "CarryAreaEgg" then
        prompt.HoldDuration = 0
    end
end)

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
    -- GameRemotes sengaja dihapus — require(Shared.Remotes) = BAC di SAE
    -- Semua remote diakses langsung via Packages.Networking
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

-- Base teleport koordinat (dari koedinat panel)
local START_POS = Vector3.new(519.464, 70.576, -370.816)

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
    -- Empty = semua allowed
    if not next(State.targetRarities) then return true end
    local name = getRarityName(record)
    -- Orvion multi-select bisa return dict {[name]=true} atau array {name}
    if State.targetRarities[name] == true then return true end
    for _, v in ipairs(State.targetRarities) do
        if v == name then return true end
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
-- HUMANOID BYPASS
-- ============================================================
local _camConn = nil

local function doHumanoidBypass()
    local char = LocalPlayer.Character
    if not char then char = LocalPlayer.CharacterAdded:Wait() end

    local origHum  = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not origHum or not rootPart then return end

    pcall(function()
        local clone = origHum:Clone()
        clone.WalkSpeed   = origHum.WalkSpeed
        clone.JumpPower   = origHum.JumpPower
        clone.MaxHealth   = origHum.MaxHealth
        clone.Health      = origHum.Health
        clone.AutoRotate  = origHum.AutoRotate
        clone.DisplayName = origHum.DisplayName
        clone.Parent      = char
        task.wait(0.05)
        origHum:Destroy()

        -- Teleport ke StartPosition
        if rootPart and rootPart.Parent then
            rootPart.CFrame                  = CFrame.new(START_POS)
            rootPart.AssemblyLinearVelocity  = Vector3.new(0, 35, 0)
            rootPart.AssemblyAngularVelocity = Vector3.zero
        end

        task.wait(0.05)
        clone.PlatformStand = false
        clone.Sit           = false
        pcall(function() clone:ChangeState(Enum.HumanoidStateType.Running) end)
    end)

    -- Camera lock via Heartbeat
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
-- WALK TO
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
        if not myPlot or not myPlot.CenterPoint or not myPlot.PetArea then return end

        -- Walk ke plot dulu — server validasi player harus dalam bounds
        local plotPos = myPlot.CenterPoint.Position
        local r = root()
        if r and (r.Position - plotPos).Magnitude > 5 then
            walkTo(plotPos, 15, true)
        end

        -- Tunggu sebentar biar bounds check server pass
        task.wait(0.2)

        local net = ReplicatedStorage:FindFirstChild("Packages")
            and ReplicatedStorage.Packages:FindFirstChild("Networking")
        local placeRemote = net and net:FindFirstChild("RF/EggWorld/AskPlaceEgg")
        if not placeRemote then return end

        -- LocalCFrame = posisi PetArea relatif ke CenterPoint
        local localCFrame = myPlot.CenterPoint.CFrame:ToObjectSpace(
            CFrame.new(myPlot.PetArea.Position)
        )

        local ok, owned = pcall(function() return EggState.ReadOwnedEgg() end)
        if not ok or type(owned) ~= "table" or #owned == 0 then return end

        local minRarNum = getRarityNumberByName(State.placeMinRarity)
        local placed, skipped = 0, 0

        for _, rec in ipairs(owned) do
            if not rec.Uid then continue end
            if minRarNum > 0 and getRarityNumber(rec) < minRarNum then
                skipped += 1; continue
            end
            local ok3, res = pcall(function()
                return placeRemote:InvokeServer({ Uid = rec.Uid, LocalCFrame = localCFrame })
            end)
            if ok3 and res == true then placed += 1 end
            task.wait(0.05)
        end
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
        local net = ReplicatedStorage:FindFirstChild("Packages")
            and ReplicatedStorage.Packages:FindFirstChild("Networking")
        if not net then return end
        local AskHatch       = net:FindFirstChild("RF/EggWorld/AskHatch")
        local AskFinishHatch = net:FindFirstChild("RF/EggWorld/AskFinishHatch")
        if not AskHatch and not AskFinishHatch then return end

        local ok, owned = pcall(function() return EggState.ReadOwnedEgg() end)
        if not ok or type(owned) ~= "table" then return end

        for _, rec in ipairs(owned) do
            if not rec.Uid then continue end
            if AskHatch then
                pcall(function() AskHatch:InvokeServer(rec.Uid) end)
                task.wait(0.05)
            end
            if AskFinishHatch then
                pcall(function() AskFinishHatch:InvokeServer(rec.Uid) end)
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
local function runAutoSell()
    pcall(function()
        local net = ReplicatedStorage:FindFirstChild("Packages")
            and ReplicatedStorage.Packages:FindFirstChild("Networking")
        if not net then return end

        if State.sellAll then
            local remote = net:FindFirstChild("RE/PetSatchel/SellEveryPet")
            if remote then pcall(function() remote:FireServer() end) end
            return
        end

        if not EggState then loadModules() end
        if not EggState then return end

        local remote = net:FindFirstChild("RE/PetSatchel/SellPet")
        if not remote then return end

        local maxNum = getRarityNumberByName(State.sellMaxRarity)
        local ok, owned = pcall(function() return EggState.ReadOwnedEgg() end)
        if not ok or type(owned) ~= "table" then return end

        for _, rec in ipairs(owned) do
            if not rec.Uid then continue end
            if getRarityNumber(rec) <= maxNum then
                pcall(function() remote:FireServer(rec.Uid) end)
                task.wait(0.05)
            end
        end
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
-- BAT AURA — target nearest player + seed (Bath aura.txt)
-- ============================================================
local BatRemote = nil
local BatLastSwing = 0

local function getBatRemote()
    if BatRemote and BatRemote.Parent then return BatRemote end
    local net = ReplicatedStorage:FindFirstChild("Packages")
        and ReplicatedStorage.Packages:FindFirstChild("Networking")
    BatRemote = net and net:FindFirstChild("RE/BatSwing/Trigger")
    return BatRemote
end

local function createBatSeed()
    local ok, r = pcall(function()
        return ("%s:%s:%s"):format(
            tostring(LocalPlayer.UserId),
            "100",
            tostring(math.floor(Workspace:GetServerTimeNow() * 1000))
        )
    end)
    return ok and r or nil
end

local function canUseBat()
    local char = LocalPlayer.Character
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool:GetAttribute("ItemType") ~= "Gear" then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    return true
end

local function getBatTarget()
    local best, bestDist = nil, math.huge
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local dist = (hrp.Position - myHRP.Position).Magnitude
        if dist <= 16.5 and dist < bestDist then
            bestDist = dist
            best = p
        end
    end
    return best
end

task.spawn(function()
    while true do
        task.wait(State.batInterval)
        if State.batAura then
            local now = Workspace.DistributedGameTime
            if now - BatLastSwing < 0.1 then continue end
            if not canUseBat() then continue end
            local target = getBatTarget()
            if not target then continue end
            local remote = getBatRemote()
            if not remote then continue end
            local seed = createBatSeed()
            pcall(function() remote:FireServer(target, seed) end)
            BatLastSwing = now
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
-- ORVION UI
-- ============================================================
local Orvion
do
    local ok, r = pcall(function()
        return loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/KnullXDgt/Orvion-UI-Library/main/source.luau"
        ))()
    end)
    if ok and r then Orvion = r
    else warn("[SAE] Orvion gagal: " .. tostring(r)); return end
end

local VindLib = Orvion  -- alias untuk Notify

local function Notify(title, text, dur)
    pcall(function() Orvion:Notify(title, text, dur or 3) end)
end

local RARITIES = {
    "Common","Uncommon","Rare","Epic","Legendary","Mythic",
    "SuperRare","Exotic","Limited","Divine","Secret","Titan",
    "Cosmic","Celestial","Transcendent","Prismatic","Rainbow",
    "Eternal","Brainrot","Mythical","Exclusive"
}

local Window = Orvion:CreateWindow({
    Title     = "Steal An Egg",
    Theme     = "Default",
    Size      = UDim2.fromOffset(470, 270),
    Center    = true,
    Draggable = true,
    Badges    = {"v2.0"},
})

-- TABS
local tabFarm,   _ = Window:CreateTab("Farm",   nil)
local tabStore,  _ = Window:CreateTab("Store",  nil)
local tabConfig, _ = Window:CreateTab("Config", nil)

-- ── FARM ─────────────────────────────────────────────────────
local secMain = Window:AddCollapsible(tabFarm, "Auto Steal", true)

Window:AddToggle(secMain, "Auto Steal", "Start / stop auto farm", false, function(v)
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
        State.running      = false
        State.busy         = false
        State.lockedRecord = nil
        if _camConn then _camConn:Disconnect(); _camConn = nil end
        Notify("SAE", "Farm stopped.", 2)
        task.delay(0.3, function()
            pcall(function()
                local h2 = hum(); if h2 then h2.Health = 0 end
            end)
        end)
    end
end, "Toggle_AutoSteal")

Window:AddToggle(secMain, "Anti-Guard", "Speed 1000 when returning", true, function(v)
    State.antiGuard = v
end, "Toggle_AntiGuard")

Window:AddToggle(secMain, "Bat Aura", "Spam bat swing (aura kill)", false, function(v)
    State.batAura = v
end, "Toggle_BatAura")

Window:AddInput(secMain, "Walk Speed", "Speed to egg (default 120)", "120", function(v)
    State.speed = tonumber(v) or 120
end, "Input_WalkSpeed")

-- ── AUTO PLACE ────────────────────────────────────────────────
local secPlace = Window:AddCollapsible(tabFarm, "Auto Place", false)

Window:AddToggle(secPlace, "Enable Auto Place", "Plant eggs to plot every X seconds", false, function(v)
    State.placeEnabled = v
    if v then loadModules() end
end, "Toggle_Place")

Window:AddInput(secPlace, "Interval (s)", "How often to place (seconds)", "5", function(v)
    State.placeInterval = tonumber(v) or 5
end, "Input_PlaceInterval")

Window:AddDropdown(secPlace,
    "Min Rarity to Place",
    "Only place eggs at or above this rarity",
    RARITIES, false, "All",
    function(v) State.placeMinRarity = type(v) == "table" and v[1] or v end,
    "Dropdown_PlaceRarity"
)

Window:AddButton(secPlace, "Place Now", "Trigger place immediately", nil, function()
    loadModules(); pcall(runAutoPlace)
    Notify("Place", "Triggered!", 2)
end)

-- ── AUTO HATCH ────────────────────────────────────────────────
local secHatch = Window:AddCollapsible(tabFarm, "Auto Hatch", false)

Window:AddToggle(secHatch, "Enable Auto Hatch", "Hatch eggs every X seconds", false, function(v)
    State.hatchEnabled = v
    if v then loadModules() end
end, "Toggle_Hatch")

Window:AddInput(secHatch, "Interval (s)", "How often to hatch (seconds)", "3", function(v)
    State.hatchInterval = tonumber(v) or 3
end, "Input_HatchInterval")

Window:AddButton(secHatch, "Hatch Now", "Trigger hatch immediately", nil, function()
    loadModules(); pcall(runAutoHatch)
    Notify("Hatch", "Triggered!", 2)
end)

-- ── ESP ───────────────────────────────────────────────────────
local secESP = Window:AddCollapsible(tabFarm, "ESP", false)

Window:AddToggle(secESP, "Egg ESP", "Show rarity/value label on eggs", false, function(v)
    State.espEnabled = v
    if not v then
        for uid in pairs(EspHighlights) do clearESP(uid) end
    end
end, "Toggle_EggESP")

-- ── FARM RARITY FILTER ────────────────────────────────────────
local secRarity = Window:AddCollapsible(tabFarm, "Farm Rarity Filter", false)

Window:AddDropdown(secRarity,
    "Target Rarities",
    "Select rarities to steal (empty = all)",
    RARITIES, true, {},
    function(v) State.targetRarities = v end,
    "Dropdown_FarmRarities"
)

-- ── FARM VALUE FILTER ─────────────────────────────────────────
local secVal = Window:AddCollapsible(tabFarm, "Farm Value Filter", false)

Window:AddInput(secVal, "Min Earning Rate", "Skip eggs below this /hr (0 = off)", "0", function(v)
    State.minEarningRate = tonumber(v) or 0
end, "Input_MinEarning")

Window:AddInput(secVal, "Min Weight", "Skip lighter (0 = off)", "0", function(v)
    State.minModelWeight = tonumber(v) or 0
end, "Input_MinWeight")

Window:AddInput(secVal, "Max Weight", "Skip heavier (0 = off)", "0", function(v)
    local n = tonumber(v) or 0
    State.maxModelWeight = n == 0 and 999999999 or n
end, "Input_MaxWeight")

-- ── STORE — AUTO SELL ─────────────────────────────────────────
local secSell = Window:AddCollapsible(tabStore, "Auto Sell", true)

Window:AddToggle(secSell, "Enable Auto Sell", "Sell eggs every X seconds", false, function(v)
    State.sellEnabled = v
    if v then loadModules() end
end, "Toggle_Sell")

Window:AddInput(secSell, "Interval (s)", "How often to sell (seconds)", "5", function(v)
    State.sellInterval = tonumber(v) or 5
end, "Input_SellInterval")

Window:AddToggle(secSell, "Sell Every Pet", "Sell ALL pets instantly", false, function(v)
    State.sellAll = v
end, "Toggle_SellAll")

Window:AddDropdown(secSell,
    "Sell Max Rarity",
    "Sell pets up to this rarity",
    RARITIES, false, "Epic",
    function(v) State.sellMaxRarity = type(v) == "table" and v[1] or v end,
    "Dropdown_SellMax"
)

Window:AddButton(secSell, "Sell Now", "Trigger sell immediately", nil, function()
    loadModules(); pcall(runAutoSell)
    Notify("Sell", "Triggered!", 2)
end)

-- ── CONFIG ─────────────────────────────────────────────────────
local secCfg = Window:AddCollapsible(tabConfig, "Configuration", true)

Window:AddButton(secCfg, "Save Config", "Save current settings", nil, function()
    pcall(function() Orvion:SaveConfig("SAE_config") end)
    Notify("Config", "Saved!", 2)
end)

Window:AddButton(secCfg, "Load Config", "Load saved settings", nil, function()
    pcall(function() Orvion:LoadConfig("SAE_config") end)
    Notify("Config", "Loaded!", 2)
end)

-- ── SHOW ──────────────────────────────────────────────────
-- Snapshot CoreGui + PlayerGui sebelum Show()
local _beforeShow = {}
local _pg = LocalPlayer:WaitForChild("PlayerGui")
for _, sg in ipairs(game:GetService("CoreGui"):GetChildren()) do _beforeShow[sg] = true end
for _, sg in ipairs(_pg:GetChildren()) do _beforeShow[sg] = true end

Window:Show()
Notify("Steal An Egg", "v2.0 loaded!", 3)

local _orvionSG = nil

-- ============================================================
-- FLOATING TOGGLE BUTTON — SETELAH Window:Show()
-- ============================================================
task.spawn(function()
    task.wait(0.3)

    -- Cari _orvionSG di sini (async, setelah Orvion selesai bikin UI)
    -- Retry sampai ketemu atau timeout 5 detik
    local deadline = tick() + 5
    while not _orvionSG and tick() < deadline do
        for _, sg in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if not _beforeShow[sg] and sg:IsA("ScreenGui") and sg.Name ~= "SAE_FloatBtn" then
                _orvionSG = sg; break
            end
        end
        if not _orvionSG then
            for _, sg in ipairs(_pg:GetChildren()) do
                if not _beforeShow[sg] and sg:IsA("ScreenGui") and sg.Name ~= "SAE_FloatBtn" then
                    _orvionSG = sg; break
                end
            end
        end
        if not _orvionSG then task.wait(0.1) end
    end

    -- Buat button di PlayerGui
    local pg  = LocalPlayer:WaitForChild("PlayerGui")
    local sg2 = Instance.new("ScreenGui")
    sg2.Name           = "SAE_FloatBtn"
    sg2.ResetOnSpawn   = false
    sg2.IgnoreGuiInset = true
    sg2.DisplayOrder   = 9999
    sg2.Parent         = pg

    local btn = Instance.new("ImageButton")
    btn.Size                   = UDim2.new(0, 44, 0, 44)
    btn.Position               = UDim2.new(0, 12, 0.5, -22)
    btn.BackgroundColor3       = Color3.fromRGB(25, 25, 30)
    btn.BackgroundTransparency = 0.3
    btn.Image                  = "rbxassetid://121365062523142"
    btn.ZIndex                 = 10
    btn.Parent                 = sg2
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local st = Instance.new("UIStroke", btn)
    st.Color        = Color3.fromRGB(180, 180, 200)
    st.Thickness    = 1.2
    st.Transparency = 0.5

    -- Drag
    local dragging  = false
    local dragStart = nil
    local btnStart  = nil
    local dragDist  = 0

    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragDist  = 0
            dragStart = inp.Position
            btnStart  = btn.Position
        end
    end)

    btn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UIS.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            local delta = inp.Position - dragStart
            dragDist = delta.Magnitude
            btn.Position = UDim2.new(
                btnStart.X.Scale, btnStart.X.Offset + delta.X,
                btnStart.Y.Scale, btnStart.Y.Offset + delta.Y
            )
        end
    end)

    -- Toggle — pakai _orvionSG yang dicapture setelah Show()
    local uiOpen = true
    btn.MouseButton1Click:Connect(function()
        if dragDist > 6 then dragDist = 0; return end
        uiOpen = not uiOpen
        if _orvionSG then
            _orvionSG.Enabled = uiOpen
        end
    end)
end)
