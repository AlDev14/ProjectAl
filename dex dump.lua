-- DEX DUMP COMPACT v2 — output ringkas, muat 1-2 screenshot
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local CS = game:GetService("CollectionService")
local out = {}
local function p(s) table.insert(out, s) end

-- 1. PLOTS
local plots = WS:FindFirstChild("Plots")
p("=PLOTS= " .. (plots and tostring(#plots:GetChildren()).."slots" or "MISSING"))
if plots then
    local first = plots:GetChildren()[1]
    if first then
        p("PlotName:" .. first.Name)
        for k,v in pairs(first:GetAttributes()) do p(" attr:"..k.."="..tostring(v)) end
        for _,c in ipairs(first:GetChildren()) do
            p(" child:"..c.Name.."("..c.ClassName..")")
            for k,v in pairs(c:GetAttributes()) do p("  attr:"..k.."="..tostring(v)) end
        end
    end
end

-- 2. TAGS (singkat)
p("=TAGS=")
for _,tag in ipairs(CS:GetTags()) do
    local n = #CS:GetTagged(tag)
    if n > 0 then p(" "..tag..":"..n) end
end

-- 3. REMOTES (target keyword)
p("=REMOTES=")
local kw = {"WriteAutoSell","FetchAutoSell","SellPet","SellEveryPet","AskPlaceEgg","AskHatch","AskFinishHatch","PlantEgg","DropFieldEgg","Steal","Haul"}
local function scan(inst, d)
    if d > 8 then return end
    for _,c in ipairs(inst:GetChildren()) do
        if c:IsA("RemoteEvent") or c:IsA("RemoteFunction") then
            for _,k in ipairs(kw) do
                if c.Name:find(k,1,true) then
                    p(" "..c:GetFullName())
                end
            end
        end
        scan(c, d+1)
    end
end
scan(RS, 0)

-- 4. PROXIMITY PROMPTS (steal egg only)
p("=PROMPTS=")
local pc = 0
for _,v in ipairs(WS:GetDescendants()) do
    if v:IsA("ProximityPrompt") and pc < 15 then
        p(" "..v.Parent.Name.."|"..v.ActionText.."|hold="..tostring(v.HoldDuration).."|dist="..tostring(v.MaxActivationDistance))
        pc += 1
    end
end
p("total:"..pc)

-- 5. EGG SLOTS
p("=EGGSLOTS=")
local aes = WS:FindFirstChild("AreaEggSlotsClient")
if aes then
    p("count:"..#aes:GetChildren())
    local c = aes:GetChildren()[1]
    if c then
        p("sample:"..c.Name)
        for k,v in pairs(c:GetAttributes()) do p(" "..k.."="..tostring(v)) end
    end
else
    p("MISSING")
end

-- 6. PLOTSTATE FUNCTIONS
p("=PLOTSTATE=")
local ok,PS = pcall(function()
    return require(RS:FindFirstChild("Client",true) and RS.Client:FindFirstChild("PlotState") or RS.Shared.PlotState)
end)
if ok and PS then
    local fns = {}
    for k,v in pairs(PS) do if type(v)=="function" then table.insert(fns,k) end end
    p(table.concat(fns,","))
else
    p("NOT FOUND")
end

-- PRINT ALL
print(table.concat(out, "\n"))
