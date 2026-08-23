-- ╔════════════════════════════════════════════════════════════════╗
-- ║     NEPTUNE.LUA BABFT — UPDATE: FPS & SERVER HOP               ║
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
    antikick  = false,
    speed     = false,
    jump      = false,
    infjump   = false,
    bhop      = false,
    fov       = false,
    esp       = false,
    clicktp   = false,
    invisible = false,
    fpsboost  = false,
    flySpeed  = 80,
    farmSpeed = 450,
    fovVal    = 110,
    espMode   = "Both",
    farmMode  = "Method 1",
}

local bv, bg, connection
local currentTween = nil
local activeSettingsOwner = nil
local autoKillConnection = nil
local autoFarm2Loop = nil
local originalLightingProps = {}

-- Цветовая палитра: Бирюзовый и Ярко-зеленый
local C = {
    bg       = Color3.fromRGB(15,  22,  20),
    panel    = Color3.fromRGB(22,  32,  28),
    panel2   = Color3.fromRGB(30,  45,  38),
    header   = Color3.fromRGB(10,  16,  14),
    accent   = Color3.fromRGB(0,   230, 160),
    accent2  = Color3.fromRGB(80,  255, 120),
    text     = Color3.fromRGB(235, 255, 245),
    muted    = Color3.fromRGB(120, 150, 135),
    green    = Color3.fromRGB(0,   255, 100),
    red      = Color3.fromRGB(230, 60,  60),
    border   = Color3.fromRGB(35,  65,  50),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "NeptuneLuaBabft"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local ok = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ok then ScreenGui.Parent = player.PlayerGui end

-- ==========================================
-- ЗАГРУЗОЧНЫЙ ЭКРАН (БЕЗ ФОНА / ПРОЗРАЧНЫЙ)
-- ==========================================
local LoadContainer = Instance.new("Frame")
LoadContainer.Size = UDim2.new(0, 320, 0, 140)
LoadContainer.AnchorPoint = Vector2.new(0.5, 0.5)
LoadContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadContainer.BackgroundColor3 = C.bg
LoadContainer.BackgroundTransparency = 0.2
LoadContainer.BorderSizePixel = 0
LoadContainer.ZIndex = 101
LoadContainer.Parent = ScreenGui
Instance.new("UICorner", LoadContainer).CornerRadius = UDim.new(0, 8)

local LoadStroke = Instance.new("UIStroke")
LoadStroke.Color = C.accent
LoadStroke.Thickness = 1.5
LoadStroke.Parent = LoadContainer

local TitleLoad = Instance.new("TextLabel")
TitleLoad.Size = UDim2.new(1, 0, 0, 40)
TitleLoad.Position = UDim2.new(0, 0, 0, 15)
TitleLoad.BackgroundTransparency = 1
TitleLoad.Text = "NEPTUNE.LUA"
TitleLoad.TextColor3 = C.accent
TitleLoad.TextSize = 22
TitleLoad.Font = Enum.Font.Code
TitleLoad.ZIndex = 102
TitleLoad.Parent = LoadContainer

local SubLoad = Instance.new("TextLabel")
SubLoad.Size = UDim2.new(1, 0, 0, 20)
SubLoad.Position = UDim2.new(0, 0, 0, 48)
SubLoad.BackgroundTransparency = 1
SubLoad.Text = "Initializing modules..."
SubLoad.TextColor3 = C.muted
SubLoad.TextSize = 11
SubLoad.Font = Enum.Font.Code
SubLoad.ZIndex = 102
SubLoad.Parent = LoadContainer

local BarBg = Instance.new("Frame")
BarBg.Size = UDim2.new(0, 270, 0, 6)
BarBg.Position = UDim2.new(0.5, -135, 0, 85)
BarBg.BackgroundColor3 = C.panel2
BarBg.BorderSizePixel = 0
BarBg.ZIndex = 102
BarBg.Parent = LoadContainer
Instance.new("UICorner", BarBg).CornerRadius = UDim.new(1, 0)

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = C.accent
BarFill.BorderSizePixel = 0
BarFill.ZIndex = 103
BarFill.Parent = BarBg
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)

local PercentLbl = Instance.new("TextLabel")
PercentLbl.Size = UDim2.new(1, 0, 0, 20)
PercentLbl.Position = UDim2.new(0, 0, 0, 100)
PercentLbl.BackgroundTransparency = 1
PercentLbl.Text = "0%"
PercentLbl.TextColor3 = C.text
PercentLbl.TextSize = 10
PercentLbl.Font = Enum.Font.Code
PercentLbl.ZIndex = 102
PercentLbl.Parent = LoadContainer

-- ==========================================
-- ОСНОВНОЙ ИНТЕРФЕЙС (СКРЫТ ДО ЗАГРУЗКИ)
-- ==========================================
local MainContainer = Instance.new("Frame")
MainContainer.Size              = UDim2.new(0, 470, 0, 100)
MainContainer.Position          = UDim2.new(0.5, -235, 0.5, -50)
MainContainer.BackgroundTransparency = 1
MainContainer.Visible           = false
MainContainer.Parent            = ScreenGui

local SettingsPopup = Instance.new("Frame")
SettingsPopup.Size              = UDim2.new(0, 160, 0, 95)
SettingsPopup.BackgroundColor3  = C.panel2
SettingsPopup.BorderSizePixel   = 0
SettingsPopup.Visible           = false
SettingsPopup.ZIndex            = 10
SettingsPopup.Parent            = ScreenGui
Instance.new("UICorner", SettingsPopup).CornerRadius = UDim.new(0, 4)
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
    Title.Position = UDim2.new(0, 6, 0, 4)
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
    Window.Position         = UDim2.new(0, posX, 0, 0)
    Window.BackgroundColor3 = C.bg
    Window.BorderSizePixel  = 0
    Window.ClipsDescendants = true
    Window.Parent           = MainContainer
    Instance.new("UICorner", Window).CornerRadius = UDim.new(0, 4)

    local WinStroke = Instance.new("UIStroke")
    WinStroke.Color = C.border
    WinStroke.Thickness = 1
    WinStroke.Parent = Window

    local WinHeader = Instance.new("Frame")
    WinHeader.Size              = UDim2.new(1, 0, 0, 26)
    WinHeader.BackgroundColor3  = C.header
    WinHeader.BorderSizePixel   = 0
    WinHeader.Parent            = Window
    Instance.new("UICorner", WinHeader).CornerRadius = UDim.new(0, 4)

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

    local dragging, dragStart, startPos
    WinHeader.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = inp.Position; startPos = Window.Position
        end
    end)
    WinHeader.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                        startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    return Scroll
end

local colPlayer   = createCategory("Player", 0)
local colMovement = createCategory("Movement", 155)
local colMisc     = createCategory("Misc", 310)

local function createModule(parent, name, callback, settingsCallback)
    local Btn = Instance.new("TextButton")
    Btn.Size                = UDim2.new(1, 0, 0, 24)
    Btn.BackgroundColor3    = C.panel
    Btn.BorderSizePixel     = 0
    Btn.Text                = "  " .. name
    Btn.TextColor3          = C.muted
    Btn.TextSize            = 10
    Btn.Font                = Enum.Font.Code
    Btn.TextXAlignment      = Enum.TextXAlignment.Left
    Btn.Parent              = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 3)

    local active = false
    Btn.MouseButton1Click:Connect(function()
        active = not active
        Btn.BackgroundColor3 = active and C.accent or C.panel
        Btn.TextColor3 = active and C.bg or C.muted
        callback(active)
    end)

    if settingsCallback then
        Btn.MouseButton2Click:Connect(function()
            local mouseLoc = UserInputService:GetMouseLocation()
            toggleSettingsPopup(name, name .. " Settings", settingsCallback, mouseLoc)
        end)
    end

    Btn.MouseEnter:Connect(function() if not active then Btn.BackgroundColor3 = C.panel2 end end)
    Btn.MouseLeave:Connect(function() if not active then Btn.BackgroundColor3 = C.panel end end)
end

-- Логика второго метода фарма
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
                            tempPart.Size = Vector3.new(5, 1, 5)
                            tempPart.Position = char.HumanoidRootPart.Position - Vector3.new(0, 6, 0)
                            
                            task.wait(1.4)
                            tempPart:Destroy()
                        end
                    end

                    if State.autofarm and normalStages:FindFirstChild("TheEnd") and normalStages.TheEnd:FindFirstChild("GoldenChest") then
                        local chestTrigger = normalStages.TheEnd.GoldenChest:FindFirstChild("Trigger")
                        if chestTrigger then
                            char.HumanoidRootPart.CFrame = chestTrigger.CFrame
                        end
                    end
                end
            end
            task.wait(3)
        end
    end)
end

-- Player Modules
createModule(colPlayer, "God Mode", function(on) State.god = on end)

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
        disableNoclip()
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

createModule(colPlayer, "Speed Boost", function(on) State.speed = on end)
createModule(colPlayer, "Jump Power", function(on) State.jump = on end)
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

-- Movement Modules
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

createModule(colMovement, "Noclip", function(on)
    State.noclip = on
    if not State.noclip then disableNoclip() end
end)
createModule(colMovement, "Infinite Jump", function(on) State.infjump = on end)
createModule(colMovement, "Bunny Hop", function(on) State.bhop = on end)
createModule(colMovement, "Click TP (Ctrl+Click)", function(on) State.clicktp = on end)

-- Misc Modules
createModule(colMisc, "Anti-Kick", function(on) State.antikick = on end)

-- FPS Booster
createModule(colMisc, "FPS Booster", function(on)
    State.fpsboost = on
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
end)

-- Server Hop
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

    btnMode.MouseButton1Click:Connect(function()
        if State.espMode == "Both" then State.espMode = "Name"
        elseif State.espMode == "Name" then State.espMode = "Distance"
        else State.espMode = "Both" end
        lbl.Text = "Mode: " .. State.espMode
    end)
end)

createModule(colMisc, "Rejoin Server", function(on)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end)

local originalCanCollide = {}
local function disableNoclip()
    if not character then return end
    for p, canCollide in pairs(originalCanCollide) do
        if p and p.Parent then p.CanCollide = canCollide end
    end
    originalCanCollide = {}
end

RunService.Stepped:Connect(function()
    if not State.noclip and not State.autofarm then return end
    if not character then return end
    for _, p in ipairs(character:GetDescendants()) do
        if p:IsA("BasePart") then
            if originalCanCollide[p] == nil then originalCanCollide[p] = p.CanCollide end
            p.CanCollide = false
        end
    end
end)

function enableFly()
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
        if not State.fly or State.autofarm or not rootPart or not bv or not bg then return end
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

function disableFly()
    if connection then connection:Disconnect(); connection = nil end
    if bv then bv:Destroy(); bv = nil end
    if bg then bg:Destroy(); bg = nil end
    if humanoid then humanoid.PlatformStand = false end
    pcall(function() if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end end)
end

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
            billboard.Size = UDim2.new(0, 200, 0, 50)
            billboard.StudsOffset = Vector3.new(0, 2.5, 0)
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

RunService.RenderStepped:Connect(function()
    if not humanoid then return end
    if State.god then
        humanoid.MaxHealth = math.huge
        humanoid.Health    = math.huge
    end
    if State.speed then humanoid.WalkSpeed = 35 else humanoid.WalkSpeed = 16 end
    if State.jump then humanoid.JumpPower = 80 else humanoid.JumpPower = 50 end
    if State.bhop and humanoid.FloorMaterial ~= Enum.Material.Air then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    
    if State.esp then
        for _, p in ipairs(Players:GetPlayers()) do
            updateEspForPlayer(p)
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

local function clickClaimButton()
    pcall(function()
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then return end
        for _, guiObj in ipairs(playerGui:GetDescendants()) do
            if guiObj:IsA("TextButton") or guiObj:IsA("ImageButton") then
                local text = (guiObj.Text or ""):lower()
                if text:find("получить") or text:find("claim") then
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

function startAutoKillLoop()
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
end)

-- ==========================================
-- АНИМАЦИЯ ЗАГРУЗОЧНОГО ЭКРАНА
-- ==========================================
task.spawn(function()
    local steps = {
        {txt = "Connecting to Neptune servers...", progress = 0.2, delay = 0.4},
        {txt = "Bypassing anti-cheat...", progress = 0.5, delay = 0.5},
        {txt = "Injecting modules...", progress = 0.8, delay = 0.4},
        {txt = "Initialization complete!", progress = 1.0, delay = 0.3}
    }

    for _, step in ipairs(steps) do
        SubLoad.Text = step.txt
        TweenService:Create(BarFill, TweenInfo.new(step.delay, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(step.progress, 0, 1, 0)
        }):Play()
        PercentLbl.Text = math.floor(step.progress * 100) .. "%"
        task.wait(step.delay + 0.1)
    end

    task.wait(0.3)

    local fadeInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(LoadContainer, fadeInfo, {Position = UDim2.new(0.5, 0, 0.45, 0)}):Play()
    
    local fadeContainer = TweenService:Create(LoadContainer, fadeInfo, {BackgroundTransparency = 1})
    local fadeText1 = TweenService:Create(TitleLoad, fadeInfo, {TextTransparency = 1})
    local fadeText2 = TweenService:Create(SubLoad, fadeInfo, {TextTransparency = 1})
    local fadeText3 = TweenService:Create(PercentLbl, fadeInfo, {TextTransparency = 1})
    local fadeBarBg = TweenService:Create(BarBg, fadeInfo, {BackgroundTransparency = 1})
    local fadeBarFi = TweenService:Create(BarFill, fadeInfo, {BackgroundTransparency = 1})
    local fadeStroke = TweenService:Create(LoadStroke, fadeInfo, {Transparency = 1})

    fadeContainer:Play()
    fadeText1:Play()
    fadeText2:Play()
    fadeText3:Play()
    fadeBarBg:Play()
    fadeBarFi:Play()
    fadeStroke:Play()

    fadeContainer.Completed:Wait()
    LoadContainer:Destroy()

    MainContainer.Visible = true
end)
