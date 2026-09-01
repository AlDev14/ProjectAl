-- ============================================================
--  KOEDINAT PANEL v1.0
--  Simple waypoint recorder — buat bikin jalur farm
--  Save posisi -> list -> TP verify -> EXPORT ke format Lua
-- ============================================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- STATE
-- ============================================================
local Waypoints = {}   -- { {Name=.., Pos=Vector3}, ... }
local Selected  = nil  -- index yang lagi dipilih (buat rename/delete)

-- ============================================================
-- UI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KoedinatPanel"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999998
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 240, 0, 320)
Main.Position = UDim2.new(0.5, -120, 0.3, 0)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 1.5
Stroke.Color = Color3.fromRGB(90, 90, 110)
Stroke.Parent = Main

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 0, 28)
Title.Position = UDim2.new(0, 5, 0, 3)
Title.BackgroundTransparency = 1
Title.Text = "WAYPOINT PANEL"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

local Sub = Instance.new("TextLabel")
Sub.Size = UDim2.new(1, -10, 0, 16)
Sub.Position = UDim2.new(0, 5, 0, 27)
Sub.BackgroundTransparency = 1
Sub.Text = "0 waypoints"
Sub.TextColor3 = Color3.fromRGB(150, 150, 160)
Sub.TextSize = 10
Sub.Font = Enum.Font.Gotham
Sub.Parent = Main

-- List
local ListBG = Instance.new("Frame")
ListBG.Size = UDim2.new(1, -20, 1, -110)
ListBG.Position = UDim2.new(0, 10, 0, 48)
ListBG.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
ListBG.BorderSizePixel = 0
ListBG.Parent = Main

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 6)
ListCorner.Parent = ListBG

local List = Instance.new("ScrollingFrame")
List.Size = UDim2.new(1, -4, 1, -4)
List.Position = UDim2.new(0, 2, 0, 2)
List.BackgroundTransparency = 1
List.BorderSizePixel = 0
List.ScrollBarThickness = 3
List.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 140)
List.AutomaticCanvasSize = Enum.AutomaticSize.Y
List.CanvasSize = UDim2.new(0, 0, 0, 0)
List.Parent = ListBG

-- Buttons row
local function MakeBtn(text, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, -4, 0, 26)
    btn.Position = UDim2.new(0, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = Main
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    return btn
end

local BtnSave  = MakeBtn("SAVE", 258)
BtnSave.Position = UDim2.new(0, 0, 0, 258)
local BtnClear = MakeBtn("CLEAR", 258)
BtnClear.Position = UDim2.new(0.5, 4, 0, 258)
local BtnCopy  = MakeBtn("COPY", 288)
BtnCopy.Position = UDim2.new(0, 0, 0, 288)
local BtnTP    = MakeBtn("TP SEL", 288)
BtnTP.Position = UDim2.new(0.5, 4, 0, 288)

-- ============================================================
-- HELPERS
-- ============================================================
local function GetRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function fmtPos(v)
    return string.format("%.1f, %.1f, %.1f", v.X, v.Y, v.Z)
end

local function RefreshList()
    for _, child in ipairs(List:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    Sub.Text = #Waypoints .. " waypoints"

    local y = 0
    for i, wp in ipairs(Waypoints) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 34)
        row.Position = UDim2.new(0, 4, 0, y)
        row.BackgroundColor3 = (i == Selected) and Color3.fromRGB(50, 70, 110) or Color3.fromRGB(32, 32, 42)
        row.BorderSizePixel = 0
        row.Parent = List

        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(0, 5)
        rc.Parent = row

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -70, 0, 34)
        label.BackgroundTransparency = 1
        label.Text = string.format("%d. %s", i, wp.Name)
        label.TextColor3 = Color3.fromRGB(230, 230, 235)
        label.TextSize = 11
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.Parent = row

        local posLbl = Instance.new("TextLabel")
        posLbl.Size = UDim2.new(1, -70, 0, 14)
        posLbl.Position = UDim2.new(0, 6, 0, 18)
        posLbl.BackgroundTransparency = 1
        posLbl.Text = fmtPos(wp.Pos)
        posLbl.TextColor3 = Color3.fromRGB(140, 140, 155)
        posLbl.TextSize = 9
        posLbl.Font = Enum.Font.Gotham
        posLbl.TextXAlignment = Enum.TextXAlignment.Left
        posLbl.Parent = row

        -- select
        row.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                Selected = (Selected == i) and nil or i
                RefreshList()
            end
        end)

        y += 36
    end
    List.CanvasSize = UDim2.new(0, 0, 0, y)
end

-- ============================================================
-- ACTIONS
-- ============================================================
BtnSave.MouseButton1Click:Connect(function()
    local root = GetRoot()
    if not root then return end
    table.insert(Waypoints, {
        Name = "Point " .. #Waypoints + 1,
        Pos  = root.Position,
    })
    RefreshList()
end)

BtnClear.MouseButton1Click:Connect(function()
    Waypoints = {}
    Selected = nil
    RefreshList()
end)

BtnTP.MouseButton1Click:Connect(function()
    if not Selected then return end
    local root = GetRoot()
    if not root then return end
    local wp = Waypoints[Selected]
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.HumanoidRootPart.CFrame = CFrame.new(wp.Pos)
    end
end)

BtnCopy.MouseButton1Click:Connect(function()
    if #Waypoints == 0 then return end
    local lines = {}
    table.insert(lines, "local PATH = {")
    for _, wp in ipairs(Waypoints) do
        table.insert(lines, string.format(
            '    Vector3.new(%.3f, %.3f, %.3f), -- %s',
            wp.Pos.X, wp.Pos.Y, wp.Pos.Z, wp.Name))
    end
    table.insert(lines, "}")
    local text = table.concat(lines, "\n")

    -- Try clipboard, fallback print
    local copied = false
    pcall(function()
        if type(setclipboard) == "function" then
            setclipboard(text)
            copied = true
        end
    end)
    if copied then
        print("WAYPOINTS COPIED (" .. #Waypoints .. ")")
    else
        print("=== WAYPOINT PATH (Lua) ===")
        print(text)
        print("=== END ===")
    end
end)

-- ============================================================
-- DRAG
-- ============================================================
local Dragging, DragStart, StartPosition = false
Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPosition = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not Dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - DragStart
        Main.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + delta.Y)
    end
end)

-- ============================================================
-- INIT
-- ============================================================
RefreshList()
print("KOEDINAT PANEL loaded — SAVE posisi, TP buat verify, COPY buat export")
