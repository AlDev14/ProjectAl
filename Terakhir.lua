-- ============================================================
-- WISNU HUB v2.0 (FluentPro Native) - Full W424 Integration
-- ESP + SILENT AIM + SURVIVOR + KILLER + MISC + UI SETTINGS
-- FLOATING BUTTON: TRANSPARAN (HANYA ICON)
-- + Gen Bypass + Moonwalk (WisnuVip) + Skill Check Upgrade
-- + Mask Selection + Hitbox Expander + Draggable FPS/Ping
-- + Killer Prediction (Spectator)
-- + Double Damage Generator + Custom FOV + Remove Visual Effects
-- + ESP Gate
-- + SILENT AIM DIPERBAIKI (OxioHub) + SISTEM KEY ONYX
-- URUTAN TAB: Survivor → ESP → Killer → Aim → Misc → UI Settings
-- ============================================================

-- ============================================================
-- 🔐 SISTEM KEY ONYX (DARI WISNU VIP)
-- ============================================================
local Onyx = loadstring(game:HttpGet("https://cdn.jnkie.com/OnyxUI.lua"))()

Onyx.Appearance = {
    Title = "Wisnu Hub",
    Subtitle = "Enter your key to continue",
    KeylessTitle = "Wisnu Hub",
    KeylessSubtitle = "No key required for this build - you're verified.",
    Icon = "rbxassetid://96848424314690",
}

Onyx.Links = {
    GetKey = "https://discord.gg/fZzN5HhFB",
    Discord = "https://discord.gg/fZzN5HhFB",
}

Onyx.Storage = {
    FileName = "WisnuHub_key",
    Remember = true,
    AutoLoad = true,
}

Onyx.Shop = {
    Enabled = false,
    Icon = "",
    Title = "Get Key",
    Subtitle = "Buy VIP key",
    ButtonText = "Buy",
    Link = "https://discord.gg/fZzN5HhFB"
}

Onyx.Callbacks.OnSuccess = function()
    -- ============================================================
    -- SCRIPT UTAMA (VVind-UI)
    -- ============================================================
    local VindUI
    do
        local ok, r = pcall(function()
            return loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/Skinny-yz/VVind-UI/refs/heads/main/src.lua"
            ))()
        end)
        if ok and r then VindUI = r
        else warn("[WisnuHub] VVind-UI gagal load: "..tostring(r)); return end
    end

    local function Notify(title, text, ntype, dur)
        pcall(function()
            VindUI:Notify({Title=title, Text=text, Type=ntype or "info", Duration=dur or 3})
        end)
    end
    -- Fluent shim agar Fluent:Notify calls tidak error
    local Fluent = { Notify = function(_, cfg)
        Notify(cfg.Title or "", cfg.Content or cfg.Text or "", (cfg.Type or "info"):lower(), cfg.Duration or 3)
    end }

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local CollectionService = game:GetService("CollectionService")
    local UserInputService = game:GetService("UserInputService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local Camera = Workspace.CurrentCamera
    local Lighting = game:GetService("Lighting")
    local Stats = game:GetService("Stats")
    local TweenService = game:GetService("TweenService")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local CoreGui = game:GetService("CoreGui")

    -- ============================================================
    -- GLOBAL CONFIG (VD)
    -- ============================================================
    getgenv().VD = getgenv().VD or {}
    local VD = getgenv().VD

    -- ESP
    VD.ESP_Enabled          = VD.ESP_Enabled          or false
    VD.ESP_Survivor         = VD.ESP_Survivor         or true
    VD.ESP_Killer           = VD.ESP_Killer           or true
    VD.ESP_Generator        = VD.ESP_Generator        or true
    VD.ESP_Pallet           = VD.ESP_Pallet           or true
    VD.ESP_Window           = VD.ESP_Window           or true
    VD.ESP_SCP              = VD.ESP_SCP              or true
    VD.ESP_Gate             = VD.ESP_Gate             or true
    VD.ESP_Distance         = VD.ESP_Distance         or 5000
    VD.ESP_ShowItem         = VD.ESP_ShowItem         or true

    -- Silent Aim (Pistol) - DIUPDATE DARI OXIO
    VD.Pistol_SilentAim     = VD.Pistol_SilentAim     or false
    VD.Pistol_BlockKnocked  = VD.Pistol_BlockKnocked  or false
    VD.Pistol_LockAim       = VD.Pistol_LockAim       or false
    VD.Pistol_Target        = VD.Pistol_Target        or "Killer"
    VD.Pistol_FOVMode       = VD.Pistol_FOVMode       or false
    VD.Pistol_ShowFOV       = VD.Pistol_ShowFOV       or false
    VD.Pistol_FOV           = VD.Pistol_FOV           or 150
    VD.Pistol_TargetPart    = VD.Pistol_TargetPart    or "Torso"
    VD.Pistol_HideLaser     = VD.Pistol_HideLaser     or false

    -- Silent Aim (Flash)
    VD.Flash_SilentAim      = VD.Flash_SilentAim      or false
    VD.Flash_YOffset        = VD.Flash_YOffset        or 8

    -- Silent Aim (Veil)
    VD.Veil_SilentAim       = VD.Veil_SilentAim       or false

    -- Survivor
    VD.AutoSkillcheck       = VD.AutoSkillcheck       or false
    VD.AutoSkillcheckMode   = VD.AutoSkillcheckMode   or "Normal"
    VD.Surv_ParryRange      = VD.Surv_ParryRange      or 15
    VD.Surv_ParrySafety     = VD.Surv_ParrySafety     or false
    VD.Surv_ParryAggressive = VD.Surv_ParryAggressive or false
    VD.Surv_ParryFace       = VD.Surv_ParryFace       or 0.7
    VD.Surv_AutoCrouch      = VD.Surv_AutoCrouch      or false
    VD.Surv_AutoDropPallet  = VD.Surv_AutoDropPallet  or false
    VD.Surv_AutoDropPalletDist = VD.Surv_AutoDropPalletDist or 6
    VD.Surv_AntiKnock       = VD.Surv_AntiKnock       or false
    VD.Surv_AutoParry       = VD.Surv_AutoParry       or false

    -- Killer
    VD.UnlimitedVault       = VD.UnlimitedVault       or false
    VD.UnlockSkillsCarry    = VD.UnlockSkillsCarry    or false
    VD.AutoStalk            = VD.AutoStalk            or false
    VD.SpearGravity         = VD.SpearGravity         or 50
    VD.SpearSpeed           = VD.SpearSpeed           or 100

    -- Hitbox Expander
    VD.HitboxExpander       = VD.HitboxExpander       or false
    VD.HitboxSize           = VD.HitboxSize           or 15

    -- Visual
    VD.NoShadow             = VD.NoShadow             or false
    VD.LowGraphics          = VD.LowGraphics          or false
    VD.Fullbright           = VD.Fullbright           or false
    VD.NoFog                = VD.NoFog                or false
    VD.ReduceMap            = VD.ReduceMap            or false
    VD.RemoveVisualEffects  = VD.RemoveVisualEffects  or false

    -- FPS & Ping Counter
    VD.ShowFPS              = VD.ShowFPS              or false
    VD.ShowPing             = VD.ShowPing             or false

    -- Gen Bypass
    VD.GenBypass_Enabled    = VD.GenBypass_Enabled    or false
    VD.GenBypass_Hotkey     = VD.GenBypass_Hotkey     or Enum.KeyCode.G

    -- Moonwalk
    VD.Moonwalk_Enabled     = VD.Moonwalk_Enabled     or false
    VD.Moonwalk_Hotkey      = VD.Moonwalk_Hotkey      or Enum.KeyCode.G

    -- Mask Selection
    VD.MaskSelection_Enabled = VD.MaskSelection_Enabled or false

    -- Killer Prediction
    VD.KillerPredict_Enabled = VD.KillerPredict_Enabled or false
    VD.KillerPredict_Interval = VD.KillerPredict_Interval or 3

    -- Double Damage Generator
    VD.DoubleDamageGen      = VD.DoubleDamageGen      or false

    -- Custom FOV
    VD.CustomFOV            = VD.CustomFOV            or false
    VD.FOVValue             = VD.FOVValue             or 100

    -- ============================================================
    -- HELPER FUNCTIONS
    -- ============================================================
    local function getRoot()
        return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end

    local function IsKiller(player)
        if not player or not player.Team then return false end
        local name = player.Team.Name
        return name == "Killer" or name == "Killers"
    end

    local ItemsFolder = ReplicatedStorage:WaitForChild("Items", 5)
    function extractAssetId(str)
        return tostring(str):match("%d+")
    end

    function getItemIcon(itemName)
        if not ItemsFolder then return nil end
        local item = ItemsFolder:FindFirstChild(itemName)
        if not item then return nil end
        local tex
        pcall(function() tex = item.Texture or item.Image end)
        if tex and tex ~= "" then
            local id = extractAssetId(tex)
            if id then
                return ("rbxthumb://type=Asset&id=%s&w=420&h=420"):format(id)
            end
        end
        return nil
    end

    -- ============================================================
    -- FAKE AVATAR (KORLESS MORPH)
    -- ============================================================
    local KorlessMorph = { Enabled = false, Connection = nil }

    local function ApplyKorless()
        local plr = game.Players.LocalPlayer
        local function Morph()
            repeat task.wait()
            until plr.Character
                and plr.Character:FindFirstChild("HumanoidRootPart")
                and plr.Character:FindFirstChild("Right Leg")
            task.wait(0.1)
            local char = plr.Character
            pcall(function()
                char.Head.Transparency = 1
                local face = char.Head:FindFirstChild("face")
                if face then face:Destroy() end
                char["Right Leg"].Transparency = 1
                -- Hapus KorlessHead lama kalau ada
                local old = char:FindFirstChild("KorlessHead")
                if old then old:Destroy() end
                local mesh = Instance.new("MeshPart")
                mesh.Name = "KorlessHead"
                mesh.Size = Vector3.new(1.5, 1.5, 1.5)
                mesh.CanCollide = false
                mesh.MeshId = "rbxassetid://902942096"
                mesh.TextureID = "rbxassetid://902843398"
                mesh.CFrame = char["Right Leg"].CFrame * CFrame.new(0, 0.5, 0)
                mesh.Parent = char
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = char["Right Leg"]
                weld.Part1 = mesh
                weld.Parent = mesh
            end)
        end
        Morph()
        if KorlessMorph.Connection then KorlessMorph.Connection:Disconnect() end
        KorlessMorph.Connection = plr.CharacterAdded:Connect(function()
            task.wait(1); Morph()
        end)
    end

    local function RemoveKorless()
        if KorlessMorph.Connection then
            KorlessMorph.Connection:Disconnect()
            KorlessMorph.Connection = nil
        end
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            -- Restore head
            char.Head.Transparency = 0
            local face = char.Head:FindFirstChild("face")
            if not face then
                local f = Instance.new("Decal")
                f.Name = "face"
                f.Texture = "rbxasset://textures/face.png"
                f.Parent = char.Head
            end
            -- Restore right leg
            char["Right Leg"].Transparency = 0
            -- Remove mesh
            local mesh = char:FindFirstChild("KorlessHead")
            if mesh then mesh:Destroy() end
        end)
    end

    -- ============================================================
    -- ESP SYSTEM
    -- ============================================================
    local highlights = {}
    local billboards = {}
    local COLORS = {
        Survivor  = Color3.fromRGB(0, 255, 0),
        Killer    = Color3.fromRGB(255, 0, 0),
        Generator = Color3.fromRGB(128, 0, 255),
        Pallet    = Color3.fromRGB(0, 200, 255),
        Window    = Color3.fromRGB(255, 255, 0),
        SCP       = Color3.fromRGB(255, 165, 0),
        Gate      = Color3.fromRGB(255, 255, 255),
    }

    local function createHighlight(obj, color)
        if not obj then return end
        if highlights[obj] then highlights[obj]:Destroy(); highlights[obj] = nil end
        local h = Instance.new("Highlight")
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = 0.7
        h.OutlineTransparency = 0.2
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = obj
        highlights[obj] = h
    end

    local function removeHighlight(obj)
        if highlights[obj] then highlights[obj]:Destroy(); highlights[obj] = nil end
    end

    local function createBillboard(obj, text, color)
        if not obj then return end
        if billboards[obj] then billboards[obj]:Destroy(); billboards[obj] = nil end
        local bg = Instance.new("BillboardGui")
        bg.Size = UDim2.new(0, 80, 0, 20)
        bg.AlwaysOnTop = true
        bg.StudsOffset = Vector3.new(0, 3, 0)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 1, 1, 1)
        lbl.BackgroundTransparency = 1
        lbl.Text = text or ""
        lbl.TextColor3 = color or Color3.new(1,1,1)
        lbl.TextStrokeTransparency = 0
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 10
        lbl.Parent = bg
        bg.Adornee = obj
        bg.Parent = obj
        billboards[obj] = bg
    end

    local function removeBillboard(obj)
        if billboards[obj] then billboards[obj]:Destroy(); billboards[obj] = nil end
    end

    local function clearESP()
        for obj in pairs(highlights) do removeHighlight(obj) end
        for obj in pairs(billboards) do removeBillboard(obj) end
        highlights = {}
        billboards = {}
    end

    local function isSCP(obj)
        if not obj then return false end
        local name = obj.Name or ""
        if not name:lower():find("scp") then return false end
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then return false end
        if obj:FindFirstChild("Generator") or obj:FindFirstChild("PalletPoint") or obj.Name == "Window" then return false end
        if obj:IsA("BasePart") then
            local model = obj:FindFirstAncestorOfClass("Model")
            if model and model:FindFirstChild("Humanoid") then return false end
        end
        return true
    end

    function CreateModernESP(parent, idName, config)
        local billboard = parent:FindFirstChild(idName)
        if not billboard then
            billboard = Instance.new("BillboardGui")
            billboard.Name = idName
            billboard.Parent = parent
            billboard.AlwaysOnTop = true
            billboard.Size = UDim2.new(0, 200, 0, 25)
            local yOffset = config.offsetY or 3.5
            billboard.StudsOffset = Vector3.new(0, yOffset, 0)

            local box = Instance.new("Frame")
            box.Name = "Box"
            box.AutomaticSize = Enum.AutomaticSize.X
            box.Size = UDim2.new(0, 0, 0, 15)
            box.Position = UDim2.new(0.5, 0, 0, 0)
            box.AnchorPoint = Vector2.new(0.5, 0)
            box.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            box.BackgroundTransparency = 0
            box.BorderSizePixel = 0
            box.ZIndex = 2
            box.Parent = billboard
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)
            local boxGradient = Instance.new("UIGradient")
            boxGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.15, 0.35),
                NumberSequenceKeypoint.new(0.85, 0.35),
                NumberSequenceKeypoint.new(1, 1)
            })
            boxGradient.Parent = box

            local padding = Instance.new("UIPadding", box)
            padding.PaddingLeft = UDim.new(0, 8)
            padding.PaddingRight = UDim.new(0, 8)

            local layout = Instance.new("UIListLayout", box)
            layout.FillDirection = Enum.FillDirection.Horizontal
            layout.VerticalAlignment = Enum.VerticalAlignment.Center
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            layout.Padding = UDim.new(0, 3)
            layout.SortOrder = Enum.SortOrder.LayoutOrder

            local icon = Instance.new("ImageLabel", box)
            icon.Name = "Icon"
            icon.Size = UDim2.new(0, 12, 0, 12)
            icon.BackgroundTransparency = 1
            icon.ZIndex = 3
            icon.LayoutOrder = 1
            icon.Visible = false

            local txt = Instance.new("TextLabel", box)
            txt.Name = "Text"
            txt.AutomaticSize = Enum.AutomaticSize.X
            txt.Size = UDim2.new(0, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.Font = Enum.Font.GothamMedium
            txt.TextSize = 10
            txt.ZIndex = 3
            txt.LayoutOrder = 2
            txt.RichText = true
            txt.TextXAlignment = Enum.TextXAlignment.Center
            txt.TextYAlignment = Enum.TextYAlignment.Center

            local line = Instance.new("Frame")
            line.Name = "Line"
            line.Size = UDim2.new(0, 1, 0, 10)
            line.Position = UDim2.new(0.5, 0, 0, 15)
            line.AnchorPoint = Vector2.new(0.5, 0)
            line.BorderSizePixel = 0
            line.ZIndex = 1
            line.Parent = billboard
            local lineGradient = Instance.new("UIGradient")
            lineGradient.Rotation = 90
            lineGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1)
            })
            lineGradient.Parent = line
        end

        billboard.Line.BackgroundColor3 = config.color

        local iconLabel = billboard.Box:FindFirstChild("Icon")
        if config.icon and config.icon ~= "" then
            if iconLabel then
                iconLabel.Image = config.icon
                iconLabel.Visible = true
            end
        else
            if iconLabel then
                iconLabel.Visible = false
            end
        end

        local hexColor = string.format("#%02X%02X%02X", config.color.R * 255, config.color.G * 255, config.color.B * 255)
        if config.distance then
            billboard.Box.Text.Text = string.format("<font color='#FFFFFF'>%s</font> <font color='%s'>[%dm]</font>", config.name, hexColor, config.distance)
        elseif config.subtext then
            billboard.Box.Text.Text = string.format("<font color='#FFFFFF'>%s</font> <font color='%s'>%s</font>", config.name, hexColor, config.subtext)
        else
            billboard.Box.Text.Text = string.format("<font color='#FFFFFF'>%s</font>", config.name)
        end
    end

    function RemoveModernESP(parent, idName)
        local esp = parent:FindFirstChild(idName)
        if esp then esp:Destroy() end
    end

    local function updateESP()
        clearESP()
        if not VD.ESP_Enabled then return end
        local root = getRoot()
        if not root then return end
        local maxDist = VD.ESP_Distance

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local char = player.Character
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dist = (hrp.Position - root.Position).Magnitude
                        if dist <= maxDist then
                            local color
                            local isKiller = IsKiller(player)
                            if isKiller then
                                -- Sembunyikan ESP killer saat Veil silent aim aktif (reduce noise)
                                if VD.ESP_Killer and not (VD.Veil_SilentAim and isAimingVeil) then
                                    color = COLORS.Killer
                                end
                            else
                                if VD.ESP_Survivor then color = COLORS.Survivor end
                            end
                            if color then
                                createHighlight(char, color)
                            else
                                -- Hapus highlight lama kalau tidak ada color (disabled/hidden)
                                removeHighlight(char)
                                local itemIcon = nil
                                if VD.ESP_ShowItem then
                                    local equipped = player:GetAttribute("EquippedItem") or char:GetAttribute("EquippedItem")
                                    if equipped then
                                        itemIcon = getItemIcon(equipped)
                                    end
                                end
                                CreateModernESP(char, "ModernESPName", {
                                    name = player.Name,
                                    distance = math.floor(dist),
                                    color = color,
                                    icon = itemIcon,
                                    offsetY = 3.5
                                })
                            end
                        end
                    end
                end
            end
        end

        if VD.ESP_Generator then
            for _, gen in ipairs(CollectionService:GetTagged("Generator")) do
                if gen and gen:IsDescendantOf(Workspace) then
                    local part = gen:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local dist = (part.Position - root.Position).Magnitude
                        if dist <= maxDist then
                            createHighlight(gen, COLORS.Generator)
                            local progress = gen:GetAttribute("RepairProgress") or gen:GetAttribute("Progress") or 0
                            if progress < 100 then
                                createBillboard(gen, string.format("[%.0f%%]", progress), COLORS.Generator)
                            end
                        end
                    end
                end
            end
        end

        if VD.ESP_Pallet then
            for _, pallet in ipairs(Workspace:GetDescendants()) do
                if (pallet.Name == "Pallet" or pallet.Name == "Palletwrong") and pallet:IsA("Model") then
                    local part = pallet:FindFirstChild("PalletPoint") or pallet:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local dist = (part.Position - root.Position).Magnitude
                        if dist <= maxDist then
                            createHighlight(pallet, COLORS.Pallet)
                        end
                    end
                end
            end
        end

        if VD.ESP_Window then
            for _, win in ipairs(Workspace:GetDescendants()) do
                -- Support both BasePart dan Model window
                if win.Name == "Window" then
                    local part = win:IsA("BasePart") and win
                        or (win:IsA("Model") and (win:FindFirstChild("Bottom") or win:FindFirstChildWhichIsA("BasePart")))
                    if part then
                        local dist = (part.Position - root.Position).Magnitude
                        if dist <= maxDist then
                            createHighlight(win, COLORS.Window)
                        end
                    end
                end
            end
        end

        if VD.ESP_SCP then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if isSCP(obj) then
                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local dist = (part.Position - root.Position).Magnitude
                        if dist <= maxDist then
                            createHighlight(obj, COLORS.SCP)
                            createBillboard(obj, string.format("%.0fm", dist), COLORS.SCP)
                        end
                    end
                end
            end
        end

        if VD.ESP_Gate then
            for _, gate in ipairs(Workspace:GetDescendants()) do
                if gate.Name == "Gate" and gate:IsA("Model") then
                    local part = gate:FindFirstChild("GatePart") or gate:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local dist = (part.Position - root.Position).Magnitude
                        if dist <= maxDist then
                            createHighlight(gate, COLORS.Gate)

                            -- Progress ESP: cek attribute hold dari server
                            -- VD gate hold = 20 detik total
                            local GATE_HOLD_TIME = 20
                            local progressPct = 0
                            local isOpen = false

                            -- Coba baca attribute progress langsung
                            local holdProgress = gate:GetAttribute("HoldProgress")
                                or gate:GetAttribute("Progress")
                                or gate:GetAttribute("OpenProgress")
                                or gate:GetAttribute("GateProgress")

                            if holdProgress then
                                -- Kalau sudah dalam bentuk 0-1
                                if holdProgress <= 1 then
                                    progressPct = math.floor(holdProgress * 100)
                                else
                                    progressPct = math.floor(holdProgress)
                                end
                            end

                            -- Cek apakah gate sudah terbuka
                            local opened = gate:GetAttribute("IsOpen")
                                or gate:GetAttribute("Opened")
                                or gate:GetAttribute("GateOpen")
                            if opened then
                                isOpen = true
                                progressPct = 100
                            end

                            -- Cek siapa yang hold (tracker per gate)
                            if not _GateHoldTrackers then _GateHoldTrackers = {} end
                            local tracker = _GateHoldTrackers[gate]

                            -- Cek attribute IsHolding
                            local isHolding = gate:GetAttribute("IsHolding")
                                or gate:GetAttribute("BeingHeld")
                                or gate:GetAttribute("HoldActive")

                            if isHolding and not tracker then
                                -- Mulai track waktu hold
                                _GateHoldTrackers[gate] = workspace.DistributedGameTime
                            elseif not isHolding and tracker then
                                _GateHoldTrackers[gate] = nil
                            end

                            -- Kalau tidak ada attribute, pakai time-based tracking
                            if holdProgress == nil and tracker then
                                local elapsed = workspace.DistributedGameTime - tracker
                                progressPct = math.floor(math.clamp(elapsed / GATE_HOLD_TIME * 100, 0, 100))
                            end

                            -- Build label
                            local label
                            if isOpen then
                                label = "GATE [OPEN]"
                            elseif progressPct > 0 then
                                label = string.format("GATE [%d%%]", progressPct)
                            else
                                label = "GATE"
                            end

                            -- Warna: hijau makin dekat selesai
                            local gateColor = COLORS.Gate
                            if progressPct >= 80 then
                                gateColor = Color3.fromRGB(0, 255, 100)
                            elseif progressPct >= 40 then
                                gateColor = Color3.fromRGB(255, 220, 0)
                            end

                            createBillboard(gate, label, gateColor)
                        end
                    end
                end
            end
        end
    end

    -- ============================================================
    -- UNLIMITED VAULT
    -- ============================================================
    local UnlimitedVaultConn = nil
    function EnableUnlimitedVault()
        if VD.UnlimitedVault then return end
        VD.UnlimitedVault = true
        for _, v in ipairs(CollectionService:GetTagged("Blocked")) do
            CollectionService:RemoveTag(v, "Blocked")
        end
        if UnlimitedVaultConn then UnlimitedVaultConn:Disconnect() end
        UnlimitedVaultConn = CollectionService:GetInstanceAddedSignal("Blocked"):Connect(function(instance)
            CollectionService:RemoveTag(instance, "Blocked")
        end)
        Notify("Unlimited Vault", "Aktif", "success", 2)
    end

    function DisableUnlimitedVault()
        VD.UnlimitedVault = false
        if UnlimitedVaultConn then
            UnlimitedVaultConn:Disconnect()
            UnlimitedVaultConn = nil
        end
        Notify("Unlimited Vault", "Nonaktif", "info", 2)
    end

    -- ============================================================
    -- UNLOCK SKILLS WHILE CARRYING + DOUBLE DAMAGE GENERATOR
    -- ============================================================
    local oldNamecall = nil
    function SetupUnlockSkillsCarry()
        if oldNamecall then return end
        local mt = getrawmetatable(game)
        oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if VD.UnlockSkillsCarry and method == "GetAttribute" and not checkcaller() then
                if args[1] == "IsCarrying" then
                    return false
                end
            end
            if VD.DoubleDamageGen and method == "FireServer" and not checkcaller() then
                local selfName = tostring(self):lower()
                if selfName:find("breakgenevent") then
                    local result = oldNamecall(self, ...)
                    task.spawn(function()
                        for _ = 1, 3 do
                            task.wait(0.05)
                            pcall(function() oldNamecall(self, unpack(args)) end)
                        end
                    end)
                    return result
                end
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end

    -- ============================================================
    -- AUTO STALK (Myers)
    -- ============================================================
    local StalkConnection = nil
    local StalkRemote = ReplicatedStorage:FindFirstChild("Remotes")
        and ReplicatedStorage.Remotes:FindFirstChild("Killers")
        and ReplicatedStorage.Remotes.Killers:FindFirstChild("Stalker")
        and ReplicatedStorage.Remotes.Killers.Stalker:FindFirstChild("StartStalking")

    function StartAutoStalk()
        if StalkConnection then return end
        if not StalkRemote then
            Notify("Auto Stalk", "Remote tidak ditemukan", "error", 3)
            return
        end
        StalkConnection = RunService.Heartbeat:Connect(function()
            if not VD.AutoStalk then return end
            local root = getRoot()
            if not root then return end
            local closest, shortest = nil, math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and not IsKiller(p) and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 30 then
                        local dist = (hrp.Position - root.Position).Magnitude
                        if dist < shortest and dist <= 150 then
                            shortest = dist
                            closest = p
                        end
                    end
                end
            end
            if closest then
                pcall(function() StalkRemote:FireServer(closest) end)
            end
        end)
    end

    function StopAutoStalk()
        if StalkConnection then
            StalkConnection:Disconnect()
            StalkConnection = nil
        end
    end

    -- ============================================================
    -- 🔫 SILENT AIM (PISTOL + FLASH + VEIL) - DIPERBAIKI DARI OXIO
    -- ============================================================
    local isChargingPistol = false
    local lockedPistolTarget = nil
    local currentTouchPistolInput = nil
    local pistolLaser = nil
    local isAimingFlash = false
    local isAimingVeil = false
    local AttackAimMode = "Normal"

    local function IsDowned(char)
        if not char then return false end
        return char:GetAttribute("Knocked") == true 
            or char:GetAttribute("IsHooked") == true
            or char:GetAttribute("IsCarried") == true
    end

    local function getTargetPartObject(char)
        if VD.Pistol_TargetPart == "Head" then 
            return char:FindFirstChild("Head")
        elseif VD.Pistol_TargetPart == "Root" or VD.Pistol_TargetPart == "HumanoidRootPart" then 
            return char:FindFirstChild("HumanoidRootPart")
        else 
            return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart") 
        end
    end

    local function getPistolTarget()
        local closestDist = (VD.Pistol_ShowFOV and VD.Pistol_FOVMode) and VD.Pistol_FOV or math.huge
        local bestTarget = nil
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        if VD.Pistol_BlockKnocked and IsDowned(myChar) then return nil end
        
        local cam = Camera
        local mouseLocation = UserInputService:GetMouseLocation()

        -- Target player (Killer/Survivor)
        if VD.Pistol_Target == "Killer" or VD.Pistol_Target == "Survivor" then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local isValidTarget = false
                    if VD.Pistol_Target == "Killer" and IsKiller(p) then 
                        isValidTarget = true
                    elseif VD.Pistol_Target == "Survivor" and not IsKiller(p) then 
                        isValidTarget = true 
                    end
                    if isValidTarget then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 and not IsDowned(p.Character) then
                            local targetPart = getTargetPartObject(p.Character)
                            if targetPart then
                                local screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
                                if onScreen or not VD.Pistol_FOVMode then
                                    local dist = VD.Pistol_FOVMode 
                                        and (Vector2.new(screenPos.X, screenPos.Y) - mouseLocation).Magnitude 
                                        or (targetPart.Position - myHRP.Position).Magnitude
                                    if dist < closestDist then
                                        closestDist = dist
                                        bestTarget = targetPart
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Target SCP
        if VD.Pistol_Target == "SCP" then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if isSCP(obj) then
                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                        if onScreen or not VD.Pistol_FOVMode then
                            local dist = VD.Pistol_FOVMode 
                                and (Vector2.new(screenPos.X, screenPos.Y) - mouseLocation).Magnitude 
                                or (part.Position - myHRP.Position).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                bestTarget = part
                            end
                        end
                    end
                end
            end
        end

        return bestTarget
    end

    local function getKillerTargetForFlash()
        local bestTarget = nil
        local closestDist = math.huge
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and IsKiller(p) and p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and hrp and not IsDowned(p.Character) then
                    local dist = (hrp.Position - myHRP.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        bestTarget = hrp 
                    end
                end
            end
        end
        return bestTarget
    end

    local VeilRemote = ReplicatedStorage:FindFirstChild("Remotes")
        and ReplicatedStorage.Remotes:FindFirstChild("Items")
        and ReplicatedStorage.Remotes.Items:FindFirstChild("Veil")
        and ReplicatedStorage.Remotes.Items.Veil:FindFirstChild("Activate")

    local function getVeilTarget()
        -- Improve: FOV viewport-based + pilih target terdekat ke crosshair
        local cam = workspace.CurrentCamera
        local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        local best, bestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and IsKiller(p) and p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and hrp then
                    local dist3D = (hrp.Position - myHRP.Position).Magnitude
                    if dist3D <= 60 then
                        local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if dist2D < bestDist then
                                bestDist = dist2D
                                best = hrp
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local function executeVeilSilentAim()
        local target = getVeilTarget()
        if target and VeilRemote then
            pcall(function() VeilRemote:FireServer(target) end)
        end
    end

    local function getSpearTarget()
        -- FOV viewport-based (dari w424) — lebih akurat untuk spear aim
        local cam = workspace.CurrentCamera
        local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local closest, shortest = nil, VD.SpearFOV or 250
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not IsKiller(p) and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local pos, visible = cam:WorldToViewportPoint(hrp.Position)
                    if visible then
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if dist < shortest then shortest = dist; closest = hrp end
                    end
                end
            end
        end
        return closest
    end

    local function SpearAimbotCalc(targetPos)
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return targetPos end
        local startPos = myHRP.Position + Vector3.new(0, 2, 0)
        local distance = (targetPos - startPos).Magnitude
        local time = distance / (VD.SpearSpeed or 100)
        local drop = 0.5 * (VD.SpearGravity or 50) * time * time
        return targetPos + Vector3.new(0, drop, 0)
    end

    local function executeSilentAimFire()
        local targetPart = getPistolTarget()
        local myChar = LocalPlayer.Character
        if VD.Pistol_BlockKnocked and IsDowned(myChar) then return end
        if not targetPart or not myChar then return end
        local myPart = myChar:FindFirstChild("HumanoidRootPart")
        if not myPart then return end

        -- Cari Twist of Fate di char ATAU backpack (Oxio approach)
        local twistOfFate = myChar:FindFirstChild("Twist of Fate")
            or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Twist of Fate"))
        if not twistOfFate then return end

        -- Weapon arg: cari gun/EmperorGun di Right Arm (Oxio original)
        local weaponArg = twistOfFate
        local rightArm = twistOfFate:FindFirstChild("Right Arm")
        if rightArm then
            if rightArm:FindFirstChild("EmperorGun") then
                weaponArg = rightArm:FindFirstChild("EmperorGun")
            elseif rightArm:FindFirstChild("gun") then
                weaponArg = rightArm:FindFirstChild("gun")
            else
                weaponArg = rightArm
            end
        end

        -- Predicted aim direction (Oxio logic)
        local startPos  = myPart.Position
        local targetPos = targetPart.Position
        local targetVel = targetPart.AssemblyLinearVelocity
        targetVel = Vector3.new(targetVel.X, 0, targetVel.Z)
        local distance    = (targetPos - startPos).Magnitude
        local timeToHit   = distance / 400
        local predictedPos = targetPos + (targetVel * timeToHit)
        local aimDirection = ((predictedPos + Vector3.new(0, -2, 0)) - startPos).Unit

        -- Fire via direct remote path (paling reliable)
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local fireRemote = remotes
                and remotes:FindFirstChild("Items")
                and remotes.Items:FindFirstChild("Twist of Fate")
                and remotes.Items["Twist of Fate"]:FindFirstChild("Fire")
            if fireRemote then
                fireRemote:FireServer(weaponArg, aimDirection)
            end
        end)
    end

    local function CreatePistolLaser()
        if pistolLaser then return end
        pistolLaser = Instance.new("Part")
        pistolLaser.Name = "VD_PistolLaser"
        pistolLaser.Material = Enum.Material.Neon
        pistolLaser.Color = Color3.fromRGB(255, 0, 0)
        pistolLaser.CanCollide = false
        pistolLaser.Anchored = true
        pistolLaser.CastShadow = false
        pistolLaser.Size = Vector3.new(0.05, 0.05, 1)
        pistolLaser.Transparency = 0
    end
    CreatePistolLaser()

    local _drawOK = (type(Drawing)=="table" and type(Drawing.new)=="function")
    local PistolFOVCircle = _drawOK and Drawing.new("Circle") or {
        Visible=false, Color=Color3.new(), Thickness=1.5, Filled=false,
        Radius=0, Position=Vector2.new()
    }
    if _drawOK then
        PistolFOVCircle.Color = Color3.fromRGB(255, 255, 255)
        PistolFOVCircle.Thickness = 1.5
        PistolFOVCircle.Filled = false
        PistolFOVCircle.Visible = false
    end

    -- Input Handlers (dari oxio)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        local isTouch = (input.UserInputType == Enum.UserInputType.Touch)
        if gameProcessed and not isTouch then return end

        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            if VD.Pistol_SilentAim then 
                isChargingPistol = true 
                lockedPistolTarget = getPistolTarget()
            end
            if VD.Flash_SilentAim then
                isAimingFlash = true
            end
            if VD.Veil_SilentAim then
                isAimingVeil = true
            end
        end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if VD.Pistol_SilentAim and isChargingPistol then 
                executeSilentAimFire() 
            end
            if VD.Veil_SilentAim and isAimingVeil then
                executeVeilSilentAim()
            end
        end
        
        if isTouch then
            if VD.Pistol_SilentAim or VD.Flash_SilentAim or VD.Veil_SilentAim then
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if playerGui then
                    local survivorMob = playerGui:FindFirstChild("Survivor-mob")
                    if survivorMob then
                        local controls = survivorMob:FindFirstChild("Controls")
                        if controls then
                            local targetBtn = controls:FindFirstChild("Gui-mob") 
                            if targetBtn and targetBtn.Visible then
                                local pos = input.Position
                                local absPos = targetBtn.AbsolutePosition
                                local absSize = targetBtn.AbsoluteSize
                                if pos.X >= absPos.X and pos.X <= (absPos.X + absSize.X) and pos.Y >= absPos.Y and pos.Y <= (absPos.Y + absSize.Y) then
                                    if VD.Pistol_SilentAim then
                                        isChargingPistol = true
                                        currentTouchPistolInput = input
                                        lockedPistolTarget = getPistolTarget()
                                    end
                                    if VD.Flash_SilentAim then
                                        isAimingFlash = true
                                        currentTouchPistolInput = input
                                    end
                                    if VD.Veil_SilentAim then
                                        isAimingVeil = true
                                        currentTouchPistolInput = input
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        local isTouchEnd = (input.UserInputType == Enum.UserInputType.Touch)
        
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            if isChargingPistol then 
                isChargingPistol = false 
                lockedPistolTarget = nil
            end
            if isAimingFlash then
                isAimingFlash = false
            end
            if isAimingVeil then
                isAimingVeil = false
            end
        end
        
        if isTouchEnd and input == currentTouchPistolInput then
            if isChargingPistol then
                isChargingPistol = false
                currentTouchPistolInput = nil
                executeSilentAimFire()
                lockedPistolTarget = nil
            end
            if isAimingFlash then
                isAimingFlash = false
                currentTouchPistolInput = nil
            end
            if isAimingVeil then
                isAimingVeil = false
                currentTouchPistolInput = nil
            end
        end
    end)

    -- Keybinds untuk mengganti target (K=Killer, J=Survivor, L=SCP) - dari oxio
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.K then
            VD.Pistol_Target = "Killer"
            Notify("Silent Aim", "Target: Killer", "info", 2)
        elseif input.KeyCode == Enum.KeyCode.J then
            VD.Pistol_Target = "Survivor"
            Notify("Silent Aim", "Target: Survivor", "info", 2)
        elseif input.KeyCode == Enum.KeyCode.L then
            VD.Pistol_Target = "SCP"
            Notify("Silent Aim", "Target: SCP", "info", 2)
        end
        pcall(function()
            if Fluent.Options and Fluent.Options["SA_Target"] then
                Fluent.Options["SA_Target"]:SetValue({VD.Pistol_Target})
            end
        end)
    end)

    -- Render loop (dari oxio, dengan Flash, Lock Aim, Laser, FOV)
    RunService.RenderStepped:Connect(function()
        -- Flash Silent Aim
        if isAimingFlash and VD.Flash_SilentAim then
            local targetPart = getKillerTargetForFlash()
            if targetPart then
                local myChar = LocalPlayer.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local targetPos = targetPart.Position + Vector3.new(0, VD.Flash_YOffset, 0)
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), 0.5)
                if myHRP then
                    local goalHrp = CFrame.lookAt(myHRP.Position, Vector3.new(targetPos.X, myHRP.Position.Y, targetPos.Z))
                    myHRP.CFrame = myHRP.CFrame:Lerp(goalHrp, 0.5)
                end
            end
        end
        
        -- Lock Aim (Pistol)
        if isChargingPistol then
            if lockedPistolTarget and VD.Pistol_LockAim and lockedPistolTarget.Parent and lockedPistolTarget.Parent:FindFirstChild("Humanoid") and lockedPistolTarget.Parent.Humanoid.Health > 0 then
                local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, lockedPistolTarget.Position)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 0.15)
            else
                lockedPistolTarget = getPistolTarget()
            end
        end
        
        -- Pistol Laser
        if isChargingPistol and VD.Pistol_SilentAim then
            local targetPart = getPistolTarget()
            if targetPart then
                CreatePistolLaser()
                local myChar = LocalPlayer.Character
                local leftArm = myChar and (myChar:FindFirstChild("Left Arm") or myChar:FindFirstChild("LeftHand"))
                local startPos = leftArm and leftArm.Position or (myChar and myChar:GetPivot().Position or Vector3.new())
                local targetPos = targetPart.Position
                local targetVel = targetPart.AssemblyLinearVelocity
                targetVel = Vector3.new(targetVel.X, 0, targetVel.Z)
                local distance = (targetPos - startPos).Magnitude
                local bulletSpeed = 400
                local timeToHit = distance / bulletSpeed
                local predictedPos = targetPos + (targetVel * timeToHit)
                local offset = Vector3.new(0, -1.2, 0)
                local endPos = predictedPos + offset
                if pistolLaser then
                    pistolLaser.Parent = Workspace
                    pistolLaser.Transparency = VD.Pistol_HideLaser and 1 or 0
                    local newDist = (endPos - startPos).Magnitude
                    if newDist > 0 then
                        pistolLaser.Size = Vector3.new(0.05, 0.05, newDist)
                        pistolLaser.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -newDist / 2)
                    end
                end
            else
                if pistolLaser and pistolLaser.Parent then
                    pistolLaser.Parent = nil
                end
            end
        else
            if pistolLaser and pistolLaser.Parent then
                pistolLaser.Parent = nil
            end
        end
        
        -- FOV Circle
        if VD.Pistol_SilentAim and VD.Pistol_ShowFOV and VD.Pistol_FOVMode then
            PistolFOVCircle.Visible = true
            PistolFOVCircle.Radius = VD.Pistol_FOV
            PistolFOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local target = getPistolTarget()
            PistolFOVCircle.Color = target and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 100)
        else
            PistolFOVCircle.Visible = false
        end

        -- Spear Aim (w424: SpearAimbotCalc)
        if VD.Pistol_SilentAim and isChargingPistol and AttackAimMode == "Spear" then
            local target = getSpearTarget()
            if target then
                local myChar = LocalPlayer.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    local aimPos = SpearAimbotCalc(target.Position)
                    if aimPos then
                        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, aimPos)
                    end
                end
            end
        end

    end)

    -- ============================================================
    -- ANTI BLIND (Killer) — hookmetamethod minimal
    -- ToF Silent Aim sekarang pakai Oxio executeSilentAimFire()
    -- ============================================================
    do
        local _hm = (type(hookmetamethod)=="function") and hookmetamethod or nil
        local _nc = (type(newcclosure)=="function") and newcclosure or function(f) return f end
        local _cc = (type(checkcaller)=="function") and checkcaller or function() return false end
        local _gn = (type(getnamecallmethod)=="function") and getnamecallmethod or function() return "" end

        if _hm then
            local oldNC
            pcall(function()
                local GotBlindedR = ReplicatedStorage:FindFirstChild("Remotes")
                    and ReplicatedStorage.Remotes:FindFirstChild("Items")
                    and ReplicatedStorage.Remotes.Items:FindFirstChild("Flashlight")
                    and ReplicatedStorage.Remotes.Items.Flashlight:FindFirstChild("GotBlinded")
                if not GotBlindedR then return end
                oldNC = _hm(game, "__namecall", _nc(function(self, ...)
                    local method = _gn()
                    if not _cc() and method == "FireServer" and self == GotBlindedR then
                        if LocalPlayer.Team and LocalPlayer.Team.Name == "Killer" then
                            return nil
                        end
                    end
                    return oldNC(self, ...)
                end))
            end)
        end
    end

    -- ============================================================
    -- AUTO SKILL CHECK (UPGRADED)
    -- ============================================================
    local TouchID        = 8822
    local ActionPath     = "Survivor-mob.Controls.action.check"
    local StateSkill = { busy = false }
    local ConnectionsSkill = {}

    local GuiService = game:GetService("GuiService")
    local LastTriggerTick = 0

    -- PressSkill — 40%.txt path + firesignal + VIM touch + Space
    local ActionPath = "Survivor-mob.Controls.action.check"
    local TouchID_SC = 8822

    -- Path-based target (dari 40%.txt) — lebih akurat dari scan recursive
    local function GetActionTarget()
        local current = PlayerGui
        for segment in string.gmatch(ActionPath, "[^%.]+") do
            current = current and current:FindFirstChild(segment)
        end
        return current
    end

    local function PressSkill()
        if workspace.DistributedGameTime - LastTriggerTick < 0.08 then return end
        LastTriggerTick = workspace.DistributedGameTime

        -- Layer 1: path-based button (dari 40%.txt)
        local btn = GetActionTarget()

        -- Layer 2: scan recursive fallback (cari "check" dan "action")
        if not btn or not btn.Visible then
            btn = PlayerGui:FindFirstChild("check", true)
                or PlayerGui:FindFirstChild("action", true)
        end

        if btn and btn:IsA("GuiObject") and btn.Visible then
            -- firesignal (paling reliable)
            if type(firesignal) == "function" then
                pcall(function()
                    firesignal(btn.MouseButton1Down)
                    task.wait(0.005)
                    firesignal(btn.MouseButton1Up)
                end)
                return
            end
            -- VIM touch (dari 40%.txt: pakai 0/2, bukan Enum)
            pcall(function()
                local pos   = btn.AbsolutePosition
                local size  = btn.AbsoluteSize
                local inset = GuiService:GetGuiInset()
                local cx = pos.X + (size.X/2) + inset.X
                local cy = pos.Y + (size.Y/2) + inset.Y
                VirtualInputManager:SendTouchEvent(TouchID_SC, 0, cx, cy)
                task.wait(0.01)
                VirtualInputManager:SendTouchEvent(TouchID_SC, 2, cx, cy)
            end)
            return
        end

        -- Space fallback (PC)
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end
    local TriggerMobileButton = PressSkill

    -- Quantum: GetSkillCheck — multi-GUI fallback scan
    local function GetSkillCheck()
        for _, guiName in ipairs({"SkillCheckPromptGui","SkillCheckPromptGui-con","SkillCheckGui","SkillCheck"}) do
            local gui = PlayerGui:FindFirstChild(guiName, true)
            if gui then
                local check = gui:FindFirstChild("Check", true) or gui:FindFirstChild("SkillCheck", true) or gui
                if check and (check.Visible == true or (check:IsA("GuiObject") and check.BackgroundTransparency < 1)) then
                    local line = check:FindFirstChild("Line", true) or check:FindFirstChild("Needle", true) or check:FindFirstChild("Pointer", true)
                    local goal = check:FindFirstChild("Goal", true) or check:FindFirstChild("Zone", true) or check:FindFirstChild("Bar", true)
                    if line and goal then return line, goal end
                end
            end
        end
        -- Fallback: scan all descendants
        for _, obj in ipairs(PlayerGui:GetDescendants()) do
            if obj.Name == "Check" and obj:IsA("GuiObject") and obj.Visible then
                local line = obj:FindFirstChild("Line", true)
                local goal = obj:FindFirstChild("Goal", true)
                if line and goal then return line, goal end
            end
        end
        return nil, nil
    end

    local LastGoalRotation = 0

    local function startSkillCheck()
        if ConnectionsSkill.SkillHeartbeat then ConnectionsSkill.SkillHeartbeat:Disconnect() end
        ConnectionsSkill.SkillHeartbeat = RunService.RenderStepped:Connect(function()
            if not VD.AutoSkillcheck or StateSkill.busy then return end
            -- Quantum multi-GUI scan
            local line, goal = GetSkillCheck()
            if not (line and goal) then return end

            local lr = (line.Rotation or 0) % 360
            local gr = (goal.Rotation or 0) % 360

            if VD.AutoSkillcheckMode == "Instant" then
                line.Rotation = goal.Rotation + 109
                StateSkill.busy = true
                task.spawn(function()
                    PressSkill()
                    task.wait(0.2)
                    StateSkill.busy = false
                end)
            else
                -- Quantum dynamic offset based on goal velocity
                local goalVelocity = math.abs(gr - LastGoalRotation)
                LastGoalRotation = gr
                local dynamicOffset = math.clamp(goalVelocity * 0.35, 0, 8)

                local startRange, endRange
                if VD.AutoSkillcheckMode == "Normal" then
                    startRange = (gr + 116 - dynamicOffset) % 360
                    endRange   = (gr + 140 + dynamicOffset) % 360
                else -- Legit
                    startRange = (gr + 102 - dynamicOffset) % 360
                    endRange   = (gr + 116 + dynamicOffset) % 360
                end

                local inZone
                if startRange > endRange then
                    inZone = (lr >= startRange or lr <= endRange)
                else
                    inZone = (lr >= startRange and lr <= endRange)
                end
                if inZone then
                    StateSkill.busy = true
                    task.spawn(function()
                        PressSkill()
                        task.wait(0.05)
                        StateSkill.busy = false
                    end)
                end
            end
        end)
    end
    if VD.AutoSkillcheck then startSkillCheck() end

    -- ============================================================
    -- AUTO PARRY
    -- ============================================================
    local ParryState = { ParryCooldown = false }
    local _ExactParryRemote = nil
    local _LastParryTick = 0

    -- Quantum: GetParryRemote — auto-discovery dengan fallback scan
    local function GetParryRemote()
        if _ExactParryRemote and _ExactParryRemote.Parent then
            return _ExactParryRemote
        end
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return nil end
        local items  = remotes:FindFirstChild("Items")
        local dagger = items and items:FindFirstChild("Parrying Dagger")
        if dagger and dagger:FindFirstChild("parry") then
            _ExactParryRemote = dagger.parry
        else
            for _, v in ipairs(remotes:GetDescendants()) do
                if v:IsA("RemoteEvent") and v.Name:lower() == "parry" then
                    _ExactParryRemote = v
                    break
                end
            end
        end
        return _ExactParryRemote
    end

    local function GetPingLocal()
        local ping = 0.08
        pcall(function()
            local s = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
            if s and s > 0 then ping = s end
        end)
        return math.clamp(ping, 0.03, 1.5)
    end

    -- Quantum: TriggerParryDagger — ping compensation + predicted position + burst
    local function ExecuteParry()
        local now = workspace.DistributedGameTime
        if now - _LastParryTick < 0.04 then return end
        local remote = GetParryRemote()
        if not remote then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not (root and hum) or hum.Health <= 0 then return end

        _LastParryTick = now

        -- Burst fire — more on high ping
        local ping = GetPingLocal()
        local burstCount = ping > 0.18 and 6 or 4
        task.spawn(function()
            for i = 1, burstCount do
                if not VD.Surv_AutoParry or not remote or not remote.Parent then break end
                pcall(function() remote:FireServer() end)
                task.wait(0.005)
            end
        end)
    end

    local function IsSafeToParry(char)
        if not VD.Surv_ParrySafety then return true end
        if not char then return false end
        local interact = char:FindFirstChild("CheckInterractable")
        if interact then
            if interact:GetAttribute("isVaulting") == true then return false end
            if interact:GetAttribute("isRepairing") == true then return false end
            if interact:GetAttribute("isUnhooking") == true then return false end
            if interact:GetAttribute("isHealing") == true then return false end
            if interact:GetAttribute("isSliding") == true then return false end
        end
        return true
    end

    local VALID_PARRY_IDS = {
        ["122812055447896"] = true,
        ["133963973694098"] = true,
        ["117042998468241"] = true,
        ["135002183282873"] = true,
        ["121216847022485"] = true,
        ["132817836308238"] = true,
        ["129784271201071"] = true,
        ["82666958311998"] = true,
        ["78432063483146"] = true,
        ["118907603246885"] = true,
        ["139369275981139"] = true,
        ["110355011987939"] = true,
        ["111920872708571"] = true,
        ["105374834496520"] = true,
        ["138720291317243"] = true,
        ["106871536134254"] = true,
        ["130593238885843"] = true,
        ["115244153053858"] = true,
        ["74968262036854"] = true,
        ["113255068724446"] = true,
        ["98163597193511"] = true,
        ["80411309607666"] = true
    }

    local function AttachParrySensor(kChar)
        if not kChar then return end
        local hum = kChar:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then return end
        animator.AnimationPlayed:Connect(function(track)
            local animId = track.Animation and track.Animation.AnimationId or ""
            local id = animId:match("%d+")
            if not id or not VALID_PARRY_IDS[id] then return end
            if VD.Surv_AutoCrouch and id == "80411309607666" then
                local myChar = LocalPlayer.Character
                if IsDowned(myChar) then return end
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local kHRP = kChar:FindFirstChild("HumanoidRootPart")
                if myHRP and kHRP and (myHRP.Position - kHRP.Position).Magnitude <= 40 then
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                    task.wait(2)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
                end
                return
            end
            local myChar = LocalPlayer.Character
            if IsDowned(myChar) or not IsSafeToParry(myChar) then return end
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local kHRP = kChar:FindFirstChild("HumanoidRootPart")
            if not myHRP or not kHRP then return end
            local dist = (myHRP.Position - kHRP.Position).Magnitude
            if VD.Surv_ParryAggressive then
                if dist <= 12 then
                    ExecuteParry()
                else
                    local tracker
                    local startTime = workspace.DistributedGameTime
                    tracker = RunService.Heartbeat:Connect(function()
                        if workspace.DistributedGameTime - startTime >= 1.5 or ParryState.ParryCooldown or not myHRP or not kHRP or IsDowned(myChar) then
                            if tracker then tracker:Disconnect() end
                            return
                        end
                        if (myHRP.Position - kHRP.Position).Magnitude <= 12 then
                            ExecuteParry()
                            if tracker then tracker:Disconnect() end
                        end
                    end)
                end
            else
                if dist > VD.Surv_ParryRange then return end
                local myPosFlat = Vector3.new(myHRP.Position.X, 0, myHRP.Position.Z)
                local kPosFlat = Vector3.new(kHRP.Position.X, 0, kHRP.Position.Z)
                local flatDelta = myPosFlat - kPosFlat
                if flatDelta.Magnitude > 0 then
                    local flatDirection = flatDelta.Unit
                    local kLookFlat = Vector3.new(kHRP.CFrame.LookVector.X, 0, kHRP.CFrame.LookVector.Z).Unit
                    local isFacing = kLookFlat:Dot(flatDirection)
                    if isFacing < VD.Surv_ParryFace then return end
                end
                ExecuteParry()
            end
        end)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and IsKiller(p) then
            AttachParrySensor(p.Character)
        end
    end
    Players.PlayerAdded:Connect(function(p)
        if p ~= LocalPlayer then
            p.CharacterAdded:Connect(function(char) AttachParrySensor(char) end)
        end
    end)

    -- ============================================================
    -- AUTO PARRY CIRCLE ESP (terpisah, setelah ParryState didefinisikan)
    -- ============================================================
    RunService.RenderStepped:Connect(function()
        pcall(function()
            local hrpCircle = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if VD.Surv_AutoParry and hrpCircle then
                if not ParryState.AutoParryAdornment or ParryState.AutoParryAdornment.Parent ~= hrpCircle then
                    if ParryState.AutoParryAdornment then
                        pcall(function() ParryState.AutoParryAdornment:Destroy() end)
                    end
                    local adorn = Instance.new("CylinderHandleAdornment")
                    adorn.Name    = "AutoParryCircleESP"
                    adorn.Height  = 0.05
                    adorn.Transparency = 0.3
                    adorn.AlwaysOnTop  = true   -- penting agar terlihat
                    adorn.Adornee = hrpCircle
                    adorn.Parent  = hrpCircle
                    ParryState.AutoParryAdornment = adorn
                end
                local cR = VD.Surv_ParryRange or 15
                ParryState.AutoParryAdornment.Radius      = cR
                ParryState.AutoParryAdornment.InnerRadius = math.max(0.1, cR - 0.15)
                ParryState.AutoParryAdornment.CFrame      = CFrame.new(0, -3, 0) * CFrame.Angles(math.rad(90), 0, 0)
                if ParryState.ParryCooldown then
                    ParryState.AutoParryAdornment.Color3 = Color3.fromRGB(255, 128, 0)
                elseif VD.Surv_ParryAggressive then
                    ParryState.AutoParryAdornment.Color3 = Color3.fromRGB(255, 0, 0)
                else
                    ParryState.AutoParryAdornment.Color3 = Color3.fromRGB(0, 255, 255)
                end
            elseif ParryState.AutoParryAdornment then
                pcall(function() ParryState.AutoParryAdornment:Destroy() end)
                ParryState.AutoParryAdornment = nil
            end
        end)
    end)

    -- ============================================================
    -- VISUAL SETTINGS
    -- ============================================================
    local OriginalLighting = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
    }

    local QUANTUM_HiddenEffects = {}
    local QUANTUM_OldFogStart, QUANTUM_OldFogEnd = nil, nil

    local function applyVisualSettings()
        Lighting.GlobalShadows = not VD.NoShadow
        if VD.LowGraphics then
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        else
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        end
        if VD.Fullbright then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        else
            Lighting.Brightness = OriginalLighting.Brightness
            Lighting.ClockTime = OriginalLighting.ClockTime
            Lighting.Ambient = OriginalLighting.Ambient
            Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        end
        if VD.NoFog then
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
        else
            Lighting.FogEnd = OriginalLighting.FogEnd
            Lighting.FogStart = OriginalLighting.FogStart
        end
        if VD.ReduceMap then
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                    v.Enabled = false
                end
                if v:IsA("Decal") and v.Name:lower():find("grass") or v.Name:lower():find("detail") then
                    v.Transparency = 1
                end
            end
        end

        if VD.RemoveVisualEffects then
            if QUANTUM_OldFogStart == nil then
                QUANTUM_OldFogStart = Lighting.FogStart
                QUANTUM_OldFogEnd = Lighting.FogEnd
            end
            Lighting.FogStart = 9e9
            Lighting.FogEnd = 9e9
            local function hideEffects(parent)
                for _, effect in ipairs(parent:GetDescendants()) do
                    local n = string.lower(effect.Name)
                    if effect:IsA("PostEffect") or effect:IsA("Clouds") or effect:IsA("Atmosphere")
                       or n:find("bloom") or n:find("dof") or n:find("sunray") or n:find("blur") then
                        if effect:IsA("Atmosphere") then
                            if effect.Parent then
                                table.insert(QUANTUM_HiddenEffects, {Obj=effect, OldParent=effect.Parent})
                                effect.Parent = nil
                            end
                        else
                            pcall(function()
                                if effect.Enabled then
                                    table.insert(QUANTUM_HiddenEffects, {Obj=effect, WasEnabled=true})
                                    effect.Enabled = false
                                end
                            end)
                        end
                    end
                end
            end
            hideEffects(Lighting)
            if Workspace.CurrentCamera then hideEffects(Workspace.CurrentCamera) end
        else
            for _, data in ipairs(QUANTUM_HiddenEffects) do
                if data.Obj then
                    if data.OldParent then data.Obj.Parent = data.OldParent
                    elseif data.WasEnabled then pcall(function() data.Obj.Enabled = true end) end
                end
            end
            table.clear(QUANTUM_HiddenEffects)
            if QUANTUM_OldFogStart then
                Lighting.FogStart = QUANTUM_OldFogStart
                Lighting.FogEnd = QUANTUM_OldFogEnd
                QUANTUM_OldFogStart, QUANTUM_OldFogEnd = nil, nil
            end
        end
    end

    -- ============================================================
    -- DRAGGABLE FPS & PING COUNTER
    -- ============================================================
    local FPSLabel = nil
    local PingLabel = nil
    local FPSFrame = nil
    local fpsCount = 0
    local fpsTime = 0
    local isDragging = false
    local dragStart = nil
    local frameStartPos = nil

    local function createCounter()
        if FPSFrame then return end
        FPSFrame = Instance.new("ScreenGui")
        FPSFrame.Name = "WisnuCounter"
        FPSFrame.ResetOnSpawn = false
        FPSFrame.IgnoreGuiInset = true
        FPSFrame.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        FPSFrame.Parent = CoreGui

        local holder = Instance.new("Frame")
        holder.Name = "DragFrame"
        holder.Size = UDim2.new(0, 150, 0, 50)
        holder.Position = UDim2.new(0.5, -75, 0.5, -25)
        holder.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        holder.BackgroundTransparency = 0.2
        holder.BorderSizePixel = 0
        holder.Active = true
        holder.Draggable = false
        holder.Parent = FPSFrame
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = holder
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Thickness = 1
        stroke.Transparency = 0.5
        stroke.Parent = holder

        FPSLabel = Instance.new("TextLabel")
        FPSLabel.Size = UDim2.new(1, 0, 0.5, 0)
        FPSLabel.Position = UDim2.new(0, 0, 0, 0)
        FPSLabel.BackgroundTransparency = 1
        FPSLabel.Font = Enum.Font.GothamBold
        FPSLabel.TextSize = 14
        FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        FPSLabel.Text = "FPS: 0"
        FPSLabel.Parent = holder

        PingLabel = Instance.new("TextLabel")
        PingLabel.Size = UDim2.new(1, 0, 0.5, 0)
        PingLabel.Position = UDim2.new(0, 0, 0.5, 0)
        PingLabel.BackgroundTransparency = 1
        PingLabel.Font = Enum.Font.GothamBold
        PingLabel.TextSize = 14
        PingLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        PingLabel.Text = "Ping: 0ms"
        PingLabel.Parent = holder

        holder.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true
                dragStart = Vector2.new(input.Position.X, input.Position.Y)
                frameStartPos = UDim2.new(holder.Position.X.Scale, holder.Position.X.Offset,
                                          holder.Position.Y.Scale, holder.Position.Y.Offset)
            end
        end)
        holder.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
                local viewport = Camera.ViewportSize
                local newX = frameStartPos.X.Scale + (delta.X / viewport.X)
                local newY = frameStartPos.Y.Scale + (delta.Y / viewport.Y)
                holder.Position = UDim2.new(newX, frameStartPos.X.Offset, newY, frameStartPos.Y.Offset)
            end
        end)

        updateCounterVisibility()
    end

    local function updateCounterVisibility()
        if FPSFrame then
            FPSFrame.Enabled = VD.ShowFPS or VD.ShowPing
        end
    end

    local function updateFPS()
        fpsCount = fpsCount + 1
        local now = tick()
        if now - fpsTime >= 1 then
            local fps = math.floor(fpsCount / (now - fpsTime))
            if FPSLabel then FPSLabel.Text = "FPS: " .. fps end
            fpsCount = 0
            fpsTime = now
        end
    end

    local function updatePing()
        local ping = Stats:GetAveragePing()
        if PingLabel then
            PingLabel.Text = "Ping: " .. math.floor(ping) .. "ms"
            if ping < 100 then
                PingLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            elseif ping < 200 then
                PingLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            else
                PingLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            end
        end
    end

    RunService.Heartbeat:Connect(function()
        if VD.ShowFPS then updateFPS() end
        if VD.ShowPing then updatePing() end
    end)

    -- ============================================================
    -- GEN BYPASS SYSTEM
    -- ============================================================
    local GenBypass = {
        Enabled     = false,
        Button      = nil,
        UI          = nil,
        Cache       = {},
        CacheTimer  = 0,
        Processed   = {},
    }

    local function GB_GetAllGenerators()
        local now = tick()
        if now - GenBypass.CacheTimer < 5 then return GenBypass.Cache end
        GenBypass.Cache = {}
        GenBypass.CacheTimer = now
        local mapFolder = Workspace:FindFirstChild("Map")
        if not mapFolder then return GenBypass.Cache end
        pcall(function()
            for _, v in pairs(mapFolder:GetDescendants()) do
                if not v:IsA("Model") then continue end
                if v.Name ~= "Generator" then continue end
                local isReal = v:GetAttribute("RepairProgress") ~= nil
                    or v:GetAttribute("kickcount") ~= nil
                    or v:GetAttribute("ProgressRepair") ~= nil
                if isReal then table.insert(GenBypass.Cache, v) end
            end
        end)
        return GenBypass.Cache
    end

    function GB_GetPoints(genModel)
        local points = {}
        pcall(function()
            for _, obj in pairs(genModel:GetChildren()) do
                if obj.Name:find("GeneratorPoint") and obj:IsA("BasePart") then
                    table.insert(points, obj)
                end
            end
        end)
        return points
    end

    function GB_WaitRepairing(point, timeout)
        local start = tick()
        while tick() - start < (timeout or 1) do
            if point:GetAttribute("IsRepairing") == true then return true end
            task.wait(0.05)
        end
        return false
    end

    function GB_DoRepair(targetPoint)
        local genModel = targetPoint.Parent
        if GenBypass.Processed[genModel] then return end
        GenBypass.Processed[genModel] = true

        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then GenBypass.Processed[genModel] = nil return end

        local RepairEvent = ReplicatedStorage:FindFirstChild("Remotes")
            and ReplicatedStorage.Remotes:FindFirstChild("Generator")
            and ReplicatedStorage.Remotes.Generator:FindFirstChild("RepairEvent")

        if not RepairEvent then 
            GenBypass.Processed[genModel] = nil 
            return 
        end

        local originalCFrame = hrp.CFrame
        pcall(function()
            for _, point in pairs(GB_GetPoints(genModel)) do
                if point ~= targetPoint and point.Parent then
                    hrp.Anchored = true
                    hrp.CFrame = point.CFrame
                    task.wait(0.15)
                    pcall(function() RepairEvent:FireServer(point, true) end)
                    if not GB_WaitRepairing(point, 0.8) then
                        pcall(function() RepairEvent:FireServer(point, false) end)
                        task.wait(0.1)
                        hrp.CFrame = point.CFrame
                        task.wait(0.15)
                        pcall(function() RepairEvent:FireServer(point, true) end)
                        GB_WaitRepairing(point, 0.5)
                    end
                    hrp.Anchored = false
                    task.wait(0.05)
                end
            end
        end)
        pcall(function()
            if hrp and hrp.Parent then
                hrp.Anchored = false
                hrp.CFrame = originalCFrame
            end
        end)
        task.wait(0.1)
        pcall(function() RepairEvent:FireServer(targetPoint, false) end)
        GenBypass.Processed[genModel] = nil
    end

    function GB_GetNearestPoint()
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local bestPoint, bestDist = nil, math.huge
        for _, gen in pairs(GB_GetAllGenerators()) do
            for _, point in pairs(GB_GetPoints(gen)) do
                local d = (hrp.Position - point.Position).Magnitude
                if d < bestDist then bestDist = d; bestPoint = point end
            end
        end
        return bestPoint, bestDist
    end

    function GB_UpdateButton()
        if GenBypass.Button then
            GenBypass.Button.Visible = GenBypass.Enabled and UserInputService.TouchEnabled
        end
    end

    function GB_CreateButton()
        local oldUI = PlayerGui:FindFirstChild("BypassGenUI")
        if oldUI then oldUI:Destroy() end

        GenBypass.UI = Instance.new("ScreenGui")
        GenBypass.UI.Name = "BypassGenUI"
        GenBypass.UI.ResetOnSpawn = false
        GenBypass.UI.IgnoreGuiInset = true
        GenBypass.UI.Parent = PlayerGui

        GenBypass.Button = Instance.new("ImageButton")
        GenBypass.Button.Name = "BypassGenButton"
        GenBypass.Button.Size = UDim2.new(0, 60, 0, 60)
        GenBypass.Button.Position = UDim2.new(0.88, 0, 0.55, 0)
        GenBypass.Button.AnchorPoint = Vector2.new(0.5, 0.5)
        GenBypass.Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        GenBypass.Button.BackgroundTransparency = 0.15
        GenBypass.Button.AutoButtonColor = true
        GenBypass.Button.Visible = false
        GenBypass.Button.ZIndex = 10
        GenBypass.Button.Parent = GenBypass.UI
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = GenBypass.Button
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Thickness = 2
        stroke.Transparency = 0.2
        stroke.Parent = GenBypass.Button
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "BYPASS"
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextScaled = true
        lbl.Font = Enum.Font.GothamBlack
        lbl.ZIndex = 11
        lbl.Parent = GenBypass.Button

        GenBypass.Button.MouseButton1Click:Connect(function()
            if not GenBypass.Enabled then return end
            local bestPoint, bestDist = GB_GetNearestPoint()
            if bestPoint and bestDist <= 8 then 
                GB_DoRepair(bestPoint) 
            end
        end)
    end

    GB_CreateButton()
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        GB_CreateButton()
        GB_UpdateButton()
    end)

    function setGenBypass(v)
        GenBypass.Enabled = v
        GB_UpdateButton()
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == VD.GenBypass_Hotkey and GenBypass.Enabled then
            local bestPoint, bestDist = GB_GetNearestPoint()
            if bestPoint and bestDist <= 8 then
                GB_DoRepair(bestPoint)
            else
                Notify("Gen Bypass", "Tidak ada generator dalam jangkauan", "warning", 2)
            end
        end
    end)

    -- ============================================================
    -- MOONWALK (WisnuVip)
    -- ============================================================
    local MOON_CONFIG = {
        SIDE_SPEED = 2.2,
        BACK_SPEED = 4.0,
        INTERVAL = 0.045,
        SMOOTH_FACTOR = 0.85,
        KEYBIND = VD.Moonwalk_Hotkey,
        GUI_POSITION = UDim2.fromScale(0.78, 0.22),
        AUTO_START = false,
    }

    local MoonwalkEnabled = VD.Moonwalk_Enabled
    local MoonwalkMoveConn = nil
    local MoonwalkGui = nil
    local KeybindConn = nil
    local CharAddedConn = nil
    local CurrentDirection = 1
    local LastSwitch = 0
    local SmoothVelocity = Vector3.new()

    local function stopMoonwalkInternal()
        if MoonwalkMoveConn then
            MoonwalkMoveConn:Disconnect()
            MoonwalkMoveConn = nil
        end
        SmoothVelocity = Vector3.new()
    end

    local function startMoonwalkInternal()
        stopMoonwalkInternal()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end
        
        CurrentDirection = 1
        LastSwitch = 0
        
        MoonwalkMoveConn = RunService.RenderStepped:Connect(function(deltaTime)
            if not MoonwalkEnabled then return end
            
            local currentChar = LocalPlayer.Character
            if not currentChar then return end
            
            local currentHrp = currentChar:FindFirstChild("HumanoidRootPart")
            local currentHum = currentChar:FindFirstChildOfClass("Humanoid")
            if not currentHrp or not currentHum or currentHum.Health <= 0 then 
                stopMoonwalkInternal()
                return 
            end
            
            local now = tick()
            if now - LastSwitch >= MOON_CONFIG.INTERVAL then
                CurrentDirection = CurrentDirection * -1
                LastSwitch = now
            end
            
            local lookVector = currentHrp.CFrame.LookVector
            local rightVector = currentHrp.CFrame.RightVector
            
            local targetVelocity = (lookVector * -MOON_CONFIG.BACK_SPEED) + (rightVector * (CurrentDirection * MOON_CONFIG.SIDE_SPEED))
            
            SmoothVelocity = SmoothVelocity:Lerp(targetVelocity, MOON_CONFIG.SMOOTH_FACTOR)
            
            currentHum:Move(SmoothVelocity, false)
        end)
    end

    local function destroyMoonwalkGui()
        if MoonwalkGui then
            MoonwalkGui:Destroy()
            MoonwalkGui = nil
        end
    end

    local function createMoonwalkGui()
        destroyMoonwalkGui()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        
        MoonwalkGui = Instance.new("ScreenGui")
        MoonwalkGui.Name = "VD_Moonwalk_V3"
        MoonwalkGui.ResetOnSpawn = false
        MoonwalkGui.Parent = pg
        
        local frame = Instance.new("Frame")
        frame.Name = "MainFrame"
        frame.Parent = MoonwalkGui
        frame.Size = UDim2.fromOffset(180, 110)
        frame.Position = MOON_CONFIG.GUI_POSITION
        frame.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
        frame.BackgroundTransparency = 0.15
        frame.Active = true
        frame.Draggable = true
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
        
        local glow = Instance.new("Frame")
        glow.Name = "Glow"
        glow.Parent = frame
        glow.Size = UDim2.fromScale(1, 1)
        glow.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
        glow.BackgroundTransparency = 0.9
        glow.BorderSizePixel = 0
        Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 12)
        
        local title = Instance.new("TextLabel")
        title.Parent = frame
        title.Size = UDim2.new(1, -50, 0, 24)
        title.Position = UDim2.fromOffset(0, 4)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 12
        title.TextColor3 = Color3.fromRGB(150, 200, 255)
        title.TextXAlignment = Enum.TextXAlignment.Center
        title.Text = "🌙 Moonwalk V3"
        
        local minimizeBtn = Instance.new("TextButton")
        minimizeBtn.Parent = frame
        minimizeBtn.Size = UDim2.fromOffset(20, 20)
        minimizeBtn.Position = UDim2.new(1, -46, 0, 4)
        minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        minimizeBtn.Text = "−"
        minimizeBtn.Font = Enum.Font.GothamBold
        minimizeBtn.TextSize = 14
        minimizeBtn.TextColor3 = Color3.new(1,1,1)
        minimizeBtn.BorderSizePixel = 0
        Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 6)
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Parent = frame
        closeBtn.Size = UDim2.fromOffset(20, 20)
        closeBtn.Position = UDim2.new(1, -24, 0, 4)
        closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
        closeBtn.Text = "✕"
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 11
        closeBtn.TextColor3 = Color3.new(1,1,1)
        closeBtn.BorderSizePixel = 0
        Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
        
        local statusLbl = Instance.new("TextLabel")
        statusLbl.Name = "StatusLbl"
        statusLbl.Parent = frame
        statusLbl.Size = UDim2.new(1,0,0,16)
        statusLbl.Position = UDim2.fromOffset(0, 30)
        statusLbl.BackgroundTransparency = 1
        statusLbl.Font = Enum.Font.GothamBold
        statusLbl.TextSize = 10
        statusLbl.TextColor3 = Color3.fromRGB(255,80,80)
        statusLbl.TextXAlignment = Enum.TextXAlignment.Center
        statusLbl.Text = "● OFF"
        
        local keybindLbl = Instance.new("TextLabel")
        keybindLbl.Parent = frame
        keybindLbl.Size = UDim2.new(1,0,0,14)
        keybindLbl.Position = UDim2.fromOffset(0, 46)
        keybindLbl.BackgroundTransparency = 1
        keybindLbl.Font = Enum.Font.Gotham
        keybindLbl.TextSize = 9
        keybindLbl.TextColor3 = Color3.fromRGB(140, 140, 160)
        keybindLbl.Text = "⌨️ " .. tostring(MOON_CONFIG.KEYBIND)
        
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Name = "ToggleBtn"
        toggleBtn.Parent = frame
        toggleBtn.Size = UDim2.fromOffset(160, 28)
        toggleBtn.Position = UDim2.fromOffset(10, 70)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 130)
        toggleBtn.Text = "▶ START"
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.TextSize = 11
        toggleBtn.TextColor3 = Color3.new(1,1,1)
        toggleBtn.BorderSizePixel = 0
        Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)
        
        local speedBar = Instance.new("Frame")
        speedBar.Name = "SpeedBar"
        speedBar.Parent = frame
        speedBar.Size = UDim2.fromOffset(160, 3)
        speedBar.Position = UDim2.fromOffset(10, 100)
        speedBar.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
        speedBar.BorderSizePixel = 0
        Instance.new("UICorner", speedBar).CornerRadius = UDim.new(0, 2)
        
        local speedFill = Instance.new("Frame")
        speedFill.Name = "SpeedFill"
        speedFill.Parent = speedBar
        speedFill.Size = UDim2.fromScale(0, 1)
        speedFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        speedFill.BorderSizePixel = 0
        Instance.new("UICorner", speedFill).CornerRadius = UDim.new(0, 2)
        
        local function updateUI()
            if MoonwalkEnabled then
                toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
                toggleBtn.Text = "■ STOP"
                statusLbl.Text = "● ON"
                statusLbl.TextColor3 = Color3.fromRGB(0, 255, 150)
                glow.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
                glow.BackgroundTransparency = 0.85
                TweenService:Create(speedFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(1, 1)}):Play()
            else
                toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 130)
                toggleBtn.Text = "▶ START"
                statusLbl.Text = "● OFF"
                statusLbl.TextColor3 = Color3.fromRGB(255,80,80)
                glow.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
                glow.BackgroundTransparency = 0.9
                TweenService:Create(speedFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(0, 1)}):Play()
            end
        end
        
        local function toggleMoonwalkUI()
            MoonwalkEnabled = not MoonwalkEnabled
            VD.Moonwalk_Enabled = MoonwalkEnabled
            if MoonwalkEnabled then 
                startMoonwalkInternal() 
            else 
                stopMoonwalkInternal() 
            end
            updateUI()
            pcall(function()
                if Fluent.Options and Fluent.Options["Moonwalk_Enable"] then
                    Fluent.Options["Moonwalk_Enable"]:SetValue(MoonwalkEnabled)
                end
            end)
        end
        
        local minimized = false
        minimizeBtn.MouseButton1Click:Connect(function()
            minimized = not minimized
            if minimized then
                frame.Size = UDim2.fromOffset(180, 32)
                statusLbl.Visible = false
                keybindLbl.Visible = false
                toggleBtn.Visible = false
                speedBar.Visible = false
                minimizeBtn.Text = "+"
            else
                frame.Size = UDim2.fromOffset(180, 110)
                statusLbl.Visible = true
                keybindLbl.Visible = true
                toggleBtn.Visible = true
                speedBar.Visible = true
                minimizeBtn.Text = "−"
            end
        end)
        
        toggleBtn.MouseButton1Click:Connect(toggleMoonwalkUI)
        
        closeBtn.MouseButton1Click:Connect(function()
            if getgenv().VD_Moonwalk_Cleanup then
                pcall(getgenv().VD_Moonwalk_Cleanup)
            end
        end)
        
        updateUI()
        
        if MOON_CONFIG.AUTO_START then
            task.wait(0.5)
            toggleMoonwalkUI()
        end
    end

    KeybindConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == MOON_CONFIG.KEYBIND then
            if MoonwalkGui then
                MoonwalkEnabled = not MoonwalkEnabled
                VD.Moonwalk_Enabled = MoonwalkEnabled
                if MoonwalkEnabled then 
                    startMoonwalkInternal() 
                else 
                    stopMoonwalkInternal() 
                end
                pcall(function()
                    local frame = MoonwalkGui:FindFirstChild("MainFrame")
                    if not frame then return end
                    local toggleBtn = frame:FindFirstChild("ToggleBtn")
                    local statusLbl = frame:FindFirstChild("StatusLbl")
                    local glow = frame:FindFirstChild("Glow")
                    local speedFill = frame:FindFirstChild("SpeedBar") and frame.SpeedBar:FindFirstChild("SpeedFill")
                    
                    if MoonwalkEnabled then
                        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
                        toggleBtn.Text = "■ STOP"
                        statusLbl.Text = "● ON"
                        statusLbl.TextColor3 = Color3.fromRGB(0, 255, 150)
                        glow.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
                        glow.BackgroundTransparency = 0.85
                        if speedFill then
                            TweenService:Create(speedFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(1, 1)}):Play()
                        end
                    else
                        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 130)
                        toggleBtn.Text = "▶ START"
                        statusLbl.Text = "● OFF"
                        statusLbl.TextColor3 = Color3.fromRGB(255,80,80)
                        glow.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
                        glow.BackgroundTransparency = 0.9
                        if speedFill then
                            TweenService:Create(speedFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(0, 1)}):Play()
                        end
                    end
                end)
            end
        end
    end)

    CharAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.3)
        if MoonwalkEnabled then 
            startMoonwalkInternal() 
        end
    end)

    getgenv().VD_Moonwalk_Cleanup = function()
        MoonwalkEnabled = false
        stopMoonwalkInternal()
        destroyMoonwalkGui()
        if KeybindConn then KeybindConn:Disconnect(); KeybindConn = nil end
        if CharAddedConn then CharAddedConn:Disconnect(); CharAddedConn = nil end
        getgenv().VD_Moonwalk_Cleanup = nil
    end

    createMoonwalkGui()

    -- ============================================================
    -- MASK SELECTION (dari MugiHub)
    -- ============================================================
    local MaskGui = nil
    local MaskKeyConn = nil
    local MaskIsOpen = true
    local MaskMinimizeBtn = nil
    local MaskBodyFrame = nil

    local MASK_DATA = {
        { arg="Alex",    label="Swan",    image="https://www.roblox.com/asset-thumbnail/image?assetId=15946083863&width=420&height=420&format=png", key=Enum.KeyCode.One },
        { arg="Brandon", label="Panther", image="https://www.roblox.com/asset-thumbnail/image?assetId=111928367372122&width=420&height=420&format=png", key=Enum.KeyCode.Two },
        { arg="Cobra",   label="Cobra",   image="https://www.roblox.com/asset-thumbnail/image?assetId=15946288579&width=420&height=420&format=png", key=Enum.KeyCode.Three },
        { arg="Rabbit",  label="Rabbit",  image="https://www.roblox.com/asset-thumbnail/image?assetId=103750154338014&width=420&height=420&format=png", key=Enum.KeyCode.Four },
        { arg="Richter", label="Rat",     image="https://www.roblox.com/asset-thumbnail/image?assetId=590245826&width=420&height=420&format=png", key=Enum.KeyCode.Five },
        { arg="Tony",    label="Tiger",   image="https://www.roblox.com/asset-thumbnail/image?assetId=96793004678696&width=420&height=420&format=png", key=Enum.KeyCode.Six },
    }
    local MASK_DEFAULT_ARG = "Richard"

    local function FireMask(argName)
        pcall(function()
            ReplicatedStorage:WaitForChild("Remotes")
                :WaitForChild("Killers"):WaitForChild("Masked"):WaitForChild("Activatepower"):FireServer(argName)
        end)
    end

    local function CheckIsMasked()
        local skVal = LocalPlayer:GetAttribute("SelectedKiller")
        if skVal == nil then
            local sk = LocalPlayer:FindFirstChild("SelectedKiller")
            if sk then skVal = sk.Value end
        end
        if skVal == nil then return false end
        return tostring(skVal):lower():find("masked") ~= nil
    end

    local function GetMaskUIScale()
        local cam = Workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        local shortSide = math.min(vp.X, vp.Y)
        return math.clamp(shortSide / 720, 0.7, 1.25)
    end

    local function setMaskPopupState(open)
        MaskIsOpen = open
        if MaskBodyFrame then MaskBodyFrame.Visible = open end
        if MaskMinimizeBtn then MaskMinimizeBtn.Text = open and "-" or "+" end
    end

    local function toggleMaskPopup()
        setMaskPopupState(not MaskIsOpen)
    end

    local function BuildMaskGui()
        if MaskGui and MaskGui.Parent then MaskGui:Destroy() end

        local scale = GetMaskUIScale()
        local PANEL_W    = math.floor(230 * scale)
        local HEADER_H   = math.floor(34 * scale)
        local CARD_SIZE  = math.floor(62 * scale)
        local CARD_GAP   = math.floor(6 * scale)
        local PAD        = math.floor(8 * scale)
        local BTN_H      = math.floor(28 * scale)

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MaskSelectionGUI"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.DisplayOrder = 60
        screenGui.Parent = (pcall(function() return gethui() end) and gethui()) or CoreGui

        local root = Instance.new("Frame")
        root.Name = "Root"
        root.Size = UDim2.new(0, PANEL_W, 0, HEADER_H)
        root.Position = UDim2.new(0.5, -PANEL_W/2, 0.16, 0)
        root.BackgroundTransparency = 1
        root.Parent = screenGui

        local header = Instance.new("Frame")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, HEADER_H)
        header.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        header.BorderSizePixel = 0
        header.ZIndex = 5
        header.Parent = root
        local hCorner = Instance.new("UICorner", header); hCorner.CornerRadius = UDim.new(0, 8)
        local hStroke = Instance.new("UIStroke", header)
        hStroke.Color = Color3.fromRGB(255, 153, 204); hStroke.Thickness = 1; hStroke.Transparency = 0.45

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Name = "Title"
        titleLbl.Size = UDim2.new(1, -HEADER_H - PAD, 1, 0)
        titleLbl.Position = UDim2.new(0, PAD, 0, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = "MASK SELECTION"
        titleLbl.TextColor3 = Color3.fromRGB(255, 153, 204)
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = math.floor(13 * scale)
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
        titleLbl.ZIndex = 6
        titleLbl.Parent = header

        local minimizeBtn = Instance.new("TextButton")
        minimizeBtn.Name = "Minimize"
        minimizeBtn.Size = UDim2.new(0, HEADER_H - 8, 0, HEADER_H - 8)
        minimizeBtn.Position = UDim2.new(1, -(HEADER_H - 4), 0.5, -(HEADER_H-8)/2)
        minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 153, 204)
        minimizeBtn.AutoButtonColor = false
        minimizeBtn.Text = "-"
        minimizeBtn.TextColor3 = Color3.fromRGB(22, 22, 28)
        minimizeBtn.Font = Enum.Font.GothamBold
        minimizeBtn.TextSize = math.floor(16 * scale)
        minimizeBtn.BorderSizePixel = 0
        minimizeBtn.ZIndex = 7
        minimizeBtn.Parent = header
        local mbCorner = Instance.new("UICorner", minimizeBtn); mbCorner.CornerRadius = UDim.new(0, 6)
        MaskMinimizeBtn = minimizeBtn

        local body = Instance.new("Frame")
        body.Name = "Body"
        body.Size = UDim2.new(1, 0, 0, 0)
        body.Position = UDim2.new(0, 0, 0, HEADER_H + PAD*0.5)
        body.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        body.BorderSizePixel = 0
        body.ZIndex = 5
        body.Parent = root
        local bCorner = Instance.new("UICorner", body); bCorner.CornerRadius = UDim.new(0, 8)
        local bStroke = Instance.new("UIStroke", body)
        bStroke.Color = Color3.fromRGB(255, 153, 204); bStroke.Thickness = 1; bStroke.Transparency = 0.55
        MaskBodyFrame = body

        local bodyPadding = Instance.new("UIPadding")
        bodyPadding.PaddingTop = UDim.new(0, PAD)
        bodyPadding.PaddingBottom = UDim.new(0, PAD)
        bodyPadding.PaddingLeft = UDim.new(0, PAD)
        bodyPadding.PaddingRight = UDim.new(0, PAD)
        bodyPadding.Parent = body

        local bodyLayout = Instance.new("UIListLayout")
        bodyLayout.Padding = UDim.new(0, PAD * 0.6)
        bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
        bodyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        bodyLayout.Parent = body

        local statusLbl = Instance.new("TextLabel")
        statusLbl.Name = "StatusLabel"
        statusLbl.LayoutOrder = 1
        statusLbl.Size = UDim2.new(1, 0, 0, math.floor(16 * scale))
        statusLbl.BackgroundTransparency = 1
        statusLbl.Text = "Active Mask: None"
        statusLbl.TextColor3 = Color3.fromRGB(90, 240, 140)
        statusLbl.Font = Enum.Font.GothamBold
        statusLbl.TextSize = math.floor(11 * scale)
        statusLbl.TextXAlignment = Enum.TextXAlignment.Left
        statusLbl.ZIndex = 6
        statusLbl.Parent = body

        local gridContainer = Instance.new("Frame")
        gridContainer.Name = "Grid"
        gridContainer.LayoutOrder = 2
        gridContainer.Size = UDim2.new(1, 0, 0, (CARD_SIZE * 3) + (CARD_GAP * 2))
        gridContainer.BackgroundTransparency = 1
        gridContainer.ZIndex = 6
        gridContainer.Parent = body

        local grid = Instance.new("UIGridLayout")
        grid.CellSize = UDim2.new(0, CARD_SIZE, 0, CARD_SIZE)
        grid.CellPadding = UDim2.new(0, CARD_GAP, 0, CARD_GAP)
        grid.FillDirection = Enum.FillDirection.Horizontal
        grid.FillDirectionMaxCells = 3
        grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
        grid.VerticalAlignment = Enum.VerticalAlignment.Center
        grid.SortOrder = Enum.SortOrder.LayoutOrder
        grid.Parent = gridContainer

        local maskCards = {}
        local selectedMask = nil

        local function resetCardStrokes()
            for _, data in pairs(maskCards) do
                data.Stroke.Color = Color3.fromRGB(55, 55, 65)
                data.Stroke.Transparency = 0.3
            end
        end

        for i, mask in ipairs(MASK_DATA) do
            local card = Instance.new("ImageButton")
            card.Name = mask.label
            card.LayoutOrder = i
            card.Size = UDim2.new(0, CARD_SIZE, 0, CARD_SIZE)
            card.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
            card.BorderSizePixel = 0
            card.AutoButtonColor = false
            card.Image = mask.image
            card.ScaleType = Enum.ScaleType.Fit
            card.ZIndex = 7
            card.Parent = gridContainer
            local cCorner = Instance.new("UICorner", card); cCorner.CornerRadius = UDim.new(0, 8)
            local cStroke = Instance.new("UIStroke", card)
            cStroke.Color = Color3.fromRGB(55, 55, 65); cStroke.Thickness = 1.5
            cStroke.Transparency = 0.3
            cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

            local numBadge = Instance.new("TextLabel")
            numBadge.Size = UDim2.new(0, math.floor(16*scale), 0, math.floor(16*scale))
            numBadge.Position = UDim2.new(0, 3, 0, 3)
            numBadge.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            numBadge.BackgroundTransparency = 0.35
            numBadge.Text = tostring(i)
            numBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
            numBadge.Font = Enum.Font.GothamBold
            numBadge.TextSize = math.floor(10 * scale)
            numBadge.BorderSizePixel = 0
            numBadge.ZIndex = 8
            numBadge.Parent = card
            local nCorner = Instance.new("UICorner", numBadge); nCorner.CornerRadius = UDim.new(0, 4)

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, 0, 0, math.floor(16 * scale))
            nameLbl.Position = UDim2.new(0, 0, 1, -math.floor(16*scale))
            nameLbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            nameLbl.BackgroundTransparency = 0.3
            nameLbl.Text = mask.label
            nameLbl.TextColor3 = Color3.fromRGB(235, 235, 240)
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = math.floor(9 * scale)
            nameLbl.BorderSizePixel = 0
            nameLbl.ZIndex = 8
            nameLbl.Parent = card
            local nmCorner = Instance.new("UICorner", nameLbl); nmCorner.CornerRadius = UDim.new(0, 5)

            local function activate()
                FireMask(mask.arg)
                selectedMask = mask.label
                statusLbl.Text = "Active Mask: " .. mask.label
                resetCardStrokes()
                cStroke.Color = Color3.fromRGB(255, 153, 204)
                cStroke.Transparency = 0
            end
            card.MouseButton1Click:Connect(activate)
            maskCards[mask.label] = {Stroke = cStroke}
            mask._activate = activate
        end

        local deactBtn = Instance.new("TextButton")
        deactBtn.Name = "Deactivate"
        deactBtn.LayoutOrder = 3
        deactBtn.Size = UDim2.new(1, 0, 0, BTN_H)
        deactBtn.BackgroundColor3 = Color3.fromRGB(178, 42, 58)
        deactBtn.Text = "[7]  Deactivate"
        deactBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        deactBtn.Font = Enum.Font.GothamBold
        deactBtn.TextSize = math.floor(12 * scale)
        deactBtn.BorderSizePixel = 0
        deactBtn.ZIndex = 6
        deactBtn.Parent = body
        local dCorner = Instance.new("UICorner", deactBtn); dCorner.CornerRadius = UDim.new(0, 6)

        local function deactivateMask()
            FireMask(MASK_DEFAULT_ARG)
            selectedMask = nil
            statusLbl.Text = "Active Mask: None"
            resetCardStrokes()
        end
        deactBtn.MouseButton1Click:Connect(deactivateMask)

        bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            body.Size = UDim2.new(1, 0, 0, bodyLayout.AbsoluteContentSize.Y + PAD*2)
        end)

        local dragging = false
        local dragStart = nil
        local startPos = nil
        local moved = false
        local DRAG_THRESHOLD = 4

        local function beginDrag(pos)
            dragging = true
            moved = false
            dragStart = pos
            startPos = root.Position
        end

        local function updateDrag(pos)
            if not dragging then return end
            local delta = pos - dragStart
            if delta.Magnitude > DRAG_THRESHOLD then moved = true end
            local viewportSize = screenGui.AbsoluteSize
            if viewportSize.X <= 0 or viewportSize.Y <= 0 then return end
            local newX = startPos.X.Scale + (delta.X / viewportSize.X)
            local newY = startPos.Y.Scale + (delta.Y / viewportSize.Y)
            newX = math.clamp(newX, -0.15, 1.05)
            newY = math.clamp(newY, 0, 0.92)
            root.Position = UDim2.new(newX, startPos.X.Offset, newY, startPos.Y.Offset)
        end

        local function endDrag()
            dragging = false
        end

        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
               or input.UserInputType == Enum.UserInputType.Touch then
                beginDrag(Vector2.new(input.Position.X, input.Position.Y))
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
               or input.UserInputType == Enum.UserInputType.Touch) then
                updateDrag(Vector2.new(input.Position.X, input.Position.Y))
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
               or input.UserInputType == Enum.UserInputType.Touch then
                if dragging then
                    local wasClick = not moved
                    endDrag()
                    if wasClick then toggleMaskPopup() end
                end
            end
        end)

        local keyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or not screenGui.Parent then return end
            local focused = UserInputService:GetFocusedTextBox()
            if focused then return end
            for _, mask in ipairs(MASK_DATA) do
                if input.KeyCode == mask.key then mask._activate(); return end
            end
            if input.KeyCode == Enum.KeyCode.Seven then deactivateMask(); return end
            if input.KeyCode == Enum.KeyCode.M then toggleMaskPopup(); return end
        end)

        screenGui.AncestryChanged:Connect(function(_, parent)
            if not parent and keyConn then keyConn:Disconnect() end
        end)

        MaskGui = screenGui
        if MaskKeyConn then MaskKeyConn:Disconnect() end
        MaskKeyConn = keyConn

        setMaskPopupState(true)
    end

    local function ShowMaskGui()
        if not CheckIsMasked() then
            Notify("Mask Selection", "You are not playing The Masked", "warning", 4)
            return
        end
        BuildMaskGui()
        Notify("Mask Selection", "GUI opened", "success", 2)
    end

    local function HideMaskGui()
        if MaskKeyConn then MaskKeyConn:Disconnect(); MaskKeyConn = nil end
        if MaskGui and MaskGui.Parent then MaskGui:Destroy(); MaskGui = nil end
        Notify("Mask Selection", "GUI closed", "info", 2)
    end

    -- ============================================================
    -- HITBOX EXPANDER
    -- ============================================================
    RunService.Heartbeat:Connect(function()
        if not VD.HitboxExpander then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local team = p.Team
                if team and (team.Name == "Killer" or team.Name == "Killers") then
                    local root = p.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local targetSize = Vector3.new(VD.HitboxSize, VD.HitboxSize, VD.HitboxSize)
                        if root.Size ~= targetSize then
                            pcall(function()
                                root.Size = targetSize
                                root.Transparency = 0.9
                                root.Material = Enum.Material.ForceField
                                root.Color = Color3.fromRGB(255,0,0)
                                root.CanCollide = false
                            end)
                        end
                    end
                end
            end
        end
    end)

    -- ============================================================
    -- KILLER PREDICTION (Spectator)
    -- ============================================================
    local KillerPredictionEnabled = false
    local KillerPredictionInterval = 3
    local KillerPredictionLabel = nil

    local function updateKillerPrediction()
        if not KillerPredictionEnabled then
            if KillerPredictionLabel then
                KillerPredictionLabel:Destroy()
                KillerPredictionLabel = nil
            end
            return
        end

        local teamName = LocalPlayer.Team and LocalPlayer.Team.Name or ""
        local isSpectator = teamName == "Spectators" or teamName == "Spectator"
        if not isSpectator then
            if KillerPredictionLabel then
                KillerPredictionLabel:Destroy()
                KillerPredictionLabel = nil
            end
            return
        end

        if not KillerPredictionLabel then
            local sg = Instance.new("ScreenGui")
            sg.Name = "KillerPredictionGUI"
            sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true
            sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            sg.Parent = CoreGui

            local lbl = Instance.new("TextLabel")
            lbl.Name = "PredictionLabel"
            lbl.Size = UDim2.new(0, 200, 0, 55)
            lbl.Position = UDim2.new(0.5, -100, 0, 25)
            lbl.AnchorPoint = Vector2.new(0.5, 0)
            lbl.BackgroundTransparency = 0.15
            lbl.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
            lbl.BorderSizePixel = 0
            lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 12
            lbl.TextWrapped = true
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.TextYAlignment = Enum.TextYAlignment.Center
            lbl.RichText = true
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = lbl
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(255, 255, 255)
            stroke.Thickness = 1
            stroke.Transparency = 0.6
            stroke.Parent = lbl

            lbl.Parent = sg
            KillerPredictionLabel = lbl
        end

        local players = Players:GetPlayers()
        table.sort(players, function(a, b)
            local aAllow = a:GetAttribute("AllowKiller") or false
            local bAllow = b:GetAttribute("AllowKiller") or false
            if aAllow ~= bAllow then return aAllow == true end
            local aChance = a:GetAttribute("KillerChance") or 0
            local bChance = b:GetAttribute("KillerChance") or 0
            return aChance > bChance
        end)
        local predicted = players[1]
        if predicted then
            local killerSelected = predicted:GetAttribute("SelectedKiller") or "Unknown"
            KillerPredictionLabel.Text = "<font size=\"14\"><b>KILLER PREDICTION</b></font>\n"
                .. "<font color=\"rgb(160,160,160)\" size=\"12\">" .. predicted.Name .. "</font>\n"
                .. "<font color=\"rgb(255,255,255)\" size=\"11\">Killer: " .. tostring(killerSelected) .. "</font>"
        else
            KillerPredictionLabel.Text = "<font size=\"14\"><b>KILLER PREDICTION</b></font>\n"
                .. "<font color=\"rgb(160,160,160)\" size=\"12\">No player found</font>\n"
                .. "<font size=\"11\">Killer: Unknown</font>"
        end
    end

    task.spawn(function()
        while true do
            if KillerPredictionEnabled then
                pcall(updateKillerPrediction)
            end
            task.wait(KillerPredictionInterval)
        end
    end)

    -- ============================================================
    -- WINDOW & TABS (VVind-UI)
    -- ============================================================
    local Window = VindUI:CreateWindow({
        Title      = "Wisnu Hub",
        Subtitle   = "Violence District",
        Icon       = "Lucide:swords",
        Size       = UDim2.fromOffset(580, 440),
        MinSize    = Vector2.new(480, 380),
        Draggable  = true,
        Resizable  = true,
        UseBlur    = false,
        DefaultTab = "Home",
    })

    local function mkSec(tab, name, icon)
        local ok, st = pcall(function()
            return tab:AddSubTab({ Name = name, Icon = icon or "Lucide:circle" })
        end)
        return ok and st or tab
    end

    local tabHome   = Window:AddTab({ Name = "Home",      Icon = "Lucide:layout-dashboard" })
    local tabSurv   = Window:AddTab({ Name = "Survivor",  Icon = "Lucide:user" })
    local tabESP    = Window:AddTab({ Name = "ESP",       Icon = "Lucide:eye" })
    local tabKiller = Window:AddTab({ Name = "Killer",    Icon = "Lucide:sword" })
    local tabAim    = Window:AddTab({ Name = "Aim",       Icon = "Lucide:crosshair" })
    local tabMisc   = Window:AddTab({ Name = "Misc",      Icon = "Lucide:layers" })
    local tabUI     = Window:AddTab({ Name = "Settings",  Icon = "Lucide:settings" })

    -- HOME TAB
    local homeInfo = mkSec(tabHome, "System Info", "Lucide:monitor")
    homeInfo:AddCard({
        UserId      = LocalPlayer.UserId,
        Title       = LocalPlayer.DisplayName,
        Description = "Violence District | Wisnu Hub",
    })
    homeInfo:AddSystemInfoGrid({ Description = "Live FPS, Ping & Executor" })


    -- ============================================================
    -- UI SURVIVOR
    -- ============================================================
    local secSkill = mkSec(tabSurv, "Skill Check")
    secSkill:AddToggle({ 
        Text = "Auto Skill Check",
        Default = VD.AutoSkillcheck,
        Callback = function(v) 
            VD.AutoSkillcheck = v
            if v then startSkillCheck() else if ConnectionsSkill.SkillHeartbeat then ConnectionsSkill.SkillHeartbeat:Disconnect() end end
        end,
        Flag = "SkillCheck",
    })
    secSkill:AddDropdown({ 
        Text = "Mode",
        Options = {"Legit", "Instant"},
        Default = VD.AutoSkillcheckMode,
        Callback = function(v) VD.AutoSkillcheckMode = v end,
        Flag = "SkillCheckMode",
    })

    local secParry = mkSec(tabSurv, "Parry")
    secParry:AddToggle({ 
        Text = "Auto Parry",
        Default = VD.Surv_AutoParry,
        Callback = function(v) VD.Surv_AutoParry = v end,
        Flag = "Parry_Enable",
    })
    secParry:AddSlider({ 
        Text = "Parry Range",
        Min = 5, Max = 30, Default = VD.Surv_ParryRange, Increment = 1,
        Callback = function(v) VD.Surv_ParryRange = v end,
        Flag = "Parry_Range",
    })
    secParry:AddToggle({ 
        Text = "Safety Mode",
        Default = VD.Surv_ParrySafety,
        Callback = function(v) VD.Surv_ParrySafety = v end,
        Flag = "Parry_Safety",
    })
    secParry:AddToggle({ 
        Text = "Aggressive",
        Default = VD.Surv_ParryAggressive,
        Callback = function(v) VD.Surv_ParryAggressive = v end,
        Flag = "Parry_Aggressive",
    })
    secParry:AddSlider({ 
        Text = "Face Threshold (0-1)",
        Min = 0, Max = 1, Default = VD.Surv_ParryFace, Increment = 0.1,
        Callback = function(v) VD.Surv_ParryFace = v end,
        Flag = "Parry_Face",
    })

    local secPredict = mkSec(tabSurv, "Killer Prediction (Spectator)")
    secPredict:AddToggle({ 
        Text = "Enable Killer Prediction",
        Default = VD.KillerPredict_Enabled,
        Tooltip = "Prediksi siapa yang akan jadi Killer berikutnya (hanya untuk Spectator)",
        Callback = function(v)
            VD.KillerPredict_Enabled = v
            KillerPredictionEnabled = v
            if not v and KillerPredictionLabel then
                KillerPredictionLabel:Destroy()
                KillerPredictionLabel = nil
            end
        end,
        Flag = "KillerPredict_Enable",
    })
    secPredict:AddSlider({ 
        Text = "Update Interval (detik)",
        Min = 1, Max = 10, Default = VD.KillerPredict_Interval, Increment = 0,
        Callback = function(v)
            VD.KillerPredict_Interval = v
            KillerPredictionInterval = v
        end,
        Flag = "KillerPredict_Interval",
    })

    local secFOV = mkSec(tabSurv, "Camera FOV")
    secFOV:AddToggle({ 
        Text = "Enable Custom FOV",
        Default = VD.CustomFOV,
        Callback = function(v) VD.CustomFOV = v end,
        Flag = "CustomFOV",
    })
    secFOV:AddSlider({ 
        Text = "FOV Value",
        Min = 70, Max = 120, Default = VD.FOVValue, Increment = 1,
        Callback = function(v) VD.FOVValue = v end,
        Flag = "FOVValue",
    })

    local secMiscSurv = mkSec(tabSurv, "Misc Survivor")
    secMiscSurv:AddToggle({ 
        Text = "Auto Crouch (Abyssal S1)",
        Default = VD.Surv_AutoCrouch,
        Callback = function(v) VD.Surv_AutoCrouch = v end,
        Flag = "AutoCrouch",
    })
    secMiscSurv:AddToggle({ 
        Text = "Auto Drop Pallet",
        Default = VD.Surv_AutoDropPallet,
        Callback = function(v) VD.Surv_AutoDropPallet = v end,
        Flag = "AutoDropPallet",
    })
    secMiscSurv:AddSlider({ 
        Text = "Drop Distance",
        Min = 2, Max = 15, Default = VD.Surv_AutoDropPalletDist, Increment = 1,
        Callback = function(v) VD.Surv_AutoDropPalletDist = v end,
        Flag = "AutoDropPalletDist",
    })
    secMiscSurv:AddToggle({ 
        Text = "Anti Knock",
        Default = VD.Surv_AntiKnock,
        Callback = function(v) VD.Surv_AntiKnock = v end,
        Flag = "AntiKnock",
    })
    secMiscSurv:AddToggle({ 
        Text = "Unlimited Vault",
        Default = VD.UnlimitedVault,
        Tooltip = "Vault/lompat jendela tanpa cooldown",
        Callback = function(v)
            VD.UnlimitedVault = v
            if v then EnableUnlimitedVault() else DisableUnlimitedVault() end
        end,
        Flag = "UnlimitedVault",
    })
    secMiscSurv:AddToggle({ 
        Text = "Gen Bypass (Boost Repair)",
        Default = VD.GenBypass_Enabled,
        Tooltip = "Memperbaiki generator dengan cepat. Aktifkan tombol BYPASS di layar (touch) atau tekan G (PC).",
        Callback = function(v)
            VD.GenBypass_Enabled = v
            setGenBypass(v)
            if v then
                Notify("Gen Bypass", "Aktif - Klik tombol BYPASS di layar atau tekan G", "success", 3)
            else
                Notify("Gen Bypass", "Nonaktif", "info", 2)
            end
        end,
        Flag = "GenBypassToggle",
    })
    secMiscSurv:AddToggle({ 
        Text = "🌙 Moonwalk (WisnuVip)",
        Default = VD.Moonwalk_Enabled,
        Tooltip = "Gerakan samping-mundur halus. Tekan G untuk toggle (PC) – GUI muncul di layar.",
        Callback = function(v)
            VD.Moonwalk_Enabled = v
            MoonwalkEnabled = v
            if v then 
                startMoonwalkInternal() 
            else 
                stopMoonwalkInternal() 
            end
            pcall(function()
                if MoonwalkGui then
                    local frame = MoonwalkGui:FindFirstChild("MainFrame")
                    if frame then
                        local toggleBtn = frame:FindFirstChild("ToggleBtn")
                        local statusLbl = frame:FindFirstChild("StatusLbl")
                        local glow = frame:FindFirstChild("Glow")
                        local speedFill = frame:FindFirstChild("SpeedBar") and frame.SpeedBar:FindFirstChild("SpeedFill")
                        if v then
                            toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
                            toggleBtn.Text = "■ STOP"
                            statusLbl.Text = "● ON"
                            statusLbl.TextColor3 = Color3.fromRGB(0, 255, 150)
                            glow.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
                            glow.BackgroundTransparency = 0.85
                            if speedFill then
                                TweenService:Create(speedFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(1, 1),
        Flag = "Moonwalk_Enable",
    }):Play()
                            end
                        else
                            toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 130)
                            toggleBtn.Text = "▶ START"
                            statusLbl.Text = "● OFF"
                            statusLbl.TextColor3 = Color3.fromRGB(255,80,80)
                            glow.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
                            glow.BackgroundTransparency = 0.9
                            if speedFill then
                                TweenService:Create(speedFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(0, 1)}):Play()
                            end
                        end
                    end
                end
            end)
        end
    })

    -- ============================================================
    -- UI ESP
    -- ============================================================
    local secESP = mkSec(tabESP, "ESP Settings")
    secESP:AddToggle({ 
        Text = "Enable ESP",
        Default = VD.ESP_Enabled,
        Callback = function(v) VD.ESP_Enabled = v; updateESP() end,
        Flag = "ESP_Main",
    })
    secESP:AddToggle({ 
        Text = "Survivor (Hijau)",
        Default = VD.ESP_Survivor,
        Callback = function(v) VD.ESP_Survivor = v; updateESP() end,
        Flag = "ESP_Survivor",
    })
    secESP:AddToggle({ 
        Text = "Killer (Merah)",
        Default = VD.ESP_Killer,
        Callback = function(v) VD.ESP_Killer = v; updateESP() end,
        Flag = "ESP_Killer",
    })
    secESP:AddToggle({ 
        Text = "Generator (Ungu)",
        Default = VD.ESP_Generator,
        Callback = function(v) VD.ESP_Generator = v; updateESP() end,
        Flag = "ESP_Generator",
    })
    secESP:AddToggle({ 
        Text = "Pallet (Biru Muda)",
        Default = VD.ESP_Pallet,
        Callback = function(v) VD.ESP_Pallet = v; updateESP() end,
        Flag = "ESP_Pallet",
    })
    secESP:AddToggle({ 
        Text = "Window (Kuning)",
        Default = VD.ESP_Window,
        Callback = function(v) VD.ESP_Window = v; updateESP() end,
        Flag = "ESP_Window",
    })
    secESP:AddToggle({ 
        Text = "SCP (Orange)",
        Default = VD.ESP_SCP,
        Callback = function(v) VD.ESP_SCP = v; updateESP() end,
        Flag = "ESP_SCP",
    })
    secESP:AddToggle({ 
        Text = "Gate (Putih)",
        Default = VD.ESP_Gate,
        Callback = function(v) VD.ESP_Gate = v; updateESP() end,
        Flag = "ESP_Gate",
    })
    secESP:AddToggle({ 
        Text = "Show Item Icon",
        Default = VD.ESP_ShowItem,
        Callback = function(v) VD.ESP_ShowItem = v; updateESP() end,
        Flag = "ESP_ShowItem",
    })
    secESP:AddSlider({ 
        Text = "Max Distance",
        Min = 20, Max = 10000, Default = VD.ESP_Distance, Increment = 0,
        Callback = function(v) VD.ESP_Distance = v; updateESP() end,
        Flag = "ESP_Distance",
    })
    secESP:AddButton({
        Text = "Refresh ESP",
        Icon = "solar/refresh-bold",
        Callback = function() updateESP(); Notify("ESP", "Refreshed", "success", 2) end
    })

    -- Color Pickers
    local secESPColor = mkSec(tabESP, "ESP Colors", "Lucide:palette")
    secESPColor:AddColorPicker({
        Text    = "Survivor Color",
        Flag    = "colorSurvivor",
        Default = COLORS.Survivor,
        Callback = function(c) COLORS.Survivor = c; updateESP() end,
    })
    secESPColor:AddColorPicker({
        Text    = "Killer Color",
        Flag    = "colorKiller",
        Default = COLORS.Killer,
        Callback = function(c) COLORS.Killer = c; updateESP() end,
    })
    secESPColor:AddColorPicker({
        Text    = "Generator Color",
        Flag    = "colorGenerator",
        Default = COLORS.Generator,
        Callback = function(c) COLORS.Generator = c; updateESP() end,
    })
    secESPColor:AddColorPicker({
        Text    = "Pallet Color",
        Flag    = "colorPallet",
        Default = COLORS.Pallet,
        Callback = function(c) COLORS.Pallet = c; updateESP() end,
    })
    secESPColor:AddColorPicker({
        Text    = "Window Color",
        Flag    = "colorWindow",
        Default = COLORS.Window,
        Callback = function(c) COLORS.Window = c; updateESP() end,
    })
    secESPColor:AddColorPicker({
        Text    = "SCP Color",
        Flag    = "colorSCP",
        Default = COLORS.SCP,
        Callback = function(c) COLORS.SCP = c; updateESP() end,
    })
    secESPColor:AddColorPicker({
        Text    = "Gate Color",
        Flag    = "colorGate",
        Default = COLORS.Gate,
        Callback = function(c) COLORS.Gate = c; updateESP() end,
    })

    local secVisual = mkSec(tabESP, "Visual Settings")
    secVisual:AddToggle({ 
        Text = "No Shadow",
        Default = VD.NoShadow,
        Callback = function(v) VD.NoShadow = v; applyVisualSettings() end,
        Flag = "NoShadow",
    })
    secVisual:AddToggle({ 
        Text = "Low Graphics",
        Default = VD.LowGraphics,
        Callback = function(v) VD.LowGraphics = v; applyVisualSettings() end,
        Flag = "LowGraphics",
    })
    secVisual:AddToggle({ 
        Text = "Fullbright",
        Default = VD.Fullbright,
        Callback = function(v) VD.Fullbright = v; applyVisualSettings() end,
        Flag = "Fullbright",
    })
    secVisual:AddToggle({ 
        Text = "No Fog",
        Default = VD.NoFog,
        Callback = function(v) VD.NoFog = v; applyVisualSettings() end,
        Flag = "NoFog",
    })

    -- ============================================================
    -- UI KILLER
    -- ============================================================
    local secKiller = mkSec(tabKiller, "Killer Features")
    secKiller:AddToggle({ 
        Text = "Unlock Skills While Carrying",
        Default = VD.UnlockSkillsCarry,
        Tooltip = "Memungkinkan menggunakan skill saat menggendong survivor",
        Callback = function(v)
            VD.UnlockSkillsCarry = v
            if v then SetupUnlockSkillsCarry() end
        end,
        Flag = "UnlockSkillsCarry",
    })
    secKiller:AddToggle({ 
        Text = "Auto Stalk (Myers)",
        Default = VD.AutoStalk,
        Tooltip = "Otomatis stalk survivor terdekat",
        Callback = function(v)
            VD.AutoStalk = v
            if v then StartAutoStalk() else StopAutoStalk() end
        end,
        Flag = "AutoStalk",
    })
    secKiller:AddParagraph({ Title = "Spear Aim Settings", Text = "" })
    secKiller:AddSlider({ 
        Text = "Spear Gravity",
        Min = 10, Max = 200, Default = VD.SpearGravity, Increment = 0,
        Callback = function(v) VD.SpearGravity = v end,
        Flag = "SpearGravity",
    })
    secKiller:AddSlider({ 
        Text = "Spear Speed",
        Min = 20, Max = 300, Default = VD.SpearSpeed, Increment = 0,
        Callback = function(v) VD.SpearSpeed = v end,
        Flag = "SpearSpeed",
    })
    secKiller:AddDropdown({ 
        Text = "Aimlock Mode",
        Options = {"Normal", "Spear"},
        Default = AttackAimMode,
        Callback = function(v) AttackAimMode = v end,
        Flag = "AttackAimMode",
    })

    secKiller:AddParagraph({ Title = "Veil Silent Aim", Text = "" })
    secKiller:AddToggle({ 
        Text = "Silent Aim (Veil)",
        Default = VD.Veil_SilentAim,
        Tooltip = "Otomatis target killer saat menggunakan Veil",
        Callback = function(v) VD.Veil_SilentAim = v end,
        Flag = "SA_Veil",
    })

    local secDouble = mkSec(tabKiller, "Double Damage Generator")
    secDouble:AddToggle({ 
        Text = "Double Damage Generator",
        Default = VD.DoubleDamageGen,
        Tooltip = "Saat menendang generator (BreakGenEvent), remote akan dikirim beberapa kali untuk damage berlipat.",
        Callback = function(v)
            VD.DoubleDamageGen = v
            if v then
                SetupUnlockSkillsCarry()
                Notify("Double Damage", "Aktif", "success", 2)
            else
                Notify("Double Damage", "Nonaktif", "info", 2)
            end
        end,
        Flag = "DoubleDamage",
    })

    local secHitbox = mkSec(tabKiller, "Hitbox Expander")
    secHitbox:AddToggle({ 
        Text = "Killer Hitbox",
        Default = VD.HitboxExpander,
        Tooltip = "Perbesar hitbox HumanoidRootPart semua killer (agar lebih mudah dipukul / dideteksi)",
        Callback = function(v)
            VD.HitboxExpander = v
            if not v then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local root = p.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            pcall(function()
                                root.Size = Vector3.new(2,2,1)
                                root.Transparency = 1
                                root.Material = Enum.Material.Plastic
                            end)
                        end
                    end
                end
            end
            Notify("Hitbox Expander", v and "ON – Size: "..tostring(VD.HitboxSize) or "OFF", "info", 2)
        end,
        Flag = "HitboxExpander",
    })
    secHitbox:AddSlider({ 
        Text = "Hitbox Size",
        Min = 2, Max = 50, Default = VD.HitboxSize, Increment = 0,
        Callback = function(v) VD.HitboxSize = v end,
        Flag = "HitboxSize",
    })

    local secMask = mkSec(tabKiller, "Mask Selection")
    secMask:AddToggle({ 
        Text = "Mask Selection GUI",
        Default = VD.MaskSelection_Enabled,
        Tooltip = "Tampilkan GUI pemilihan mask (untuk The Masked) – tekan M untuk minimize, angka 1-6 untuk mask, 7 untuk deaktivasi.",
        Callback = function(v)
            VD.MaskSelection_Enabled = v
            if v then ShowMaskGui() else HideMaskGui() end
        end,
        Flag = "MaskSelection_Enable",
    })

    -- ============================================================
    -- UI AIM (Pistol + Flash, tanpa Veil)
    -- ============================================================
    local secPistol = mkSec(tabAim, "🔫 Pistol Silent Aim")
    secPistol:AddToggle({ 
        Text = "Silent Aim (Pistol)",
        Default = VD.Pistol_SilentAim,
        Callback = function(v) 
            VD.Pistol_SilentAim = v
        end,
        Flag = "SA_Pistol",
    })
    secPistol:AddToggle({ 
        Text = "Block when Knocked",
        Default = VD.Pistol_BlockKnocked,
        Callback = function(v) VD.Pistol_BlockKnocked = v end,
        Flag = "SA_BlockKnocked",
    })
    secPistol:AddToggle({ 
        Text = "Lock Aim",
        Default = VD.Pistol_LockAim,
        Callback = function(v) VD.Pistol_LockAim = v end,
        Flag = "SA_LockAim",
    })
    secPistol:AddToggle({ 
        Text = "FOV Mode",
        Default = VD.Pistol_FOVMode,
        Callback = function(v) VD.Pistol_FOVMode = v end,
        Flag = "SA_FOVMode",
    })
    secPistol:AddToggle({ 
        Text = "Show FOV Circle",
        Default = VD.Pistol_ShowFOV,
        Callback = function(v) VD.Pistol_ShowFOV = v end,
        Flag = "SA_ShowFOV",
    })
    secPistol:AddSlider({ 
        Text = "FOV Radius",
        Min = 30, Max = 500, Default = VD.Pistol_FOV, Increment = 5,
        Callback = function(v) VD.Pistol_FOV = v end,
        Flag = "SA_FOV",
    })
    secPistol:AddDropdown({ 
        Text = "Target",
        Options = {"Killer", "Survivor", "SCP"},
        Default = VD.Pistol_Target,
        Callback = function(v) 
            VD.Pistol_Target = v[1]
        end,
        Flag = "SA_Target",
    })
    secPistol:AddDropdown({ 
        Text = "Target Part",
        Options = {"Torso", "Head", "Root"},
        Default = VD.Pistol_TargetPart,
        Callback = function(v) VD.Pistol_TargetPart = v end,
        Flag = "SA_TargetPart",
    })
    secPistol:AddToggle({ 
        Text = "Hide Laser",
        Default = VD.Pistol_HideLaser,
        Callback = function(v) 
            VD.Pistol_HideLaser = v
            if pistolLaser then pistolLaser.Transparency = v and 1 or 0 end
        end,
        Flag = "SA_HideLaser",
    })

    local secFlash = mkSec(tabAim, "🔦 Flashlight Silent Aim")
    secFlash:AddToggle({ 
        Text = "Silent Aim (Flashlight)",
        Default = VD.Flash_SilentAim,
        Callback = function(v) VD.Flash_SilentAim = v end,
        Flag = "SA_Flash",
    })
    secFlash:AddSlider({ 
        Text = "Flash Y Offset",
        Min = -5, Max = 20, Default = VD.Flash_YOffset, Increment = 0.5,
        Callback = function(v) VD.Flash_YOffset = v end,
        Flag = "SA_FlashYOffset",
    })

    -- ============================================================
    -- UI MISC
    -- ============================================================
    local secFakeAva = mkSec(tabMisc, "Fake Avatar", "Lucide:user-round-x")
    secFakeAva:AddToggle({
        Text    = "Korless Morph",
        Description = "Sembunyikan head + ganti dengan Korless mask",
        Default = false,
        Flag    = "KorlessMorph",
        Callback = function(v)
            KorlessMorph.Enabled = v
            if v then
                ApplyKorless()
                Notify("Fake Avatar", "Korless Morph ON", "success", 2)
            else
                RemoveKorless()
                Notify("Fake Avatar", "Morph removed", "info", 2)
            end
        end,
    })

    local secCutscene = mkSec(tabMisc, "Cutscene", "Lucide:film")
    secCutscene:AddToggle({ Text = "Skip Cutscene",
        Default = VD.SkipCutscene,
        Flag = "SkipCutscene",
        Callback = function(v)
            VD.SkipCutscene = v
            if v then pcall(TrySkipCutscene) end
        end,
    })

    local secMisc = mkSec(tabMisc, "Performance & Display")
    secMisc:AddToggle({ 
        Text = "Show FPS Counter",
        Default = VD.ShowFPS,
        Callback = function(v)
            VD.ShowFPS = v
            if not FPSFrame then createCounter() end
            updateCounterVisibility()
            if not v then fpsCount = 0; fpsTime = 0 end
        end,
        Flag = "ShowFPS",
    })
    secMisc:AddToggle({ 
        Text = "Show Ping Counter",
        Default = VD.ShowPing,
        Callback = function(v)
            VD.ShowPing = v
            if not FPSFrame then createCounter() end
            updateCounterVisibility()
        end,
        Flag = "ShowPing",
    })
    secMisc:AddToggle({ 
        Text = "Reduce Map (Hapus Partikel)",
        Default = VD.ReduceMap,
        Tooltip = "Menghapus partikel & dekorasi untuk meningkatkan performa",
        Callback = function(v)
            VD.ReduceMap = v
            applyVisualSettings()
        end,
        Flag = "ReduceMap",
    })
    secMisc:AddToggle({ 
        Text = "Remove Visual Effects",
        Default = VD.RemoveVisualEffects,
        Tooltip = "Hapus semua efek visual (bloom, DOF, atmosfer, kabut, dll.)",
        Callback = function(v)
            VD.RemoveVisualEffects = v
            applyVisualSettings()
            if v then
                Notify("Visual Effects", "Semua efek disembunyikan", "success", 2)
            else
                Notify("Visual Effects", "Efek dipulihkan", "info", 2)
            end
        end,
        Flag = "RemoveVisualEffects",
    })

    -- ============================================================
    -- UI SETTINGS
    -- ============================================================
    -- Settings tab — VVind save/load config
    local settingsSec = mkSec(tabUI, "Configuration", "Lucide:save")
    settingsSec:AddButton({
        Text = "Save Config",
        Icon = "Lucide:save",
        Callback = function()
            pcall(function() VindUI:SaveConfig("wisnuhub") end)
            Notify("Config", "Saved", "success", 2)
        end,
    })
    settingsSec:AddButton({
        Text = "Load Config",
        Icon = "Lucide:folder-open",
        Callback = function()
            pcall(function() VindUI:LoadConfig("wisnuhub", true) end)
            Notify("Config", "Loaded", "success", 2)
        end,
    })

    -- ============================================================
    -- FLOATING BUTTON
    -- ============================================================
    local function createFloatingButton()
        Fluent.FloatingButtonManager:SetLibrary(Fluent)

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "WisnuHub_FloatingBtn"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = CoreGui

        local btn = Instance.new("ImageButton")
        btn.Size = UDim2.new(0, 50, 0, 50)
        btn.AnchorPoint = Vector2.new(0, 0)
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.Parent = screenGui

        local viewport = Camera.ViewportSize
        btn.Position = UDim2.new(0, viewport.X - 50 - 16, 0, viewport.Y - 50 - 16)

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundTransparency = 1
        bg.BorderSizePixel = 0
        bg.Parent = btn

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = bg

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.5
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 1
        stroke.Parent = bg

        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 32, 0, 32)
        icon.Position = UDim2.new(0.5, -16, 0.5, -16)
        icon.BackgroundTransparency = 1
        icon.Image = "rbxassetid://80668677085388"
        icon.ScaleType = Enum.ScaleType.Fit
        icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
        icon.Parent = bg

        local dragging = false
        local dragStartMouse = Vector2.new()
        local dragStartPos = Vector2.new()

        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStartMouse = input.Position
                dragStartPos = Vector2.new(btn.Position.X.Offset, btn.Position.Y.Offset)
            end
        end)

        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = input.Position - dragStartMouse
                local newX = math.clamp(dragStartPos.X + delta.X, 0, Camera.ViewportSize.X - btn.Size.X.Offset)
                local newY = math.clamp(dragStartPos.Y + delta.Y, 0, Camera.ViewportSize.Y - btn.Size.Y.Offset)
                btn.Position = UDim2.new(0, newX, 0, newY)
            end
        end)

        local _uiOpen = true
        btn.MouseButton1Click:Connect(function()
            _uiOpen = not _uiOpen
            pcall(function()
                -- VVind-UI: coba Toggle, fallback ke ScreenGui Enabled
                if Window.Toggle then
                    Window:Toggle()
                elseif Window.ScreenGui then
                    Window.ScreenGui.Enabled = _uiOpen
                elseif Window.Root then
                    Window.Root.Enabled = _uiOpen
                end
            end)
        end)
    end
    createFloatingButton()

    -- ============================================================
    -- AUTO UPDATE ESP & LOOPS
    -- ============================================================
    local function onCharacterAdded(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if VD.ESP_Enabled then updateESP() end
        end)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then onCharacterAdded(player) end
    end

    Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then onCharacterAdded(player) end
    end)

    Players.PlayerRemoving:Connect(function()
        if VD.ESP_Enabled then task.wait(0.1); updateESP() end
    end)

    task.spawn(function()
        while RunService:IsRunning() do
            task.wait(2)
            if VD.ESP_Enabled then updateESP() end
        end
    end)

    local UsedPallets = {}
    RunService.Heartbeat:Connect(function()
        if VD.Surv_AntiKnock then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth then pcall(function() hum.Health = hum.MaxHealth end) end
            if hum then
                local state = hum:GetState()
                if state == Enum.HumanoidStateType.Dead or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll then
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
                end
            end
        end

        if VD.Surv_AutoDropPallet then
            local root = getRoot()
            if root then
                local killerRoot, killerDist = nil, math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and IsKiller(p) and p.Character then
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local d = (hrp.Position - root.Position).Magnitude
                            if d < killerDist then killerDist = d; killerRoot = hrp end
                        end
                    end
                end
                if killerRoot and killerDist <= VD.Surv_AutoDropPalletDist then
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    local palletFold = remotes and remotes:FindFirstChild("Pallet")
                    local dropEvent = palletFold and palletFold:FindFirstChild("PalletDropEvent")
                    if dropEvent then
                        local bestPallet = nil
                        local bestDist = 8
                        for _, pallet in ipairs(Workspace:GetDescendants()) do
                            if (pallet.Name == "Pallet" or pallet.Name == "Palletwrong") and pallet:IsA("Model") and not UsedPallets[pallet] then
                                local refPart = pallet:FindFirstChild("PalletPoint") or pallet:FindFirstChild("PalletPointSlide")
                                if refPart then
                                    local d2 = (root.Position - refPart.Position).Magnitude
                                    if d2 < bestDist then
                                        bestDist = d2
                                        bestPallet = pallet
                                    end
                                end
                            end
                        end
                        if bestPallet then
                            local fireTarget = bestPallet:FindFirstChild("PalletPointSlide") or bestPallet:FindFirstChild("PalletPoint")
                            if fireTarget then
                                pcall(function() dropEvent:FireServer(fireTarget) end)
                                UsedPallets[bestPallet] = true
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Custom FOV loop
    RunService:BindToRenderStep("CustomFOV", Enum.RenderPriority.Camera.Value + 1, function()
        if VD.CustomFOV then
            local cam = Workspace.CurrentCamera
            if cam then
                cam.FieldOfView = VD.FOVValue
            end
        end
    end)

    -- ============================================================
    -- NOTIFICATION
    -- ============================================================
    Notify("Wisnu Hub", "JEMBOT game babi.", "success", 8)

    print("✅game jembot!")
end -- end of Onyx.Callbacks.OnSuccess

-- ============================================================
-- JALANKAN SISTEM KEY ONYX
-- ============================================================
Onyx:LaunchJunkie({
    Service = "Wisnu",
    Identifier = "1163413",
    Provider = "WISNU HUB"
})