-- ============================================================
--  BACKPACK EGG INSPECTOR
--  Toggle panel → list semua Tool di Backpack
--  Klik item → copy nama ke clipboard
-- ============================================================
local Players       = game:GetService("Players")
local UIS           = game:GetService("UserInputService")
local LP            = Players.LocalPlayer
local PG            = LP:WaitForChild("PlayerGui")

-- Hapus instance lama
pcall(function()
    local old = PG:FindFirstChild("EggInspector")
    if old then old:Destroy() end
end)

local SG = Instance.new("ScreenGui")
SG.Name             = "EggInspector"
SG.ResetOnSpawn     = false
SG.IgnoreGuiInset   = true
SG.DisplayOrder     = 999999
SG.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
SG.Parent = (type(gethui)=="function" and pcall(gethui) and gethui()) or PG

-- ============================================================
-- TOGGLE BUTTON
-- ============================================================
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size                  = UDim2.fromOffset(120, 32)
ToggleBtn.Position              = UDim2.new(0.5, -60, 0, 10)
ToggleBtn.BackgroundColor3      = Color3.fromRGB(30, 30, 40)
ToggleBtn.BorderSizePixel       = 0
ToggleBtn.Text                  = "EGG INSPECTOR"
ToggleBtn.TextColor3            = Color3.fromRGB(100, 180, 255)
ToggleBtn.TextSize              = 12
ToggleBtn.Font                  = Enum.Font.GothamBold
ToggleBtn.Parent                = SG
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = ToggleBtn
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(60,120,200); s.Thickness = 1; s.Parent = ToggleBtn
end

-- Drag toggle button
do
    local drag, ds, fp = false
    ToggleBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag=true; ds=i.Position; fp=ToggleBtn.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then drag=false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then
            local d=i.Position-ds
            ToggleBtn.Position=UDim2.new(fp.X.Scale,fp.X.Offset+d.X,fp.Y.Scale,fp.Y.Offset+d.Y)
        end
    end)
end

-- ============================================================
-- PANEL
-- ============================================================
local Panel = Instance.new("Frame")
Panel.Size              = UDim2.fromOffset(280, 360)
Panel.Position          = UDim2.new(0.5,-140,0,50)
Panel.BackgroundColor3  = Color3.fromRGB(15,15,22)
Panel.BorderSizePixel   = 0
Panel.Visible           = false
Panel.Active            = true
Panel.Parent            = SG
do
    local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=Panel
    local s = Instance.new("UIStroke"); s.Color=Color3.fromRGB(55,55,75); s.Thickness=1.5; s.Parent=Panel
end

-- Header
local Header = Instance.new("Frame")
Header.Size             = UDim2.new(1,0,0,34)
Header.BackgroundColor3 = Color3.fromRGB(22,22,32)
Header.BorderSizePixel  = 0
Header.Parent           = Panel
do
    local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=Header
    -- Fix bottom corners
    local fix = Instance.new("Frame")
    fix.Size=UDim2.new(1,0,0.5,0); fix.Position=UDim2.new(0,0,0.5,0)
    fix.BackgroundColor3=Color3.fromRGB(22,22,32); fix.BorderSizePixel=0; fix.Parent=Header
end

local Title = Instance.new("TextLabel")
Title.Size=UDim2.new(1,-70,1,0); Title.Position=UDim2.new(0,12,0,0)
Title.BackgroundTransparency=1; Title.Text="Backpack Eggs"
Title.TextColor3=Color3.fromRGB(235,235,240); Title.TextSize=13
Title.Font=Enum.Font.GothamBold; Title.TextXAlignment=Enum.TextXAlignment.Left
Title.Parent=Header

local CountLbl = Instance.new("TextLabel")
CountLbl.Size=UDim2.fromOffset(60,34); CountLbl.Position=UDim2.new(1,-110,0,0)
CountLbl.BackgroundTransparency=1; CountLbl.Text="0 eggs"
CountLbl.TextColor3=Color3.fromRGB(120,120,140); CountLbl.TextSize=11
CountLbl.Font=Enum.Font.Gotham; CountLbl.Parent=Header

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size=UDim2.fromOffset(28,22); RefreshBtn.Position=UDim2.new(1,-98,0,6)
RefreshBtn.BackgroundColor3=Color3.fromRGB(40,40,55); RefreshBtn.BorderSizePixel=0
RefreshBtn.Text="↺"; RefreshBtn.TextColor3=Color3.fromRGB(100,180,255)
RefreshBtn.TextSize=14; RefreshBtn.Font=Enum.Font.GothamBold; RefreshBtn.Parent=Header
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,5); c.Parent=RefreshBtn end

local CloseBtn2 = Instance.new("TextButton")
CloseBtn2.Size=UDim2.fromOffset(28,22); CloseBtn2.Position=UDim2.new(1,-62,0,6)
CloseBtn2.BackgroundColor3=Color3.fromRGB(40,40,55); CloseBtn2.BorderSizePixel=0
CloseBtn2.Text="×"; CloseBtn2.TextColor3=Color3.fromRGB(220,80,80)
CloseBtn2.TextSize=16; CloseBtn2.Font=Enum.Font.GothamBold; CloseBtn2.Parent=Header
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,5); c.Parent=CloseBtn2 end

local CopyAllBtn = Instance.new("TextButton")
CopyAllBtn.Size=UDim2.new(1,-20,0,26); CopyAllBtn.Position=UDim2.new(0,10,0,38)
CopyAllBtn.BackgroundColor3=Color3.fromRGB(40,100,60); CopyAllBtn.BorderSizePixel=0
CopyAllBtn.Text="COPY ALL NAMES"; CopyAllBtn.TextColor3=Color3.fromRGB(180,255,180)
CopyAllBtn.TextSize=11; CopyAllBtn.Font=Enum.Font.GothamBold; CopyAllBtn.Parent=Panel
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=CopyAllBtn
   local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(60,160,80); s.Thickness=1; s.Parent=CopyAllBtn
end

-- Status label (copy feedback)
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size=UDim2.new(1,-20,0,16); StatusLbl.Position=UDim2.new(0,10,0,68)
StatusLbl.BackgroundTransparency=1; StatusLbl.Text=""
StatusLbl.TextColor3=Color3.fromRGB(100,220,100); StatusLbl.TextSize=10
StatusLbl.Font=Enum.Font.Gotham; StatusLbl.TextXAlignment=Enum.TextXAlignment.Left
StatusLbl.Parent=Panel

-- Scroll list
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size=UDim2.new(1,-10,1,-88); Scroll.Position=UDim2.new(0,5,0,84)
Scroll.BackgroundTransparency=1; Scroll.BorderSizePixel=0
Scroll.ScrollBarThickness=3; Scroll.ScrollBarImageColor3=Color3.fromRGB(60,60,80)
Scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; Scroll.CanvasSize=UDim2.new(0,0,0,0)
Scroll.Parent=Panel
local Layout=Instance.new("UIListLayout"); Layout.Padding=UDim.new(0,3)
Layout.SortOrder=Enum.SortOrder.LayoutOrder; Layout.Parent=Scroll

-- Drag panel
do
    local drag, ds, fp = false
    Header.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=i.Position; fp=Panel.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then drag=false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then
            local d=i.Position-ds
            Panel.Position=UDim2.new(fp.X.Scale,fp.X.Offset+d.X,fp.Y.Scale,fp.Y.Offset+d.Y)
        end
    end)
end

-- ============================================================
-- POPULATE LIST
-- ============================================================
local function clearStatus()
    task.delay(2, function() StatusLbl.Text = "" end)
end

local function copyText(text)
    local ok = false
    pcall(function()
        if type(setclipboard)=="function" then
            setclipboard(text); ok=true
        elseif type(toclipboard)=="function" then
            toclipboard(text); ok=true
        end
    end)
    StatusLbl.Text = ok and ("✓ Copied: " .. text) or ("(no clipboard) " .. text)
    print("[EggInspector] " .. text)
    clearStatus()
end

local function populate()
    -- Clear list
    for _, c in ipairs(Scroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end

    local backpack = LP.Backpack
    local char     = LP.Character
    local tools    = {}

    -- Scan backpack
    for _, t in ipairs(backpack:GetChildren()) do
        if t:IsA("Tool") then table.insert(tools, {tool=t, loc="Backpack"}) end
    end
    -- Scan character juga (yang lagi equipped)
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then table.insert(tools, {tool=t, loc="Equipped"}) end
        end
    end

    CountLbl.Text = #tools .. " tools"

    if #tools == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size=UDim2.new(1,-10,0,30); empty.BackgroundTransparency=1
        empty.Text="No tools found in Backpack"
        empty.TextColor3=Color3.fromRGB(120,120,140); empty.TextSize=11
        empty.Font=Enum.Font.Gotham; empty.Parent=Scroll
        return
    end

    for i, entry in ipairs(tools) do
        local t = entry.tool
        local row = Instance.new("Frame")
        row.Size=UDim2.new(1,-4,0,42); row.BackgroundColor3=Color3.fromRGB(24,24,34)
        row.BorderSizePixel=0; row.LayoutOrder=i; row.Parent=Scroll
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=row end

        -- Loc badge
        local badge = Instance.new("TextLabel")
        badge.Size=UDim2.fromOffset(60,14); badge.Position=UDim2.new(1,-65,0,4)
        badge.BackgroundColor3=entry.loc=="Equipped" and Color3.fromRGB(60,120,60) or Color3.fromRGB(40,40,60)
        badge.BorderSizePixel=0; badge.Text=entry.loc
        badge.TextColor3=Color3.fromRGB(200,220,200); badge.TextSize=9
        badge.Font=Enum.Font.GothamBold; badge.Parent=row
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,4); c.Parent=badge end

        -- Name
        local nameL = Instance.new("TextLabel")
        nameL.Size=UDim2.new(1,-75,0,20); nameL.Position=UDim2.new(0,8,0,4)
        nameL.BackgroundTransparency=1; nameL.Text=t.Name
        nameL.TextColor3=Color3.fromRGB(235,235,240); nameL.TextSize=12
        nameL.Font=Enum.Font.GothamBold; nameL.TextXAlignment=Enum.TextXAlignment.Left
        nameL.TextTruncate=Enum.TextTruncate.AtEnd; nameL.Parent=row

        -- Attributes
        local attrs = {}
        for k, v in pairs(t:GetAttributes()) do
            table.insert(attrs, k.."="..tostring(v))
        end
        local attrStr = #attrs > 0 and table.concat(attrs, "  ") or "no attributes"
        local attrL = Instance.new("TextLabel")
        attrL.Size=UDim2.new(1,-10,0,14); attrL.Position=UDim2.new(0,8,0,24)
        attrL.BackgroundTransparency=1; attrL.Text=attrStr
        attrL.TextColor3=Color3.fromRGB(100,140,180); attrL.TextSize=9
        attrL.Font=Enum.Font.Gotham; attrL.TextXAlignment=Enum.TextXAlignment.Left
        attrL.TextTruncate=Enum.TextTruncate.AtEnd; attrL.Parent=row

        -- Copy button
        local copyBtn = Instance.new("TextButton")
        copyBtn.Size=UDim2.fromOffset(40,20); copyBtn.Position=UDim2.new(1,-48,1,-24)
        copyBtn.BackgroundColor3=Color3.fromRGB(40,80,140); copyBtn.BorderSizePixel=0
        copyBtn.Text="COPY"; copyBtn.TextColor3=Color3.fromRGB(200,220,255)
        copyBtn.TextSize=9; copyBtn.Font=Enum.Font.GothamBold; copyBtn.Parent=row
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,4); c.Parent=copyBtn end

        -- Hover
        row.MouseEnter:Connect(function() row.BackgroundColor3=Color3.fromRGB(32,32,48) end)
        row.MouseLeave:Connect(function() row.BackgroundColor3=Color3.fromRGB(24,24,34) end)

        -- Click row = copy name
        local clickBtn = Instance.new("TextButton")
        clickBtn.Size=UDim2.new(1,-50,1,0); clickBtn.BackgroundTransparency=1
        clickBtn.Text=""; clickBtn.Parent=row
        clickBtn.MouseButton1Click:Connect(function() copyText(t.Name) end)

        -- Copy button = copy full info
        copyBtn.MouseButton1Click:Connect(function()
            local info = t.Name
            -- Tambah Uid kalau ada
            local uid = t:GetAttribute("Uid") or t:GetAttribute("uid") or t:GetAttribute("ID")
            if uid then info = info .. "\nUid: " .. tostring(uid) end
            copyText(info)
        end)
    end
end

-- ============================================================
-- EVENTS
-- ============================================================
ToggleBtn.MouseButton1Click:Connect(function()
    Panel.Visible = not Panel.Visible
    if Panel.Visible then populate() end
end)

RefreshBtn.MouseButton1Click:Connect(function() populate() end)
CloseBtn2.MouseButton1Click:Connect(function() Panel.Visible = false end)

CopyAllBtn.MouseButton1Click:Connect(function()
    local backpack = LP.Backpack
    local char = LP.Character
    local names = {}
    for _, t in ipairs(backpack:GetChildren()) do
        if t:IsA("Tool") then table.insert(names, t.Name) end
    end
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then table.insert(names, t.Name .. " (equipped)") end
        end
    end
    if #names == 0 then
        StatusLbl.Text = "No tools found!"; clearStatus(); return
    end
    local text = table.concat(names, "\n")
    local ok = false
    pcall(function()
        if type(setclipboard)=="function" then setclipboard(text); ok=true
        elseif type(toclipboard)=="function" then toclipboard(text); ok=true end
    end)
    StatusLbl.Text = ok and ("✓ Copied " .. #names .. " names!") or "Printed to console"
    print("=== ALL BACKPACK TOOLS ===")
    print(text)
    print("=== END ===")
    clearStatus()
end)

print("[EggInspector] loaded — klik EGG INSPECTOR buat buka panel")
