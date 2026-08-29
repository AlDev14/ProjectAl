-- Test FluentUI Elements
local ok, Fluent = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/AlDev14/modded-ui/refs/heads/main/FluentUI.lua"
    ))()
end)
if not ok or not Fluent then warn("[Test] Load failed"); return end
print("[Test] Fluent type="..type(Fluent))

local Window = Fluent:CreateWindow({
    Title    = "UI Test",
    SubTitle = "VD Hub",
    TabWidth = 130,
    Size     = UDim2.fromOffset(500, 380),
    Theme    = "Darker",
    Acrylic  = false,
    MinimizeKey = Enum.KeyCode.RightShift,
})
if not Window then warn("[Test] Window nil"); return end
print("[Test] Window type="..type(Window))
print("[Test] AddTab="..type(Window.AddTab))

local tab1 = Window:AddTab({ Title="Test", Icon="solar/user-bold" })
print("[Test] tab1 type="..type(tab1))
print("[Test] tab1.AddSection="..tostring(tab1 and type(tab1.AddSection)))

local sec1 = tab1:AddSection("My Section")
print("[Test] sec1 type="..type(sec1))
print("[Test] sec1.AddToggle="..tostring(sec1 and type(sec1.AddToggle)))

local tog = sec1:AddToggle("T1",{Title="Toggle Test",Default=false,Callback=function(v) print("T="..tostring(v)) end})
print("[Test] toggle type="..type(tog))

local sl = sec1:AddSlider("S1",{Title="Slider",Min=0,Max=10,Default=5,Rounding=0,Callback=function(v) end})
print("[Test] slider type="..type(sl))

-- Force show
pcall(function()
    if Fluent.GUI then
        Fluent.GUI.Enabled = true
        Fluent.GUI.Parent = (gethui and gethui()) or game:GetService("CoreGui")
        print("[Test] GUI parent="..tostring(Fluent.GUI.Parent))
    end
end)

print("[Test] DONE")
