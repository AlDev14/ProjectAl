-- ============================================================
-- PLOT SYSTEM — Auto Plant, Place, Sell
-- Dipisah dari Egg.lua untuk reuse & mudah diupdate
-- ============================================================
-- Dipanggil via loadstring dari GitHub
-- Butuh: EggState, PlotState, ReplicatedStorage (dari caller)
-- ============================================================

local PlotSystem = {}

-- ============================================================
-- PLACE EGG via RF Remote (confirmed dari rspy)
-- Format: {Uid = uid, LocalCFrame = cframe}
-- Path: ReplicatedStorage.Packages.Networking["RF/EggWorld/AskPlaceEgg"]
-- ============================================================
function PlotSystem.placeEgg(ReplicatedStorage, EggState, PlotState, uid, localCFrame)
    local ok, result = pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("Packages")
            and ReplicatedStorage.Packages:FindFirstChild("Networking")
            and ReplicatedStorage.Packages.Networking:FindFirstChild("RF/EggWorld/AskPlaceEgg")
        if not remote then
            warn("[PlotSystem] RF/EggWorld/AskPlaceEgg not found")
            return false
        end
        return remote:InvokeServer({
            Uid        = uid,
            LocalCFrame = localCFrame,
        })
    end)
    return ok and result == true
end

-- ============================================================
-- PLACE ALL OWNED EGGS ke Plot
-- ============================================================
function PlotSystem.placeAllEggs(ReplicatedStorage, EggState, PlotState)
    pcall(function()
        if not EggState or not PlotState then return end

        local myPlot = PlotState.ResolvePlot()
        if not myPlot or not myPlot.CenterPoint or not myPlot.PetArea then return end
        local localCFrame = myPlot.CenterPoint.CFrame:ToObjectSpace(
            CFrame.new(myPlot.PetArea.Position)
        )

        local ok, owned = pcall(function() return EggState.ReadOwnedEgg() end)
        if not ok or type(owned) ~= "table" or #owned == 0 then return end

        for _, record in ipairs(owned) do
            if not record.Uid then continue end
            local placed = PlotSystem.placeEgg(ReplicatedStorage, EggState, PlotState, record.Uid, localCFrame)
            if not placed then
                -- Fallback: EggState.PlantEgg langsung
                pcall(function() EggState.PlantEgg(record.Uid, localCFrame) end)
            end
            task.wait(0.05)
        end
    end)
end

-- ============================================================
-- AUTO PLANT (fallback tanpa remote)
-- ============================================================
function PlotSystem.plantStolenEggs(EggState, PlotState)
    pcall(function()
        if not PlotState or not EggState then return end
        local myPlot = PlotState.ResolvePlot()
        if not myPlot or not myPlot.CenterPoint or not myPlot.PetArea then return end
        local localCFrame = myPlot.CenterPoint.CFrame:ToObjectSpace(
            CFrame.new(myPlot.PetArea.Position)
        )
        local ok, owned = pcall(function() return EggState.ReadOwnedEgg() end)
        if not ok or type(owned) ~= "table" then return end
        for _, record in ipairs(owned) do
            if record.Uid then
                pcall(function() EggState.PlantEgg(record.Uid, localCFrame) end)
            end
        end
    end)
end

-- ============================================================
-- SMART AUTO SELL — jual egg di bawah max rarity threshold
-- ============================================================
function PlotSystem.triggerSmartAutoSell(EggState, Assets, getEggRarityNumber, getTargetRarityNumber, autoSellMaxRarity)
    pcall(function()
        if not EggState then return end
        local maxSellNum = getTargetRarityNumber(autoSellMaxRarity)
        local ok, owned = pcall(function() return EggState.ReadOwnedEgg() end)
        if not ok or type(owned) ~= "table" then return end
        for _, record in ipairs(owned) do
            if getEggRarityNumber(record) <= maxSellNum then
                pcall(function()
                    if EggState.DropFieldEgg then
                        EggState.DropFieldEgg(record.Uid)
                    end
                end)
            end
        end
    end)
end

-- ============================================================
-- RESOLVE BASE POSITION dari Plot
-- ============================================================
function PlotSystem.getBasePlotPosition(PlotState, fallbackPos)
    local pos = nil
    pcall(function()
        local myPlot = PlotState.ResolvePlot()
        if myPlot and myPlot.CenterPoint then
            pos = myPlot.CenterPoint.Position
        end
    end)
    return pos or fallbackPos
end

return PlotSystem
