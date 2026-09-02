-- Dump backpack tools + attributes
local LP = game:GetService("Players").LocalPlayer
print("=== BACKPACK ===")
for _, tool in ipairs(LP.Backpack:GetChildren()) do
    print("Tool:", tool.Name, tool.ClassName)
    for k, v in pairs(tool:GetAttributes()) do
        print("  attr:", k, "=", tostring(v))
    end
end
print("=== CHARACTER TOOLS ===")
local char = LP.Character
if char then
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            print("Tool:", tool.Name)
            for k, v in pairs(tool:GetAttributes()) do
                print("  attr:", k, "=", tostring(v))
            end
        end
    end
end
print("=== DONE ===")
