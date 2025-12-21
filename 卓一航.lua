local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StatsService = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Config = {
    Sensitivity = 0, 
    LockMode = "Character", 
    AimPart = "Torso", 
    PredictionEnabled = false,
    SmartPrediction = false,
    PredictionAmount = 0.165,
    ProjectileSpeed = 1000,
    GravityCorrection = 0,
    AccelerationPrediction = false,
    TeamCheck = false,
    CoverCheck = false,
    ContinuousLock = false, 
    MaxDistance = 2000,
    UseFOV = false,
    FOVVisible = false,
    FOVRadius = 130,
    FixedFOV = false,
    FOVColor = Color3.fromRGB(255, 255, 255),
    BoxVisible = false,
    BoxColor = Color3.fromRGB(255, 255, 255),
    RingColor = Color3.fromRGB(255, 255, 255),
    RainbowFOV = false,
    RainbowBox = false,
    RainbowRing = false,
    WhitelistEnabled = false,
    BlacklistEnabled = false,
    Whitelist = {},
    Blacklist = {},
    PriorityMode = "Crosshair",
    DynamicSwitching = false,
    BoxSize = 5.5,
    BoxThickness = 1,
    BoxSpeed = 1,
    BoxTransparency = 0,
    LegitMode = false,
    AimOffset = 0,
    ShakePower = 0,
    MissChance = 0,
    SmoothnessCurve = "Linear",
    ReactionDelay = 0,
    NotificationEnabled = true,
    NotificationDuration = 2.5,
    TextLocked = "已锁定",
    TextUnlocked = "已解锁",
    TextLost = "目标丢失"
}

local TargetState = {
    Velocity = Vector3.zero,
    Acceleration = Vector3.zero,
    LastUpdate = 0
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PureLockSystem"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if game:GetService("CoreGui") then
    pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "DynamicIsland"
NotificationContainer.Size = UDim2.new(0, 0, 0, 35)
NotificationContainer.Position = UDim2.new(0.5, 0, 0, 10)
NotificationContainer.AnchorPoint = Vector2.new(0.5, 0)
NotificationContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
NotificationContainer.BackgroundTransparency = 0.1
NotificationContainer.ClipsDescendants = true
NotificationContainer.ZIndex = 100
NotificationContainer.Parent = ScreenGui
Instance.new("UICorner", NotificationContainer).CornerRadius = UDim.new(1, 0)

local NotifyDot = Instance.new("Frame", NotificationContainer)
NotifyDot.Size = UDim2.new(0, 8, 0, 8)
NotifyDot.Position = UDim2.new(0, 12, 0.5, 0)
NotifyDot.AnchorPoint = Vector2.new(0, 0.5)
NotifyDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", NotifyDot).CornerRadius = UDim.new(1, 0)

local NotifyLabel = Instance.new("TextLabel", NotificationContainer)
NotifyLabel.Size = UDim2.new(0, 0, 1, 0)
NotifyLabel.Position = UDim2.new(0, 28, 0, 0)
NotifyLabel.BackgroundTransparency = 1
NotifyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
NotifyLabel.TextTransparency = 1
NotifyLabel.Font = Enum.Font.GothamBold
NotifyLabel.TextSize = 12
NotifyLabel.TextXAlignment = Enum.TextXAlignment.Left
NotifyLabel.AutomaticSize = Enum.AutomaticSize.X

local function ShowNotification(title, type)
    if not ScreenGui.Parent or not Config.NotificationEnabled then return end
    
    NotifyLabel.Text = title
    local bounds = game:GetService("TextService"):GetTextSize(title, 12, Enum.Font.GothamBold, Vector2.new(1000, 35))
    local targetWidth = bounds.X + 45
    
    local dotColor = Color3.fromRGB(255, 255, 255)
    if type == "Lock" then dotColor = Color3.fromRGB(0, 255, 100)
    elseif type == "Unlock" then dotColor = Color3.fromRGB(255, 50, 50)
    elseif type == "Warn" then dotColor = Color3.fromRGB(255, 200, 50) end
    NotifyDot.BackgroundColor3 = dotColor

    NotificationContainer.Size = UDim2.new(0, 0, 0, 35)
    NotifyLabel.TextTransparency = 1
    NotifyDot.BackgroundTransparency = 1
    
    local t1 = TweenService:Create(NotificationContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, targetWidth, 0, 35)})
    local t2 = TweenService:Create(NotifyLabel, TweenInfo.new(0.3), {TextTransparency = 0})
    local t3 = TweenService:Create(NotifyDot, TweenInfo.new(0.3), {BackgroundTransparency = 0})
    
    t1:Play()
    task.wait(0.2)
    t2:Play()
    t3:Play()
    
    task.delay(Config.NotificationDuration, function()
        TweenService:Create(NotifyLabel, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        TweenService:Create(NotifyDot, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        task.wait(0.2)
        TweenService:Create(NotificationContainer, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 35)}):Play()
    end)
end

local ClickOverlay = Instance.new("TextButton")
ClickOverlay.Name = "ClickOverlay"
ClickOverlay.Size = UDim2.new(1, 0, 1, 0)
ClickOverlay.BackgroundTransparency = 1
ClickOverlay.Text = ""
ClickOverlay.Visible = false
ClickOverlay.ZIndex = 0 
ClickOverlay.Parent = ScreenGui

local FOVCircleGui = Instance.new("ScreenGui")
FOVCircleGui.Name = "FOVCircleGui"
FOVCircleGui.ResetOnSpawn = false
FOVCircleGui.IgnoreGuiInset = true
FOVCircleGui.Parent = ScreenGui.Parent

local FOVCircleFrame = Instance.new("Frame", FOVCircleGui)
FOVCircleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircleFrame.BackgroundTransparency = 1
FOVCircleFrame.Visible = false
FOVCircleFrame.Size = UDim2.fromOffset(Config.FOVRadius*2, Config.FOVRadius*2)
local FOVStroke = Instance.new("UIStroke", FOVCircleFrame)
FOVStroke.Thickness = 1
FOVStroke.Transparency = 0.6
Instance.new("UICorner", FOVCircleFrame).CornerRadius = UDim.new(1, 0)

local MainButton = Instance.new("TextButton")
MainButton.Name = "LookButton"
MainButton.Size = UDim2.new(0, 40, 0, 40)
MainButton.Position = UDim2.new(0.8, -20, 0.6, -20)
MainButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainButton.Text = "AIM"
MainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MainButton.Font = Enum.Font.GothamBold
MainButton.TextSize = 10
MainButton.AutoButtonColor = false
MainButton.Parent = ScreenGui
Instance.new("UICorner", MainButton).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", MainButton).Color = Color3.fromRGB(60, 60, 60)
Instance.new("UIStroke", MainButton).Thickness = 1

local LockRing = Instance.new("Frame")
LockRing.Size = UDim2.new(1.3, 0, 1.3, 0)
LockRing.Position = UDim2.new(0.5, 0, 0.5, 0)
LockRing.AnchorPoint = Vector2.new(0.5, 0.5)
LockRing.BackgroundTransparency = 1
LockRing.Visible = false
LockRing.Parent = MainButton
local RingStroke = Instance.new("UIStroke", LockRing)
RingStroke.Thickness = 1
RingStroke.Color = Config.RingColor
Instance.new("UICorner", LockRing).CornerRadius = UDim.new(1, 0)

local ProgressBarBg = Instance.new("Frame")
ProgressBarBg.Size = UDim2.new(1.5, 0, 0, 2)
ProgressBarBg.Position = UDim2.new(0.5, 0, 1.4, 0)
ProgressBarBg.AnchorPoint = Vector2.new(0.5, 0)
ProgressBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ProgressBarBg.BorderSizePixel = 0
ProgressBarBg.Visible = false
ProgressBarBg.Parent = MainButton

local ProgressBarFill = Instance.new("Frame")
ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ProgressBarFill.BorderSizePixel = 0
ProgressBarFill.Parent = ProgressBarBg

local ConfirmContainer = Instance.new("Frame", MainButton)
ConfirmContainer.Size = UDim2.new(2.4, 0, 0.8, 0)
ConfirmContainer.Position = UDim2.new(0.5, 0, 1.15, 0)
ConfirmContainer.AnchorPoint = Vector2.new(0.5, 0)
ConfirmContainer.BackgroundTransparency = 1
ConfirmContainer.Visible = false

local ConfirmBtn = Instance.new("TextButton", ConfirmContainer)
ConfirmBtn.Size = UDim2.new(0.45, 0, 1, 0)
ConfirmBtn.BackgroundColor3 = Color3.fromRGB(30, 160, 60)
ConfirmBtn.Text = "保存"
ConfirmBtn.Font = Enum.Font.GothamBold
ConfirmBtn.TextSize = 10
ConfirmBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", ConfirmBtn).CornerRadius = UDim.new(0, 4)

local CancelBtn = Instance.new("TextButton", ConfirmContainer)
CancelBtn.Size = UDim2.new(0.45, 0, 1, 0)
CancelBtn.Position = UDim2.new(0.55, 0, 0, 0)
CancelBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
CancelBtn.Text = "取消"
CancelBtn.Font = Enum.Font.GothamBold
CancelBtn.TextSize = 10
CancelBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", CancelBtn).CornerRadius = UDim.new(0, 4)

local SettingsPanel = Instance.new("Frame")
SettingsPanel.AnchorPoint = Vector2.new(0.5, 0.5)
SettingsPanel.Size = UDim2.new(0, 0, 0, 0)
SettingsPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
SettingsPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SettingsPanel.BorderSizePixel = 0
SettingsPanel.Visible = false
SettingsPanel.ClipsDescendants = true
SettingsPanel.ZIndex = 2
SettingsPanel.Parent = ScreenGui
Instance.new("UICorner", SettingsPanel).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", SettingsPanel).Color = Color3.fromRGB(50, 50, 50)
Instance.new("UIStroke", SettingsPanel).Thickness = 1

local PanelContent = Instance.new("Frame", SettingsPanel)
PanelContent.Size = UDim2.new(1, 0, 1, 0)
PanelContent.BackgroundTransparency = 1

local SideBar = Instance.new("Frame", PanelContent)
SideBar.Size = UDim2.new(0.22, 0, 1, 0)
SideBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
SideBar.BorderSizePixel = 0
local SideLayout = Instance.new("UIListLayout", SideBar)
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Padding = UDim.new(0, 2)
local SidePadding = Instance.new("UIPadding", SideBar)
SidePadding.PaddingTop = UDim.new(0, 8)
SidePadding.PaddingLeft = UDim.new(0, 8)
SidePadding.PaddingRight = UDim.new(0, 8)

local MainArea = Instance.new("Frame", PanelContent)
MainArea.Size = UDim2.new(0.78, 0, 1, 0)
MainArea.Position = UDim2.new(0.22, 0, 0, 0)
MainArea.BackgroundTransparency = 1
local MainPadding = Instance.new("UIPadding", MainArea)
MainPadding.PaddingTop = UDim.new(0, 12)
MainPadding.PaddingLeft = UDim.new(0, 12)
MainPadding.PaddingRight = UDim.new(0, 12)

local TooltipFrame = Instance.new("Frame", ScreenGui)
TooltipFrame.Size = UDim2.new(0, 220, 0, 50)
TooltipFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TooltipFrame.BackgroundTransparency = 1 
TooltipFrame.Visible = false
TooltipFrame.ZIndex = 20
Instance.new("UICorner", TooltipFrame).CornerRadius = UDim.new(0, 4)
local TooltipStroke = Instance.new("UIStroke", TooltipFrame)
TooltipStroke.Color = Color3.fromRGB(80, 80, 80)
TooltipStroke.Transparency = 1
local TooltipText = Instance.new("TextLabel", TooltipFrame)
TooltipText.Size = UDim2.new(1, -12, 1, -8)
TooltipText.Position = UDim2.new(0, 6, 0, 4)
TooltipText.BackgroundTransparency = 1
TooltipText.TextColor3 = Color3.fromRGB(220, 220, 220)
TooltipText.TextTransparency = 1
TooltipText.TextWrapped = true
TooltipText.Font = Enum.Font.Gotham
TooltipText.TextSize = 10
TooltipText.TextXAlignment = Enum.TextXAlignment.Left
TooltipText.TextYAlignment = Enum.TextYAlignment.Center

local function ToggleTooltip(btn, text)
    if TooltipFrame.Visible and TooltipFrame.Position == UDim2.new(0, btn.AbsolutePosition.X + 25, 0, btn.AbsolutePosition.Y) then
        local t1 = TweenService:Create(TooltipFrame, TweenInfo.new(0.15), {BackgroundTransparency = 1})
        local t2 = TweenService:Create(TooltipText, TweenInfo.new(0.15), {TextTransparency = 1})
        local t3 = TweenService:Create(TooltipStroke, TweenInfo.new(0.15), {Transparency = 1})
        t1:Play(); t2:Play(); t3:Play()
        t1.Completed:Connect(function() TooltipFrame.Visible = false end)
    else
        TooltipText.Text = text
        TooltipFrame.Visible = true
        TooltipFrame.Position = UDim2.new(0, btn.AbsolutePosition.X + 25, 0, btn.AbsolutePosition.Y)
        TweenService:Create(TooltipFrame, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
        TweenService:Create(TooltipText, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
        TweenService:Create(TooltipStroke, TweenInfo.new(0.15), {Transparency = 0.5}):Play()
    end
end

local Pages = {}
local CurrentPage = nil

local function CreatePage(name)
    local P = Instance.new("ScrollingFrame", MainArea)
    P.Name = name .. "Page"
    P.Size = UDim2.new(1, 0, 1, 0)
    P.BackgroundTransparency = 1
    P.ScrollBarThickness = 2
    P.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
    P.Visible = false
    P.AutomaticCanvasSize = Enum.AutomaticSize.Y
    P.CanvasSize = UDim2.new(0,0,0,0)
    local L = Instance.new("UIListLayout", P)
    L.SortOrder = Enum.SortOrder.LayoutOrder
    L.Padding = UDim.new(0, 6)
    Pages[name] = P
    return P
end

local function SwitchPage(name)
    for n, p in pairs(Pages) do p.Visible = (n == name) end
end

local function CreateTab(text, pageName)
    local Btn = Instance.new("TextButton", SideBar)
    Btn.Size = UDim2.new(1, 0, 0, 28)
    Btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 10
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    
    Btn.MouseButton1Click:Connect(function()
        for _, b in pairs(SideBar:GetChildren()) do
            if b:IsA("TextButton") then
                TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 25, 25), TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
            end
        end
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 40), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        CurrentPage = pageName
        SwitchPage(pageName)
    end)
end

local function CreateSection(text, parent)
    local L = Instance.new("TextLabel", parent)
    L.Text = string.upper(text)
    L.Size = UDim2.new(1, 0, 0, 24)
    L.BackgroundTransparency = 1
    L.TextColor3 = Color3.fromRGB(100, 100, 100)
    L.Font = Enum.Font.GothamBold
    L.TextSize = 9
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.TextYAlignment = Enum.TextYAlignment.Bottom
    return L
end

local function CreateHelpBtn(parent, desc)
    local Btn = Instance.new("TextButton", parent)
    Btn.Size = UDim2.new(0, 16, 0, 16)
    Btn.Position = UDim2.new(1, -16, 0, 0)
    Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Btn.Text = "?"
    Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    Btn.TextSize = 9
    Btn.AutoButtonColor = false
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    Btn.MouseButton1Click:Connect(function() ToggleTooltip(Btn, desc) end)
    return Btn
end

local function CreateSlider(name, desc, parent, min, max, default, callback, smartOverride)
    local C = Instance.new("Frame", parent)
    C.Size = UDim2.new(1, 0, 0, 36)
    C.BackgroundTransparency = 1
    
    local Title = Instance.new("TextLabel", C)
    Title.Text = name
    Title.Size = UDim2.new(0.5, 0, 0.5, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(200, 200, 200)
    Title.Font = Enum.Font.GothamMedium
    Title.TextSize = 10
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    local InputBox = Instance.new("TextBox", C)
    InputBox.Text = tostring(default)
    InputBox.Size = UDim2.new(0.3, 0, 0.5, 0)
    InputBox.Position = UDim2.new(0.55, 0, 0, 0)
    InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    InputBox.Font = Enum.Font.GothamBold
    InputBox.TextSize = 9
    InputBox.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 4)
    
    CreateHelpBtn(C, desc)
    
    local BG = Instance.new("Frame", C)
    BG.Size = UDim2.new(1, 0, 0, 2)
    BG.Position = UDim2.new(0, 0, 0.8, 0)
    BG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    BG.BorderSizePixel = 0
    
    local Fill = Instance.new("Frame", BG)
    Fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    Fill.BorderSizePixel = 0
    
    local Btn = Instance.new("TextButton", BG)
    Btn.Size = UDim2.new(1, 0, 2, 0)
    Btn.Position = UDim2.new(0,0,-0.5,0)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""
    
    local function UpdateVal(v)
        local clamped = math.clamp(v, min, max)
        local p = math.clamp((clamped - min)/(max-min), 0, 1)
        Fill.Size = UDim2.new(p, 0, 1, 0)
        InputBox.Text = string.format("%.2f", clamped)
    end
    
    InputBox.FocusLost:Connect(function()
        local n = tonumber(InputBox.Text)
        if n then
            local clamped = math.clamp(n, min, max)
            UpdateVal(clamped)
            callback(clamped)
        else
            InputBox.Text = string.format("%.2f", Config[name] or default)
        end
    end)

    local dragging = false
    Btn.InputBegan:Connect(function(i) 
        if smartOverride and Config.SmartPrediction then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true end 
    end)
    UserInputService.InputChanged:Connect(function(i) 
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then 
            local pos = math.clamp((i.Position.X - BG.AbsolutePosition.X) / BG.AbsoluteSize.X, 0, 1)
            local value = min + ((max - min) * pos)
            UpdateVal(value)
            callback(value)
        end 
    end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    
    if smartOverride then
        RunService.RenderStepped:Connect(function()
            if Config.SmartPrediction then
                BG.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                Fill.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                UpdateVal(Config.PredictionAmount)
            else
                BG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                Fill.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
            end
        end)
    end
end

local function CreateInputBox(name, desc, parent, defaultText, callback)
    local C = Instance.new("Frame", parent)
    C.Size = UDim2.new(1, 0, 0, 36)
    C.BackgroundTransparency = 1
    
    local Title = Instance.new("TextLabel", C)
    Title.Text = name
    Title.Size = UDim2.new(0.5, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(200, 200, 200)
    Title.Font = Enum.Font.GothamMedium
    Title.TextSize = 10
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    local Input = Instance.new("TextBox", C)
    Input.Text = defaultText
    Input.Size = UDim2.new(0.4, 0, 0.7, 0)
    Input.Position = UDim2.new(0.5, 0, 0.15, 0)
    Input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    Input.Font = Enum.Font.Gotham
    Input.TextSize = 10
    Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 4)
    
    CreateHelpBtn(C, desc)
    
    Input.FocusLost:Connect(function()
        callback(Input.Text)
    end)
end

local function CreateCycleButton(name, desc, parent, options, defaultIndex, callback)
    local C = Instance.new("Frame", parent)
    C.Size = UDim2.new(1, 0, 0, 30)
    C.BackgroundTransparency = 1
    
    CreateHelpBtn(C, desc)
    
    local Btn = Instance.new("TextButton", C)
    Btn.Size = UDim2.new(0.9, 0, 1, 0)
    Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 10
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.AutoButtonColor = false
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIPadding", Btn).PaddingLeft = UDim.new(0, 6)
    
    local currentIndex = defaultIndex
    if type(defaultIndex) == "string" then
        for i,v in ipairs(options) do if v == defaultIndex then currentIndex = i break end end
    end
    
    local function UpdateText()
        Btn.Text = name .. ":  " .. options[currentIndex]
    end
    
    Btn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex + 1
        if currentIndex > #options then currentIndex = 1 end
        UpdateText()
        TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
        task.delay(0.1, function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play() end)
        callback(options[currentIndex], currentIndex)
    end)
    
    UpdateText()
    return C
end

local function HexToColor(hex)
    hex = hex:gsub("#","")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1,2), 16)
    local g = tonumber(hex:sub(3,4), 16)
    local b = tonumber(hex:sub(5,6), 16)
    if r and g and b then
        return Color3.fromRGB(r,g,b)
    end
    return nil
end

local function CreateColorSystem(name, parent, defaultColor, configKey, rainbowKey)
    local C = Instance.new("Frame", parent)
    C.Size = UDim2.new(1, 0, 0, 100)
    C.BackgroundTransparency = 1
    
    local Header = Instance.new("TextLabel", C)
    Header.Text = name
    Header.Size = UDim2.new(1, 0, 0, 16)
    Header.BackgroundTransparency = 1
    Header.TextColor3 = Color3.fromRGB(200, 200, 200)
    Header.Font = Enum.Font.GothamBold
    Header.TextSize = 10
    Header.TextXAlignment = Enum.TextXAlignment.Left
    
    local Preview = Instance.new("Frame", C)
    Preview.Size = UDim2.new(0, 30, 0, 16)
    Preview.Position = UDim2.new(1, -60, 0, 0)
    Preview.BackgroundColor3 = defaultColor
    Instance.new("UICorner", Preview).CornerRadius = UDim.new(0, 4)
    
    local RainBtn = Instance.new("TextButton", C)
    RainBtn.Size = UDim2.new(0, 25, 0, 16)
    RainBtn.Position = UDim2.new(1, -25, 0, 0)
    RainBtn.Text = "RGB"
    RainBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    RainBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    RainBtn.TextSize = 8
    RainBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", RainBtn).CornerRadius = UDim.new(0, 4)
    
    RainBtn.MouseButton1Click:Connect(function()
        Config[rainbowKey] = not Config[rainbowKey]
        if Config[rainbowKey] then
             RainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
             RainBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        else
             RainBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
             RainBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
    end)
    
    local sliders = {}
    
    local function UpdateColorPreview()
        Preview.BackgroundColor3 = Config[configKey]
    end
    
    local function UpdateSliders()
        local c = Config[configKey]
        if sliders["R"] then sliders["R"](c.R * 255) end
        if sliders["G"] then sliders["G"](c.G * 255) end
        if sliders["B"] then sliders["B"](c.B * 255) end
    end
    
    local HexBox = Instance.new("TextBox", C)
    HexBox.Size = UDim2.new(0.3, 0, 0, 16)
    HexBox.Position = UDim2.new(0.35, 0, 0, 0)
    HexBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    HexBox.TextColor3 = Color3.fromRGB(200, 200, 200)
    HexBox.TextSize = 9
    HexBox.Font = Enum.Font.Gotham
    HexBox.Text = "#FFFFFF"
    HexBox.PlaceholderText = "HEX"
    Instance.new("UICorner", HexBox).CornerRadius = UDim.new(0, 4)
    
    HexBox.FocusLost:Connect(function()
        local col = HexToColor(HexBox.Text)
        if col then
            Config[configKey] = col
            UpdateColorPreview()
            UpdateSliders()
        end
    end)
    
    local function MakeRGB(cName, yOff, getC, setC)
        local S = Instance.new("Frame", C)
        S.Size = UDim2.new(1, 0, 0, 14)
        S.Position = UDim2.new(0, 0, 0, yOff)
        S.BackgroundTransparency = 1
        
        local L = Instance.new("TextLabel", S)
        L.Text = cName
        L.Size = UDim2.new(0, 10, 1, 0)
        L.BackgroundTransparency = 1
        L.TextColor3 = Color3.fromRGB(120, 120, 120)
        L.TextSize = 8
        L.Font = Enum.Font.GothamBold
        
        local Bar = Instance.new("Frame", S)
        Bar.Size = UDim2.new(0.85, 0, 0, 2)
        Bar.Position = UDim2.new(0.1, 0, 0.5, -1)
        Bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Bar.BorderSizePixel = 0
        
        local Fill = Instance.new("Frame", Bar)
        Fill.Size = UDim2.new(getC()/255, 0, 1, 0)
        Fill.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        Fill.BorderSizePixel = 0
        
        local Trig = Instance.new("TextButton", Bar)
        Trig.Size = UDim2.new(1, 0, 4, 0)
        Trig.Position = UDim2.new(0,0,-1.5,0)
        Trig.BackgroundTransparency = 1
        Trig.Text = ""
        
        local function SetVal(p)
             Fill.Size = UDim2.new(p, 0, 1, 0)
             setC(p*255)
             UpdateColorPreview()
             local c = Config[configKey]
             HexBox.Text = string.format("#%02X%02X%02X", c.R*255, c.G*255, c.B*255)
        end
        
        local dragging = false
        Trig.InputBegan:Connect(function(i) 
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true end 
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local p = math.clamp((i.Position.X - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X, 0, 1)
                SetVal(p)
            end
        end)
        UserInputService.InputEnded:Connect(function(i) 
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end 
        end)
        
        sliders[cName] = function(val)
            Fill.Size = UDim2.new(val/255, 0, 1, 0)
        end
    end
    
    MakeRGB("R", 20, function() return Config[configKey].R*255 end, function(v) local c = Config[configKey]; Config[configKey] = Color3.fromRGB(v, c.G*255, c.B*255) end)
    MakeRGB("G", 38, function() return Config[configKey].G*255 end, function(v) local c = Config[configKey]; Config[configKey] = Color3.fromRGB(c.R*255, v, c.B*255) end)
    MakeRGB("B", 56, function() return Config[configKey].B*255 end, function(v) local c = Config[configKey]; Config[configKey] = Color3.fromRGB(c.R*255, c.G*255, v) end)
    
    RunService.RenderStepped:Connect(function()
        if Config[rainbowKey] then
            Preview.BackgroundColor3 = Config[configKey]
        end
    end)
end

local P1 = CreatePage("Aim")
CreateSection("基础设置", P1)
CreateSlider("灵敏度", "控制准星跟随目标的平滑程度，数值越低越平滑，越高越生硬", P1, 0, 100, Config.Sensitivity, function(v) Config.Sensitivity = v end)
CreateCycleButton("锁定模式", "选择通过旋转角色身体还是仅移动相机视角来锁定", P1, {"人物", "镜头"}, Config.LockMode == "Character" and 1 or 2, function(o) Config.LockMode = (o == "人物") and "Character" or "Camera" end)
CreateCycleButton("瞄准部位", "自动锁定目标的身体部位", P1, {"躯干", "头部"}, Config.AimPart == "Torso" and 1 or 2, function(o) Config.AimPart = (o == "躯干") and "Torso" or "Head" end)
CreateCycleButton("锁定行为", "单次按下切换开关，或需要按住按键保持锁定", P1, {"单次", "连续"}, Config.ContinuousLock and 2 or 1, function(o) Config.ContinuousLock = (o == "连续") end)

CreateSection("高级逻辑", P1)
CreateCycleButton("目标优先级", "选择自动选取目标的逻辑：准星最近、血量最低或距离最近", P1, {"准星最近", "血量最低", "距离最近"}, 1, function(o) 
    if o == "准星最近" then Config.PriorityMode = "Crosshair"
    elseif o == "血量最低" then Config.PriorityMode = "Lowest Health"
    else Config.PriorityMode = "Closest Distance" end
end)
CreateCycleButton("动态切换", "当有更符合条件的目标出现时自动切换锁定对象", P1, {"关闭", "开启"}, Config.DynamicSwitching and 2 or 1, function(o) Config.DynamicSwitching = (o == "开启") end)

CreateSection("伪装模式", P1)
CreateCycleButton("启用伪装", "开启后模拟人类操作，减少被检测风险", P1, {"关闭", "开启"}, Config.LegitMode and 2 or 1, function(o) Config.LegitMode = (o == "开启") end)
CreateSlider("随机偏移", "在瞄准点周围增加随机抖动范围", P1, 0, 5, Config.AimOffset, function(v) Config.AimOffset = v end)
CreateSlider("手抖强度", "模拟鼠标手抖效果，增加不规则运动", P1, 0, 10, Config.ShakePower, function(v) Config.ShakePower = v end)
CreateSlider("失误概率", "随机停止锁定以模拟玩家失误(0-100%)", P1, 0, 100, Config.MissChance, function(v) Config.MissChance = v end)
CreateSlider("人类延迟", "锁定前的反应时间(秒)", P1, 0, 1, Config.ReactionDelay, function(v) Config.ReactionDelay = v end)
CreateCycleButton("平滑曲线", "准星移动的数学轨迹模型", P1, {"线性", "正弦", "二次方"}, 1, function(o) 
    if o == "线性" then Config.SmoothnessCurve = "Linear"
    elseif o == "正弦" then Config.SmoothnessCurve = "Sine"
    else Config.SmoothnessCurve = "Quad" end
end)

CreateSection("预判设置", P1)
CreateCycleButton("启用预判", "根据目标运动轨迹预测其未来位置", P1, {"关闭", "开启"}, 1, function(o) Config.PredictionEnabled = (o == "开启") end)
CreateCycleButton("预判类型", "自动计算或手动设置固定值", P1, {"手动", "自动"}, 1, function(o) Config.SmartPrediction = (o == "自动") end)
CreateSlider("预判数值", "手动预判系数(时间/距离)", P1, 0, 5, Config.PredictionAmount, function(v) if not Config.SmartPrediction then Config.PredictionAmount = v end end, true)
CreateCycleButton("加速度预测", "计算目标速度变化率以提高精准度", P1, {"关闭", "开启"}, 1, function(o) Config.AccelerationPrediction = (o == "开启") end)
CreateSlider("子弹速度", "武器子弹飞行速度(Studs/s)", P1, 100, 5000, Config.ProjectileSpeed, function(v) Config.ProjectileSpeed = v end)
CreateSlider("重力补偿", "针对子弹下坠的垂直补偿", P1, 0, 10, Config.GravityCorrection, function(v) Config.GravityCorrection = v end)

local P2 = CreatePage("Visuals")
CreateSection("视野范围", P2)
CreateCycleButton("FOV 限制", "仅锁定位于视野圈内的目标", P2, {"关闭", "开启"}, 1, function(o) Config.UseFOV = (o == "开启") end)
CreateCycleButton("显示 FOV", "在屏幕上绘制视野范围圆圈", P2, {"关闭", "开启"}, 1, function(o) 
    Config.FOVVisible = (o == "开启")
    FOVCircleFrame.Visible = Config.FOVVisible
    FOVCircleFrame.Size = UDim2.fromOffset(Config.FOVRadius*2, Config.FOVRadius*2)
end)
CreateSlider("FOV 半径", "视野圆圈的大小", P2, 10, 800, Config.FOVRadius, function(v) Config.FOVRadius = v; FOVCircleFrame.Size = UDim2.fromOffset(v*2, v*2) end)
CreateCycleButton("FOV 位置", "视野圈跟随鼠标或固定在屏幕中心", P2, {"跟随", "固定"}, 1, function(o) Config.FixedFOV = (o == "固定") end)

CreateSection("锁定框样式", P2)
CreateCycleButton("显示锁定框", "在锁定目标身上显示方框", P2, {"关闭", "开启"}, 1, function(o) Config.BoxVisible = (o == "开启") end)
CreateSlider("锁定框大小", "相对人物比例大小", P2, 1, 10, Config.BoxSize, function(v) Config.BoxSize = v end)
CreateSlider("线条粗细", "边框线条的厚度", P2, 1, 5, Config.BoxThickness, function(v) Config.BoxThickness = v end)
CreateSlider("旋转速度", "锁定框的旋转动画速度", P2, 0, 10, Config.BoxSpeed, function(v) Config.BoxSpeed = v end)
CreateSlider("透明度", "锁定框的可见度(1为完全隐形)", P2, 0, 1, Config.BoxTransparency, function(v) Config.BoxTransparency = v end)

CreateSection("颜色设置", P2)
CreateColorSystem("FOV 圆圈", P2, Config.FOVColor, "FOVColor", "RainbowFOV")
CreateColorSystem("锁定框", P2, Config.BoxColor, "BoxColor", "RainbowBox")
CreateColorSystem("主按钮", P2, Config.RingColor, "RingColor", "RainbowRing")

local P3 = CreatePage("Misc")
CreateSection("通知系统", P3)
CreateCycleButton("启用通知", "在屏幕上方显示灵动岛风格通知", P3, {"关闭", "开启"}, 2, function(o) Config.NotificationEnabled = (o == "开启") end)
CreateSlider("通知时长", "通知显示的持续时间(秒)", P3, 0.5, 5, Config.NotificationDuration, function(v) Config.NotificationDuration = v end)
CreateInputBox("锁定提示词", "自定义锁定时显示的文本", P3, Config.TextLocked, function(t) Config.TextLocked = t end)
CreateInputBox("解锁提示词", "自定义解锁时显示的文本", P3, Config.TextUnlocked, function(t) Config.TextUnlocked = t end)
CreateInputBox("丢失提示词", "自定义丢失目标时显示的文本", P3, Config.TextLost, function(t) Config.TextLost = t end)

CreateSection("过滤设置", P3)
CreateCycleButton("队伍检查", "不锁定同一队伍的玩家", P3, {"关闭", "开启"}, 1, function(o) Config.TeamCheck = (o == "开启") end)
CreateCycleButton("掩体检测", "仅锁定可见(无遮挡)的目标", P3, {"关闭", "开启"}, 1, function(o) Config.CoverCheck = (o == "开启") end)
CreateSlider("最大距离", "允许锁定的最远距离", P3, 100, 5000, Config.MaxDistance, function(v) Config.MaxDistance = v end)

CreateSection("界面设置", P3)
local EditBtn = Instance.new("TextButton", P3)
EditBtn.Size = UDim2.new(1, 0, 0, 30)
EditBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
EditBtn.Text = "移动按钮位置"
EditBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
EditBtn.Font = Enum.Font.GothamMedium
EditBtn.TextSize = 10
Instance.new("UICorner", EditBtn).CornerRadius = UDim.new(0, 4)
EditBtn.MouseButton1Click:Connect(function()
    SettingsPanel:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Exponential, 0.3, true, function() 
        SettingsPanel.Visible = false 
        ClickOverlay.Visible = false
    end)
    ConfirmContainer.Visible = true
    isEditingPos = true
end)

local P4 = CreatePage("Lists")
local ListContainer = Instance.new("Frame", P4)
ListContainer.Size = UDim2.new(1, 0, 0.9, 0)
ListContainer.BackgroundTransparency = 1

local LeftPanel = Instance.new("Frame", ListContainer)
LeftPanel.Size = UDim2.new(0.48, 0, 1, 0)
LeftPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", LeftPanel).CornerRadius = UDim.new(0, 4)

local RightPanel = Instance.new("Frame", ListContainer)
RightPanel.Size = UDim2.new(0.48, 0, 1, 0)
RightPanel.Position = UDim2.new(0.52, 0, 0, 0)
RightPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", RightPanel).CornerRadius = UDim.new(0, 4)

local function BuildListPanel(parent, title, listRef, otherListRef, color, enableKey)
    local H = Instance.new("TextLabel", parent)
    H.Text = title
    H.Size = UDim2.new(0.6, 0, 0, 24)
    H.BackgroundTransparency = 1
    H.TextColor3 = Color3.fromRGB(150, 150, 150)
    H.Font = Enum.Font.GothamBold
    H.TextSize = 9
    H.TextXAlignment = Enum.TextXAlignment.Left
    H.Position = UDim2.new(0, 4, 0, 0)
    
    local Toggle = Instance.new("TextButton", parent)
    Toggle.Size = UDim2.new(0, 24, 0, 14)
    Toggle.Position = UDim2.new(1, -28, 0, 5)
    Toggle.BackgroundColor3 = Config[enableKey] and color or Color3.fromRGB(40, 40, 40)
    Toggle.Text = ""
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 4)
    
    Toggle.MouseButton1Click:Connect(function()
        Config[enableKey] = not Config[enableKey]
        Toggle.BackgroundColor3 = Config[enableKey] and color or Color3.fromRGB(40, 40, 40)
    end)
    
    local AddBtn = Instance.new("TextButton", parent)
    AddBtn.Size = UDim2.new(1, -4, 0, 16)
    AddBtn.Position = UDim2.new(0, 2, 0, 24)
    AddBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    AddBtn.Text = "添加玩家 ▼"
    AddBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    AddBtn.TextSize = 9
    AddBtn.Font = Enum.Font.Gotham
    Instance.new("UICorner", AddBtn).CornerRadius = UDim.new(0, 2)
    
    local Scroll = Instance.new("ScrollingFrame", parent)
    Scroll.Size = UDim2.new(1, -4, 1, -44)
    Scroll.Position = UDim2.new(0, 2, 0, 44)
    Scroll.BackgroundTransparency = 1
    Scroll.ScrollBarThickness = 2
    local UIList = Instance.new("UIListLayout", Scroll)
    UIList.SortOrder = Enum.SortOrder.Name
    
    local Selector = Instance.new("ScrollingFrame", parent)
    Selector.Size = UDim2.new(1, 0, 0, 120)
    Selector.Position = UDim2.new(0, 0, 0, 42)
    Selector.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Selector.Visible = false
    Selector.ZIndex = 5
    Selector.ScrollBarThickness = 2
    local SelLayout = Instance.new("UIListLayout", Selector)
    SelLayout.SortOrder = Enum.SortOrder.Name
    
    AddBtn.MouseButton1Click:Connect(function()
        Selector.Visible = not Selector.Visible
        AddBtn.Text = Selector.Visible and "关闭 ▲" or "添加玩家 ▼"
    end)
    
    local function RefreshView()
        for _, c in pairs(Scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        for uid, _ in pairs(listRef) do
            local pName = "未知"
            local p = Players:GetPlayerByUserId(uid)
            if p then pName = p.Name end
            
            local Row = Instance.new("Frame", Scroll)
            Row.Size = UDim2.new(1, 0, 0, 18)
            Row.BackgroundTransparency = 1
            
            local Lbl = Instance.new("TextLabel", Row)
            Lbl.Text = pName
            Lbl.Size = UDim2.new(0.8, 0, 1, 0)
            Lbl.BackgroundTransparency = 1
            Lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
            Lbl.TextSize = 9
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            
            local Del = Instance.new("TextButton", Row)
            Del.Size = UDim2.new(0, 16, 0, 16)
            Del.Position = UDim2.new(1, -16, 0, 1)
            Del.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
            Del.Text = "-"
            Del.TextColor3 = Color3.fromRGB(200, 200, 200)
            Del.TextSize = 10
            Instance.new("UICorner", Del).CornerRadius = UDim.new(0, 2)
            
            Del.MouseButton1Click:Connect(function()
                listRef[uid] = nil
                RefreshView()
            end)
        end
    end
    
    local function RefreshSelector()
        for _, c in pairs(Selector:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not listRef[p.UserId] then
                local B = Instance.new("TextButton", Selector)
                B.Size = UDim2.new(1, -4, 0, 18)
                B.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                B.Text = p.Name
                B.TextColor3 = Color3.fromRGB(200, 200, 200)
                B.TextSize = 9
                B.ZIndex = 6
                
                B.MouseButton1Click:Connect(function()
                    listRef[p.UserId] = true
                    otherListRef[p.UserId] = nil 
                    RefreshView()
                    Selector.Visible = false
                    AddBtn.Text = "添加玩家 ▼"
                end)
            end
        end
    end
    
    AddBtn.MouseButton1Click:Connect(RefreshSelector)
    return RefreshView
end

local RefWhite = BuildListPanel(LeftPanel, "白名单", Config.Whitelist, Config.Blacklist, Color3.fromRGB(30, 160, 60), "WhitelistEnabled")
local RefBlack = BuildListPanel(RightPanel, "黑名单", Config.Blacklist, Config.Whitelist, Color3.fromRGB(160, 30, 30), "BlacklistEnabled")

P4:GetPropertyChangedSignal("Visible"):Connect(function()
    if P4.Visible then RefWhite(); RefBlack() end
end)

CreateTab("瞄准", "Aim")
CreateTab("视觉", "Visuals")
CreateTab("杂项", "Misc")
CreateTab("名单", "Lists")

local isLocked = false
local currentTarget = nil
local lockedUserId = nil
local visualEffect = nil
local legitOffset = Vector3.zero
local lastLockTime = 0

local function UpdatePanel(show)
    if show then
        ClickOverlay.Visible = true
        SettingsPanel.Visible = true
        SettingsPanel.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(SettingsPanel, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 460, 0, 340)}):Play()
    else
        ClickOverlay.Visible = false
        TooltipFrame.Visible = false 
        SettingsPanel:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Exponential, 0.3, true, function() SettingsPanel.Visible = false end)
    end
end

ClickOverlay.MouseButton1Click:Connect(function() UpdatePanel(false) end)

local isPressing = false
local pressStart = 0
local dragInput
local dragStart
local startBtnPos

MainButton.InputBegan:Connect(function(input)
    if isEditingPos then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
            dragStart = input.Position
            startBtnPos = MainButton.Position
        end
    else
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isPressing = true
            pressStart = tick()
            
            ProgressBarBg.Visible = true
            ProgressBarFill.Size = UDim2.new(0,0,1,0)
            
            TweenService:Create(MainButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 36, 0, 36)}):Play()
            
            task.spawn(function()
                while isPressing do
                    local dur = tick() - pressStart
                    local prog = math.clamp(dur / 0.6, 0, 1)
                    ProgressBarFill.Size = UDim2.new(prog, 0, 1, 0)
                    if prog >= 1 then
                        isPressing = false
                        ProgressBarBg.Visible = false
                        UpdatePanel(true)
                        break
                    end
                    RunService.RenderStepped:Wait()
                end
            end)
        end
    end
end)

MainButton.InputChanged:Connect(function(input)
    if isEditingPos then
        if input == dragInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainButton.Position = UDim2.new(startBtnPos.X.Scale, startBtnPos.X.Offset + delta.X, startBtnPos.Y.Scale, startBtnPos.Y.Offset + delta.Y)
        end
    end
end)

MainButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if isEditingPos then
            if input == dragInput then dragInput = nil end
        else
            TweenService:Create(MainButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 40, 0, 40)}):Play()
            if isPressing then
                isPressing = false
                ProgressBarBg.Visible = false
                if (tick() - pressStart) < 0.6 then
                    isLocked = not isLocked
                    if isLocked then
                        ShowNotification(Config.TextLocked, "Lock")
                        LockRing.Visible = true
                    else
                        ShowNotification(Config.TextUnlocked, "Unlock")
                        LockRing.Visible = false
                        currentTarget = nil
                        lockedUserId = nil
                        TargetState = {Velocity = Vector3.zero, Acceleration = Vector3.zero, LastUpdate = 0}
                        if visualEffect then visualEffect.Enabled = false end
                    end
                end
            end
        end
    end
end)

ConfirmBtn.MouseButton1Click:Connect(function() isEditingPos = false; ConfirmContainer.Visible = false end)
CancelBtn.MouseButton1Click:Connect(function() 
    isEditingPos = false 
    ConfirmContainer.Visible = false 
    MainButton.Position = UDim2.new(0.8, -20, 0.6, -20) 
end)

local function EnsureBoxVisuals(targetChar)
    if not Config.BoxVisible then if visualEffect then visualEffect.Enabled = false end return end
    if not targetChar then if visualEffect then visualEffect.Enabled = false end return end
    local root = targetChar:FindFirstChild("HumanoidRootPart")
    local torso = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso") or root
    if not root or not torso then if visualEffect then visualEffect.Enabled = false end return end
    
    if not visualEffect or visualEffect.Parent ~= ScreenGui then
        if visualEffect then visualEffect:Destroy() end
        local bb = Instance.new("BillboardGui", ScreenGui)
        bb.Name = "LockBox"
        bb.Adornee = torso
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 0, 0, 0)
        local container = Instance.new("Frame", bb)
        container.Size = UDim2.new(1,0,1,0)
        container.BackgroundTransparency = 1
        container.AnchorPoint = Vector2.new(0.5,0.5)
        container.Position = UDim2.fromScale(0.5,0.5)
        
        local function Line(p, a, s)
            local f = Instance.new("Frame", container)
            f.Name = "Line"
            f.BorderSizePixel = 0
            f.Position = p; f.AnchorPoint = a; f.Size = s
            return f
        end
        local l, w = UDim2.new(0.43, 0, 0, Config.BoxThickness), UDim2.new(0, Config.BoxThickness, 0.43, 0)
        Line(UDim2.new(0,0,0,0), Vector2.new(0,0), l); Line(UDim2.new(0,0,0,0), Vector2.new(0,0), w)
        Line(UDim2.new(1,0,0,0), Vector2.new(1,0), l); Line(UDim2.new(1,0,0,0), Vector2.new(1,0), w)
        Line(UDim2.new(0,0,1,0), Vector2.new(0,1), l); Line(UDim2.new(0,0,1,0), Vector2.new(0,1), w)
        Line(UDim2.new(1,0,1,0), Vector2.new(1,1), l); Line(UDim2.new(1,0,1,0), Vector2.new(1,1), w)
        visualEffect = bb
    else
        visualEffect.Enabled = true
        visualEffect.Adornee = torso
        local size = torso.Size.X * Config.BoxSize
        visualEffect.Size = UDim2.new(0, size, 0, size)
    end
    
    for _, v in pairs(visualEffect.Frame:GetChildren()) do
        v.BackgroundColor3 = Config.BoxColor
        v.BackgroundTransparency = Config.BoxTransparency
        if v.Size.X.Offset == 1 or v.Size.X.Offset > 1 then 
             if v.Size.Y.Scale > 0 then v.Size = UDim2.new(0, Config.BoxThickness, 0.43, 0) 
             else v.Size = UDim2.new(0.43, 0, 0, Config.BoxThickness) end
        end
    end
    visualEffect.Frame.Rotation = visualEffect.Frame.Rotation + Config.BoxSpeed
end

local function CheckCover(model)
    local root, head = model:FindFirstChild("HumanoidRootPart"), model:FindFirstChild("Head")
    if not root or not head then return false end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, model}
    params.FilterType = Enum.RaycastFilterType.Exclude
    return not workspace:Raycast(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position), params)
end

local function GetSortedTarget()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local mousePos = Config.FixedFOV and (Camera.ViewportSize / 2) or UserInputService:GetMouseLocation()
    
    local targets = {}
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if Config.WhitelistEnabled and not Config.Whitelist[p.UserId] then continue end
            if Config.BlacklistEnabled and Config.Blacklist[p.UserId] then continue end
            
            if not (Config.TeamCheck and p.Team == LocalPlayer.Team) then
                local char = p.Character
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                if root and hum and hum.Health > 0 then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist <= Config.MaxDistance then
                        local sPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                        if onScreen then
                            if not Config.CoverCheck or CheckCover(char) then
                                local fovDist = (Vector2.new(sPos.X, sPos.Y) - mousePos).Magnitude
                                if not Config.UseFOV or fovDist <= Config.FOVRadius then
                                    table.insert(targets, {
                                        Char = char,
                                        Dist = dist,
                                        Fov = fovDist,
                                        Health = hum.Health
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    if #targets == 0 then return nil end
    
    table.sort(targets, function(a, b)
        if Config.PriorityMode == "Lowest Health" then
            return a.Health < b.Health
        elseif Config.PriorityMode == "Closest Distance" then
            return a.Dist < b.Dist
        else
            return a.Fov < b.Fov
        end
    end)
    
    return targets[1].Char
end

RunService.RenderStepped:Connect(function()
    local dt = RunService.RenderStepped:Wait()
    local hue = tick() % 5 / 5
    local rainbowC = Color3.fromHSV(hue, 1, 1)
    if Config.RainbowFOV then Config.FOVColor = rainbowC end
    if Config.RainbowBox then Config.BoxColor = rainbowC end
    if Config.RainbowRing then Config.RingColor = rainbowC end
    
    FOVStroke.Color = Config.FOVColor
    RingStroke.Color = Config.RingColor
    
    if Config.FOVVisible then
        FOVCircleFrame.Position = Config.FixedFOV and UDim2.fromScale(0.5, 0.5) or UDim2.fromOffset(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    end
    
    if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
        local now = tick()
        if TargetState.LastUpdate ~= 0 then
            local timeDelta = now - TargetState.LastUpdate
            if timeDelta > 0 then
                local currentVel = currentTarget.HumanoidRootPart.AssemblyLinearVelocity
                local newAccel = (currentVel - TargetState.Velocity) / timeDelta
                if newAccel.Magnitude > 1000 then newAccel = Vector3.zero end
                TargetState.Acceleration = TargetState.Acceleration:Lerp(newAccel, 0.1)
                TargetState.Velocity = currentVel
            end
        end
        TargetState.LastUpdate = now
    else
        TargetState = {Velocity = Vector3.zero, Acceleration = Vector3.zero, LastUpdate = 0}
    end

    if Config.SmartPrediction and Config.PredictionEnabled then
        local ping = StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
        local base = ping / 1000 
        if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
            local dist = (currentTarget.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            base = base + (dist / Config.ProjectileSpeed)
        end
        Config.PredictionAmount = math.clamp(base, 0, 5)
    end
    
    if isLocked then
        if Config.DynamicSwitching then
            local potential = GetSortedTarget()
            if potential and potential ~= currentTarget then
                currentTarget = potential
                lockedUserId = Players:GetPlayerFromCharacter(potential).UserId
                if Config.LegitMode then
                    legitOffset = Vector3.new(math.random(-Config.AimOffset, Config.AimOffset), math.random(-Config.AimOffset, Config.AimOffset), math.random(-Config.AimOffset, Config.AimOffset))
                    lastLockTime = tick()
                end
            end
        end

        if not lockedUserId then
            local t = GetSortedTarget()
            if t then 
                lockedUserId = Players:GetPlayerFromCharacter(t).UserId 
                if Config.LegitMode then
                    legitOffset = Vector3.new(math.random(-Config.AimOffset, Config.AimOffset), math.random(-Config.AimOffset, Config.AimOffset), math.random(-Config.AimOffset, Config.AimOffset))
                    lastLockTime = tick()
                end
            end
        end
        
        if lockedUserId then
            local p = Players:GetPlayerByUserId(lockedUserId)
            if not p then
                if Config.ContinuousLock then
                     lockedUserId = nil; currentTarget = nil
                else
                     currentTarget = nil 
                     ShowNotification(Config.TextLost, "Warn")
                     if visualEffect then visualEffect.Enabled = false end
                end
            else
                local char = p.Character
                local valid = false
                if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 and char:FindFirstChild("HumanoidRootPart") then
                    valid = true
                    if Config.CoverCheck and not CheckCover(char) then valid = false end
                    if Config.UseFOV then
                        local r = char:FindFirstChild("HumanoidRootPart")
                        local s, o = Camera:WorldToViewportPoint(r.Position)
                        local m = Config.FixedFOV and (Camera.ViewportSize/2) or UserInputService:GetMouseLocation()
                        if (Vector2.new(s.X, s.Y) - m).Magnitude > Config.FOVRadius then valid = false end
                    end
                end
                
                if not valid then
                    if Config.ContinuousLock then
                        local nt = GetSortedTarget()
                        if nt then 
                            lockedUserId = Players:GetPlayerFromCharacter(nt).UserId; char = nt 
                            if Config.LegitMode then
                                legitOffset = Vector3.new(math.random(-Config.AimOffset, Config.AimOffset), math.random(-Config.AimOffset, Config.AimOffset), math.random(-Config.AimOffset, Config.AimOffset))
                                lastLockTime = tick()
                            end
                        else 
                            lockedUserId = nil; currentTarget = nil
                            ShowNotification("无可用目标", "Warn")
                        end
                    else
                         currentTarget = nil
                         ShowNotification("目标无效", "Warn")
                         if visualEffect then visualEffect.Enabled = false end
                    end
                else
                    currentTarget = char
                end
                
                if currentTarget and currentTarget:FindFirstChild(Config.AimPart) then
                    EnsureBoxVisuals(currentTarget)
                    
                    if Config.LegitMode then
                        if (tick() - lastLockTime < Config.ReactionDelay) then return end
                        if math.random(0, 100) < Config.MissChance then return end
                    end
                    
                    local aimPos = currentTarget[Config.AimPart].Position
                    
                    if Config.LegitMode then 
                        aimPos = aimPos + legitOffset 
                        if Config.ShakePower > 0 then
                            aimPos = aimPos + Vector3.new(
                                math.random(-Config.ShakePower, Config.ShakePower)/10, 
                                math.random(-Config.ShakePower, Config.ShakePower)/10, 
                                math.random(-Config.ShakePower, Config.ShakePower)/10
                            )
                        end
                    end
                    
                    if Config.PredictionEnabled and currentTarget:FindFirstChild("HumanoidRootPart") then
                        local t = Config.PredictionAmount
                        local vel = TargetState.Velocity
                        
                        if Config.SmartPrediction then
                            local dist = (currentTarget.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
                            t = dist / Config.ProjectileSpeed
                        end

                        aimPos = aimPos + (vel * t)
                        
                        if Config.AccelerationPrediction then
                            aimPos = aimPos + (0.5 * TargetState.Acceleration * (t^2))
                        end
                        
                        aimPos = aimPos + Vector3.new(0, (0.5 * Config.GravityCorrection * (t^2)), 0)
                    end
                    
                    local rawSens = math.clamp(Config.Sensitivity, 0, 100)
                    local alpha = (100 - rawSens) / 100
                    
                    if Config.LegitMode then
                        if Config.SmoothnessCurve == "Sine" then
                            alpha = math.sin(alpha * math.pi / 2)
                        elseif Config.SmoothnessCurve == "Quad" then
                            alpha = alpha * alpha
                        end
                    end
                    
                    if Config.LockMode == "Character" and LocalPlayer.Character then
                        LocalPlayer.Character.Humanoid.AutoRotate = false
                        local look = Vector3.new(aimPos.X, LocalPlayer.Character.HumanoidRootPart.Position.Y, aimPos.Z)
                        local newCF = CFrame.lookAt(LocalPlayer.Character.HumanoidRootPart.Position, look)
                        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame:Lerp(newCF, alpha)
                    else
                        if LocalPlayer.Character then LocalPlayer.Character.Humanoid.AutoRotate = true end
                        local curCF = Camera.CFrame
                        local targetCF = CFrame.lookAt(curCF.Position, aimPos)
                        Camera.CFrame = curCF:Lerp(targetCF, alpha)
                    end
                else
                    if visualEffect then visualEffect.Enabled = false end
                end
            end
        end
    else
        if visualEffect then visualEffect.Enabled = false end
        lockedUserId = nil
        currentTarget = nil
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.AutoRotate = true
        end
    end
end)
