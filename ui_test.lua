-- Test FluentUI v3
local ok, Fluent = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/AlDev14/modded-ui/refs/heads/main/FluentUI.lua"
    ))()
end)
if not ok or not Fluent then warn("Load failed"); return end

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

local tab1 = Window:AddTab({ Title="Tab1", Icon="solar/user-bold" })
local sec1  = tab1:AddSection("Section 1")
sec1:AddToggle("T1",{Title="Toggle",Default=false,Callback=function(v) print("T="..tostring(v)) end})
sec1:AddSlider("S1",{Title="Slider",Min=0,Max=10,Default=5,Rounding=0,Callback=function(v) end})
sec1:AddButton({Title="Click Me",Callback=function() print("clicked") end})

task.wait(1)

-- Force tab select + debug
pcall(function()
    -- Coba SelectTab
    if Window.SelectTab then
        print("Calling SelectTab(1)")
        Window:SelectTab(1)
    end

    -- Cari ContainerHolder dan force visible
    local gui = Fluent.GUI
    if not gui then print("NO GUI"); return end

    local function debugFrame(inst, depth, prefix)
        if depth > 6 then return end
        local sz = inst.AbsoluteSize
        local vis = inst.Visible
        if (inst:IsA("Frame") or inst:IsA("ScrollingFrame") or inst:IsA("CanvasGroup")) then
            if sz.X < 5 or sz.Y < 5 then
                print(prefix .. "SMALL: " .. inst.Name .. " size=" .. tostring(sz))
            elseif not vis then
                print(prefix .. "HIDDEN: " .. inst.Name)
                inst.Visible = true -- force visible
                print(prefix .. "  -> forced visible")
            end
        end
        for _,c in ipairs(inst:GetChildren()) do
            debugFrame(c, depth+1, prefix.."  ")
        end
    end
    debugFrame(gui, 0, "")
end)

print("DONE")
