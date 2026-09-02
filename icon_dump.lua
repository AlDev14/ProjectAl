-- ICON DUMP — cari Assets.Directory via getgc (no require = no BAC)
local RS = game:GetService("ReplicatedStorage")

-- Cari table yang punya key "Hellhound" = Assets.Directory
local dir = nil
if type(getgc) == "function" then
    for _, v in ipairs(getgc()) do
        if type(v) == "table" and rawget(v, "Hellhound") then
            local h = rawget(v, "Hellhound")
            if type(h) == "table" and rawget(h, "Icon") and rawget(h, "EarningRate") then
                dir = v
                print("Found Assets.Directory via getgc!")
                break
            end
        end
    end
end

if not dir then
    warn("Assets.Directory not found via getgc")
    return
end

local lines = {}
local count = 0

for id, data in pairs(dir) do
    if type(data) == "table" then
        local icon    = tostring(data.Icon or "")
        local name    = tostring(data.DisplayName or data._id or id)
        local rarity  = data.Rarity and tostring(data.Rarity._id or "") or ""
        local earning = tonumber(data.EarningRate) or 0
        table.insert(lines, string.format(
            '    ["%s"] = {Icon="%s", Name="%s", Rarity="%s", Earn=%d},',
            tostring(id), icon, name, rarity, earning
        ))
        count += 1
    end
end

table.sort(lines)
print("-- ASSET ICON TABLE ("..count.." entries)")
print("local ASSET_ICONS = {")
for _, l in ipairs(lines) do print(l) end
print("}")
print("-- TOTAL:", count)
