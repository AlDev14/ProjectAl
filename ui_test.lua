-- Test FluentUI
local ok, Fluent = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/AlDev14/modded-ui/refs/heads/main/FluentUI.lua"
    ))()
end)
if not ok or not Fluent then warn("[Test] Load failed: "..tostring(Fluent)); return end
print("[Test] FluentUI loaded OK")

local Window = Fluent:CreateWindow({
    Title    = "UI Test",
    SubTitle = "VD Hub",
    TabWidth = 130,
    Size     = UDim2.fromOffset(500, 380),
    Theme    = "Darker",
    Acrylic  = false,
    MinimizeKey = Enum.KeyCode.RightShift,
})
if not Window then warn("[Test] Window failed"); return end
print("[Test] Window OK")

-- Debug: cek ScreenGui
task.wait(0.5)
pcall(function()
    local CoreGui = game:GetService("CoreGui")
    local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
    
    -- Cek di mana GUI berada
    for _, sg in ipairs(CoreGui:GetChildren()) do
        if sg:IsA("ScreenGui") then
            print("[Test] CoreGui ScreenGui: "..sg.Name.." Enabled="..tostring(sg.Enabled))
        end
    end
    if PlayerGui then
        for _, sg in ipairs(PlayerGui:GetChildren()) do
            if sg:IsA("ScreenGui") then
                print("[Test] PlayerGui ScreenGui: "..sg.Name.." Enabled="..tostring(sg.Enabled))
            end
        end
    end
    
    -- Cek Fluent.GUI
    if Fluent.GUI then
        print("[Test] Fluent.GUI: "..Fluent.GUI.Name.." Parent="..tostring(Fluent.GUI.Parent))
        print("[Test] Fluent.GUI.Enabled="..tostring(Fluent.GUI.Enabled))
    else
        print("[Test] Fluent.GUI = nil!")
    end
end)

local tab1 = Window:AddTab({ Title="Tab 1", Icon="solar/user-bold" })
local tab2 = Window:AddTab({ Title="Tab 2", Icon="solar/eye-bold" })
if not tab1 or not tab2 then warn("[Test] Tabs failed"); return end
print("[Test] Tabs OK")

local sec1 = tab1:AddSection("Section 1")
if not sec1 then warn("[Test] Section failed"); return end
print("[Test] Section OK")

sec1:AddToggle("Toggle1",{Title="Test Toggle",Default=false,Callback=function(v) print("Toggle: "..tostring(v)) end})
print("[Test] Toggle OK")

sec1:AddSlider("Slider1",{Title="Test Slider",Min=0,Max=100,Default=50,Rounding=0,Callback=function(v) print("Slider: "..tostring(v)) end})
print("[Test] Slider OK")

sec1:AddDropdown("Drop1",{Title="Test Dropdown",Values={"A","B","C"},Default="A",Callback=function(v) print("Dropdown: "..tostring(v)) end})
print("[Test] Dropdown OK")

sec1:AddButton({Title="Test Button",Callback=function() print("Button clicked!") end})
print("[Test] Button OK")

local sec2 = tab2:AddSection("Section 2")
sec2:AddToggle("Toggle2",{Title="Another Toggle",Default=true,Callback=function(v) end})
print("[Test] Tab2 Section OK")

Fluent:Notify({Title="UI Test",Content="All elements loaded!",Type="Success",Duration=3})
-- Paksa show window
pcall(function()
    if Window.Show then Window:Show() end
    if Window.Root then Window.Root.Visible = true end
    -- Paksa ScreenGui visible
    if Fluent.GUI then
        Fluent.GUI.Enabled = true
        Fluent.GUI.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end
end)
print("[Test] ALL DONE!")
