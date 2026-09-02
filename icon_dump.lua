-- ICON DUMP — cari Assets.Directory via getgc (no require = no BAC)
-- Output ringkas: satu print per item, gak perlu format Lua
local RS = game:GetService("ReplicatedStorage")

local dir = nil
if type(getgc) == "function" then
    for _, v in ipairs(getgc()) do
        if type(v) == "table" and rawget(v, "Hellhound") then
            local h = rawget(v, "Hellhound")
            if type(h) == "table" and rawget(h, "Icon") and rawget(h, "EarningRate") then
                dir = v
                break
            end
        end
    end
end

if not dir then warn("Assets.Directory not found"); return end

-- Kumpulkan semua dalam satu string besar
local out = {}
for id, data in pairs(dir) do
    if type(data) == "table" then
        local icon    = tostring(data.Icon or "")
        local name    = tostring(data.DisplayName or id)
        local rarity  = data.Rarity and tostring(data.Rarity._id or "") or ""
        table.insert(out, name.."|"..rarity.."|"..icon)
    end
end
table.sort(out)
-- Print semua dalam satu blok
print("=== ICON DUMP ("..#out..") ===\n"..table.concat(out, "\n").."\n=== END ===")
