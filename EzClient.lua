local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local Workspace        = game:GetService("Workspace")
local Camera           = Workspace.CurrentCamera

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()

local C = {
    Bg          = Color3.fromRGB(15, 15, 18),
    BgDark      = Color3.fromRGB(10, 10, 13),
    BgPanel     = Color3.fromRGB(20, 20, 25),
    BgHover     = Color3.fromRGB(28, 28, 35),
    Border      = Color3.fromRGB(38, 38, 50),
    BorderLight = Color3.fromRGB(55, 55, 72),
    Accent      = Color3.fromRGB(120, 40, 210),
    AccentBright= Color3.fromRGB(148, 60, 235),
    AccentDim   = Color3.fromRGB(80,  22, 150),
    AccentFaint = Color3.fromRGB(40,  15, 75),
    Text        = Color3.fromRGB(210, 210, 220),
    TextMid     = Color3.fromRGB(150, 150, 165),
    TextDim     = Color3.fromRGB(90,  90, 108),
    White       = Color3.fromRGB(255, 255, 255),
    Green       = Color3.fromRGB(55,  185,  70),
    Orange      = Color3.fromRGB(220, 160,  40),
    Red         = Color3.fromRGB(205,  55,  55),
}

local FB = Enum.Font.GothamBold
local FR = Enum.Font.Gotham
local FM = Enum.Font.GothamMedium

local S = {
    ESP_Enabled      = false,
    ESP_Names        = true,
    ESP_Boxes        = true,
    ESP_Tracers      = false,
    ESP_Health       = true,
    ESP_Distance     = true,
    ESP_Outline      = false,
    ESP_Skeleton     = false,
    ESP_MaxDist      = 500,
    ESP_NameSize     = 13,
    ESP_BoxThick     = 1,
    ESP_TracerThick  = 1,
    ESP_TracerOrigin = "Bottom",
    ESP_TeamFilter   = false,
    ESP_NormalColor  = Color3.fromRGB(210, 210, 220),
    ESP_TargetColor  = Color3.fromRGB(148, 60, 235),
    ESP_BoxColor     = Color3.fromRGB(210, 210, 220),
    ESP_HealthyColor = Color3.fromRGB(55,  185, 70),
    ESP_LowHPColor   = Color3.fromRGB(205, 55,  55),

    CAM_Enabled      = false,
    CAM_Key          = Enum.KeyCode.Q,
    CAM_Smoothing    = 0.10,
    CAM_Sensitivity  = 1.0,
    CAM_FOVRadius    = 80,
    CAM_ShowFOV      = true,
    CAM_FOVColor     = Color3.fromRGB(148, 60, 235),
    CAM_FOVThick     = 1,
    CAM_FOVAlpha     = 0.25,
    CAM_TargetPart   = "Head",
    CAM_Priority     = "Closest",
    CAM_MaxDist      = 500,

    HIT_Enabled      = true,
    HIT_Color        = Color3.fromRGB(148, 60, 235),
    HIT_FillAlpha    = 0.6,
    HIT_OutlineAlpha = 0.0,
    HIT_Duration     = 0.45,

    HB_Enabled       = false,
    HB_X             = 4.0,
    HB_Y             = 4.0,
    HB_Z             = 4.0,

    HUD_Enabled      = true,

    MENU_KEY         = Enum.KeyCode.RightShift,
}

local function SafeKeyName(k)
    if type(k) == "userdata" then
        local ok, n = pcall(function() return k.Name end)
        if ok and type(n) == "string" and #n > 0 then return n end
    end
    return "None"
end

local function TW(obj, props, t, st, dir)
    return TweenService:Create(obj,
        TweenInfo.new(t or 0.18, st or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props)
end

local function Round(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = inst
    return c
end

local function W2V(pos)
    local v, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), v.Z, onScreen
end

local function GetBounds(char)
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local any = false
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            local sz, cf = p.Size, p.CFrame
            local hx, hy, hz = sz.X/2, sz.Y/2, sz.Z/2
            for sx = -1,1,2 do for sy = -1,1,2 do for sz2 = -1,1,2 do
                local sc, depth, on = W2V((cf * CFrame.new(sx*hx, sy*hy, sz2*hz)).Position)
                if on and depth > 0 then
                    any = true
                    if sc.X < minX then minX = sc.X end
                    if sc.Y < minY then minY = sc.Y end
                    if sc.X > maxX then maxX = sc.X end
                    if sc.Y > maxY then maxY = sc.Y end
                end
            end end end
        end
    end
    if not any then return nil end
    return minX, minY, maxX, maxY
end

local SG = Instance.new("ScreenGui")
SG.Name           = "EzClientGui"
SG.ResetOnSpawn   = false
SG.IgnoreGuiInset = true
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if not pcall(function() SG.Parent = CoreGui end) then
    SG.Parent = LP:WaitForChild("PlayerGui")
end

local ESPLayer = Instance.new("Frame")
ESPLayer.Name                  = "ESPLayer"
ESPLayer.Size                  = UDim2.new(1, 0, 1, 0)
ESPLayer.BackgroundTransparency = 1
ESPLayer.BorderSizePixel       = 0
ESPLayer.ZIndex                = 1
ESPLayer.Parent                = SG

local WIN_W, WIN_H = 700, 460

local Win = Instance.new("Frame")
Win.Name             = "Win"
Win.Size             = UDim2.new(0, WIN_W, 0, WIN_H)
Win.Position         = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
Win.BackgroundColor3 = C.Bg
Win.BorderSizePixel  = 0
Win.ClipsDescendants = false
Win.Visible          = false
Win.ZIndex           = 10
Win.Parent           = SG
Round(Win, 8)

local WinBorder = Instance.new("UIStroke")
WinBorder.Color       = C.Border
WinBorder.Thickness   = 1
WinBorder.Parent      = Win

local WinClip = Instance.new("Frame")
WinClip.Size             = UDim2.new(1, 0, 1, 0)
WinClip.BackgroundTransparency = 1
WinClip.ClipsDescendants = true
WinClip.BorderSizePixel  = 0
WinClip.ZIndex           = 10
WinClip.Parent           = Win
Round(WinClip, 8)

local TITLEBAR_H = 36

local TBar = Instance.new("Frame")
TBar.Name             = "TBar"
TBar.Size             = UDim2.new(1, 0, 0, TITLEBAR_H)
TBar.BackgroundColor3 = C.BgDark
TBar.BorderSizePixel  = 0
TBar.ZIndex           = 11
TBar.Parent           = WinClip

local TBarLine = Instance.new("Frame")
TBarLine.Size             = UDim2.new(1, 0, 0, 1)
TBarLine.Position         = UDim2.new(0, 0, 1, -1)
TBarLine.BackgroundColor3 = C.Border
TBarLine.BorderSizePixel  = 0
TBarLine.ZIndex           = 12
TBarLine.Parent           = TBar

local AccentBar = Instance.new("Frame")
AccentBar.Size             = UDim2.new(0, 36, 0, 2)
AccentBar.Position         = UDim2.new(0, 12, 1, -2)
AccentBar.BackgroundColor3 = C.Accent
AccentBar.BorderSizePixel  = 0
AccentBar.ZIndex           = 13
AccentBar.Parent           = TBar
Round(AccentBar, 1)

local TTitle = Instance.new("TextLabel")
TTitle.Size                  = UDim2.new(1, -90, 1, 0)
TTitle.Position              = UDim2.new(0, 12, 0, 0)
TTitle.BackgroundTransparency = 1
TTitle.Font                  = FB
TTitle.TextSize              = 13
TTitle.TextColor3            = C.Text
TTitle.TextXAlignment        = Enum.TextXAlignment.Left
TTitle.Text                  = "EzClient"
TTitle.ZIndex                = 12
TTitle.Parent                = TBar

local TVersion = Instance.new("TextLabel")
TVersion.Size                  = UDim2.new(0, 60, 1, 0)
TVersion.Position              = UDim2.new(0, 74, 0, 0)
TVersion.BackgroundTransparency = 1
TVersion.Font                  = FR
TVersion.TextSize              = 11
TVersion.TextColor3            = C.TextDim
TVersion.TextXAlignment        = Enum.TextXAlignment.Left
TVersion.Text                  = "v2.0"
TVersion.ZIndex                = 12
TVersion.Parent                = TBar

local function MakeTBarBtn(icon, xOff, color)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0, 22, 0, 22)
    b.Position         = UDim2.new(1, xOff, 0.5, -11)
    b.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    b.BorderSizePixel  = 0
    b.Font             = FB
    b.TextSize         = 13
    b.TextColor3       = color or C.TextMid
    b.Text             = icon
    b.ZIndex           = 12
    b.Parent           = TBar
    Round(b, 5)
    b.MouseEnter:Connect(function() TW(b, {BackgroundColor3 = Color3.fromRGB(50,50,60)}, 0.1):Play() end)
    b.MouseLeave:Connect(function() TW(b, {BackgroundColor3 = Color3.fromRGB(35,35,42)}, 0.1):Play() end)
    return b
end

local BtnClose = MakeTBarBtn("×", -28, C.Text)
local BtnMin   = MakeTBarBtn("−", -54, C.TextMid)

do
    local drag, ds, dp = false, nil, nil
    TBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; ds = i.Position; dp = Win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            Win.Position = UDim2.new(dp.X.Scale, dp.X.Offset + d.X, dp.Y.Scale, dp.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
end

local SIDEBAR_W = 130

local Sidebar = Instance.new("Frame")
Sidebar.Name             = "Sidebar"
Sidebar.Size             = UDim2.new(0, SIDEBAR_W, 1, -TITLEBAR_H)
Sidebar.Position         = UDim2.new(0, 0, 0, TITLEBAR_H)
Sidebar.BackgroundColor3 = C.BgDark
Sidebar.BorderSizePixel  = 0
Sidebar.ZIndex           = 11
Sidebar.Parent           = WinClip

local SidebarBorderR = Instance.new("Frame")
SidebarBorderR.Size             = UDim2.new(0, 1, 1, 0)
SidebarBorderR.Position         = UDim2.new(1, -1, 0, 0)
SidebarBorderR.BackgroundColor3 = C.Border
SidebarBorderR.BorderSizePixel  = 0
SidebarBorderR.ZIndex           = 12
SidebarBorderR.Parent           = Sidebar

local SidebarInner = Instance.new("Frame")
SidebarInner.Size                  = UDim2.new(1, 0, 1, 0)
SidebarInner.BackgroundTransparency = 1
SidebarInner.Parent                = Sidebar
local SBLayout = Instance.new("UIListLayout")
SBLayout.SortOrder    = Enum.SortOrder.LayoutOrder
SBLayout.Padding      = UDim.new(0, 1)
SBLayout.Parent       = SidebarInner
local SBPad = Instance.new("UIPadding")
SBPad.PaddingTop  = UDim.new(0, 8)
SBPad.PaddingLeft = UDim.new(0, 6)
SBPad.PaddingRight = UDim.new(0, 6)
SBPad.Parent       = SidebarInner

local Content = Instance.new("Frame")
Content.Name                  = "Content"
Content.Size                  = UDim2.new(1, -SIDEBAR_W, 1, -TITLEBAR_H)
Content.Position              = UDim2.new(0, SIDEBAR_W, 0, TITLEBAR_H)
Content.BackgroundTransparency = 1
Content.BorderSizePixel       = 0
Content.ClipsDescendants      = true
Content.ZIndex                = 11
Content.Parent                = WinClip

local Tabs       = {}
local TabBtns    = {}
local ActiveTab  = nil

local TAB_LIST = {
    { id = "ESP",      label = "ESP",       icon = "◈" },
    { id = "Camlock",  label = "Camlock",   icon = "◎" },
    { id = "HitFX",    label = "Hit FX",    icon = "◆" },
    { id = "Hitbox",   label = "Hitbox",    icon = "⬚" },
    { id = "Settings", label = "Settings",  icon = "≡" },
    { id = "Keybinds", label = "Keybinds",  icon = "⌘" },
}

local function MakeSidebarBtn(tabDef, order)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = C.BgDark
    btn.BorderSizePixel  = 0
    btn.Font             = FM
    btn.TextSize         = 12
    btn.TextColor3       = C.TextDim
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.Text             = "  " .. tabDef.icon .. "   " .. tabDef.label
    btn.LayoutOrder      = order
    btn.ZIndex           = 12
    btn.Parent           = SidebarInner
    Round(btn, 5)

    local pill = Instance.new("Frame")
    pill.Size             = UDim2.new(0, 2, 0.55, 0)
    pill.Position         = UDim2.new(0, 0, 0.225, 0)
    pill.BackgroundColor3 = C.Accent
    pill.BorderSizePixel  = 0
    pill.BackgroundTransparency = 1
    pill.ZIndex           = 13
    pill.Parent           = btn
    Round(pill, 1)

    return btn, pill
end

local function MakeTabPanel(id)
    local sf = Instance.new("ScrollingFrame")
    sf.Name                   = id .. "_panel"
    sf.Size                   = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel        = 0
    sf.ScrollBarThickness     = 3
    sf.ScrollBarImageColor3   = C.Border
    sf.CanvasSize             = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    sf.Visible                = false
    sf.ZIndex                 = 12
    sf.Parent                 = Content

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, 4)
    layout.Parent    = sf

    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft   = UDim.new(0, 10)
    pad.PaddingRight  = UDim.new(0, 10)
    pad.Parent        = sf

    Tabs[id] = sf
    return sf
end

local function SwitchTab(id)
    if ActiveTab == id then return end
    ActiveTab = id
    for tid, panel in pairs(Tabs) do
        panel.Visible = (tid == id)
    end
    for tid, d in pairs(TabBtns) do
        local btn, pill = d[1], d[2]
        if tid == id then
            TW(btn,  {BackgroundColor3 = C.AccentFaint, TextColor3 = C.AccentBright}, 0.12):Play()
            TW(pill, {BackgroundTransparency = 0}, 0.12):Play()
        else
            TW(btn,  {BackgroundColor3 = C.BgDark, TextColor3 = C.TextDim}, 0.12):Play()
            TW(pill, {BackgroundTransparency = 1}, 0.12):Play()
        end
    end
end

for i, def in ipairs(TAB_LIST) do
    MakeTabPanel(def.id)
    local btn, pill = MakeSidebarBtn(def, i)
    TabBtns[def.id] = {btn, pill}
    local tid = def.id
    btn.MouseButton1Click:Connect(function() SwitchTab(tid) end)
    btn.MouseEnter:Connect(function()
        if ActiveTab ~= tid then TW(btn, {BackgroundColor3 = C.BgHover}, 0.08):Play() end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveTab ~= tid then TW(btn, {BackgroundColor3 = C.BgDark}, 0.08):Play() end
    end)
end

SwitchTab("ESP")

local function Header(parent, text, order)
    local f = Instance.new("Frame")
    f.Size                  = UDim2.new(1, 0, 0, 22)
    f.BackgroundTransparency = 1
    f.LayoutOrder           = order or 0
    f.Parent                = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1, -4, 1, 0)
    lbl.Position              = UDim2.new(0, 2, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = FM
    lbl.TextSize              = 10
    lbl.TextColor3            = C.Accent
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.Text                  = string.upper(text)
    lbl.Parent                = f

    local line = Instance.new("Frame")
    line.Size             = UDim2.new(1, 0, 0, 1)
    line.Position         = UDim2.new(0, 0, 1, -1)
    line.BackgroundColor3 = C.Border
    line.BorderSizePixel  = 0
    line.Parent           = f
    return f
end

local function Toggle(parent, label, key, order, cb)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = C.BgPanel
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order or 0
    row.Parent           = parent
    Round(row, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1, -52, 1, 0)
    lbl.Position              = UDim2.new(0, 9, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = FR
    lbl.TextSize              = 12
    lbl.TextColor3            = S[key] and C.Text or C.TextMid
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.Text                  = label
    lbl.Parent                = row

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(0, 32, 0, 17)
    track.Position         = UDim2.new(1, -40, 0.5, -8)
    track.BackgroundColor3 = S[key] and C.Accent or C.Border
    track.BorderSizePixel  = 0
    track.Parent           = row
    Round(track, 9)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 11, 0, 11)
    knob.Position         = S[key] and UDim2.new(0, 18, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
    knob.BackgroundColor3 = C.White
    knob.BorderSizePixel  = 0
    knob.Parent           = track
    Round(knob, 6)

    local function Refresh()
        local on = S[key]
        TW(track, {BackgroundColor3 = on and C.Accent or C.Border}, 0.15):Play()
        TW(knob,  {Position = on and UDim2.new(0,18,0.5,-5) or UDim2.new(0,3,0.5,-5)}, 0.15):Play()
        lbl.TextColor3 = on and C.Text or C.TextMid
    end
    Refresh()

    local hit = Instance.new("TextButton")
    hit.Size                  = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text                  = ""
    hit.Parent                = row

    hit.MouseButton1Click:Connect(function()
        S[key] = not S[key]; Refresh()
        if cb then cb(S[key]) end
    end)
    hit.MouseEnter:Connect(function() TW(row, {BackgroundColor3 = C.BgHover}, 0.08):Play() end)
    hit.MouseLeave:Connect(function() TW(row, {BackgroundColor3 = C.BgPanel}, 0.08):Play() end)

    return row, Refresh
end

local function Slider(parent, label, key, mn, mx, step, order, fmt, cb)
    fmt  = fmt  or "%g"
    step = step or 1

    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = C.BgPanel
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order or 0
    row.Parent           = parent
    Round(row, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(0.65, 0, 0, 18)
    lbl.Position              = UDim2.new(0, 9, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = FR
    lbl.TextSize              = 12
    lbl.TextColor3            = C.Text
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.Text                  = label
    lbl.Parent                = row

    local val = Instance.new("TextLabel")
    val.Size                  = UDim2.new(0.35, -9, 0, 18)
    val.Position              = UDim2.new(0.65, 0, 0, 4)
    val.BackgroundTransparency = 1
    val.Font                  = FM
    val.TextSize              = 11
    val.TextColor3            = C.Accent
    val.TextXAlignment        = Enum.TextXAlignment.Right
    val.Text                  = string.format(fmt, S[key])
    val.Parent                = row

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1, -18, 0, 4)
    track.Position         = UDim2.new(0, 9, 0, 30)
    track.BackgroundColor3 = C.Border
    track.BorderSizePixel  = 0
    track.Parent           = row
    Round(track, 2)

    local pct0 = math.clamp((S[key] - mn) / (mx - mn), 0, 1)
    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new(pct0, 0, 1, 0)
    fill.BackgroundColor3 = C.Accent
    fill.BorderSizePixel  = 0
    fill.Parent           = track
    Round(fill, 2)

    local thumb = Instance.new("Frame")
    thumb.Size             = UDim2.new(0, 10, 0, 10)
    thumb.AnchorPoint      = Vector2.new(0.5, 0.5)
    thumb.Position         = UDim2.new(pct0, 0, 0.5, 0)
    thumb.BackgroundColor3 = C.White
    thumb.BorderSizePixel  = 0
    thumb.Parent           = track
    Round(thumb, 5)

    local function SetV(raw)
        local v = math.clamp(math.floor((raw - mn)/step + 0.5)*step + mn, mn, mx)
        S[key] = v
        local p = math.clamp((v - mn)/(mx - mn), 0, 1)
        fill.Size      = UDim2.new(p, 0, 1, 0)
        thumb.Position = UDim2.new(p, 0, 0.5, 0)
        val.Text       = string.format(fmt, v)
        if cb then cb(v) end
    end

    local sliding = false
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            local rel = (i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
            SetV(mn + rel*(mx-mn))
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = (i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
            SetV(mn + rel*(mx-mn))
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    return row
end

local function Dropdown(parent, label, key, opts, order, cb)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = C.BgPanel
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order or 0
    row.ClipsDescendants = false
    row.ZIndex           = 5
    row.Parent           = parent
    Round(row, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(0.5, 0, 1, 0)
    lbl.Position              = UDim2.new(0, 9, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = FR
    lbl.TextSize              = 12
    lbl.TextColor3            = C.Text
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.Text                  = label
    lbl.ZIndex                = 6
    lbl.Parent                = row

    local dbtn = Instance.new("TextButton")
    dbtn.Size             = UDim2.new(0, 115, 0, 20)
    dbtn.Position         = UDim2.new(1, -122, 0.5, -10)
    dbtn.BackgroundColor3 = C.BgDark
    dbtn.Font             = FM
    dbtn.TextSize         = 11
    dbtn.TextColor3       = C.AccentBright
    dbtn.Text             = tostring(S[key]) .. " ▾"
    dbtn.BorderSizePixel  = 0
    dbtn.ZIndex           = 6
    dbtn.Parent           = row
    Round(dbtn, 4)

    local list = Instance.new("Frame")
    list.Size             = UDim2.new(0, 115, 0, #opts * 24 + 6)
    list.Position         = UDim2.new(1, -122, 1, 2)
    list.BackgroundColor3 = C.BgDark
    list.BorderSizePixel  = 1
    list.BorderColor3     = C.Border
    list.Visible          = false
    list.ZIndex           = 30
    list.Parent           = row
    Round(list, 5)

    local ll = Instance.new("UIListLayout")
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding   = UDim.new(0, 0)
    ll.Parent    = list
    local lp = Instance.new("UIPadding")
    lp.PaddingTop = UDim.new(0, 3); lp.Parent = list

    for i, opt in ipairs(opts) do
        local item = Instance.new("TextButton")
        item.Size             = UDim2.new(1, 0, 0, 24)
        item.BackgroundColor3 = C.BgDark
        item.BorderSizePixel  = 0
        item.Font             = FR
        item.TextSize         = 11
        item.TextColor3       = tostring(S[key]) == opt and C.AccentBright or C.TextMid
        item.Text             = opt
        item.ZIndex           = 31
        item.LayoutOrder      = i
        item.Parent           = list
        item.MouseEnter:Connect(function()
            TW(item, {BackgroundColor3 = C.BgHover}, 0.06):Play()
        end)
        item.MouseLeave:Connect(function()
            TW(item, {BackgroundColor3 = C.BgDark}, 0.06):Play()
        end)
        item.MouseButton1Click:Connect(function()
            S[key] = opt
            dbtn.Text = opt .. " ▾"
            list.Visible = false
            for _, ch in ipairs(list:GetChildren()) do
                if ch:IsA("TextButton") then
                    ch.TextColor3 = ch.Text == opt and C.AccentBright or C.TextMid
                end
            end
            if cb then cb(opt) end
        end)
    end

    local open = false
    dbtn.MouseButton1Click:Connect(function() open = not open; list.Visible = open end)
    UserInputService.InputBegan:Connect(function(i)
        if open and i.UserInputType == Enum.UserInputType.MouseButton1 then
            local p  = i.Position
            local rp = row.AbsolutePosition
            local rs = row.AbsoluteSize
            local lh = list.AbsoluteSize.Y
            if not (p.X >= rp.X and p.X <= rp.X + rs.X + 10
                and p.Y >= rp.Y and p.Y <= rp.Y + rs.Y + lh + 8) then
                open = false; list.Visible = false
            end
        end
    end)
    return row
end

local ActivePicker = nil

local function ColorPicker(parent, label, key, order, cb)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = C.BgPanel
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order or 0
    row.Parent           = parent
    Round(row, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1, -52, 1, 0)
    lbl.Position              = UDim2.new(0, 9, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = FR
    lbl.TextSize              = 12
    lbl.TextColor3            = C.Text
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.Text                  = label
    lbl.Parent                = row

    local swatch = Instance.new("TextButton")
    swatch.Size             = UDim2.new(0, 36, 0, 18)
    swatch.Position         = UDim2.new(1, -43, 0.5, -9)
    swatch.BackgroundColor3 = S[key]
    swatch.BorderSizePixel  = 0
    swatch.Text             = ""
    swatch.Parent           = row
    Round(swatch, 4)
    local swatchStroke = Instance.new("UIStroke")
    swatchStroke.Color     = C.BorderLight
    swatchStroke.Thickness = 1
    swatchStroke.Parent    = swatch

    local popup = Instance.new("Frame")
    popup.Name             = "ColorPicker"
    popup.Size             = UDim2.new(0, 200, 0, 160)
    popup.BackgroundColor3 = C.BgDark
    popup.BorderSizePixel  = 1
    popup.BorderColor3     = C.Border
    popup.Visible          = false
    popup.ZIndex           = 60
    popup.Parent           = SG
    Round(popup, 7)

    local ptitle = Instance.new("TextLabel")
    ptitle.Size                  = UDim2.new(1, 0, 0, 22)
    ptitle.BackgroundTransparency = 1
    ptitle.Font                  = FM
    ptitle.TextSize              = 11
    ptitle.TextColor3            = C.TextMid
    ptitle.Text                  = label
    ptitle.ZIndex                = 61
    ptitle.Parent                = popup

    local h0, s0, v0 = S[key]:ToHSV()

    local function MakePSlider(yp, lchar, init)
        local t = Instance.new("Frame")
        t.Size             = UDim2.new(1, -28, 0, 12)
        t.Position         = UDim2.new(0, 22, 0, yp)
        t.BackgroundColor3 = C.Border
        t.BorderSizePixel  = 0
        t.ZIndex           = 62
        t.Parent           = popup
        Round(t, 3)

        local tl = Instance.new("TextLabel")
        tl.Size                  = UDim2.new(0, 16, 1, 0)
        tl.Position              = UDim2.new(0, -18, 0, 0)
        tl.BackgroundTransparency = 1
        tl.Font                  = FM
        tl.TextSize              = 9
        tl.TextColor3            = C.TextDim
        tl.Text                  = lchar
        tl.ZIndex                = 62
        tl.Parent                = t

        local f = Instance.new("Frame")
        f.Size             = UDim2.new(math.clamp(init,0,1), 0, 1, 0)
        f.BackgroundColor3 = C.Accent
        f.BorderSizePixel  = 0
        f.Parent           = t
        Round(f, 3)

        local k = Instance.new("Frame")
        k.Size             = UDim2.new(0, 8, 0, 8)
        k.AnchorPoint      = Vector2.new(0.5, 0.5)
        k.Position         = UDim2.new(math.clamp(init,0,1), 0, 0.5, 0)
        k.BackgroundColor3 = C.White
        k.BorderSizePixel  = 0
        k.ZIndex           = 63
        k.Parent           = t
        Round(k, 4)

        return t, f, k
    end

    local hT, hF, hK = MakePSlider(26, "H", h0)
    local sT, sF, sK = MakePSlider(48, "S", s0)
    local vT, vF, vK = MakePSlider(70, "V", v0)

    local preview = Instance.new("Frame")
    preview.Size             = UDim2.new(1, -18, 0, 20)
    preview.Position         = UDim2.new(0, 9, 0, 92)
    preview.BackgroundColor3 = Color3.fromHSV(h0, s0, v0)
    preview.BorderSizePixel  = 0
    preview.ZIndex           = 62
    preview.Parent           = popup
    Round(preview, 4)

    local applyBtn = Instance.new("TextButton")
    applyBtn.Size             = UDim2.new(1, -18, 0, 22)
    applyBtn.Position         = UDim2.new(0, 9, 0, 118)
    applyBtn.BackgroundColor3 = C.Accent
    applyBtn.Font             = FM
    applyBtn.TextSize         = 11
    applyBtn.TextColor3       = C.White
    applyBtn.Text             = "Apply"
    applyBtn.BorderSizePixel  = 0
    applyBtn.ZIndex           = 62
    applyBtn.Parent           = popup
    Round(applyBtn, 4)

    local function RefreshPreview()
        preview.BackgroundColor3 = Color3.fromHSV(h0, s0, v0)
    end

    local function BindPS(trackF, fillF, knobF, setter)
        local act = false
        trackF.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                act = true
                local r = math.clamp((i.Position.X - trackF.AbsolutePosition.X) / trackF.AbsoluteSize.X, 0, 1)
                setter(r); fillF.Size = UDim2.new(r,0,1,0); knobF.Position = UDim2.new(r,0,0.5,0)
                RefreshPreview()
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if act and i.UserInputType == Enum.UserInputType.MouseMovement then
                local r = math.clamp((i.Position.X - trackF.AbsolutePosition.X) / trackF.AbsoluteSize.X, 0, 1)
                setter(r); fillF.Size = UDim2.new(r,0,1,0); knobF.Position = UDim2.new(r,0,0.5,0)
                RefreshPreview()
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then act = false end
        end)
    end

    BindPS(hT, hF, hK, function(r) h0 = r end)
    BindPS(sT, sF, sK, function(r) s0 = r end)
    BindPS(vT, vF, vK, function(r) v0 = r end)

    applyBtn.MouseButton1Click:Connect(function()
        local col = Color3.fromHSV(h0, s0, v0)
        S[key] = col
        swatch.BackgroundColor3 = col
        popup.Visible = false
        ActivePicker = nil
        if cb then cb(col) end
    end)

    local pickerOpen = false
    swatch.MouseButton1Click:Connect(function()
        if ActivePicker and ActivePicker ~= popup then
            ActivePicker.Visible = false
        end
        pickerOpen = not pickerOpen
        popup.Visible = pickerOpen
        ActivePicker = pickerOpen and popup or nil
        if pickerOpen then
            local ap = swatch.AbsolutePosition
            local ax = math.min(ap.X + 44, Camera.ViewportSize.X - 210)
            local ay = math.max(4, ap.Y - 20)
            popup.Position = UDim2.new(0, ax, 0, ay)
            h0, s0, v0 = S[key]:ToHSV()
            hK.Position = UDim2.new(math.clamp(h0,0,1),0,0.5,0); hF.Size = UDim2.new(math.clamp(h0,0,1),0,1,0)
            sK.Position = UDim2.new(math.clamp(s0,0,1),0,0.5,0); sF.Size = UDim2.new(math.clamp(s0,0,1),0,1,0)
            vK.Position = UDim2.new(math.clamp(v0,0,1),0,0.5,0); vF.Size = UDim2.new(math.clamp(v0,0,1),0,1,0)
            RefreshPreview()
        end
    end)

    return row
end

local function KeybindRow(parent, label, key, order)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = C.BgPanel
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order or 0
    row.Parent           = parent
    Round(row, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1, -100, 1, 0)
    lbl.Position              = UDim2.new(0, 9, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = FR
    lbl.TextSize              = 12
    lbl.TextColor3            = C.Text
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.Text                  = label
    lbl.Parent                = row

    local kbtn = Instance.new("TextButton")
    kbtn.Size             = UDim2.new(0, 80, 0, 20)
    kbtn.Position         = UDim2.new(1, -87, 0.5, -10)
    kbtn.BackgroundColor3 = C.BgDark
    kbtn.Font             = FM
    kbtn.TextSize         = 11
    kbtn.TextColor3       = C.AccentBright
    kbtn.Text             = SafeKeyName(S[key])
    kbtn.BorderSizePixel  = 0
    kbtn.Parent           = row
    Round(kbtn, 4)

    local listening = false
    kbtn.MouseButton1Click:Connect(function()
        listening = true; kbtn.Text = "…"; kbtn.TextColor3 = C.TextDim
    end)
    kbtn.MouseEnter:Connect(function()
        TW(row, {BackgroundColor3 = C.BgHover}, 0.08):Play()
    end)
    kbtn.MouseLeave:Connect(function()
        TW(row, {BackgroundColor3 = C.BgPanel}, 0.08):Play()
    end)
    UserInputService.InputBegan:Connect(function(i)
        if not listening then return end
        if i.UserInputType == Enum.UserInputType.Keyboard then
            S[key] = i.KeyCode
            kbtn.Text      = SafeKeyName(i.KeyCode)
            kbtn.TextColor3 = C.AccentBright
            listening       = false
        end
    end)
    return row
end

local function ActionButton(parent, text, color, order, cb)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.LayoutOrder      = order or 0
    row.Parent           = parent

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = color or C.AccentDim
    btn.Font             = FM
    btn.TextSize         = 12
    btn.TextColor3       = C.White
    btn.Text             = text
    btn.BorderSizePixel  = 0
    btn.Parent           = row
    Round(btn, 5)
    btn.MouseEnter:Connect(function() TW(btn, {BackgroundColor3 = C.Accent}, 0.1):Play() end)
    btn.MouseLeave:Connect(function() TW(btn, {BackgroundColor3 = color or C.AccentDim}, 0.1):Play() end)
    btn.MouseButton1Click:Connect(function() if cb then cb() end end)
    return row
end

local espPanel     = Tabs["ESP"]
local camPanel     = Tabs["Camlock"]
local hitPanel     = Tabs["HitFX"]
local hitboxPanel  = Tabs["Hitbox"]
local settingsPanel = Tabs["Settings"]
local keybindPanel = Tabs["Keybinds"]

Header(espPanel, "Visibility", 1)
Toggle(espPanel, "Enable ESP",        "ESP_Enabled",   2)
Toggle(espPanel, "Names",             "ESP_Names",     3)
Toggle(espPanel, "2D Boxes",          "ESP_Boxes",     4)
Toggle(espPanel, "Tracers",           "ESP_Tracers",   5)
Toggle(espPanel, "Health Bars",       "ESP_Health",    6)
Toggle(espPanel, "Distance Labels",   "ESP_Distance",  7)
Toggle(espPanel, "Character Outline", "ESP_Outline",   8)
Toggle(espPanel, "Skeleton",          "ESP_Skeleton",  9)
Toggle(espPanel, "Team Filter",       "ESP_TeamFilter",10)
Header(espPanel, "Configuration", 11)
Slider(espPanel,  "Max Distance",     "ESP_MaxDist",   50, 1000, 10, 12, "%g")
Slider(espPanel,  "Name Size",        "ESP_NameSize",  8,  20,   1,  13, "%g")
Slider(espPanel,  "Box Thickness",    "ESP_BoxThick",  0.5, 4,  0.5, 14, "%.1f")
Slider(espPanel,  "Tracer Thickness", "ESP_TracerThick",0.5, 4, 0.5, 15, "%.1f")
Dropdown(espPanel,"Tracer Origin",    "ESP_TracerOrigin",{"Bottom","Center","Cursor"}, 16)
Header(espPanel, "Colors", 17)
ColorPicker(espPanel, "Name Color",   "ESP_NormalColor", 18)
ColorPicker(espPanel, "Target Color", "ESP_TargetColor", 19)
ColorPicker(espPanel, "Box Color",    "ESP_BoxColor",    20)

Header(camPanel, "Camera Lock", 1)
Toggle(camPanel,  "Enable Camlock",   "CAM_Enabled",    2)
Dropdown(camPanel,"Priority",         "CAM_Priority",   {"Closest","LowHealth","FOV"}, 3)
Dropdown(camPanel,"Target Part",      "CAM_TargetPart", {"Head","HumanoidRootPart","Torso"}, 4)
Slider(camPanel,  "Smoothing",        "CAM_Smoothing",  0.01, 1.0, 0.01, 5, "%.2f")
Slider(camPanel,  "Sensitivity",      "CAM_Sensitivity",0.1,  3.0, 0.05, 6, "%.2f")
Slider(camPanel,  "Max Distance",     "CAM_MaxDist",    50, 1000, 10, 7, "%g", function(v) S.CAM_MaxDist = v end)
Header(camPanel, "FOV Circle", 8)
Toggle(camPanel,  "Show FOV Circle",  "CAM_ShowFOV",    9)
Slider(camPanel,  "FOV Radius",       "CAM_FOVRadius",  10, 400, 5, 10, "%g")
Slider(camPanel,  "Thickness",        "CAM_FOVThick",   0.5, 5, 0.5, 11, "%.1f")
Slider(camPanel,  "Transparency",     "CAM_FOVAlpha",   0.0, 0.9, 0.05, 12, "%.2f")
ColorPicker(camPanel, "Circle Color", "CAM_FOVColor",  13)

do
    local targetRow = Instance.new("Frame")
    targetRow.Size             = UDim2.new(1, 0, 0, 28)
    targetRow.BackgroundColor3 = C.AccentFaint
    targetRow.BorderSizePixel  = 0
    targetRow.LayoutOrder      = 14
    targetRow.Parent           = camPanel
    Round(targetRow, 5)
    local targetLbl = Instance.new("TextLabel")
    targetLbl.Name                 = "TargetLabel"
    targetLbl.Size                 = UDim2.new(1, -12, 1, 0)
    targetLbl.Position             = UDim2.new(0, 8, 0, 0)
    targetLbl.BackgroundTransparency = 1
    targetLbl.Font                 = FM
    targetLbl.TextSize             = 11
    targetLbl.TextColor3           = C.TextMid
    targetLbl.TextXAlignment       = Enum.TextXAlignment.Left
    targetLbl.Text                 = "No target"
    targetLbl.Parent               = targetRow
end

Header(hitPanel, "Hit Feedback", 1)
Toggle(hitPanel,  "Enable Hit Outline","HIT_Enabled",   2)
Slider(hitPanel,  "Duration",          "HIT_Duration",  0.1, 2.0, 0.05, 3, "%.2fs")
Slider(hitPanel,  "Fill Transparency", "HIT_FillAlpha", 0.0, 1.0, 0.05, 4, "%.2f")
Slider(hitPanel,  "Outline Alpha",     "HIT_OutlineAlpha",0.0,1.0,0.05, 5, "%.2f")
ColorPicker(hitPanel, "Hit Color",     "HIT_Color",     6)

Header(hitboxPanel, "Hitbox Expander", 1)
do
    local noteF = Instance.new("Frame")
    noteF.Size             = UDim2.new(1, 0, 0, 36)
    noteF.BackgroundColor3 = C.BgPanel
    noteF.BorderSizePixel  = 0
    noteF.LayoutOrder      = 2
    noteF.Parent           = hitboxPanel
    Round(noteF, 5)
    local nl = Instance.new("TextLabel")
    nl.Size                  = UDim2.new(1, -12, 1, 0)
    nl.Position              = UDim2.new(0, 6, 0, 0)
    nl.BackgroundTransparency = 1
    nl.Font                  = FR
    nl.TextSize              = 10
    nl.TextColor3            = C.TextDim
    nl.TextWrapped           = true
    nl.TextXAlignment        = Enum.TextXAlignment.Left
    nl.Text                  = "Authorized Studio testing only. Visualizes hitbox size; does not modify server-side hit registration."
    nl.Parent                = noteF
end
Toggle(hitboxPanel, "Enable Hitbox Preview", "HB_Enabled", 3)
Slider(hitboxPanel, "Width  (X)",  "HB_X", 1, 20, 0.25, 4, "%.2f")
Slider(hitboxPanel, "Height (Y)",  "HB_Y", 1, 20, 0.25, 5, "%.2f")
Slider(hitboxPanel, "Depth  (Z)",  "HB_Z", 1, 20, 0.25, 6, "%.2f")
ActionButton(hitboxPanel, "Reset Hitbox Defaults", C.AccentDim, 7, function()
    S.HB_X = 4.0; S.HB_Y = 4.0; S.HB_Z = 4.0
end)

Header(settingsPanel, "Display", 1)
Toggle(settingsPanel, "Show HUD",  "HUD_Enabled", 2)
Header(settingsPanel, "Defaults", 3)
ActionButton(settingsPanel, "Reset All to Default", C.AccentDim, 4, function()
    S.ESP_Enabled=false; S.ESP_Names=true; S.ESP_Boxes=true; S.ESP_Tracers=false
    S.ESP_Health=true; S.ESP_Distance=true; S.ESP_Outline=false; S.ESP_Skeleton=false
    S.ESP_MaxDist=500; S.ESP_NameSize=13; S.ESP_BoxThick=1; S.ESP_TracerThick=1
    S.ESP_TracerOrigin="Bottom"; S.ESP_TeamFilter=false
    S.ESP_NormalColor=Color3.fromRGB(210,210,220); S.ESP_TargetColor=Color3.fromRGB(148,60,235)
    S.ESP_BoxColor=Color3.fromRGB(210,210,220)
    S.CAM_Enabled=false; S.CAM_Smoothing=0.10; S.CAM_Sensitivity=1.0
    S.CAM_FOVRadius=80; S.CAM_ShowFOV=true; S.CAM_FOVThick=1; S.CAM_FOVAlpha=0.25
    S.CAM_MaxDist=500
    S.HIT_Enabled=true; S.HIT_Duration=0.45; S.HIT_FillAlpha=0.6; S.HIT_OutlineAlpha=0.0
    S.HB_Enabled=false; S.HB_X=4; S.HB_Y=4; S.HB_Z=4
    S.HUD_Enabled=true
end)

Header(keybindPanel, "Keybinds", 1)
KeybindRow(keybindPanel, "Toggle Menu",  "MENU_KEY", 2)
KeybindRow(keybindPanel, "Camlock Key",  "CAM_Key",  3)

local HUD = Instance.new("Frame")
HUD.Name                  = "HUD"
HUD.Size                  = UDim2.new(0, 96, 0, 8)
HUD.Position              = UDim2.new(0, 8, 0.5, -50)
HUD.BackgroundColor3      = Color3.fromRGB(10, 10, 14)
HUD.BackgroundTransparency = 0.25
HUD.BorderSizePixel       = 0
HUD.AutomaticSize         = Enum.AutomaticSize.Y
HUD.ZIndex                = 5
HUD.Parent                = SG
Round(HUD, 5)
do
    local stroke = Instance.new("UIStroke")
    stroke.Color     = C.Border
    stroke.Thickness = 1
    stroke.Parent    = HUD
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, 1)
    layout.Parent    = HUD
    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)
    pad.PaddingLeft   = UDim.new(0, 6)
    pad.PaddingRight  = UDim.new(0, 6)
    pad.Parent        = HUD
end

local HTitle = Instance.new("TextLabel")
HTitle.Size                  = UDim2.new(1, 0, 0, 14)
HTitle.BackgroundTransparency = 1
HTitle.Font                  = FM
HTitle.TextSize              = 10
HTitle.TextColor3            = C.Accent
HTitle.TextXAlignment        = Enum.TextXAlignment.Left
HTitle.Text                  = "EzClient"
HTitle.LayoutOrder           = 0
HTitle.Parent                = HUD

local HUD_FEATS = {
    {key="ESP_Enabled", lbl="ESP"},
    {key="CAM_Enabled", lbl="Lock"},
    {key="HIT_Enabled", lbl="Hit"},
    {key="HB_Enabled",  lbl="HBox"},
}
local HUDItems = {}
for i, f in ipairs(HUD_FEATS) do
    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1, 0, 0, 12)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = FR
    lbl.TextSize              = 10
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.LayoutOrder           = i
    lbl.Parent                = HUD
    HUDItems[f.key] = lbl
end

local function UpdateHUD()
    HUD.Visible = S.HUD_Enabled
    for _, f in ipairs(HUD_FEATS) do
        local item = HUDItems[f.key]
        if item then
            local on = S[f.key]
            item.Text      = (on and "▪ " or "· ") .. f.lbl
            item.TextColor3 = on and C.AccentBright or C.TextDim
        end
    end
end
UpdateHUD()

local FOVFrame = Instance.new("Frame")
FOVFrame.Name                  = "FOVCircle"
FOVFrame.BackgroundTransparency = 1
FOVFrame.BorderSizePixel       = 0
FOVFrame.AnchorPoint           = Vector2.new(0.5, 0.5)
FOVFrame.ZIndex                = 3
FOVFrame.Parent                = SG

local FOVInner = Instance.new("Frame")
FOVInner.Name                  = "Inner"
FOVInner.AnchorPoint           = Vector2.new(0.5, 0.5)
FOVInner.BackgroundTransparency = 1
FOVInner.ZIndex                = 3
FOVInner.Parent                = FOVFrame
Round(FOVInner, 0)
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = FOVInner
end

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color       = C.Accent
FOVStroke.Thickness   = 1
FOVStroke.Transparency = 0.25
FOVStroke.Parent      = FOVInner

local function UpdateFOV()
    local vp  = Camera.ViewportSize
    local dia = S.CAM_FOVRadius * 2
    FOVFrame.Size     = UDim2.new(0, dia, 0, dia)
    FOVFrame.Position = UDim2.new(0, vp.X/2, 0, vp.Y/2)
    FOVFrame.Visible  = S.CAM_Enabled and S.CAM_ShowFOV
    FOVInner.Size     = UDim2.new(1, 0, 1, 0)
    FOVInner.Position = UDim2.new(0.5, 0, 0.5, 0)
    FOVStroke.Color       = S.CAM_FOVColor
    FOVStroke.Thickness   = S.CAM_FOVThick
    FOVStroke.Transparency = S.CAM_FOVAlpha
end
UpdateFOV()

local ESPData = {}

local function DestroyESP(player)
    local d = ESPData[player]
    if not d then return end
    ESPData[player] = nil
    for _, conn in ipairs(d.conns) do
        pcall(function() conn:Disconnect() end)
    end
    for _, obj in ipairs(d.objects) do
        pcall(function() if obj and obj.Parent then obj:Destroy() end end)
    end
end

local function MakeLine()
    local f = Instance.new("Frame")
    f.BackgroundColor3 = C.Text
    f.BorderSizePixel  = 0
    f.Visible          = false
    f.Parent           = ESPLayer
    return f
end

local function CreateESP(player)
    if player == LP then return end
    DestroyESP(player)

    local d = {objects = {}, conns = {}}
    ESPData[player] = d

    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop    = true
    bb.Size           = UDim2.new(0, 130, 0, 18)
    bb.StudsOffset    = Vector3.new(0, 3.2, 0)
    bb.Parent         = Workspace

    local nl = Instance.new("TextLabel")
    nl.Size                  = UDim2.new(1, 0, 1, 0)
    nl.BackgroundTransparency = 1
    nl.Font                  = FM
    nl.TextStrokeTransparency = 0.4
    nl.TextStrokeColor3      = Color3.fromRGB(0, 0, 0)
    nl.TextScaled            = false
    nl.Parent                = bb

    d.bb  = bb
    d.nl  = nl
    table.insert(d.objects, bb)

    local hBB = Instance.new("BillboardGui")
    hBB.AlwaysOnTop = true
    hBB.Size        = UDim2.new(0, 4, 0, 36)
    hBB.StudsOffset = Vector3.new(-2.4, 0, 0)
    hBB.Parent      = Workspace

    local hBG = Instance.new("Frame")
    hBG.Size             = UDim2.new(1, 0, 1, 0)
    hBG.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    hBG.BorderSizePixel  = 0
    hBG.Parent           = hBB
    Round(hBG, 2)

    local hFill = Instance.new("Frame")
    hFill.AnchorPoint      = Vector2.new(0, 1)
    hFill.Position         = UDim2.new(0, 0, 1, 0)
    hFill.BackgroundColor3 = C.Green
    hFill.BorderSizePixel  = 0
    hFill.Parent           = hBG
    Round(hFill, 2)

    d.hBB   = hBB
    d.hFill = hFill
    table.insert(d.objects, hBB)

    local selBox = Instance.new("SelectionBox")
    selBox.Color3              = C.Text
    selBox.LineThickness       = 0.03
    selBox.SurfaceTransparency = 1
    selBox.SurfaceColor3       = C.Text
    selBox.Parent              = Workspace
    d.highlight = selBox
    table.insert(d.objects, selBox)

    d.boxTop   = MakeLine(); d.boxBot  = MakeLine()
    d.boxLeft  = MakeLine(); d.boxRight = MakeLine()
    d.tracer   = MakeLine()

    local dLbl = Instance.new("TextLabel")
    dLbl.BackgroundTransparency = 1
    dLbl.Font                  = FR
    dLbl.TextStrokeTransparency = 0.4
    dLbl.TextStrokeColor3      = Color3.fromRGB(0, 0, 0)
    dLbl.TextXAlignment        = Enum.TextXAlignment.Center
    dLbl.TextColor3            = C.Text
    dLbl.Visible               = false
    dLbl.Parent                = ESPLayer
    d.dLbl = dLbl

    for _, obj in ipairs({d.boxTop,d.boxBot,d.boxLeft,d.boxRight,d.tracer,dLbl}) do
        table.insert(d.objects, obj)
    end
end

local function SetupESP(player)
    CreateESP(player)
    local function OnChar(char)
        local d = ESPData[player]
        if not d then return end
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hrp or not hum then return end
        if d.bb   then d.bb.Adornee  = hrp  end
        if d.hBB  then d.hBB.Adornee = hrp  end
        if d.highlight then d.highlight.Adornee = char end

        local hConn = hum.HealthChanged:Connect(function(hp)
            local d2 = ESPData[player]
            if not d2 or not d2.hFill then return end
            local pct = math.clamp(hp / math.max(hum.MaxHealth, 1), 0, 1)
            local col = pct > 0.5 and S.ESP_HealthyColor
                     or pct > 0.25 and S.ESP_HealthyColor:Lerp(S.ESP_LowHPColor, (0.5-pct)*4)
                     or S.ESP_LowHPColor
            d2.hFill.BackgroundColor3 = col
            d2.hFill.Size             = UDim2.new(1, 0, pct, 0)
        end)
        table.insert(d.conns, hConn)
    end
    if player.Character then task.spawn(OnChar, player.Character) end
    local cc = player.CharacterAdded:Connect(function(char) task.spawn(OnChar, char) end)
    if ESPData[player] then table.insert(ESPData[player].conns, cc) end
end

local function DrawLine(f, x1, y1, x2, y2, thick)
    local dx, dy = x2-x1, y2-y1
    local len    = math.sqrt(dx*dx + dy*dy)
    if len < 1 then f.Visible = false; return end
    f.Size     = UDim2.new(0, len, 0, math.max(1, thick))
    f.Position = UDim2.new(0, x1, 0, y1 - thick/2)
    f.Rotation = math.deg(math.atan2(dy, dx))
    f.Visible  = true
end

local function HideF(f) if f and f.Parent then f.Visible = false end end
local function ShowF(f) if f and f.Parent then f.Visible = true  end end

local CamTarget = nil

RunService.RenderStepped:Connect(function()
    UpdateHUD()
    UpdateFOV()

    if not S.ESP_Enabled then
        for _, d in pairs(ESPData) do
            if d.bb  then pcall(function() d.bb.Enabled  = false end) end
            if d.hBB then pcall(function() d.hBB.Enabled = false end) end
            if d.highlight then pcall(function() d.highlight.Adornee = nil end) end
            HideF(d.boxTop); HideF(d.boxBot)
            HideF(d.boxLeft); HideF(d.boxRight)
            HideF(d.tracer); HideF(d.dLbl)
            if d.bones then
                for _, b in ipairs(d.bones) do HideF(b) end
            end
        end
        return
    end

    local myChar = LP.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local vp     = Camera.ViewportSize

    for player, d in pairs(ESPData) do
        local char     = player.Character
        local hrp      = char and char:FindFirstChild("HumanoidRootPart")
        local hum      = char and char:FindFirstChildOfClass("Humanoid")

        local alive = char ~= nil and hrp ~= nil and hum ~= nil and hum.Health > 0
        if alive and S.ESP_TeamFilter then
            if player.Team == LP.Team then alive = false end
        end
        if alive and myHRP then
            if (hrp.Position - myHRP.Position).Magnitude > S.ESP_MaxDist then alive = false end
        end

        local isTarget  = (CamTarget == player)
        local nameColor = isTarget and S.ESP_TargetColor or S.ESP_NormalColor

        if d.bb  then pcall(function() d.bb.Enabled  = alive and S.ESP_Names  end) end
        if d.hBB then pcall(function() d.hBB.Enabled = alive and S.ESP_Health end) end

        if d.highlight then
            pcall(function()
                if alive and S.ESP_Outline then
                    d.highlight.Adornee            = char
                    d.highlight.Color3             = nameColor
                    d.highlight.SurfaceColor3      = nameColor
                    d.highlight.LineThickness      = 0.03
                    d.highlight.SurfaceTransparency = 0.85
                else
                    d.highlight.Adornee = nil
                end
            end)
        end

        if alive then
            if d.nl then
                pcall(function()
                    d.nl.Text       = player.Name
                    d.nl.TextSize   = S.ESP_NameSize
                    d.nl.TextColor3 = nameColor
                end)
            end

            if d.hFill and hum then
                pcall(function()
                    local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                    d.hFill.Size = UDim2.new(1, 0, pct, 0)
                end)
            end

            local minX, minY, maxX, maxY = GetBounds(char)

            if minX then
                local bk = S.ESP_BoxThick

                if S.ESP_Boxes then
                    if d.boxTop   and d.boxTop.Parent   then DrawLine(d.boxTop,  minX, minY, maxX, minY, bk) end
                    if d.boxBot   and d.boxBot.Parent   then DrawLine(d.boxBot,  minX, maxY, maxX, maxY, bk) end
                    if d.boxLeft  and d.boxLeft.Parent  then
                        d.boxLeft.Size     = UDim2.new(0, bk, 0, math.max(1, maxY-minY))
                        d.boxLeft.Position = UDim2.new(0, minX-bk/2, 0, minY)
                        d.boxLeft.Visible  = true
                    end
                    if d.boxRight and d.boxRight.Parent then
                        d.boxRight.Size     = UDim2.new(0, bk, 0, math.max(1, maxY-minY))
                        d.boxRight.Position = UDim2.new(0, maxX-bk/2, 0, minY)
                        d.boxRight.Visible  = true
                    end
                    local boxCol = S.ESP_BoxColor
                    for _, bf in ipairs({d.boxTop, d.boxBot, d.boxLeft, d.boxRight}) do
                        if bf and bf.Parent then bf.BackgroundColor3 = boxCol end
                    end
                else
                    HideF(d.boxTop); HideF(d.boxBot)
                    HideF(d.boxLeft); HideF(d.boxRight)
                end

                if S.ESP_Tracers and hrp then
                    local origin
                    if S.ESP_TracerOrigin == "Bottom" then
                        origin = Vector2.new(vp.X/2, vp.Y)
                    elseif S.ESP_TracerOrigin == "Center" then
                        origin = Vector2.new(vp.X/2, vp.Y/2)
                    else
                        origin = Vector2.new(Mouse.X, Mouse.Y)
                    end
                    local tsc, tdepth, ton = W2V(hrp.Position)
                    if ton and tdepth > 0 and d.tracer and d.tracer.Parent then
                        DrawLine(d.tracer, origin.X, origin.Y, tsc.X, tsc.Y, S.ESP_TracerThick)
                        d.tracer.BackgroundColor3 = nameColor
                    else
                        HideF(d.tracer)
                    end
                else
                    HideF(d.tracer)
                end

                if S.ESP_Distance and myHRP and d.dLbl and d.dLbl.Parent then
                    local dist = math.floor((hrp.Position - myHRP.Position).Magnitude)
                    d.dLbl.Text       = dist .. "m"
                    d.dLbl.TextSize   = math.max(8, S.ESP_NameSize - 2)
                    d.dLbl.TextColor3 = nameColor
                    d.dLbl.Size       = UDim2.new(0, 60, 0, 13)
                    d.dLbl.Position   = UDim2.new(0, (minX+maxX)/2-30, 0, maxY+2)
                    d.dLbl.Visible    = true
                else
                    HideF(d.dLbl)
                end
            else
                HideF(d.boxTop); HideF(d.boxBot)
                HideF(d.boxLeft); HideF(d.boxRight)
                HideF(d.tracer); HideF(d.dLbl)
            end

            if S.ESP_Skeleton then
                local BONES = {
                    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
                    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},
                    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},
                    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},
                    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},
                }
                if not d.bones then d.bones = {} end
                for i, pr in ipairs(BONES) do
                    local p1 = char:FindFirstChild(pr[1])
                    local p2 = char:FindFirstChild(pr[2])
                    if p1 and p2 then
                        if not d.bones[i] then
                            d.bones[i] = MakeLine()
                            table.insert(d.objects, d.bones[i])
                        end
                        local s1, _, o1 = W2V(p1.Position)
                        local s2, _, o2 = W2V(p2.Position)
                        if o1 and o2 and d.bones[i] and d.bones[i].Parent then
                            DrawLine(d.bones[i], s1.X, s1.Y, s2.X, s2.Y, 1)
                            d.bones[i].BackgroundColor3 = nameColor
                        else
                            HideF(d.bones[i])
                        end
                    end
                end
            else
                if d.bones then
                    for _, b in ipairs(d.bones) do
                        pcall(function() if b and b.Parent then b:Destroy() end end)
                    end
                    d.bones = nil
                end
            end
        else
            HideF(d.boxTop); HideF(d.boxBot)
            HideF(d.boxLeft); HideF(d.boxRight)
            HideF(d.tracer); HideF(d.dLbl)
            if d.bones then for _, b in ipairs(d.bones) do HideF(b) end end
        end
    end
end)

Players.PlayerAdded:Connect(SetupESP)
Players.PlayerRemoving:Connect(DestroyESP)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then SetupESP(p) end
end

local HitHighlights = {}

local function FlashHit(char)
    if not S.HIT_Enabled then return end
    if not char or not char.Parent then return end

    if HitHighlights[char] then
        HitHighlights[char]:Destroy()
        HitHighlights[char] = nil
    end

    local hl = Instance.new("SelectionBox")
    hl.Adornee            = char
    hl.Color3             = S.HIT_Color
    hl.SurfaceColor3      = S.HIT_Color
    hl.LineThickness      = 0.06
    hl.SurfaceTransparency = math.max(0, math.min(1, S.HIT_FillAlpha))
    hl.Parent             = Workspace
    HitHighlights[char]   = hl

    local dur       = S.HIT_Duration
    local steps     = 20
    local dt        = dur / steps
    local startThick = 0.06
    local startSurf  = math.max(0, math.min(1, S.HIT_FillAlpha))

    task.spawn(function()
        for i = 1, steps do
            task.wait(dt)
            if not hl or not hl.Parent then return end
            if HitHighlights[char] ~= hl then return end
            local t = i / steps
            hl.LineThickness      = startThick * (1 - t)
            hl.SurfaceTransparency = math.min(1, startSurf + (1 - startSurf) * t)
        end
        if HitHighlights[char] == hl then
            hl:Destroy()
            HitHighlights[char] = nil
        end
    end)
end

local function HookHit(player)
    local function OnChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        local prev = hum.Health

        local hConn = hum.HealthChanged:Connect(function(hp)
            if hp < prev then FlashHit(char) end
            prev = hp
        end)
        local dConn = hum.Died:Connect(function()
            if HitHighlights[char] then HitHighlights[char]:Destroy(); HitHighlights[char]=nil end
            hConn:Disconnect()
        end)
        char.AncestryChanged:Connect(function()
            if not char.Parent then
                if HitHighlights[char] then HitHighlights[char]:Destroy(); HitHighlights[char]=nil end
                hConn:Disconnect(); dConn:Disconnect()
            end
        end)
    end
    if player.Character then task.spawn(OnChar, player.Character) end
    player.CharacterAdded:Connect(function(c) task.spawn(OnChar, c) end)
end

Players.PlayerAdded:Connect(HookHit)
for _, p in ipairs(Players:GetPlayers()) do HookHit(p) end

local HitboxParts = {}

local function RebuildHitbox(char)
    if HitboxParts[char] then
        HitboxParts[char]:Destroy()
        HitboxParts[char] = nil
    end
    if not S.HB_Enabled then return end
    if not char or not char.Parent then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local vis = Instance.new("SelectionBox")
    vis.Adornee           = hrp
    vis.Color3            = C.AccentBright
    vis.SurfaceColor3     = C.AccentBright
    vis.SurfaceTransparency = 0.75
    vis.LineThickness     = 0.04
    vis.Parent            = Workspace

    local sz = Instance.new("SpecialMesh")
    sz.MeshType = Enum.MeshType.Box
    sz.Scale    = Vector3.new(S.HB_X, S.HB_Y, S.HB_Z)

    HitboxParts[char] = vis
end

RunService.Heartbeat:Connect(function()
    if not S.HB_Enabled then
        for char, vis in pairs(HitboxParts) do
            if vis and vis.Parent then vis:Destroy() end
            HitboxParts[char] = nil
        end
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local char = player.Character
            if char and not HitboxParts[char] then
                RebuildHitbox(char)
            end
            if char and HitboxParts[char] then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then
                    HitboxParts[char]:Destroy()
                    HitboxParts[char] = nil
                end
            end
        end
    end
    for char, vis in pairs(HitboxParts) do
        if not char.Parent then
            if vis and vis.Parent then vis:Destroy() end
            HitboxParts[char] = nil
        end
    end
end)

local CamActive = false
local CamConn   = nil
local CamTargetLabel = camPanel:FindFirstChild("TargetLabel", true)

local function FindCamTarget()
    local myChar = LP.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local vp = Camera.ViewportSize
    local cx, cy = vp.X/2, vp.Y/2

    local best, bestScore = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local char = player.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local skipTeam = S.ESP_TeamFilter and player.Team == LP.Team
                if not skipTeam then
                    local d3 = (hrp.Position - myHRP.Position).Magnitude
                    if d3 <= S.CAM_MaxDist then
                        local sc, depth, on = W2V(hrp.Position)
                        if on and depth > 0 then
                            local sd = math.sqrt((sc.X-cx)^2 + (sc.Y-cy)^2)
                            if sd <= S.CAM_FOVRadius then
                                local score = S.CAM_Priority=="LowHealth" and hum.Health
                                           or S.CAM_Priority=="FOV"       and sd
                                           or d3
                                if score < bestScore then bestScore=score; best=player end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function StartCam()
    if CamConn then CamConn:Disconnect() end
    CamConn = RunService.RenderStepped:Connect(function()
        if not S.CAM_Enabled or not CamActive then
            if CamTarget then
                CamTarget = nil
                if CamTargetLabel then CamTargetLabel.Text = "No target"; CamTargetLabel.TextColor3 = C.TextMid end
            end
            return
        end
        local tgt = FindCamTarget()
        CamTarget = tgt
        if not tgt then
            if CamTargetLabel then CamTargetLabel.Text = "No target"; CamTargetLabel.TextColor3 = C.TextMid end
            return
        end
        if CamTargetLabel then CamTargetLabel.Text = "→ " .. tgt.Name; CamTargetLabel.TextColor3 = S.ESP_TargetColor end
        local char = tgt.Character
        if not char then return end
        local part = char:FindFirstChild(S.CAM_TargetPart) or char:FindFirstChild("HumanoidRootPart")
        if not part then return end
        local smooth = math.clamp(S.CAM_Smoothing * S.CAM_Sensitivity, 0.01, 1)
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, part.Position), smooth)
    end)
end
StartCam()

UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if type(S.CAM_Key)=="userdata" and i.KeyCode==S.CAM_Key then
        if S.CAM_Enabled then
            CamActive = not CamActive
            if not CamActive then
                CamTarget = nil
                if CamTargetLabel then CamTargetLabel.Text="No target"; CamTargetLabel.TextColor3=C.TextMid end
            end
        end
    end
end)

LP.CharacterRemoving:Connect(function()
    CamActive = false; CamTarget = nil
end)

local menuOpen = false

local function SetMenu(v)
    menuOpen = v
    if v then
        Win.Visible   = true
        Win.Size      = UDim2.new(0, 0, 0, 0)
        Win.Position  = UDim2.new(0.5, 0, 0.5, 0)
        TW(Win, {
            Size     = UDim2.new(0, WIN_W, 0, WIN_H),
            Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
        }, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
    else
        local t = TW(Win, {
            Size     = UDim2.new(0, WIN_W, 0, 0),
            Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
        }, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t:Play()
        t.Completed:Once(function() if not menuOpen then Win.Visible = false end end)
    end
end

BtnClose.MouseButton1Click:Connect(function() SetMenu(false) end)
BtnMin.MouseButton1Click:Connect(function() SetMenu(false) end)

UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if type(S.MENU_KEY)=="userdata" and i.KeyCode==S.MENU_KEY then
        SetMenu(not menuOpen)
    end
end)

SetMenu(true)
