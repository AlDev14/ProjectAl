-- Test FluentUI - SelectTab Fix
local ok, Fluent = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/AlDev14/modded-ui/refs/heads/main/FluentUI.lua"
    ))()
end)
if not ok or not Fluent then warn("Load failed: "..tostring(Fluent)); return end
print("[Test] Loaded OK")

local Window = Fluent:CreateWindow({
    Title    = "UI Test",
    SubTitle = "VD Hub",
    TabWidth = 130,
    Size     = UDim2.fromOffset(500, 380),
    Theme    = "Darker",
    Acrylic  = false,
    MinimizeKey = Enum.KeyCode.RightShift,
})
if not Window then warn("Window nil"); return end
print("[Test] Window OK")

local tab1 = Window:AddTab({ Title="Tab1", Icon="solar/user-bold" })
local tab2 = Window:AddTab({ Title="Tab2", Icon="solar/eye-bold" })

local sec1 = tab1:AddSection("Section 1")
sec1:AddToggle("T1",{Title="Toggle Test",Default=false,Callback=function(v) print("Toggle="..tostring(v)) end})
sec1:AddSlider("S1",{Title="Slider",Min=0,Max=100,Default=50,Rounding=0,Callback=function(v) print("Slider="..tostring(v)) end})
sec1:AddButton({Title="Click Me",Callback=function() print("Button clicked!") end})

local sec2 = tab2:AddSection("Section 2")
sec2:AddToggle("T2",{Title="Tab2 Toggle",Default=true,Callback=function(v) end})

Fluent:Notify({Title="Test",Content="UI loaded!",Type="Success",Duration=3})
print("[Test] DONE - check if tabs have content")
