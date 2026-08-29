-- Test FluentUI v2
local ok, Fluent = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/AlDev14/modded-ui/refs/heads/main/FluentUI.lua"
    ))()
end)
if not ok or not Fluent then warn("[Test] Load failed"); return end

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

local tab1 = Window:AddTab({ Title="Test", Icon="solar/user-bold" })
local sec1  = tab1:AddSection("Section 1")
sec1:AddToggle("T1",{Title="Toggle",Default=false,Callback=function(v) print("T="..tostring(v)) end})
sec1:AddSlider("S1",{Title="Slider",Min=0,Max=10,Default=5,Rounding=0,Callback=function(v) end})
sec1:AddButton({Title="Button",Callback=function() print("click") end})

task.wait(0.5)

-- Debug container
pcall(function()
    -- Coba select tab
    if Window.SelectTab then Window:SelectTab(1) end

    -- Debug Window internals
    local w = Window
    print("[D] Window keys:")
    for k,v in pairs(w) do
        if type(v) ~= "function" then
            print("  "..tostring(k).."="..tostring(v))
        end
    end
end)

-- Force show semua frame
pcall(function()
    if Fluent.GUI then
        local function showAll(inst, depth)
            if depth > 10 then return end
            if inst:IsA("Frame") or inst:IsA("ScrollingFrame") or inst:IsA("CanvasGroup") then
                if inst.Size.X.Offset == 0 and inst.Size.Y.Offset == 0 and inst.Size.X.Scale == 0 and inst.Size.Y.Scale == 0 then
                    print("[D] ZERO SIZE: "..inst:GetFullName())
                end
            end
            for _,c in ipairs(inst:GetChildren()) do showAll(c, depth+1) end
        end
        showAll(Fluent.GUI, 0)
    end
end)

print("[Test] DONE")
