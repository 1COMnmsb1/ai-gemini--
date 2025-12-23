local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local StatsService = game:GetService("Stats")
local Teams = game:GetService("Teams")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local repo = "https://raw.githubusercontent.com/ATLASTEAM01/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Connections = {}

local Config = {
    Sensitivity = 0, 
    LockMode = "人物", 
    AimPart = "躯干", 
    PredictionEnabled = false,
    SmartPrediction = false,
    PredictionAmount = 0.165,
    PredictionStyle = "标准",
    AccelerationPrediction = false,
    TeamCheck = false,
    TeamCheckMode = "标准",
    CoverCheck = false,
    MultiPointCheck = false,
    WallCheckFallback = false, 
    ContinuousLock = false, 
    MaxDistance = 2000,
    UseFOV = false,
    FOVVisible = false,
    FOVRadius = 130,
    UserFOVRadius = 130, 
    SmartFOV = false,
    SmartFOVMin = 10,
    SmartFOVSpeed = 15,
    FixedFOV = false,
    FOVColor = Color3.fromRGB(255, 255, 255),
    BoxVisible = false,
    BoxColor = Color3.fromRGB(255, 255, 255),
    BoxShape = "方框",
    BoxBreathing = false,
    RingColor = Color3.fromRGB(255, 255, 255),
    TracerVisible = false,
    TracerColor = Color3.fromRGB(255, 255, 255),
    TracerThickness = 1,
    TracerTransparency = 0,
    RainbowFOV = false,
    RainbowBox = false,
    RainbowRing = false,
    RainbowTracer = false,
    WhitelistEnabled = false,
    BlacklistEnabled = false,
    Whitelist = {},
    Blacklist = {},
    TeamWhitelistEnabled = false,
    TeamWhitelist = {},
    TeamBlacklistEnabled = false,
    TeamBlacklist = {},
    PriorityMode = "准心优先",
    StickyAiming = true,
    BoxSize = 5.5,
    BoxThickness = 1,
    BoxSpeed = 1,
    BoxTransparency = 0,
    LegitMode = false,
    AimOffset = 0,
    ShakePower = 0,
    MissChance = 0,
    SmoothnessCurve = "线性",
    ReactionDelay = 0,
    NotificationEnabled = true,
    NotificationDuration = 2.5,
    NotificationCooldown = 0,
    TextLocked = "已锁定",
    TextUnlocked = "已解锁",
    TextLost = "目标丢失",
    HeadshotChance = 0,
    AdminWatchdog = false,
    SilentEnabled = false,
    SilentHitChance = 100,
    SilentPrediction = 0.165,
    SilentMethod = "Raycast",
    WallbangMode = "无",
    BulletTPMode = "无",
    HitSound = "关闭",
    ShowDamage = false,
    AimQuickButtonEnabled = false,
    AimQuickButtonSize = 50,
    AimQuickButtonTransparency = 0.3,
    SilentQuickButtonEnabled = false,
    SilentQuickButtonSize = 50,
    SilentQuickButtonTransparency = 0.3
}

local HitSounds = {
    ["钟声"] = "rbxassetid://8679627751",
    ["金属"] = "rbxassetid://3125624765",
    ["点击"] = "rbxassetid://17755696142",
    ["爆炸"] = "rbxassetid://10070796384"
}

local damageIndicators = {}
local DAMAGE_INDICATOR_FADE_TIME = 1.0
local INDICATOR_FLOAT_SPEED = 40

local QuickButtonGui = Instance.new("ScreenGui")
QuickButtonGui.Name = "PureLockQuickButtons"
QuickButtonGui.Parent = CoreGui
QuickButtonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local AimButton = Instance.new("TextButton")
local SilentButton = Instance.new("TextButton")

local function SetupQuickButton(btn, name, yOffset, toggleRef, sizeConfig, transparencyConfig)
    btn.Parent = QuickButtonGui
    btn.Size = UDim2.fromOffset(sizeConfig, sizeConfig)
    btn.Position = UDim2.new(0.9, 0, 0.4, yOffset)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BackgroundTransparency = transparencyConfig
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    
    local dragging, dragInput, dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
        end
    end)
    btn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    btn.MouseButton1Click:Connect(function()
        if toggleRef and toggleRef.Value ~= nil then
            toggleRef:SetValue(not toggleRef.Value)
        end
    end)
    
    return btn
end

local function UpdateQuickButtons()
    if Config.AimQuickButtonEnabled then
        AimButton.Visible = true
        AimButton.Size = UDim2.fromOffset(Config.AimQuickButtonSize, Config.AimQuickButtonSize)
        AimButton.BackgroundTransparency = Config.AimQuickButtonTransparency
        if Toggles.AimEnabled.Value then
            AimButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        else
            AimButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    else
        AimButton.Visible = false
    end

    if Config.SilentQuickButtonEnabled then
        SilentButton.Visible = true
        SilentButton.Size = UDim2.fromOffset(Config.SilentQuickButtonSize, Config.SilentQuickButtonSize)
        SilentButton.BackgroundTransparency = Config.SilentQuickButtonTransparency
        if Toggles.SilentEnabled.Value then
            SilentButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        else
            SilentButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    else
        SilentButton.Visible = false
    end
end

local function playHitSound(soundId)
    local sound = Instance.new("Sound")
    sound.Parent = CoreGui
    sound.SoundId = soundId
    sound.Volume = 1
    sound:Play()
    Debris:AddItem(sound, sound.TimeLength + 0.2)
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = Camera:WorldToViewportPoint(Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function createDamageIndicator(position, damage)
    local screenPos, onScreen = getPositionOnScreen(position)
    if not onScreen then return end

    local indicator = {}
    indicator.Created = tick()
    indicator.Position = screenPos
    
    local text = Drawing.new("Text")
    text.Font = Drawing.Fonts.Monospace
    text.Text = string.format("-%d", math.floor(damage))
    text.Color = Color3.fromRGB(255, 50, 50)
    text.Size = 22
    text.Center = true
    text.Outline = true
    text.Visible = true
    
    indicator.TextObject = text
    table.insert(damageIndicators, indicator)
end

local lastNotifyTime = 0
local function ShowNotification(title, type, force)
    if not Config.NotificationEnabled then return end
    if not force and tick() - lastNotifyTime < Config.NotificationCooldown then return end
    lastNotifyTime = tick()
    Library:Notify(title, 3)
end

local VisualsGui = Instance.new("ScreenGui")
VisualsGui.Name = "PureLockVisuals"
VisualsGui.ResetOnSpawn = false
VisualsGui.IgnoreGuiInset = true
VisualsGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local FOVCircleFrame = Instance.new("Frame", VisualsGui)
FOVCircleFrame.Name = "FOVCircle"
FOVCircleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircleFrame.BackgroundTransparency = 1
FOVCircleFrame.Visible = false
FOVCircleFrame.Size = UDim2.fromOffset(Config.FOVRadius*2, Config.FOVRadius*2)
local FOVStroke = Instance.new("UIStroke", FOVCircleFrame)
FOVStroke.Thickness = 1
FOVStroke.Transparency = 0.6
Instance.new("UICorner", FOVCircleFrame).CornerRadius = UDim.new(1, 0)

local TracerLineFrame = Instance.new("Frame", VisualsGui)
TracerLineFrame.Name = "TracerLine"
TracerLineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
TracerLineFrame.BorderSizePixel = 0
TracerLineFrame.Visible = false

local visualEffect = nil
local function CleanupVisuals()
    if visualEffect then
        visualEffect:Destroy()
        visualEffect = nil
    end
end

local Window = Library:CreateWindow({
    Title = "通用瞄准",
    Footer = "作者:卓一航",
    Theme = "Dark",
    Accent = "#00ff00"
})

local AimTab = Window:AddTab("战斗")
local VisualsTab = Window:AddTab("视觉")
local MiscTab = Window:AddTab("辅助")
local ListsTab = Window:AddTab("名单")
local SettingsTab = Window:AddTab("设置")

local AimGeneralGroup = AimTab:AddLeftGroupbox("基础参数")
AimGeneralGroup:AddSlider('Sensitivity', {
    Text = '平滑度 (0=锁死)',
    Default = Config.Sensitivity,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(Value) Config.Sensitivity = Value end
})
AimGeneralGroup:AddDropdown('LockMode', {
    Text = '锁定模式',
    Default = Config.LockMode,
    Values = {"人物", "相机"},
    Callback = function(Value) Config.LockMode = Value end
})
AimGeneralGroup:AddDropdown('AimPart', {
    Text = '瞄准部位',
    Default = Config.AimPart,
    Values = {"躯干", "头部", "手臂", "腿部", "随机"},
    Callback = function(Value) Config.AimPart = Value end
})
AimGeneralGroup:AddToggle('ContinuousLock', {
    Text = '连续锁定 (需按住)',
    Default = Config.ContinuousLock,
    Callback = function(Value) Config.ContinuousLock = Value end
})

local AimLogicGroup = AimTab:AddLeftGroupbox("目标逻辑")
AimLogicGroup:AddDropdown('PriorityMode', {
    Text = '优先目标',
    Default = Config.PriorityMode,
    Values = {"准心优先", "最低血量", "最近距离"},
    Callback = function(Value) Config.PriorityMode = Value end
})
AimLogicGroup:AddToggle('StickyAiming', {
    Text = '粘性瞄准',
    Default = Config.StickyAiming,
    Callback = function(Value) Config.StickyAiming = Value end
})
AimLogicGroup:AddToggle('WallCheckFallback', {
    Text = '掩体回退 (自动打身)',
    Default = Config.WallCheckFallback,
    Callback = function(Value) Config.WallCheckFallback = Value end
})

local LegitGroup = AimTab:AddRightGroupbox("伪装模式")
LegitGroup:AddToggle('LegitMode', {
    Text = '启用伪装',
    Default = Config.LegitMode,
    Callback = function(Value) Config.LegitMode = Value end
})
LegitGroup:AddSlider('AimOffset', {
    Text = '随机偏移',
    Default = Config.AimOffset,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Callback = function(Value) Config.AimOffset = Value end
})
LegitGroup:AddSlider('ShakePower', {
    Text = '手抖强度',
    Default = Config.ShakePower,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Callback = function(Value) Config.ShakePower = Value end
})
LegitGroup:AddSlider('MissChance', {
    Text = '失误概率',
    Default = Config.MissChance,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(Value) Config.MissChance = Value end
})
LegitGroup:AddSlider('ReactionDelay', {
    Text = '人类延迟 (秒)',
    Default = Config.ReactionDelay,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value) Config.ReactionDelay = Value end
})
LegitGroup:AddDropdown('SmoothnessCurve', {
    Text = '平滑曲线',
    Default = Config.SmoothnessCurve,
    Values = {"线性", "正弦", "二次方", "指数", "弹性", "圆形"},
    Callback = function(Value) Config.SmoothnessCurve = Value end
})

local SilentGroup = AimTab:AddRightGroupbox("静默自瞄")
SilentGroup:AddToggle('SilentEnabled', {
    Text = '启用静默自瞄',
    Default = Config.SilentEnabled,
    Callback = function(Value) 
        Config.SilentEnabled = Value 
        UpdateQuickButtons()
    end
})
SilentGroup:AddDropdown('SilentMethod', {
    Text = '拦截模式',
    Default = Config.SilentMethod,
    Values = {"Raycast", "FindPartOnRay", "FindPartOnRayWithIgnoreList", "FindPartOnRayWithWhitelist", "ScreenPointToRay", "ViewportPointToRay", "Mouse.Hit", "Mouse.Target", "Ray.new"},
    Callback = function(Value) Config.SilentMethod = Value end
})
SilentGroup:AddSlider('SilentHitChance', {
    Text = '静默命中率',
    Default = Config.SilentHitChance,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(Value) Config.SilentHitChance = Value end
})
SilentGroup:AddDropdown('WallbangMode', {
    Text = '穿墙模式',
    Default = Config.WallbangMode,
    Values = {'无', 'RaycastParams', 'SpoofHit'},
    Callback = function(Value) Config.WallbangMode = Value end
})
SilentGroup:AddDropdown('BulletTPMode', {
    Text = '子弹传送',
    Default = Config.BulletTPMode,
    Values = {'无', '坐标传送', '骨骼传送'},
    Callback = function(Value) Config.BulletTPMode = Value end
})

SilentGroup:AddToggle('SilentQuickButtonEnabled', {
    Text = '启用静默快捷按钮',
    Default = Config.SilentQuickButtonEnabled,
    Callback = function(Value)
        Config.SilentQuickButtonEnabled = Value
        UpdateQuickButtons()
    end
})
SilentGroup:AddSlider('SilentQuickButtonSize', {
    Text = '按钮大小',
    Default = Config.SilentQuickButtonSize,
    Min = 20,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        Config.SilentQuickButtonSize = Value
        UpdateQuickButtons()
    end
})
SilentGroup:AddSlider('SilentQuickButtonTransparency', {
    Text = '按钮透明度',
    Default = Config.SilentQuickButtonTransparency,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        Config.SilentQuickButtonTransparency = Value
        UpdateQuickButtons()
    end
})

local PredGroup = AimTab:AddRightGroupbox("预判系统")
PredGroup:AddToggle('PredictionEnabled', {
    Text = '启用预判',
    Default = Config.PredictionEnabled,
    Callback = function(Value) Config.PredictionEnabled = Value end
})
PredGroup:AddToggle('SmartPrediction', {
    Text = '智能自动预判',
    Default = Config.SmartPrediction,
    Callback = function(Value) Config.SmartPrediction = Value end
})
PredGroup:AddSlider('PredictionAmount', {
    Text = '手动预判数值',
    Default = Config.PredictionAmount,
    Min = 0,
    Max = 5,
    Rounding = 3,
    Callback = function(Value) Config.PredictionAmount = Value end
})

local FeedbackGroup = AimTab:AddRightGroupbox("战斗反馈")
FeedbackGroup:AddSlider('HeadshotChance', {
    Text = '强制爆头率',
    Default = Config.HeadshotChance,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(Value) Config.HeadshotChance = Value end
})
FeedbackGroup:AddDropdown('HitSound', {
    Text = '击中音效',
    Default = '关闭',
    Values = {'关闭', '钟声', '金属', '点击', '爆炸'},
    Callback = function(Value) Config.HitSound = Value end
})
FeedbackGroup:AddToggle('ShowDamage', {
    Text = '显示伤害',
    Default = Config.ShowDamage,
    Callback = function(Value) Config.ShowDamage = Value end
})

local FOVGroup = VisualsTab:AddLeftGroupbox("视野范围 (FOV)")
FOVGroup:AddToggle('UseFOV', {
    Text = 'FOV 限制',
    Default = Config.UseFOV,
    Callback = function(Value) Config.UseFOV = Value end
})
FOVGroup:AddToggle('FOVVisible', {
    Text = '显示 FOV 圆圈',
    Default = Config.FOVVisible,
    Callback = function(Value) Config.FOVVisible = Value end
})
FOVGroup:AddSlider('UserFOVRadius', {
    Text = '圆圈半径',
    Default = Config.UserFOVRadius,
    Min = 10,
    Max = 800,
    Rounding = 0,
    Callback = function(Value) 
        Config.UserFOVRadius = Value
        if Config.SmartFOVMin > Value then Config.SmartFOVMin = Value end
    end
})
FOVGroup:AddToggle('SmartFOV', {
    Text = '智能缩放 (随距离)',
    Default = Config.SmartFOV,
    Callback = function(Value) Config.SmartFOV = Value end
})
FOVGroup:AddSlider('SmartFOVMin', {
    Text = '最小缩放半径',
    Default = Config.SmartFOVMin,
    Min = 10,
    Max = 800,
    Rounding = 0,
    Callback = function(Value) Config.SmartFOVMin = Value end
})
FOVGroup:AddSlider('SmartFOVSpeed', {
    Text = '缩放平滑速度',
    Default = Config.SmartFOVSpeed,
    Min = 1,
    Max = 30,
    Rounding = 1,
    Callback = function(Value) Config.SmartFOVSpeed = Value end
})
FOVGroup:AddToggle('FixedFOV', {
    Text = '固定在屏幕中心',
    Default = Config.FixedFOV,
    Callback = function(Value) Config.FixedFOV = Value end
})
FOVGroup:AddLabel('圆圈颜色'):AddColorPicker('FOVColor', {
    Default = Config.FOVColor,
    Title = 'FOV 颜色',
    Callback = function(Value) Config.FOVColor = Value end
})
FOVGroup:AddToggle('RainbowFOV', {
    Text = '彩虹渐变模式',
    Default = Config.RainbowFOV,
    Callback = function(Value) Config.RainbowFOV = Value end
})

local BoxGroup = VisualsTab:AddRightGroupbox("锁定框样式")
BoxGroup:AddToggle('BoxVisible', {
    Text = '显示目标锁定框',
    Default = Config.BoxVisible,
    Callback = function(Value) Config.BoxVisible = Value end
})
BoxGroup:AddDropdown('BoxShape', {
    Text = '形状',
    Default = Config.BoxShape,
    Values = {"方框", "三角形", "五角星", "六角星"},
    Callback = function(Value) Config.BoxShape = Value end
})
BoxGroup:AddSlider('BoxSize', {
    Text = '大小比例',
    Default = Config.BoxSize,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value) Config.BoxSize = Value end
})
BoxGroup:AddSlider('BoxThickness', {
    Text = '线条粗细',
    Default = Config.BoxThickness,
    Min = 1,
    Max = 5,
    Rounding = 0,
    Callback = function(Value) Config.BoxThickness = Value end
})
BoxGroup:AddSlider('BoxSpeed', {
    Text = '旋转速度',
    Default = Config.BoxSpeed,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Callback = function(Value) Config.BoxSpeed = Value end
})
BoxGroup:AddSlider('BoxTransparency', {
    Text = '透明度',
    Default = Config.BoxTransparency,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value) Config.BoxTransparency = Value end
})
BoxGroup:AddLabel('锁定框颜色'):AddColorPicker('BoxColor', {
    Default = Config.BoxColor,
    Title = '锁定框颜色',
    Callback = function(Value) Config.BoxColor = Value end
})
BoxGroup:AddToggle('RainbowBox', {
    Text = '彩虹渐变模式',
    Default = Config.RainbowBox,
    Callback = function(Value) Config.RainbowBox = Value end
})
BoxGroup:AddToggle('BoxBreathing', {
    Text = '呼吸灯效果',
    Default = Config.BoxBreathing,
    Callback = function(Value) Config.BoxBreathing = Value end
})

local TracerGroup = VisualsTab:AddLeftGroupbox("追踪线样式")
TracerGroup:AddToggle('TracerVisible', {
    Text = '显示追踪线',
    Default = Config.TracerVisible,
    Callback = function(Value) Config.TracerVisible = Value end
})
TracerGroup:AddSlider('TracerThickness', {
    Text = '线条粗细',
    Default = Config.TracerThickness,
    Min = 1,
    Max = 5,
    Rounding = 0,
    Callback = function(Value) Config.TracerThickness = Value end
})
TracerGroup:AddSlider('TracerTransparency', {
    Text = '透明度',
    Default = Config.TracerTransparency,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value) Config.TracerTransparency = Value end
})
TracerGroup:AddLabel('追踪线颜色'):AddColorPicker('TracerColor', {
    Default = Config.TracerColor,
    Title = '追踪线颜色',
    Callback = function(Value) Config.TracerColor = Value end
})
TracerGroup:AddToggle('RainbowTracer', {
    Text = '彩虹渐变模式',
    Default = Config.RainbowTracer,
    Callback = function(Value) Config.RainbowTracer = Value end
})

local FilterGroup = MiscTab:AddLeftGroupbox("过滤条件")
FilterGroup:AddToggle('TeamCheck', {
    Text = '队伍检查',
    Default = Config.TeamCheck,
    Callback = function(Value) Config.TeamCheck = Value end
})
FilterGroup:AddDropdown('TeamCheckMode', {
    Text = '队伍判断模式',
    Default = Config.TeamCheckMode,
    Values = {"标准", "Attribute", "Object", "Folder", "Leaderstats"},
    Callback = function(Value) Config.TeamCheckMode = Value end
})
FilterGroup:AddToggle('CoverCheck', {
    Text = '可见性检查 (防墙)',
    Default = Config.CoverCheck,
    Callback = function(Value) Config.CoverCheck = Value end
})
FilterGroup:AddToggle('MultiPointCheck', {
    Text = '多点检测',
    Default = Config.MultiPointCheck,
    Callback = function(Value) Config.MultiPointCheck = Value end
})
FilterGroup:AddSlider('MaxDistance', {
    Text = '最大锁定距离',
    Default = Config.MaxDistance,
    Min = 100,
    Max = 5000,
    Rounding = 0,
    Callback = function(Value) Config.MaxDistance = Value end
})

local NotifyGroup = MiscTab:AddRightGroupbox("通知系统")
NotifyGroup:AddToggle('NotificationEnabled', {
    Text = '启用屏幕通知',
    Default = Config.NotificationEnabled,
    Callback = function(Value) Config.NotificationEnabled = Value end
})
NotifyGroup:AddSlider('NotificationCooldown', {
    Text = '通知冷却时间',
    Default = Config.NotificationCooldown,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Callback = function(Value) Config.NotificationCooldown = Value end
})
NotifyGroup:AddInput('TextLocked', {
    Text = '锁定提示词',
    Default = Config.TextLocked,
    Callback = function(Value) Config.TextLocked = Value end
})
NotifyGroup:AddInput('TextUnlocked', {
    Text = '解锁提示词',
    Default = Config.TextUnlocked,
    Callback = function(Value) Config.TextUnlocked = Value end
})
NotifyGroup:AddInput('TextLost', {
    Text = '丢失提示词',
    Default = Config.TextLost,
    Callback = function(Value) Config.TextLost = Value end
})

local AdminGroup = MiscTab:AddRightGroupbox("安全防护")
AdminGroup:AddToggle('AdminWatchdog', {
    Text = '管理员检测',
    Default = Config.AdminWatchdog,
    Callback = function(Value) Config.AdminWatchdog = Value end
})

local function UpdateListDropdowns()
    local whitelistNames = {}
    for id, _ in pairs(Config.Whitelist) do
        local p = Players:GetPlayerByUserId(id)
        if p then table.insert(whitelistNames, p.Name) end
    end
    if #whitelistNames == 0 then whitelistNames = {"无"} end
    Options.WhitelistMembers:SetValues(whitelistNames)

    local blacklistNames = {}
    for id, _ in pairs(Config.Blacklist) do
        local p = Players:GetPlayerByUserId(id)
        if p then table.insert(blacklistNames, p.Name) end
    end
    if #blacklistNames == 0 then blacklistNames = {"无"} end
    Options.BlacklistMembers:SetValues(blacklistNames)

    local teamWhiteNames = {}
    for name, _ in pairs(Config.TeamWhitelist) do
        table.insert(teamWhiteNames, name)
    end
    if #teamWhiteNames == 0 then teamWhiteNames = {"无"} end
    Options.TeamWhitelistMembers:SetValues(teamWhiteNames)

    local teamBlackNames = {}
    for name, _ in pairs(Config.TeamBlacklist) do
        table.insert(teamBlackNames, name)
    end
    if #teamBlackNames == 0 then teamBlackNames = {"无"} end
    Options.TeamBlacklistMembers:SetValues(teamBlackNames)
end

local function GetPlayer(String)
    if not String or String == "" then return nil end
    local Exact = Players:FindFirstChild(String)
    if Exact then return Exact end
    String = String:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #String) == String then
            return p
        end
        if p.DisplayName:lower():sub(1, #String) == String then
            return p
        end
    end
    return nil
end

local function GetTeam(String)
    if not String or String == "" then return nil end
    local Exact = Teams:FindFirstChild(String)
    if Exact then return Exact end
    String = String:lower()
    for _, t in ipairs(Teams:GetTeams()) do
        if t.Name:lower():sub(1, #String) == String then
            return t
        end
    end
    return nil
end

local PlayerListGroup = ListsTab:AddLeftGroupbox("玩家名单管理")
PlayerListGroup:AddToggle('WhitelistEnabled', {
    Text = '启用白名单',
    Default = Config.WhitelistEnabled,
    Callback = function(Value) Config.WhitelistEnabled = Value end
})
PlayerListGroup:AddDropdown('WhitelistMembers', {
    Text = '当前白名单列表',
    Values = {"无"},
    Default = 1,
    Multi = false
})
PlayerListGroup:AddInput('AddWhitelist', {
    Text = '添加/移除 白名单',
    Placeholder = '输入玩家名称',
    Callback = function(Value)
        local p = GetPlayer(Value)
        if p then
            if Config.Whitelist[p.UserId] then
                Config.Whitelist[p.UserId] = nil
                Library:Notify("已从白名单移除: " .. p.Name)
            else
                Config.Whitelist[p.UserId] = true
                Config.Blacklist[p.UserId] = nil
                Library:Notify("已添加至白名单: " .. p.Name)
            end
            UpdateListDropdowns()
        else
            Library:Notify("添加错误 " .. Value .. " 不存在")
        end
    end
})

PlayerListGroup:AddToggle('BlacklistEnabled', {
    Text = '启用黑名单',
    Default = Config.BlacklistEnabled,
    Callback = function(Value) Config.BlacklistEnabled = Value end
})
PlayerListGroup:AddDropdown('BlacklistMembers', {
    Text = '当前黑名单列表',
    Values = {"无"},
    Default = 1,
    Multi = false
})
PlayerListGroup:AddInput('AddBlacklist', {
    Text = '添加/移除 黑名单',
    Placeholder = '输入玩家名称',
    Callback = function(Value)
        local p = GetPlayer(Value)
        if p then
            if Config.Blacklist[p.UserId] then
                Config.Blacklist[p.UserId] = nil
                Library:Notify("已从黑名单移除: " .. p.Name)
            else
                Config.Blacklist[p.UserId] = true
                Config.Whitelist[p.UserId] = nil
                Library:Notify("已添加至黑名单: " .. p.Name)
            end
            UpdateListDropdowns()
        else
            Library:Notify("添加错误 " .. Value .. " 不存在")
        end
    end
})

local TeamListGroup = ListsTab:AddRightGroupbox("队伍名单管理")
TeamListGroup:AddToggle('TeamWhitelistEnabled', {
    Text = '启用队伍白名单',
    Default = Config.TeamWhitelistEnabled,
    Callback = function(Value) Config.TeamWhitelistEnabled = Value end
})
TeamListGroup:AddDropdown('TeamWhitelistMembers', {
    Text = '当前白名单队伍',
    Values = {"无"},
    Default = 1,
    Multi = false
})
TeamListGroup:AddInput('AddTeamWhitelist', {
    Text = '添加/移除 白名单队伍',
    Placeholder = '输入队伍名称',
    Callback = function(Value)
        local t = GetTeam(Value)
        if t then
            if Config.TeamWhitelist[t.Name] then
                Config.TeamWhitelist[t.Name] = nil
                Library:Notify("已移除白名单队伍: " .. t.Name)
            else
                Config.TeamWhitelist[t.Name] = true
                Library:Notify("已添加白名单队伍: " .. t.Name)
            end
            UpdateListDropdowns()
        else
            Library:Notify("添加错误 " .. Value .. " 不存在")
        end
    end
})

TeamListGroup:AddToggle('TeamBlacklistEnabled', {
    Text = '启用队伍黑名单',
    Default = Config.TeamBlacklistEnabled,
    Callback = function(Value) Config.TeamBlacklistEnabled = Value end
})
TeamListGroup:AddDropdown('TeamBlacklistMembers', {
    Text = '当前黑名单队伍',
    Values = {"无"},
    Default = 1,
    Multi = false
})
TeamListGroup:AddInput('AddTeamBlacklist', {
    Text = '添加/移除 黑名单队伍',
    Placeholder = '输入队伍名称',
    Callback = function(Value)
        local t = GetTeam(Value)
        if t then
            if Config.TeamBlacklist[t.Name] then
                Config.TeamBlacklist[t.Name] = nil
                Library:Notify("已移除黑名单队伍: " .. t.Name)
            else
                Config.TeamBlacklist[t.Name] = true
                Library:Notify("已添加黑名单队伍: " .. t.Name)
            end
            UpdateListDropdowns()
        else
            Library:Notify("添加错误 " .. Value .. " 不存在")
        end
    end
})

Library:SetWatermark("PureLock System - Obsidian")

local isLocked = false
local currentTarget = nil
local lockedUserId = nil
local legitOffset = Vector3.zero
local lastLockTime = 0
local previouslyLockedId = nil
local lastHealth = 0
local healthConnection = nil
local SharedPart = nil
local lastShotTime = 0

local function getPositionOnScreen(Vector)
    if not Camera then return Vector2.zero, false end
    local Vec3, OnScreen = Camera:WorldToViewportPoint(Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function EnsureBoxVisuals(targetChar)
    if not Config.BoxVisible then CleanupVisuals() return end
    if not targetChar then CleanupVisuals() return end
    local root = targetChar:FindFirstChild("HumanoidRootPart")
    local torso = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso") or root
    if not root or not torso then CleanupVisuals() return end
    
    if not visualEffect or not visualEffect.Parent then
        CleanupVisuals()
        local bb = Instance.new("BillboardGui", CoreGui)
        bb.Name = "LockBox"
        bb.Adornee = torso
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 0, 0, 0)
        local container = Instance.new("Frame", bb)
        container.Name = "MainFrame"
        container.Size = UDim2.new(1,0,1,0)
        container.BackgroundTransparency = 1
        container.AnchorPoint = Vector2.new(0.5,0.5)
        container.Position = UDim2.fromScale(0.5,0.5)
        Instance.new("UIAspectRatioConstraint", container).AspectRatio = 1
        visualEffect = bb
    else
        visualEffect.Enabled = true
        visualEffect.Adornee = torso
        local size = torso.Size.X * Config.BoxSize
        if Config.BoxBreathing then
             local scale = 1 + math.sin(tick() * 5) * 0.1
             size = size * scale
        end
        visualEffect.Size = UDim2.new(0, size, 0, size)
    end
    
    local mf = visualEffect:FindFirstChild("MainFrame")
    if mf then
        if not mf:FindFirstChild("Line") then
            local function Line(p, a, s, r)
                local f = Instance.new("Frame", mf)
                f.Name = "Line"
                f.BorderSizePixel = 0
                f.Position = p; f.AnchorPoint = a; f.Size = s
                f.BackgroundColor3 = Config.BoxColor
                f.BackgroundTransparency = Config.BoxTransparency
                if r then f.Rotation = r end
                return f
            end

            local function DrawPoly(points)
                for i = 1, #points do
                    local p1 = points[i]
                    local p2 = points[(i % #points) + 1]
                    local center = (p1 + p2) / 2
                    local dist = (p2 - p1).Magnitude
                    local angle = math.atan2(p2.Y - p1.Y, p2.X - p1.X)
                    Line(UDim2.new(center.X, 0, center.Y, 0), Vector2.new(0.5, 0.5), UDim2.new(dist, 0, 0, Config.BoxThickness), math.deg(angle))
                end
            end

            if Config.BoxShape == "方框" then
                local l, w = UDim2.new(0.43, 0, 0, Config.BoxThickness), UDim2.new(0, Config.BoxThickness, 0.43, 0)
                Line(UDim2.new(0,0,0,0), Vector2.new(0,0), l); Line(UDim2.new(0,0,0,0), Vector2.new(0,0), w)
                Line(UDim2.new(1,0,0,0), Vector2.new(1,0), l); Line(UDim2.new(1,0,0,0), Vector2.new(1,0), w)
                Line(UDim2.new(0,0,1,0), Vector2.new(0,1), l); Line(UDim2.new(0,0,1,0), Vector2.new(0,1), w)
                Line(UDim2.new(1,0,1,0), Vector2.new(1,1), l); Line(UDim2.new(1,0,1,0), Vector2.new(1,1), w)
            elseif Config.BoxShape == "三角形" then
                local p1, p2, p3 = Vector2.new(0.5, 0), Vector2.new(1, 1), Vector2.new(0, 1)
                local function DrawCorner(c, n1, n2)
                    local dir1, dir2 = (n1-c).Unit, (n2-c).Unit
                    local len = 0.3
                    local l1 = c + dir1 * len
                    local l2 = c + dir2 * len
                    local dist1, dist2 = (l1-c).Magnitude, (l2-c).Magnitude
                    local angle1 = math.atan2(dir1.Y, dir1.X)
                    local angle2 = math.atan2(dir2.Y, dir2.X)
                    local center1, center2 = (c+l1)/2, (c+l2)/2
                    Line(UDim2.new(center1.X, 0, center1.Y, 0), Vector2.new(0.5, 0.5), UDim2.new(dist1, 0, 0, Config.BoxThickness), math.deg(angle1))
                    Line(UDim2.new(center2.X, 0, center2.Y, 0), Vector2.new(0.5, 0.5), UDim2.new(dist2, 0, 0, Config.BoxThickness), math.deg(angle2))
                end
                DrawCorner(p1, p2, p3)
                DrawCorner(p2, p1, p3)
                DrawCorner(p3, p1, p2)
            elseif Config.BoxShape == "五角星" then
                local pts = {}
                for i = 0, 4 do
                    local angle = math.rad(-90 + i * 72)
                    table.insert(pts, Vector2.new(0.5 + 0.5 * math.cos(angle), 0.5 + 0.5 * math.sin(angle)))
                end
                local starOrder = {pts[1], pts[3], pts[5], pts[2], pts[4]}
                DrawPoly(starOrder)
            elseif Config.BoxShape == "六角星" then
                DrawPoly({Vector2.new(0.5, 0), Vector2.new(0.933, 0.75), Vector2.new(0.067, 0.75)})
                DrawPoly({Vector2.new(0.5, 1), Vector2.new(0.933, 0.25), Vector2.new(0.067, 0.25)})
            end
        end
        
        mf.Rotation = mf.Rotation + Config.BoxSpeed
        local breathingAlpha = 1
        if Config.BoxBreathing then
            breathingAlpha = (math.sin(tick() * 5) + 1) / 2
        end
        
        local rainbowColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
        
        for _, v in pairs(mf:GetChildren()) do
            if v:IsA("Frame") then
                if Config.RainbowBox then
                    v.BackgroundColor3 = rainbowColor
                else
                    v.BackgroundColor3 = Config.BoxColor
                end
                
                if Config.BoxBreathing then
                    v.BackgroundTransparency = Config.BoxTransparency + (1 - Config.BoxTransparency) * (1 - breathingAlpha) * 0.7
                else
                    v.BackgroundTransparency = Config.BoxTransparency
                end
                if Config.BoxShape ~= "方框" and Config.BoxShape ~= "三角形" then v.Size = UDim2.new(v.Size.X.Scale, v.Size.X.Offset, 0, Config.BoxThickness) end
            end
        end
    end
end

local function IsPartVisible(part, ignoreList)
    if not part then return false end
    local origin = Camera.CFrame.Position
    local dest = part.Position
    local direction = dest - origin
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList
    params.IgnoreWater = true
    
    local blocked = false
    local currentOrigin = origin
    local currentDir = direction
    local iterations = 0
    
    while iterations < 10 do
        iterations = iterations + 1
        local result = workspace:Raycast(currentOrigin, currentDir, params)
        if not result then
            break
        else
            if result.Instance:IsDescendantOf(part.Parent) then
                break
            else
                if not result.Instance.CanCollide then
                    local newIgnore = params.FilterDescendantsInstances
                    table.insert(newIgnore, result.Instance)
                    params.FilterDescendantsInstances = newIgnore
                    currentOrigin = result.Position + (currentDir.Unit * 0.1)
                    currentDir = dest - currentOrigin
                else
                    blocked = true
                    break
                end
            end
        end
    end
    return not blocked
end

local function CheckCover(model)
    local root = model:FindFirstChild("HumanoidRootPart")
    local head = model:FindFirstChild("Head")
    if not root or not head then return false end
    
    local partsToCheck = {head}
    if Config.MultiPointCheck then
        table.insert(partsToCheck, root)
        local possibleParts = {"Left Arm", "Right Arm", "Left Leg", "Right Leg", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftUpperLeg", "RightUpperLeg", "LeftHand", "RightHand", "LeftFoot", "RightFoot"}
        for _, name in pairs(possibleParts) do
            local p = model:FindFirstChild(name)
            if p then table.insert(partsToCheck, p) end
        end
    end

    local ignoreList = {LocalPlayer.Character, Camera}
    for _, part in pairs(partsToCheck) do
        if IsPartVisible(part, ignoreList) then return true end
    end
    return false
end

local function GetTargetPart(char)
    if not char then return "Torso" end
    
    if Config.AimPart == "头部" then
        if Config.WallCheckFallback then
            local head = char:FindFirstChild("Head")
            local torso = char:FindFirstChild("HumanoidRootPart")
            if head and torso then
                local ignoreList = {LocalPlayer.Character, Camera}
                if not IsPartVisible(head, ignoreList) then
                    if IsPartVisible(torso, ignoreList) then
                        return "HumanoidRootPart"
                    end
                end
            end
        end
        return "Head"
    end

    if Config.AimPart == "躯干" then
        if Config.HeadshotChance > 0 and char:FindFirstChild("Head") and math.random(1,100) <= Config.HeadshotChance then
            if not Config.CoverCheck or CheckCover(char) then return "Head" end
        end
        return "HumanoidRootPart"
    end
    
    local parts = {}
    if Config.AimPart == "随机" then
        for _, v in pairs(char:GetChildren()) do if v:IsA("BasePart") then table.insert(parts, v.Name) end end
    elseif Config.AimPart == "手臂" then
        parts = {"Left Arm","Right Arm","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm"}
    elseif Config.AimPart == "腿部" then
        parts = {"Left Leg","Right Leg","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg"}
    end
    
    local visibleParts = {}
    for _, name in ipairs(parts) do
        local p = char:FindFirstChild(name)
        if p then table.insert(visibleParts, name) end
    end
    
    if #visibleParts > 0 then
        local mousePos = UserInputService:GetMouseLocation()
        table.sort(visibleParts, function(a,b)
            local p1 = Camera:WorldToViewportPoint(char[a].Position)
            local p2 = Camera:WorldToViewportPoint(char[b].Position)
            return (Vector2.new(p1.X, p1.Y) - mousePos).Magnitude < (Vector2.new(p2.X, p2.Y) - mousePos).Magnitude
        end)
        return visibleParts[1]
    end
    
    return "Torso"
end

local function IsTeammate(p)
    if not Config.TeamCheck then return false end
    if p == LocalPlayer then return true end
    
    local mode = Config.TeamCheckMode or "标准"
    
    if mode == "标准" then
        if p.Team and p.Team == LocalPlayer.Team then return true end
    elseif mode == "Attribute" then
        local myTeam = LocalPlayer:GetAttribute("Team") or LocalPlayer:GetAttribute("Side") or LocalPlayer:GetAttribute("Faction")
        local theirTeam = p:GetAttribute("Team") or p:GetAttribute("Side") or p:GetAttribute("Faction")
        if myTeam and theirTeam and myTeam == theirTeam then return true end
        if LocalPlayer.Character and p.Character then
            local myCharTeam = LocalPlayer.Character:GetAttribute("Team") or LocalPlayer.Character:GetAttribute("Side") or LocalPlayer.Character:GetAttribute("Faction")
            local theirCharTeam = p.Character:GetAttribute("Team") or p.Character:GetAttribute("Side") or p.Character:GetAttribute("Faction")
            if myCharTeam and theirCharTeam and myCharTeam == theirCharTeam then return true end
        end
    elseif mode == "Object" then
        if LocalPlayer.Character and p.Character then
             local function findVal(parent)
                for _, c in ipairs(parent:GetChildren()) do
                    if c:IsA("StringValue") or c:IsA("IntValue") or c:IsA("ObjectValue") then
                        if c.Name == "Team" or c.Name == "TeamName" or c.Name == "Squad" then return c.Value end
                    end
                end
             end
             local myVal = findVal(LocalPlayer.Character)
             local theirVal = findVal(p.Character)
             if myVal and theirVal and myVal == theirVal then return true end
        end
    elseif mode == "Folder" then
        if LocalPlayer.Character and p.Character and LocalPlayer.Character.Parent and p.Character.Parent then
            if LocalPlayer.Character.Parent == p.Character.Parent and LocalPlayer.Character.Parent ~= workspace then
                return true
            end
        end
    elseif mode == "Leaderstats" then
        if LocalPlayer:FindFirstChild("leaderstats") and p:FindFirstChild("leaderstats") then
            local myTeam = LocalPlayer.leaderstats:FindFirstChild("Team") or LocalPlayer.leaderstats:FindFirstChild("Side") or LocalPlayer.leaderstats:FindFirstChild("Faction")
            local theirTeam = p.leaderstats:FindFirstChild("Team") or p.leaderstats:FindFirstChild("Side") or p.leaderstats:FindFirstChild("Faction")
            if myTeam and theirTeam and myTeam.ClassName == theirTeam.ClassName and myTeam.Value == theirTeam.Value then
                return true
            end
        end
    end
    return false
end

local function GetSortedTarget()
    if not LocalPlayer.Character then return nil end
    local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    if not Camera then return nil end
    local mousePos = Config.FixedFOV and (Camera.ViewportSize / 2) or UserInputService:GetMouseLocation()
    
    local targets = {}
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if Config.WhitelistEnabled and Config.Whitelist[p.UserId] then continue end 
            if Config.BlacklistEnabled and Config.Blacklist[p.UserId] then continue end
            if Config.TeamWhitelistEnabled then
                if not p.Team and not Config.TeamWhitelist["Neutral"] then continue end
                if p.Team and not Config.TeamWhitelist[p.Team.Name] then continue end
            end
            if Config.TeamBlacklistEnabled then
                if not p.Team and Config.TeamBlacklist["Neutral"] then continue end
                if p.Team and Config.TeamBlacklist[p.Team.Name] then continue end
            end
            
            if IsTeammate(p) then continue end
            
            local char = p.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 then
                local dist = (root.Position - myRoot.Position).Magnitude
                if dist <= Config.MaxDistance then
                    local sPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if (not Config.UseFOV) or onScreen then
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
    
    if #targets == 0 then return nil end
    
    table.sort(targets, function(a, b)
        if Config.PriorityMode == "最低血量" then
            return a.Health < b.Health
        elseif Config.PriorityMode == "最近距离" then
            return a.Dist < b.Dist
        else
            return a.Fov < b.Fov
        end
    end)
    
    return targets[1].Char
end

local lastSearch = 0

Library:OnUnload(function()
    CleanupVisuals()
    if VisualsGui then VisualsGui:Destroy() end
    if QuickButtonGui then QuickButtonGui:Destroy() end
    for _, conn in ipairs(Connections) do
        if conn then conn:Disconnect() end
    end
    Connections = {}
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({'MenuKeybind'})
ThemeManager:SetFolder('PureLockObsidian')
SaveManager:SetFolder('PureLockObsidian/configs')
SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToTab(SettingsTab)

SettingsTab:AddLeftGroupbox("快捷键绑定"):AddLabel("菜单开/关"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "菜单开关" }) 
Library.ToggleKeybind = Options.MenuKeybind 

AimGeneralGroup:AddToggle('AimEnabled', {
    Text = '开启锁定功能',
    Default = false,
    Callback = function(Value)
        isLocked = Value
        if not isLocked then
            ShowNotification(Config.TextUnlocked, "Unlock")
            currentTarget = nil
            lockedUserId = nil
            previouslyLockedId = nil
            if healthConnection then
                healthConnection:Disconnect()
                healthConnection = nil
            end
            CleanupVisuals()
        end
        UpdateQuickButtons()
    end
}):AddKeyPicker('AimKeybind', {
    Default = 'C',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = '锁定按键',
    NoUI = false,
})

AimGeneralGroup:AddToggle('AimQuickButtonEnabled', {
    Text = '启用自瞄快捷按钮',
    Default = Config.AimQuickButtonEnabled,
    Callback = function(Value)
        Config.AimQuickButtonEnabled = Value
        UpdateQuickButtons()
    end
})
AimGeneralGroup:AddSlider('AimQuickButtonSize', {
    Text = '按钮大小',
    Default = Config.AimQuickButtonSize,
    Min = 20,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        Config.AimQuickButtonSize = Value
        UpdateQuickButtons()
    end
})
AimGeneralGroup:AddSlider('AimQuickButtonTransparency', {
    Text = '按钮透明度',
    Default = Config.AimQuickButtonTransparency,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        Config.AimQuickButtonTransparency = Value
        UpdateQuickButtons()
    end
})

SetupQuickButton(AimButton, "自瞄", 0, Toggles.AimEnabled, Config.AimQuickButtonSize, Config.AimQuickButtonTransparency)

local function CheckAdmin(player)
    if not Config.AdminWatchdog then return end
    if player:GetAttribute("isAdmin") or player:GetAttribute("Admin") or player:GetAttribute("Rank") then
        ShowNotification("警告: 疑似管理员在场 - " .. player.Name, "Danger", true)
    end
end

table.insert(Connections, Players.PlayerAdded:Connect(CheckAdmin))
for _, p in pairs(Players:GetPlayers()) do CheckAdmin(p) end

table.insert(Connections, RunService.Heartbeat:Connect(function()
    local t = GetSortedTarget()
    if t then
        SharedPart = t:FindFirstChild(Config.AimPart) or t:FindFirstChild("HumanoidRootPart")
    else
        SharedPart = nil
    end
end))

table.insert(Connections, workspace.ChildAdded:Connect(function(child)
    if Config.BulletTPMode == "无" or not SharedPart then return end
    task.wait()
    if not SharedPart or not SharedPart.Parent then return end
    
    if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
         if Config.BulletTPMode == "坐标传送" then
             child.CFrame = CFrame.new(SharedPart.Position)
         elseif Config.BulletTPMode == "骨骼传送" then
             child.CFrame = SharedPart.CFrame
         end
    end
end))

table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
    local now = tick()
    
    if Config.ContinuousLock then
        isLocked = Options.AimKeybind:GetState()
    end
    
    local rainbowColor = Color3.fromHSV(now % 5 / 5, 1, 1)
    if Config.RainbowFOV then Config.FOVColor = rainbowColor end
    if Config.RainbowBox then Config.BoxColor = rainbowColor end
    if Config.RainbowRing then Config.RingColor = rainbowColor end
    if Config.RainbowTracer then Config.TracerColor = rainbowColor end
    
    FOVStroke.Color = Config.FOVColor

    local currentCameraFOV = Camera.FieldOfView
    local scaledMaxFOV = Config.UserFOVRadius * (70 / currentCameraFOV)
    local targetRadius = Config.UserFOVRadius

    if Config.SmartFOV then
        targetRadius = scaledMaxFOV
        if isLocked and currentTarget then
            local part = currentTarget:FindFirstChild(Config.AimPart) or currentTarget:FindFirstChild("HumanoidRootPart")
            if part then
                local dist = (part.Position - Camera.CFrame.Position).Magnitude
                targetRadius = math.clamp(Config.UserFOVRadius * (60 / dist), Config.SmartFOVMin, scaledMaxFOV)
            end
        end
    end
    
    Config.FOVRadius = Config.FOVRadius + (targetRadius - Config.FOVRadius) * math.clamp(dt * Config.SmartFOVSpeed, 0, 1)
    
    FOVCircleFrame.Size = UDim2.fromOffset(Config.FOVRadius*2, Config.FOVRadius*2)

    local mousePos = Config.FixedFOV and (Camera.ViewportSize / 2) or UserInputService:GetMouseLocation()
    
    if Config.FOVVisible and Camera then
        FOVCircleFrame.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
        FOVCircleFrame.Visible = true
    else
        FOVCircleFrame.Visible = false
    end
    
    local usedPrediction = Config.PredictionAmount

    if Config.SmartPrediction and Config.PredictionEnabled then
        local ping = 100
        local success, result = pcall(function()
             return LocalPlayer:GetNetworkPing() * 1000
        end)
        if not success then
             pcall(function()
                 if StatsService then
                     ping = StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
                 end
             end)
        else
             ping = result
        end
        
        local base = ping / 1000 
        usedPrediction = math.clamp(base, 0, 5)
    end
    
    local activeTarget = nil
    
    if isLocked and Camera then
        if now - lastSearch > 0.1 then
            lastSearch = now
            if not lockedUserId then
                local t = GetSortedTarget()
                if t then 
                    if Players:GetPlayerFromCharacter(t) then
                        lockedUserId = Players:GetPlayerFromCharacter(t).UserId 
                        lastLockTime = now
                        if Config.LegitMode then
                            legitOffset = Vector3.new(math.random(-Config.AimOffset*10, Config.AimOffset*10)/10, math.random(-Config.AimOffset*10, Config.AimOffset*10)/10, math.random(-Config.AimOffset*10, Config.AimOffset*10)/10)
                        end
                    end
                end
            end
        end
        
        if lockedUserId then
            if lockedUserId ~= previouslyLockedId then
                local p = Players:GetPlayerByUserId(lockedUserId)
                if p then
                    ShowNotification(Config.TextLocked .. " : " .. p.Name, "Lock")
                end
                previouslyLockedId = lockedUserId
                if healthConnection then healthConnection:Disconnect(); healthConnection = nil end
            end

            local p = Players:GetPlayerByUserId(lockedUserId)
            if not p then
                if Config.ContinuousLock then
                     lockedUserId = nil; currentTarget = nil
                     previouslyLockedId = nil
                else
                     currentTarget = nil 
                     lockedUserId = nil
                     ShowNotification(Config.TextLost, "Warn")
                     if healthConnection then healthConnection:Disconnect(); healthConnection = nil end
                     CleanupVisuals()
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
                            if Players:GetPlayerFromCharacter(nt) then
                                lockedUserId = Players:GetPlayerFromCharacter(nt).UserId; char = nt 
                                lastLockTime = now
                                if Config.LegitMode then
                                    legitOffset = Vector3.new(math.random(-Config.AimOffset*10, Config.AimOffset*10)/10, math.random(-Config.AimOffset*10, Config.AimOffset*10)/10, math.random(-Config.AimOffset*10, Config.AimOffset*10)/10)
                                end
                            end
                        else 
                            lockedUserId = nil; currentTarget = nil
                            ShowNotification("无可用目标", "Warn")
                            previouslyLockedId = nil
                            if healthConnection then healthConnection:Disconnect(); healthConnection = nil end
                        end
                    else
                         currentTarget = nil
                         lockedUserId = nil
                         ShowNotification("目标无效", "Warn")
                         if healthConnection then healthConnection:Disconnect(); healthConnection = nil end
                         CleanupVisuals()
                    end
                else
                    currentTarget = char
                end
                
                activeTarget = currentTarget
                
                local finalPart = GetTargetPart(currentTarget)

                if currentTarget and currentTarget:FindFirstChild(finalPart) then
                    EnsureBoxVisuals(currentTarget)
                    
                    local tracerDrawn = false
                    if Config.TracerVisible and currentTarget and visualEffect and visualEffect.Adornee then
                        local targetPos, onScreen = Camera:WorldToViewportPoint(visualEffect.Adornee.Position)
                        if onScreen then
                            local fovCenter = Config.FixedFOV and (Camera.ViewportSize / 2) or UserInputService:GetMouseLocation()
                            local targetVec2 = Vector2.new(targetPos.X, targetPos.Y)
                            local length = (targetVec2 - fovCenter).Magnitude
                            local center = (targetVec2 + fovCenter) / 2
                            local angle = math.atan2(targetVec2.Y - fovCenter.Y, targetVec2.X - fovCenter.X)
                            
                            TracerLineFrame.Visible = true
                            TracerLineFrame.BackgroundColor3 = Config.TracerColor
                            TracerLineFrame.BackgroundTransparency = Config.TracerTransparency
                            TracerLineFrame.Size = UDim2.fromOffset(length, Config.TracerThickness)
                            TracerLineFrame.Position = UDim2.fromOffset(center.X, center.Y)
                            TracerLineFrame.Rotation = math.deg(angle)
                            tracerDrawn = true
                        end
                    end
                    if not tracerDrawn then TracerLineFrame.Visible = false end
                    
                    local proceed = true
                    if Config.LegitMode then
                        if (now - lastLockTime < Config.ReactionDelay) then proceed = false end
                        if math.random(1, 100) <= Config.MissChance then proceed = false end
                    end
                    
                    if proceed then
                        local aimPos = currentTarget[finalPart].Position
                        
                        if Config.LegitMode then 
                            aimPos = aimPos + legitOffset 
                            if Config.ShakePower > 0 then
                                aimPos = aimPos + Vector3.new(
                                    (math.random() - 0.5) * 2 * Config.ShakePower,
                                    (math.random() - 0.5) * 2 * Config.ShakePower,
                                    (math.random() - 0.5) * 2 * Config.ShakePower
                                )
                            end
                        end
                        
                        if Config.PredictionEnabled and currentTarget:FindFirstChild("HumanoidRootPart") then
                            local t = usedPrediction
                            local vel = currentTarget.HumanoidRootPart.AssemblyLinearVelocity
                            aimPos = aimPos + (vel * t)
                        end
                        
                        local rawSens = math.clamp(Config.Sensitivity, 0, 100)
                        local lerpFactor = (100 - rawSens) / 100
                        
                        if Config.LegitMode then
                            local x = math.clamp(lerpFactor, 0, 1)
                            if Config.SmoothnessCurve == "正弦" then
                                lerpFactor = math.sin(x * math.pi / 2)
                            elseif Config.SmoothnessCurve == "二次方" then
                                lerpFactor = x * x
                            elseif Config.SmoothnessCurve == "指数" then
                                lerpFactor = 2^(10 * (x - 1))
                            elseif Config.SmoothnessCurve == "圆形" then
                                lerpFactor = 1 - math.sqrt(1 - x * x)
                            elseif Config.SmoothnessCurve == "弹性" then
                                 lerpFactor = x == 0 and 0 or x == 1 and 1 or -2^(10 * x - 10) * math.sin((x * 10 - 10.75) * ((2 * math.pi) / 3))
                            end
                        end
                        
                        if Config.LockMode == "人物" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            pcall(function()
                                LocalPlayer.Character.Humanoid.AutoRotate = false
                                local currentCF = LocalPlayer.Character.HumanoidRootPart.CFrame
                                local targetLook = CFrame.lookAt(currentCF.Position, Vector3.new(aimPos.X, currentCF.Position.Y, aimPos.Z))
                                LocalPlayer.Character.HumanoidRootPart.CFrame = currentCF:Lerp(targetLook, lerpFactor)
                            end)
                        else
                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then 
                                pcall(function() LocalPlayer.Character.Humanoid.AutoRotate = true end)
                            end
                            local curCF = Camera.CFrame
                            local targetCF = CFrame.lookAt(curCF.Position, aimPos)
                            Camera.CFrame = curCF:Lerp(targetCF, lerpFactor)
                        end
                    end
                else
                    CleanupVisuals()
                    TracerLineFrame.Visible = false
                end
            end
        end
    else
        if Config.SilentEnabled and SharedPart and SharedPart.Parent then
            activeTarget = SharedPart.Parent
            if Config.BoxVisible then
                EnsureBoxVisuals(SharedPart.Parent)
            else
                CleanupVisuals()
            end
        else
            CleanupVisuals()
        end
        TracerLineFrame.Visible = false
        lockedUserId = nil
        previouslyLockedId = nil
        currentTarget = nil
        if healthConnection then healthConnection:Disconnect(); healthConnection = nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.AutoRotate = true
        end
    end
    
    if activeTarget and activeTarget:FindFirstChild("Humanoid") then
        if not healthConnection then
            lastHealth = activeTarget.Humanoid.Health
            healthConnection = activeTarget.Humanoid.HealthChanged:Connect(function(newHealth)
                local diff = lastHealth - newHealth
                if diff > 0 then
                    if Config.HitSound ~= "关闭" and HitSounds[Config.HitSound] then
                        playHitSound(HitSounds[Config.HitSound])
                    end
                    if Config.ShowDamage and activeTarget:FindFirstChild("Head") then
                        createDamageIndicator(activeTarget.Head.Position, diff)
                    end
                end
                lastHealth = newHealth
            end)
        end
    end
    
    local currentTime = tick()
    for i = #damageIndicators, 1, -1 do
        local indicator = damageIndicators[i]
        local age = currentTime - indicator.Created
        if age > DAMAGE_INDICATOR_FADE_TIME then
            indicator.TextObject:Remove()
            table.remove(damageIndicators, i)
        else
            local progress = age / DAMAGE_INDICATOR_FADE_TIME
            indicator.TextObject.Position = indicator.Position - Vector2.new(0, progress * INDICATOR_FLOAT_SPEED)
            indicator.TextObject.Transparency = 1 - progress 
        end
    end
end))

SetupQuickButton(SilentButton, "静默", 60, Toggles.SilentEnabled, Config.SilentQuickButtonSize, Config.SilentQuickButtonTransparency)
UpdateQuickButtons()

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = { ArgCountRequired = 3, Args = {"Instance", "Ray", "table", "boolean", "boolean"} },
    FindPartOnRayWithWhitelist = { ArgCountRequired = 3, Args = {"Instance", "Ray", "table", "boolean"} },
    FindPartOnRay = { ArgCountRequired = 2, Args = {"Instance", "Ray", "Instance", "boolean", "boolean"} },
    Raycast = { ArgCountRequired = 3, Args = {"Instance", "Vector3", "Vector3", "RaycastParams"} }
}

local function CalculateChance(Percentage)
    Percentage = math.floor(Percentage)
    return math.random() <= Percentage / 100
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then return false end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]

    if Config.SilentEnabled and not checkcaller() and CalculateChance(Config.SilentHitChance) and SharedPart and SharedPart.Parent then
        local methodMap = {
            ["FindPartOnRay"] = "FindPartOnRay",
            ["FindPartOnRayWithIgnoreList"] = "FindPartOnRayWithIgnoreList",
            ["FindPartOnRayWithWhitelist"] = "FindPartOnRayWithWhitelist",
            ["Raycast"] = "Raycast",
            ["ScreenPointToRay"] = "ScreenPointToRay",
            ["ViewportPointToRay"] = "ViewportPointToRay"
        }
        
        local targetMethod = methodMap[Config.SilentMethod]

        if targetMethod == Method then
            if (Method == "FindPartOnRayWithIgnoreList" or Method == "FindPartOnRayWithWhitelist" or Method == "FindPartOnRay") then
                local expectedArgs = ExpectedArguments[Method] or ExpectedArguments["FindPartOnRay"]
                if ValidateArguments(Arguments, expectedArgs) then
                    if Config.WallbangMode == "SpoofHit" then
                        return SharedPart, SharedPart.Position, SharedPart.CFrame.LookVector, SharedPart.Material
                    end
                    
                    local function getDirection(Origin, Position)
                        return (Position - Origin).Unit * 1000
                    end
                    Arguments[2] = Ray.new(Arguments[2].Origin, getDirection(Arguments[2].Origin, SharedPart.Position))
                    return oldNamecall(unpack(Arguments))
                end
            elseif Method == "Raycast" then
                if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                    local shotOrigin = Arguments[2]
                    
                    if Config.WallbangMode == "RaycastParams" then
                        local direction = (SharedPart.Position - shotOrigin).Unit * 1000
                        local wallbangParams = RaycastParams.new()
                        wallbangParams.FilterType = Enum.RaycastFilterType.Include
                        wallbangParams.FilterDescendantsInstances = {SharedPart.Parent}
                        local newArgs = {self, shotOrigin, direction, wallbangParams}
                        return oldNamecall(unpack(newArgs))
                    elseif Config.WallbangMode == "SpoofHit" then
                        return {
                            Instance = SharedPart,
                            Position = SharedPart.Position,
                            Material = Enum.Material.Plastic,
                            Normal = Vector3.new(0, 1, 0),
                            Distance = (shotOrigin - SharedPart.Position).Magnitude
                        }
                    end
                    
                    if Config.BulletTPMode ~= "无" then
                        Arguments[2] = SharedPart.Position + Vector3.new(0, 2, 0)
                    end
                    
                    Arguments[3] = (SharedPart.Position - Arguments[2]).Unit * 1000
                    return oldNamecall(unpack(Arguments))
                end
            elseif (Method == "ScreenPointToRay" or Method == "ViewportPointToRay") and self == Camera then
                local shotOrigin = Camera.CFrame.Position
                local direction = (SharedPart.Position - shotOrigin).Unit
                return Ray.new(shotOrigin, direction)
            end
        end
    end
    return oldNamecall(...)
end))

local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    if self == Mouse and not checkcaller() and Config.SilentEnabled and 
       (Config.SilentMethod == "Mouse.Hit" or Config.SilentMethod == "Mouse.Target") then
        if SharedPart and SharedPart.Parent then
            if Index == "Target" or Index == "target" then
                if CalculateChance(Config.SilentHitChance) then
                    return SharedPart
                end
            elseif Index == "Hit" or Index == "hit" then
                if CalculateChance(Config.SilentHitChance) then
                    local pos = SharedPart.Position
                    if Config.PredictionEnabled and SharedPart.AssemblyLinearVelocity then
                        pos = pos + (SharedPart.AssemblyLinearVelocity * Config.PredictionAmount)
                    end
                    return CFrame.new(pos)
                end
            elseif Index == "X" or Index == "x" then
                return self.X
            elseif Index == "Y" or Index == "y" then
                return self.Y
            end
        end
    end
    return oldIndex(self, Index)
end))

local oldRayNew
oldRayNew = hookfunction(Ray.new, newcclosure(function(origin, direction)
    if Config.SilentEnabled and (Config.SilentMethod == "Ray.new") and 
       SharedPart and SharedPart.Parent and not checkcaller() and CalculateChance(Config.SilentHitChance) then
        local function getDirection(Origin, Position)
            return (Position - Origin).Unit * 1000
        end
        local newDirectionVector = getDirection(origin, SharedPart.Position)
        return oldRayNew(origin, newDirectionVector)
    end
    return oldRayNew(origin, direction)
end))
