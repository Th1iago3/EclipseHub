-- ECLIPSE HUB 

local LocalPlayer = game:GetService("Players").LocalPlayer
if game.PlaceId ~= 114234929420007 then
    LocalPlayer:Kick("Eclipse Hub: Jogo incompativel.")
    return
end

-- ANTI-EXEC DUPLA
if getgenv().EclipseHubLoaded then 
    warn("Eclipse Hub: Script ja esta em execucao. Fechando segunda instancia...")
    return 
end
getgenv().EclipseHubLoaded = true

-- SERVICOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

-- VARIAVEIS
local Camera = Workspace.CurrentCamera
local OriginalCameraFOV = Camera.FieldOfView
local OriginalCameraType = Camera.CameraType
local Characters = Workspace:WaitForChild("Characters")

-- CARREGAR OBSIDIAN COM TIMEOUT PARA EVITAR TRAVAMENTOS
local Library
local success, err = pcall(function()
    Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua", true))()
end)

if not success or not Library then
    warn("Eclipse Hub: Falha critica ao carregar Obsidian Library.")
    getgenv().EclipseHubLoaded = nil -- Permite tentar novamente se falhar
    return
end

-- CRIACAO DA JANELA NA COREGUI
local Window = Library:CreateWindow({
    Title = "ECLIPSE HUB",
    Footer = string.format("%s | ID: %d", LocalPlayer.Name, LocalPlayer.UserId),
    AutoShow = true,
    ToggleKeybind = Enum.KeyCode.RightShift
})

-- ATUALIZAR FOOTER
task.spawn(function()
    while scriptRunning do
        task.wait(1)
        if Window then
            pcall(function()
                Window:SetFooter(string.format("%s | ID: %d", LocalPlayer.Name, LocalPlayer.UserId))
            end)
        end
    end
end)

-- SISTEMA DE NOTIFICACAO VISUAL
local NotificationFrame = Instance.new("Frame")
NotificationFrame.Size = UDim2.new(0, 250, 0, 0)
NotificationFrame.Position = UDim2.new(0, 20, 0, 20)
NotificationFrame.BackgroundTransparency = 1
NotificationFrame.Parent = CoreGui
NotificationFrame.ZIndex = 1000
local NotifLayout = Instance.new("UIListLayout", NotificationFrame)
NotifLayout.Padding = UDim.new(0, 5)
NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local function Notify(text, type)
    local color = Color3.fromRGB(0, 150, 255)
    if type == "error" then color = Color3.fromRGB(255, 50, 50)
    elseif type == "success" then color = Color3.fromRGB(50, 255, 100)
    elseif type == "warning" then color = Color3.fromRGB(255, 200, 0) end

    local Item = Instance.new("Frame")
    Item.Size = UDim2.new(1, 0, 0, 40)
    Item.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Item.BackgroundTransparency = 0.1
    Item.BorderSizePixel = 0
    Item.Parent = NotificationFrame
    Item.Position = UDim2.new(0, 0, 0, -50)
    Item.ClipsDescendants = true
    Instance.new("UICorner", Item).CornerRadius = UDim.new(0, 8)
    
    local Stroke = Instance.new("UIStroke", Item)
    Stroke.Color = color; Stroke.Thickness = 1.5; Stroke.Transparency = 0.2

    local Label = Instance.new("TextLabel", Item)
    Label.Size = UDim2.new(1, -10, 1, 0); Label.Position = UDim2.new(0, 5, 0, 0)
    Label.BackgroundTransparency = 1; Label.Text = text
    Label.Font = Enum.Font.GothamBold; Label.TextSize = 14
    Label.TextColor3 = Color3.fromRGB(255, 255, 255); Label.TextXAlignment = Enum.TextXAlignment.Left

    local Bar = Instance.new("Frame", Item)
    Bar.Size = UDim2.new(1, 0, 0, 3); Bar.Position = UDim2.new(0, 0, 1, -3)
    Bar.BackgroundColor3 = color; Bar.BorderSizePixel = 0

    TweenService:Create(Item, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    TweenService:Create(Bar, TweenInfo.new(3, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 3)}):Play()

    task.delay(3.5, function()
        if Item and Item.Parent then
            local fadeOut = TweenService:Create(Item, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)})
            fadeOut:Play()
            fadeOut.Completed:Connect(function() if Item and Item.Parent then Item:Destroy() end end)
        end
    end)
end

-- CONFIGURACAO GLOBAL
local Config = {
    GlobalEnable = true,
    TeamCheck = false,
    Aimbot = { Enabled = false, FOV = 150, Smoothness = 5, TargetPart = "Head", DrawFOV = true, VisibilityCheck = true },
    TriggerBot = { Enabled = false, Delay = 0.01, Mode = "HitChance", HitChance = 100, Spread = 0 },
    ESP = { Enabled = false, MaxDistance = 500, CornerBox = true, Name = true, Distance = true, HealthBar = true, TargetLine = true, Position = "Top" },
    Skins = { SkinChangerEnabled = false, SelectedKnife = "Butterfly Knife", SelectedSkins = {} },
    Movement = { BunnyHop = false, AutoStrafe = false, StrafeSpeed = 1.0 },
    World = { Weather = "None" },
    Misc = { ChatNotifications = true, AntiDetection = true }
}

local scriptRunning = true
local UnloadConnections = {}
local function connectSignal(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        table.insert(UnloadConnections, conn)
    end
    return conn
end

local function CleanupScript()
    scriptRunning = false
    for _, conn in ipairs(UnloadConnections) do
        if conn and conn.Disconnect then
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(UnloadConnections)

    if NotificationFrame and NotificationFrame.Parent then
        pcall(function() NotificationFrame:Destroy() end)
        NotificationFrame = nil
    end

    if Camera.CameraType == Enum.CameraType.Scriptable then
        Camera.CameraType = OriginalCameraType
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then Camera.CameraSubject = hum end
        end
    end
    if Camera.FieldOfView ~= OriginalCameraFOV then
        Camera.FieldOfView = OriginalCameraFOV
    end

    if type(ESPObjects) == "table" then
        for _, data in pairs(ESPObjects) do
            if type(data) == "table" then
                if type(data.CornerLines) == "table" then
                    for _, line in pairs(data.CornerLines) do
                        if line and line.Remove then pcall(function() line:Remove() end) end
                    end
                end
                if data.NameTag and data.NameTag.Remove then pcall(function() data.NameTag:Remove() end) end
                if data.DistTag and data.DistTag.Remove then pcall(function() data.DistTag:Remove() end) end
                if data.HealthBg and data.HealthBg.Remove then pcall(function() data.HealthBg:Remove() end) end
                if data.HealthFill and data.HealthFill.Remove then pcall(function() data.HealthFill:Remove() end) end
            end
        end
        table.clear(ESPObjects)
    end

    if TargetLine and TargetLine.Remove then pcall(function() TargetLine:Remove() end) end
    if FOVCircle and FOVCircle.Remove then pcall(function() FOVCircle:Remove() end) end
    if WeatherPart then pcall(function() WeatherPart:Destroy() end); WeatherPart = nil end

    if Library then
        if type(Library.Unload) == "function" then
            pcall(function() Library:Unload() end)
        end
        if Library.ScreenGui and Library.ScreenGui.Destroy then
            pcall(function() Library.ScreenGui:Destroy() end)
        end
        getgenv().Library = nil
    end

    if Window and type(Window.Destroy) == "function" then
        pcall(function() Window:Destroy() end)
    end
    Window = nil
end

-- VARIAVEIS DE ESTADO
local ESPObjects = {}
local TargetLine = Drawing.new("Line")
TargetLine.Thickness = 3; TargetLine.Color = Color3.fromRGB(255, 140, 0); TargetLine.Visible = false

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2; FOVCircle.NumSides = 64; FOVCircle.Filled = false
FOVCircle.Visible = false; FOVCircle.Color = Color3.fromRGB(255, 255, 255); FOVCircle.Transparency = 0.3

-- FUNCOES UTILITARIAS
local function IsAlive()
    local t = Characters:FindFirstChild("Terrorists")
    local ct = Characters:FindFirstChild("Counter-Terrorists")
    return (t and t:FindFirstChild(LocalPlayer.Name)) or (ct and ct:FindFirstChild(LocalPlayer.Name))
end

local function IsAlly(plr)
    if not plr.Character then return false end
    return plr.Character.Parent == LocalPlayer.Character.Parent
end

local function IsEnemy(plr)
    if plr == LocalPlayer then return false end
    if not plr.Character then return false end
    if Config.TeamCheck then return not IsAlly(plr) end
    return true
end

local function WorldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local FriendUserIds = {}

local function IsFriend(player)
    return player and player.UserId and FriendUserIds[player.UserId]
end

local function SendChatMessage(text, color)
    if not Config.Misc.ChatNotifications then return end
    pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = text,
            Color = color or Color3.fromRGB(180, 180, 255),
            Font = Enum.Font.SourceSansBold,
            FontSize = Enum.FontSize.Size24,
            TextTransparency = 0
        })
    end)
end

local function QueuePlayerMessage(player, joined)
    if not player then return end
    local name = player.Name
    local action = joined and "entrou no servidor" or "saiu do servidor"
    local color = joined and Color3.fromRGB(180, 255, 255) or Color3.fromRGB(255, 210, 150)
    SendChatMessage(string.format("[ECLIPSE] [PLAYER] %s %s", name, action), color)
end

local function EnableEclipseCloak(silent)
    Config.Misc.AntiDetection = true
    pcall(function()
        if getgenv then
            getgenv().EclipseHubLoaded = nil
            getgenv().EclipseHubTrace = nil
        end
    end)
    if not silent then
        Notify("Cloak de Eclipse ativado", "success")
    end
end

local function FlushEclipseTrace()
    pcall(function()
        if getgenv then
            getgenv().EclipseHubTrace = nil
            getgenv().EclipseHubLoaded = nil
        end
    end)
    Notify("Rastro secreto limpo", "warning")
end

local function UpdateFriendList()
    table.clear(FriendUserIds)
    local success, pages = pcall(function()
        return LocalPlayer:GetFriendsAsync()
    end)
    if not success or not pages then return end
    local current = pages
    while current do
        local ok, friends = pcall(function()
            return current:GetCurrentPage()
        end)
        if not ok or not friends then break end
        for _, friend in ipairs(friends) do
            if friend and friend.Id then
                FriendUserIds[friend.Id] = true
            end
        end
        local nextOk, nextPage = pcall(function()
            return current:GetNextPageAsync()
        end)
        if not nextOk or not nextPage then break end
        current = nextPage
    end
end

local function IsVisible(part)
    if not part then return false end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = Workspace:Raycast(origin, direction, rayParams)
    if result then return result.Instance:IsDescendantOf(part.Parent) end
    return true
end

local function GetAimbotTargetPart(character)
    if not character then return nil end
    local partName = Config.Aimbot.TargetPart
    local candidates = {}
    if partName == "Head" then
        candidates = {"Head"}
    elseif partName == "Neck" then
        candidates = {"Neck", "Head", "UpperTorso", "Torso"}
    elseif partName == "Arms" then
        candidates = {"LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand"}
    elseif partName == "Legs" then
        candidates = {"LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot"}
    elseif partName == "HumanoidRootPart" then
        candidates = {"HumanoidRootPart"}
    else
        candidates = {partName}
    end
    for _, name in ipairs(candidates) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

-- SISTEMA DE DROPDOWN SEGURO (CORRECAO PRINCIPAL)
-- Esta funcao garante que o dropdown so seja criado se houver opcoes validas
local function SafeAddDropdown(group, id, data)
    if type(data.Values) ~= "table" or #data.Values == 0 then
        if type(data.Options) == "table" and #data.Options > 0 then
            data.Values = data.Options
        else
            data.Values = {"Nenhum"}
        end
    end
    if not data.Default or not table.find(data.Values, data.Default) then
        data.Default = data.Values[1]
    end
    if type(data.Options) ~= "table" or #data.Options == 0 then
        data.Options = data.Values
    end
    
    local dropdown = nil
    local ok, err = pcall(function()
        dropdown = group:AddDropdown(id, data)
    end)
    if not ok then
        warn("Eclipse Hub: Erro ao criar dropdown '" .. tostring(id) .. "' - " .. tostring(err))
    end
    return dropdown
end

-- ==================== LOGICA DO JOGO ====================

-- ESP SYSTEM
local HealthGradientColors = {
    {threshold = 0.00, color = Color3.fromRGB(120, 20, 20)},
    {threshold = 0.25, color = Color3.fromRGB(150, 30, 30)},
    {threshold = 0.50, color = Color3.fromRGB(180, 100, 20)},
    {threshold = 0.75, color = Color3.fromRGB(200, 180, 20)},
    {threshold = 1.00, color = Color3.fromRGB(40, 160, 40)},
}

local function GetHealthColor(percentage)
    for i = 1, #HealthGradientColors do
        if percentage <= HealthGradientColors[i].threshold then
            local current = HealthGradientColors[i]
            local previous = i > 1 and HealthGradientColors[i-1] or current
            if i == 1 then return current.color end
            local prevThreshold, currThreshold = previous.threshold, current.threshold
            local range = currThreshold - prevThreshold
            local t = (percentage - prevThreshold) / range
            local c1, c2 = previous.color, current.color
            return Color3.new(c1.R + (c2.R - c1.R) * t, c1.G + (c2.G - c1.G) * t, c1.B + (c2.B - c1.B) * t)
        end
    end
    return HealthGradientColors[#HealthGradientColors].color
end

local function createESPObjects(plr)
    local data = {
        CornerLines = {},
        NameTag = Drawing.new("Text"),
        DistTag = Drawing.new("Text"),
        HealthBg = Drawing.new("Line"),
        HealthFill = Drawing.new("Line")
    }
    for i = 1, 8 do
        data.CornerLines[i] = Drawing.new("Line")
        data.CornerLines[i].Thickness = 2; data.CornerLines[i].Visible = false
    end
    data.NameTag.Font = 2; data.NameTag.Size = 14; data.NameTag.Outline = true; data.NameTag.Center = true; data.NameTag.Visible = false
    data.DistTag.Font = 2; data.DistTag.Size = 12; data.DistTag.Outline = true; data.DistTag.Center = true; data.DistTag.Visible = false
    data.HealthBg.Thickness = 4; data.HealthBg.Color = Color3.fromRGB(10, 10, 10); data.HealthBg.Visible = false
    data.HealthFill.Thickness = 3; data.HealthFill.Visible = false
    return data
end

local function updateESP()
    if not Config.GlobalEnable or not Config.ESP.Enabled then
        for _, data in pairs(ESPObjects) do
            for _, line in pairs(data.CornerLines) do line.Visible = false end
            data.NameTag.Visible = false; data.DistTag.Visible = false
            data.HealthBg.Visible = false; data.HealthFill.Visible = false
        end
        TargetLine.Visible = false
        return
    end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        for _, data in pairs(ESPObjects) do
            for _, line in pairs(data.CornerLines) do line.Visible = false end
            data.NameTag.Visible = false; data.DistTag.Visible = false; data.HealthBg.Visible = false; data.HealthFill.Visible = false
        end
        TargetLine.Visible = false
        return
    end

    local closestTarget = nil
    local closestDist = math.huge
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if Config.TeamCheck and IsAlly(plr) then continue end
        
        local char = plr.Character
        if not char then 
            if ESPObjects[plr] then
                for _, line in pairs(ESPObjects[plr].CornerLines) do line.Visible = false end
                ESPObjects[plr].NameTag.Visible = false; ESPObjects[plr].DistTag.Visible = false
                ESPObjects[plr].HealthBg.Visible = false; ESPObjects[plr].HealthFill.Visible = false
            end
            continue 
        end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if not root or not head or not hum or hum.Health <= 0 then
            if ESPObjects[plr] then
                for _, line in pairs(ESPObjects[plr].CornerLines) do line.Visible = false end
                ESPObjects[plr].NameTag.Visible = false; ESPObjects[plr].DistTag.Visible = false
                ESPObjects[plr].HealthBg.Visible = false; ESPObjects[plr].HealthFill.Visible = false
            end
            continue
        end
        
        local dist = (myRoot.Position - root.Position).Magnitude
        local maxEspDistance = Config.ESP.MaxDistance
        if Config.Aimbot.Enabled then
            maxEspDistance = math.max(maxEspDistance, 500)
        end
        if dist > maxEspDistance then 
            if ESPObjects[plr] then
                for _, line in pairs(ESPObjects[plr].CornerLines) do line.Visible = false end
                ESPObjects[plr].NameTag.Visible = false; ESPObjects[plr].DistTag.Visible = false
                ESPObjects[plr].HealthBg.Visible = false; ESPObjects[plr].HealthFill.Visible = false
            end
            continue 
        end

        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local footPos, footOnScreen = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

        if not (headOnScreen and footOnScreen) then
            if ESPObjects[plr] then
                for _, line in pairs(ESPObjects[plr].CornerLines) do line.Visible = false end
                ESPObjects[plr].NameTag.Visible = false; ESPObjects[plr].DistTag.Visible = false
                ESPObjects[plr].HealthBg.Visible = false; ESPObjects[plr].HealthFill.Visible = false
            end
            continue
        end

        if headOnScreen then
            local aimDist = (Vector2.new(headPos.X, headPos.Y) - viewportCenter).Magnitude
            if aimDist < closestDist then
                closestDist = aimDist
                closestTarget = {player = plr, root = root, head = head, hum = hum, dist = dist}
            end
        end

        if not ESPObjects[plr] then ESPObjects[plr] = createESPObjects(plr) end
        local data = ESPObjects[plr]
        
        if not (headOnScreen and footOnScreen) then
            for _, line in pairs(data.CornerLines) do line.Visible = false end
            data.NameTag.Visible = false; data.DistTag.Visible = false
            data.HealthBg.Visible = false; data.HealthFill.Visible = false
            continue
        end

        local height = math.abs(headPos.Y - footPos.Y)
        local width = height * 0.6
        local centerX = headPos.X
        local centerY = (headPos.Y + footPos.Y) / 2
        local left = centerX - width / 2; local right = centerX + width / 2
        local top = centerY - height / 2; local bottom = centerY + height / 2
        local cornerW = width * 0.25; local cornerH = height * 0.25

        if Config.ESP.CornerBox then
            local lines = data.CornerLines
            local color = IsAlly(plr) and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 40, 40)
            lines[1].From = Vector2.new(left, top); lines[1].To = Vector2.new(left + cornerW, top); lines[1].Color = color; lines[1].Visible = true
            lines[2].From = Vector2.new(left, top); lines[2].To = Vector2.new(left, top + cornerH); lines[2].Color = color; lines[2].Visible = true
            lines[3].From = Vector2.new(right, top); lines[3].To = Vector2.new(right - cornerW, top); lines[3].Color = color; lines[3].Visible = true
            lines[4].From = Vector2.new(right, top); lines[4].To = Vector2.new(right, top + cornerH); lines[4].Color = color; lines[4].Visible = true
            lines[5].From = Vector2.new(left, bottom); lines[5].To = Vector2.new(left + cornerW, bottom); lines[5].Color = color; lines[5].Visible = true
            lines[6].From = Vector2.new(left, bottom); lines[6].To = Vector2.new(left, bottom - cornerH); lines[6].Color = color; lines[6].Visible = true
            lines[7].From = Vector2.new(right, bottom); lines[7].To = Vector2.new(right - cornerW, bottom); lines[7].Color = color; lines[7].Visible = true
            lines[8].From = Vector2.new(right, bottom); lines[8].To = Vector2.new(right, bottom - cornerH); lines[8].Color = color; lines[8].Visible = true
        else
            for _, line in pairs(data.CornerLines) do line.Visible = false end
        end

        local textY = Config.ESP.Position == "Top" and top - 18 or bottom + 18
        local distY = Config.ESP.Position == "Top" and top - 35 or bottom + 35

        if Config.ESP.Name then
            data.NameTag.Text = plr.Name
            data.NameTag.Position = Vector2.new(centerX, textY)
            data.NameTag.Color = IsAlly(plr) and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(220, 30, 30)
            data.NameTag.Visible = true
        else data.NameTag.Visible = false end

        if Config.ESP.Distance then
            data.DistTag.Text = math.floor(dist) .. "m"
            data.DistTag.Position = Vector2.new(centerX, distY)
            data.DistTag.Color = Color3.fromRGB(200, 180, 0)
            data.DistTag.Visible = true
        else data.DistTag.Visible = false end

        if Config.ESP.HealthBar then
            local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local barHeight = height * pct
            local barX = left - 10
            data.HealthBg.From = Vector2.new(barX, top); data.HealthBg.To = Vector2.new(barX, bottom); data.HealthBg.Visible = true
            data.HealthFill.From = Vector2.new(barX, bottom); data.HealthFill.To = Vector2.new(barX, bottom - barHeight)
            data.HealthFill.Color = GetHealthColor(pct)
            data.HealthFill.Visible = true
        else
            data.HealthBg.Visible = false; data.HealthFill.Visible = false
        end
    end

    if Config.ESP.TargetLine and closestTarget then
        local screenPos, onScreen = Camera:WorldToViewportPoint(closestTarget.head.Position)
        if onScreen then
            TargetLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            TargetLine.To = Vector2.new(screenPos.X, screenPos.Y)
            TargetLine.Visible = true
        else TargetLine.Visible = false end
    else TargetLine.Visible = false end
end

-- AIMBOT & TRIGGER
local function updateAimbot()
    if not Config.GlobalEnable or not Config.Aimbot.Enabled or not Config.Aimbot.DrawFOV then
        FOVCircle.Visible = false
    end
    if not Config.GlobalEnable or not Config.Aimbot.Enabled then
        return
    end

    FOVCircle.Visible = Config.Aimbot.DrawFOV
    FOVCircle.Radius = Config.Aimbot.FOV
    FOVCircle.Position = UserInputService:GetMouseLocation()

    local isAiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or Config.TriggerBot.Enabled
    if not isAiming then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local closestPart = nil
    local closestDist = Config.Aimbot.FOV

    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if not IsEnemy(plr) then continue end
        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local part = GetAimbotTargetPart(char)
        if not part then continue end
        if Config.Aimbot.VisibilityCheck and not IsVisible(part) then continue end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if onScreen then
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestPart = part
            end
        end
    end

    if closestPart then
        local screenPos = Camera:WorldToViewportPoint(closestPart.Position)
        local targetPos = Vector2.new(screenPos.X, screenPos.Y)
        local deltaX = (targetPos.X - mousePos.X) / Config.Aimbot.Smoothness
        local deltaY = (targetPos.Y - mousePos.Y) / Config.Aimbot.Smoothness
        
        local maxMove = 2.0
        deltaX = math.clamp(deltaX, -maxMove, maxMove)
        deltaY = math.clamp(deltaY, -maxMove, maxMove)
        
        if mousemoverel then mousemoverel(deltaX, deltaY) end
    end
end

local lastTriggerTime = 0
local function updateTriggerBot()
    if not Config.GlobalEnable or not Config.TriggerBot.Enabled or not IsAlive() then return end
    if tick() - lastTriggerTime < Config.TriggerBot.Delay then return end
    
    local shouldFire = false
    if Config.TriggerBot.Mode == "HitChance" then
        if math.random(1, 100) <= Config.TriggerBot.HitChance then shouldFire = true end
    elseif Config.TriggerBot.Mode == "NoSpread" then
        shouldFire = true
    end
    
    if shouldFire then
        local viewportSize = Camera.ViewportSize
        local centerScreen = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
        local spread = Config.TriggerBot.Spread
        local aimPoint = centerScreen + Vector2.new(math.random(-spread, spread), math.random(-spread, spread))
        
        local ray = Camera:ViewportPointToRay(aimPoint.X, aimPoint.Y)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        local ignoreList = {Camera}
        if LocalPlayer.Character then table.insert(ignoreList, LocalPlayer.Character) end
        raycastParams.FilterDescendantsInstances = ignoreList
        
        local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
        if result and result.Instance then
            local model = result.Instance:FindFirstAncestorOfClass("Model")
            if model and model:FindFirstChildOfClass("Humanoid") then
                local humTarget = model:FindFirstChildOfClass("Humanoid")
                if humTarget and humTarget.Health > 0 then
                    local plr = Players:GetPlayerFromCharacter(model)
                    if plr then
                        if Config.TeamCheck and IsAlly(plr) then return end
                    end
                    lastTriggerTime = tick()
                    if mouse1click then mouse1click() end
                end
            end
        end
    end
end

-- MOVEMENT
local lastBhopTime = 0
local strafeDirection = 1
local lastStrafeTime = 0

local function updateMovement()
    if not Config.GlobalEnable then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    if Config.Movement.BunnyHop and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        if hum.FloorMaterial ~= Enum.Material.Air and tick() - lastBhopTime > 0.02 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            lastBhopTime = tick()
        end
    end

    if Config.Movement.AutoStrafe and hum:GetState() == Enum.HumanoidStateType.Freefall then
        local currentTime = tick()
        if currentTime - lastStrafeTime > 0.5 then strafeDirection = strafeDirection * -1; lastStrafeTime = currentTime end
        local moveDirection = UserInputService:GetMouseDelta().X
        if math.abs(moveDirection) > 5 then
            local strafeAmount = math.clamp(moveDirection / 150, -1, 1) * Config.Movement.StrafeSpeed
            local currentVel = root.Velocity
            root.Velocity = Vector3.new(
                currentVel.X + (root.CFrame.RightVector * strafeAmount * strafeDirection).X * 50,
                currentVel.Y,
                currentVel.Z + (root.CFrame.RightVector * strafeAmount * strafeDirection).Z * 50
            )
        end
    end
end

-- SKIN CHANGER LOGIC (BLUEX INTEGRATED)
local SkinSystem = { scriptRunning = false, spawned = false, inspecting = false, swinging = false, lastAttackTime = 0, vm = nil, animator = nil }
local knives = { ["Karambit"]={Offset=CFrame.new(0,-1.5,1.5)}, ["Butterfly Knife"]={Offset=CFrame.new(0,-1.5,1.5)}, ["M9 Bayonet"]={Offset=CFrame.new(0,-1.5,1)}, ["Flip Knife"]={Offset=CFrame.new(0,-1.5,1.25)}, ["Gut Knife"]={Offset=CFrame.new(0,-1.5,0.5)} }
local CT_ONLY = {["USP-S"]=true, ["Five-SeveN"]=true, ["MP9"]=true, ["FAMAS"]=true, ["M4A1-S"]=true, ["M4A4"]=true, ["AUG"]=true}
local SHARED = {["P250"]=true, ["Desert Eagle"]=true, ["Dual Berettas"]=true, ["Negev"]=true, ["P90"]=true, ["Nova"]=true, ["XM1014"]=true, ["AWP"]=true, ["SSG 08"]=true}
local KNIVES = {["Karambit"]=true, ["Butterfly Knife"]=true, ["M9 Bayonet"]=true, ["Flip Knife"]=true, ["Gut Knife"]=true, ["T Knife"]=true, ["CT Knife"]=true}
local GLOVES = {["Sports Gloves"]=true}
local SkinsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Skins")
local IgnoreFolders = {["HE Grenade"]=true, ["Incendiary Grenade"]=true, ["Molotov"]=true, ["Smoke Grenade"]=true, ["Flashbang"]=true, ["Decoy Grenade"]=true, ["C4"]=true, ["CT Glove"]=true, ["T Glove"]=true}

local function cleanPart(part) if not part:IsA("BasePart") then return end part.CanCollide=false; part.Anchored=false; part.CastShadow=false; part.CanTouch=false; part.CanQuery=false end
local function disableCollisions(model) for _, p in model:GetDescendants() do cleanPart(p) end end
local function hideOriginalKnife(knife) for _, p in knife:GetDescendants() do if p:IsA("BasePart") or p:IsA("MeshPart") or p:IsA("Texture") then p.Transparency=1 end end end

local function attachAsset(folder, armPartName, assetModelName, finalName, offset)
    local targetArm = SkinSystem.vm:FindFirstChild(armPartName)
    if not targetArm then return end
    local assetMesh = folder:WaitForChild(assetModelName):Clone()
    cleanPart(assetMesh); assetMesh.Name = finalName; assetMesh.Parent = targetArm
    local motor = Instance.new("Motor6D"); motor.Part0=targetArm; motor.Part1=assetMesh; motor.C0=offset; motor.Parent=targetArm
end

local function playSound(folder, name)
    local weaponSounds = ReplicatedStorage.Sounds:FindFirstChild(Config.Skins.SelectedKnife)
    if not weaponSounds then return end
    local sound = weaponSounds:WaitForChild(folder):WaitForChild(name):Clone()
    sound.Parent = Camera; sound:Play(); sound.Ended:Once(function() sound:Destroy() end)
end

local function handleAction(actionName, inputState, inputObject)
    if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
    if not SkinSystem.spawned or not SkinSystem.animator or not IsAlive() then return Enum.ContextActionResult.Pass end
    if actionName == "InspectKnifeAction" then
        if SkinSystem.inspecting or SkinSystem.swinging then return Enum.ContextActionResult.Pass end
        SkinSystem.inspecting = true
        if SkinSystem.idleAnim then SkinSystem.idleAnim:Stop() end
        SkinSystem.inspectAnim:Play()
        SkinSystem.inspectAnim.Stopped:Once(function() SkinSystem.inspecting = false end)
    elseif actionName == "AttackKnifeAction" then
        local currentTime = os.clock()
        if currentTime - SkinSystem.lastAttackTime < 1 then return Enum.ContextActionResult.Pass end
        SkinSystem.lastAttackTime = currentTime
        if SkinSystem.inspecting then SkinSystem.inspecting = false; if SkinSystem.inspectAnim then SkinSystem.inspectAnim:Stop() end end
        SkinSystem.swinging = true
        if SkinSystem.idleAnim then SkinSystem.idleAnim:Stop() end
        local anims = {SkinSystem.HeavySwingAnim, SkinSystem.Swing1Anim, SkinSystem.Swing2Anim}
        local chosenAnim = anims[math.random(1, #anims)]
        local soundFolder = (chosenAnim == SkinSystem.HeavySwingAnim and "HitOne") or (chosenAnim == SkinSystem.Swing1Anim and "HitTwo") or "HitThree"
        chosenAnim:Play(); playSound(soundFolder, "1")
        chosenAnim.Stopped:Once(function() SkinSystem.swinging = false end)
    end
    return Enum.ContextActionResult.Pass
end

local function removeViewmodel()
    SkinSystem.spawned = false
    ContextActionService:UnbindAction("InspectKnifeAction"); ContextActionService:UnbindAction("AttackKnifeAction")
    if SkinSystem.vm then SkinSystem.vm:Destroy(); SkinSystem.vm = nil end
    SkinSystem.animator = nil; SkinSystem.inspecting = false; SkinSystem.swinging = false
end

local function spawnViewmodel(knife)
    if SkinSystem.spawned or not SkinSystem.scriptRunning then return end
    local myModel = IsAlive()
    if not myModel then return end
    SkinSystem.spawned = true
    local knifeTemplate = ReplicatedStorage.Assets.Weapons:WaitForChild(Config.Skins.SelectedKnife)
    local knifeOffset = knives[Config.Skins.SelectedKnife].Offset
    SkinSystem.vm = knifeTemplate:WaitForChild("Camera"):Clone()
    SkinSystem.vm.Name = Config.Skins.SelectedKnife; SkinSystem.vm.Parent = Camera
    disableCollisions(SkinSystem.vm); hideOriginalKnife(knife)

    if myModel.Parent.Name == "Terrorists" then
        local tGloves = ReplicatedStorage.Assets.Weapons:WaitForChild("T Glove")
        attachAsset(tGloves, "Left Arm", "Left Arm", "Glove", CFrame.new(0,0,-1.5)); attachAsset(tGloves, "Right Arm", "Right Arm", "Glove", CFrame.new(0,0,-1.5))
    else
        local sleeves = ReplicatedStorage.Assets.Sleeves:WaitForChild("IDF")
        local ctGloves = ReplicatedStorage.Assets.Weapons:WaitForChild("CT Glove")
        attachAsset(sleeves, "Left Arm", "Left Arm", "Sleeve", CFrame.new(0,0,0.5)); attachAsset(ctGloves, "Left Arm", "Left Arm", "Glove", CFrame.new(0,0,-1.5))
        attachAsset(sleeves, "Right Arm", "Right Arm", "Sleeve", CFrame.new(0,0,0.5)); attachAsset(ctGloves, "Right Arm", "Right Arm", "Glove", CFrame.new(0,0,-1.5))
    end

    local animController = SkinSystem.vm:FindFirstChildOfClass("AnimationController") or SkinSystem.vm:FindFirstChildOfClass("Animator")
    SkinSystem.animator = animController:FindFirstChildWhichIsA("Animator") or animController
    local animFolder = ReplicatedStorage.Assets.WeaponAnimations:WaitForChild(Config.Skins.SelectedKnife):WaitForChild("CameraAnimations")
    SkinSystem.equipAnim = SkinSystem.animator:LoadAnimation(animFolder:WaitForChild("Equip"))
    SkinSystem.idleAnim = SkinSystem.animator:LoadAnimation(animFolder:WaitForChild("Idle"))
    SkinSystem.inspectAnim = SkinSystem.animator:LoadAnimation(animFolder:WaitForChild("Inspect"))
    SkinSystem.HeavySwingAnim = SkinSystem.animator:LoadAnimation(animFolder:WaitForChild("Heavy Swing"))
    SkinSystem.Swing1Anim = SkinSystem.animator:LoadAnimation(animFolder:WaitForChild("Swing1"))
    SkinSystem.Swing2Anim = SkinSystem.animator:LoadAnimation(animFolder:WaitForChild("Swing2"))

    SkinSystem.vm:SetPrimaryPartCFrame(Camera.CFrame * CFrame.new(0, -1.5, 5))
    TweenService:Create(SkinSystem.vm.PrimaryPart, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = Camera.CFrame * knifeOffset}):Play()
    SkinSystem.equipAnim:Play(); playSound("Equip", "1")
    ContextActionService:BindAction("InspectKnifeAction", handleAction, false, Enum.KeyCode.F)
    ContextActionService:BindAction("AttackKnifeAction", handleAction, false, Enum.UserInputType.MouseButton1)
end

local function applyWeaponSkin(model)
    if not model or not Config.Skins.SkinChangerEnabled or not IsAlive() then return end
    local skinName = Config.Skins.SelectedSkins[model.Name]
    if not skinName then return end
    pcall(function()
        local skinFolder = SkinsFolder:FindFirstChild(model.Name)
        if not skinFolder then return end
        local skinType = skinFolder:FindFirstChild(skinName)
        local sourceFolder = skinType and skinType:FindFirstChild("Camera") and skinType.Camera:FindFirstChild("Factory New")
        if not sourceFolder then return end

        for _, obj in Camera:GetChildren() do
            local left = obj:FindFirstChild("Left Arm"); local right = obj:FindFirstChild("Right Arm")
            if left or right then
                local gloveFolder = SkinsFolder:FindFirstChild("Sports Gloves")
                local gloveSkin = gloveFolder and gloveFolder:FindFirstChild(Config.Skins.SelectedSkins["Sports Gloves"])
                local gloveSource = gloveSkin and gloveSkin:FindFirstChild("Camera") and gloveSkin.Camera:FindFirstChild("Factory New")
                if gloveSource then
                    for _, side in {"Left Arm", "Right Arm"} do
                        local arm = obj:FindFirstChild(side); local src = gloveSource:FindFirstChild(side)
                        if arm and src then
                            local gloveMesh = arm:FindFirstChild("Glove")
                            if gloveMesh then
                                local existing = gloveMesh:FindFirstChildOfClass("SurfaceAppearance")
                                if existing then existing:Destroy() end
                                local clone = src:Clone(); clone.Name = "SurfaceAppearance"; clone.Parent = gloveMesh
                            end
                        end
                    end
                end
            end
        end

        if not GLOVES[model.Name] then
            local weaponFolder = model:FindFirstChild("Weapon")
            if weaponFolder then
                for _, part in weaponFolder:GetDescendants() do
                    if part:IsA("BasePart") then
                        local newSkin = sourceFolder:FindFirstChild(part.Name)
                        if newSkin then
                            local existing = part:FindFirstChildOfClass("SurfaceAppearance")
                            if existing then existing:Destroy() end
                            local clone = newSkin:Clone(); clone.Name = "SurfaceAppearance"; clone.Parent = part
                        end
                    end
                end
            end
        end
        model:SetAttribute("SkinApplied", skinName)
    end)
end

-- WEATHER
local WeatherPart = nil
local WeatherEmitter = nil
local function UpdateWeather(wType)
    if WeatherPart then WeatherPart:Destroy(); WeatherPart = nil end
    WeatherEmitter = nil
    if wType == "None" then return end
    WeatherPart = Instance.new("Part"); WeatherPart.Name = "Eclipse_Weather"; WeatherPart.Size = Vector3.new(100,1,100)
    WeatherPart.Transparency = 1; WeatherPart.Anchored = true; WeatherPart.CanCollide = false; WeatherPart.Parent = Camera
    WeatherEmitter = Instance.new("ParticleEmitter"); WeatherEmitter.Name = "EclipseWeatherEmitter"; WeatherEmitter.Parent = WeatherPart; WeatherEmitter.EmissionDirection = Enum.NormalId.Bottom
    if wType == "Rain" then
        WeatherEmitter.Texture = "rbxassetid://241868005"; WeatherEmitter.Rate = 10000; WeatherEmitter.Color = ColorSequence.new(Color3.fromRGB(200,200,200))
        WeatherEmitter.Size = NumberSequence.new(3,6); WeatherEmitter.Lifetime = NumberRange.new(2,2.5); WeatherEmitter.Speed = NumberRange.new(80,100); WeatherEmitter.Acceleration = Vector3.new(0,-50,0)
    elseif wType == "Snow" then
        WeatherEmitter.Texture = "rbxassetid://99851851"; WeatherEmitter.Rate = 200; WeatherEmitter.Color = ColorSequence.new(Color3.fromRGB(255,255,255))
        WeatherEmitter.Size = NumberSequence.new(0.25,0.35); WeatherEmitter.Speed = NumberRange.new(30,30); WeatherEmitter.Lifetime = NumberRange.new(5,10); WeatherEmitter.SpreadAngle = Vector2.new(50,50)
    elseif wType == "Hell Fire" then
        WeatherEmitter.Texture = "rbxassetid://242205518"; WeatherEmitter.Rate = 400; WeatherEmitter.Color = ColorSequence.new(Color3.fromRGB(255,100,0), Color3.fromRGB(150,0,0))
        WeatherEmitter.Size = NumberSequence.new(2,4); WeatherEmitter.Speed = NumberRange.new(40,60); WeatherEmitter.Lifetime = NumberRange.new(2,3); WeatherEmitter.Acceleration = Vector3.new(0,-10,0)
    end
end

connectSignal(Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        QueuePlayerMessage(player, true)
    end
end))

connectSignal(Players.PlayerRemoving:Connect(function(player)
    if player ~= LocalPlayer then
        QueuePlayerMessage(player, false)
    end
    if ESPObjects[player] then
        for _, line in pairs(ESPObjects[player].CornerLines) do line.Visible = false end
        ESPObjects[player].NameTag.Visible = false; ESPObjects[player].DistTag.Visible = false
        ESPObjects[player].HealthBg.Visible = false; ESPObjects[player].HealthFill.Visible = false
        ESPObjects[player] = nil
    end
end))

task.spawn(function()
    UpdateFriendList()
    while scriptRunning do
        task.wait(60)
        UpdateFriendList()
    end
end)

-- MAIN LOOP
connectSignal(RunService.RenderStepped:Connect(function()
    if not scriptRunning then return end
    updateESP(); updateAimbot(); updateTriggerBot(); updateMovement()

    if SkinSystem.scriptRunning and SkinSystem.vm and SkinSystem.vm.PrimaryPart then
        SkinSystem.vm.PrimaryPart.CFrame = Camera.CFrame * knives[Config.Skins.SelectedKnife].Offset
        if not SkinSystem.inspecting and not SkinSystem.swinging then
            if SkinSystem.idleAnim and not SkinSystem.idleAnim.IsPlaying then SkinSystem.idleAnim:Play() end
        end
    end
    
    if WeatherPart then
        WeatherPart.CFrame = Camera.CFrame * CFrame.new(0, 30, 0)
    end
end))

task.spawn(function()
    while scriptRunning do
        task.wait(0.1)
    end
end)

task.spawn(function()
    while scriptRunning do
        task.wait(0.5)
        if Config.Skins.SkinChangerEnabled and IsAlive() then
            for _, obj in Camera:GetChildren() do
                if Config.Skins.SelectedSkins[obj.Name] and obj:GetAttribute("SkinApplied") ~= Config.Skins.SelectedSkins[obj.Name] then applyWeaponSkin(obj) end
            end
        end
    end
end)

task.spawn(function()
    while scriptRunning do
        local living = IsAlive()
        local currentKnife = Camera:FindFirstChild("T Knife") or Camera:FindFirstChild("CT Knife")
        if SkinSystem.scriptRunning and living and currentKnife and not SkinSystem.spawned then
            spawnViewmodel(currentKnife)
        elseif (not SkinSystem.scriptRunning or not currentKnife or not living) and SkinSystem.spawned then
            removeViewmodel()
        end
        task.wait(0.1)
    end
end)

connectSignal(Camera.ChildAdded:Connect(function(obj)
    if not scriptRunning then return end
    if Config.Skins.SkinChangerEnabled and IsAlive() then task.wait(0.1); applyWeaponSkin(obj) end
end))


-- ==================== GUI SETUP (OBSIDIAN + SAFE DROPDOWNS) ====================
local AimTab = Window:AddTab("AIM", "crosshair")
local VisualsTab = Window:AddTab("VISUALS", "eye")
local SkinsTab = Window:AddTab("SKINS", "swords")
local MovementTab = Window:AddTab("MOVEMENT", "move")
local WorldTab = Window:AddTab("WORLD", "globe")
local MiscTab = Window:AddTab("MISC", "settings")
local GeneralTab = Window:AddTab("GENERAL", "settings")

-- AIM TAB
local MainGroup = AimTab:AddLeftGroupbox("GLOBAL CONTROLS")
MainGroup:AddToggle("Global_Enable", {Text = "GLOBAL ENABLE", Default = true, Callback = function(v) Config.GlobalEnable = v end})
MainGroup:AddToggle("Team_Check", {Text = "TEAM CHECK", Default = false, Callback = function(v) Config.TeamCheck = v end})

local AimGroup = AimTab:AddRightGroupbox("AIMBOT")
AimGroup:AddToggle("Aimbot_Toggle", {Text = "ENABLE AIMBOT", Default = false, Callback = function(v) Config.Aimbot.Enabled = v end})
AimGroup:AddSlider("Aimbot_FOV", {Text = "FOV", Default = 150, Min = 50, Max = 200, Rounding = 0, Callback = function(v) Config.Aimbot.FOV = v end})
AimGroup:AddSlider("Aimbot_Smooth", {Text = "SMOOTHNESS", Default = 5, Min = 1, Max = 20, Rounding = 0, Callback = function(v) Config.Aimbot.Smoothness = v end})
SafeAddDropdown(AimGroup, "Aimbot_Part", {Text = "TARGET PART", Values = {"Head", "Neck", "Arms", "Legs"}, Default = "Head", Callback = function(v) Config.Aimbot.TargetPart = v end})
AimGroup:AddToggle("Aimbot_DrawFOV", {Text = "DRAW AIM FOV", Default = true, Callback = function(v) Config.Aimbot.DrawFOV = v end})
AimGroup:AddToggle("Aimbot_Vis", {Text = "VISIBILITY CHECK", Default = true, Callback = function(v) Config.Aimbot.VisibilityCheck = v end})

local TriggerGroup = AimTab:AddLeftGroupbox("TRIGGER BOT")
TriggerGroup:AddToggle("Trigger_Toggle", {Text = "ENABLE TRIGGER", Default = false, Callback = function(v) Config.TriggerBot.Enabled = v end})
local triggerDelaySlider = TriggerGroup:AddSlider("Trigger_Delay", {Text = "DELAY", Default = 0.01, Min = 0.01, Max = 0.5, Rounding = 2, Callback = function(v) Config.TriggerBot.Delay = v end})
local triggerHitChanceSlider = TriggerGroup:AddSlider("Trigger_HitChance", {Text = "HIT CHANCE (%)", Default = 100, Min = 1, Max = 100, Rounding = 0, Callback = function(v) Config.TriggerBot.HitChance = v end})
local triggerSpreadSlider = TriggerGroup:AddSlider("Trigger_Spread", {Text = "SPREAD", Default = 0, Min = 0, Max = 10, Rounding = 0, Callback = function(v) Config.TriggerBot.Spread = v end})
local function UpdateTriggerModeUI(mode)
    if mode == "NoSpread" then
        Config.TriggerBot.HitChance = 100
        Config.TriggerBot.Spread = 0
        Config.TriggerBot.Delay = 0.01
        if triggerHitChanceSlider then triggerHitChanceSlider:SetValue(100); triggerHitChanceSlider:SetDisabled(true) end
        if triggerSpreadSlider then triggerSpreadSlider:SetValue(0); triggerSpreadSlider:SetDisabled(true) end
        if triggerDelaySlider then triggerDelaySlider:SetValue(0.01); triggerDelaySlider:SetDisabled(true) end
    else
        if triggerHitChanceSlider then triggerHitChanceSlider:SetDisabled(false) end
        if triggerSpreadSlider then triggerSpreadSlider:SetDisabled(false) end
        if triggerDelaySlider then triggerDelaySlider:SetDisabled(false) end
    end
end
local triggerModeDropdown = SafeAddDropdown(TriggerGroup, "Trigger_Mode", {Text = "MODE", Values = {"HitChance", "NoSpread"}, Default = "HitChance", Callback = function(v)
    Config.TriggerBot.Mode = v
    if v == "NoSpread" then Config.TriggerBot.HitChance = 100; Config.TriggerBot.Spread = 0; Config.TriggerBot.Delay = 0.01 end
    UpdateTriggerModeUI(v)
end})
UpdateTriggerModeUI(Config.TriggerBot.Mode)

-- VISUALS TAB
local ESPGroup = VisualsTab:AddLeftGroupbox("ESP SETTINGS")
ESPGroup:AddToggle("ESP_Toggle", {Text = "ENABLE ESP", Default = false, Callback = function(v) Config.ESP.Enabled = v end})
ESPGroup:AddToggle("ESP_Box", {Text = "CORNER BOX", Default = true, Callback = function(v) Config.ESP.CornerBox = v end})
ESPGroup:AddToggle("ESP_Name", {Text = "NAMES", Default = true, Callback = function(v) Config.ESP.Name = v end})
ESPGroup:AddToggle("ESP_Distance", {Text = "DISTANCE", Default = true, Callback = function(v) Config.ESP.Distance = v end})
ESPGroup:AddToggle("ESP_HP", {Text = "HEALTH BAR", Default = true, Callback = function(v) Config.ESP.HealthBar = v end})
ESPGroup:AddToggle("ESP_Target", {Text = "TARGET LINE", Default = true, Callback = function(v) Config.ESP.TargetLine = v end})
SafeAddDropdown(ESPGroup, "ESP_Pos", {Text = "TEXT POSITION", Options = {"Top", "Bottom"}, Default = "Top", Callback = function(v) Config.ESP.Position = v end})

-- SKINS TAB (CARREGAMENTO TARDIO PARA EVITAR BUGS)
local SkinGroup = SkinsTab:AddLeftGroupbox("SKIN CHANGER")
SkinGroup:AddToggle("Skin_Toggle", {Text = "ENABLE SKIN CHANGER", Default = false, Callback = function(v) Config.Skins.SkinChangerEnabled = v end})
SkinGroup:AddToggle("Knife_Toggle", {Text = "CUSTOM KNIFE", Default = false, Callback = function(v) SkinSystem.scriptRunning = v; if not v then removeViewmodel() end end})
SafeAddDropdown(SkinGroup, "Knife_Select", {Text = "SELECT KNIFE", Options = {"Butterfly Knife", "Karambit", "M9 Bayonet", "Flip Knife", "Gut Knife"}, Default = "Butterfly Knife", Callback = function(v) Config.Skins.SelectedKnife = v; if SkinSystem.spawned then removeViewmodel() end end})

local function CreateSkinDropdown(weaponName, section)
    local folder = SkinsFolder:FindFirstChild(weaponName)
    if not folder then return end
    local options = {}
    for _, skin in folder:GetChildren() do 
        if skin.Name and skin.Name ~= "" then table.insert(options, skin.Name) end 
    end
    if #options == 0 then return end -- Protecao contra pasta vazia
    if not Config.Skins.SelectedSkins[weaponName] then Config.Skins.SelectedSkins[weaponName] = options[1] end
    SafeAddDropdown(section, "Skin_" .. weaponName, {Text = weaponName, Options = options, Default = Config.Skins.SelectedSkins[weaponName], Callback = function(v) Config.Skins.SelectedSkins[weaponName] = v end})
end

local SkinsKnivesSection = SkinsTab:AddLeftGroupbox("KNIVES SKINS")
for name in pairs(KNIVES) do CreateSkinDropdown(name, SkinsKnivesSection) end
local SkinsGlovesSection = SkinsTab:AddRightGroupbox("GLOVES")
for name in pairs(GLOVES) do CreateSkinDropdown(name, SkinsGlovesSection) end
local SkinsCTSection = SkinsTab:AddLeftGroupbox("CT WEAPONS")
for name in pairs(CT_ONLY) do CreateSkinDropdown(name, SkinsCTSection) end
local SkinsSharedSection = SkinsTab:AddRightGroupbox("SHARED WEAPONS")
for name in pairs(SHARED) do CreateSkinDropdown(name, SkinsSharedSection) end
for _, folder in SkinsFolder:GetChildren() do
    local n = folder.Name
    if not IgnoreFolders[n] and not KNIVES[n] and not GLOVES[n] and not CT_ONLY[n] and not SHARED[n] then CreateSkinDropdown(n, SkinsSharedSection) end
end

-- MOVEMENT TAB
local MoveGroup = MovementTab:AddLeftGroupbox("MOVEMENT", nil, true, true)
MoveGroup:AddToggle("Bhop_Toggle", {Text = "BUNNY HOP", Default = false, Callback = function(v) Config.Movement.BunnyHop = v end})
MoveGroup:AddToggle("Strafe_Toggle", {Text = "AUTO STRAFE", Default = false, Callback = function(v) Config.Movement.AutoStrafe = v end})
MoveGroup:AddSlider("Strafe_Speed", {Text = "STRAFE SPEED", Default = 1.0, Min = 0.1, Max = 1.5, Rounding = 2, Callback = function(v) Config.Movement.StrafeSpeed = v end})

-- WORLD TAB
local WorldGroup = WorldTab:AddLeftGroupbox("ENVIRONMENT", nil, true, true)
SafeAddDropdown(WorldGroup, "Weather_Select", {Text = "WEATHER", Values = {"None", "Rain", "Snow", "Hell Fire"}, Default = "None", Callback = function(v) Config.World.Weather = v; UpdateWeather(v) end})

-- MISC TAB
local MiscGroup = MiscTab:AddLeftGroupbox("MISCELLANEOUS", nil, true, true)
MiscGroup:AddToggle("ChatLogging_Toggle", {Text = "CHAT LOGGING", Default = true, Callback = function(v) Config.Misc.ChatNotifications = v end})

-- GENERAL TAB
local GeneralGroup = GeneralTab:AddLeftGroupbox("GENERAL")
GeneralGroup:AddButton({Text = "UNLOAD", Func = function()
    Notify("Hooks Unloaded", "success")
    CleanupScript()
    removeViewmodel()
    getgenv().EclipseHubLoaded = nil
    pcall(function() Library:Unload() end)
end})

GeneralGroup:AddButton({Text = "SUICIDE", Func = function()
    LocalPlayer:Kick("")
end})

-- INITIALIZATION
UpdateWeather(Config.World.Weather)
EnableEclipseCloak(true)