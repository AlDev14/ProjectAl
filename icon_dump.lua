-- ICON DUMP — ambil semua egg icon + DisplayName dari Assets.Directory
local RS = game:GetService("ReplicatedStorage")

local ok, Assets = pcall(function()
    return require(RS.Data.Assets)
end)
if not ok or not Assets then
    warn("Assets nil, coba path lain")
    ok, Assets = pcall(function() return require(RS.Shared.Assets) end)
end
if not ok or not Assets then
    warn("Assets gagal load"); return
end

local dir = Assets.Directory or Assets
local lines = {}
local count = 0

for id, data in pairs(dir) do
    if type(data) == "table" then
        local icon    = data.Icon or ""
        local name    = data.DisplayName or data._id or id
        local rarity  = data.Rarity and (data.Rarity._id or "") or ""
        local earning = data.EarningRate or 0
        table.insert(lines, string.format(
            '    ["%s"] = {Icon="%s", Name="%s", Rarity="%s", Earn=%d},',
            tostring(id), tostring(icon), tostring(name), tostring(rarity), earning
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
