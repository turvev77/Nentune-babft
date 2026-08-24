-- ╔════════════════════════════════════════════════════════════════╗
-- ║       NEPTUNE.LUA BABFT — WITH AUTO FARM & ULTRA FARM          ║
-- ╚════════════════════════════════════════════════════════════════╝

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local Lighting          = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")
local camera    = Workspace.CurrentCamera

local function updateCharVars(newChar)
    character = newChar or player.Character
    if character then
        humanoid = character:WaitForChild("Humanoid", 5)
        rootPart = character:WaitForChild("HumanoidRootPart", 5)
    end
end

local State = {
    fly       = false,
    noclip    = false,
    god       = false,
    autofarm  = false,
    ultrafarm = false,
    speed     = false,
    jump      = false,
    infjump   = false,
    bhop      = false,
    fov       = false,
    infzoom   = false,
    zoomSpeed = 5,
    esp       = false,
    goldesp   = false,
    clicktp   = false,
    invisible = false,
    shaders   = false,
    flySpeed  = 80,
    farmSpeed = 450,
    walkSpeed = 35,
    jumpPower = 80,
    fovVal    = 110,
    espMode   = "Both",
    espHitbox   = false,
    espChams    = false,
    espTracers  = false,
    espSkeleton = false,
    espHealth   = false,
    espNameDist = true,
    cycleRunning = false,
    espHitboxSize = 2.0,
    espChamsColor = Color3.fromRGB(255, 50, 50),
    espChamsTransp = 0.5,
    espTracerColor = Color3.fromRGB(0, 230, 160),
    killDelay = 19,
    farmMode  = "Method 1",
    shaderTint = Color3.fromRGB(255, 200, 150),
    fogDensity = 0.05,
    fogColor   = Color3.fromRGB(150, 180, 200),
    saturation = 0.3,
    contrast   = 0.1
}

local bv, bg, connection
local currentTween = nil
local activeSettingsOwner = nil
local autoKillConnection = nil
local autoFarm2Loop = nil
local ultraKillConnection = nil
local ultraFarm2Loop = nil
local antiKickConnection = nil
local originalLightingProps = {}
local customAtmosphere = nil
local customColorCorrection = nil
local shaderButtonReference = nil

-- Цветовая палитра (macOS тема)
local C = {
    bg       = Color3.fromRGB(20,  26,  24),
    panel    = Color3.fromRGB(28,  38,  34),
    panel2   = Color3.fromRGB(36,  50,  44),
    header   = Color3.fromRGB(15,  20,  18),
    accent   = Color3.fromRGB(0,   230, 160),
    accent2  = Color3.fromRGB(80,  255, 120),
    text     = Color3.fromRGB(235, 255, 245),
    muted    = Color3.fromRGB(120, 150, 135),
    green    = Color3.fromRGB(0,   255, 100),
    red      = Color3.fromRGB(230, 60,  60),
    border   = Color3.fromRGB(45,  75,  60),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "NeptuneLuaBabft"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local ok = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ok then ScreenGui.Parent = player.PlayerGui end

-- ==========================================
-- ОСНОВНОЙ ИНТЕРФЕЙС
-- ==========================================
-- Обёртка для ClipsDescendants — без UICorner, иначе углы торчат при minimize
local MainClip = Instance.new("Frame")
MainClip.Size              = UDim2.new(0, 480, 0, 160)
MainClip.Position          = UDim2.new(0.5, -240, 0.5, -80)
MainClip.BackgroundTransparency = 1
MainClip.BorderSizePixel   = 0
MainClip.ClipsDescendants  = true  -- обрезает строго по прямоугольнику
MainClip.Parent            = ScreenGui

local MainContainer = Instance.new("Frame")
MainContainer.Size              = UDim2.new(1, 0, 1, 0)  -- 100% от обёртки
MainContainer.Position          = UDim2.new(0, 0, 0, 0)
MainContainer.BackgroundColor3  = C.bg
MainContainer.BackgroundTransparency = 0.1
MainContainer.Visible           = true
MainContainer.ClipsDescendants  = false  -- убираем — теперь режет MainClip
MainContainer.Parent            = MainClip
Instance.new("UICorner", MainContainer).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = C.border
MainStroke.Thickness = 1.5
MainStroke.Parent = MainContainer

-- Startup border pulse (position stays fixed, only border animates)
task.spawn(function()
    task.wait(0.1)
    TweenService:Create(MainStroke, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Color = C.accent, Thickness = 2}):Play()
    task.wait(0.5)
    TweenService:Create(MainStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Color = C.border, Thickness = 1.5}):Play()
end)

local MacHeader = Instance.new("Frame")
MacHeader.Size = UDim2.new(1, 0, 0, 30)
MacHeader.BackgroundColor3 = C.header
MacHeader.BorderSizePixel = 0
MacHeader.Parent = MainContainer
Instance.new("UICorner", MacHeader).CornerRadius = UDim.new(0, 10)

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 10)
headerFix.Position = UDim2.new(0, 0, 1, -10)
headerFix.BackgroundColor3 = C.header
headerFix.BorderSizePixel = 0
headerFix.Parent = MacHeader

local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.new(0, 12, 0, 12)
btnClose.Position = UDim2.new(0, 12, 0, 9)
btnClose.BackgroundColor3 = Color3.fromRGB(255, 95, 86)
btnClose.Text = ""
btnClose.Parent = MacHeader
Instance.new("UICorner", btnClose).CornerRadius = UDim.new(1, 0)

local btnMinimize = Instance.new("TextButton")
btnMinimize.Size = UDim2.new(0, 12, 0, 12)
btnMinimize.Position = UDim2.new(0, 30, 0, 9)
btnMinimize.BackgroundColor3 = Color3.fromRGB(255, 189, 46)
btnMinimize.Text = ""
btnMinimize.Parent = MacHeader
Instance.new("UICorner", btnMinimize).CornerRadius = UDim.new(1, 0)

local btnExpand = Instance.new("TextButton")
btnExpand.Size = UDim2.new(0, 12, 0, 12)
btnExpand.Position = UDim2.new(0, 48, 0, 9)
btnExpand.BackgroundColor3 = Color3.fromRGB(39, 201, 63)
btnExpand.Text = ""
btnExpand.Parent = MacHeader
Instance.new("UICorner", btnExpand).CornerRadius = UDim.new(1, 0)

local WindowTitle = Instance.new("TextLabel")
WindowTitle.Size = UDim2.new(1, 0, 1, 0)
WindowTitle.BackgroundTransparency = 1
WindowTitle.Text = "neptune.lua — dashboard"
WindowTitle.TextColor3 = C.muted
WindowTitle.TextSize = 11
WindowTitle.Font = Enum.Font.Code
WindowTitle.Parent = MacHeader

-- Close: simple hide
btnClose.MouseButton1Click:Connect(function()
    MainContainer.Visible = false
end)

-- Minimize: collapse/expand
-- FIX: запоминаем реальную высоту перед схлопыванием
local minimizeLock = false
local savedMainH = 160
btnMinimize.MouseButton1Click:Connect(function()
    if minimizeLock then return end
    minimizeLock = true
    local isCollapsed = MainClip.Size.Y.Offset <= 35
    if isCollapsed then
        -- Разворачиваем обёртку и контейнер одновременно
        TweenService:Create(MainClip, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 480, 0, savedMainH)}):Play()
        local tw = TweenService:Create(MainContainer, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {Size = UDim2.new(1, 0, 1, 0)})
        tw:Play()
        tw.Completed:Connect(function()
            for _, ch in ipairs(MainContainer:GetChildren()) do
                if ch:IsA("Frame") and ch ~= MacHeader then ch.Visible = true end
            end
            minimizeLock = false
        end)
    else
        savedMainH = MainClip.Size.Y.Offset
        for _, ch in ipairs(MainContainer:GetChildren()) do
            if ch:IsA("Frame") and ch ~= MacHeader then ch.Visible = false end
        end
        -- Схлопываем обёртку — она режет углы правильно
        TweenService:Create(MainClip, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 480, 0, 30)}):Play()
        local tw = TweenService:Create(MainContainer, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Size = UDim2.new(1, 0, 1, 0)})
        tw:Play()
        tw.Completed:Connect(function() minimizeLock = false end)
    end
end)

-- Mac button hover animations (color only, no size change to avoid layout issues)
local function animMacBtn(btn, baseColor)
    local TI_in  = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TI_out = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local bright = Color3.new(
        math.min(baseColor.R * 1.3, 1),
        math.min(baseColor.G * 1.3, 1),
        math.min(baseColor.B * 1.3, 1)
    )
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TI_in, {BackgroundColor3 = bright}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TI_out, {BackgroundColor3 = baseColor}):Play()
    end)
end
animMacBtn(btnClose,    Color3.fromRGB(255, 95,  86))
animMacBtn(btnMinimize, Color3.fromRGB(255, 189, 46))
animMacBtn(btnExpand,   Color3.fromRGB(39,  201, 63))

-- Alt зажат = режим ресайза (подсвечиваем рамку)
local function isAlt()
    return UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
end

local mainDragging, mainDragStart, mainStartPos = false, nil, nil
local mainResizing, mainResizeStart, mainResizeStartSize = false, nil, nil
local MAIN_MIN_W, MAIN_MIN_H = 200, 50

MacHeader.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        if isAlt() then
            mainResizing        = true
            mainResizeStart     = inp.Position
            mainResizeStartSize = Vector2.new(MainClip.AbsoluteSize.X, MainClip.AbsoluteSize.Y)
            MainStroke.Color    = C.accent2
        else
            mainDragging  = true
            mainDragStart = inp.Position
            mainStartPos  = MainClip.Position
        end
    end
end)
MacHeader.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        mainDragging = false
        if mainResizing then
            mainResizing     = false
            MainStroke.Color = C.border
        end
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if mainResizing then
        local d    = inp.Position - mainResizeStart
        local newW = math.max(MAIN_MIN_W, mainResizeStartSize.X + d.X)
        local newH = math.max(MAIN_MIN_H, mainResizeStartSize.Y + d.Y)
        MainClip.Size = UDim2.new(0, newW, 0, newH)
    elseif mainDragging then
        local d = inp.Position - mainDragStart
        MainClip.Position = UDim2.new(mainStartPos.X.Scale, mainStartPos.X.Offset + d.X,
                                      mainStartPos.Y.Scale, mainStartPos.Y.Offset + d.Y)
    end
end)

local SettingsPopup = Instance.new("Frame")
SettingsPopup.Size              = UDim2.new(0, 240, 0, 220)
SettingsPopup.BackgroundColor3  = C.panel2
SettingsPopup.BorderSizePixel   = 0
SettingsPopup.Visible           = false
SettingsPopup.ZIndex            = 10
SettingsPopup.Parent            = ScreenGui
Instance.new("UICorner", SettingsPopup).CornerRadius = UDim.new(0, 6)
local PopStroke = Instance.new("UIStroke")
PopStroke.Color = C.accent
PopStroke.Thickness = 1
PopStroke.Parent = SettingsPopup

local function toggleSettingsPopup(ownerName, title, builderFunc, pos)
    if activeSettingsOwner == ownerName then
        local tw = TweenService:Create(SettingsPopup, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0, SettingsPopup.Position.X.Offset, 0, SettingsPopup.Position.Y.Offset - 6),
        })
        tw:Play()
        tw.Completed:Connect(function()
            SettingsPopup.Visible = false
            SettingsPopup.Position = UDim2.new(0, pos.X, 0, pos.Y)
        end)
        activeSettingsOwner = nil
        return
    end

    SettingsPopup.Position = UDim2.new(0, pos.X, 0, pos.Y + 8)
    for _, child in ipairs(SettingsPopup:GetChildren()) do
        if child:IsA("GuiObject") and child ~= PopStroke and child.Name ~= "UICorner" then
            child:Destroy()
        end
    end

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -10, 0, 22)
    Title.Position = UDim2.new(0, 8, 0, 4)
    Title.BackgroundTransparency = 1
    Title.Text = title
    Title.TextColor3 = C.accent
    Title.TextSize = 11
    Title.Font = Enum.Font.Code
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 11
    Title.Parent = SettingsPopup

    builderFunc(SettingsPopup)
    SettingsPopup.Visible = true
    activeSettingsOwner = ownerName

    -- Animate open: slide-down into place
    TweenService:Create(SettingsPopup, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, pos.X, 0, pos.Y),
    }):Play()
end

-- categoryHeights[window] = целевая высота категории (обновляется до tween)
local categoryHeights = {}

local function syncMainHeight()
    if MainClip.Size.Y.Offset <= 35 then return end
    local maxH = 26
    for _, h in pairs(categoryHeights) do
        if h > maxH then maxH = h end
    end
    local targetH = math.max(160, 40 + maxH + 14)
    TweenService:Create(MainClip,
        TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 480, 0, targetH)}):Play()
    savedMainH = targetH
end

local function createCategory(title, posX)
    local Window = Instance.new("Frame")
    Window.Size             = UDim2.new(0, 145, 0, 30)
    Window.Position         = UDim2.new(0, posX, 0, 40)
    Window.BackgroundColor3 = C.panel
    Window.BorderSizePixel  = 0
    Window.ClipsDescendants = true
    Window.Parent           = MainContainer
    Instance.new("UICorner", Window).CornerRadius = UDim.new(0, 6)

    local WinStroke = Instance.new("UIStroke")
    WinStroke.Color = C.border
    WinStroke.Thickness = 1
    WinStroke.Parent = Window

    local WinHeader = Instance.new("Frame")
    WinHeader.Size              = UDim2.new(1, 0, 0, 26)
    WinHeader.BackgroundColor3  = C.header
    WinHeader.BorderSizePixel   = 0
    WinHeader.Parent            = Window
    Instance.new("UICorner", WinHeader).CornerRadius = UDim.new(0, 6)

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size               = UDim2.new(1, -10, 1, 0)
    TitleLbl.Position           = UDim2.new(0, 8, 0, 0)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text               = title .. "  [+]"
    TitleLbl.TextColor3         = C.accent
    TitleLbl.TextSize           = 11
    TitleLbl.Font               = Enum.Font.Code
    TitleLbl.TextXAlignment     = Enum.TextXAlignment.Left
    TitleLbl.Parent             = WinHeader

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size                 = UDim2.new(1, -4, 0, 0)
    Scroll.Position             = UDim2.new(0, 2, 0, 28)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel      = 0
    Scroll.ScrollBarThickness   = 2
    Scroll.ScrollBarImageColor3 = C.accent
    Scroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
    Scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    Scroll.Parent               = Window

    local UIList = Instance.new("UIListLayout")
    UIList.SortOrder            = Enum.SortOrder.LayoutOrder
    UIList.Padding              = UDim.new(0, 3)
    UIList.Parent               = Scroll

    -- FIX: стартуем свёрнутыми, но Scroll заранее не зануляем по высоте
    local collapsed = true
    Window.Size = UDim2.new(0, 145, 0, 26)

    -- FIX: Scroll всегда держит реальную высоту контента —
    -- ClipsDescendants на Window скрывает его пока свёрнуто
    local function getContentH()
        -- читаем напрямую, не из кешированной переменной
        return UIList.AbsoluteContentSize.Y
    end

    UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local h = getContentH()
        -- Scroll всегда имеет правильный размер
        Scroll.Size = UDim2.new(1, -4, 0, h)
        -- если уже открыт — обновляем Window тоже (без анимации)
        if not collapsed then
            Window.Size = UDim2.new(0, 145, 0, h + 32)
        end
    end)

    local TI_cat_open  = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local TI_cat_close = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.In)
    local TI_hdr       = TweenInfo.new(0.12, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)

    WinHeader.MouseEnter:Connect(function()
        TweenService:Create(WinHeader, TI_hdr, {BackgroundColor3 = Color3.fromRGB(22, 30, 26)}):Play()
    end)
    WinHeader.MouseLeave:Connect(function()
        TweenService:Create(WinHeader, TI_hdr, {BackgroundColor3 = C.header}):Play()
    end)

    -- Регистрируем эту категорию в таблице высот (свёрнута по умолчанию)
    categoryHeights[Window] = 26

    WinHeader.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            collapsed = not collapsed
            if collapsed then
                TitleLbl.Text = title .. "  [+]"
                -- Обновляем таблицу ДО tween
                categoryHeights[Window] = 26
                syncMainHeight()
                TweenService:Create(WinStroke, TI_cat_close, {Color = C.border}):Play()
                TweenService:Create(Window,    TI_cat_close, {Size  = UDim2.new(0, 145, 0, 26)}):Play()
            else
                TitleLbl.Text = title .. "  [-]"
                local h = getContentH()
                local function doOpen(h2)
                    Scroll.Size = UDim2.new(1, -4, 0, h2)
                    -- Обновляем таблицу ДО tween — syncMainHeight читает правильное значение
                    categoryHeights[Window] = h2 + 32
                    syncMainHeight()
                    TweenService:Create(WinStroke, TI_cat_open, {Color = C.accent}):Play()
                    TweenService:Create(Window,    TI_cat_open, {Size  = UDim2.new(0, 145, 0, h2 + 32)}):Play()
                    task.delay(0.35, function()
                        TweenService:Create(WinStroke, TweenInfo.new(0.3), {Color = C.border}):Play()
                    end)
                end
                if h == 0 then
                    task.defer(function() doOpen(getContentH()) end)
                else
                    doOpen(h)
                end
            end
        end
    end)

    return Scroll
end

local colPlayer   = createCategory("Player", 12)
local colMovement = createCategory("Movement", 167)
local colMisc     = createCategory("Misc", 322)

local function createModule(parent, name, callback, settingsCallback)
    local Btn = Instance.new("TextButton")
    Btn.Size                = UDim2.new(1, 0, 0, 24)
    Btn.BackgroundColor3    = C.panel2
    Btn.BorderSizePixel     = 0
    Btn.Text                = "  " .. name
    Btn.TextColor3          = C.muted
    Btn.TextSize            = 10
    Btn.Font                = Enum.Font.Code
    Btn.TextXAlignment      = Enum.TextXAlignment.Left
    Btn.Parent              = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)

    local active = false
    local TI_toggle = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TI_hover  = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function triggerState(newState)
        active = newState
        TweenService:Create(Btn, TI_toggle, {
            BackgroundColor3 = active and C.accent or C.panel2,
            TextColor3       = active and C.bg or C.muted,
        }):Play()
        -- small scale pulse via Size
        if active then
            TweenService:Create(Btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = UDim2.new(1, 2, 0, 26)}):Play()
            task.delay(0.08, function()
                TweenService:Create(Btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = UDim2.new(1, 0, 0, 24)}):Play()
            end)
        end
        callback(active)
    end

    Btn.MouseButton1Click:Connect(function()
        triggerState(not active)
    end)

    if name == "World Shaders" then
        shaderButtonReference = {
            Set = triggerState,
            Get = function() return active end
        }
    end

    if settingsCallback then
        Btn.MouseButton2Click:Connect(function()
            local mouseLoc = UserInputService:GetMouseLocation()
            toggleSettingsPopup(name, name .. " Settings", settingsCallback, mouseLoc)
        end)
    end

    Btn.MouseEnter:Connect(function()
        if not active then
            TweenService:Create(Btn, TI_hover, {BackgroundColor3 = C.header}):Play()
        end
    end)
    Btn.MouseLeave:Connect(function()
        if not active then
            TweenService:Create(Btn, TI_hover, {BackgroundColor3 = C.panel2}):Play()
        end
    end)
end

local function forceKillCharacter(char)
    if not char then return end
    char:BreakJoints()
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
    if root then root:Destroy() end
    if head then head:Destroy() end
end

local runSingleCycle
local startAutoKillLoop
local runUltraSingleCycle
local startUltraKillLoop

-- Применение оптимизации FPS для Ultra Farm
local function applyFpsBoost(on)
    if on then
        originalLightingProps.GlobalShadows = Lighting.GlobalShadows
        originalLightingProps.FogEnd = Lighting.FogEnd
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 999999
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                obj.Enabled = false
            elseif obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
            end
        end
    else
        Lighting.GlobalShadows = originalLightingProps.GlobalShadows or true
        Lighting.FogEnd = originalLightingProps.FogEnd or 100000
    end
end

-- Включение защиты от кика (Anti-Kick)
local function startAntiKick()
    if antiKickConnection then pcall(function() task.cancel(antiKickConnection) end) end
    antiKickConnection = task.spawn(function()
        local vu = game:GetService("VirtualUser")
        while State.ultrafarm do
            pcall(function()
                vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
            task.wait(50)
        end
    end)
end

local function startAutoFarm2Loop()
    if autoFarm2Loop then
        pcall(function() task.cancel(autoFarm2Loop) end)
        autoFarm2Loop = nil
    end
    autoFarm2Loop = task.spawn(function()
        while State.autofarm do
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local normalStages = Workspace:FindFirstChild("BoatStages") and Workspace.BoatStages:FindFirstChild("NormalStages")
                if normalStages then
                    for i = 1, 10 do
                        if not State.autofarm then break end
                        local stage = normalStages:FindFirstChild("CaveStage" .. i)
                        if stage and stage:FindFirstChild("DarknessPart") then
                            char.HumanoidRootPart.CFrame = stage.DarknessPart.CFrame
                            
                            local tempPart = Instance.new("Part", char)
                            tempPart.Anchored = true
                            tempPart.Size = Vector3.new(6, 1, 6)
                            
                            local backPos = char.HumanoidRootPart.CFrame + (char.HumanoidRootPart.CFrame.LookVector * 10) - Vector3.new(0, 3, 0)
                            tempPart.CFrame = backPos
                            char.HumanoidRootPart.CFrame = backPos + Vector3.new(0, 4, 0)
                            
                            task.wait(1.7)
                            tempPart:Destroy()
                        end
                    end

                    if State.autofarm then
                        forceKillCharacter(char)
                    end
                end
            end
            task.wait(3)
        end
    end)
end

local function startUltraFarm2Loop()
    if ultraFarm2Loop then
        pcall(function() task.cancel(ultraFarm2Loop) end)
        ultraFarm2Loop = nil
    end
    ultraFarm2Loop = task.spawn(function()
        while State.ultrafarm do
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local normalStages = Workspace:FindFirstChild("BoatStages") and Workspace.BoatStages:FindFirstChild("NormalStages")
                if normalStages then
                    for i = 1, 10 do
                        if not State.ultrafarm then break end
                        local stage = normalStages:FindFirstChild("CaveStage" .. i)
                        if stage and stage:FindFirstChild("DarknessPart") then
                            char.HumanoidRootPart.CFrame = stage.DarknessPart.CFrame
                            
                            local tempPart = Instance.new("Part", char)
                            tempPart.Anchored = true
                            tempPart.Size = Vector3.new(6, 1, 6)
                            
                            local backPos = char.HumanoidRootPart.CFrame + (char.HumanoidRootPart.CFrame.LookVector * 10) - Vector3.new(0, 3, 0)
                            tempPart.CFrame = backPos
                            char.HumanoidRootPart.CFrame = backPos + Vector3.new(0, 4, 0)
                            
                            task.wait(1.7)
                            tempPart:Destroy()
                        end
                    end

                    if State.ultrafarm then
                        forceKillCharacter(char)
                    end
                end
            end
            task.wait(3)
        end
    end)
end

createModule(colPlayer, "God Mode", function(on) State.god = on end)

-- Стандартный Auto Farm
createModule(colPlayer, "Auto Farm", function(on)
    State.autofarm = on
    if on then
        if State.farmMode == "Method 1" then
            if player.Character then task.spawn(function() runSingleCycle(player.Character) end) end
            task.delay(1, function() if State.autofarm then startAutoKillLoop() end end)
        else
            startAutoFarm2Loop()
        end
    else
        if currentTween then currentTween:Cancel() end
        if autoKillConnection then pcall(function() task.cancel(autoKillConnection) end); autoKillConnection = nil end
        if autoFarm2Loop then pcall(function() task.cancel(autoFarm2Loop) end); autoFarm2Loop = nil end
        State.noclip = false
    end
end, function(popup)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 18)
    lbl.Position = UDim2.new(0, 6, 0, 30)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = C.text
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Code
    lbl.Text = "Mode: " .. State.farmMode
    lbl.ZIndex = 11
    lbl.Parent = popup

    local btnMode = Instance.new("TextButton")
    btnMode.Size = UDim2.new(1, -12, 0, 22)
    btnMode.Position = UDim2.new(0, 6, 0, 52)
    btnMode.BackgroundColor3 = C.panel
    btnMode.TextColor3 = C.accent
    btnMode.TextSize = 10
    btnMode.Font = Enum.Font.Code
    btnMode.Text = "Switch Method"
    btnMode.ZIndex = 11
    btnMode.Parent = popup
    Instance.new("UICorner", btnMode).CornerRadius = UDim.new(0, 3)

    btnMode.MouseButton1Click:Connect(function()
        if State.farmMode == "Method 1" then
            State.farmMode = "Method 2"
        else
            State.farmMode = "Method 1"
        end
        lbl.Text = "Mode: " .. State.farmMode
    end)

    -- Tween Speed слайдер
    local speedMin, speedMax = 50, 2000

    local speedLbl = Instance.new("TextLabel")
    speedLbl.Size = UDim2.new(1, -12, 0, 18)
    speedLbl.Position = UDim2.new(0, 6, 0, 84)
    speedLbl.BackgroundTransparency = 1
    speedLbl.TextColor3 = C.text
    speedLbl.TextSize = 10
    speedLbl.Font = Enum.Font.Code
    speedLbl.Text = "Tween Speed: " .. State.farmSpeed
    speedLbl.ZIndex = 11
    speedLbl.Parent = popup

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -12, 0, 8)
    sliderBg.Position = UDim2.new(0, 6, 0, 106)
    sliderBg.BackgroundColor3 = C.panel
    sliderBg.BorderSizePixel = 0
    sliderBg.ZIndex = 11
    sliderBg.Parent = popup
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((State.farmSpeed - speedMin) / (speedMax - speedMin), 0, 1, 0)
    sliderFill.BackgroundColor3 = C.accent
    sliderFill.BorderSizePixel = 0
    sliderFill.ZIndex = 12
    sliderFill.Parent = sliderBg
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

    local sliderKnob = Instance.new("Frame")
    sliderKnob.Size = UDim2.new(0, 12, 0, 12)
    sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    sliderKnob.Position = UDim2.new((State.farmSpeed - speedMin) / (speedMax - speedMin), 0, 0.5, 0)
    sliderKnob.BackgroundColor3 = C.accent2
    sliderKnob.BorderSizePixel = 0
    sliderKnob.ZIndex = 13
    sliderKnob.Parent = sliderBg
    Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

    local slidingAF = false
    sliderBg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            slidingAF = true
        end
    end)
    sliderBg.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            slidingAF = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if slidingAF and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local absPos  = sliderBg.AbsolutePosition.X
            local absSize = sliderBg.AbsoluteSize.X
            local rel = math.clamp((inp.Position.X - absPos) / absSize, 0, 1)
            State.farmSpeed = math.floor(speedMin + rel * (speedMax - speedMin))
            sliderFill.Size = UDim2.new(rel, 0, 1, 0)
            sliderKnob.Position = UDim2.new(rel, 0, 0.5, 0)
            speedLbl.Text = "Tween Speed: " .. State.farmSpeed
        end
    end)

    -- Kill Delay слайдер (Auto Farm)
    local killDelayMin, killDelayMax = 5, 60

    local killDelayLbl = Instance.new("TextLabel")
    killDelayLbl.Size = UDim2.new(1, -12, 0, 18)
    killDelayLbl.Position = UDim2.new(0, 6, 0, 124)
    killDelayLbl.BackgroundTransparency = 1
    killDelayLbl.TextColor3 = C.text
    killDelayLbl.TextSize = 10
    killDelayLbl.Font = Enum.Font.Code
    killDelayLbl.Text = "Kill Delay: " .. State.killDelay .. "s"
    killDelayLbl.ZIndex = 11
    killDelayLbl.Parent = popup

    local kdSliderBg = Instance.new("Frame")
    kdSliderBg.Size = UDim2.new(1, -12, 0, 8)
    kdSliderBg.Position = UDim2.new(0, 6, 0, 146)
    kdSliderBg.BackgroundColor3 = C.panel
    kdSliderBg.BorderSizePixel = 0
    kdSliderBg.ZIndex = 11
    kdSliderBg.Parent = popup
    Instance.new("UICorner", kdSliderBg).CornerRadius = UDim.new(1, 0)

    local kdSliderFill = Instance.new("Frame")
    kdSliderFill.Size = UDim2.new((State.killDelay - killDelayMin) / (killDelayMax - killDelayMin), 0, 1, 0)
    kdSliderFill.BackgroundColor3 = C.accent
    kdSliderFill.BorderSizePixel = 0
    kdSliderFill.ZIndex = 12
    kdSliderFill.Parent = kdSliderBg
    Instance.new("UICorner", kdSliderFill).CornerRadius = UDim.new(1, 0)

    local kdSliderKnob = Instance.new("Frame")
    kdSliderKnob.Size = UDim2.new(0, 12, 0, 12)
    kdSliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    kdSliderKnob.Position = UDim2.new((State.killDelay - killDelayMin) / (killDelayMax - killDelayMin), 0, 0.5, 0)
    kdSliderKnob.BackgroundColor3 = C.accent2
    kdSliderKnob.BorderSizePixel = 0
    kdSliderKnob.ZIndex = 13
    kdSliderKnob.Parent = kdSliderBg
    Instance.new("UICorner", kdSliderKnob).CornerRadius = UDim.new(1, 0)

    local kdSlidingAF = false
    kdSliderBg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then kdSlidingAF = true end
    end)
    kdSliderBg.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then kdSlidingAF = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if kdSlidingAF and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local absPos  = kdSliderBg.AbsolutePosition.X
            local absSize = kdSliderBg.AbsoluteSize.X
            local rel = math.clamp((inp.Position.X - absPos) / absSize, 0, 1)
            State.killDelay = math.floor(killDelayMin + rel * (killDelayMax - killDelayMin))
            kdSliderFill.Size = UDim2.new(rel, 0, 1, 0)
            kdSliderKnob.Position = UDim2.new(rel, 0, 0.5, 0)
            killDelayLbl.Text = "Kill Delay: " .. State.killDelay .. "s"
        end
    end)

    local afHint = Instance.new("TextLabel")
    afHint.Size = UDim2.new(1, -12, 0, 38)
    afHint.Position = UDim2.new(0, 6, 0, 168)
    afHint.BackgroundTransparency = 1
    afHint.TextColor3 = C.muted
    afHint.TextSize = 9
    afHint.Font = Enum.Font.Code
    afHint.Text = "💡 Method 1: tween through stages.\nMethod 2: instant teleport.\nKill Delay: time before force-kill."
    afHint.TextWrapped = true
    afHint.TextXAlignment = Enum.TextXAlignment.Left
    afHint.ZIndex = 11
    afHint.Parent = popup

    popup.Size = UDim2.new(0, 240, 0, 215)
end)

-- Новый отдельный Ultra Farm (Фарм + Анти-кик + Буст FPS)
createModule(colPlayer, "Ultra Farm", function(on)
    State.ultrafarm = on
    if on then
        applyFpsBoost(true)
        startAntiKick()
        if State.farmMode == "Method 1" then
            if player.Character then task.spawn(function() runUltraSingleCycle(player.Character) end) end
            task.delay(1, function() if State.ultrafarm then startUltraKillLoop() end end)
        else
            startUltraFarm2Loop()
        end
    else
        applyFpsBoost(false)
        if antiKickConnection then pcall(function() task.cancel(antiKickConnection) end); antiKickConnection = nil end
        if currentTween then currentTween:Cancel() end
        if ultraKillConnection then pcall(function() task.cancel(ultraKillConnection) end); ultraKillConnection = nil end
        if ultraFarm2Loop then pcall(function() task.cancel(ultraFarm2Loop) end); ultraFarm2Loop = nil end
        State.noclip = false
    end
end, function(popup)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 18)
    lbl.Position = UDim2.new(0, 6, 0, 30)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = C.text
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Code
    lbl.Text = "Mode: " .. State.farmMode
    lbl.ZIndex = 11
    lbl.Parent = popup

    local btnMode = Instance.new("TextButton")
    btnMode.Size = UDim2.new(1, -12, 0, 22)
    btnMode.Position = UDim2.new(0, 6, 0, 52)
    btnMode.BackgroundColor3 = C.panel
    btnMode.TextColor3 = C.accent
    btnMode.TextSize = 10
    btnMode.Font = Enum.Font.Code
    btnMode.Text = "Switch Method"
    btnMode.ZIndex = 11
    btnMode.Parent = popup
    Instance.new("UICorner", btnMode).CornerRadius = UDim.new(0, 3)

    btnMode.MouseButton1Click:Connect(function()
        if State.farmMode == "Method 1" then
            State.farmMode = "Method 2"
        else
            State.farmMode = "Method 1"
        end
        lbl.Text = "Mode: " .. State.farmMode
    end)

    -- Tween Speed слайдер (Ultra Farm)
    local speedMinU, speedMaxU = 50, 2000

    local speedLblU = Instance.new("TextLabel")
    speedLblU.Size = UDim2.new(1, -12, 0, 18)
    speedLblU.Position = UDim2.new(0, 6, 0, 84)
    speedLblU.BackgroundTransparency = 1
    speedLblU.TextColor3 = C.text
    speedLblU.TextSize = 10
    speedLblU.Font = Enum.Font.Code
    speedLblU.Text = "Tween Speed: " .. State.farmSpeed
    speedLblU.ZIndex = 11
    speedLblU.Parent = popup

    local sliderBgU = Instance.new("Frame")
    sliderBgU.Size = UDim2.new(1, -12, 0, 8)
    sliderBgU.Position = UDim2.new(0, 6, 0, 106)
    sliderBgU.BackgroundColor3 = C.panel
    sliderBgU.BorderSizePixel = 0
    sliderBgU.ZIndex = 11
    sliderBgU.Parent = popup
    Instance.new("UICorner", sliderBgU).CornerRadius = UDim.new(1, 0)

    local sliderFillU = Instance.new("Frame")
    sliderFillU.Size = UDim2.new((State.farmSpeed - speedMinU) / (speedMaxU - speedMinU), 0, 1, 0)
    sliderFillU.BackgroundColor3 = C.accent
    sliderFillU.BorderSizePixel = 0
    sliderFillU.ZIndex = 12
    sliderFillU.Parent = sliderBgU
    Instance.new("UICorner", sliderFillU).CornerRadius = UDim.new(1, 0)

    local sliderKnobU = Instance.new("Frame")
    sliderKnobU.Size = UDim2.new(0, 12, 0, 12)
    sliderKnobU.AnchorPoint = Vector2.new(0.5, 0.5)
    sliderKnobU.Position = UDim2.new((State.farmSpeed - speedMinU) / (speedMaxU - speedMinU), 0, 0.5, 0)
    sliderKnobU.BackgroundColor3 = C.accent2
    sliderKnobU.BorderSizePixel = 0
    sliderKnobU.ZIndex = 13
    sliderKnobU.Parent = sliderBgU
    Instance.new("UICorner", sliderKnobU).CornerRadius = UDim.new(1, 0)

    local slidingUF = false
    sliderBgU.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            slidingUF = true
        end
    end)
    sliderBgU.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            slidingUF = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if slidingUF and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local absPos  = sliderBgU.AbsolutePosition.X
            local absSize = sliderBgU.AbsoluteSize.X
            local rel = math.clamp((inp.Position.X - absPos) / absSize, 0, 1)
            State.farmSpeed = math.floor(speedMinU + rel * (speedMaxU - speedMinU))
            sliderFillU.Size = UDim2.new(rel, 0, 1, 0)
            sliderKnobU.Position = UDim2.new(rel, 0, 0.5, 0)
            speedLblU.Text = "Tween Speed: " .. State.farmSpeed
        end
    end)

    -- Kill Delay слайдер (Ultra Farm)
    local killDelayMinU, killDelayMaxU = 5, 60

    local killDelayLblU = Instance.new("TextLabel")
    killDelayLblU.Size = UDim2.new(1, -12, 0, 18)
    killDelayLblU.Position = UDim2.new(0, 6, 0, 124)
    killDelayLblU.BackgroundTransparency = 1
    killDelayLblU.TextColor3 = C.text
    killDelayLblU.TextSize = 10
    killDelayLblU.Font = Enum.Font.Code
    killDelayLblU.Text = "Kill Delay: " .. State.killDelay .. "s"
    killDelayLblU.ZIndex = 11
    killDelayLblU.Parent = popup

    local kdSliderBgU = Instance.new("Frame")
    kdSliderBgU.Size = UDim2.new(1, -12, 0, 8)
    kdSliderBgU.Position = UDim2.new(0, 6, 0, 146)
    kdSliderBgU.BackgroundColor3 = C.panel
    kdSliderBgU.BorderSizePixel = 0
    kdSliderBgU.ZIndex = 11
    kdSliderBgU.Parent = popup
    Instance.new("UICorner", kdSliderBgU).CornerRadius = UDim.new(1, 0)

    local kdSliderFillU = Instance.new("Frame")
    kdSliderFillU.Size = UDim2.new((State.killDelay - killDelayMinU) / (killDelayMaxU - killDelayMinU), 0, 1, 0)
    kdSliderFillU.BackgroundColor3 = C.accent
    kdSliderFillU.BorderSizePixel = 0
    kdSliderFillU.ZIndex = 12
    kdSliderFillU.Parent = kdSliderBgU
    Instance.new("UICorner", kdSliderFillU).CornerRadius = UDim.new(1, 0)

    local kdSliderKnobU = Instance.new("Frame")
    kdSliderKnobU.Size = UDim2.new(0, 12, 0, 12)
    kdSliderKnobU.AnchorPoint = Vector2.new(0.5, 0.5)
    kdSliderKnobU.Position = UDim2.new((State.killDelay - killDelayMinU) / (killDelayMaxU - killDelayMinU), 0, 0.5, 0)
    kdSliderKnobU.BackgroundColor3 = C.accent2
    kdSliderKnobU.BorderSizePixel = 0
    kdSliderKnobU.ZIndex = 13
    kdSliderKnobU.Parent = kdSliderBgU
    Instance.new("UICorner", kdSliderKnobU).CornerRadius = UDim.new(1, 0)

    local kdSlidingUF = false
    kdSliderBgU.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then kdSlidingUF = true end
    end)
    kdSliderBgU.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then kdSlidingUF = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if kdSlidingUF and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local absPos  = kdSliderBgU.AbsolutePosition.X
            local absSize = kdSliderBgU.AbsoluteSize.X
            local rel = math.clamp((inp.Position.X - absPos) / absSize, 0, 1)
            State.killDelay = math.floor(killDelayMinU + rel * (killDelayMaxU - killDelayMinU))
            kdSliderFillU.Size = UDim2.new(rel, 0, 1, 0)
            kdSliderKnobU.Position = UDim2.new(rel, 0, 0.5, 0)
            killDelayLblU.Text = "Kill Delay: " .. State.killDelay .. "s"
        end
    end)

    local ufHint = Instance.new("TextLabel")
    ufHint.Size = UDim2.new(1, -12, 0, 44)
    ufHint.Position = UDim2.new(0, 6, 0, 168)
    ufHint.BackgroundTransparency = 1
    ufHint.TextColor3 = C.muted
    ufHint.TextSize = 9
    ufHint.Font = Enum.Font.Code
    ufHint.Text = "💡 Ultra Farm includes FPS boost\n& anti-kick. Method 1: tween.\nMethod 2: instant teleport."
    ufHint.TextWrapped = true
    ufHint.TextXAlignment = Enum.TextXAlignment.Left
    ufHint.ZIndex = 11
    ufHint.Parent = popup

    popup.Size = UDim2.new(0, 240, 0, 220)
end)

createModule(colPlayer, "Speed Boost", function(on)
    State.speed = on
    if not on and humanoid then humanoid.WalkSpeed = 16 end
end, function(popup)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 18)
    lbl.Position = UDim2.new(0, 6, 0, 30)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = C.text
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Code
    lbl.Text = "WalkSpeed: " .. State.walkSpeed
    lbl.ZIndex = 11
    lbl.Parent = popup

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -12, 0, 22)
    box.Position = UDim2.new(0, 6, 0, 52)
    box.BackgroundColor3 = C.panel
    box.TextColor3 = C.text
    box.TextSize = 10
    box.Font = Enum.Font.Code
    box.Text = tostring(State.walkSpeed)
    box.ZIndex = 11
    box.Parent = popup
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)

    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then
            State.walkSpeed = val
            lbl.Text = "WalkSpeed: " .. State.walkSpeed
        end
    end)

    local speedHint = Instance.new("TextLabel")
    speedHint.Size = UDim2.new(1, -12, 0, 28)
    speedHint.Position = UDim2.new(0, 6, 0, 80)
    speedHint.BackgroundTransparency = 1
    speedHint.TextColor3 = C.muted
    speedHint.TextSize = 9
    speedHint.Font = Enum.Font.Code
    speedHint.Text = "💡 Default: 16. Type value & press Enter.\nHigh values may look unnatural."
    speedHint.TextWrapped = true
    speedHint.TextXAlignment = Enum.TextXAlignment.Left
    speedHint.ZIndex = 11
    speedHint.Parent = popup

    popup.Size = UDim2.new(0, 240, 0, 115)
end)

createModule(colPlayer, "Jump Power", function(on)
    State.jump = on
    if not on and humanoid then humanoid.JumpPower = 50 end
end, function(popup)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 18)
    lbl.Position = UDim2.new(0, 6, 0, 30)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = C.text
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Code
    lbl.Text = "JumpPower: " .. State.jumpPower
    lbl.ZIndex = 11
    lbl.Parent = popup

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -12, 0, 22)
    box.Position = UDim2.new(0, 6, 0, 52)
    box.BackgroundColor3 = C.panel
    box.TextColor3 = C.text
    box.TextSize = 10
    box.Font = Enum.Font.Code
    box.Text = tostring(State.jumpPower)
    box.ZIndex = 11
    box.Parent = popup
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)

    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then
            State.jumpPower = val
            lbl.Text = "JumpPower: " .. State.jumpPower
        end
    end)

    local jumpHint = Instance.new("TextLabel")
    jumpHint.Size = UDim2.new(1, -12, 0, 28)
    jumpHint.Position = UDim2.new(0, 6, 0, 80)
    jumpHint.BackgroundTransparency = 1
    jumpHint.TextColor3 = C.muted
    jumpHint.TextSize = 9
    jumpHint.Font = Enum.Font.Code
    jumpHint.Text = "💡 Default: 50. Type value & press Enter.\nPair with Infinite Jump for best results."
    jumpHint.TextWrapped = true
    jumpHint.TextXAlignment = Enum.TextXAlignment.Left
    jumpHint.ZIndex = 11
    jumpHint.Parent = popup

    popup.Size = UDim2.new(0, 240, 0, 115)
end)

createModule(colPlayer, "Invisible", function(on)
    State.invisible = on
    if character then
        for _, p in ipairs(character:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                if p.Name ~= "HumanoidRootPart" then
                    p.LocalTransparencyModifier = State.invisible and 1 or 0
                end
            elseif p:IsA("Accessory") or p:IsA("Clothing") then
                local handle = p:FindFirstChild("Handle")
                if handle then
                    handle.LocalTransparencyModifier = State.invisible and 1 or 0
                end
            end
        end
    end
end)

local function enableFly()
    if not rootPart or not humanoid then return end
    if bv then bv:Destroy() end
    if bg then bg:Destroy() end
    if connection then connection:Disconnect() end
    
    bv = Instance.new("BodyVelocity")
    bv.Name = "NeptuneFlyVel"
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(300000, 300000, 300000)
    bv.Parent = rootPart
    
    bg = Instance.new("BodyGyro")
    bg.Name = "NeptuneFlyGyro"
    bg.MaxTorque = Vector3.new(300000, 300000, 300000)
    bg.P = 20000
    bg.CFrame = rootPart.CFrame
    bg.Parent = rootPart
    
    humanoid.PlatformStand = true
    
    connection = RunService.RenderStepped:Connect(function()
        if not State.fly or State.autofarm or State.ultrafarm or not rootPart or not bv or not bg then return end
        local camCF = camera.CFrame
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W)            then dir += camCF.LookVector        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)            then dir -= camCF.LookVector        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)            then dir -= camCF.RightVector       end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)            then dir += camCF.RightVector       end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)        then dir += Vector3.new(0, 1, 0)    end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)  then dir -= Vector3.new(0, 1, 0)    end
        
        if dir.Magnitude > 0 then
            bv.Velocity = dir.Unit * State.flySpeed
        else
            bv.Velocity = Vector3.new(0, 0.1, 0)
        end
        bg.CFrame = camCF
    end)
end

local function disableFly()
    if connection then connection:Disconnect(); connection = nil end
    if bv then bv:Destroy(); bv = nil end
    if bg then bg:Destroy(); bg = nil end
    if humanoid then humanoid.PlatformStand = false end
    pcall(function() if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end end)
end

-- Таблица Drawing-объектов для трассеров (по имени игрока)
local espTracerDrawings = {}

-- Чистим трассер сразу когда игрок выходит
Players.PlayerRemoving:Connect(function(leavingPlayer)
    local name = leavingPlayer.Name
    if espTracerDrawings[name] then
        pcall(function() espTracerDrawings[name]:Remove() end)
        espTracerDrawings[name] = nil
    end
end)

createModule(colMovement, "Flight", function(on)
    State.fly = on
    if State.fly then enableFly() else disableFly() end
end, function(popup)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 18)
    lbl.Position = UDim2.new(0, 6, 0, 30)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = C.text
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Code
    lbl.Text = "Speed: " .. State.flySpeed
    lbl.ZIndex = 11
    lbl.Parent = popup

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -12, 0, 22)
    box.Position = UDim2.new(0, 6, 0, 52)
    box.BackgroundColor3 = C.panel
    box.TextColor3 = C.text
    box.TextSize = 10
    box.Font = Enum.Font.Code
    box.Text = tostring(State.flySpeed)
    box.ZIndex = 11
    box.Parent = popup
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)

    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then
            State.flySpeed = val
            lbl.Text = "Speed: " .. State.flySpeed
        end
    end)

    local flyHint = Instance.new("TextLabel")
    flyHint.Size = UDim2.new(1, -12, 0, 38)
    flyHint.Position = UDim2.new(0, 6, 0, 80)
    flyHint.BackgroundTransparency = 1
    flyHint.TextColor3 = C.muted
    flyHint.TextSize = 9
    flyHint.Font = Enum.Font.Code
    flyHint.Text = "💡 WASD to fly. Space = up, Ctrl = down.\nDefault speed: 80. Type & press Enter\nto apply new speed."
    flyHint.TextWrapped = true
    flyHint.TextXAlignment = Enum.TextXAlignment.Left
    flyHint.ZIndex = 11
    flyHint.Parent = popup

    popup.Size = UDim2.new(0, 240, 0, 125)
end)

createModule(colMovement, "Noclip", function(on) State.noclip = on end)
createModule(colMovement, "Infinite Jump", function(on) State.infjump = on end)
createModule(colMovement, "Bunny Hop", function(on) State.bhop = on end)
createModule(colMovement, "Click TP (Ctrl+Click)", function(on) State.clicktp = on end)

createModule(colMisc, "World Shaders", function(on)
    State.shaders = on
    if on then
        if not customColorCorrection or not customColorCorrection.Parent then
            customColorCorrection = Instance.new("ColorCorrectionEffect")
            customColorCorrection.Name = "NeptuneShaderCC"
            customColorCorrection.Parent = Lighting
        end
        customColorCorrection.TintColor = State.shaderTint
        customColorCorrection.Saturation = State.saturation
        customColorCorrection.Contrast = State.contrast

        if not customAtmosphere or not customAtmosphere.Parent then
            customAtmosphere = Instance.new("Atmosphere")
            customAtmosphere.Name = "NeptuneShaderAtmo"
            customAtmosphere.Parent = Lighting
        end
        customAtmosphere.Density = State.fogDensity
        customAtmosphere.Color = State.fogColor
    else
        if customColorCorrection then customColorCorrection:Destroy(); customColorCorrection = nil end
        if customAtmosphere then customAtmosphere:Destroy(); customAtmosphere = nil end
    end
end, function(popup)
    local ScrollShaders = Instance.new("ScrollingFrame")
    ScrollShaders.Size = UDim2.new(1, -8, 1, -30)
    ScrollShaders.Position = UDim2.new(0, 4, 0, 26)
    ScrollShaders.BackgroundTransparency = 1
    ScrollShaders.BorderSizePixel = 0
    ScrollShaders.ScrollBarThickness = 3
    ScrollShaders.ScrollBarImageColor3 = C.accent
    ScrollShaders.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollShaders.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScrollShaders.ZIndex = 11
    ScrollShaders.Parent = popup

    local Grid = Instance.new("UIGridLayout")
    Grid.CellSize = UDim2.new(0, 108, 0, 22)
    Grid.CellPadding = UDim2.new(0, 4, 0, 4)
    Grid.SortOrder = Enum.SortOrder.LayoutOrder
    Grid.Parent = ScrollShaders

    local function applyPreset(tint, fColor, density, sat, contrast)
        State.shaderTint = tint
        State.fogColor = fColor
        State.fogDensity = density
        State.saturation = sat
        State.contrast = contrast
        
        if shaderButtonReference and not shaderButtonReference.Get() then
            shaderButtonReference.Set(true)
        else
            if customColorCorrection then 
                customColorCorrection.TintColor = tint 
                customColorCorrection.Saturation = sat
                customColorCorrection.Contrast = contrast
            end
            if customAtmosphere then 
                customAtmosphere.Color = fColor
                customAtmosphere.Density = density
            end
        end
    end

    local shadersList = {
        {"Sunset Glow",     Color3.fromRGB(255, 180, 130), Color3.fromRGB(200, 120, 100), 0.08,  0.4,  0.1},
        {"Cyberpunk Neon",  Color3.fromRGB(150, 220, 255), Color3.fromRGB(80, 50, 150),   0.1,   0.6,  0.3},
        {"Matrix Green",    Color3.fromRGB(120, 255, 150), Color3.fromRGB(20, 80, 40),    0.12,  0.5,  0.2},
        {"Deep Ocean",      Color3.fromRGB(130, 180, 255), Color3.fromRGB(10, 30, 70),    0.15,  0.2,  0.1},
        {"Blood Moon",      Color3.fromRGB(255, 100, 100), Color3.fromRGB(90, 20, 20),    0.14,  0.5,  0.4},
        {"Gold Hour",       Color3.fromRGB(255, 230, 150), Color3.fromRGB(150, 120, 50),  0.05,  0.4,  0.1},
        {"Arctic Frost",    Color3.fromRGB(220, 240, 255), Color3.fromRGB(180, 200, 220), 0.06, -0.1,  0.1},
        {"Vaporwave",       Color3.fromRGB(255, 150, 220), Color3.fromRGB(120, 40, 140),  0.09,  0.5,  0.2},
        {"Toxic Wasteland", Color3.fromRGB(180, 255, 100), Color3.fromRGB(50, 80, 20),    0.11,  0.4,  0.3},
        {"Monochrome Noir", Color3.fromRGB(200, 200, 200), Color3.fromRGB(50, 50, 50),    0.08, -1.0,  0.4},
        {"Retro 90s",       Color3.fromRGB(240, 220, 180), Color3.fromRGB(100, 90, 70),   0.04,  0.2, -0.1},
        {"Solar Flare",     Color3.fromRGB(255, 130, 50),  Color3.fromRGB(180, 70, 10),   0.1,   0.7,  0.3},
        {"Abyss Dark",      Color3.fromRGB(80, 90, 120),   Color3.fromRGB(10, 10, 15),    0.2,  -0.4,  0.5},
        {"Cherry Blossom",  Color3.fromRGB(255, 200, 220), Color3.fromRGB(160, 100, 120), 0.05,  0.3,  0.0},
        {"Coffee Vintage",  Color3.fromRGB(220, 190, 150), Color3.fromRGB(90, 70, 50),    0.07, -0.2,  0.2},
        {"Royal Purple",    Color3.fromRGB(200, 150, 255), Color3.fromRGB(70, 30, 100),   0.09,  0.4,  0.2},
        {"Neon Arcade",     Color3.fromRGB(255, 50, 200),  Color3.fromRGB(50, 10, 80),    0.13,  0.8,  0.5},
        {"Moody Forest",    Color3.fromRGB(150, 180, 150), Color3.fromRGB(40, 60, 40),    0.12,  0.1,  0.1},
        {"Mars Dust",       Color3.fromRGB(255, 160, 120), Color3.fromRGB(120, 50, 30),   0.15,  0.3,  0.3},
        {"Clear Standard",  Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200), 0,     0.0,  0.0}
    }

    local TI_shade = TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for _, data in ipairs(shadersList) do
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = C.panel
        btn.TextColor3 = C.text
        btn.TextSize = 8
        btn.Font = Enum.Font.Code
        btn.Text = data[1]
        btn.ZIndex = 11
        btn.Parent = ScrollShaders
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)

        local tColor, fCol, fDens, sat, con = data[2], data[3], data[4], data[5], data[6]
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TI_shade, {BackgroundColor3 = C.panel2, TextColor3 = C.accent}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TI_shade, {BackgroundColor3 = C.panel, TextColor3 = C.text}):Play()
        end)
        btn.MouseButton1Click:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = C.accent}):Play()
            task.delay(0.15, function()
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = C.panel2}):Play()
            end)
            applyPreset(tColor, fCol, fDens, sat, con)
        end)
    end

    -- Hint at the bottom of the shader scroll
    local shaderHintFrame = Instance.new("Frame")
    shaderHintFrame.Size = UDim2.new(1, 0, 0, 36)
    shaderHintFrame.BackgroundTransparency = 1
    shaderHintFrame.LayoutOrder = 999
    shaderHintFrame.ZIndex = 11
    shaderHintFrame.Parent = ScrollShaders

    local shaderHint = Instance.new("TextLabel")
    shaderHint.Size = UDim2.new(1, -4, 1, 0)
    shaderHint.BackgroundTransparency = 1
    shaderHint.TextColor3 = C.muted
    shaderHint.TextSize = 9
    shaderHint.Font = Enum.Font.Code
    shaderHint.Text = "💡 Click a preset to apply. Enable World\nShaders first. 'Clear Standard' resets."
    shaderHint.TextWrapped = true
    shaderHint.TextXAlignment = Enum.TextXAlignment.Left
    shaderHint.ZIndex = 11
    shaderHint.Parent = shaderHintFrame
end)

-- ==========================================
-- INFINITY ZOOM
-- ==========================================
local infZoomConnection  = nil
local origMaxZoomDist    = nil
local origCameraType     = nil

local function stopInfZoom()
    if infZoomConnection then
        infZoomConnection:Disconnect()
        infZoomConnection = nil
    end
    -- Восстанавливаем оригинальные значения
    pcall(function()
        local lp = Players.LocalPlayer
        if origMaxZoomDist then lp.CameraMaxZoomDistance = origMaxZoomDist end
        if origCameraType  then camera.CameraType = origCameraType end
    end)
    origMaxZoomDist = nil
    origCameraType  = nil
end

local function startInfZoom()
    stopInfZoom()
    pcall(function()
        local lp = Players.LocalPlayer
        origMaxZoomDist = lp.CameraMaxZoomDistance
        origCameraType  = camera.CameraType
        -- Снимаем ограничение отдаления
        lp.CameraMaxZoomDistance = 1e9
    end)
    -- Колесо мыши крутит отдаление напрямую — просто убираем лимит,
    -- движок Roblox сам обрабатывает зум колесом.
    -- Для принудительного контроля через код — двигаем камеру по LookVector
    infZoomConnection = UserInputService.InputChanged:Connect(function(inp)
        if not State.infzoom then return end
        if inp.UserInputType == Enum.UserInputType.MouseWheel then
            -- inp.Position.Z: +1 зум к персонажу, -1 отдалить
            -- При CameraMaxZoomDistance = 1e9 движок уже делает это сам,
            -- но если камера Custom — двигаем вручную
            if camera.CameraType == Enum.CameraType.Custom then return end
            local delta = -inp.Position.Z * State.zoomSpeed
            camera.CFrame = camera.CFrame * CFrame.new(0, 0, delta)
        end
    end)
end

createModule(colMisc, "Infinity Zoom", function(on)
    State.infzoom = on
    if on then
        startInfZoom()
    else
        stopInfZoom()
    end
end, function(popup)
    -- Скорость зума (только для не-Custom камеры)
    local speedLblZ = Instance.new("TextLabel")
    speedLblZ.Size = UDim2.new(1, -12, 0, 18)
    speedLblZ.Position = UDim2.new(0, 6, 0, 30)
    speedLblZ.BackgroundTransparency = 1
    speedLblZ.TextColor3 = C.text
    speedLblZ.TextSize = 10
    speedLblZ.Font = Enum.Font.Code
    speedLblZ.Text = "Scroll Speed: " .. State.zoomSpeed
    speedLblZ.ZIndex = 11
    speedLblZ.Parent = popup

    local spdMin, spdMax = 1, 50
    local spdBg = Instance.new("Frame")
    spdBg.Size = UDim2.new(1, -12, 0, 8)
    spdBg.Position = UDim2.new(0, 6, 0, 52)
    spdBg.BackgroundColor3 = C.panel
    spdBg.BorderSizePixel = 0
    spdBg.ZIndex = 11
    spdBg.Parent = popup
    Instance.new("UICorner", spdBg).CornerRadius = UDim.new(1, 0)

    local spdFill = Instance.new("Frame")
    spdFill.Size = UDim2.new((State.zoomSpeed - spdMin) / (spdMax - spdMin), 0, 1, 0)
    spdFill.BackgroundColor3 = C.accent
    spdFill.BorderSizePixel = 0
    spdFill.ZIndex = 12
    spdFill.Parent = spdBg
    Instance.new("UICorner", spdFill).CornerRadius = UDim.new(1, 0)

    local spdKnob = Instance.new("Frame")
    spdKnob.Size = UDim2.new(0, 12, 0, 12)
    spdKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    spdKnob.Position = UDim2.new((State.zoomSpeed - spdMin) / (spdMax - spdMin), 0, 0.5, 0)
    spdKnob.BackgroundColor3 = C.accent2
    spdKnob.BorderSizePixel = 0
    spdKnob.ZIndex = 13
    spdKnob.Parent = spdBg
    Instance.new("UICorner", spdKnob).CornerRadius = UDim.new(1, 0)

    local slidingSpd = false
    spdBg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then slidingSpd = true end
    end)
    spdBg.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then slidingSpd = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if slidingSpd and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((inp.Position.X - spdBg.AbsolutePosition.X) / spdBg.AbsoluteSize.X, 0, 1)
            State.zoomSpeed = math.floor(spdMin + rel * (spdMax - spdMin))
            spdFill.Size = UDim2.new(rel, 0, 1, 0)
            spdKnob.Position = UDim2.new(rel, 0, 0.5, 0)
            speedLblZ.Text = "Scroll Speed: " .. State.zoomSpeed
        end
    end)

    -- Кнопка сброса зума (приближаем камеру обратно к персонажу)
    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(1, -12, 0, 22)
    resetBtn.Position = UDim2.new(0, 6, 0, 74)
    resetBtn.BackgroundColor3 = C.panel
    resetBtn.TextColor3 = C.accent
    resetBtn.TextSize = 10
    resetBtn.Font = Enum.Font.Code
    resetBtn.Text = "Reset Zoom"
    resetBtn.ZIndex = 11
    resetBtn.Parent = popup
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 3)
    resetBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if rootPart then
                -- Телепортируем камеру обратно за спиной персонажа
                camera.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 5, 12), rootPart.Position)
            end
        end)
    end)

    -- Hint
    local hintLbl = Instance.new("TextLabel")
    hintLbl.Size = UDim2.new(1, -12, 0, 38)
    hintLbl.Position = UDim2.new(0, 6, 0, 102)
    hintLbl.BackgroundTransparency = 1
    hintLbl.TextColor3 = C.muted
    hintLbl.TextSize = 9
    hintLbl.Font = Enum.Font.Code
    hintLbl.Text = "💡 Scroll wheel zooms without limit.\nScroll Speed only affects non-Custom\ncamera mode."
    hintLbl.TextWrapped = true
    hintLbl.ZIndex = 11
    hintLbl.Parent = popup

    popup.Size = UDim2.new(0, 240, 0, 150)
end)

createModule(colMisc, "Server Hop", function(on)
    pcall(function()
        local servers = {}
        local req = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        if req and req.data then
            for _, s in ipairs(req.data) do
                if type(s) == "table" and s.playing < s.maxPlayers and s.id ~= game.JobId then
                    table.insert(servers, s.id)
                end
            end
        end
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], player)
        else
            TeleportService:Teleport(game.PlaceId, player)
        end
    end)
end)

createModule(colMisc, "FOV Changer", function(on)
    State.fov = on
    camera.FieldOfView = State.fov and State.fovVal or 70
end, function(popup)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 18)
    lbl.Position = UDim2.new(0, 6, 0, 30)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = C.text
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Code
    lbl.Text = "FOV Value: " .. State.fovVal
    lbl.ZIndex = 11
    lbl.Parent = popup

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -12, 0, 22)
    box.Position = UDim2.new(0, 6, 0, 52)
    box.BackgroundColor3 = C.panel
    box.TextColor3 = C.text
    box.TextSize = 10
    box.Font = Enum.Font.Code
    box.Text = tostring(State.fovVal)
    box.ZIndex = 11
    box.Parent = popup
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)

    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then
            State.fovVal = val
            lbl.Text = "FOV Value: " .. State.fovVal
            if State.fov then camera.FieldOfView = State.fovVal end
        end
    end)

    local fovHint = Instance.new("TextLabel")
    fovHint.Size = UDim2.new(1, -12, 0, 32)
    fovHint.Position = UDim2.new(0, 6, 0, 80)
    fovHint.BackgroundTransparency = 1
    fovHint.TextColor3 = C.muted
    fovHint.TextSize = 9
    fovHint.Font = Enum.Font.Code
    fovHint.Text = "💡 Default FOV is 70. Higher values\nwiden view (max ~120 recommended)."
    fovHint.TextWrapped = true
    fovHint.TextXAlignment = Enum.TextXAlignment.Left
    fovHint.ZIndex = 11
    fovHint.Parent = popup

    popup.Size = UDim2.new(0, 240, 0, 125)
end)

local function updateEspForPlayer(targetPlayer)
    if targetPlayer == player then return end
    local char = targetPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    local charRoot = char:FindFirstChild("HumanoidRootPart")
    local charHum  = char:FindFirstChildOfClass("Humanoid")
    if not head or not charRoot then return end

    -- ── Чистка при выключении ──────────────────────────────────────────────
    if not State.esp then
        for _, n in ipairs({
            "NeptuneESPBillboard","NeptuneESPHealth",
            "NeptuneESPSkeleton","NeptuneESPHitbox","NeptuneESPHighlight"
        }) do
            local obj = char:FindFirstChild(n)
            if obj then obj:Destroy() end
        end
        -- Drawing tracer
        if espTracerDrawings[targetPlayer.Name] then
            pcall(function() espTracerDrawings[targetPlayer.Name]:Remove() end)
            espTracerDrawings[targetPlayer.Name] = nil
        end
        -- Gold ESP
        local gb = char:FindFirstChild("NeptuneGoldESPBillboard")
        if gb then gb:Destroy() end
        return
    end

    local dist = rootPart and math.floor((rootPart.Position - charRoot.Position).Magnitude) or 0

    -- ── 1. Billboard: имя + дистанция ─────────────────────────────────────
    do
        local bb = char:FindFirstChild("NeptuneESPBillboard")
        if not bb then
            bb = Instance.new("BillboardGui")
            bb.Name = "NeptuneESPBillboard"
            bb.Size = UDim2.new(0, 200, 0, 30)
            bb.StudsOffset = Vector3.new(0, 4.0, 0)
            bb.AlwaysOnTop = true
            local lbl = Instance.new("TextLabel")
            lbl.Name = "ESPText"
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = C.accent
            lbl.TextStrokeTransparency = 0.5
            lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
            lbl.TextSize = 12
            lbl.Font = Enum.Font.Code
            lbl.Parent = bb
            bb.Parent = char
        end
        local lbl = bb:FindFirstChild("ESPText")
        if lbl then
            if State.espMode == "Name" then
                lbl.Text = targetPlayer.Name
            elseif State.espMode == "Distance" then
                lbl.Text = "[" .. dist .. " studs]"
            else
                lbl.Text = targetPlayer.Name .. " [" .. dist .. " studs]"
            end
        end
    end

    -- ── 2. Health ESP ───────────────────────────────────────────────────────
    do
        local bb = char:FindFirstChild("NeptuneESPHealth")
        if State.espHealth then
            if not bb then
                bb = Instance.new("BillboardGui")
                bb.Name = "NeptuneESPHealth"
                bb.Size = UDim2.new(0, 80, 0, 8)
                bb.StudsOffset = Vector3.new(0, 2.6, 0)
                bb.AlwaysOnTop = true
                local bg2 = Instance.new("Frame")
                bg2.Name = "HealthBG"
                bg2.Size = UDim2.new(1, 0, 1, 0)
                bg2.BackgroundColor3 = Color3.fromRGB(40,10,10)
                bg2.BorderSizePixel = 0
                bg2.Parent = bb
                Instance.new("UICorner", bg2).CornerRadius = UDim.new(1,0)
                local fill = Instance.new("Frame")
                fill.Name = "HealthFill"
                fill.Size = UDim2.new(1, 0, 1, 0)
                fill.BackgroundColor3 = Color3.fromRGB(0,220,80)
                fill.BorderSizePixel = 0
                fill.Parent = bg2
                Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
                bb.Parent = char
            end
            local hbg = bb:FindFirstChild("HealthBG")
            local fill = hbg and hbg:FindFirstChild("HealthFill")
            if fill and charHum then
                local pct = math.clamp(charHum.Health / math.max(charHum.MaxHealth, 1), 0, 1)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                local r = math.floor(math.clamp((1-pct)*2, 0, 1)*220)
                local g = math.floor(math.clamp(pct*2, 0, 1)*220)
                fill.BackgroundColor3 = Color3.fromRGB(r, g, 0)
            end
        else
            if bb then bb:Destroy() end
        end
    end

    -- ── 3. Hitbox Expander (SelectionBox по charRoot) ───────────────────────
    do
        local hb = char:FindFirstChild("NeptuneESPHitbox")
        if State.espHitbox then
            if not hb then
                hb = Instance.new("SelectionBox")
                hb.Name = "NeptuneESPHitbox"
                hb.Color3 = Color3.fromRGB(255, 80, 80)
                hb.LineThickness = 0.07
                hb.SurfaceTransparency = 1
                hb.Adornee = charRoot
                hb.Parent = char
            end
            -- Масштабируем через LocalScale если доступен, иначе просто оставляем SelectionBox
            -- (SelectionBox автоматически подстраивается под Adornee.Size)
            -- Попытка сдвинуть размер через CFrame offset не нужна — SelectionBox уже видно сквозь стены
        else
            if hb then hb:Destroy() end
        end
    end

    -- ── 4. Chams сквозь стены — используем Highlight instance ──────────────
    do
        local hl = char:FindFirstChild("NeptuneESPHighlight")
        if State.espChams then
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = "NeptuneESPHighlight"
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillTransparency = State.espChamsTransp
                hl.OutlineTransparency = 0
                hl.FillColor = State.espChamsColor
                hl.OutlineColor = State.espChamsColor
                hl.Adornee = char
                hl.Parent = char
            else
                -- обновляем цвет/прозрачность если изменилось
                hl.FillTransparency = State.espChamsTransp
                hl.FillColor = State.espChamsColor
                hl.OutlineColor = State.espChamsColor
            end
        else
            if hl then hl:Destroy() end
        end
    end

    -- ── 5. Tracers через Drawing API (единственный способ) ─────────────────
    do
        local pname = targetPlayer.Name
        if State.espTracers and rootPart then
            -- создаём Drawing.Line если нет
            if not espTracerDrawings[pname] then
                local ok, line = pcall(function() return Drawing.new("Line") end)
                if ok and line then
                    line.Thickness = 1.5
                    line.Color = Color3.fromRGB(0, 230, 160)
                    line.Transparency = 0.2
                    line.Visible = true
                    espTracerDrawings[pname] = line
                end
            end
            local line = espTracerDrawings[pname]
            if line then
                local cam = Workspace.CurrentCamera
                local vp = cam.ViewportSize
                -- from: центр низа экрана (фиксированная точка, без зеркала)
                local fromScreen = Vector2.new(vp.X / 2, vp.Y)
                -- to: позиция цели в экранных координатах
                local toPos3, toVis = cam:WorldToViewportPoint(charRoot.Position - Vector3.new(0, 3, 0))
                -- скрываем если цель за камерой (Z > 0 означает перед камерой)
                if toVis and toPos3.Z > 0 then
                    line.From    = fromScreen
                    line.To      = Vector2.new(toPos3.X, toPos3.Y)
                    line.Visible = true
                else
                    line.Visible = false
                end
            end
        else
            -- убираем Drawing
            if espTracerDrawings[pname] then
                pcall(function() espTracerDrawings[pname]:Remove() end)
                espTracerDrawings[pname] = nil
            end
        end
    end

    -- ── 6. Skeleton ESP — используем LineHandleAdornment ────────────────────
    do
        local skelFolder = char:FindFirstChild("NeptuneESPSkeleton")
        if State.espSkeleton then
            if not skelFolder then
                skelFolder = Instance.new("Folder")
                skelFolder.Name = "NeptuneESPSkeleton"
                skelFolder.Parent = char

                local bones = {
                    {"Head","UpperTorso"},
                    {"UpperTorso","LowerTorso"},
                    {"UpperTorso","LeftUpperArm"},
                    {"LeftUpperArm","LeftLowerArm"},
                    {"LeftLowerArm","LeftHand"},
                    {"UpperTorso","RightUpperArm"},
                    {"RightUpperArm","RightLowerArm"},
                    {"RightLowerArm","RightHand"},
                    {"LowerTorso","LeftUpperLeg"},
                    {"LeftUpperLeg","LeftLowerLeg"},
                    {"LeftLowerLeg","LeftFoot"},
                    {"LowerTorso","RightUpperLeg"},
                    {"RightUpperLeg","RightLowerLeg"},
                    {"RightLowerLeg","RightFoot"},
                }

                for _, pair in ipairs(bones) do
                    local part1 = char:FindFirstChild(pair[1])
                    local part2 = char:FindFirstChild(pair[2])
                    if part1 and part2 then
                        -- LineHandleAdornment рисует линию между двумя точками
                        local lha = Instance.new("LineHandleAdornment")
                        lha.Name = pair[1].."_"..pair[2]
                        lha.Color3 = C.accent2
                        lha.Thickness = 3
                        lha.AlwaysOnTop = true
                        lha.ZIndex = 5
                        lha.Length = 0
                        lha.Adornee = part1
                        -- Direction и Length обновим в цикле ниже
                        lha.Parent = skelFolder
                    end
                end
            end

            -- Каждый кадр обновляем direction/length
            for _, lha in ipairs(skelFolder:GetChildren()) do
                if lha:IsA("LineHandleAdornment") then
                    local names = string.split(lha.Name, "_")
                    local p1 = char:FindFirstChild(names[1])
                    local p2 = char:FindFirstChild(names[2])
                    if p1 and p2 then
                        local dir = p2.Position - p1.Position
                        lha.Length = dir.Magnitude
                        lha.CFrame = CFrame.new(Vector3.zero, dir.Unit)
                    end
                end
            end
        else
            if skelFolder then skelFolder:Destroy() end
        end
    end
end

createModule(colMisc, "Player ESP", function(on)
    State.esp = on
    if not on then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                for _, n in ipairs({
                    "NeptuneESPBillboard","NeptuneESPHealth","NeptuneESPTracer",
                    "NeptuneESPSkeleton","NeptuneESPHitbox","NeptuneESPChams"
                }) do
                    local obj = p.Character:FindFirstChild(n)
                    if obj then obj:Destroy() end
                    -- tracers живут в ScreenGui
                    local tr = ScreenGui:FindFirstChild("NeptuneESPTracer_" .. p.Name)
                    if tr then tr:Destroy() end
                end
                -- убираем chams из деталей
                for _, part in ipairs(p.Character:GetDescendants()) do
                    local hl = part:FindFirstChild("NeptuneESPChams")
                    if hl then hl:Destroy() end
                end
            end
        end
    end
end, function(popup)
    -- popup будет скроллиться
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -4, 1, -30)
    scroll.Position = UDim2.new(0, 2, 0, 28)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = C.accent
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ZIndex = 11
    scroll.Parent = popup
    local listL = Instance.new("UIListLayout")
    listL.SortOrder = Enum.SortOrder.LayoutOrder
    listL.Padding = UDim.new(0,4)
    listL.Parent = scroll

    popup.Size = UDim2.new(0, 240, 0, 420)

    local function addLabel(text, order)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -8, 0, 16)
        l.BackgroundTransparency = 1
        l.TextColor3 = C.muted
        l.TextSize = 9
        l.Font = Enum.Font.Code
        l.Text = text
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.LayoutOrder = order
        l.ZIndex = 11
        l.Parent = scroll
        return l
    end

    local function addToggle(text, stateKey, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 22)
        btn.BackgroundColor3 = State[stateKey] and C.accent or C.panel
        btn.TextColor3 = State[stateKey] and C.bg or C.accent
        btn.TextSize = 10
        btn.Font = Enum.Font.Code
        btn.Text = text .. ": " .. (State[stateKey] and "ON" or "OFF")
        btn.LayoutOrder = order
        btn.ZIndex = 11
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,3)
        local TI_t = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        btn.MouseEnter:Connect(function()
            if not State[stateKey] then
                TweenService:Create(btn, TI_t, {BackgroundColor3 = Color3.fromRGB(45, 65, 55)}):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if not State[stateKey] then
                TweenService:Create(btn, TI_t, {BackgroundColor3 = C.panel}):Play()
            end
        end)
        btn.MouseButton1Click:Connect(function()
            State[stateKey] = not State[stateKey]
            TweenService:Create(btn, TI_t, {
                BackgroundColor3 = State[stateKey] and C.accent or C.panel,
                TextColor3       = State[stateKey] and C.bg    or C.accent,
            }):Play()
            btn.Text = text .. ": " .. (State[stateKey] and "ON" or "OFF")
        end)
        return btn
    end

    local function addSlider(labelPrefix, stateKey, minV, maxV, order)
        local lbl = addLabel(labelPrefix .. ": " .. State[stateKey], order)
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, -8, 0, 8)
        bg.BackgroundColor3 = C.panel
        bg.BorderSizePixel = 0
        bg.LayoutOrder = order + 1
        bg.ZIndex = 11
        bg.Parent = scroll
        Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((State[stateKey]-minV)/(maxV-minV), 0, 1, 0)
        fill.BackgroundColor3 = C.accent
        fill.BorderSizePixel = 0
        fill.ZIndex = 12
        fill.Parent = bg
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0,10,0,10)
        knob.AnchorPoint = Vector2.new(0.5,0.5)
        knob.Position = UDim2.new((State[stateKey]-minV)/(maxV-minV),0,0.5,0)
        knob.BackgroundColor3 = C.accent2
        knob.BorderSizePixel = 0
        knob.ZIndex = 13
        knob.Parent = bg
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
        local sliding = false
        bg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding=true end end)
        bg.InputEnded:Connect(function(i)  if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding=false end end)
        UserInputService.InputChanged:Connect(function(i)
            if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = math.clamp((i.Position.X - bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)
                local val = minV + rel*(maxV-minV)
                -- round to 1 decimal
                val = math.floor(val*10+0.5)/10
                State[stateKey] = val
                fill.Size = UDim2.new(rel,0,1,0)
                knob.Position = UDim2.new(rel,0,0.5,0)
                lbl.Text = labelPrefix .. ": " .. State[stateKey]
            end
        end)
    end

    -- ── Секция: базовый текстовый ESP ──
    addLabel("── Name / Distance ESP ──", 1)
    local modeLbl = addLabel("Mode: " .. State.espMode, 2)
    local btnMode = Instance.new("TextButton")
    btnMode.Size = UDim2.new(1, -8, 0, 22)
    btnMode.BackgroundColor3 = C.panel
    btnMode.TextColor3 = C.accent
    btnMode.TextSize = 10
    btnMode.Font = Enum.Font.Code
    btnMode.Text = "Toggle Mode (Name/Dist/Both)"
    btnMode.LayoutOrder = 3
    btnMode.ZIndex = 11
    btnMode.Parent = scroll
    Instance.new("UICorner", btnMode).CornerRadius = UDim.new(0,3)
    btnMode.MouseButton1Click:Connect(function()
        if State.espMode == "Both" then State.espMode = "Name"
        elseif State.espMode == "Name" then State.espMode = "Distance"
        else State.espMode = "Both" end
        modeLbl.Text = "Mode: " .. State.espMode
    end)

    -- ── Секция: доп. фичи ──
    addLabel("── Extra Features ──", 10)
    addToggle("Health ESP",      "espHealth",   11)
    addToggle("Chams (WallSee)", "espChams",    12)
    addToggle("Tracers",         "espTracers",  13)
    addToggle("Skeleton ESP",    "espSkeleton", 14)
    addToggle("Hitbox Expander", "espHitbox",   15)

    -- Gold ESP отдельно с cleanup
    local goldBtn = Instance.new("TextButton")
    goldBtn.Size = UDim2.new(1, -8, 0, 22)
    goldBtn.BackgroundColor3 = State.goldesp and C.accent or C.panel
    goldBtn.TextColor3 = State.goldesp and C.bg or C.accent
    goldBtn.TextSize = 10
    goldBtn.Font = Enum.Font.Code
    goldBtn.Text = "Gold ESP: " .. (State.goldesp and "ON" or "OFF")
    goldBtn.LayoutOrder = 16
    goldBtn.ZIndex = 11
    goldBtn.Parent = scroll
    Instance.new("UICorner", goldBtn).CornerRadius = UDim.new(0,3)
    goldBtn.MouseButton1Click:Connect(function()
        State.goldesp = not State.goldesp
        TweenService:Create(goldBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = State.goldesp and C.accent or C.panel,
            TextColor3       = State.goldesp and C.bg    or C.accent,
        }):Play()
        goldBtn.Text = "Gold ESP: " .. (State.goldesp and "ON" or "OFF")
        if not State.goldesp then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    local bb = p.Character:FindFirstChild("NeptuneGoldESPBillboard")
                    if bb then bb:Destroy() end
                end
            end
        end
    end)

    -- ── Секция: настройки Hitbox ──
    addLabel("── Hitbox Size ──", 20)
    addSlider("Size", "espHitboxSize", 1, 6, 21)

    -- ── Секция: настройки Chams прозрачности ──
    addLabel("── Chams Transparency ──", 30)
    addSlider("Opacity", "espChamsTransp", 0, 1, 31)

    -- ── Hints ──
    addLabel("── Tips ──", 40)
    local hintE1 = addLabel("💡 Right-click module to open settings.", 41)
    hintE1.TextColor3 = C.muted
    local hintE2 = addLabel("Chams & Tracers show players thru walls.", 42)
    hintE2.TextColor3 = C.muted
    local hintE3 = addLabel("Gold ESP highlights gold-holding players.", 43)
    hintE3.TextColor3 = C.muted
    local hintE4 = addLabel("Hitbox Expander makes targets easier to hit.", 44)
    hintE4.TextColor3 = C.muted
end)

local function updateGoldEspForPlayer(targetPlayer)
    if targetPlayer == player then return end
    local char = targetPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head") or char:FindFirstChildPrimaryPart()
    if not head then return end

    local billboard = char:FindFirstChild("NeptuneGoldESPBillboard")
    if State.goldesp then
        if not billboard then
            billboard = Instance.new("BillboardGui")
            billboard.Name = "NeptuneGoldESPBillboard"
            billboard.Size = UDim2.new(0, 200, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 5.2, 0)
            billboard.AlwaysOnTop = true
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Name = "GoldESPText"
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
            textLabel.TextStrokeTransparency = 0.5
            textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            textLabel.TextSize = 12
            textLabel.Font = Enum.Font.Code
            textLabel.Parent = billboard
            
            billboard.Parent = char
        end

        local textLbl = billboard:FindFirstChild("GoldESPText")
        if textLbl then
            local goldVal = "0"
            pcall(function()
                goldVal = tostring(targetPlayer.Data.Gold.Value)
            end)
            textLbl.Text = "🪙 " .. goldVal .. " Gold"
        end
    else
        if billboard then billboard:Destroy() end
    end
end

createModule(colMisc, "Rejoin Server", function(on)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end)

-- ==========================================
-- STATS HUD (FPS / PING / COORDS / SPEED)
-- ==========================================
State.statshud   = false
State.hudEditMode = false
State.hudFontSize = 9
State.hudBgAlpha  = 0.18
State.hudRowEnabled = {FPS = true, PING = true, POS = true, SPD = true}

local ROW_H     = 15   -- высота одной строки
local PAD_TOP   = 4    -- отступ сверху
local PAD_SIDES = 6

-- ── Gold Session Tracker ──────────────────────────────────────────────────
local sessionGoldEarned = 0
local sessionStartGold  = nil
local goldConnection    = nil

local function setupGoldTracking()
    pcall(function()
        local data = player:WaitForChild("Data", 5)
        if not data then return end
        local goldVal = data:WaitForChild("Gold", 5)
        if not goldVal then return end
        sessionStartGold = goldVal.Value
        if goldConnection then goldConnection:Disconnect() end
        goldConnection = goldVal:GetPropertyChangedSignal("Value"):Connect(function()
            local diff = goldVal.Value - sessionStartGold
            sessionGoldEarned = math.max(0, diff)
        end)
    end)
end
task.spawn(setupGoldTracking)
player.CharacterAdded:Connect(function() task.delay(2, setupGoldTracking) end)


local StatsHUD = Instance.new("Frame")
StatsHUD.Name                   = "NeptuneStatsHUD"
StatsHUD.Size                   = UDim2.new(0, 168, 0, ROW_H * 4 + PAD_TOP * 2)
StatsHUD.Position               = UDim2.new(0, 12, 0, 12)
StatsHUD.BackgroundColor3       = Color3.fromRGB(12, 16, 14)
StatsHUD.BackgroundTransparency = State.hudBgAlpha
StatsHUD.BorderSizePixel        = 0
StatsHUD.Visible                = false
StatsHUD.ZIndex                 = 20
StatsHUD.Parent                 = ScreenGui
Instance.new("UICorner", StatsHUD).CornerRadius = UDim.new(0, 7)

local HUDStroke = Instance.new("UIStroke")
HUDStroke.Color     = C.accent
HUDStroke.Thickness = 1
HUDStroke.Parent    = StatsHUD

-- Пересчёт высоты под активные строки
local function recalcHUDHeight()
    local visible = 0
    for _, en in pairs(State.hudRowEnabled) do
        if en then visible = visible + 1 end
    end
    -- edit panel: +70 если открыта
    local extra = State.hudEditMode and 72 or 0
    StatsHUD.Size = UDim2.new(0, 168, 0, visible * ROW_H + PAD_TOP * 2 + extra)
end

-- Строки статов
local statLines = {}
local statRows  = {}
local statNames = {"FPS", "PING", "POS", "SPD"}
local statIcons = {"⚡", "📶", "📍", "💨"}

for i, name in ipairs(statNames) do
    local row = Instance.new("Frame")
    row.Name                = "Row_" .. name
    row.Size                = UDim2.new(1, -PAD_SIDES * 2, 0, ROW_H)
    row.BackgroundTransparency = 1
    row.ZIndex              = 21
    row.Parent              = StatsHUD
    statRows[name]          = row

    local icon = Instance.new("TextLabel")
    icon.Size               = UDim2.new(0, 14, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text               = statIcons[i]
    icon.TextSize           = State.hudFontSize
    icon.Font               = Enum.Font.Code
    icon.TextColor3         = C.accent
    icon.ZIndex             = 22
    icon.Parent             = row

    local key = Instance.new("TextLabel")
    key.Name                = "Key"
    key.Size                = UDim2.new(0, 35, 1, 0)
    key.Position            = UDim2.new(0, 14, 0, 0)
    key.BackgroundTransparency = 1
    key.Text                = name
    key.TextSize            = State.hudFontSize
    key.Font                = Enum.Font.Code
    key.TextColor3          = C.muted
    key.TextXAlignment      = Enum.TextXAlignment.Left
    key.ZIndex              = 22
    key.Parent              = row

    local val = Instance.new("TextLabel")
    val.Name                = "Val"
    val.Size                = UDim2.new(1, -50, 1, 0)
    val.Position            = UDim2.new(0, 50, 0, 0)
    val.BackgroundTransparency = 1
    val.Text                = "—"
    val.TextSize            = State.hudFontSize
    val.Font                = Enum.Font.Code
    val.TextColor3          = C.text
    val.TextXAlignment      = Enum.TextXAlignment.Left
    val.ZIndex              = 22
    val.Parent              = row

    statLines[name] = val
end

-- Перераскладка строк по Y (пропускаем скрытые), с учётом текущей высоты HUD
local function relayoutRows()
    local visible = {}
    for _, name in ipairs(statNames) do
        if State.hudRowEnabled[name] then
            table.insert(visible, name)
        else
            statRows[name].Visible = false
        end
    end
    if #visible == 0 then return end

    local hudH   = StatsHUD.AbsoluteSize.Y > 0 and StatsHUD.AbsoluteSize.Y or (ROW_H * #visible + PAD_TOP * 2)
    local usable = hudH - PAD_TOP * 2
    local rowH   = math.floor(usable / #visible)

    for i, name in ipairs(visible) do
        local row = statRows[name]
        row.Visible  = true
        row.Size     = UDim2.new(1, -PAD_SIDES * 2, 0, rowH)
        row.Position = UDim2.new(0, PAD_SIDES, 0, PAD_TOP + (i - 1) * rowH)
    end
end
relayoutRows()

-- ---- EDIT PANEL (появляется внизу HUD при ПКМ) ----
local EditPanel = Instance.new("Frame")
EditPanel.Name                  = "EditPanel"
EditPanel.Size                  = UDim2.new(1, 0, 0, 70)
EditPanel.BackgroundColor3      = Color3.fromRGB(18, 26, 22)
EditPanel.BackgroundTransparency = 0.1
EditPanel.BorderSizePixel       = 0
EditPanel.Visible               = false
EditPanel.ZIndex                = 23
EditPanel.Parent                = StatsHUD
Instance.new("UICorner", EditPanel).CornerRadius = UDim.new(0, 5)

local EPStroke = Instance.new("UIStroke")
EPStroke.Color     = C.border
EPStroke.Thickness = 1
EPStroke.Parent    = EditPanel

local function positionEditPanel()
    local visCount = 0
    for _, en in pairs(State.hudRowEnabled) do if en then visCount += 1 end end
    EditPanel.Position = UDim2.new(0, 0, 0, visCount * ROW_H + PAD_TOP * 2)
end

-- Тогглы строк в edit panel
local toggleBtns = {}
for i, name in ipairs(statNames) do
    local tb = Instance.new("TextButton")
    tb.Size             = UDim2.new(0, 34, 0, 14)
    tb.Position         = UDim2.new(0, 4 + (i-1) * 38, 0, 4)
    tb.BackgroundColor3 = State.hudRowEnabled[name] and C.accent or C.panel
    tb.TextColor3       = State.hudRowEnabled[name] and C.bg or C.muted
    tb.Text             = name
    tb.TextSize         = 8
    tb.Font             = Enum.Font.Code
    tb.BorderSizePixel  = 0
    tb.ZIndex           = 24
    tb.Parent           = EditPanel
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 3)
    toggleBtns[name] = tb

    tb.MouseButton1Click:Connect(function()
        State.hudRowEnabled[name] = not State.hudRowEnabled[name]
        tb.BackgroundColor3 = State.hudRowEnabled[name] and C.accent or C.panel
        tb.TextColor3       = State.hudRowEnabled[name] and C.bg or C.muted
        relayoutRows()
        positionEditPanel()
        recalcHUDHeight()
    end)
end

-- Слайдер размера шрифта
local fsLbl = Instance.new("TextLabel")
fsLbl.Size = UDim2.new(1, -8, 0, 12)
fsLbl.Position = UDim2.new(0, 4, 0, 22)
fsLbl.BackgroundTransparency = 1
fsLbl.Text = "Font: " .. State.hudFontSize
fsLbl.TextSize = 8
fsLbl.Font = Enum.Font.Code
fsLbl.TextColor3 = C.muted
fsLbl.TextXAlignment = Enum.TextXAlignment.Left
fsLbl.ZIndex = 24
fsLbl.Parent = EditPanel

local fsBg = Instance.new("Frame")
fsBg.Size = UDim2.new(1, -8, 0, 6)
fsBg.Position = UDim2.new(0, 4, 0, 36)
fsBg.BackgroundColor3 = C.panel
fsBg.BorderSizePixel = 0
fsBg.ZIndex = 24
fsBg.Parent = EditPanel
Instance.new("UICorner", fsBg).CornerRadius = UDim.new(1, 0)

local fsFill = Instance.new("Frame")
fsFill.Size = UDim2.new((State.hudFontSize - 7) / (16 - 7), 0, 1, 0)
fsFill.BackgroundColor3 = C.accent
fsFill.BorderSizePixel = 0
fsFill.ZIndex = 25
fsFill.Parent = fsBg
Instance.new("UICorner", fsFill).CornerRadius = UDim.new(1, 0)

local fsKnob = Instance.new("Frame")
fsKnob.Size = UDim2.new(0, 10, 0, 10)
fsKnob.AnchorPoint = Vector2.new(0.5, 0.5)
fsKnob.Position = UDim2.new((State.hudFontSize - 7) / (16 - 7), 0, 0.5, 0)
fsKnob.BackgroundColor3 = C.accent2
fsKnob.BorderSizePixel = 0
fsKnob.ZIndex = 26
fsKnob.Parent = fsBg
Instance.new("UICorner", fsKnob).CornerRadius = UDim.new(1, 0)

-- Слайдер прозрачности фона
local bgLbl = Instance.new("TextLabel")
bgLbl.Size = UDim2.new(1, -8, 0, 12)
bgLbl.Position = UDim2.new(0, 4, 0, 46)
bgLbl.BackgroundTransparency = 1
bgLbl.Text = "BG: " .. math.floor((1 - State.hudBgAlpha) * 100) .. "%"
bgLbl.TextSize = 8
bgLbl.Font = Enum.Font.Code
bgLbl.TextColor3 = C.muted
bgLbl.TextXAlignment = Enum.TextXAlignment.Left
bgLbl.ZIndex = 24
bgLbl.Parent = EditPanel

local bgBg = Instance.new("Frame")
bgBg.Size = UDim2.new(1, -8, 0, 6)
bgBg.Position = UDim2.new(0, 4, 0, 60)
bgBg.BackgroundColor3 = C.panel
bgBg.BorderSizePixel = 0
bgBg.ZIndex = 24
bgBg.Parent = EditPanel
Instance.new("UICorner", bgBg).CornerRadius = UDim.new(1, 0)

local bgFill = Instance.new("Frame")
bgFill.Size = UDim2.new(1 - State.hudBgAlpha, 0, 1, 0)
bgFill.BackgroundColor3 = C.accent
bgFill.BorderSizePixel = 0
bgFill.ZIndex = 25
bgFill.Parent = bgBg
Instance.new("UICorner", bgFill).CornerRadius = UDim.new(1, 0)

local bgKnob = Instance.new("Frame")
bgKnob.Size = UDim2.new(0, 10, 0, 10)
bgKnob.AnchorPoint = Vector2.new(0.5, 0.5)
bgKnob.Position = UDim2.new(1 - State.hudBgAlpha, 0, 0.5, 0)
bgKnob.BackgroundColor3 = C.accent2
bgKnob.BorderSizePixel = 0
bgKnob.ZIndex = 26
bgKnob.Parent = bgBg
Instance.new("UICorner", bgKnob).CornerRadius = UDim.new(1, 0)

-- Слайдер логика: шрифт
local slidingFS = false
fsBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then slidingFS = true end end)
fsBg.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then slidingFS = false end end)

-- Слайдер логика: bg
local slidingBG = false
bgBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then slidingBG = true end end)
bgBg.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then slidingBG = false end end)

UserInputService.InputChanged:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    if slidingFS then
        local rel = math.clamp((inp.Position.X - fsBg.AbsolutePosition.X) / fsBg.AbsoluteSize.X, 0, 1)
        State.hudFontSize = math.floor(7 + rel * (16 - 7))
        fsFill.Size = UDim2.new(rel, 0, 1, 0)
        fsKnob.Position = UDim2.new(rel, 0, 0.5, 0)
        fsLbl.Text = "Font: " .. State.hudFontSize
        -- применяем ко всем лейблам
        for _, name in ipairs(statNames) do
            local row = statRows[name]
            for _, child in ipairs(row:GetChildren()) do
                if child:IsA("TextLabel") then
                    child.TextSize = State.hudFontSize
                end
            end
        end
    end

    if slidingBG then
        local rel = math.clamp((inp.Position.X - bgBg.AbsolutePosition.X) / bgBg.AbsoluteSize.X, 0, 1)
        State.hudBgAlpha = 1 - rel
        bgFill.Size = UDim2.new(rel, 0, 1, 0)
        bgKnob.Position = UDim2.new(rel, 0, 0.5, 0)
        bgLbl.Text = "BG: " .. math.floor(rel * 100) .. "%"
        StatsHUD.BackgroundTransparency = State.hudBgAlpha
    end
end)

-- ======= STATS HUD: Alt+ЛКМ = ресайз, ЛКМ = drag =======
local HUD_MIN_W, HUD_MIN_H = 100, 30
local hudResizing, hudResizeStart, hudResizeStartSize = false, nil, nil
local hudDragging, hudDragStart, hudStartPos = false, nil, nil

-- ПКМ по HUD = toggle edit mode
StatsHUD.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        State.hudEditMode = not State.hudEditMode
        TweenService:Create(HUDStroke, TweenInfo.new(0.2), {
            Color = State.hudEditMode and Color3.fromRGB(255, 200, 50) or C.accent
        }):Play()
        positionEditPanel()
        recalcHUDHeight()
        if State.hudEditMode then
            EditPanel.Visible = true
            local origEP = EditPanel.Position
            EditPanel.Position = UDim2.new(origEP.X.Scale, origEP.X.Offset, origEP.Y.Scale, origEP.Y.Offset + 6)
            TweenService:Create(EditPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = origEP,
            }):Play()
        else
            local origEP = EditPanel.Position
            local tw = TweenService:Create(EditPanel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(origEP.X.Scale, origEP.X.Offset, origEP.Y.Scale, origEP.Y.Offset + 6),
            })
            tw:Play()
            tw.Completed:Connect(function()
                EditPanel.Visible = false
                EditPanel.Position = origEP
            end)
        end
    end
end)

StatsHUD.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        if isAlt() then
            hudResizing        = true
            hudResizeStart     = inp.Position
            hudResizeStartSize = Vector2.new(StatsHUD.AbsoluteSize.X, StatsHUD.AbsoluteSize.Y)
            HUDStroke.Color    = C.accent2
        else
            hudDragging  = true
            hudDragStart = inp.Position
            hudStartPos  = StatsHUD.Position
        end
    end
end)
StatsHUD.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        hudDragging = false
        if hudResizing then
            hudResizing    = false
            HUDStroke.Color = State.hudEditMode and Color3.fromRGB(255, 200, 50) or C.accent
        end
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    -- Ресайз Alt+drag
    if hudResizing then
        local d    = inp.Position - hudResizeStart
        local newW = math.max(HUD_MIN_W, hudResizeStartSize.X + d.X)
        local newH = math.max(HUD_MIN_H, hudResizeStartSize.Y + d.Y)
        StatsHUD.Size = UDim2.new(0, newW, 0, newH)

        local autoFont = math.clamp(math.floor(newW / 168 * 9), 6, 36)
        State.hudFontSize = autoFont
        relayoutRows()
        for _, name in ipairs(statNames) do
            for _, child in ipairs(statRows[name]:GetChildren()) do
                if child:IsA("TextLabel") then child.TextSize = autoFont end
            end
        end
        local rel = math.clamp((autoFont - 7) / (36 - 7), 0, 1)
        fsFill.Size = UDim2.new(rel, 0, 1, 0)
        fsKnob.Position = UDim2.new(rel, 0, 0.5, 0)
        fsLbl.Text = "Font: " .. autoFont
        return
    end

    -- Перетаскивание
    if hudDragging and not slidingFS and not slidingBG then
        local d = inp.Position - hudDragStart
        StatsHUD.Position = UDim2.new(
            hudStartPos.X.Scale, hudStartPos.X.Offset + d.X,
            hudStartPos.Y.Scale, hudStartPos.Y.Offset + d.Y
        )
    end
end)

-- Кнопка в меню
createModule(colMisc, "Stats HUD", function(on)
    State.statshud = on
    if on then
        StatsHUD.Position = UDim2.new(
            StatsHUD.Position.X.Scale, StatsHUD.Position.X.Offset,
            StatsHUD.Position.Y.Scale, StatsHUD.Position.Y.Offset - 8
        )
        StatsHUD.Visible = true
        TweenService:Create(StatsHUD, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(StatsHUD.Position.X.Scale, StatsHUD.Position.X.Offset,
                                  StatsHUD.Position.Y.Scale, StatsHUD.Position.Y.Offset + 8),
        }):Play()
    else
        local origPos = StatsHUD.Position
        local tw = TweenService:Create(StatsHUD, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(origPos.X.Scale, origPos.X.Offset, origPos.Y.Scale, origPos.Y.Offset - 6),
        })
        tw:Play()
        tw.Completed:Connect(function()
            StatsHUD.Visible = false
            StatsHUD.Position = origPos
            State.hudEditMode = false
            EditPanel.Visible = false
            HUDStroke.Color = C.accent
        end)
    end
end)

-- Обновление значений
local fpsBuffer = {}

RunService.RenderStepped:Connect(function(dt)
    if not State.statshud then return end

    -- FPS
    table.insert(fpsBuffer, dt)
    if #fpsBuffer > 30 then table.remove(fpsBuffer, 1) end
    local avgDt = 0
    for _, v in ipairs(fpsBuffer) do avgDt += v end
    local fps = math.floor(1 / (avgDt / #fpsBuffer))

    -- Ping
    local ping = 0
    pcall(function()
        ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    end)

    -- Coords
    local posText = "—"
    if rootPart then
        local p = rootPart.Position
        posText = string.format("%d, %d, %d", math.floor(p.X), math.floor(p.Y), math.floor(p.Z))
    end

    -- Speed
    local spdText = "—"
    if rootPart then
        local vel = rootPart.AssemblyLinearVelocity
        spdText = math.floor(Vector3.new(vel.X, 0, vel.Z).Magnitude) .. " st/s"
    end

    -- Цвета FPS
    statLines["FPS"].TextColor3 = fps >= 50 and C.green or (fps >= 25 and Color3.fromRGB(255,200,50) or C.red)
    -- Цвета Ping
    statLines["PING"].TextColor3 = ping <= 80 and C.green or (ping <= 180 and Color3.fromRGB(255,200,50) or C.red)

    statLines["FPS"].Text  = fps .. " fps"
    statLines["PING"].Text = ping .. " ms"
    statLines["POS"].Text  = posText
    statLines["SPD"].Text  = spdText
end)


-- ==========================================
-- GOLD SESSION HUD  (с edit panel как у Stats HUD)
-- ==========================================
State.goldhud = false

-- ── Gold Session Tracker ──────────────────────────────────────────────────
local sessionGoldEarned  = 0
local sessionStartGold   = nil
local sessionStartTime   = tick()
local goldDataConnection = nil

local function setupGoldTracking()
    pcall(function()
        local data = player:WaitForChild("Data", 5)
        if not data then return end
        local goldVal = data:WaitForChild("Gold", 5)
        if not goldVal then return end
        if sessionStartGold == nil then
            sessionStartGold = goldVal.Value
            sessionStartTime = tick()
        end
        if goldDataConnection then goldDataConnection:Disconnect() end
        goldDataConnection = goldVal:GetPropertyChangedSignal("Value"):Connect(function()
            local diff = goldVal.Value - sessionStartGold
            sessionGoldEarned = math.max(0, diff)
        end)
    end)
end
task.spawn(setupGoldTracking)

-- ── Состояние HUD ─────────────────────────────────────────────────────────
local GOLD_ROW_H   = 15
local GOLD_PAD_TOP = 4
local GOLD_PAD_S   = 6

local goldHudState = {
    editMode   = false,
    fontSize   = 9,
    bgAlpha    = 0.18,
    rowEnabled = { Earned = true, ["Per/hr"] = true, Time = true },
}

-- ── Фрейм Gold HUD ────────────────────────────────────────────────────────
local GoldHUD = Instance.new("Frame")
GoldHUD.Name                   = "NeptuneGoldHUD"
GoldHUD.Size                   = UDim2.new(0, 180, 0, GOLD_ROW_H * 3 + GOLD_PAD_TOP * 2 + 24)
GoldHUD.Position               = UDim2.new(0, 12, 0, 200)
GoldHUD.BackgroundColor3       = Color3.fromRGB(12, 16, 14)
GoldHUD.BackgroundTransparency = goldHudState.bgAlpha
GoldHUD.BorderSizePixel        = 0
GoldHUD.Visible                = false
GoldHUD.ZIndex                 = 20
GoldHUD.Parent                 = ScreenGui
Instance.new("UICorner", GoldHUD).CornerRadius = UDim.new(0, 7)

local GoldStroke = Instance.new("UIStroke")
GoldStroke.Color     = Color3.fromRGB(255, 200, 50)
GoldStroke.Thickness = 1
GoldStroke.Parent    = GoldHUD

-- ── Заголовок ─────────────────────────────────────────────────────────────
local GoldTitle = Instance.new("TextLabel")
GoldTitle.Size               = UDim2.new(1, -8, 0, 16)
GoldTitle.Position           = UDim2.new(0, 6, 0, 4)
GoldTitle.BackgroundTransparency = 1
GoldTitle.Text               = "🪙  Gold Session"
GoldTitle.TextColor3         = Color3.fromRGB(255, 200, 50)
GoldTitle.TextSize           = goldHudState.fontSize
GoldTitle.Font               = Enum.Font.Code
GoldTitle.TextXAlignment     = Enum.TextXAlignment.Left
GoldTitle.ZIndex             = 21
GoldTitle.Parent             = GoldHUD

local GoldDivider = Instance.new("Frame")
GoldDivider.Size             = UDim2.new(1, -12, 0, 1)
GoldDivider.Position         = UDim2.new(0, 6, 0, 21)
GoldDivider.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
GoldDivider.BackgroundTransparency = 0.6
GoldDivider.BorderSizePixel  = 0
GoldDivider.ZIndex           = 21
GoldDivider.Parent           = GoldHUD

-- ── Строки данных ─────────────────────────────────────────────────────────
local goldRowDef = {
    { key = "Earned",  icon = "＋" },
    { key = "Per/hr",  icon = "⚡" },
    { key = "Time",    icon = "⏱" },
}
local goldLines    = {}   -- key → TextLabel (значение)
local goldRowFrames = {}  -- key → Frame (вся строка)

local function relayoutGoldRows()
    local visible = {}
    for _, rd in ipairs(goldRowDef) do
        if goldHudState.rowEnabled[rd.key] then
            table.insert(visible, rd.key)
        else
            if goldRowFrames[rd.key] then goldRowFrames[rd.key].Visible = false end
        end
    end

    local startY = 26  -- ниже заголовка + разделителя
    for i, key in ipairs(visible) do
        local f = goldRowFrames[key]
        if f then
            f.Visible  = true
            f.Position = UDim2.new(0, GOLD_PAD_S, 0, startY + (i - 1) * GOLD_ROW_H)
            f.Size     = UDim2.new(1, -GOLD_PAD_S * 2, 0, GOLD_ROW_H)
        end
    end
end

local function recalcGoldHUDHeight()
    local vis = 0
    for _, en in pairs(goldHudState.rowEnabled) do if en then vis += 1 end end
    local extra = goldHudState.editMode and 84 or 0
    local resetH = 18
    GoldHUD.Size = UDim2.new(
        0, GoldHUD.Size.X.Offset,
        0, 26 + vis * GOLD_ROW_H + resetH + GOLD_PAD_TOP + extra
    )
end

for _, rd in ipairs(goldRowDef) do
    local f = Instance.new("Frame")
    f.Name                  = "GoldRow_" .. rd.key
    f.Size                  = UDim2.new(1, -GOLD_PAD_S * 2, 0, GOLD_ROW_H)
    f.BackgroundTransparency = 1
    f.ZIndex                = 21
    f.Parent                = GoldHUD
    goldRowFrames[rd.key]   = f

    local icon = Instance.new("TextLabel")
    icon.Size               = UDim2.new(0, 14, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text               = rd.icon
    icon.TextSize           = goldHudState.fontSize
    icon.Font               = Enum.Font.Code
    icon.TextColor3         = Color3.fromRGB(255, 200, 50)
    icon.ZIndex             = 22
    icon.Parent             = f

    local key = Instance.new("TextLabel")
    key.Name                = "Key"
    key.Size                = UDim2.new(0, 42, 1, 0)
    key.Position            = UDim2.new(0, 14, 0, 0)
    key.BackgroundTransparency = 1
    key.Text                = rd.key
    key.TextSize            = goldHudState.fontSize
    key.Font                = Enum.Font.Code
    key.TextColor3          = C.muted
    key.TextXAlignment      = Enum.TextXAlignment.Left
    key.ZIndex              = 22
    key.Parent              = f

    local val = Instance.new("TextLabel")
    val.Name                = "Val"
    val.Size                = UDim2.new(1, -58, 1, 0)
    val.Position            = UDim2.new(0, 58, 0, 0)
    val.BackgroundTransparency = 1
    val.Text                = "—"
    val.TextSize            = goldHudState.fontSize
    val.Font                = Enum.Font.Code
    val.TextColor3          = C.text
    val.TextXAlignment      = Enum.TextXAlignment.Left
    val.ZIndex              = 22
    val.Parent              = f

    goldLines[rd.key] = val
end

relayoutGoldRows()

-- ── Кнопка Reset (внизу) ──────────────────────────────────────────────────
local GoldResetBtn = Instance.new("TextButton")
GoldResetBtn.Name            = "GoldResetBtn"
GoldResetBtn.Size            = UDim2.new(1, -12, 0, 14)
GoldResetBtn.Position        = UDim2.new(0, 6, 1, -18)
GoldResetBtn.BackgroundColor3 = Color3.fromRGB(28, 38, 34)
GoldResetBtn.TextColor3      = C.muted
GoldResetBtn.TextSize        = 8
GoldResetBtn.Font            = Enum.Font.Code
GoldResetBtn.Text            = "↺  Reset"
GoldResetBtn.BorderSizePixel = 0
GoldResetBtn.ZIndex          = 22
GoldResetBtn.Parent          = GoldHUD
Instance.new("UICorner", GoldResetBtn).CornerRadius = UDim.new(0, 3)
GoldResetBtn.MouseButton1Click:Connect(function()
    sessionGoldEarned = 0
    sessionStartTime  = tick()
    pcall(function()
        local goldVal = player.Data.Gold
        if goldVal then sessionStartGold = goldVal.Value end
    end)
end)

-- ── Edit Panel (появляется снизу по ПКМ) ─────────────────────────────────
local GoldEditPanel = Instance.new("Frame")
GoldEditPanel.Name                   = "GoldEditPanel"
GoldEditPanel.Size                   = UDim2.new(1, 0, 0, 82)
GoldEditPanel.BackgroundColor3       = Color3.fromRGB(18, 26, 22)
GoldEditPanel.BackgroundTransparency = 0.1
GoldEditPanel.BorderSizePixel        = 0
GoldEditPanel.Visible                = false
GoldEditPanel.ZIndex                 = 23
GoldEditPanel.Parent                 = GoldHUD
Instance.new("UICorner", GoldEditPanel).CornerRadius = UDim.new(0, 5)

local GoldEPStroke = Instance.new("UIStroke")
GoldEPStroke.Color     = C.border
GoldEPStroke.Thickness = 1
GoldEPStroke.Parent    = GoldEditPanel

local function positionGoldEditPanel()
    local vis = 0
    for _, en in pairs(goldHudState.rowEnabled) do if en then vis += 1 end end
    GoldEditPanel.Position = UDim2.new(0, 0, 0, 26 + vis * GOLD_ROW_H + 18 + GOLD_PAD_TOP)
end

-- Тогглы строк (Earned / Per/hr / Time)
local goldToggleBtns = {}
local rowKeys = { "Earned", "Per/hr", "Time" }
for i, rk in ipairs(rowKeys) do
    local tb = Instance.new("TextButton")
    tb.Size             = UDim2.new(0, 48, 0, 14)
    tb.Position         = UDim2.new(0, 4 + (i - 1) * 52, 0, 4)
    tb.BackgroundColor3 = goldHudState.rowEnabled[rk] and Color3.fromRGB(255, 200, 50) or C.panel
    tb.TextColor3       = goldHudState.rowEnabled[rk] and C.bg or C.muted
    tb.Text             = rk
    tb.TextSize         = 8
    tb.Font             = Enum.Font.Code
    tb.BorderSizePixel  = 0
    tb.ZIndex           = 24
    tb.Parent           = GoldEditPanel
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 3)
    goldToggleBtns[rk] = tb

    tb.MouseButton1Click:Connect(function()
        goldHudState.rowEnabled[rk] = not goldHudState.rowEnabled[rk]
        tb.BackgroundColor3 = goldHudState.rowEnabled[rk] and Color3.fromRGB(255, 200, 50) or C.panel
        tb.TextColor3       = goldHudState.rowEnabled[rk] and C.bg or C.muted
        relayoutGoldRows()
        positionGoldEditPanel()
        recalcGoldHUDHeight()
    end)
end

-- Слайдер: Font Size
local gFsLbl = Instance.new("TextLabel")
gFsLbl.Size               = UDim2.new(1, -8, 0, 12)
gFsLbl.Position           = UDim2.new(0, 4, 0, 22)
gFsLbl.BackgroundTransparency = 1
gFsLbl.Text               = "Font: " .. goldHudState.fontSize
gFsLbl.TextSize           = 8
gFsLbl.Font               = Enum.Font.Code
gFsLbl.TextColor3         = C.muted
gFsLbl.TextXAlignment     = Enum.TextXAlignment.Left
gFsLbl.ZIndex             = 24
gFsLbl.Parent             = GoldEditPanel

local gFsBg = Instance.new("Frame")
gFsBg.Size             = UDim2.new(1, -8, 0, 6)
gFsBg.Position         = UDim2.new(0, 4, 0, 36)
gFsBg.BackgroundColor3 = C.panel
gFsBg.BorderSizePixel  = 0
gFsBg.ZIndex           = 24
gFsBg.Parent           = GoldEditPanel
Instance.new("UICorner", gFsBg).CornerRadius = UDim.new(1, 0)

local gFsFill = Instance.new("Frame")
gFsFill.Size             = UDim2.new((goldHudState.fontSize - 7) / (16 - 7), 0, 1, 0)
gFsFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
gFsFill.BorderSizePixel  = 0
gFsFill.ZIndex           = 25
gFsFill.Parent           = gFsBg
Instance.new("UICorner", gFsFill).CornerRadius = UDim.new(1, 0)

local gFsKnob = Instance.new("Frame")
gFsKnob.Size          = UDim2.new(0, 10, 0, 10)
gFsKnob.AnchorPoint   = Vector2.new(0.5, 0.5)
gFsKnob.Position      = UDim2.new((goldHudState.fontSize - 7) / (16 - 7), 0, 0.5, 0)
gFsKnob.BackgroundColor3 = Color3.fromRGB(255, 220, 80)
gFsKnob.BorderSizePixel  = 0
gFsKnob.ZIndex        = 26
gFsKnob.Parent        = gFsBg
Instance.new("UICorner", gFsKnob).CornerRadius = UDim.new(1, 0)

-- Слайдер: BG Transparency
local gBgLbl = Instance.new("TextLabel")
gBgLbl.Size               = UDim2.new(1, -8, 0, 12)
gBgLbl.Position           = UDim2.new(0, 4, 0, 48)
gBgLbl.BackgroundTransparency = 1
gBgLbl.Text               = "BG: " .. math.floor((1 - goldHudState.bgAlpha) * 100) .. "%"
gBgLbl.TextSize           = 8
gBgLbl.Font               = Enum.Font.Code
gBgLbl.TextColor3         = C.muted
gBgLbl.TextXAlignment     = Enum.TextXAlignment.Left
gBgLbl.ZIndex             = 24
gBgLbl.Parent             = GoldEditPanel

local gBgBg = Instance.new("Frame")
gBgBg.Size             = UDim2.new(1, -8, 0, 6)
gBgBg.Position         = UDim2.new(0, 4, 0, 62)
gBgBg.BackgroundColor3 = C.panel
gBgBg.BorderSizePixel  = 0
gBgBg.ZIndex           = 24
gBgBg.Parent           = GoldEditPanel
Instance.new("UICorner", gBgBg).CornerRadius = UDim.new(1, 0)

local gBgFill = Instance.new("Frame")
gBgFill.Size             = UDim2.new(1 - goldHudState.bgAlpha, 0, 1, 0)
gBgFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
gBgFill.BorderSizePixel  = 0
gBgFill.ZIndex           = 25
gBgFill.Parent           = gBgBg
Instance.new("UICorner", gBgFill).CornerRadius = UDim.new(1, 0)

local gBgKnob = Instance.new("Frame")
gBgKnob.Size          = UDim2.new(0, 10, 0, 10)
gBgKnob.AnchorPoint   = Vector2.new(0.5, 0.5)
gBgKnob.Position      = UDim2.new(1 - goldHudState.bgAlpha, 0, 0.5, 0)
gBgKnob.BackgroundColor3 = Color3.fromRGB(255, 220, 80)
gBgKnob.BorderSizePixel  = 0
gBgKnob.ZIndex        = 26
gBgKnob.Parent        = gBgBg
Instance.new("UICorner", gBgKnob).CornerRadius = UDim.new(1, 0)

-- ── GOLD HUD: слайдеры Font & BG ────────────────────────────────────────
local gSlidingFS = false
local gSlidingBG = false

gFsBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then gSlidingFS = true end end)
gFsBg.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then gSlidingFS = false end end)
gBgBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then gSlidingBG = true end end)
gBgBg.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then gSlidingBG = false end end)

local function applyGoldFontSize(sz)
    goldHudState.fontSize = sz
    GoldTitle.TextSize    = sz
    for _, rd in ipairs(goldRowDef) do
        local f = goldRowFrames[rd.key]
        if f then
            for _, child in ipairs(f:GetChildren()) do
                if child:IsA("TextLabel") then child.TextSize = sz end
            end
        end
    end
end

-- ── GOLD HUD: Alt+ЛКМ = ресайз, ЛКМ = drag ──────────────────────────────
local GOLD_MIN_W, GOLD_MIN_H = 120, 40
local gResizing, gResizeStart, gResizeStartSize = false, nil, nil
local ghDragging, ghDragStart, ghStartPos = false, nil, nil

-- ПКМ = toggle edit mode
GoldHUD.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        goldHudState.editMode = not goldHudState.editMode
        GoldEditPanel.Visible = goldHudState.editMode
        GoldStroke.Color = goldHudState.editMode
            and Color3.fromRGB(255, 255, 100)
            or  Color3.fromRGB(255, 200, 50)
        positionGoldEditPanel()
        recalcGoldHUDHeight()
    end
end)

GoldHUD.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        if isAlt() then
            gResizing        = true
            gResizeStart     = inp.Position
            gResizeStartSize = Vector2.new(GoldHUD.AbsoluteSize.X, GoldHUD.AbsoluteSize.Y)
            GoldStroke.Color = Color3.fromRGB(255, 255, 100)
        else
            ghDragging  = true
            ghDragStart = inp.Position
            ghStartPos  = GoldHUD.Position
        end
    end
end)
GoldHUD.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        ghDragging = false
        if gResizing then
            gResizing        = false
            GoldStroke.Color = goldHudState.editMode
                and Color3.fromRGB(255, 255, 100)
                or  Color3.fromRGB(255, 200, 50)
        end
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    -- Ресайз Gold HUD Alt+drag
    if gResizing then
        local d    = inp.Position - gResizeStart
        local newW = math.max(GOLD_MIN_W, gResizeStartSize.X + d.X)
        local newH = math.max(GOLD_MIN_H, gResizeStartSize.Y + d.Y)
        GoldHUD.Size = UDim2.new(0, newW, 0, newH)
        local autoFont = math.clamp(math.floor(newW / 180 * 9), 6, 28)
        applyGoldFontSize(autoFont)
        local rel = math.clamp((autoFont - 7) / (28 - 7), 0, 1)
        gFsFill.Size     = UDim2.new(rel, 0, 1, 0)
        gFsKnob.Position = UDim2.new(rel, 0, 0.5, 0)
        gFsLbl.Text      = "Font: " .. autoFont
        return
    end

    -- Слайдер шрифта
    if gSlidingFS then
        local rel = math.clamp((inp.Position.X - gFsBg.AbsolutePosition.X) / gFsBg.AbsoluteSize.X, 0, 1)
        local sz  = math.floor(7 + rel * (16 - 7))
        applyGoldFontSize(sz)
        gFsFill.Size     = UDim2.new(rel, 0, 1, 0)
        gFsKnob.Position = UDim2.new(rel, 0, 0.5, 0)
        gFsLbl.Text      = "Font: " .. sz
    end

    -- Слайдер BG
    if gSlidingBG then
        local rel = math.clamp((inp.Position.X - gBgBg.AbsolutePosition.X) / gBgBg.AbsoluteSize.X, 0, 1)
        goldHudState.bgAlpha = 1 - rel
        gBgFill.Size         = UDim2.new(rel, 0, 1, 0)
        gBgKnob.Position     = UDim2.new(rel, 0, 0.5, 0)
        gBgLbl.Text          = "BG: " .. math.floor(rel * 100) .. "%"
        GoldHUD.BackgroundTransparency = goldHudState.bgAlpha
    end

    -- Перетаскивание
    if ghDragging and not gSlidingFS and not gSlidingBG then
        local d = inp.Position - ghDragStart
        GoldHUD.Position = UDim2.new(
            ghStartPos.X.Scale, ghStartPos.X.Offset + d.X,
            ghStartPos.Y.Scale, ghStartPos.Y.Offset + d.Y
        )
    end
end)

-- ── Кнопка в меню ────────────────────────────────────────────────────────
createModule(colMisc, "Gold HUD", function(on)
    State.goldhud = on
    GoldHUD.Visible = on
    if on then
        task.spawn(setupGoldTracking)
    else
        goldHudState.editMode = false
        GoldEditPanel.Visible = false
        GoldStroke.Color      = Color3.fromRGB(255, 200, 50)
    end
end)

-- ── Обновление значений ──────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if not State.goldhud then return end
    local elapsed = tick() - sessionStartTime
    local hours   = elapsed / 3600
    local perHour = hours > 0 and math.floor(sessionGoldEarned / hours) or 0
    local mins    = math.floor(elapsed / 60)
    local secs    = math.floor(elapsed % 60)

    goldLines["Earned"].Text  = "+" .. tostring(sessionGoldEarned) .. " 🪙"
    goldLines["Per/hr"].Text  = tostring(perHour) .. " 🪙/h"
    goldLines["Time"].Text    = string.format("%d:%02d", mins, secs)

    goldLines["Earned"].TextColor3 = Color3.fromRGB(255, 220, 80)
    goldLines["Per/hr"].TextColor3 = Color3.fromRGB(100, 220, 140)
    goldLines["Time"].TextColor3   = C.text
end)


RunService.Stepped:Connect(function()
    if not character then return end
    local noclipActive = State.noclip or State.autofarm or State.ultrafarm

    if noclipActive then
        noclipWasActive = true
        for _, p in ipairs(character:GetDescendants()) do
            if p:IsA("BasePart") then
                if originalCanCollide[p] == nil then
                    originalCanCollide[p] = p.CanCollide
                end
                p.CanCollide = false
            end
        end
    elseif noclipWasActive then
        -- Восстанавливаем коллизии при выключении
        noclipWasActive = false
        for _, p in ipairs(character:GetDescendants()) do
            if p:IsA("BasePart") then
                if originalCanCollide[p] ~= nil then
                    p.CanCollide = originalCanCollide[p]
                end
            end
        end
        originalCanCollide = {}
    end
end)

RunService.RenderStepped:Connect(function()
    if not humanoid then return end
    if State.god then
        humanoid.MaxHealth = math.huge
        humanoid.Health    = math.huge
    end
    
    if State.speed then
        pcall(function() humanoid.WalkSpeed = State.walkSpeed end)
    end
    if State.jump then
        pcall(function() humanoid.JumpPower = State.jumpPower end)
    end

    if State.bhop and humanoid.FloorMaterial ~= Enum.Material.Air then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    
    if State.esp then
        for _, p in ipairs(Players:GetPlayers()) do
            updateEspForPlayer(p)
        end
    else
        -- чистим Drawing tracers если esp выключен
        for pname, line in pairs(espTracerDrawings) do
            pcall(function() line:Remove() end)
            espTracerDrawings[pname] = nil
        end
    end

    if State.goldesp then
        for _, p in ipairs(Players:GetPlayers()) do
            updateGoldEspForPlayer(p)
        end
    else
        -- чистим gold billboards если выключен
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local bb = p.Character:FindFirstChild("NeptuneGoldESPBillboard")
                if bb then bb:Destroy() end
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if State.infjump and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Delete then
        MainContainer.Visible = not MainContainer.Visible
        if SettingsPopup.Visible then SettingsPopup.Visible = false; activeSettingsOwner = nil end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and State.clicktp and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local mouse = player:GetMouse()
        if rootPart and mouse.Target then
            rootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end)

local function clickClaimButton()
    pcall(function()
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then return end
        for _, guiObj in ipairs(playerGui:GetDescendants()) do
            if guiObj:IsA("TextButton") or guiObj:IsA("ImageButton") then
                local text = (guiObj.Text or ""):lower()
                if text:find("claim") then
                    local absPos = guiObj.AbsolutePosition
                    local absSize = guiObj.AbsoluteSize
                    VirtualInputManager:SendMouseButtonEvent(absPos.X + absSize.X/2, absPos.Y + absSize.Y/2, 0, true, game, 0)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(absPos.X + absSize.X/2, absPos.Y + absSize.Y/2, 0, false, game, 0)
                end
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════
-- AUTO FARM — Method 1
-- Источник логики: github.com/Stefanuk12, Alive-Debug, lilmond
-- Путь: BoatStages.NormalStages.CaveStage1-10 → DarknessPart
--        → TheEnd.GoldenChest.Trigger → ClaimRiverResultsGold
-- ══════════════════════════════════════════════════════
runSingleCycle = function(char)
    if not State.autofarm then return end
    local root = char:WaitForChild("HumanoidRootPart", 5)
    local hum  = char:WaitForChild("Humanoid", 5)
    if not root or not hum then return end
    task.wait(0.5)
    if not State.autofarm or hum.Health <= 0 then return end

    State.noclip     = true
    State.cycleRunning = true
    local flightCompleted = true

    -- Ждём появления BoatStages (до 10 сек после спавна)
    local stages
    for _ = 1, 20 do
        local bs = Workspace:FindFirstChild("BoatStages")
        if bs then stages = bs:FindFirstChild("NormalStages") end
        if stages then break end
        task.wait(0.5)
    end

    if stages then
        for i = 1, 10 do
            if not State.autofarm or hum.Health <= 0 then
                flightCompleted = false; break
            end
            local stage = stages:FindFirstChild("CaveStage" .. i)
            local darkPart = stage and stage:FindFirstChild("DarknessPart")
            if not darkPart then flightCompleted = false; continue end

            local targetCF = darkPart.CFrame
            local dist = (root.Position - targetCF.Position).Magnitude

            -- Temp Part под ногами чтобы не упасть во время телепорта
            local tempPart = Instance.new("Part")
            tempPart.Anchored  = true
            tempPart.CanCollide = true
            tempPart.Size      = Vector3.new(4, 1, 4)
            tempPart.CFrame    = CFrame.new(targetCF.Position - Vector3.new(0, 3, 0))
            tempPart.Parent    = char

            -- Tween к DarknessPart
            currentTween = TweenService:Create(root,
                TweenInfo.new(dist / State.farmSpeed, Enum.EasingStyle.Linear),
                {CFrame = targetCF})
            currentTween:Play()

            while currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing do
                if not State.autofarm or hum.Health <= 0 then
                    currentTween:Cancel(); flightCompleted = false; break
                end
                task.wait(0.05)
            end

            tempPart:Destroy()
            task.wait(0.08)
        end

        -- Идём к финальному сундуку
        if State.autofarm and flightCompleted and hum.Health > 0 then
            -- Метод 1: TheEnd.GoldenChest.Trigger (основной путь по открытым скриптам)
            local trigger = stages:FindFirstChild("TheEnd") and
                           stages.TheEnd:FindFirstChild("GoldenChest") and
                           stages.TheEnd.GoldenChest:FindFirstChild("Trigger")

            -- Метод 2: ClaimRiverResultsGold (резерв)
            local goldChest = trigger or Workspace:FindFirstChild("ClaimRiverResultsGold", true)

            if trigger then
                -- Несколько раз телепортируемся к триггеру чтобы точно засчиталось
                for _ = 1, 15 do
                    if not State.autofarm then break end
                    root.CFrame = trigger.CFrame
                    root.AssemblyLinearVelocity = Vector3.zero
                    task.wait(0.1)
                end
                task.wait(0.3)
                for _ = 1, 5 do clickClaimButton(); task.wait(0.15) end
            elseif goldChest then
                root.CFrame = goldChest.CFrame
                task.wait(0.2)
                for _ = 1, 5 do clickClaimButton(); task.wait(0.15) end
            end
        end
    else
        flightCompleted = false
    end

    State.cycleRunning = false
    if State.autofarm then
        forceKillCharacter(char)
    end
end

startAutoKillLoop = function()
    if autoKillConnection then
        pcall(function() task.cancel(autoKillConnection) end)
        autoKillConnection = nil
    end
    autoKillConnection = task.spawn(function()
        while State.autofarm do
            -- ждём старта цикла (до 5 сек)
            local waited = 0
            while not State.cycleRunning and waited < 5 and State.autofarm do
                task.wait(0.1)
                waited += 0.1
            end
            if not State.autofarm then break end
            -- ждём killDelay секунд с момента старта цикла
            task.wait(State.killDelay)
            -- принудительно убиваем — неважно завис или нет
            if State.autofarm and character then
                if currentTween then currentTween:Cancel() end
                State.cycleRunning = false
                forceKillCharacter(character)
            end
            -- ждём следующего цикла (CharacterAdded запустит новый)
            task.wait(3)
        end
    end)
end

-- Логика Ultra Farm Method 1
runUltraSingleCycle = function(char)
    if not State.ultrafarm then return end
    local root = char:WaitForChild("HumanoidRootPart", 5)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if not root or not humanoid then return end
    task.wait(0.5)
    if not State.ultrafarm or humanoid.Health <= 0 then return end
    State.noclip = true
    State.cycleRunning = true
    local flightCompleted = true
    local stages = Workspace:FindFirstChild("BoatStages") and Workspace.BoatStages:FindFirstChild("NormalStages")
    if stages then
        for i = 1, 10 do
            if not State.ultrafarm or humanoid.Health <= 0 then flightCompleted = false; break end
            local stage = stages:FindFirstChild("CaveStage" .. i)
            if stage and stage:FindFirstChild("DarknessPart") then
                local targetCF = stage.DarknessPart.CFrame
                currentTween = TweenService:Create(root, TweenInfo.new((root.Position - targetCF.Position).Magnitude / State.farmSpeed, Enum.EasingStyle.Linear), {CFrame = targetCF})
                currentTween:Play()
                while currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing do
                    if not State.ultrafarm or humanoid.Health <= 0 then currentTween:Cancel(); flightCompleted = false; break end
                    task.wait(0.05)
                end
                task.wait(0.05)
            else
                flightCompleted = false
            end
        end
    else
        flightCompleted = false
    end
    if State.ultrafarm then
        if flightCompleted and humanoid.Health > 0 then
            local goldChest = Workspace:FindFirstChild("ClaimRiverResultsGold")
            if goldChest then
                root.CFrame = goldChest.CFrame
                task.wait(0.2)
                for _ = 1, 3 do clickClaimButton(); task.wait(0.2) end
            end
        end
        State.cycleRunning = false
        forceKillCharacter(char)
    else
        State.cycleRunning = false
    end
end

startUltraKillLoop = function()
    if ultraKillConnection then
        pcall(function() task.cancel(ultraKillConnection) end)
        ultraKillConnection = nil
    end
    ultraKillConnection = task.spawn(function()
        while State.ultrafarm do
            -- ждём старта цикла (до 5 сек)
            local waited = 0
            while not State.cycleRunning and waited < 5 and State.ultrafarm do
                task.wait(0.1)
                waited += 0.1
            end
            if not State.ultrafarm then break end
            -- ждём killDelay секунд с момента старта цикла
            task.wait(State.killDelay)
            -- принудительно убиваем
            if State.ultrafarm and character then
                if currentTween then currentTween:Cancel() end
                State.cycleRunning = false
                forceKillCharacter(character)
            end
            task.wait(3)
        end
    end)
end

player.CharacterAdded:Connect(function(newChar)
    updateCharVars(newChar)
    if connection then connection:Disconnect(); connection = nil end
    bv, bg = nil, nil
    originalCanCollide = {}
    noclipWasActive = false
    State.cycleRunning = false
    if currentTween then currentTween:Cancel() end
    task.wait(1)
    if State.god and humanoid then humanoid.MaxHealth = math.huge; humanoid.Health = math.huge end
    if State.fly then enableFly() end
    if State.autofarm then
        if State.farmMode == "Method 1" then
            task.spawn(function() runSingleCycle(newChar) end)
            task.delay(1, function() if State.autofarm then startAutoKillLoop() end end)
        else
            startAutoFarm2Loop()
        end
    end
    if State.ultrafarm then 
        applyFpsBoost(true)
        startAntiKick()
        if State.farmMode == "Method 1" then
            task.spawn(function() runUltraSingleCycle(newChar) end)
            task.delay(1, function() if State.ultrafarm then startUltraKillLoop() end end)
        else
            startUltraFarm2Loop()
        end
    end
end)
