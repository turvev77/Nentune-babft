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
local MainContainer = Instance.new("Frame")
MainContainer.Size              = UDim2.new(0, 480, 0, 160)
MainContainer.Position          = UDim2.new(0.5, -240, 0.5, -80)
MainContainer.BackgroundColor3  = C.bg
MainContainer.BackgroundTransparency = 0.1
MainContainer.Visible           = true
MainContainer.Parent            = ScreenGui
Instance.new("UICorner", MainContainer).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = C.border
MainStroke.Thickness = 1.5
MainStroke.Parent = MainContainer

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
btnClose.MouseButton1Click:Connect(function()
    MainContainer.Visible = false
end)

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

local dragging, dragStart, startPos
MacHeader.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = inp.Position; startPos = MainContainer.Position
    end
end)
MacHeader.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dragStart
        MainContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
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
        SettingsPopup.Visible = false
        activeSettingsOwner = nil
        return
    end

    SettingsPopup.Position = UDim2.new(0, pos.X, 0, pos.Y)
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
    TitleLbl.Text               = title .. "  [-]"
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

    local contentHeight = 0
    UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentHeight = UIList.AbsoluteContentSize.Y
        Scroll.Size = UDim2.new(1, -4, 0, contentHeight)
        if Window.Size.Y.Offset > 30 then
            Window.Size = UDim2.new(0, 145, 0, contentHeight + 32)
        end
    end)

    local collapsed = false
    WinHeader.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            collapsed = not collapsed
            if collapsed then
                TitleLbl.Text = title .. "  [+]"
                TweenService:Create(Window, TweenInfo.new(0.2), {Size = UDim2.new(0, 145, 0, 26)}):Play()
            else
                TitleLbl.Text = title .. "  [-]"
                TweenService:Create(Window, TweenInfo.new(0.2), {Size = UDim2.new(0, 145, 0, contentHeight + 32)}):Play()
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
    
    local function triggerState(newState)
        active = newState
        Btn.BackgroundColor3 = active and C.accent or C.panel2
        Btn.TextColor3 = active and C.bg or C.muted
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

    Btn.MouseEnter:Connect(function() if not active then Btn.BackgroundColor3 = C.header end end)
    Btn.MouseLeave:Connect(function() if not active then Btn.BackgroundColor3 = C.panel2 end end)
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
            startAutoKillLoop()
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
end)

-- Новый отдельный Ultra Farm (Фарм + Анти-кик + Буст FPS)
createModule(colPlayer, "Ultra Farm", function(on)
    State.ultrafarm = on
    if on then
        applyFpsBoost(true)
        startAntiKick()
        if State.farmMode == "Method 1" then
            if player.Character then task.spawn(function() runUltraSingleCycle(player.Character) end) end
            startUltraKillLoop()
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
        btn.MouseButton1Click:Connect(function()
            applyPreset(tColor, fCol, fDens, sat, con)
        end)
    end
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
end)

local function updateEspForPlayer(targetPlayer)
    if targetPlayer == player then return end
    local char = targetPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head") or char:FindFirstChildPrimaryPart()
    if not head then return end

    local billboard = char:FindFirstChild("NeptuneESPBillboard")
    if State.esp then
        if not billboard then
            billboard = Instance.new("BillboardGui")
            billboard.Name = "NeptuneESPBillboard"
            billboard.Size = UDim2.new(0, 200, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 4.0, 0)
            billboard.AlwaysOnTop = true
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Name = "ESPText"
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.TextColor3 = C.accent
            textLabel.TextStrokeTransparency = 0.5
            textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            textLabel.TextSize = 12
            textLabel.Font = Enum.Font.Code
            textLabel.Parent = billboard
            
            billboard.Parent = char
        end

        local textLbl = billboard:FindFirstChild("ESPText")
        if textLbl and rootPart and char:FindFirstChild("HumanoidRootPart") then
            local dist = math.floor((rootPart.Position - char.HumanoidRootPart.Position).Magnitude)
            if State.espMode == "Name" then
                textLbl.Text = targetPlayer.Name
            elseif State.espMode == "Distance" then
                textLbl.Text = "[" .. dist .. " studs]"
            else
                textLbl.Text = targetPlayer.Name .. " [" .. dist .. " studs]"
            end
        end
    else
        if billboard then billboard:Destroy() end
    end
end

createModule(colMisc, "Player ESP", function(on)
    State.esp = on
    if not on then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local bb = p.Character:FindFirstChild("NeptuneESPBillboard")
                if bb then bb:Destroy() end
            end
        end
    end
end, function(popup)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 18)
    lbl.Position = UDim2.new(0, 6, 0, 30)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = C.text
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Code
    lbl.Text = "Mode: " .. State.espMode
    lbl.ZIndex = 11
    lbl.Parent = popup

    local btnMode = Instance.new("TextButton")
    btnMode.Size = UDim2.new(1, -12, 0, 22)
    btnMode.Position = UDim2.new(0, 6, 0, 52)
    btnMode.BackgroundColor3 = C.panel
    btnMode.TextColor3 = C.accent
    btnMode.TextSize = 10
    btnMode.Font = Enum.Font.Code
    btnMode.Text = "Toggle Mode"
    btnMode.ZIndex = 11
    btnMode.Parent = popup
    Instance.new("UICorner", btnMode).CornerRadius = UDim.new(0, 3)

    local btnGold = Instance.new("TextButton")
    btnGold.Size = UDim2.new(1, -12, 0, 22)
    btnGold.Position = UDim2.new(0, 6, 0, 80)
    btnGold.BackgroundColor3 = State.goldesp and C.accent or C.panel
    btnGold.TextColor3 = State.goldesp and C.bg or C.accent
    btnGold.TextSize = 10
    btnGold.Font = Enum.Font.Code
    btnGold.Text = "Gold ESP: " .. (State.goldesp and "ON" or "OFF")
    btnGold.ZIndex = 11
    btnGold.Parent = popup
    Instance.new("UICorner", btnGold).CornerRadius = UDim.new(0, 3)

    btnMode.MouseButton1Click:Connect(function()
        if State.espMode == "Both" then State.espMode = "Name"
        elseif State.espMode == "Name" then State.espMode = "Distance"
        else State.espMode = "Both" end
        lbl.Text = "Mode: " .. State.espMode
    end)

    btnGold.MouseButton1Click:Connect(function()
        State.goldesp = not State.goldesp
        btnGold.BackgroundColor3 = State.goldesp and C.accent or C.panel
        btnGold.TextColor3 = State.goldesp and C.bg or C.accent
        btnGold.Text = "Gold ESP: " .. (State.goldesp and "ON" or "OFF")
        if not State.goldesp then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    local bb = p.Character:FindFirstChild("NeptuneGoldESPBillboard")
                    if bb then bb:Destroy() end
                end
            end
        end
    end)
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

local originalCanCollide = {}
RunService.Stepped:Connect(function()
    if not State.noclip and not State.autofarm and not State.ultrafarm then return end
    if not character then return end
    for _, p in ipairs(character:GetDescendants()) do
        if p:IsA("BasePart") then
            if originalCanCollide[p] == nil then originalCanCollide[p] = p.CanCollide end
            p.CanCollide = false
        end
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
    end

    if State.goldesp then
        for _, p in ipairs(Players:GetPlayers()) do
            updateGoldEspForPlayer(p)
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

-- Логика обычного Auto Farm Method 1
runSingleCycle = function(char)
    if not State.autofarm then return end
    local root = char:WaitForChild("HumanoidRootPart", 5)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if not root or not humanoid then return end
    task.wait(0.5)
    if not State.autofarm or humanoid.Health <= 0 then return end
    State.noclip = true
    local flightCompleted = true
    local stages = Workspace:FindFirstChild("BoatStages") and Workspace.BoatStages:FindFirstChild("NormalStages")
    if stages then
        for i = 1, 10 do
            if not State.autofarm or humanoid.Health <= 0 then flightCompleted = false; break end
            local stage = stages:FindFirstChild("CaveStage" .. i)
            if stage and stage:FindFirstChild("DarknessPart") then
                local targetCF = stage.DarknessPart.CFrame
                currentTween = TweenService:Create(root, TweenInfo.new((root.Position - targetCF.Position).Magnitude / State.farmSpeed, Enum.EasingStyle.Linear), {CFrame = targetCF})
                currentTween:Play()
                while currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing do
                    if not State.autofarm or humanoid.Health <= 0 then currentTween:Cancel(); flightCompleted = false; break end
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
    if State.autofarm then
        if flightCompleted and humanoid.Health > 0 then
            local goldChest = Workspace:FindFirstChild("ClaimRiverResultsGold")
            if goldChest then
                root.CFrame = goldChest.CFrame
                task.wait(0.2)
                for _ = 1, 3 do clickClaimButton(); task.wait(0.2) end
            end
        end
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
            task.wait(19)
            if State.autofarm and character then
                forceKillCharacter(character)
            end
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
        forceKillCharacter(char)
    end
end

startUltraKillLoop = function()
    if ultraKillConnection then
        pcall(function() task.cancel(ultraKillConnection) end)
        ultraKillConnection = nil
    end
    ultraKillConnection = task.spawn(function()
        while State.ultrafarm do
            task.wait(19)
            if State.ultrafarm and character then
                forceKillCharacter(character)
            end
        end
    end)
end

player.CharacterAdded:Connect(function(newChar)
    updateCharVars(newChar)
    if connection then connection:Disconnect(); connection = nil end
    bv, bg = nil, nil
    originalCanCollide = {}
    if currentTween then currentTween:Cancel() end
    task.wait(1)
    if State.god and humanoid then humanoid.MaxHealth = math.huge; humanoid.Health = math.huge end
    if State.fly then enableFly() end
    if State.autofarm then
        if State.farmMode == "Method 1" then
            startAutoKillLoop()
            task.spawn(function() runSingleCycle(newChar) end)
        else
            startAutoFarm2Loop()
        end
    end
    if State.ultrafarm then 
        applyFpsBoost(true)
        startAntiKick()
        if State.farmMode == "Method 1" then
            startUltraKillLoop()
            task.spawn(function() runUltraSingleCycle(newChar) end) 
        else
            startUltraFarm2Loop()
        end
    end
end)
