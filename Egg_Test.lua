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
    -- Auto Place Pet
    placePetEnabled   = false,
    placePetInterval  = 5,
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

-- ============================================================
-- EGG NAME LOOKUP BY RARITY (Source: IGN wiki + in-game confirmed)
-- Tool di Backpack = nama pet saja (tanpa " Egg")
-- ============================================================
-- ============================================================
-- EGG AREA NAMES (biome names di backpack)
-- ============================================================
local AREA_NAMES = {
    "Forest","Lake","Desert","Jungle","Snow","Volcano",
    "Abyss Ocean","Prehistoric","Cosmic","Cherry Blossom","Titan Temple"
}
local AREA_SET = {}
for _, a in ipairs(AREA_NAMES) do AREA_SET[a] = true end

-- Helper: ambil semua egg dari Backpack
-- Identifikasi via ItemType = AssetEgg/PetEgg, atau nama area
local function getEggsFromBackpack(minRarity)
    local result = {}
    local minNum = RARITY_ORDER[minRarity] or 0
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if not tool:IsA("Tool") then continue end
        local itemType = tool:GetAttribute("ItemType")
        -- Egg kalau ItemType = AssetEgg/PetEgg ATAU nama tool ada di AREA_SET
        local isEgg = (itemType == "AssetEgg" or itemType == "PetEgg") or AREA_SET[tool.Name]
        if not isEgg then continue end
        -- Rarity dari attribute atau 0 (unknown)
        local rarNum = 0
        local rarity = "Unknown"
        -- Coba baca rarity dari attribute
        local rarAttr = tool:GetAttribute("Rarity") or tool:GetAttribute("rarity")
        if rarAttr and RARITY_ORDER[rarAttr] then
            rarity = rarAttr
            rarNum = RARITY_ORDER[rarAttr]
        end
        if minNum <= 0 or rarNum >= minNum or rarNum == 0 then
            table.insert(result, {
                tool    = tool,
                name    = tool.Name,
                rarity  = rarity,
                rarNum  = rarNum,
            })
        end
    end
    return result
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
local function walkTo(goal, timeout, isReturning, checkFn)
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

    -- checkFn optional: kalau return false, batalkan walkTo
    -- default: cek State.running (hanya untuk farm cycle)
    local shouldContinue = checkFn or function() return State.running end

    while workspace.DistributedGameTime - t0 < timeout do
        if not shouldContinue() then break end
        task.wait(0.02)
        r  = root(); h2 = hum()
        if not r or not h2 then break end

        local dist = (r.Position - goal).Magnitude

        if dist <= targetDist then
            h2.WalkSpeed = 0
            h2:Move(Vector3.zero, false)
            r.AssemblyLinearVelocity  = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
            -- Snap CFrame tepat ke goal biar gak kelewatan
            pcall(function()
                r.CFrame = CFrame.new(goal) * (r.CFrame - r.CFrame.Position)
            end)
            if isReturning then
                pcall(function() r.CFrame = CFrame.new(START_POS) end)
            end
            break
        end

        -- Brake zone lebih besar biar gak overshoot
        local brake = math.clamp(speed * 0.5, 20, 100)
        if dist <= brake then
            h2.WalkSpeed = math.max(16, speed * (dist/brake)^1.5)
        else
            h2.WalkSpeed = speed
        end
        h2:MoveTo(goal)

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
    if not PlotState then loadModules() end
    if not PlotState then return end
    pcall(function()
        local myPlot = PlotState.ResolvePlot()
        if not myPlot or not myPlot.CenterPoint or not myPlot.PetArea then
            warn("[AutoPlace] ResolvePlot gagal")
            return
        end

        -- Walk ke plot dulu (independent dari State.running)
        local plotPos = myPlot.CenterPoint.Position
        local r = root()
        if r and (r.Position - plotPos).Magnitude > 5 then
            walkTo(plotPos, 15, true, function() return State.placeEnabled end)
        end
        task.wait(0.3)

        local net = ReplicatedStorage:FindFirstChild("Packages")
            and ReplicatedStorage.Packages:FindFirstChild("Networking")
        local placeRemote = net and net:FindFirstChild("RF/EggWorld/AskPlaceEgg")
        local wearRemote  = net and net:FindFirstChild("RF/EggWorld/AskWearTool")
        if not placeRemote then warn("[AutoPlace] AskPlaceEgg not found"); return end

        local localCFrame = myPlot.CenterPoint.CFrame:ToObjectSpace(myPlot.PetArea.CFrame)

        -- Sync dulu dari server biar ReadOwnerEggs up-to-date
        if not EggState then
            print("[AutoPlace] EggState nil"); return
        end

        pcall(function() EggState.SyncOwnedEggs() end)
        task.wait(0.3)

        local ok, owned = pcall(function()
            return EggState.ReadOwnerEggs(LocalPlayer.UserId)
        end)
        if not ok or type(owned) ~= "table" or not next(owned) then
            print("[AutoPlace] owned egg kosong — ok:", ok, "type:", type(owned))
            return
        end

        print("[AutoPlace] owned eggs count:", (function()
            local c = 0; for _ in pairs(owned) do c += 1 end; return c
        end)())

        local minRarNum = RARITY_ORDER[State.placeMinRarity] or 0
        local placed = 0

        for _, rec in ipairs(owned) do
            local uid = rec.Uid
            if not uid then continue end

            -- Filter rarity — kalau gak bisa dibaca, loloskan
            if minRarNum > 0 then
                local rarNum = 0
                if rec.Rarity and type(rec.Rarity) == "table" then
                    rarNum = rec.Rarity.RarityNumber or 0
                elseif rec.RarityNumber and type(rec.RarityNumber) == "number" then
                    rarNum = rec.RarityNumber
                end
                if rarNum > 0 and rarNum < minRarNum then continue end
            end

            -- 1. WearEggTool — equip via remote
            if wearRemote then
                pcall(function() wearRemote:InvokeServer(uid) end)
                task.wait(0.25)
            end

            -- 2. AskPlaceEgg
            local ok3, res = pcall(function()
                return placeRemote:InvokeServer({Uid = uid, LocalCFrame = localCFrame})
            end)
            if ok3 and res then
                placed += 1
                print("[AutoPlace] placed uid:", uid, "asset:", tostring(rec.AssetCategory))
            else
                warn("[AutoPlace] failed uid:", uid, tostring(res))
            end
            task.wait(0.1)
        end
        print(string.format("[AutoPlace] total placed=%d", placed))
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
-- AUTO PLACE PET — scan Backpack ItemType=Asset, pindah ke Character
-- ============================================================
local function runAutoPlacePet()
    if not PlotState then loadModules() end
    if not PlotState then return end
    pcall(function()
        local myPlot = PlotState.ResolvePlot()
        if not myPlot or not myPlot.CenterPoint or not myPlot.PetArea then return end

        -- Walk ke plot
        local plotPos = myPlot.CenterPoint.Position
        local r = root()
        if r and (r.Position - plotPos).Magnitude > 5 then
            walkTo(plotPos, 15, true, function() return State.placePetEnabled end)
        end
        task.wait(0.3)

        local net = ReplicatedStorage:FindFirstChild("Packages")
            and ReplicatedStorage.Packages:FindFirstChild("Networking")
        local placeRemote = net and net:FindFirstChild("RF/EggWorld/AskPlaceEgg")
        if not placeRemote then return end

        local localCFrame = myPlot.CenterPoint.CFrame:ToObjectSpace(myPlot.PetArea.CFrame)

        -- Scan backpack buat pet (ItemType = Asset atau Phone)
        local placed = 0
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if not tool:IsA("Tool") then continue end
            local itemType = tool:GetAttribute("ItemType")
            if itemType ~= "Asset" and itemType ~= "Phone" then continue end

            -- Equip pet
            pcall(function() tool.Parent = LocalPlayer.Character end)
            task.wait(0.15)

            local uid = tool:GetAttribute("Uid") or tool:GetAttribute("uid") or tool.Name
            local ok3, res = pcall(function()
                return placeRemote:InvokeServer({Uid = uid, LocalCFrame = localCFrame})
            end)
            if ok3 and res then
                placed += 1
                print("[AutoPlacePet] placed:", tool.Name)
            else
                pcall(function() tool.Parent = LocalPlayer.Backpack end)
            end
            task.wait(0.1)
        end
        print(string.format("[AutoPlacePet] total placed=%d", placed))
    end)
end

task.spawn(function()
    while true do
        task.wait(State.placePetInterval or 5)
        if State.placePetEnabled then
            if not PlotState then loadModules() end
            pcall(runAutoPlacePet)
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

        -- ReadOwnerEggs(userId) → {[uid]=record}
        local owned = EggState.ReadOwnerEggs(LocalPlayer.UserId)
        if type(owned) ~= "table" then return end

        for uid, rec in pairs(owned) do
            if AskHatch then
                pcall(function() AskHatch:InvokeServer(uid) end)
                task.wait(0.05)
            end
            if AskFinishHatch then
                pcall(function() AskFinishHatch:InvokeServer(uid) end)
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
-- AUTO SELL — AskWearTool + getnilinstances + ToolTrigger
-- Confirmed dari rspy SAE KONTOL.txt
-- ============================================================
local function getToolFromNil(name)
    if type(getnilinstances) ~= "function" then return nil end
    local ok, result = pcall(function()
        for _, obj in ipairs(getnilinstances()) do
            if obj:IsA("Tool") and obj.Name == name then
                return obj
            end
        end
        return nil
    end)
    return ok and result or nil
end

local function runAutoSell()
    pcall(function()
        local net = ReplicatedStorage:FindFirstChild("Packages")
            and ReplicatedStorage.Packages:FindFirstChild("Networking")
        if not net then return end

        -- Sell All pets
        if State.sellAll then
            local remote = net:FindFirstChild("RE/PetSatchel/SellEveryPet")
            if remote then
                remote:FireServer()
                print("[AutoSell] SellEveryPet fired")
            end
            return
        end

        if not EggState then loadModules() end
        if not EggState then warn("[AutoSell] EggState nil"); return end

        local wearRemote    = net:FindFirstChild("RF/EggWorld/AskWearTool")
        local triggerRemote = net:FindFirstChild("RE/ToolTrigger/Trigger")
        if not wearRemote or not triggerRemote then
            warn("[AutoSell] remote missing — wearTool:" .. tostring(wearRemote ~= nil) ..
                 " trigger:" .. tostring(triggerRemote ~= nil))
            return
        end

        local maxNum = getRarityNumberByName(State.sellMaxRarity)
        local ok, owned = pcall(function() return EggState.ReadOwnedEgg() end)
        if not ok or type(owned) ~= "table" or #owned == 0 then
            print("[AutoSell] owned egg kosong")
            return
        end

        local sold, skipped = 0, 0
        for _, rec in ipairs(owned) do
            if not rec.Uid then continue end
            local rarNum = getRarityNumber(rec)
            if rarNum > maxNum then skipped += 1; continue end

            -- 1. Equip egg via AskWearTool
            local ok2, toolName = pcall(function()
                return wearRemote:InvokeServer(rec.Uid)
            end)

            task.wait(0.2)

            -- 2. Cari tool di nil instances (egg masuk nil setelah equip)
            local eggName = rec.AssetCategory or rec.DisplayName
                or (rec.Rarity and rec._id) or tostring(rec.Uid)

            local tool = nil
            -- Cari di nil instances
            tool = getToolFromNil(eggName)
            -- Fallback: scan character
            if not tool then
                local char = LocalPlayer.Character
                if char then
                    tool = char:FindFirstChildOfClass("Tool")
                end
            end

            if tool then
                -- 3. Trigger sell via ToolTrigger
                pcall(function() triggerRemote:FireServer(tool) end)
                sold += 1
                print("[AutoSell] sold: " .. tostring(eggName))
            else
                warn("[AutoSell] tool not found for: " .. tostring(eggName))
            end
            task.wait(0.3)
        end
        print(string.format("[AutoSell] sold=%d skipped=%d", sold, skipped))
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
-- OBSIDIAN UI
-- ============================================================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library     = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local function Notify(title, text, dur)
    pcall(function()
        Library:Notify({
            Title    = title,
            Content  = text,
            Duration = dur or 3,
        })
    end)
end

local RARITIES = {
    "Common","Uncommon","Rare","Epic","Legendary","Mythic",
    "SuperRare","Exotic","Limited","Divine","Secret","Titan",
    "Cosmic","Celestial","Transcendent","Prismatic","Rainbow",
    "Eternal","Brainrot","Mythical","Exclusive"
}

local Window = Library:CreateWindow({
    Title    = "Steal An Egg",
    Footer   = "v2.0",
    AutoShow = true,
    Center   = true,
})

local Tabs = {
    Farm   = Window:AddTab("Farm",   "wheat"),
    Store  = Window:AddTab("Store",  "shopping-bag"),
    Config = Window:AddTab("Config", "settings"),
}

-- ── FARM LEFT — Auto Steal ────────────────────────────────────
local grpSteal = Tabs.Farm:AddLeftGroupbox("Auto Steal")

grpSteal:AddToggle("AutoSteal", {
    Text    = "Auto Steal",
    Default = false,
    Callback = function(v)
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
            task.delay(0.3, function()
                pcall(function() LocalPlayer:LoadCharacter() end)
            end)
        end
    end,
})

grpSteal:AddToggle("AntiGuard", {
    Text    = "Anti-Guard",
    Default = true,
    Callback = function(v) State.antiGuard = v end,
})

grpSteal:AddToggle("BatAura", {
    Text    = "Bat Aura",
    Default = false,
    Callback = function(v) State.batAura = v end,
})

grpSteal:AddSlider("WalkSpeed", {
    Text     = "Walk Speed",
    Default  = 120,
    Min      = 16,
    Max      = 500,
    Rounding = 0,
    Callback = function(v) State.speed = v end,
})

-- Rarity Filter
grpSteal:AddDropdown("FarmRarities", {
    Values   = RARITIES,
    Default  = 1,
    Multi    = true,
    Text     = "Target Rarities",
    Tooltip  = "Kosong = steal semua",
    Callback = function(v)
        State.targetRarities = {}
        for k, sel in pairs(v) do
            if sel then State.targetRarities[k] = true end
        end
    end,
})

-- ── FARM RIGHT — Visual ───────────────────────────────────────
local grpVisual = Tabs.Farm:AddRightGroupbox("Visual")

grpVisual:AddToggle("EggESP", {
    Text    = "Egg ESP",
    Default = false,
    Callback = function(v)
        State.espEnabled = v
        if not v then for uid in pairs(EspHighlights) do clearESP(uid) end end
    end,
})

grpVisual:AddToggle("FloatVis", {
    Text    = "Float (visual)",
    Default = false,
    Tooltip = "Client-side, cuma lo yang liat",
    Callback = function(v) State.floatEnabled = v; updateFloat() end,
})

grpVisual:AddSlider("FloatHeight", {
    Text     = "Float Height",
    Default  = 3,
    Min      = 1,
    Max      = 10,
    Rounding = 0,
    Callback = function(v) State.floatHeight = v end,
})

grpVisual:AddToggle("AnimToggle", {
    Text    = "Animation",
    Default = true,
    Tooltip = "Off = R6 tegak diam",
    Callback = function(v) State.animEnabled = v; updateAnim() end,
})

-- ── FARM LEFT — Place & Hatch ─────────────────────────────────
local grpPlace = Tabs.Farm:AddLeftGroupbox("Auto Place Egg")

grpPlace:AddToggle("PlaceEgg", {
    Text    = "Enable",
    Default = false,
    Callback = function(v) State.placeEnabled = v; if v then loadModules() end end,
})

grpPlace:AddSlider("PlaceInterval", {
    Text = "Interval (s)", Default = 5, Min = 1, Max = 30, Rounding = 0,
    Callback = function(v) State.placeInterval = v end,
})

grpPlace:AddDropdown("PlaceMinRarity", {
    Values   = RARITIES,
    Default  = 1,
    Text     = "Min Rarity",
    Callback = function(v) State.placeMinRarity = v end,
})

grpPlace:AddButton({ Text = "Place Now", Func = function()
    loadModules(); pcall(runAutoPlace); Notify("Place","Triggered!",2)
end })

local grpPlacePet = Tabs.Farm:AddLeftGroupbox("Auto Place Pet")

grpPlacePet:AddToggle("PlacePet", {
    Text    = "Enable",
    Default = false,
    Callback = function(v) State.placePetEnabled = v; if v then loadModules() end end,
})
grpPlacePet:AddSlider("PlacePetInterval", {
    Text = "Interval (s)", Default = 5, Min = 1, Max = 30, Rounding = 0,
    Callback = function(v) State.placePetInterval = v end,
})
grpPlacePet:AddButton({ Text = "Place Pet Now", Func = function()
    loadModules(); pcall(runAutoPlacePet); Notify("Place Pet","Triggered!",2)
end })

local grpHatch = Tabs.Farm:AddRightGroupbox("Auto Hatch")

grpHatch:AddToggle("HatchEgg", {
    Text    = "Enable",
    Default = false,
    Callback = function(v) State.hatchEnabled = v; if v then loadModules() end end,
})

grpHatch:AddSlider("HatchInterval", {
    Text = "Interval (s)", Default = 3, Min = 1, Max = 30, Rounding = 0,
    Callback = function(v) State.hatchInterval = v end,
})

grpHatch:AddButton({ Text = "Hatch Now", Func = function()
    loadModules(); pcall(runAutoHatch); Notify("Hatch","Triggered!",2)
end })

-- Value Filter
local grpVal = Tabs.Farm:AddRightGroupbox("Value Filter")

grpVal:AddInput("MinEarning", {
    Default = "0", Numeric = true, Finished = true,
    Text = "Min Earning Rate", Placeholder = "0 = off",
    Callback = function(v) State.minEarningRate = tonumber(v) or 0 end,
})
grpVal:AddInput("MinWeight", {
    Default = "0", Numeric = true, Finished = true,
    Text = "Min Weight", Placeholder = "0 = off",
    Callback = function(v) State.minModelWeight = tonumber(v) or 0 end,
})
grpVal:AddInput("MaxWeight", {
    Default = "0", Numeric = true, Finished = true,
    Text = "Max Weight", Placeholder = "0 = off",
    Callback = function(v)
        local n = tonumber(v) or 0
        State.maxModelWeight = n == 0 and 999999999 or n
    end,
})

-- ── STORE ─────────────────────────────────────────────────────
local grpSell = Tabs.Store:AddLeftGroupbox("Auto Sell")

grpSell:AddToggle("SellEnable", {
    Text = "Enable Auto Sell", Default = false,
    Callback = function(v) State.sellEnabled = v; if v then loadModules() end end,
})
grpSell:AddToggle("SellAll", {
    Text = "Sell Every Pet", Default = false,
    Callback = function(v) State.sellAll = v end,
})
grpSell:AddSlider("SellInterval", {
    Text = "Interval (s)", Default = 5, Min = 1, Max = 60, Rounding = 0,
    Callback = function(v) State.sellInterval = v end,
})
grpSell:AddDropdown("SellMaxRarity", {
    Values = RARITIES, Default = "Epic", Text = "Sell Max Rarity",
    Callback = function(v) State.sellMaxRarity = v end,
})
grpSell:AddButton({ Text = "Sell Now", Func = function()
    loadModules(); pcall(runAutoSell); Notify("Sell","Triggered!",2)
end })

-- ── CONFIG ─────────────────────────────────────────────────────
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("SAE_Test")
SaveManager:BuildConfigSection(Tabs.Config)
ThemeManager:ApplyToTab(Tabs.Config)

Notify("Steal An Egg", "v2.0 loaded!", 3)
