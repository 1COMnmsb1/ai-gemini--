local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Debris = game:GetService("Debris")
local Teams = game:GetService("Teams")
local LocalizationService = game:GetService("LocalizationService")

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

local possiblePartsToCheck = {"Left Arm", "Right Arm", "Left Leg", "Right Leg", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftUpperLeg", "RightUpperLeg", "LeftHand", "RightHand", "LeftFoot", "RightFoot", "Head", "UpperTorso", "LowerTorso", "Torso"}

local Config = {
    Sensitivity = 0, 
    LockMode = "人物", 
    AimPart = "躯干", 
    PredictionEnabled = false,
    SmartPrediction = false,
    PredictionAmount = 0.165,
    TeamCheck = false,
    TeamCheckMode = "队伍标签",
    CoverCheck = false,
    MultiPointScale = 18,
    WallCheckFallback = false, 
    MaxDistance = 2000,
    UseFOV = false,
    FOVVisible = false,
    FOVRadius = 130,
    UserFOVRadius = 130, 
    FixedFOV = false,
    FOVColor = Color3.fromRGB(255, 255, 255),
    FOVThickness = 1,
    FOVTransparency = 0.6,
    BoxVisible = false,
    BoxColor = Color3.fromRGB(255, 255, 255),
    BoxShape = "方框",
    RingColor = Color3.fromRGB(255, 255, 255),
    TracerVisible = false,
    TracerColor = Color3.fromRGB(255, 255, 255),
    TracerThickness = 1,
    TracerTransparency = 0,
    RainbowFOV = false,
    RainbowFOVSpeed = 1,
    RainbowBox = false,
    RainbowBoxSpeed = 1,
    RainbowRing = false,
    RainbowTracer = false,
    RainbowTracerSpeed = 1,
    WhitelistEnabled = false,
    BlacklistEnabled = false,
    Whitelist = {},
    Blacklist = {},
    TeamWhitelistEnabled = false,
    TeamWhitelist = {},
    TeamBlacklistEnabled = false,
    TeamBlacklist = {},
    PriorityMode = "准心优先",
    StickyAiming = false,
    BoxSize = 5.5,
    BoxThickness = 1,
    BoxSpeed = 1,
    BoxTransparency = 0,
    NotificationEnabled = true,
    NotificationDuration = 2.5,
    NotificationCooldown = 0,
    TextLocked = "已锁定",
    TextUnlocked = "已解锁",
    TextLost = "目标丢失",
    TextEliminated = "目标死亡",
    HeadshotChance = 0,
    SilentEnabled = false,
    SilentAimPart = "躯干",
    SilentHitChance = 100,
    SilentPrediction = 0.165,
    SilentMethod = "Raycast",
    SilentStickyAiming = false,
    WallbangMode = "无",
    BulletTPMode = "无",
    HitSound = "关闭",
    ShowDamage = false,
    AimQuickButtonEnabled = false,
    AimQuickButtonSize = 50,
    AimQuickButtonTransparency = 0.3,
    SilentQuickButtonEnabled = false,
    SilentQuickButtonSize = 50,
    SilentQuickButtonTransparency = 0.3,
    HealthVisible = false,
    HealthPosition = "上方",
    HealthAlignment = "中心",
    HealthTextColor = Color3.fromRGB(255, 255, 255),
    RainbowHealthText = false,
    RainbowHealthSpeed = 1
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
    if not Camera then return Vector2.zero, false end
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
    Library:Notify(title, Config.NotificationDuration)
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
local healthVisualEffect = nil

local function CleanupVisuals()
    if visualEffect then
        visualEffect:Destroy()
        visualEffect = nil
    end
    if healthVisualEffect then
        healthVisualEffect:Destroy()
        healthVisualEffect = nil
    end
end

local Window = Library:CreateWindow({
    Title = "卓一航瞄准",
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

local isLocked = false
local currentTarget = nil
local healthConnection = nil
local lastGlobalTarget = nil
local lastGlobalTargetId = nil
local silentLockedTarget = nil

AimGeneralGroup:AddToggle('AimEnabled', {
    Text = '开启锁定功能',
    Default = false,
    Callback = function(Value)
        isLocked = Value
        UpdateQuickButtons()
    end
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
AimGeneralGroup:AddSlider('Sensitivity', {
    Text = '平滑度 (0=锁死)',
    Default = Config.Sensitivity,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(Value) Config.Sensitivity = Value end
})
AimGeneralGroup:AddToggle('StickyAiming', {
    Text = '粘性瞄准',
    Default = Config.StickyAiming,
    Callback = function(Value) Config.StickyAiming = Value end
})

local AimLogicGroup = AimTab:AddLeftGroupbox("目标逻辑")
AimLogicGroup:AddDropdown('PriorityMode', {
    Text = '优先目标',
    Default = Config.PriorityMode,
    Values = {"准心优先", "最低血量", "最近距离"},
    Callback = function(Value) Config.PriorityMode = Value end
})
AimLogicGroup:AddToggle('WallCheckFallback', {
    Text = '掩体回退 (自动打身)',
    Default = Config.WallCheckFallback,
    Callback = function(Value) Config.WallCheckFallback = Value end
})

local PredGroup = AimTab:AddLeftGroupbox("预判系统")
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

local SilentGroup = AimTab:AddRightGroupbox("静默自瞄")
SilentGroup:AddToggle('SilentEnabled', {
    Text = '启用静默自瞄',
    Default = Config.SilentEnabled,
    Callback = function(Value) 
        Config.SilentEnabled = Value 
        UpdateQuickButtons()
    end
})
SilentGroup:AddDropdown('SilentAimPart', {
    Text = '静默命中部位',
    Default = Config.SilentAimPart,
    Values = {"躯干", "头部", "手臂", "腿部", "随机"},
    Callback = function(Value) Config.SilentAimPart = Value end
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
SilentGroup:AddToggle('SilentStickyAiming', {
    Text = '粘性瞄准',
    Default = Config.SilentStickyAiming,
    Callback = function(Value) Config.SilentStickyAiming = Value end
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
SilentGroup:AddDropdown('WallbangMode', {
    Text = '穿墙模式',
    Default = Config.WallbangMode,
    Values = {'无', '物理穿透 (RaycastParams)', '伪造击中 (SpoofHit)'},
    Callback = function(Value) Config.WallbangMode = Value end
})
SilentGroup:AddDropdown('BulletTPMode', {
    Text = '子弹传送',
    Default = Config.BulletTPMode,
    Values = {'无', '坐标传送', '骨骼传送'},
    Callback = function(Value) Config.BulletTPMode = Value end
})


local FeedbackGroup = AimTab:AddRightGroupbox("战斗反馈")
FeedbackGroup:AddSlider('HeadshotChance', {
    Text = '爆头率',
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
    end
})
FOVGroup:AddSlider('FOVThickness', {
    Text = '圆圈粗细',
    Default = Config.FOVThickness,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(Value) Config.FOVThickness = Value end
})
FOVGroup:AddSlider('FOVTransparency', {
    Text = '圆圈透明度',
    Default = Config.FOVTransparency,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value) Config.FOVTransparency = Value end
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
FOVGroup:AddSlider('RainbowFOVSpeed', {
    Text = '彩虹变换速度',
    Default = Config.RainbowFOVSpeed,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value) Config.RainbowFOVSpeed = Value end
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
BoxGroup:AddSlider('RainbowBoxSpeed', {
    Text = '彩虹变换速度',
    Default = Config.RainbowBoxSpeed,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value) Config.RainbowBoxSpeed = Value end
})

local HealthGroup = VisualsTab:AddRightGroupbox("生命值显示")
HealthGroup:AddToggle('HealthVisible', {
    Text = '显示血条',
    Default = Config.HealthVisible,
    Callback = function(Value) Config.HealthVisible = Value end
})
HealthGroup:AddDropdown('HealthPosition', {
    Text = '显示位置',
    Default = Config.HealthPosition,
    Values = {"上方", "中心", "下方"},
    Callback = function(Value) Config.HealthPosition = Value end
})
HealthGroup:AddDropdown('HealthAlignment', {
    Text = '水平对齐',
    Default = Config.HealthAlignment,
    Values = {"左侧", "中心", "右侧"},
    Callback = function(Value) Config.HealthAlignment = Value end
})
HealthGroup:AddLabel('文字颜色'):AddColorPicker('HealthTextColor', {
    Default = Config.HealthTextColor,
    Title = '文字颜色',
    Callback = function(Value) Config.HealthTextColor = Value end
})
HealthGroup:AddToggle('RainbowHealthText', {
    Text = '彩虹渐变模式',
    Default = Config.RainbowHealthText,
    Callback = function(Value) Config.RainbowHealthText = Value end
})
HealthGroup:AddSlider('RainbowHealthSpeed', {
    Text = '彩虹变换速度',
    Default = Config.RainbowHealthSpeed,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value) Config.RainbowHealthSpeed = Value end
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
TracerGroup:AddSlider('RainbowTracerSpeed', {
    Text = '彩虹变换速度',
    Default = Config.RainbowTracerSpeed,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value) Config.RainbowTracerSpeed = Value end
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
    Values = {"队伍标签", "属性检测", "对象检测", "文件夹检测", "榜单检测"},
    Callback = function(Value) Config.TeamCheckMode = Value end
})
FilterGroup:AddToggle('CoverCheck', {
    Text = '可见性检查 (防墙)',
    Default = Config.CoverCheck,
    Callback = function(Value) Config.CoverCheck = Value end
})
FilterGroup:AddSlider('MultiPointScale', {
    Text = '多点检测部位数量',
    Default = Config.MultiPointScale,
    Min = 0,
    Max = 18,
    Rounding = 0,
    Callback = function(Value) Config.MultiPointScale = Value end
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
NotifyGroup:AddSlider('NotificationDuration', {
    Text = '通知持续时间',
    Default = Config.NotificationDuration,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value) Config.NotificationDuration = Value end
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
NotifyGroup:AddInput('TextEliminated', {
    Text = '消灭提示词',
    Default = Config.TextEliminated,
    Callback = function(Value) Config.TextEliminated = Value end
})

local function GetFormattedPlayerName(p)
    if p.DisplayName and p.DisplayName ~= p.Name then
        return p.Name .. " (" .. p.DisplayName .. ")"
    end
    return p.Name
end

local Translator
pcall(function()
    Translator = LocalizationService:GetTranslatorForPlayerAsync(LocalPlayer)
end)

local function GetFormattedTeamName(t)
    local localizedName = t.Name
    if Translator then
        pcall(function()
            localizedName = Translator:Translate(t, t.Name)
        end)
    end
    
    if localizedName ~= t.Name then
        return t.Name .. " (" .. localizedName .. ")"
    else
        return t.Name
    end
end

local function GetAllPlayerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(t, GetFormattedPlayerName(p))
    end
    return t
end

local function GetAllTeamNames()
    local t = {}
    for _, team in ipairs(Teams:GetTeams()) do
        table.insert(t, GetFormattedTeamName(team))
    end
    return t
end

local function GetWhitelistTable()
    local t = {}
    for id, _ in pairs(Config.Whitelist) do
        local p = Players:GetPlayerByUserId(id)
        if p then t[GetFormattedPlayerName(p)] = true end
    end
    return t
end

local function GetBlacklistTable()
    local t = {}
    for id, _ in pairs(Config.Blacklist) do
        local p = Players:GetPlayerByUserId(id)
        if p then t[GetFormattedPlayerName(p)] = true end
    end
    return t
end

local function GetTeamWhitelistTable()
    local t = {}
    for name, _ in pairs(Config.TeamWhitelist) do 
        local team = Teams:FindFirstChild(name)
        if team then t[GetFormattedTeamName(team)] = true end
    end
    return t
end

local function GetTeamBlacklistTable()
    local t = {}
    for name, _ in pairs(Config.TeamBlacklist) do 
        local team = Teams:FindFirstChild(name)
        if team then t[GetFormattedTeamName(team)] = true end
    end
    return t
end

local PlayerListGroup = ListsTab:AddLeftGroupbox("玩家名单管理")
PlayerListGroup:AddToggle('WhitelistEnabled', {
    Text = '启用白名单',
    Default = Config.WhitelistEnabled,
    Callback = function(Value) Config.WhitelistEnabled = Value end
})
PlayerListGroup:AddDropdown('WhitelistManager', {
    Text = '管理白名单 (勾选添加)',
    Values = GetAllPlayerNames(),
    Default = {},
    Multi = true,
    Callback = function(Value)
        Config.Whitelist = {}
        for fmtName, selected in pairs(Value) do
            if selected then
                for _, p in ipairs(Players:GetPlayers()) do
                    if GetFormattedPlayerName(p) == fmtName then
                        Config.Whitelist[p.UserId] = true
                        Config.Blacklist[p.UserId] = nil
                        break
                    end
                end
            end
        end
    end
})

PlayerListGroup:AddToggle('BlacklistEnabled', {
    Text = '启用黑名单',
    Default = Config.BlacklistEnabled,
    Callback = function(Value) Config.BlacklistEnabled = Value end
})
PlayerListGroup:AddDropdown('BlacklistManager', {
    Text = '管理黑名单 (勾选添加)',
    Values = GetAllPlayerNames(),
    Default = {},
    Multi = true,
    Callback = function(Value)
        Config.Blacklist = {}
        for fmtName, selected in pairs(Value) do
            if selected then
                for _, p in ipairs(Players:GetPlayers()) do
                    if GetFormattedPlayerName(p) == fmtName then
                        Config.Blacklist[p.UserId] = true
                        Config.Whitelist[p.UserId] = nil
                        break
                    end
                end
            end
        end
    end
})

local TeamListGroup = ListsTab:AddRightGroupbox("队伍名单管理")
TeamListGroup:AddToggle('TeamWhitelistEnabled', {
    Text = '启用队伍白名单',
    Default = Config.TeamWhitelistEnabled,
    Callback = function(Value) Config.TeamWhitelistEnabled = Value end
})
TeamListGroup:AddDropdown('TeamWhitelistManager', {
    Text = '管理白名单队伍 (勾选添加)',
    Values = GetAllTeamNames(),
    Default = {},
    Multi = true,
    Callback = function(Value)
        Config.TeamWhitelist = {}
        for fmtName, selected in pairs(Value) do
            if selected then
                for _, t in ipairs(Teams:GetTeams()) do
                    if GetFormattedTeamName(t) == fmtName then
                        Config.TeamWhitelist[t.Name] = true
                        Config.TeamBlacklist[t.Name] = nil
                        break
                    end
                end
            end
        end
    end
})

TeamListGroup:AddToggle('TeamBlacklistEnabled', {
    Text = '启用队伍黑名单',
    Default = Config.TeamBlacklistEnabled,
    Callback = function(Value) Config.TeamBlacklistEnabled = Value end
})
TeamListGroup:AddDropdown('TeamBlacklistManager', {
    Text = '管理黑名单队伍 (勾选添加)',
    Values = GetAllTeamNames(),
    Default = {},
    Multi = true,
    Callback = function(Value)
        Config.TeamBlacklist = {}
        for fmtName, selected in pairs(Value) do
            if selected then
                for _, t in ipairs(Teams:GetTeams()) do
                    if GetFormattedTeamName(t) == fmtName then
                        Config.TeamBlacklist[t.Name] = true
                        Config.TeamWhitelist[t.Name] = nil
                        break
                    end
                end
            end
        end
    end
})

Library:SetWatermark("PureLock System - Obsidian")

local lastHealth = 0
local SharedPart = nil
local lastShotTime = 0
local lockedUserId = nil

local function DrawLine(parent, p, a, s, r, color, transp, boxRainbowColor)
    local f = Instance.new("Frame")
    f.Name = "Line"
    f.Parent = parent
    f.BorderSizePixel = 0
    f.Position = p
    f.AnchorPoint = a
    f.Size = s
    f.BackgroundColor3 = color
    f.BackgroundTransparency = transp
    if boxRainbowColor and Config.RainbowBox then
        f.BackgroundColor3 = boxRainbowColor
    end
    if r then f.Rotation = r end
    return f
end

local function DrawPolyFromPoints(parent, points, thickness, color, transp, boxRainbowColor)
    for i = 1, #points do
        local p1 = points[i]
        local p2 = points[(i % #points) + 1]
        local center = (p1 + p2) / 2
        local dist = (p2 - p1).Magnitude
        local angle = math.atan2(p2.Y - p1.Y, p2.X - p1.X)
        DrawLine(parent, UDim2.new(center.X, 0, center.Y, 0), Vector2.new(0.5, 0.5), UDim2.new(dist, 0, 0, thickness), math.deg(angle), color, transp, boxRainbowColor)
    end
end

local function DrawTriangleCorner(parent, c, n1, n2, thickness, color, transp, boxRainbowColor)
    local dir1, dir2 = (n1-c).Unit, (n2-c).Unit
    local len = 0.3
    local l1 = c + dir1 * len
    local l2 = c + dir2 * len
    local dist1, dist2 = (l1-c).Magnitude, (l2-c).Magnitude
    local angle1 = math.atan2(dir1.Y, dir1.X)
    local angle2 = math.atan2(dir2.Y, dir2.X)
    local center1, center2 = (c+l1)/2, (c+l2)/2
    DrawLine(parent, UDim2.new(center1.X, 0, center1.Y, 0), Vector2.new(0.5, 0.5), UDim2.new(dist1, 0, 0, thickness), math.deg(angle1), color, transp, boxRainbowColor)
    DrawLine(parent, UDim2.new(center2.X, 0, center2.Y, 0), Vector2.new(0.5, 0.5), UDim2.new(dist2, 0, 0, thickness), math.deg(angle2), color, transp, boxRainbowColor)
end

local function EnsureBoxVisuals(targetChar, boxRainbowColor)
    if not Config.BoxVisible then CleanupVisuals() return end
    if not targetChar then CleanupVisuals() return end
    local root = targetChar:FindFirstChild("HumanoidRootPart")
    local torso = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso") or root
    if not root or not torso then CleanupVisuals() return end
    
    if not visualEffect or not visualEffect.Parent then
        if visualEffect then visualEffect:Destroy() end
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
        visualEffect.Size = UDim2.new(0, size, 0, size)
    end
    
    local mf = visualEffect:FindFirstChild("MainFrame")
    if mf then
        if not mf:FindFirstChild("Line") then
            if Config.BoxShape == "方框" then
                local l, w = UDim2.new(0.43, 0, 0, Config.BoxThickness), UDim2.new(0, Config.BoxThickness, 0.43, 0)
                DrawLine(mf, UDim2.new(0,0,0,0), Vector2.new(0,0), l, 0, Config.BoxColor, Config.BoxTransparency, boxRainbowColor)
                DrawLine(mf, UDim2.new(0,0,0,0), Vector2.new(0,0), w, 0, Config.BoxColor, Config.BoxTransparency, boxRainbowColor)
                DrawLine(mf, UDim2.new(1,0,0,0), Vector2.new(1,0), l, 0, Config.BoxColor, Config.BoxTransparency, boxRainbowColor)
                DrawLine(mf, UDim2.new(1,0,0,0), Vector2.new(1,0), w, 0, Config.BoxColor, Config.BoxTransparency, boxRainbowColor)
                DrawLine(mf, UDim2.new(0,0,1,0), Vector2.new(0,1), l, 0, Config.BoxColor, Config.BoxTransparency, boxRainbowColor)
                DrawLine(mf, UDim2.new(0,0,1,0), Vector2.new(0,1), w, 0, Config.BoxColor, Config.BoxTransparency, boxRainbowColor)
                DrawLine(mf, UDim2.new(1,0,1,0), Vector2.new(1,1), l, 0, Config.BoxColor, Config.BoxTransparency, boxRainbowColor)
                DrawLine(mf, UDim2.new(1,0,1,0), Vector2.new(1,1), w, 0, Config.BoxColor, Config.BoxTransparency, boxRainbowColor)
            elseif Config.BoxShape == "三角形" then
                local p1, p2, p3 = Vector2.new(0.5, 0), Vector2.new(1, 1), Vector2.new(0, 1)
                DrawTriangleCorner(mf, p1, p2, p3, Config.BoxThickness, Config.BoxColor, Config.BoxTransparency, boxRainbowColor)
                DrawTriangleCorner(mf, p2, p1, p3, Config.BoxThickness, Config.BoxColor, Config.BoxTransparency, boxRainbowColor)
                DrawTriangleCorner(mf, p3, p1, p2, Config.BoxThickness, Config.BoxColor, Config.BoxTransparency, boxRainbowColor)
            elseif Config.BoxShape == "五角星" then
                local pts = {}
                for i = 0, 4 do
                    local angle = math.rad(-90 + i * 72)
                    table.insert(pts, Vector2.new(0.5 + 0.5 * math.cos(angle), 0.5 + 0.5 * math.sin(angle)))
                end
                local starOrder = {pts[1], pts[3], pts[5], pts[2], pts[4]}
                DrawPolyFromPoints(mf, starOrder, Config.BoxThickness, Config.BoxColor, Config.BoxTransparency, boxRainbowColor)
            elseif Config.BoxShape == "六角星" then
                DrawPolyFromPoints(mf, {Vector2.new(0.5, 0), Vector2.new(0.933, 0.75), Vector2.new(0.067, 0.75)}, Config.BoxThickness, Config.BoxColor, Config.BoxTransparency, boxRainbowColor)
                DrawPolyFromPoints(mf, {Vector2.new(0.5, 1), Vector2.new(0.933, 0.25), Vector2.new(0.067, 0.25)}, Config.BoxThickness, Config.BoxColor, Config.BoxTransparency, boxRainbowColor)
            end
        end
        
        mf.Rotation = mf.Rotation + Config.BoxSpeed
        
        for _, v in pairs(mf:GetChildren()) do
            if v:IsA("Frame") then
                if Config.RainbowBox then
                    v.BackgroundColor3 = boxRainbowColor
                else
                    v.BackgroundColor3 = Config.BoxColor
                end
                
                v.BackgroundTransparency = Config.BoxTransparency
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
    
    if Config.MultiPointScale <= 0 then
        return IsPartVisible(head, {LocalPlayer.Character, Camera})
    end

    local partsToCheck = {head}
    table.insert(partsToCheck, root)
    
    local maxChecks = math.min(#possiblePartsToCheck, Config.MultiPointScale)
    
    for i = 1, maxChecks do
        local name = possiblePartsToCheck[i]
        local p = model:FindFirstChild(name)
        if p then table.insert(partsToCheck, p) end
    end

    local ignoreList = {LocalPlayer.Character, Camera}
    for _, part in pairs(partsToCheck) do
        if IsPartVisible(part, ignoreList) then return true end
    end
    return false
end

local function GetSmartTargetPart(char, isSilent)
    if not char then return nil end
    local preferredPartName = isSilent and Config.SilentAimPart or Config.AimPart
    
    local parts = {}
    if preferredPartName == "随机" then
        for _, v in pairs(char:GetChildren()) do 
            if v:IsA("BasePart") then table.insert(parts, v) end 
        end
        if #parts > 0 then
            return parts[math.random(1, #parts)]
        end
        return char:FindFirstChild("HumanoidRootPart")
    end

    local preferredPart = char:FindFirstChild(preferredPartName)
    if not preferredPart then 
        if preferredPartName == "躯干" then preferredPart = char:FindFirstChild("HumanoidRootPart") end
        if preferredPartName == "头部" then preferredPart = char:FindFirstChild("Head") end
    end
    if not preferredPart then preferredPart = char:FindFirstChild("HumanoidRootPart") end

    if IsPartVisible(preferredPart, {LocalPlayer.Character, Camera}) then
        return preferredPart
    end

    if Config.WallCheckFallback then
        local bestPart = nil
        local bestDist = 99999
        local mousePos = UserInputService:GetMouseLocation()

        for _, partName in ipairs(possiblePartsToCheck) do
            local part = char:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                if IsPartVisible(part, {LocalPlayer.Character, Camera}) then
                    if isSilent then
                        return part
                    else
                        local screenPos = Camera:WorldToViewportPoint(part.Position)
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < bestDist then
                            bestDist = dist
                            bestPart = part
                        end
                    end
                end
            end
        end
        if bestPart then return bestPart end
    end

    return preferredPart
end

local function IsTeammate(p, cachedLocalTeam)
    if not Config.TeamCheck then return false end
    if p == LocalPlayer then return true end
    
    local mode = Config.TeamCheckMode or "队伍标签"
    
    if mode == "队伍标签" then
        if cachedLocalTeam and p.Team == cachedLocalTeam then return true end
    elseif mode == "属性检测" then
        if cachedLocalTeam then
            local theirTeam = p:GetAttribute("Team") or p:GetAttribute("Side") or p:GetAttribute("Faction")
            if cachedLocalTeam == theirTeam then return true end
        end
        if LocalPlayer.Character and p.Character then
            local myCharTeam = LocalPlayer.Character:GetAttribute("Team") or LocalPlayer.Character:GetAttribute("Side") or LocalPlayer.Character:GetAttribute("Faction")
            local theirCharTeam = p.Character:GetAttribute("Team") or p.Character:GetAttribute("Side") or p.Character:GetAttribute("Faction")
            if myCharTeam and theirCharTeam and myCharTeam == theirCharTeam then return true end
        end
    elseif mode == "对象检测" then
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
    elseif mode == "文件夹检测" then
        if LocalPlayer.Character and p.Character and LocalPlayer.Character.Parent and p.Character.Parent then
            if LocalPlayer.Character.Parent == p.Character.Parent and LocalPlayer.Character.Parent ~= workspace then
                return true
            end
        end
    elseif mode == "榜单检测" then
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
    local maxDistSq = Config.MaxDistance * Config.MaxDistance
    local fovRadiusSq = Config.FOVRadius * Config.FOVRadius
    
    local myTeamVal = nil
    if Config.TeamCheck then
        local mode = Config.TeamCheckMode or "队伍标签"
        if mode == "队伍标签" then
            myTeamVal = LocalPlayer.Team
        elseif mode == "属性检测" then
            myTeamVal = LocalPlayer:GetAttribute("Team") or LocalPlayer:GetAttribute("Side") or LocalPlayer:GetAttribute("Faction")
        end
    end
    
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
            
            if IsTeammate(p, myTeamVal) then continue end
            
            local char = p.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 then
                local distVector = root.Position - myRoot.Position
                local distSq = distVector.X*distVector.X + distVector.Y*distVector.Y + distVector.Z*distVector.Z
                
                if distSq <= maxDistSq then
                    local Vec3, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if (not Config.UseFOV) or onScreen then
                        if not Config.CoverCheck or CheckCover(char) then
                            local screenDx = Vec3.X - mousePos.X
                            local screenDy = Vec3.Y - mousePos.Y
                            local fovDistSq = screenDx*screenDx + screenDy*screenDy
                            
                            if not Config.UseFOV or fovDistSq <= fovRadiusSq then
                                table.insert(targets, {
                                    Char = char,
                                    DistSq = distSq,
                                    FovSq = fovDistSq,
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
            return a.DistSq < b.DistSq
        else
            return a.FovSq < b.FovSq
        end
    end)
    
    return targets[1].Char
end

local function IsValidTarget(char)
    if not char then return false end
    if not LocalPlayer.Character then return false end
    local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end
    
    local player = Players:GetPlayerFromCharacter(char)
    if player then
        if Config.WhitelistEnabled and Config.Whitelist[player.UserId] then return false end
        if Config.BlacklistEnabled and Config.Blacklist[player.UserId] then return false end
        
        local myTeamVal = nil
        if Config.TeamCheck then
            local mode = Config.TeamCheckMode or "队伍标签"
            if mode == "队伍标签" then
                myTeamVal = LocalPlayer.Team
            elseif mode == "属性检测" then
                myTeamVal = LocalPlayer:GetAttribute("Team") or LocalPlayer:GetAttribute("Side") or LocalPlayer:GetAttribute("Faction")
            end
        end
        if IsTeammate(player, myTeamVal) then return false end
    end
    
    local distVector = root.Position - myRoot.Position
    local distSq = distVector.X*distVector.X + distVector.Y*distVector.Y + distVector.Z*distVector.Z
    local maxDistSq = Config.MaxDistance * Config.MaxDistance
    
    if distSq > maxDistSq then return false end
    
    if Config.CoverCheck and not CheckCover(char) then return false end
    
    if Config.UseFOV then
        local Vec3, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then return false end
        local mousePos = Config.FixedFOV and (Camera.ViewportSize / 2) or UserInputService:GetMouseLocation()
        local screenDx = Vec3.X - mousePos.X
        local screenDy = Vec3.Y - mousePos.Y
        local fovDistSq = screenDx*screenDx + screenDy*screenDy
        local fovRadiusSq = Config.FOVRadius * Config.FOVRadius
        
        if fovDistSq > fovRadiusSq then return false end
    end
    
    return true
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

table.insert(Connections, Players.PlayerAdded:Connect(function(p)
    local allPlayers = GetAllPlayerNames()
    Options.WhitelistManager:SetValues(allPlayers)
    Options.BlacklistManager:SetValues(allPlayers)
    Options.WhitelistManager:SetValue(GetWhitelistTable())
    Options.BlacklistManager:SetValue(GetBlacklistTable())
end))

table.insert(Connections, Players.PlayerRemoving:Connect(function(p)
    local allPlayers = GetAllPlayerNames()
    Options.WhitelistManager:SetValues(allPlayers)
    Options.BlacklistManager:SetValues(allPlayers)
    Options.WhitelistManager:SetValue(GetWhitelistTable())
    Options.BlacklistManager:SetValue(GetBlacklistTable())
end))

table.insert(Connections, Teams.ChildAdded:Connect(function()
    local allTeams = GetAllTeamNames()
    Options.TeamWhitelistManager:SetValues(allTeams)
    Options.TeamBlacklistManager:SetValues(allTeams)
    Options.TeamWhitelistManager:SetValue(GetTeamWhitelistTable())
    Options.TeamBlacklistManager:SetValue(GetTeamBlacklistTable())
end))

table.insert(Connections, RunService.Heartbeat:Connect(function()
    local t = nil
    
    if Config.SilentEnabled and Config.SilentStickyAiming then
        if silentLockedTarget and IsValidTarget(silentLockedTarget) then
            t = silentLockedTarget
        else
            t = GetSortedTarget()
            silentLockedTarget = t
        end
    else
        t = GetSortedTarget()
        silentLockedTarget = nil
    end
    
    if t then
        SharedPart = GetSmartTargetPart(t, true)
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
    
    if Toggles.AimEnabled and Toggles.AimEnabled.Value then
        isLocked = true
    else
        isLocked = false
    end
    
    local fovRainbow = Color3.fromHSV(now * Config.RainbowFOVSpeed % 1, 1, 1)
    local boxRainbow = Color3.fromHSV(now * Config.RainbowBoxSpeed % 1, 1, 1)
    local healthRainbow = Color3.fromHSV(now * Config.RainbowHealthSpeed % 1, 1, 1)
    local tracerRainbow = Color3.fromHSV(now * Config.RainbowTracerSpeed % 1, 1, 1)

    if Config.RainbowFOV then Config.FOVColor = fovRainbow end
    if Config.RainbowBox then Config.BoxColor = boxRainbow end
    if Config.RainbowTracer then Config.TracerColor = tracerRainbow end
    
    FOVStroke.Color = Config.FOVColor
    FOVStroke.Thickness = Config.FOVThickness
    FOVStroke.Transparency = Config.FOVTransparency

    Config.FOVRadius = Config.UserFOVRadius
    
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
        local bestTarget = GetSortedTarget()
        
        if Config.StickyAiming then
            local currentP = lockedUserId and Players:GetPlayerByUserId(lockedUserId)
            local currentC = currentP and currentP.Character
            
            local isCurrentValid = false
            if currentC and currentC:FindFirstChild("Humanoid") and currentC.Humanoid.Health > 0 and currentC:FindFirstChild("HumanoidRootPart") then
                 if (not Config.CoverCheck or CheckCover(currentC)) then
                     if Config.UseFOV then
                        local r = currentC:FindFirstChild("HumanoidRootPart")
                        local s, o = Camera:WorldToViewportPoint(r.Position)
                        local m = Config.FixedFOV and (Camera.ViewportSize/2) or UserInputService:GetMouseLocation()
                        local screenDx = s.X - m.X
                        local screenDy = s.Y - m.Y
                        if (screenDx*screenDx + screenDy*screenDy) <= (Config.FOVRadius * Config.FOVRadius) then
                            isCurrentValid = true
                        end
                     else
                        isCurrentValid = true
                     end
                 end
            end
            
            if not isCurrentValid then
                if bestTarget then
                     local p = Players:GetPlayerFromCharacter(bestTarget)
                     if p then
                        lockedUserId = p.UserId
                        currentTarget = bestTarget
                     end
                else
                     lockedUserId = nil
                     currentTarget = nil
                end
            else
                currentTarget = currentC
            end
        else
            if bestTarget then
                local p = Players:GetPlayerFromCharacter(bestTarget)
                if p then
                    lockedUserId = p.UserId
                    currentTarget = bestTarget
                end
            else
                lockedUserId = nil
                currentTarget = nil
            end
        end
        
        if lockedUserId then
            activeTarget = currentTarget
            
            if currentTarget then
                local finalPart = GetSmartTargetPart(currentTarget, false)
                if finalPart then
                    local aimPos = finalPart.Position
                    
                    if Config.PredictionEnabled and currentTarget:FindFirstChild("HumanoidRootPart") then
                        local t = usedPrediction
                        local vel = currentTarget.HumanoidRootPart.AssemblyLinearVelocity
                        aimPos = aimPos + (vel * t)
                    end
                    
                    local rawSens = math.clamp(Config.Sensitivity, 0, 100)
                    local lerpFactor = (100 - rawSens) / 100
                    
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
            end
        end
    else
        if Config.SilentEnabled and SharedPart and SharedPart.Parent then
            activeTarget = SharedPart.Parent
        end
        lockedUserId = nil
        currentTarget = nil
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.AutoRotate = true
        end
    end
    
    if activeTarget ~= lastGlobalTarget then
        if activeTarget then
            local p = Players:GetPlayerFromCharacter(activeTarget)
            if p then
                ShowNotification(Config.TextLocked .. " : " .. p.Name, "Lock")
            end
            if healthConnection then healthConnection:Disconnect(); healthConnection = nil end
        else
            if lastGlobalTarget then
                if lastGlobalTarget:FindFirstChild("Humanoid") and lastGlobalTarget.Humanoid.Health <= 0 then
                     ShowNotification(Config.TextEliminated, "Success")
                else
                     ShowNotification(Config.TextLost, "Warn")
                end
            end
            if healthConnection then healthConnection:Disconnect(); healthConnection = nil end
        end
        lastGlobalTarget = activeTarget
    end
    
    if activeTarget then
        if Config.BoxVisible then
            EnsureBoxVisuals(activeTarget, boxRainbow)
        else
            if visualEffect then visualEffect:Destroy(); visualEffect = nil end
        end
        
        local tracerDrawn = false
        if Config.TracerVisible then
             local targetPart = activeTarget:FindFirstChild("HumanoidRootPart") or activeTarget:FindFirstChild("Torso") or activeTarget:FindFirstChild("UpperTorso")
             if targetPart then
                 local targetPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
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
        end
        if not tracerDrawn then TracerLineFrame.Visible = false end
    else
        CleanupVisuals()
        TracerLineFrame.Visible = false
    end
    
    if Config.HealthVisible and activeTarget and activeTarget:FindFirstChild("Humanoid") then
        local adornee = nil
        local offset = Vector3.new(0, 0, 0)
        
        if Config.HealthPosition == "上方" then
            adornee = activeTarget:FindFirstChild("Head")
            offset = Vector3.new(0, 1.5, 0)
        elseif Config.HealthPosition == "中心" then
            adornee = activeTarget:FindFirstChild("HumanoidRootPart")
            offset = Vector3.new(0, 0, 0)
        elseif Config.HealthPosition == "下方" then
            adornee = activeTarget:FindFirstChild("HumanoidRootPart")
            offset = Vector3.new(0, -3.5, 0)
        end
        
        if adornee then
            if not healthVisualEffect or not healthVisualEffect.Parent then
                if healthVisualEffect then healthVisualEffect:Destroy() end
                healthVisualEffect = Instance.new("BillboardGui", CoreGui)
                healthVisualEffect.Name = "PureLockHealth"
                healthVisualEffect.AlwaysOnTop = true
                healthVisualEffect.Size = UDim2.new(0, 100, 0, 50)
                
                local label = Instance.new("TextLabel", healthVisualEffect)
                label.Name = "HealthLabel"
                label.AnchorPoint = Vector2.new(0.5, 0.5)
                label.Position = UDim2.fromScale(0.5, 0.5)
                label.BackgroundTransparency = 0.5
                label.BackgroundColor3 = Color3.new(0, 0, 0)
                label.TextSize = 13
                label.Font = Enum.Font.SourceSans
                label.BorderSizePixel = 0
                label.AutomaticSize = Enum.AutomaticSize.XY
                label.Size = UDim2.new(0, 0, 0, 0)
                label.TextStrokeTransparency = 1
            end
            
            healthVisualEffect.Adornee = adornee
            healthVisualEffect.StudsOffset = offset
            
            local label = healthVisualEffect:FindFirstChild("HealthLabel")
            if label then
                label.Text = tostring(math.floor(activeTarget.Humanoid.Health))
                if Config.RainbowHealthText then
                    label.TextColor3 = healthRainbow
                else
                    label.TextColor3 = Config.HealthTextColor
                end
            end
        else
            if healthVisualEffect then healthVisualEffect:Destroy(); healthVisualEffect = nil end
        end
    else
        if healthVisualEffect then healthVisualEffect:Destroy(); healthVisualEffect = nil end
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
                    Arguments[2] = oldRayNew(Arguments[2].Origin, getDirection(Arguments[2].Origin, SharedPart.Position))
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
                return oldRayNew(shotOrigin, direction)
            end
        end
    end
    return oldNamecall(...)
end))

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
