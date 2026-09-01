-- ============================================================
--  DEX DUMP v1.0 — satu kali jalan, semua data yang dibutuhin
--  Print: Plots structure, attributes, tags, remotes, prompts
-- ============================================================
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")

print("========== DUMP START ==========")

-- ============================================================
-- 1. PLOTS FOLDER
-- ============================================================
print("=== 1. PLOTS ===")
local plots = WS:FindFirstChild("Plots")
print("Plots folder:", plots and plots:GetFullName() or "NOT FOUND")
if plots then
    for _, plot in ipairs(plots:GetChildren()) do
        print("  Plot:", plot.Name, "(" .. plot.ClassName .. ")")
        for k, v in pairs(plot:GetAttributes()) do
            print("    attr[" .. k .. "] = " .. tostring(v))
        end
        for _, child in ipairs(plot:GetChildren()) do
            print("    child:", child.Name, "(" .. child.ClassName .. ")")
            for k, v in pairs(child:GetAttributes()) do
                print("      attr[" .. k .. "] = " .. tostring(v))
            end
            if child:IsA("Model") then
                for _, sub in ipairs(child:GetChildren()) do
                    print("      sub:", sub.Name, "(" .. sub.ClassName .. ")")
                end
            end
        end
        break -- cukup 1 plot aja (strukturnya sama)
    end
end

-- ============================================================
-- 2. COLLECTION SERVICE TAGS
-- ============================================================
print("=== 2. TAGS ===")
local cs = game:GetService("CollectionService")
for _, tag in ipairs(cs:GetTags()) do
    print("  Tag:", tag, "-> count:", #cs:GetTagged(tag))
end

-- ============================================================
-- 3. REMOTES (keyword match)
-- ============================================================
print("=== 3. REMOTES ===")
local keywords = {
    "WriteAutoSell", "FetchAutoSell", "SellPet", "SellEveryPet",
    "AskPlaceEgg", "AskHatch", "AskFinishHatch", "PlantEgg",
    "DropFieldEgg", "Steal", "Pickup"
}
local function scan(inst, depth)
    if depth > 7 then return end
    for _, child in ipairs(inst:GetChildren()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction")
            or child:IsA("BindableEvent") or child:IsA("BindableFunction") then
            for _, kw in ipairs(keywords) do
                if child.Name:find(kw, 1, true) then
                    print("  REMOTE:", child:GetFullName(), "(" .. child.ClassName .. ")")
                end
            end
        end
        scan(child, depth + 1)
    end
end
scan(RS, 0)

-- ============================================================
-- 4. PROXIMITY PROMPT (steal egg)
-- ============================================================
print("=== 4. PROXIMITY PROMPTS ===")
local prompts = {}
for _, v in ipairs(WS:GetDescendants()) do
    if v:IsA("ProximityPrompt") then
        table.insert(prompts, v:GetFullName() .. " | ActionText=" .. tostring(v.ActionText))
    end
end
print("  Total prompts:", #prompts)
for i = 1, math.min(#prompts, 30) do
    print("  PROMPT:", prompts[i])
end

-- ============================================================
-- 5. AREA EGG SLOTS (egg di field)
-- ============================================================
print("=== 5. AREA EGG SLOTS ===")
local aes = WS:FindFirstChild("AreaEggSlotsClient")
print("AreaEggSlotsClient:", aes and aes:GetFullName() or "NOT FOUND")
if aes then
    print("  Total children:", #aes:GetChildren())
    local c = 0
    for _, child in ipairs(aes:GetChildren()) do
        if c < 5 then
            print("  egg:", child.Name, "(" .. child.ClassName .. ")")
            for k, v in pairs(child:GetAttributes()) do
                print("    attr[" .. k .. "] = " .. tostring(v))
            end
            -- Cek bagian dalam model egg
            for _, sub in ipairs(child:GetChildren()) do
                print("    child:", sub.Name, "(" .. sub.ClassName .. ")")
            end
        end
        c += 1
    end
end

-- ============================================================
-- 6. PLOTSTATE MODULE (fungsi yang tersedia)
-- ============================================================
print("=== 6. PLOTSTATE MODULE ===")
local ok, PlotState = pcall(function()
    local cur = RS
    for _, seg in ipairs({"Client", "PlotState"}) do
        cur = cur:FindFirstChild(seg)
        if not cur then return nil end
    end
    return require(cur)
end)
if ok and PlotState then
    for k, v in pairs(PlotState) do
        print("  PlotState." .. tostring(k), "=", type(v))
    end
else
    print("  PlotState not found via Client.PlotState, coba Shared.PlotState")
    local ok2, PS2 = pcall(function()
        local cur = RS
        for _, seg in ipairs({"Shared", "PlotState"}) do
            cur = cur:FindFirstChild(seg)
            if not cur then return nil end
        end
        return require(cur)
    end)
    if ok2 and PS2 then
        for k, v in pairs(PS2) do
            print("  PlotState." .. tostring(k), "=", type(v))
        end
    else
        print("  PlotState: NOT FOUND")
    end
end

print("========== DUMP END ==========")
