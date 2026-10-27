local env = (getgenv and getgenv()) or _G
if env.EzClientUnload then
	pcall(env.EzClientUnload)
end

local cref = cloneref or function(i) return i end
local function svc(name) return cref(game:GetService(name)) end

local Players          = svc("Players")
local RunService       = svc("RunService")
local TweenService     = svc("TweenService")
local UserInputService = svc("UserInputService")
local Workspace        = svc("Workspace")
local CoreGui          = svc("CoreGui")

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()

local Palette = {
	Deep        = Color3.fromRGB(10,  6,  20),
	Violet      = Color3.fromRGB(100, 35, 195),
	Bright      = Color3.fromRGB(148, 60, 235),
	Lavender    = Color3.fromRGB(200, 165, 255),
	Mist        = Color3.fromRGB(232, 220, 255),
	Surface     = Color3.fromRGB(18,  16,  26),
	Panel       = Color3.fromRGB(24,  21,  34),
	PanelHover  = Color3.fromRGB(32,  28,  46),
	Border      = Color3.fromRGB(48,  40,  72),
	BorderBright= Color3.fromRGB(72,  58, 108),
	Text        = Color3.fromRGB(218, 210, 235),
	TextMid     = Color3.fromRGB(148, 138, 172),
	TextDim     = Color3.fromRGB(88,  80, 112),
	White       = Color3.fromRGB(255, 255, 255),
	Green       = Color3.fromRGB(60,  195, 80),
	Orange      = Color3.fromRGB(225, 165, 40),
	Red         = Color3.fromRGB(210, 55,  55),
}

local Config = {
	MenuKey   = Enum.KeyCode.RightShift,
	UnloadKey = Enum.KeyCode.End,

	Esp = {
		Enabled      = false,
		Names        = true,
		Boxes        = true,
		Tracers      = false,
		Health       = true,
		Distance     = true,
		Outline      = false,
		Skeleton     = false,
		MaxDist      = 500,
		NameSize     = 13,
		BoxThick     = 1,
		TracerThick  = 1,
		TracerOrigin = "Bottom",
		TeamFilter   = false,
		NormalColor  = Color3.fromRGB(218, 210, 235),
		TargetColor  = Color3.fromRGB(148, 60, 235),
		BoxColor     = Color3.fromRGB(218, 210, 235),
	},

	Cam = {
		Enabled    = false,
		Key        = Enum.KeyCode.Q,
		Smoothing  = 0.10,
		Sensitivity= 1.0,
		FOVRadius  = 80,
		ShowFOV    = true,
		FOVColor   = Color3.fromRGB(148, 60, 235),
		FOVThick   = 1,
		FOVAlpha   = 0.25,
		TargetPart = "Head",
		Priority   = "Closest",
		MaxDist    = 500,
	},

	Hit = {
		Enabled     = true,
		Color       = Color3.fromRGB(148, 60, 235),
		Duration    = 0.45,
		FillAlpha   = 0.6,
		OutlineAlpha= 0.0,
	},

	Hitbox = {
		Enabled = false,
		X       = 4.0,
		Y       = 4.0,
		Z       = 4.0,
	},

	Hud = {
		Enabled = true,
	},
}

local cleanupTasks = {}
local function addCleanup(fn) table.insert(cleanupTasks, fn) end

local lockTarget    = nil
local lockListeners = {}
local function setLock(v)
	if lockTarget == v then return end
	lockTarget = v
	for _, fn in ipairs(lockListeners) do fn(v) end
end

local function mountGui(gui)
	if gethui then
		local ok, hui = pcall(gethui)
		if ok and hui then
			local ok2 = pcall(function() gui.Parent = hui end)
			if ok2 and gui.Parent then return end
		end
	end
	local ok = pcall(function() gui.Parent = CoreGui end)
	if not ok or not gui.Parent then
		gui.Parent = LP:WaitForChild("PlayerGui")
	end
end

local function TW(obj, props, t, st, dir)
	return TweenService:Create(obj, TweenInfo.new(t or 0.18, st or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
end
local function Rnd(inst, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = inst; return c end
local function W2V(pos) local v, on = Workspace.CurrentCamera:WorldToViewportPoint(pos); return Vector2.new(v.X, v.Y), v.Z, on end
local function SafeKey(k) if type(k)=="userdata" then local ok,n=pcall(function() return k.Name end); if ok and type(n)=="string" and #n>0 then return n end end; return "None" end

local function GetBounds(char)
	local mnX,mnY,mxX,mxY = math.huge,math.huge,-math.huge,-math.huge
	local any = false
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			local s,cf = p.Size, p.CFrame
			local hx,hy,hz = s.X/2,s.Y/2,s.Z/2
			for sx=-1,1,2 do for sy=-1,1,2 do for sz=-1,1,2 do
				local sc,d,on = W2V((cf*CFrame.new(sx*hx,sy*hy,sz*hz)).Position)
				if on and d>0 then
					any=true
					if sc.X<mnX then mnX=sc.X end; if sc.Y<mnY then mnY=sc.Y end
					if sc.X>mxX then mxX=sc.X end; if sc.Y>mxY then mxY=sc.Y end
				end
			end end end
		end
	end
	if not any then return nil end
	return mnX,mnY,mxX,mxY
end

local function HideF(f) if f and f.Parent then f.Visible=false end end

-- ─────────────────────────────────────────────
-- UI
-- ─────────────────────────────────────────────
local function startUI()
	local W, H = 700, 460
	local SIDE  = 130
	local TBAR  = 36

	local SG = Instance.new("ScreenGui")
	SG.Name="EzClientGui"; SG.ResetOnSpawn=false; SG.IgnoreGuiInset=true
	SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
	mountGui(SG)

	local ESPLayer = Instance.new("Frame")
	ESPLayer.Name="ESPLayer"; ESPLayer.Size=UDim2.new(1,0,1,0)
	ESPLayer.BackgroundTransparency=1; ESPLayer.BorderSizePixel=0; ESPLayer.ZIndex=1
	ESPLayer.Parent=SG

	local Win = Instance.new("Frame")
	Win.Name="Win"; Win.Size=UDim2.new(0,W,0,H)
	Win.Position=UDim2.new(0.5,-W/2,0.5,-H/2)
	Win.BackgroundColor3=Palette.Surface; Win.BorderSizePixel=0
	Win.ClipsDescendants=false; Win.Visible=false; Win.ZIndex=10; Win.Parent=SG
	Rnd(Win,8)
	local WinStroke = Instance.new("UIStroke"); WinStroke.Color=Palette.Border; WinStroke.Thickness=1; WinStroke.Parent=Win

	local WinClip = Instance.new("Frame")
	WinClip.Size=UDim2.new(1,0,1,0); WinClip.BackgroundTransparency=1
	WinClip.ClipsDescendants=true; WinClip.BorderSizePixel=0; WinClip.ZIndex=10; WinClip.Parent=Win
	Rnd(WinClip,8)

	local TBar = Instance.new("Frame")
	TBar.Size=UDim2.new(1,0,0,TBAR); TBar.BackgroundColor3=Palette.Deep
	TBar.BorderSizePixel=0; TBar.ZIndex=11; TBar.Parent=WinClip

	local TBarLine = Instance.new("Frame")
	TBarLine.Size=UDim2.new(1,0,0,1); TBarLine.Position=UDim2.new(0,0,1,-1)
	TBarLine.BackgroundColor3=Palette.Border; TBarLine.BorderSizePixel=0; TBarLine.ZIndex=12; TBarLine.Parent=TBar

	local AccentBar = Instance.new("Frame")
	AccentBar.Size=UDim2.new(0,32,0,2); AccentBar.Position=UDim2.new(0,12,1,-2)
	AccentBar.BackgroundColor3=Palette.Violet; AccentBar.BorderSizePixel=0; AccentBar.ZIndex=13; AccentBar.Parent=TBar
	Rnd(AccentBar,1)

	local TTitle = Instance.new("TextLabel")
	TTitle.Size=UDim2.new(1,-90,1,0); TTitle.Position=UDim2.new(0,12,0,0)
	TTitle.BackgroundTransparency=1; TTitle.Font=Enum.Font.GothamBold; TTitle.TextSize=13
	TTitle.TextColor3=Palette.Text; TTitle.TextXAlignment=Enum.TextXAlignment.Left
	TTitle.Text="EzClient"; TTitle.ZIndex=12; TTitle.Parent=TBar

	local TVer = Instance.new("TextLabel")
	TVer.Size=UDim2.new(0,60,1,0); TVer.Position=UDim2.new(0,80,0,0)
	TVer.BackgroundTransparency=1; TVer.Font=Enum.Font.Gotham; TVer.TextSize=11
	TVer.TextColor3=Palette.TextDim; TVer.TextXAlignment=Enum.TextXAlignment.Left
	TVer.Text="v2.0"; TVer.ZIndex=12; TVer.Parent=TBar

	local function TBarBtn(icon, xOff)
		local b = Instance.new("TextButton")
		b.Size=UDim2.new(0,22,0,22); b.Position=UDim2.new(1,xOff,0.5,-11)
		b.BackgroundColor3=Color3.fromRGB(32,28,46); b.BorderSizePixel=0
		b.Font=Enum.Font.GothamBold; b.TextSize=14; b.TextColor3=Palette.TextMid
		b.Text=icon; b.ZIndex=12; b.Parent=TBar; Rnd(b,5)
		b.MouseEnter:Connect(function() TW(b,{BackgroundColor3=Palette.Border},0.08):Play() end)
		b.MouseLeave:Connect(function() TW(b,{BackgroundColor3=Color3.fromRGB(32,28,46)},0.08):Play() end)
		return b
	end
	local BtnClose = TBarBtn("×",-28)
	local BtnMin   = TBarBtn("−",-54)

	do
		local drag,ds,dp=false,nil,nil
		TBar.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;ds=i.Position;dp=Win.Position end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
				local d=i.Position-ds
				Win.Position=UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
		end)
	end

	local SB = Instance.new("Frame")
	SB.Name="Sidebar"; SB.Size=UDim2.new(0,SIDE,1,-TBAR); SB.Position=UDim2.new(0,0,0,TBAR)
	SB.BackgroundColor3=Palette.Deep; SB.BorderSizePixel=0; SB.ZIndex=11; SB.Parent=WinClip

	local SBR = Instance.new("Frame")
	SBR.Size=UDim2.new(0,1,1,0); SBR.Position=UDim2.new(1,-1,0,0)
	SBR.BackgroundColor3=Palette.Border; SBR.BorderSizePixel=0; SBR.ZIndex=12; SBR.Parent=SB

	local SBInner = Instance.new("Frame")
	SBInner.Size=UDim2.new(1,0,1,0); SBInner.BackgroundTransparency=1; SBInner.Parent=SB
	local SBL = Instance.new("UIListLayout"); SBL.SortOrder=Enum.SortOrder.LayoutOrder; SBL.Padding=UDim.new(0,1); SBL.Parent=SBInner
	local SBP = Instance.new("UIPadding"); SBP.PaddingTop=UDim.new(0,8); SBP.PaddingLeft=UDim.new(0,5); SBP.PaddingRight=UDim.new(0,5); SBP.Parent=SBInner

	local Content = Instance.new("Frame")
	Content.Size=UDim2.new(1,-SIDE,1,-TBAR); Content.Position=UDim2.new(0,SIDE,0,TBAR)
	Content.BackgroundTransparency=1; Content.BorderSizePixel=0; Content.ClipsDescendants=true
	Content.ZIndex=11; Content.Parent=WinClip

	local Tabs, TabBtns, ActiveTab = {}, {}, nil

	local TAB_LIST = {
		{id="ESP",      label="ESP",      icon="◈"},
		{id="Camlock",  label="Camlock",  icon="◎"},
		{id="HitFX",    label="Hit FX",   icon="◆"},
		{id="Hitbox",   label="Hitbox",   icon="⬚"},
		{id="Settings", label="Settings", icon="≡"},
		{id="Keybinds", label="Keys",     icon="⌘"},
	}

	local function MakePanel(id)
		local sf = Instance.new("ScrollingFrame")
		sf.Name=id.."_p"; sf.Size=UDim2.new(1,0,1,0); sf.BackgroundTransparency=1
		sf.BorderSizePixel=0; sf.ScrollBarThickness=3; sf.ScrollBarImageColor3=Palette.Border
		sf.CanvasSize=UDim2.new(0,0,0,0); sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
		sf.Visible=false; sf.ZIndex=12; sf.Parent=Content
		local l=Instance.new("UIListLayout"); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,4); l.Parent=sf
		local p=Instance.new("UIPadding"); p.PaddingTop=UDim.new(0,10); p.PaddingBottom=UDim.new(0,12)
		p.PaddingLeft=UDim.new(0,10); p.PaddingRight=UDim.new(0,10); p.Parent=sf
		Tabs[id]=sf; return sf
	end

	local function SwitchTab(id)
		if ActiveTab==id then return end; ActiveTab=id
		for tid,pnl in pairs(Tabs) do pnl.Visible=(tid==id) end
		for tid,d in pairs(TabBtns) do
			local btn,pill=d[1],d[2]
			if tid==id then
				TW(btn,{BackgroundColor3=Color3.fromRGB(38,28,62),TextColor3=Palette.Bright},0.12):Play()
				TW(pill,{BackgroundTransparency=0},0.12):Play()
			else
				TW(btn,{BackgroundColor3=Palette.Deep,TextColor3=Palette.TextDim},0.12):Play()
				TW(pill,{BackgroundTransparency=1},0.12):Play()
			end
		end
	end

	local function MakeSideBtn(def,order)
		local btn=Instance.new("TextButton")
		btn.Size=UDim2.new(1,0,0,32); btn.BackgroundColor3=Palette.Deep; btn.BorderSizePixel=0
		btn.Font=Enum.Font.GothamMedium; btn.TextSize=12; btn.TextColor3=Palette.TextDim
		btn.TextXAlignment=Enum.TextXAlignment.Left
		btn.Text="  "..def.icon.."   "..def.label
		btn.LayoutOrder=order; btn.ZIndex=12; btn.Parent=SBInner; Rnd(btn,5)
		local pill=Instance.new("Frame")
		pill.Size=UDim2.new(0,2,0.55,0); pill.Position=UDim2.new(0,0,0.225,0)
		pill.BackgroundColor3=Palette.Violet; pill.BorderSizePixel=0; pill.BackgroundTransparency=1
		pill.ZIndex=13; pill.Parent=btn; Rnd(pill,1)
		return btn,pill
	end

	for i,def in ipairs(TAB_LIST) do
		MakePanel(def.id)
		local btn,pill=MakeSideBtn(def,i)
		TabBtns[def.id]={btn,pill}
		local tid=def.id
		btn.MouseButton1Click:Connect(function() SwitchTab(tid) end)
		btn.MouseEnter:Connect(function() if ActiveTab~=tid then TW(btn,{BackgroundColor3=Palette.Panel},0.08):Play() end end)
		btn.MouseLeave:Connect(function() if ActiveTab~=tid then TW(btn,{BackgroundColor3=Palette.Deep},0.08):Play() end end)
	end
	SwitchTab("ESP")

	-- widget builders
	local function Header(parent,text,order)
		local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,22); f.BackgroundTransparency=1; f.LayoutOrder=order or 0; f.Parent=parent
		local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,-4,1,0); l.Position=UDim2.new(0,2,0,0)
		l.BackgroundTransparency=1; l.Font=Enum.Font.GothamMedium; l.TextSize=10; l.TextColor3=Palette.Bright
		l.TextXAlignment=Enum.TextXAlignment.Left; l.Text=string.upper(text); l.Parent=f
		local ln=Instance.new("Frame"); ln.Size=UDim2.new(1,0,0,1); ln.Position=UDim2.new(0,0,1,-1)
		ln.BackgroundColor3=Palette.Border; ln.BorderSizePixel=0; ln.Parent=f
		return f
	end

	local function Toggle(parent,label,tbl,key,order,cb)
		local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,30); row.BackgroundColor3=Palette.Panel
		row.BorderSizePixel=0; row.LayoutOrder=order or 0; row.Parent=parent; Rnd(row,5)
		local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-52,1,0); lbl.Position=UDim2.new(0,9,0,0)
		lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.Gotham; lbl.TextSize=12
		lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=label; lbl.Parent=row
		local track=Instance.new("Frame"); track.Size=UDim2.new(0,32,0,17); track.Position=UDim2.new(1,-40,0.5,-8)
		track.BorderSizePixel=0; track.Parent=row; Rnd(track,9)
		local knob=Instance.new("Frame"); knob.Size=UDim2.new(0,11,0,11); knob.BorderSizePixel=0
		knob.BackgroundColor3=Palette.White; knob.Parent=track; Rnd(knob,6)
		local function Refresh()
			local on=tbl[key]
			TW(track,{BackgroundColor3=on and Palette.Violet or Palette.Border},0.15):Play()
			TW(knob,{Position=on and UDim2.new(0,18,0.5,-5) or UDim2.new(0,3,0.5,-5)},0.15):Play()
			lbl.TextColor3=on and Palette.Text or Palette.TextMid
		end
		Refresh()
		local hit=Instance.new("TextButton"); hit.Size=UDim2.new(1,0,1,0); hit.BackgroundTransparency=1; hit.Text=""; hit.Parent=row
		hit.MouseButton1Click:Connect(function() tbl[key]=not tbl[key]; Refresh(); if cb then cb(tbl[key]) end end)
		hit.MouseEnter:Connect(function() TW(row,{BackgroundColor3=Palette.PanelHover},0.08):Play() end)
		hit.MouseLeave:Connect(function() TW(row,{BackgroundColor3=Palette.Panel},0.08):Play() end)
		return row,Refresh
	end

	local function Slider(parent,label,tbl,key,mn,mx,step,order,fmt,cb)
		fmt=fmt or "%g"; step=step or 1
		local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,44); row.BackgroundColor3=Palette.Panel
		row.BorderSizePixel=0; row.LayoutOrder=order or 0; row.Parent=parent; Rnd(row,5)
		local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(0.65,0,0,18); lbl.Position=UDim2.new(0,9,0,4)
		lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.Gotham; lbl.TextSize=12; lbl.TextColor3=Palette.Text
		lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=label; lbl.Parent=row
		local val=Instance.new("TextLabel"); val.Size=UDim2.new(0.35,-9,0,18); val.Position=UDim2.new(0.65,0,0,4)
		val.BackgroundTransparency=1; val.Font=Enum.Font.GothamMedium; val.TextSize=11; val.TextColor3=Palette.Bright
		val.TextXAlignment=Enum.TextXAlignment.Right; val.Text=string.format(fmt,tbl[key]); val.Parent=row
		local trk=Instance.new("Frame"); trk.Size=UDim2.new(1,-18,0,4); trk.Position=UDim2.new(0,9,0,30)
		trk.BackgroundColor3=Palette.Border; trk.BorderSizePixel=0; trk.Parent=row; Rnd(trk,2)
		local p0=math.clamp((tbl[key]-mn)/(mx-mn),0,1)
		local fill=Instance.new("Frame"); fill.Size=UDim2.new(p0,0,1,0); fill.BackgroundColor3=Palette.Violet
		fill.BorderSizePixel=0; fill.Parent=trk; Rnd(fill,2)
		local thumb=Instance.new("Frame"); thumb.Size=UDim2.new(0,10,0,10); thumb.AnchorPoint=Vector2.new(0.5,0.5)
		thumb.Position=UDim2.new(p0,0,0.5,0); thumb.BackgroundColor3=Palette.White; thumb.BorderSizePixel=0; thumb.Parent=trk; Rnd(thumb,5)
		local function SetV(raw)
			local v=math.clamp(math.floor((raw-mn)/step+0.5)*step+mn,mn,mx)
			tbl[key]=v; local p=math.clamp((v-mn)/(mx-mn),0,1)
			fill.Size=UDim2.new(p,0,1,0); thumb.Position=UDim2.new(p,0,0.5,0)
			val.Text=string.format(fmt,v); if cb then cb(v) end
		end
		local sliding=false
		trk.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true; SetV(mn+(i.Position.X-trk.AbsolutePosition.X)/trk.AbsoluteSize.X*(mx-mn)) end end)
		UserInputService.InputChanged:Connect(function(i) if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then SetV(mn+(i.Position.X-trk.AbsolutePosition.X)/trk.AbsoluteSize.X*(mx-mn)) end end)
		UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end end)
		return row
	end

	local function Dropdown(parent,label,tbl,key,opts,order,cb)
		local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,30); row.BackgroundColor3=Palette.Panel
		row.BorderSizePixel=0; row.LayoutOrder=order or 0; row.ClipsDescendants=false; row.ZIndex=5; row.Parent=parent; Rnd(row,5)
		local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(0.5,0,1,0); lbl.Position=UDim2.new(0,9,0,0)
		lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.Gotham; lbl.TextSize=12; lbl.TextColor3=Palette.Text
		lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=label; lbl.ZIndex=6; lbl.Parent=row
		local dbtn=Instance.new("TextButton"); dbtn.Size=UDim2.new(0,115,0,20); dbtn.Position=UDim2.new(1,-122,0.5,-10)
		dbtn.BackgroundColor3=Palette.Deep; dbtn.Font=Enum.Font.GothamMedium; dbtn.TextSize=11
		dbtn.TextColor3=Palette.Bright; dbtn.Text=tostring(tbl[key]).." ▾"; dbtn.BorderSizePixel=0; dbtn.ZIndex=6; dbtn.Parent=row; Rnd(dbtn,4)
		local list=Instance.new("Frame"); list.Size=UDim2.new(0,115,0,#opts*24+6); list.Position=UDim2.new(1,-122,1,2)
		list.BackgroundColor3=Palette.Deep; list.BorderSizePixel=1; list.BorderColor3=Palette.Border
		list.Visible=false; list.ZIndex=30; list.Parent=row; Rnd(list,5)
		local ll=Instance.new("UIListLayout"); ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,0); ll.Parent=list
		local lp=Instance.new("UIPadding"); lp.PaddingTop=UDim.new(0,3); lp.Parent=list
		for i,opt in ipairs(opts) do
			local item=Instance.new("TextButton"); item.Size=UDim2.new(1,0,0,24); item.BackgroundColor3=Palette.Deep
			item.BorderSizePixel=0; item.Font=Enum.Font.Gotham; item.TextSize=11
			item.TextColor3=tostring(tbl[key])==opt and Palette.Bright or Palette.TextMid
			item.Text=opt; item.ZIndex=31; item.LayoutOrder=i; item.Parent=list
			item.MouseEnter:Connect(function() TW(item,{BackgroundColor3=Palette.Panel},0.06):Play() end)
			item.MouseLeave:Connect(function() TW(item,{BackgroundColor3=Palette.Deep},0.06):Play() end)
			item.MouseButton1Click:Connect(function()
				tbl[key]=opt; dbtn.Text=opt.." ▾"; list.Visible=false
				for _,ch in ipairs(list:GetChildren()) do if ch:IsA("TextButton") then ch.TextColor3=ch.Text==opt and Palette.Bright or Palette.TextMid end end
				if cb then cb(opt) end
			end)
		end
		local open=false
		dbtn.MouseButton1Click:Connect(function() open=not open; list.Visible=open end)
		UserInputService.InputBegan:Connect(function(i)
			if open and i.UserInputType==Enum.UserInputType.MouseButton1 then
				local p=i.Position; local rp=row.AbsolutePosition; local rs=row.AbsoluteSize
				if not(p.X>=rp.X and p.X<=rp.X+rs.X+10 and p.Y>=rp.Y and p.Y<=rp.Y+rs.Y+list.AbsoluteSize.Y+8) then
					open=false; list.Visible=false
				end
			end
		end)
		return row
	end

	local ActivePicker=nil
	local function ColorPicker(parent,label,tbl,key,order,cb)
		local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,30); row.BackgroundColor3=Palette.Panel
		row.BorderSizePixel=0; row.LayoutOrder=order or 0; row.Parent=parent; Rnd(row,5)
		local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-52,1,0); lbl.Position=UDim2.new(0,9,0,0)
		lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.Gotham; lbl.TextSize=12; lbl.TextColor3=Palette.Text
		lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=label; lbl.Parent=row
		local sw=Instance.new("TextButton"); sw.Size=UDim2.new(0,36,0,18); sw.Position=UDim2.new(1,-43,0.5,-9)
		sw.BackgroundColor3=tbl[key]; sw.BorderSizePixel=0; sw.Text=""; sw.Parent=row; Rnd(sw,4)
		local swS=Instance.new("UIStroke"); swS.Color=Palette.BorderBright; swS.Thickness=1; swS.Parent=sw

		local popup=Instance.new("Frame"); popup.Size=UDim2.new(0,200,0,158)
		popup.BackgroundColor3=Palette.Deep; popup.BorderSizePixel=1; popup.BorderColor3=Palette.Border
		popup.Visible=false; popup.ZIndex=60; popup.Parent=SG; Rnd(popup,7)

		local ptitle=Instance.new("TextLabel"); ptitle.Size=UDim2.new(1,0,0,22); ptitle.BackgroundTransparency=1
		ptitle.Font=Enum.Font.GothamMedium; ptitle.TextSize=11; ptitle.TextColor3=Palette.TextMid
		ptitle.Text=label; ptitle.ZIndex=61; ptitle.Parent=popup

		local h0,s0,v0=tbl[key]:ToHSV()
		local function MkPS(yp,lc,iv)
			local t=Instance.new("Frame"); t.Size=UDim2.new(1,-28,0,12); t.Position=UDim2.new(0,22,0,yp)
			t.BackgroundColor3=Palette.Border; t.BorderSizePixel=0; t.ZIndex=62; t.Parent=popup; Rnd(t,3)
			local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(0,16,1,0); tl.Position=UDim2.new(0,-18,0,0)
			tl.BackgroundTransparency=1; tl.Font=Enum.Font.GothamMedium; tl.TextSize=9; tl.TextColor3=Palette.TextDim; tl.Text=lc; tl.ZIndex=62; tl.Parent=t
			local f=Instance.new("Frame"); f.Size=UDim2.new(math.clamp(iv,0,1),0,1,0); f.BackgroundColor3=Palette.Violet; f.BorderSizePixel=0; f.Parent=t; Rnd(f,3)
			local k=Instance.new("Frame"); k.Size=UDim2.new(0,8,0,8); k.AnchorPoint=Vector2.new(0.5,0.5)
			k.Position=UDim2.new(math.clamp(iv,0,1),0,0.5,0); k.BackgroundColor3=Palette.White; k.BorderSizePixel=0; k.ZIndex=63; k.Parent=t; Rnd(k,4)
			return t,f,k
		end
		local hT,hF,hK=MkPS(26,"H",h0); local sT,sF,sK=MkPS(48,"S",s0); local vT,vF,vK=MkPS(70,"V",v0)
		local prev=Instance.new("Frame"); prev.Size=UDim2.new(1,-18,0,18); prev.Position=UDim2.new(0,9,0,90)
		prev.BackgroundColor3=Color3.fromHSV(h0,s0,v0); prev.BorderSizePixel=0; prev.ZIndex=62; prev.Parent=popup; Rnd(prev,4)
		local apB=Instance.new("TextButton"); apB.Size=UDim2.new(1,-18,0,22); apB.Position=UDim2.new(0,9,0,114)
		apB.BackgroundColor3=Palette.Violet; apB.Font=Enum.Font.GothamMedium; apB.TextSize=11
		apB.TextColor3=Palette.White; apB.Text="Apply"; apB.BorderSizePixel=0; apB.ZIndex=62; apB.Parent=popup; Rnd(apB,4)

		local function RefPrev() prev.BackgroundColor3=Color3.fromHSV(h0,s0,v0) end
		local function BindPS(tr,fi,kn,set)
			local act=false
			tr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then act=true; local r=math.clamp((i.Position.X-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1); set(r); fi.Size=UDim2.new(r,0,1,0); kn.Position=UDim2.new(r,0,0.5,0); RefPrev() end end)
			UserInputService.InputChanged:Connect(function(i) if act and i.UserInputType==Enum.UserInputType.MouseMovement then local r=math.clamp((i.Position.X-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1); set(r); fi.Size=UDim2.new(r,0,1,0); kn.Position=UDim2.new(r,0,0.5,0); RefPrev() end end)
			UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then act=false end end)
		end
		BindPS(hT,hF,hK,function(r) h0=r end); BindPS(sT,sF,sK,function(r) s0=r end); BindPS(vT,vF,vK,function(r) v0=r end)
		apB.MouseButton1Click:Connect(function()
			local col=Color3.fromHSV(h0,s0,v0); tbl[key]=col; sw.BackgroundColor3=col; popup.Visible=false; ActivePicker=nil; if cb then cb(col) end
		end)
		local picOpen=false
		sw.MouseButton1Click:Connect(function()
			if ActivePicker and ActivePicker~=popup then ActivePicker.Visible=false end
			picOpen=not picOpen; popup.Visible=picOpen; ActivePicker=picOpen and popup or nil
			if picOpen then
				local ap=sw.AbsolutePosition
				popup.Position=UDim2.new(0,math.min(ap.X+44,Workspace.CurrentCamera.ViewportSize.X-210),0,math.max(4,ap.Y-20))
				h0,s0,v0=tbl[key]:ToHSV()
				hK.Position=UDim2.new(math.clamp(h0,0,1),0,0.5,0); hF.Size=UDim2.new(math.clamp(h0,0,1),0,1,0)
				sK.Position=UDim2.new(math.clamp(s0,0,1),0,0.5,0); sF.Size=UDim2.new(math.clamp(s0,0,1),0,1,0)
				vK.Position=UDim2.new(math.clamp(v0,0,1),0,0.5,0); vF.Size=UDim2.new(math.clamp(v0,0,1),0,1,0)
				RefPrev()
			end
		end)
		return row
	end

	local function KeyRow(parent,label,tbl,key,order)
		local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,30); row.BackgroundColor3=Palette.Panel
		row.BorderSizePixel=0; row.LayoutOrder=order or 0; row.Parent=parent; Rnd(row,5)
		local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-100,1,0); lbl.Position=UDim2.new(0,9,0,0)
		lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.Gotham; lbl.TextSize=12; lbl.TextColor3=Palette.Text
		lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=label; lbl.Parent=row
		local kb=Instance.new("TextButton"); kb.Size=UDim2.new(0,80,0,20); kb.Position=UDim2.new(1,-87,0.5,-10)
		kb.BackgroundColor3=Palette.Deep; kb.Font=Enum.Font.GothamMedium; kb.TextSize=11
		kb.TextColor3=Palette.Bright; kb.Text=SafeKey(tbl[key]); kb.BorderSizePixel=0; kb.Parent=row; Rnd(kb,4)
		local listening=false
		kb.MouseButton1Click:Connect(function() listening=true; kb.Text="…"; kb.TextColor3=Palette.TextDim end)
		kb.MouseEnter:Connect(function() TW(row,{BackgroundColor3=Palette.PanelHover},0.08):Play() end)
		kb.MouseLeave:Connect(function() TW(row,{BackgroundColor3=Palette.Panel},0.08):Play() end)
		UserInputService.InputBegan:Connect(function(i)
			if not listening then return end
			if i.UserInputType==Enum.UserInputType.Keyboard then
				tbl[key]=i.KeyCode; kb.Text=SafeKey(i.KeyCode); kb.TextColor3=Palette.Bright; listening=false
			end
		end)
		return row
	end

	local function ActBtn(parent,text,order,cb)
		local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,30); row.BackgroundTransparency=1; row.LayoutOrder=order or 0; row.Parent=parent
		local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundColor3=Palette.AccentDim or Palette.Violet
		btn.Font=Enum.Font.GothamMedium; btn.TextSize=12; btn.TextColor3=Palette.White; btn.Text=text; btn.BorderSizePixel=0; btn.Parent=row; Rnd(btn,5)
		btn.MouseEnter:Connect(function() TW(btn,{BackgroundColor3=Palette.Bright},0.1):Play() end)
		btn.MouseLeave:Connect(function() TW(btn,{BackgroundColor3=Palette.Violet},0.1):Play() end)
		btn.MouseButton1Click:Connect(function() if cb then cb() end end)
		return row
	end

	-- build tabs
	local esp=Tabs["ESP"]; local cam=Tabs["Camlock"]; local hit=Tabs["HitFX"]; local hb=Tabs["Hitbox"]
	local settings=Tabs["Settings"]; local keys=Tabs["Keybinds"]

	Header(esp,"Visibility",1)
	Toggle(esp,"Enable ESP",         Config.Esp,"Enabled",   2)
	Toggle(esp,"Names",              Config.Esp,"Names",     3)
	Toggle(esp,"2D Boxes",           Config.Esp,"Boxes",     4)
	Toggle(esp,"Tracers",            Config.Esp,"Tracers",   5)
	Toggle(esp,"Health Bars",        Config.Esp,"Health",    6)
	Toggle(esp,"Distance Labels",    Config.Esp,"Distance",  7)
	Toggle(esp,"Character Outline",  Config.Esp,"Outline",   8)
	Toggle(esp,"Skeleton",           Config.Esp,"Skeleton",  9)
	Toggle(esp,"Team Filter",        Config.Esp,"TeamFilter",10)
	Header(esp,"Config",11)
	Slider(esp, "Max Distance",      Config.Esp,"MaxDist",   50,1000,10,12,"%g")
	Slider(esp, "Name Size",         Config.Esp,"NameSize",  8,20,1,13,"%g")
	Slider(esp, "Box Thickness",     Config.Esp,"BoxThick",  0.5,4,0.5,14,"%.1f")
	Slider(esp, "Tracer Thickness",  Config.Esp,"TracerThick",0.5,4,0.5,15,"%.1f")
	Dropdown(esp,"Tracer Origin",    Config.Esp,"TracerOrigin",{"Bottom","Center","Cursor"},16)
	Header(esp,"Colors",17)
	ColorPicker(esp,"Name Color",    Config.Esp,"NormalColor",18)
	ColorPicker(esp,"Target Color",  Config.Esp,"TargetColor",19)
	ColorPicker(esp,"Box Color",     Config.Esp,"BoxColor",  20)

	Header(cam,"Camera Lock",1)
	Toggle(cam, "Enable Camlock",    Config.Cam,"Enabled",   2)
	Dropdown(cam,"Priority",         Config.Cam,"Priority",  {"Closest","LowHealth","FOV"},3)
	Dropdown(cam,"Target Part",      Config.Cam,"TargetPart",{"Head","HumanoidRootPart","Torso"},4)
	Slider(cam, "Smoothing",         Config.Cam,"Smoothing", 0.01,1.0,0.01,5,"%.2f")
	Slider(cam, "Sensitivity",       Config.Cam,"Sensitivity",0.1,3.0,0.05,6,"%.2f")
	Slider(cam, "Max Distance",      Config.Cam,"MaxDist",   50,1000,10,7,"%g")
	Header(cam,"FOV Circle",8)
	Toggle(cam, "Show FOV Circle",   Config.Cam,"ShowFOV",   9)
	Slider(cam, "FOV Radius",        Config.Cam,"FOVRadius", 10,400,5,10,"%g")
	Slider(cam, "Thickness",         Config.Cam,"FOVThick",  0.5,5,0.5,11,"%.1f")
	Slider(cam, "Transparency",      Config.Cam,"FOVAlpha",  0.0,0.9,0.05,12,"%.2f")
	ColorPicker(cam,"Circle Color",  Config.Cam,"FOVColor",  13)

	do
		local trow=Instance.new("Frame"); trow.Size=UDim2.new(1,0,0,28); trow.BackgroundColor3=Color3.fromRGB(38,28,62)
		trow.BorderSizePixel=0; trow.LayoutOrder=14; trow.Parent=cam; Rnd(trow,5)
		local tl=Instance.new("TextLabel"); tl.Name="TargetLabel"; tl.Size=UDim2.new(1,-12,1,0); tl.Position=UDim2.new(0,8,0,0)
		tl.BackgroundTransparency=1; tl.Font=Enum.Font.GothamMedium; tl.TextSize=11; tl.TextColor3=Palette.TextMid
		tl.TextXAlignment=Enum.TextXAlignment.Left; tl.Text="No target"; tl.Parent=trow
	end

	Header(hit,"Hit Feedback",1)
	Toggle(hit, "Enable Hit Outline",Config.Hit,"Enabled",   2)
	Slider(hit, "Duration",          Config.Hit,"Duration",  0.1,2.0,0.05,3,"%.2fs")
	Slider(hit, "Fill Transparency", Config.Hit,"FillAlpha", 0.0,1.0,0.05,4,"%.2f")
	Slider(hit, "Outline Alpha",     Config.Hit,"OutlineAlpha",0.0,1.0,0.05,5,"%.2f")
	ColorPicker(hit,"Hit Color",     Config.Hit,"Color",     6)

	Header(hb,"Hitbox Expander",1)
	do
		local nf=Instance.new("Frame"); nf.Size=UDim2.new(1,0,0,34); nf.BackgroundColor3=Palette.Panel; nf.BorderSizePixel=0; nf.LayoutOrder=2; nf.Parent=hb; Rnd(nf,5)
		local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(1,-12,1,0); nl.Position=UDim2.new(0,6,0,0)
		nl.BackgroundTransparency=1; nl.Font=Enum.Font.Gotham; nl.TextSize=10; nl.TextColor3=Palette.TextDim
		nl.TextWrapped=true; nl.TextXAlignment=Enum.TextXAlignment.Left
		nl.Text="Studio testing only. Visualizes hitbox; does not change server-side hit registration."; nl.Parent=nf
	end
	Toggle(hb,  "Enable Hitbox Preview",Config.Hitbox,"Enabled",3)
	Slider(hb,  "Width  (X)",           Config.Hitbox,"X",    1,20,0.25,4,"%.2f")
	Slider(hb,  "Height (Y)",           Config.Hitbox,"Y",    1,20,0.25,5,"%.2f")
	Slider(hb,  "Depth  (Z)",           Config.Hitbox,"Z",    1,20,0.25,6,"%.2f")
	ActBtn(hb,  "Reset Hitbox Defaults",7,function() Config.Hitbox.X=4;Config.Hitbox.Y=4;Config.Hitbox.Z=4 end)

	Header(settings,"Display",1)
	Toggle(settings,"Show HUD",      Config.Hud,"Enabled",   2)
	Header(settings,"Defaults",3)
	ActBtn(settings,"Reset All to Default",4,function()
		local E=Config.Esp; E.Enabled=false;E.Names=true;E.Boxes=true;E.Tracers=false;E.Health=true
		E.Distance=true;E.Outline=false;E.Skeleton=false;E.MaxDist=500;E.NameSize=13
		E.BoxThick=1;E.TracerThick=1;E.TracerOrigin="Bottom";E.TeamFilter=false
		E.NormalColor=Color3.fromRGB(218,210,235);E.TargetColor=Color3.fromRGB(148,60,235);E.BoxColor=Color3.fromRGB(218,210,235)
		local C2=Config.Cam; C2.Enabled=false;C2.Smoothing=0.10;C2.Sensitivity=1.0;C2.FOVRadius=80
		C2.ShowFOV=true;C2.FOVThick=1;C2.FOVAlpha=0.25;C2.MaxDist=500;C2.FOVColor=Color3.fromRGB(148,60,235)
		local H=Config.Hit; H.Enabled=true;H.Duration=0.45;H.FillAlpha=0.6;H.OutlineAlpha=0.0;H.Color=Color3.fromRGB(148,60,235)
		Config.Hitbox.Enabled=false;Config.Hitbox.X=4;Config.Hitbox.Y=4;Config.Hitbox.Z=4
		Config.Hud.Enabled=true
	end)

	Header(keys,"Keybinds",1)
	KeyRow(keys,"Toggle Menu",  Config,"MenuKey", 2)
	KeyRow(keys,"Camlock Key",  Config.Cam,"Key", 3)
	KeyRow(keys,"Unload",       Config,"UnloadKey",4)

	-- HUD
	local HUD=Instance.new("Frame"); HUD.Name="HUD"; HUD.Size=UDim2.new(0,92,0,8)
	HUD.Position=UDim2.new(0,8,0.5,-50); HUD.BackgroundColor3=Color3.fromRGB(10,8,18)
	HUD.BackgroundTransparency=0.2; HUD.BorderSizePixel=0; HUD.AutomaticSize=Enum.AutomaticSize.Y
	HUD.ZIndex=5; HUD.Parent=SG; Rnd(HUD,5)
	local hs=Instance.new("UIStroke"); hs.Color=Palette.Border; hs.Thickness=1; hs.Parent=HUD
	local hl2=Instance.new("UIListLayout"); hl2.SortOrder=Enum.SortOrder.LayoutOrder; hl2.Padding=UDim.new(0,1); hl2.Parent=HUD
	local hp=Instance.new("UIPadding"); hp.PaddingTop=UDim.new(0,4); hp.PaddingBottom=UDim.new(0,4); hp.PaddingLeft=UDim.new(0,6); hp.PaddingRight=UDim.new(0,6); hp.Parent=HUD
	local htl=Instance.new("TextLabel"); htl.Size=UDim2.new(1,0,0,13); htl.BackgroundTransparency=1
	htl.Font=Enum.Font.GothamMedium; htl.TextSize=10; htl.TextColor3=Palette.Bright
	htl.TextXAlignment=Enum.TextXAlignment.Left; htl.Text="EzClient"; htl.LayoutOrder=0; htl.Parent=HUD
	local HUD_FEATS={{tbl=Config.Esp,key="Enabled",lbl="ESP"},{tbl=Config.Cam,key="Enabled",lbl="Lock"},{tbl=Config.Hit,key="Enabled",lbl="Hit"},{tbl=Config.Hitbox,key="Enabled",lbl="HBox"}}
	local HUDItems={}
	for i,f in ipairs(HUD_FEATS) do
		local item=Instance.new("TextLabel"); item.Size=UDim2.new(1,0,0,11); item.BackgroundTransparency=1
		item.Font=Enum.Font.Gotham; item.TextSize=10; item.TextXAlignment=Enum.TextXAlignment.Left
		item.LayoutOrder=i; item.Parent=HUD; HUDItems[i]=item
	end
	local function UpdateHUD()
		HUD.Visible=Config.Hud.Enabled
		for i,f in ipairs(HUD_FEATS) do
			local item=HUDItems[i]; local on=f.tbl[f.key]
			item.Text=(on and "▪ " or "· ")..f.lbl
			item.TextColor3=on and Palette.Bright or Palette.TextDim
		end
	end
	UpdateHUD()

	-- FOV Circle
	local FOVFrame=Instance.new("Frame"); FOVFrame.BackgroundTransparency=1; FOVFrame.BorderSizePixel=0
	FOVFrame.AnchorPoint=Vector2.new(0.5,0.5); FOVFrame.ZIndex=3; FOVFrame.Parent=SG
	local FOVInner=Instance.new("Frame"); FOVInner.Name="Inner"; FOVInner.AnchorPoint=Vector2.new(0.5,0.5)
	FOVInner.BackgroundTransparency=1; FOVInner.ZIndex=3; FOVInner.Parent=FOVFrame
	do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=FOVInner end
	local FOVStroke=Instance.new("UIStroke"); FOVStroke.Color=Palette.Bright; FOVStroke.Thickness=1; FOVStroke.Transparency=0.25; FOVStroke.Parent=FOVInner
	local function UpdateFOV()
		local vp=Workspace.CurrentCamera.ViewportSize; local dia=Config.Cam.FOVRadius*2
		FOVFrame.Size=UDim2.new(0,dia,0,dia); FOVFrame.Position=UDim2.new(0,vp.X/2,0,vp.Y/2)
		FOVFrame.Visible=Config.Cam.Enabled and Config.Cam.ShowFOV
		FOVInner.Size=UDim2.new(1,0,1,0); FOVInner.Position=UDim2.new(0.5,0,0.5,0)
		FOVStroke.Color=Config.Cam.FOVColor; FOVStroke.Thickness=Config.Cam.FOVThick; FOVStroke.Transparency=Config.Cam.FOVAlpha
	end
	UpdateFOV()

	-- menu open/close
	local menuOpen=false
	local function SetMenu(v)
		menuOpen=v
		if v then
			Win.Visible=true; Win.Size=UDim2.new(0,0,0,0); Win.Position=UDim2.new(0.5,0,0.5,0)
			TW(Win,{Size=UDim2.new(0,W,0,H),Position=UDim2.new(0.5,-W/2,0.5,-H/2)},0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out):Play()
		else
			local t=TW(Win,{Size=UDim2.new(0,W,0,0),Position=UDim2.new(0.5,-W/2,0.5,-H/2)},0.16,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
			t:Play(); t.Completed:Once(function() if not menuOpen then Win.Visible=false end end)
		end
	end
	BtnClose.MouseButton1Click:Connect(function() SetMenu(false) end)
	BtnMin.MouseButton1Click:Connect(function() SetMenu(false) end)

	local menuConn=UserInputService.InputBegan:Connect(function(i,gpe)
		if gpe then return end
		if type(Config.MenuKey)=="userdata" and i.KeyCode==Config.MenuKey then SetMenu(not menuOpen) end
	end)

	SetMenu(true)

	addCleanup(function()
		menuConn:Disconnect()
		SG:Destroy()
	end)

	return SG, ESPLayer, UpdateHUD, UpdateFOV
end

-- ─────────────────────────────────────────────
-- ESP
-- ─────────────────────────────────────────────
local function startEsp(ESPLayer)
	local records = {}
	local connections = {}

	local function MakeLine()
		local f=Instance.new("Frame"); f.BackgroundColor3=Palette.Text; f.BorderSizePixel=0; f.Visible=false; f.Parent=ESPLayer; return f
	end

	local function DestroyRecord(player)
		local d=records[player]; if not d then return end
		records[player]=nil
		for _,conn in ipairs(d.conns) do pcall(function() conn:Disconnect() end) end
		for _,obj in ipairs(d.objects) do pcall(function() if obj and obj.Parent then obj:Destroy() end end) end
	end

	local function DrawLine(f,x1,y1,x2,y2,thick)
		local dx,dy=x2-x1,y2-y1; local len=math.sqrt(dx*dx+dy*dy)
		if len<1 then f.Visible=false; return end
		f.Size=UDim2.new(0,len,0,math.max(1,thick)); f.Position=UDim2.new(0,x1,0,y1-thick/2)
		f.Rotation=math.deg(math.atan2(dy,dx)); f.Visible=true
	end

	local function CreateRecord(player)
		if player==LP then return end
		DestroyRecord(player)
		local d={objects={},conns={}}
		records[player]=d

		local bb=Instance.new("BillboardGui"); bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,130,0,18)
		bb.StudsOffset=Vector3.new(0,3.2,0); bb.Parent=Workspace
		local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(1,0,1,0); nl.BackgroundTransparency=1
		nl.Font=Enum.Font.GothamMedium; nl.TextStrokeTransparency=0.4; nl.TextStrokeColor3=Color3.fromRGB(0,0,0); nl.Parent=bb
		d.bb=bb; d.nl=nl; table.insert(d.objects,bb)

		local hBB=Instance.new("BillboardGui"); hBB.AlwaysOnTop=true; hBB.Size=UDim2.new(0,4,0,36)
		hBB.StudsOffset=Vector3.new(-2.4,0,0); hBB.Parent=Workspace
		local hBG=Instance.new("Frame"); hBG.Size=UDim2.new(1,0,1,0); hBG.BackgroundColor3=Color3.fromRGB(20,18,28)
		hBG.BorderSizePixel=0; hBG.Parent=hBB; Rnd(hBG,2)
		local hFill=Instance.new("Frame"); hFill.AnchorPoint=Vector2.new(0,1); hFill.Position=UDim2.new(0,0,1,0)
		hFill.BackgroundColor3=Palette.Green; hFill.BorderSizePixel=0; hFill.Parent=hBG; Rnd(hFill,2)
		d.hBB=hBB; d.hFill=hFill; table.insert(d.objects,hBB)

		local selBox=Instance.new("SelectionBox"); selBox.Color3=Palette.Text; selBox.LineThickness=0.03
		selBox.SurfaceTransparency=1; selBox.SurfaceColor3=Palette.Text; selBox.Parent=Workspace
		d.selBox=selBox; table.insert(d.objects,selBox)

		d.boxTop=MakeLine(); d.boxBot=MakeLine(); d.boxLeft=MakeLine(); d.boxRight=MakeLine(); d.tracer=MakeLine()
		local dLbl=Instance.new("TextLabel"); dLbl.BackgroundTransparency=1; dLbl.Font=Enum.Font.Gotham
		dLbl.TextStrokeTransparency=0.4; dLbl.TextStrokeColor3=Color3.fromRGB(0,0,0)
		dLbl.TextXAlignment=Enum.TextXAlignment.Center; dLbl.TextColor3=Palette.Text; dLbl.Visible=false; dLbl.Parent=ESPLayer
		d.dLbl=dLbl
		for _,obj in ipairs({d.boxTop,d.boxBot,d.boxLeft,d.boxRight,d.tracer,dLbl}) do table.insert(d.objects,obj) end
	end

	local function SetupRecord(player)
		CreateRecord(player)
		local function OnChar(char)
			local d=records[player]; if not d then return end
			local hrp=char:WaitForChild("HumanoidRootPart",5)
			local hum=char:WaitForChild("Humanoid",5)
			if not hrp or not hum then return end
			if d.bb then d.bb.Adornee=hrp end
			if d.hBB then d.hBB.Adornee=hrp end
			if d.selBox then d.selBox.Adornee=char end
			local hConn=hum.HealthChanged:Connect(function(hp)
				local d2=records[player]; if not d2 or not d2.hFill then return end
				local pct=math.clamp(hp/math.max(hum.MaxHealth,1),0,1)
				local col=pct>0.5 and Palette.Green or pct>0.25 and Palette.Orange or Palette.Red
				d2.hFill.BackgroundColor3=col; d2.hFill.Size=UDim2.new(1,0,pct,0)
			end)
			table.insert(d.conns,hConn)
		end
		if player.Character then task.spawn(OnChar,player.Character) end
		local cc=player.CharacterAdded:Connect(function(c) task.spawn(OnChar,c) end)
		if records[player] then table.insert(records[player].conns,cc) end
	end

	local stepConn=RunService.RenderStepped:Connect(function()
		if not Config.Esp.Enabled then
			for _,d in pairs(records) do
				if d.bb then pcall(function() d.bb.Enabled=false end) end
				if d.hBB then pcall(function() d.hBB.Enabled=false end) end
				if d.selBox then pcall(function() d.selBox.Adornee=nil end) end
				HideF(d.boxTop);HideF(d.boxBot);HideF(d.boxLeft);HideF(d.boxRight);HideF(d.tracer);HideF(d.dLbl)
				if d.bones then for _,b in ipairs(d.bones) do HideF(b) end end
			end
			return
		end
		local myChar=LP.Character; local myHRP=myChar and myChar:FindFirstChild("HumanoidRootPart")
		local vp=Workspace.CurrentCamera.ViewportSize
		for player,d in pairs(records) do
			local char=player.Character
			local hrp=char and char:FindFirstChild("HumanoidRootPart")
			local hum=char and char:FindFirstChildOfClass("Humanoid")
			local alive=char~=nil and hrp~=nil and hum~=nil and hum.Health>0
			if alive and Config.Esp.TeamFilter and player.Team==LP.Team then alive=false end
			if alive and myHRP and (hrp.Position-myHRP.Position).Magnitude>Config.Esp.MaxDist then alive=false end
			local isTarget=(lockTarget==player)
			local nameColor=isTarget and Config.Esp.TargetColor or Config.Esp.NormalColor
			if d.bb then pcall(function() d.bb.Enabled=alive and Config.Esp.Names end) end
			if d.hBB then pcall(function() d.hBB.Enabled=alive and Config.Esp.Health end) end
			if d.selBox then pcall(function()
				if alive and Config.Esp.Outline then
					d.selBox.Adornee=char; d.selBox.Color3=nameColor; d.selBox.SurfaceColor3=nameColor
					d.selBox.LineThickness=0.03; d.selBox.SurfaceTransparency=0.85
				else d.selBox.Adornee=nil end
			end) end
			if alive then
				if d.nl then pcall(function() d.nl.Text=player.Name; d.nl.TextSize=Config.Esp.NameSize; d.nl.TextColor3=nameColor end) end
				if d.hFill and hum then pcall(function() d.hFill.Size=UDim2.new(1,0,math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1),0) end) end
				local mnX,mnY,mxX,mxY=GetBounds(char)
				if mnX then
					local bk=Config.Esp.BoxThick
					if Config.Esp.Boxes then
						if d.boxTop and d.boxTop.Parent then DrawLine(d.boxTop,mnX,mnY,mxX,mnY,bk) end
						if d.boxBot and d.boxBot.Parent then DrawLine(d.boxBot,mnX,mxY,mxX,mxY,bk) end
						if d.boxLeft and d.boxLeft.Parent then d.boxLeft.Size=UDim2.new(0,bk,0,math.max(1,mxY-mnY)); d.boxLeft.Position=UDim2.new(0,mnX-bk/2,0,mnY); d.boxLeft.Visible=true end
						if d.boxRight and d.boxRight.Parent then d.boxRight.Size=UDim2.new(0,bk,0,math.max(1,mxY-mnY)); d.boxRight.Position=UDim2.new(0,mxX-bk/2,0,mnY); d.boxRight.Visible=true end
						for _,bf in ipairs({d.boxTop,d.boxBot,d.boxLeft,d.boxRight}) do if bf and bf.Parent then bf.BackgroundColor3=Config.Esp.BoxColor end end
					else HideF(d.boxTop);HideF(d.boxBot);HideF(d.boxLeft);HideF(d.boxRight) end
					if Config.Esp.Tracers and hrp then
						local origin=Config.Esp.TracerOrigin=="Bottom" and Vector2.new(vp.X/2,vp.Y) or Config.Esp.TracerOrigin=="Center" and Vector2.new(vp.X/2,vp.Y/2) or Vector2.new(Mouse.X,Mouse.Y)
						local tsc,tdepth,ton=W2V(hrp.Position)
						if ton and tdepth>0 and d.tracer and d.tracer.Parent then DrawLine(d.tracer,origin.X,origin.Y,tsc.X,tsc.Y,Config.Esp.TracerThick); d.tracer.BackgroundColor3=nameColor
						else HideF(d.tracer) end
					else HideF(d.tracer) end
					if Config.Esp.Distance and myHRP and d.dLbl and d.dLbl.Parent then
						local dist=math.floor((hrp.Position-myHRP.Position).Magnitude)
						d.dLbl.Text=dist.."m"; d.dLbl.TextSize=math.max(8,Config.Esp.NameSize-2); d.dLbl.TextColor3=nameColor
						d.dLbl.Size=UDim2.new(0,60,0,13); d.dLbl.Position=UDim2.new(0,(mnX+mxX)/2-30,0,mxY+2); d.dLbl.Visible=true
					else HideF(d.dLbl) end
				else HideF(d.boxTop);HideF(d.boxBot);HideF(d.boxLeft);HideF(d.boxRight);HideF(d.tracer);HideF(d.dLbl) end
				if Config.Esp.Skeleton then
					local BONES={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}}
					if not d.bones then d.bones={} end
					for i,pr in ipairs(BONES) do
						local p1=char:FindFirstChild(pr[1]); local p2=char:FindFirstChild(pr[2])
						if p1 and p2 then
							if not d.bones[i] then d.bones[i]=MakeLine(); table.insert(d.objects,d.bones[i]) end
							local s1,_,o1=W2V(p1.Position); local s2,_,o2=W2V(p2.Position)
							if o1 and o2 and d.bones[i] and d.bones[i].Parent then DrawLine(d.bones[i],s1.X,s1.Y,s2.X,s2.Y,1); d.bones[i].BackgroundColor3=nameColor
							else HideF(d.bones[i]) end
						end
					end
				else
					if d.bones then for _,b in ipairs(d.bones) do pcall(function() if b and b.Parent then b:Destroy() end end) end; d.bones=nil end
				end
			else
				HideF(d.boxTop);HideF(d.boxBot);HideF(d.boxLeft);HideF(d.boxRight);HideF(d.tracer);HideF(d.dLbl)
				if d.bones then for _,b in ipairs(d.bones) do HideF(b) end end
			end
		end
	end)

	table.insert(connections,Players.PlayerAdded:Connect(SetupRecord))
	table.insert(connections,Players.PlayerRemoving:Connect(DestroyRecord))
	for _,p in ipairs(Players:GetPlayers()) do if p~=LP then SetupRecord(p) end end

	addCleanup(function()
		stepConn:Disconnect()
		for _,conn in ipairs(connections) do conn:Disconnect() end
		local pl={}; for p in pairs(records) do table.insert(pl,p) end
		for _,p in ipairs(pl) do DestroyRecord(p) end
	end)
end

-- ─────────────────────────────────────────────
-- HIT FX
-- ─────────────────────────────────────────────
local function startHitFx()
	local HitBoxes={}
	local connections={}

	local function FlashHit(char)
		if not Config.Hit.Enabled then return end
		if not char or not char.Parent then return end
		if HitBoxes[char] then HitBoxes[char]:Destroy(); HitBoxes[char]=nil end
		local box=Instance.new("SelectionBox")
		box.Adornee=char; box.Color3=Config.Hit.Color; box.SurfaceColor3=Config.Hit.Color
		box.LineThickness=0.06; box.SurfaceTransparency=math.max(0,math.min(1,Config.Hit.FillAlpha)); box.Parent=Workspace
		HitBoxes[char]=box
		local dur=Config.Hit.Duration; local steps=20; local dt=dur/steps
		local startThick=0.06; local startSurf=math.max(0,math.min(1,Config.Hit.FillAlpha))
		task.spawn(function()
			for i=1,steps do
				task.wait(dt)
				if not box or not box.Parent then return end
				if HitBoxes[char]~=box then return end
				local t=i/steps; box.LineThickness=startThick*(1-t); box.SurfaceTransparency=math.min(1,startSurf+(1-startSurf)*t)
			end
			if HitBoxes[char]==box then box:Destroy(); HitBoxes[char]=nil end
		end)
	end

	local function HookPlayer(player)
		local function OnChar(char)
			local hum=char:WaitForChild("Humanoid",5); if not hum then return end
			local prev=hum.Health
			local hConn=hum.HealthChanged:Connect(function(hp) if hp<prev then FlashHit(char) end; prev=hp end)
			local dConn=hum.Died:Connect(function() if HitBoxes[char] then HitBoxes[char]:Destroy(); HitBoxes[char]=nil end; hConn:Disconnect() end)
			char.AncestryChanged:Connect(function() if not char.Parent then if HitBoxes[char] then HitBoxes[char]:Destroy(); HitBoxes[char]=nil end; hConn:Disconnect(); dConn:Disconnect() end end)
		end
		if player.Character then task.spawn(OnChar,player.Character) end
		player.CharacterAdded:Connect(function(c) task.spawn(OnChar,c) end)
	end

	table.insert(connections,Players.PlayerAdded:Connect(HookPlayer))
	for _,p in ipairs(Players:GetPlayers()) do HookPlayer(p) end

	addCleanup(function()
		for _,conn in ipairs(connections) do conn:Disconnect() end
		for _,box in pairs(HitBoxes) do pcall(function() box:Destroy() end) end
		table.clear(HitBoxes)
	end)
end

-- ─────────────────────────────────────────────
-- HITBOX PREVIEW
-- ─────────────────────────────────────────────
local function startHitbox()
	local HBParts={}
	local stepConn

	local function RebuildHB(char)
		if HBParts[char] then HBParts[char]:Destroy(); HBParts[char]=nil end
		if not Config.Hitbox.Enabled then return end
		if not char or not char.Parent then return end
		local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
		local vis=Instance.new("SelectionBox"); vis.Adornee=hrp; vis.Color3=Palette.Bright
		vis.SurfaceColor3=Palette.Bright; vis.SurfaceTransparency=0.75; vis.LineThickness=0.04; vis.Parent=Workspace
		HBParts[char]=vis
	end

	stepConn=RunService.Heartbeat:Connect(function()
		if not Config.Hitbox.Enabled then
			for char,vis in pairs(HBParts) do if vis and vis.Parent then vis:Destroy() end; HBParts[char]=nil end
			return
		end
		for _,player in ipairs(Players:GetPlayers()) do
			if player~=LP then
				local char=player.Character
				if char and not HBParts[char] then RebuildHB(char) end
				if char and HBParts[char] then
					local hrp=char:FindFirstChild("HumanoidRootPart")
					if not hrp then HBParts[char]:Destroy(); HBParts[char]=nil end
				end
			end
		end
		for char,vis in pairs(HBParts) do
			if not char.Parent then if vis and vis.Parent then vis:Destroy() end; HBParts[char]=nil end
		end
	end)

	addCleanup(function()
		stepConn:Disconnect()
		for _,vis in pairs(HBParts) do pcall(function() vis:Destroy() end) end
		table.clear(HBParts)
	end)
end

-- ─────────────────────────────────────────────
-- CAMLOCK
-- ─────────────────────────────────────────────
local function startCamlock(camPanel)
	local stepName="EzClientCamlock"
	local bound=false
	local connections={}
	local TargetLabel=camPanel and camPanel:FindFirstChild("TargetLabel",true) or nil

	local function localAlive()
		local c=LP.Character; local h=c and c:FindFirstChildOfClass("Humanoid"); return h~=nil and h.Health>0
	end
	local function validHead(other)
		if not other or other==LP then return nil end
		local char=other.Character; if not char then return nil end
		local hum=char:FindFirstChildOfClass("Humanoid"); local head=char:FindFirstChild("Head")
		if not hum or hum.Health<=0 or not head or not head:IsA("BasePart") then return nil end
		return head
	end
	local function unlock()
		if bound then bound=false; RunService:UnbindFromRenderStep(stepName) end
		setLock(nil)
		if TargetLabel then TargetLabel.Text="No target"; TargetLabel.TextColor3=Palette.TextMid end
	end
	local function step(dt)
		local cam=Workspace.CurrentCamera
		local head=validHead(lockTarget)
		if not cam or not head or not localAlive() then unlock(); return end
		local pos=cam.CFrame.Position
		local offset=head.Position-pos; local dist=offset.Magnitude
		if dist<0.5 or math.abs(offset.Y/dist)>0.999 then return end
		local desired=CFrame.lookAt(pos,head.Position)
		local alpha=1-math.exp(-Config.Cam.Smoothing*Config.Cam.Sensitivity*60*dt)
		cam.CFrame=cam.CFrame:Lerp(desired,math.clamp(alpha,0.01,1))
		if TargetLabel then TargetLabel.Text="→ "..lockTarget.Name; TargetLabel.TextColor3=Config.Esp.TargetColor end
	end
	local function pickTarget()
		local cam=Workspace.CurrentCamera; if not cam or not localAlive() then return nil end
		local loc=UserInputService:GetMouseLocation()
		local tolerance=Config.Cam.FOVRadius*math.max(cam.ViewportSize.Y/1080,0.75)
		local best,bestDist=nil,tolerance
		for _,other in ipairs(Players:GetPlayers()) do
			local head=validHead(other)
			if head then
				local sc,depth,on=W2V(head.Position)
				if on and depth>0 and depth<=Config.Cam.MaxDist then
					local d2=(Vector2.new(sc.X,sc.Y)-loc).Magnitude
					if d2<=bestDist then best=other; bestDist=d2 end
				end
			end
		end
		return best
	end
	table.insert(connections,UserInputService.InputBegan:Connect(function(i,processed)
		if processed then return end
		if type(Config.Cam.Key)~="userdata" or i.KeyCode~=Config.Cam.Key then return end
		if not Config.Cam.Enabled then return end
		if lockTarget then unlock(); return end
		local found=pickTarget()
		if found then
			setLock(found)
			if not bound then bound=true; RunService:BindToRenderStep(stepName,Enum.RenderPriority.Camera.Value+1,step) end
		end
	end))
	table.insert(connections,Players.PlayerRemoving:Connect(function(other) if other==lockTarget then unlock() end end))
	table.insert(connections,LP.CharacterAdded:Connect(unlock))
	addCleanup(function()
		unlock()
		for _,conn in ipairs(connections) do conn:Disconnect() end
	end)
end

-- ─────────────────────────────────────────────
-- BOOTSTRAP
-- ─────────────────────────────────────────────
local SG, ESPLayer, UpdateHUD, UpdateFOV = startUI()

startEsp(ESPLayer)
startHitFx()
startHitbox()
startCamlock(SG and SG:FindFirstChild("Win",true) and SG.Win:FindFirstChild("WinClip",true) and SG.Win.WinClip:FindFirstChild("Camlock_p",true) or nil)

-- render HUD + FOV every frame
local frameConn=RunService.RenderStepped:Connect(function()
	if UpdateHUD then UpdateHUD() end
	if UpdateFOV then UpdateFOV() end
end)
addCleanup(function() frameConn:Disconnect() end)

-- unload key
local unloaded=false
local function unload()
	if unloaded then return end; unloaded=true
	for i=#cleanupTasks,1,-1 do pcall(cleanupTasks[i]) end
	table.clear(cleanupTasks)
	if env.EzClientUnload==unload then env.EzClientUnload=nil end
end
env.EzClientUnload=unload

local unloadConn
unloadConn=UserInputService.InputBegan:Connect(function(i,gpe)
	if not gpe and type(Config.UnloadKey)=="userdata" and i.KeyCode==Config.UnloadKey then
		unloadConn:Disconnect(); unload()
	end
end)
addCleanup(function() unloadConn:Disconnect() end)
