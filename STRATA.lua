--[[
    S T R A T A   ·  crystal glass UI
    ------------------------------------------------------------------
    local STRATA = loadstring(game:HttpGet("https://raw.githubusercontent.com/n1xvare/STARA-UI/main/STRATA.lua"))()
    local Window = STRATA:CreateWindow({ ToggleKey = Enum.KeyCode.RightShift })
    Crystal frames are pre-rendered PNGs (assets/) loaded from GitHub via getcustomasset.
]]

local STRATA = { Version = "1.1.0", Flags = {}, Options = {}, _Hooks = {} }

------------------------------------------------------------------------ services
local cloneref = cloneref or function(x) return x end
local function Svc(n) return cloneref(game:GetService(n)) end
local Players, TweenService, UserInputService = Svc("Players"), Svc("TweenService"), Svc("UserInputService")
local RunService, TextService, HttpService = Svc("RunService"), Svc("TextService"), Svc("HttpService")
local Lighting, CoreGui = Svc("Lighting"), Svc("CoreGui")
local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------------------ theme
local rgb = Color3.fromRGB
local Theme = {
    Mode = "Glass",                       -- "Glass" (clear, blurred) or "Dark"
    Accent = nil,                         -- nil = silver crystal, or any Color3
    Silver = rgb(226, 229, 236),
    Text = rgb(244, 245, 248),
    Sub = rgb(186, 189, 196),
}
STRATA.Theme = Theme
local function Accent() return Theme.Accent or Theme.Silver end
local function Dark() return Theme.Mode == "Dark" end
local function OnTheme(fn) table.insert(STRATA._Hooks, fn); fn() end

local FONT = "rbxasset://fonts/families/BuilderSans.json"
local FW = Enum.FontWeight

------------------------------------------------------------------------ helpers
local function New(c, p, kids)
    local o = Instance.new(c)
    local parent
    if p then for k, v in pairs(p) do if k == "Parent" then parent = v else o[k] = v end end end
    if kids then for _, k in ipairs(kids) do k.Parent = o end end
    if parent then o.Parent = parent end
    return o
end
local function Tween(o, t, props, style, dir, delay)
    local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out, 0, false, delay or 0), props)
    tw:Play()
    return tw
end
local function Corner(p, r) return New("UICorner", { CornerRadius = UDim.new(0, r), Parent = p }) end
local function Text(parent, txt, size, color, weight, props)
    local l = New("TextLabel", { BackgroundTransparency = 1, FontFace = Font.new(FONT, weight or FW.Medium), Text = txt or "", TextSize = size,
        TextColor3 = color or Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = parent })
    if props then for k, v in pairs(props) do l[k] = v end end
    return l
end
local function Btn(parent, props)
    local b = New("TextButton", { BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = parent })
    if props then for k, v in pairs(props) do b[k] = v end end
    return b
end
local function Measure(txt, size, bold)
    local ok, v = pcall(function()
        local p = Instance.new("GetTextBoundsParams")
        p.Text, p.Size, p.Width, p.Font = txt, size, 1e4, Font.new(FONT, bold and FW.Bold or FW.SemiBold)
        return TextService:GetTextBoundsAsync(p)
    end)
    if ok and typeof(v) == "Vector2" then return v end
    ok, v = pcall(function() return TextService:GetTextSize(txt, size, bold and Enum.Font.ArialBold or Enum.Font.Arial, Vector2.new(1e4, 1e4)) end)
    return ok and v or Vector2.new(#txt * size * 0.54, size)
end
local function SafeCall(fn, ...)
    if not fn then return end
    local a = table.pack(...)
    task.spawn(function() local ok, e = pcall(fn, table.unpack(a, 1, a.n)); if not ok then warn("[STRATA] " .. tostring(e)) end end)
end
local function IsClick(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function IsMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end
local function Round(n, s) s = s or 1; return math.floor(n / s + 0.5) * s end

------------------------------------------------------------------------ assets
local Assets = { BaseURL = "https://raw.githubusercontent.com/n1xvare/STARA-UI/main/assets/", Folder = "STRATA", Version = "2", Cache = {} }
STRATA.Assets = Assets
local function Asset(name)
    if Assets.Cache[name] then return Assets.Cache[name] end
    local gca = getcustomasset or getsynasset
    if not (writefile and isfile and isfolder and makefolder and gca) then Assets.Cache[name] = ""; return "" end
    local dir = Assets.Folder .. "/v" .. Assets.Version
    local path = dir .. "/" .. name
    local ok = pcall(function()
        if not isfolder(Assets.Folder) then makefolder(Assets.Folder) end
        if not isfolder(dir) then makefolder(dir) end
        if not isfile(path) then
            local data = game:HttpGet(Assets.BaseURL .. name)
            if not data or #data < 64 then error("download failed") end
            writefile(path, data)
        end
    end)
    local id = ""
    if ok then local ok2, r = pcall(gca, path); if ok2 then id = r end end
    Assets.Cache[name] = id
    return id
end
local PRELOAD = { "window_rim.png", "panel_rim.png", "panel_fill.png", "ring.png", "field_rim.png", "pill_rim.png", "logo_silver.png", "logo_white.png", "icons.png" }
for _, g in ipairs({ "tab", "tag", "tile", "check", "knob" }) do
    for _, part in ipairs({ "gem", "bevel", "hl", "rim" }) do table.insert(PRELOAD, g .. "_" .. part .. ".png") end
end

-- 9-slice image helper
local function Slice(parent, name, sliceRect, props)
    local i = New("ImageLabel", { BackgroundTransparency = 1, Image = Asset(name), ScaleType = Enum.ScaleType.Slice, SliceCenter = sliceRect, Parent = parent })
    if props then for k, v in pairs(props) do i[k] = v end end
    return i
end
local S_WINDOW, S_PANEL, S_TAB = Rect.new(24, 24, 104, 104), Rect.new(14, 14, 82, 82), Rect.new(16, 12, 100, 23)
local S_TAG, S_FIELD, S_PILL = Rect.new(42, 1, 140, 28), Rect.new(9, 9, 31, 15), Rect.new(14, 13, 46, 15)

-- faceted gem = 4 stacked layers rendered from the same polygon:
--   gem   grayscale facets (tinted: accent / dark / silver)
--   bevel white glass facets (shown on dark gems -> clear crystal edges)
--   hl    gloss band, lit edge lines, star glints (never tinted)
--   rim   chrome edge with rainbow dispersion (never tinted)
local GEM_PARTS = { "gem", "bevel", "hl", "rim" }
local function Gem(parent, name, slice, props)
    local f = New("Frame", { BackgroundTransparency = 1, Parent = parent })
    if props then for k, v in pairs(props) do f[k] = v end end
    local g = { Root = f }
    for _, part in ipairs(GEM_PARTS) do
        local i = New("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = Asset(name .. "_" .. part .. ".png"), ZIndex = f.ZIndex, Parent = f })
        if slice then i.ScaleType = Enum.ScaleType.Slice; i.SliceCenter = slice end
        g[part] = i
    end
    return g
end
local function GemDark() return Theme.Mode == "Dark" and rgb(6, 6, 8) or rgb(14, 15, 18) end
-- state: "on" (accent gem), "off" (dark crystal), "hover" (dark crystal, brighter edges); soft = translucent silver when no accent
local function GemLook(g, state, instant, soft)
    local on = state == "on"
    local gemT
    if on then gemT = Theme.Accent and 0 or (soft and 0.6 or 0.5)
    else gemT = Theme.Mode == "Dark" and 0.04 or 0.3 end
    local props = {
        gem = { ImageColor3 = on and (Theme.Accent or Theme.Silver) or GemDark(), ImageTransparency = gemT },
        bevel = { ImageTransparency = on and 1 or (state == "hover" and 0.15 or 0.38) },
        hl = { ImageTransparency = on and 0 or 0.45 },
        rim = { ImageColor3 = on and rgb(255, 255, 255) or rgb(132, 136, 146) },
    }
    for k, pr in pairs(props) do
        if instant then for a, b in pairs(pr) do g[k][a] = b end else Tween(g[k], 0.3, pr) end
    end
end

local ICELL = 64
local IconMap = {["crosshair"]={0,0}, ["pointer"]={1,0}, ["filter"]={2,0}, ["eye"]={3,0}, ["run"]={4,0}, ["sliders"]={5,0}, ["configs"]={6,0}, ["moon"]={7,0}, ["sun"]={0,1}, ["chevron"]={1,1}, ["check"]={2,1}, ["user"]={3,1}, ["globe"]={4,1}, ["brush"]={5,1}, ["keyboard"]={6,1}, ["x"]={7,1}, ["shield"]={0,2}, ["bolt"]={1,2}, ["save"]={2,2}, ["folder"]={3,2}}
STRATA.Icons = IconMap
local function Icon(parent, name, size, color, props)
    local i = New("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), ImageColor3 = color or Theme.Text, ScaleType = Enum.ScaleType.Fit, Parent = parent })
    local c = IconMap[name]
    if c then i.Image = Asset("icons.png"); i.ImageRectSize = Vector2.new(ICELL, ICELL); i.ImageRectOffset = Vector2.new(c[1] * ICELL, c[2] * ICELL)
    else i.Image = name and Asset(name) or "" end
    if props then for k, v in pairs(props) do i[k] = v end end
    return i
end

------------------------------------------------------------------------ acrylic blur (glass plane + DOF, ScreenPointToRay = AbsolutePosition space)
local Acrylic = {}
Acrylic.__index = Acrylic
function Acrylic.new(frame)
    local self = setmetatable({ Frame = frame, Enabled = true }, Acrylic)
    self.DOF = New("DepthOfFieldEffect", { Name = "STRATA_Blur", FarIntensity = 0, FocusDistance = 51.6, InFocusRadius = 50, NearIntensity = 1, Parent = Lighting })
    local p = Instance.new("Part")
    p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false; p.Locked = true
    p.Material = Enum.Material.Glass; p.Transparency = 0.98; p.Color = Color3.new(0, 0, 0); p.Size = Vector3.new(1, 1, 0)
    p.Parent = workspace.CurrentCamera
    self.Part = p
    self.Mesh = New("SpecialMesh", { MeshType = Enum.MeshType.Brick, Offset = Vector3.new(0, 0, -0.000001), Parent = p })
    self.Bind = "STRATA_Acrylic_" .. tostring(math.random(1, 1e6))
    local ok = pcall(function() RunService:BindToRenderStep(self.Bind, ((Enum.RenderPriority.Camera.Value) or 200) + 1, function() self:Update() end) end)
    if not ok then self.Bind = nil; self.Conn = RunService.RenderStepped:Connect(function() self:Update() end) end
    return self
end
function Acrylic:SetEnabled(v) self.Enabled = v; self.DOF.Enabled = v; self.Part.Transparency = v and 0.98 or 1 end
function Acrylic:Update()
    if not self.Enabled then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    if self.Part.Parent ~= cam then self.Part.Parent = cam end
    local pos, size = self.Frame.AbsolutePosition, self.Frame.AbsoluteSize
    if size.X < 8 then return end
    pos, size = pos + Vector2.new(8, 8), size - Vector2.new(16, 16)
    local function W(x, y) local r = cam:ScreenPointToRay(x, y, 0); return r.Origin + r.Direction * 0.001 end
    local tl, tr, br = W(pos.X, pos.Y), W(pos.X + size.X, pos.Y), W(pos.X + size.X, pos.Y + size.Y)
    local cf = cam.CFrame
    self.Part.CFrame = CFrame.fromMatrix((tl + br) / 2, cf.XVector, cf.YVector, cf.ZVector)
    self.Mesh.Scale = Vector3.new((tr - tl).Magnitude, (tr - br).Magnitude, 0)
end
function Acrylic:Destroy()
    if self.Bind then pcall(function() RunService:UnbindFromRenderStep(self.Bind) end) end
    if self.Conn then self.Conn:Disconnect() end
    self.Part:Destroy(); self.DOF:Destroy()
end

------------------------------------------------------------------------ layout (measured from the reference, 840x550)
local L = {
    W = 840, H = 550,
    HeaderH = 58,
    TabX = 214, TabY = 13, TabW = 116, TabH = 35, TabGap = 9,
    ArcCX = -177, ArcCY = 297, TileR = 258, TileStep = 18, TileW = 86, TileH = 90,
    LeftX = 141, LeftW = 335, RightX = 489, RightW = 329, ColTop = 73, ColBottom = 517,
    RowPad = 23, RowRight = 18,
}
STRATA.Layout = L

------------------------------------------------------------------------ classes
local Window = {}; Window.__index = Window
local Page = {}; Page.__index = Page
local Tab = {}; Tab.__index = Tab
local Section = {}; Section.__index = Section

local function GuiParent(g)
    pcall(function() if protectgui then protectgui(g) elseif syn and syn.protect_gui then syn.protect_gui(g) end end)
    local ok = pcall(function() g.Parent = (gethui and gethui()) or CoreGui end)
    if not ok or not g.Parent then g.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end

function STRATA:CreateWindow(o)
    o = o or {}
    local self = setmetatable({ Pages = {}, Connections = {} }, Window)
    STRATA._Window = self
    self.ToggleKey = o.ToggleKey or Enum.KeyCode.RightShift
    if o.Accent then Theme.Accent = o.Accent end
    if o.Mode then Theme.Mode = o.Mode end
    if o.AssetsURL then Assets.BaseURL = o.AssetsURL end
    for _, n in ipairs(PRELOAD) do task.spawn(Asset, n) end
    local t0 = os.clock()
    while os.clock() - t0 < 6 do
        local done = true
        for _, n in ipairs(PRELOAD) do if Assets.Cache[n] == nil then done = false end end
        if done then break end
        task.wait()
    end

    local gui = New("ScreenGui", { Name = "STRATA_" .. string.sub(HttpService:GenerateGUID(false), 1, 6), ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 9999 })
    GuiParent(gui)
    self.Gui = gui
    local holder = New("Frame", { Name = "Holder", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(L.W, L.H),
        BackgroundTransparency = 1, Parent = gui })
    self.Holder = holder
    self.Scale = New("UIScale", { Parent = holder })
    local main = New("CanvasGroup", { Name = "Main", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = holder })
    Corner(main, 16)
    self.Main = main

    -- window body
    self.Body = New("Frame", { Name = "Body", Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -8), BorderSizePixel = 0, Parent = main })
    Corner(self.Body, 13)
    OnTheme(function()
        Tween(self.Body, 0.35, { BackgroundColor3 = Dark() and rgb(5, 5, 7) or rgb(22, 23, 26), BackgroundTransparency = Dark() and 0.04 or 0.62 })
    end)
    -- header band
    self.HeaderBand = New("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, L.HeaderH), BackgroundColor3 = rgb(0, 0, 0), BorderSizePixel = 0, Parent = main })
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.55, 0.85), Parent = self.HeaderBand })
    New("Frame", { Position = UDim2.fromOffset(8, L.HeaderH), Size = UDim2.new(1, -16, 0, 1), BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.82,
        BorderSizePixel = 0, Parent = main })

    -- logo (silver / tinted)
    self.LogoSilver = New("ImageLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(21, 14), Size = UDim2.fromOffset(170, 30), Image = Asset("logo_silver.png"), Parent = main })
    self.LogoTint = New("ImageLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(21, 14), Size = UDim2.fromOffset(170, 30), Image = Asset("logo_white.png"), ImageTransparency = 1, Parent = main })
    OnTheme(function()
        local c = Theme.Accent
        Tween(self.LogoSilver, 0.35, { ImageTransparency = c and 1 or 0 })
        Tween(self.LogoTint, 0.35, { ImageTransparency = c and 0 or 1, ImageColor3 = c or Theme.Silver })
    end)
    New("Frame", { Position = UDim2.fromOffset(199, 14), Size = UDim2.fromOffset(1, 34), BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = main })

    self:_Drag() -- drag zone first, so tabs / buttons created later sit above it
    self.TabBar = New("Frame", { Name = "Tabs", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = main })
    self:_BuildTopRight()
    self:_BuildWheel()
    self.Content = New("Frame", { Name = "Content", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = main })

    -- crystal window frame + shimmer sweep
    self.Frame = Slice(main, "window_rim.png", S_WINDOW, { Name = "Crystal", Size = UDim2.fromScale(1, 1), ZIndex = 5 })
    self.Shine = Slice(main, "window_rim.png", S_WINDOW, { Name = "Shine", Size = UDim2.fromScale(1, 1), ZIndex = 6, ImageColor3 = rgb(255, 255, 255) })
    self.ShineGrad = New("UIGradient", { Rotation = 25, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 1),
        NumberSequenceKeypoint.new(0.5, 0.1), NumberSequenceKeypoint.new(0.58, 1), NumberSequenceKeypoint.new(1, 1) }), Offset = Vector2.new(-1, 0), Parent = self.Shine })

    -- overlay for popups
    self.Overlay = New("Frame", { Name = "Overlay", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = gui })
    self.Catcher = Btn(self.Overlay, { Size = UDim2.fromScale(1, 1), Visible = false })
    self.Catcher.MouseButton1Down:Connect(function() self:ClosePopups() end)

    if o.Blur ~= false then
        local ok, a = pcall(Acrylic.new, main)
        if ok then self.Acrylic = a end
    end

    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(i, gp)
        if not gp and i.KeyCode == self.ToggleKey then self:Toggle() end
    end))
    -- periodic crystal shimmer
    task.spawn(function()
        while self.Gui.Parent do
            self:Shimmer()
            task.wait(5)
        end
    end)
    local cam = workspace.CurrentCamera
    if o.Scale then self.BaseScale = o.Scale
    elseif cam then
        local vp = cam.ViewportSize
        local fit = math.min(1, (vp.X - 30) / L.W, (vp.Y - 30) / L.H)
        if fit < 1 and fit > 0.3 then self.BaseScale = fit end
    end
    -- open animation
    self.Visible = true
    main.GroupTransparency = 1
    self.Scale.Scale = (self.BaseScale or 1) * 0.94
    task.defer(function()
        Tween(main, 0.4, { GroupTransparency = 0 })
        Tween(self.Scale, 0.55, { Scale = self.BaseScale or 1 }, Enum.EasingStyle.Back)
    end)
    return self
end

function Window:Shimmer()
    self.ShineGrad.Offset = Vector2.new(-1, 0)
    Tween(self.ShineGrad, 1.4, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
end

function Window:_Drag()
    local drag, start, startPos
    local zone = New("Frame", { Name = "DragZone", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, L.HeaderH), Active = true, Parent = self.Main })
    zone.InputBegan:Connect(function(i) if IsClick(i) then drag, start, startPos = true, i.Position, self.Holder.Position; self:ClosePopups() end end)
    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(i)
        if drag and IsMove(i) then
            local d = i.Position - start
            Tween(self.Holder, 0.12, { Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) })
        end
    end))
    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(i) if IsClick(i) then drag = false end end))
    zone.ZIndex = 1
end

------------------------------------------------------------------------ top right: accent picker circle + theme switch
function Window:_BuildTopRight()
    local main = self.Main
    local cb = New("TextButton", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(731, 30), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = rgb(0, 0, 0),
        BackgroundTransparency = 0.4, Text = "", AutoButtonColor = false, ZIndex = 3, Parent = main })
    Corner(cb, 14)
    Slice(cb, "pill_rim.png", S_PILL, { Size = UDim2.fromScale(1, 1), ZIndex = 4 })
    local dot = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 18), ZIndex = 4, Parent = cb })
    Corner(dot, 9)
    OnTheme(function() Tween(dot, 0.3, { BackgroundColor3 = Theme.Accent or rgb(255, 255, 255) }) end)
    cb.MouseButton1Click:Connect(function() self:_AccentPopup(cb) end)

    local pill = New("Frame", { Position = UDim2.fromOffset(758, 16), Size = UDim2.fromOffset(58, 27), BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 0.45, ZIndex = 3, Parent = main })
    Corner(pill, 13)
    Slice(pill, "pill_rim.png", S_PILL, { Size = UDim2.fromScale(1, 1), ZIndex = 4 })
    local knob = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(21, 21), BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.8, ZIndex = 4, Parent = pill })
    Corner(knob, 11)
    local moon = Icon(pill, "moon", 12, Theme.Text, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(16, 13.5), ZIndex = 5 })
    local sun = Icon(pill, "sun", 13, Theme.Text, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(42, 13.5), ZIndex = 5 })
    OnTheme(function()
        local dark = Dark()
        Tween(knob, 0.35, { Position = UDim2.fromOffset(dark and 16 or 42, 13.5), BackgroundColor3 = Theme.Accent or rgb(255, 255, 255), BackgroundTransparency = Theme.Accent and 0.55 or 0.8 })
        Tween(moon, 0.3, { ImageTransparency = dark and 0 or 0.55, ImageColor3 = dark and (Theme.Accent and Theme.Accent:Lerp(rgb(255, 255, 255), 0.4) or Theme.Text) or Theme.Text })
        Tween(sun, 0.3, { ImageTransparency = dark and 0.55 or 0 })
    end)
    local b = Btn(pill, { Size = UDim2.fromScale(1, 1), ZIndex = 6 })
    b.MouseButton1Click:Connect(function() STRATA:SetMode(Dark() and "Glass" or "Dark") end)
end

------------------------------------------------------------------------ wheel navigation (crystal arc + sector tiles)
function Window:_BuildWheel()
    local main = self.Main
    self.Wheel = New("Frame", { Name = "Wheel", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, Parent = main })
    New("ImageLabel", { Name = "Ring", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, L.ArcCY - 280), Size = UDim2.fromOffset(160, 560),
        Image = Asset("ring.png"), Parent = self.Wheel })
    self.WheelRot = New("NumberValue", { Value = 0 })
    self.WheelRot.Changed:Connect(function() self:_PlaceTiles() end)
end

function Window:_PlaceTiles()
    local span = L.TileStep * 5
    for i, p in ipairs(self.Pages) do
        local a = (i - 3) * L.TileStep + self.WheelRot.Value * L.TileStep
        a = ((a + span / 2) % span) - span / 2
        local rad = math.rad(a)
        local cx, cy = L.ArcCX + L.TileR * math.cos(rad), L.ArcCY + L.TileR * math.sin(rad)
        for _, l in pairs(p.Tile) do l.Position = UDim2.fromOffset(cx, cy); l.Rotation = a end
        p.TileLabel.Position = UDim2.fromOffset(cx, cy)
        p.TileFade = math.clamp((math.abs(a) - 37) / 8, 0, 1)
        self:_TileApply(p)
    end
end

-- one tile = dark crystal (bevel visible) <-> accent gem, blended by p.Act (0..1); active tile also grows out of the ring
function Window:_TileApply(p)
    local a, fade, hov = p.Act.Value, p.TileFade or 0, p.Hover and 1 or 0
    local function T(x) return math.max(fade, x) end
    local offT = Dark() and 0.04 or 0.3
    local onT = Theme.Accent and 0 or 0.5
    local g = p.Tile
    g.gem.ImageColor3 = GemDark():Lerp(Accent(), a)
    g.gem.ImageTransparency = T(offT + (onT - offT) * a)
    g.bevel.ImageTransparency = T(0.18 - 0.12 * hov + 0.82 * a)
    g.hl.ImageTransparency = T(0.45 * (1 - a))
    g.rim.ImageTransparency = fade
    g.rim.ImageColor3 = rgb(185, 189, 198):Lerp(rgb(255, 255, 255), a)
    local s = 1 + 0.1 * a
    for _, l in pairs(g) do l.Size = UDim2.fromOffset(L.TileW * s, L.TileH * s); l.ZIndex = a > 0.01 and 2 or 1 end
    p.TileLabel.GroupTransparency = fade
    p.TileText.TextColor3 = Theme.Text
    p.TileIcon.ImageColor3 = Theme.Text
end

function Window:_TileStyle(p, active, instant)
    p.Active = active
    if instant then p.Act.Value = active and 1 or 0 else Tween(p.Act, 0.45, { Value = active and 1 or 0 }, Enum.EasingStyle.Back) end
    self:_TileApply(p)
end

------------------------------------------------------------------------ pages / tabs
function Window:Page(o)
    o = o or {}
    local p = setmetatable({ Window = self, Title = o.Title or "Page", IconName = o.Icon or "crosshair", Tabs = {} }, Page)
    table.insert(self.Pages, p)
    p.Index = #self.Pages
    -- tile parts (back, fill, frame) + horizontal label
    p.Tile = {}
    for _, part in ipairs(GEM_PARTS) do
        p.Tile[part] = New("ImageLabel", { Name = "Tile_" .. part, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(L.TileW, L.TileH),
            Image = Asset("tile_" .. part .. ".png"), Parent = self.Wheel })
    end
    p.Act = New("NumberValue", { Value = 0 })
    p.Act.Changed:Connect(function() self:_TileApply(p) end)
    p.TileLabel = New("CanvasGroup", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(76, 44), ZIndex = 3, Parent = self.Wheel })
    p.TileIcon = Icon(p.TileLabel, p.IconName, 18, Theme.Text, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 1), ZIndex = 3 })
    p.TileText = Text(p.TileLabel, p.Title, 11, Theme.Text, FW.Bold, { Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3 })
    New("UIStroke", { Color = rgb(0, 0, 0), Transparency = 0.55, Thickness = 1, Parent = p.TileText })
    local hit = Btn(p.TileLabel, { Size = UDim2.fromScale(1, 1), ZIndex = 4 })
    hit.MouseButton1Click:Connect(function() self:SelectPage(p) end)
    hit.MouseEnter:Connect(function() p.Hover = true; self:_TileApply(p) end)
    hit.MouseLeave:Connect(function() p.Hover = false; self:_TileApply(p) end)
    OnTheme(function() self:_TileStyle(p, p.Active == true, true) end)
    -- this page's tab buttons (3 per page in the header)
    p.TabGroup = New("CanvasGroup", { Name = "Tabs_" .. p.Title, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = self.TabBar })
    self:_PlaceTiles()
    if not self.Current then self:SelectPage(p, true) end
    return p
end

function Page:Tab(o)
    if type(o) == "string" then o = { Title = o } end
    o = o or {}
    local w = self.Window
    local t = setmetatable({ Window = w, Page = self, Title = o.Title or "Tab", IconName = o.Icon or "crosshair", Sections = {} }, Tab)
    table.insert(self.Tabs, t)
    t.Index = #self.Tabs
    local x = L.TabX + (t.Index - 1) * (L.TabW + L.TabGap)
    local b = New("TextButton", { Position = UDim2.fromOffset(x, L.TabY), Size = UDim2.fromOffset(L.TabW, L.TabH), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
        ZIndex = 3, Parent = self.TabGroup })
    t.Gem = Gem(b, "tab", S_TAB, { Size = UDim2.fromScale(1, 1), ZIndex = 3 })
    local tw = Measure(t.Title, 13).X
    local ic = Icon(b, t.IconName, 14, Theme.Text, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.5, -(tw + 22) / 2, 0.5, 0), ZIndex = 5 })
    t.Label = Text(b, t.Title, 13, Theme.Text, FW.SemiBold, { Position = UDim2.new(0.5, -(tw + 22) / 2 + 22, 0, 0), Size = UDim2.new(0, tw + 4, 1, 0), ZIndex = 5 })
    New("UIStroke", { Color = rgb(0, 0, 0), Transparency = 0.6, Thickness = 1, Parent = t.Label })
    t.Button, t.IconImg = b, ic
    b.MouseButton1Click:Connect(function() self:SelectTab(t) end)
    b.MouseEnter:Connect(function() if self.CurrentTab ~= t then GemLook(t.Gem, "hover") end end)
    b.MouseLeave:Connect(function() if self.CurrentTab ~= t then GemLook(t.Gem, "off") end end)
    OnTheme(function() t:_Style(self.CurrentTab == t, true) end)
    -- content: two scrolling columns
    t.Root = New("CanvasGroup", { Name = "Tab_" .. self.Title .. "_" .. t.Title, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = w.Content })
    local function col(x, width)
        local s = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(x - 4, L.ColTop - 4), Size = UDim2.fromOffset(width + 8, L.ColBottom - L.ColTop + 8),
            CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = t.Root })
        s:GetPropertyChangedSignal("CanvasPosition"):Connect(function() w:ClosePopups() end)
        return s
    end
    t.Left, t.Right = col(L.LeftX, L.LeftW), col(L.RightX, L.RightW)
    if not self.CurrentTab then
        self.CurrentTab = t
        t:_Style(true, true)
        if w.Current == self then t:_Show(true) end
    end
    return t
end

function Tab:_Style(active, instant)
    GemLook(self.Gem, active and "on" or "off", instant)
    self.Label.TextColor3 = Theme.Text
    self.IconImg.ImageColor3 = Theme.Text
end

function Page:SelectTab(t, instant)
    local old = self.CurrentTab
    if old == t then return end
    self.CurrentTab = t
    if old then old:_Style(false) end
    t:_Style(true)
    if self.Window.Current == self then
        self.Window:ClosePopups()
        if old then
            local r = old.Root
            Tween(r, 0.15, { GroupTransparency = 1 })
            task.delay(0.15, function() if self.CurrentTab ~= old then r.Visible = false end end)
        end
        t:_Show(instant)
    end
end

function Tab:_Show(instant)
    local r = self.Root
    self:_Layout()
    r.Visible = true
    if instant then r.GroupTransparency = 0; r.Position = UDim2.fromOffset(0, 0) return end
    r.GroupTransparency = 1
    r.Position = UDim2.fromOffset(14, 0)
    Tween(r, 0.45, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, nil, nil, 0.08)
    -- sections cascade
    for i, s in ipairs(self.Sections) do
        s.Root.Position = UDim2.fromOffset(s.Root.Position.X.Offset, s.Y + 10)
        Tween(s.Root, 0.5, { Position = UDim2.fromOffset(s.Root.Position.X.Offset, s.Y) }, nil, nil, 0.06 * i)
    end
end

function Window:SelectPage(p, instant)
    if type(p) == "number" then p = self.Pages[p] end
    if not p or self.Current == p then return end
    self:ClosePopups()
    local old = self.Current
    self.Current = p
    if old then
        self:_TileStyle(old, false)
        local g = old.TabGroup
        Tween(g, 0.15, { GroupTransparency = 1 })
        task.delay(0.16, function() if self.Current ~= old then g.Visible = false end end)
        if old.CurrentTab then
            local r = old.CurrentTab.Root
            Tween(r, 0.15, { GroupTransparency = 1 })
            task.delay(0.16, function() if self.Current ~= old then r.Visible = false end end)
        end
    end
    self:_TileStyle(p, true, instant)
    -- wheel spins one full turn and settles
    if not instant then
        self.WheelRot.Value = -5
        Tween(self.WheelRot, 1.0, { Value = 0 }, Enum.EasingStyle.Quint)
    end
    p.TabGroup.Visible = true
    p.TabGroup.GroupTransparency = instant and 0 or 1
    if not instant then Tween(p.TabGroup, 0.35, { GroupTransparency = 0 }, nil, nil, 0.1) end
    if p.CurrentTab then
        if instant then p.CurrentTab:_Show(true) else task.delay(0.12, function() if self.Current == p then p.CurrentTab:_Show() end end) end
    end
    if not instant then self:Shimmer() end
end

------------------------------------------------------------------------ sections
function Tab:Section(o)
    if type(o) == "string" then o = { Title = o } end
    o = o or {}
    local w = self.Window
    local side = o.Side == "Right" and "Right" or "Left"
    local width = side == "Left" and L.LeftW or L.RightW
    local s = setmetatable({ Window = w, Tab = self, Title = o.Title or "Section", Side = side, Width = width, Rows = {}, H = 52 }, Section)
    table.insert(self.Sections, s)
    local parent = side == "Left" and self.Left or self.Right
    s.Root = New("Frame", { Name = "Section_" .. s.Title, BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(width, 100), Parent = parent })
    s.Fill = Slice(s.Root, "panel_fill.png", S_PANEL, { Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 1, -6), ImageColor3 = rgb(0, 0, 0) })
    -- header strip right of the tag: steel band + facet line (sits under the frame)
    s.Caption = o.Caps == false and s.Title or string.upper(s.Title)
    local tw = Measure(s.Caption, 14, true).X
    local tagW = math.max(150, tw + 80)
    local strip = New("Frame", { Name = "Strip", Position = UDim2.fromOffset(tagW - 24, 7), Size = UDim2.new(1, -(tagW - 24) - 3, 0, 22), BackgroundColor3 = rgb(52, 55, 62),
        BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = s.Root })
    New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.6, 0.55), NumberSequenceKeypoint.new(1, 0.35) }), Parent = strip })
    New("Frame", { Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = rgb(160, 166, 178), BackgroundTransparency = 0.55, BorderSizePixel = 0, Parent = strip })
    New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -62, 0.5, 0), Size = UDim2.fromOffset(62, 1), Rotation = -19, BackgroundColor3 = rgb(200, 205, 215),
        BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = strip })
    s.FrameImg = Slice(s.Root, "panel_rim.png", S_PANEL, { Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 1, -6), ZIndex = 2 })
    -- slanted gem tag
    s.Tag = Gem(s.Root, "tag", S_TAG, { Position = UDim2.fromOffset(1, 0), Size = UDim2.fromOffset(tagW, 29), ZIndex = 3 })
    s.TagText = Text(s.Root, s.Caption, 14, Theme.Text, FW.SemiBold, { Position = UDim2.fromOffset(26, 0), Size = UDim2.fromOffset(tagW - 40, 29), ZIndex = 5 })
    New("UIStroke", { Color = rgb(0, 0, 0), Transparency = 0.5, Thickness = 1, Parent = s.TagText })
    OnTheme(function()
        Tween(s.Fill, 0.35, { ImageTransparency = Dark() and 0.12 or 0.5 })
        GemLook(s.Tag, "on", false, true)
        s.TagText.TextColor3 = Theme.Text
    end)
    s.Body = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 10), ZIndex = 3, Parent = s.Root })
    self:_Layout()
    return s
end

function Tab:_Layout()
    for _, side in ipairs({ "Left", "Right" }) do
        local col = side == "Left" and self.Left or self.Right
        local y, last = 4, nil
        for _, s in ipairs(self.Sections) do
            if s.Side == side then
                s.Y = y
                s.Root.Position = UDim2.fromOffset(4, y)
                s.Root.Size = UDim2.fromOffset(s.Width, s.H)
                y = y + s.H + 15
                last = s
            end
        end
        -- the last section in a column stretches to the bottom (like the reference)
        local avail = L.ColBottom - L.ColTop
        if last and y - 15 < avail + 4 then
            last.Root.Size = UDim2.fromOffset(last.Width, avail - last.Y + 4)
            y = avail + 19
        end
        col.CanvasSize = UDim2.fromOffset(0, y - 11)
    end
end

function Section:_Row(h)
    local r = { Y = self.H - 52, H = h }
    r.Frame = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(L.RowPad, r.Y), Size = UDim2.new(1, -(L.RowPad + L.RowRight), 0, h), ZIndex = 3, Parent = self.Body })
    self.H = self.H + h
    table.insert(self.Rows, r)
    self.Tab:_Layout()
    return r
end

local function Register(el, flag, v) if flag then STRATA.Flags[flag] = v; STRATA.Options[flag] = el end end

-- glass checkbox
function Section:Toggle(o)
    o = o or {}
    local r = self:_Row(26)
    r.Value = o.Default == true
    Text(r.Frame, o.Title or "Toggle", 12, Theme.Text, FW.SemiBold, { Size = UDim2.new(1, -40, 1, 0), ZIndex = 3 })
    local box = New("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 2, 0.5, 0), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, ZIndex = 3, Parent = r.Frame })
    local gem = Gem(box, "check", nil, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 22), ZIndex = 4 })
    local sc = New("UIScale", { Parent = gem.Root })
    local tick = Icon(box, "check", 13, rgb(255, 255, 255), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ImageTransparency = r.Value and 0 or 1, ZIndex = 6 })
    local function style(instant)
        GemLook(gem, r.Value and "on" or "off", instant)
        tick.ImageColor3 = rgb(255, 255, 255)
    end
    OnTheme(function() style(true) end)
    function r:Set(v, silent)
        r.Value = v == true
        style(false)
        Tween(tick, 0.2, { ImageTransparency = r.Value and 0 or 1 })
        sc.Scale = 0.6
        Tween(sc, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
        if o.Flag then STRATA.Flags[o.Flag] = r.Value end
        if not silent then SafeCall(o.Callback, r.Value) end
    end
    function r:Get() return r.Value end
    local b = Btn(r.Frame, { Size = UDim2.fromScale(1, 1), ZIndex = 7 })
    b.MouseButton1Click:Connect(function() r:Set(not r.Value) end)
    Register(r, o.Flag, r.Value)
    return r
end
Section.Checkbox = Section.Toggle

-- slider with oval glass knob
function Section:Slider(o)
    o = o or {}
    local r = self:_Row(39)
    local min, max, step = o.Min or 0, o.Max or 100, o.Increment or 1
    r.Value = math.clamp(o.Default or min, min, max)
    Text(r.Frame, o.Title or "Slider", 12, Theme.Text, FW.SemiBold, { Size = UDim2.new(1, -70, 0, 20), ZIndex = 3 })
    local val = Text(r.Frame, "", 11, Theme.Text, FW.Medium, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(80, 20),
        TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3 })
    local track = New("Frame", { Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.78, ZIndex = 3, Parent = r.Frame })
    Corner(track, 2)
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), ZIndex = 3, Parent = track })
    Corner(fill, 2)
    local glow = New("UIStroke", { Thickness = 1.5, Transparency = 0.6, Parent = fill })
    local kg = Gem(track, "knob", nil, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(23, 14), ZIndex = 4 })
    local knob = kg.Root
    OnTheme(function()
        local c = Accent()
        fill.BackgroundColor3 = c:Lerp(rgb(255, 255, 255), 0.15); glow.Color = c
        GemLook(kg, "on", true)
    end)
    local function fmt(v)
        if o.Format then return o.Format(v) end
        local s = step % 1 == 0 and tostring(math.floor(v + 0.5)) or string.format("%.1f", v)
        return s .. (o.Suffix or "")
    end
    function r:Set(v, silent, instant)
        v = math.clamp(Round(v, step), min, max)
        r.Value = v
        local a = max == min and 0 or (v - min) / (max - min)
        if instant then fill.Size = UDim2.fromScale(a, 1); knob.Position = UDim2.fromScale(a, 0.5)
        else Tween(fill, 0.15, { Size = UDim2.fromScale(a, 1) }); Tween(knob, 0.15, { Position = UDim2.fromScale(a, 0.5) }) end
        val.Text = fmt(v)
        if o.Flag then STRATA.Flags[o.Flag] = v end
        if not silent then SafeCall(o.Callback, v) end
    end
    function r:Get() return r.Value end
    local hit = Btn(r.Frame, { Position = UDim2.fromOffset(-6, 14), Size = UDim2.new(1, 12, 0, 22), ZIndex = 7 })
    local dragging = false
    local function upd(x) r:Set(min + (max - min) * math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)) end
    hit.InputBegan:Connect(function(i) if IsClick(i) then dragging = true; Tween(knob, 0.15, { Size = UDim2.fromOffset(27, 16) }); upd(i.Position.X) end end)
    table.insert(self.Window.Connections, UserInputService.InputChanged:Connect(function(i) if dragging and IsMove(i) then upd(i.Position.X) end end))
    table.insert(self.Window.Connections, UserInputService.InputEnded:Connect(function(i)
        if dragging and IsClick(i) then dragging = false; Tween(knob, 0.25, { Size = UDim2.fromOffset(23, 14) }, Enum.EasingStyle.Back) end
    end))
    r:Set(r.Value, true, true)
    Register(r, o.Flag, r.Value)
    return r
end

-- dark glass field (dropdown / keybind / color)
local function Field(parent, width, height, chevron)
    local f = New("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 2, 0.5, 0), Size = UDim2.fromOffset(width, height), BackgroundColor3 = rgb(0, 0, 0),
        BackgroundTransparency = 0.35, Text = "", AutoButtonColor = false, ZIndex = 3, Parent = parent })
    Corner(f, 6)
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.5) }), Parent = f })
    Slice(f, chevron == "pill" and "pill_rim.png" or "field_rim.png", chevron == "pill" and S_PILL or S_FIELD, { Size = UDim2.fromScale(1, 1), ZIndex = 5 })
    local t = Text(f, "", 10, Theme.Text, FW.Medium, { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, chevron == true and -34 or -20, 1, 0), ZIndex = 4,
        TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = chevron == "pill" and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left })
    local chev
    if chevron == true then
        New("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 3), Size = UDim2.new(0, 1, 1, -6), BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.75, ZIndex = 4, Parent = f })
        chev = Icon(f, "chevron", 11, Theme.Text, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -12, 0.5, 0), ZIndex = 4 })
    end
    f.MouseEnter:Connect(function() Tween(f, 0.15, { BackgroundTransparency = 0.15 }) end)
    f.MouseLeave:Connect(function() Tween(f, 0.15, { BackgroundTransparency = 0.35 }) end)
    return f, t, chev
end

local function OptText(x) return type(x) == "table" and (x.Text or x[1]) or tostring(x) end

function Section:Dropdown(o)
    o = o or {}
    local w = self.Window
    local r = self:_Row(27)
    local opts = o.Options or {}
    r.Multi = o.Multi
    if r.Multi then r.Value = {}; for _, v in ipairs(o.Default or {}) do r.Value[v] = true end else r.Value = o.Default or (opts[1] and OptText(opts[1])) or "" end
    Text(r.Frame, o.Title or "Dropdown", 12, Theme.Text, FW.SemiBold, { Size = UDim2.new(1, -130, 1, 0), ZIndex = 3 })
    local f, t, chev = Field(r.Frame, o.Width or 119, 21, true)
    function r:Get()
        if not r.Multi then return r.Value end
        local out = {}
        for _, x in ipairs(opts) do if r.Value[OptText(x)] then out[#out + 1] = OptText(x) end end
        return out
    end
    local function show() t.Text = r.Multi and (#r:Get() > 0 and table.concat(r:Get(), ", ") or "None") or r.Value end
    function r:Set(v, silent)
        if r.Multi then r.Value = {}; for _, x in ipairs(v or {}) do r.Value[x] = true end else r.Value = v end
        show()
        if r.Refresh then r.Refresh() end
        if o.Flag then STRATA.Flags[o.Flag] = r:Get() end
        if not silent then SafeCall(o.Callback, r:Get()) end
    end
    f.MouseButton1Click:Connect(function()
        if w.Popup and w.Popup.Owner == r then w:ClosePopups() return end
        local scale = w.Scale.Scale
        local ap, as = w:_Rel(f), f.AbsoluteSize
        local H = math.min(#opts, 7) * 22 + 8
        local pop = New("CanvasGroup", { Position = UDim2.fromOffset(ap.X, ap.Y + as.Y + 3 * scale), Size = UDim2.fromOffset(as.X / scale, 0), BackgroundColor3 = rgb(6, 6, 8),
            BackgroundTransparency = 0.05, GroupTransparency = 1, ZIndex = 5, Parent = w.Overlay })
        New("UIScale", { Scale = scale, Parent = pop })
        Corner(pop, 6)
        Slice(pop, "field_rim.png", S_FIELD, { Size = UDim2.fromScale(1, 1), ZIndex = 9 })
        local list = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 1, -8),
            CanvasSize = UDim2.fromOffset(0, #opts * 22), ScrollBarThickness = 0, ZIndex = 6, Parent = pop })
        local rows = {}
        for i, x in ipairs(opts) do
            local name = OptText(x)
            local row = Btn(list, { Position = UDim2.fromOffset(4, (i - 1) * 22), Size = UDim2.new(1, -8, 0, 20), BackgroundColor3 = Accent(), BackgroundTransparency = 1, ZIndex = 7 })
            Corner(row, 4)
            local lbl = Text(row, name, 10, Theme.Text, FW.Medium, { Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), ZIndex = 8 })
            rows[i] = { row = row, lbl = lbl, name = name }
            row.MouseEnter:Connect(function() if not (r.Multi and r.Value[name] or r.Value == name) then Tween(row, 0.12, { BackgroundTransparency = 0.85 }) end end)
            row.MouseLeave:Connect(function() if r.Refresh then r.Refresh() end end)
            row.MouseButton1Click:Connect(function()
                if r.Multi then r.Value[name] = not r.Value[name] or nil; r:Set(r:Get()) else r:Set(name); w:ClosePopups() end
            end)
        end
        r.Refresh = function()
            for _, q in ipairs(rows) do
                local sel = (r.Multi and r.Value[q.name]) or (not r.Multi and r.Value == q.name)
                q.row.BackgroundColor3 = Accent()
                Tween(q.row, 0.12, { BackgroundTransparency = sel and 0.55 or 1 })
            end
        end
        r.Refresh()
        Tween(pop, 0.3, { Size = UDim2.fromOffset(as.X / scale, H), GroupTransparency = 0 })
        Tween(chev, 0.25, { Rotation = 180 })
        w:_OpenPopup({ Owner = r, Close = function()
            r.Refresh = nil
            Tween(chev, 0.25, { Rotation = 0 })
            Tween(pop, 0.15, { Size = UDim2.fromOffset(as.X / scale, 0), GroupTransparency = 1 })
            task.delay(0.17, function() pop:Destroy() end)
        end })
    end)
    show()
    Register(r, o.Flag, r:Get())
    return r
end

local Short = { MouseButton1 = "Mouse 1", MouseButton2 = "Mouse 2", MouseButton3 = "Mouse 3", LeftShift = "LeftShift", RightShift = "RightShift",
    LeftControl = "LeftCtrl", RightControl = "RightCtrl", LeftAlt = "LeftAlt", RightAlt = "RightAlt" }
local function KeyName(k) if not k then return "None" end return Short[k.Name] or k.Name end

function Section:Keybind(o)
    o = o or {}
    local r = self:_Row(27)
    r.Key, r.Mode, r.State = o.Default, o.Mode or "Toggle", false
    Text(r.Frame, o.Title or "Keybind", 12, Theme.Text, FW.SemiBold, { Size = UDim2.new(1, -110, 1, 0), ZIndex = 3 })
    local f, t = Field(r.Frame, 93, 21, "pill")
    t.Text = KeyName(r.Key)
    local listening = false
    f.MouseButton1Click:Connect(function() listening = true; t.Text = "..." end)
    function r:Set(k) r.Key = k; t.Text = KeyName(k); if o.Flag then STRATA.Flags[o.Flag] = k and k.Name end; SafeCall(o.Changed, k) end
    function r:Get() return r.Key, r.State end
    table.insert(self.Window.Connections, UserInputService.InputBegan:Connect(function(i, gp)
        if listening then
            local k
            if i.UserInputType == Enum.UserInputType.Keyboard then k = i.KeyCode
            elseif i.UserInputType == Enum.UserInputType.MouseButton2 or i.UserInputType == Enum.UserInputType.MouseButton3 then k = i.UserInputType end
            if k then listening = false; if k == Enum.KeyCode.Escape then k = nil end; r:Set(k) end
            return
        end
        if gp or not r.Key then return end
        if i.KeyCode == r.Key or i.UserInputType == r.Key then
            if r.Mode == "Toggle" then r.State = not r.State else r.State = true end
            SafeCall(o.Callback, r.State)
        end
    end))
    table.insert(self.Window.Connections, UserInputService.InputEnded:Connect(function(i)
        if r.Mode == "Hold" and r.State and r.Key and (i.KeyCode == r.Key or i.UserInputType == r.Key) then r.State = false; SafeCall(o.Callback, false) end
    end))
    Register(r, o.Flag, r.Key and r.Key.Name)
    return r
end

function Section:ColorPicker(o)
    o = o or {}
    local w = self.Window
    local r = self:_Row(26)
    r.Value = o.Default or rgb(30, 144, 255)
    Text(r.Frame, o.Title or "Color", 12, Theme.Text, FW.SemiBold, { Size = UDim2.new(1, -40, 1, 0), ZIndex = 3 })
    local holder = New("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 2, 0.5, 0), Size = UDim2.fromOffset(o.Pill and 40 or 22, 22), BackgroundColor3 = rgb(0, 0, 0),
        BackgroundTransparency = 0.4, Text = "", AutoButtonColor = false, ZIndex = 3, Parent = r.Frame })
    Corner(holder, 11)
    Slice(holder, "pill_rim.png", S_PILL, { Size = UDim2.fromScale(1, 1), ZIndex = 5 })
    local dot = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = r.Value, ZIndex = 4, Parent = holder })
    Corner(dot, 7)
    New("UIStroke", { Color = r.Value, Thickness = 2, Transparency = 0.5, Parent = dot })
    function r:Set(c, silent)
        r.Value = c
        dot.BackgroundColor3 = c; dot.UIStroke.Color = c
        if o.Flag then STRATA.Flags[o.Flag] = c end
        if not silent then SafeCall(o.Callback, c) end
    end
    function r:Get() return r.Value end
    holder.MouseButton1Click:Connect(function() w:_ColorPopup(holder, r.Value, function(c) r:Set(c) end, r) end)
    Register(r, o.Flag, r.Value)
    return r
end

function Section:Button(o)
    o = o or {}
    local r = self:_Row(32)
    local b = New("TextButton", { Position = UDim2.fromOffset(0, 3), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3, Parent = r.Frame })
    local g = Gem(b, "tab", S_TAB, { Size = UDim2.fromScale(1, 1), ZIndex = 3 })
    local lbl = Text(b, o.Title or "Button", 12, Theme.Text, FW.Bold, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5 })
    New("UIStroke", { Color = rgb(0, 0, 0), Transparency = 0.6, Thickness = 1, Parent = lbl })
    local hover = false
    OnTheme(function() GemLook(g, hover and "hover" or "off", true) end)
    b.MouseEnter:Connect(function() hover = true; GemLook(g, "hover") end)
    b.MouseLeave:Connect(function() hover = false; GemLook(g, "off") end)
    b.MouseButton1Click:Connect(function()
        GemLook(g, "on", true)
        task.delay(0.12, function() GemLook(g, hover and "hover" or "off") end)
        SafeCall(o.Callback)
    end)
    return r
end

function Section:Label(txt)
    local r = self:_Row(22)
    r.Label = Text(r.Frame, txt or "", 11, Theme.Sub, FW.Regular, { Size = UDim2.fromScale(1, 1), TextWrapped = true, ZIndex = 3 })
    function r:Set(t) r.Label.Text = t end
    return r
end

------------------------------------------------------------------------ color popup (SV square + vertical hue + HEX + RGB)
local function Hex(c) return string.format("%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) end

function Window:_ColorPopup(anchor, color, onChange, owner)
    if self.Popup and self.Popup.Owner == owner then self:ClosePopups() return end
    local scale = self.Scale.Scale
    local ap, as = self:_Rel(anchor), anchor.AbsoluteSize
    local PW, PH = 178, 198
    local x = ap.X + as.X / 2 - PW / 2 * scale
    local ov = self.Overlay.AbsoluteSize
    x = math.clamp(x, 4, math.max(4, ov.X - PW * scale - 4))
    local y = ap.Y + as.Y + 3 * scale
    local pop = New("CanvasGroup", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(PW, PH), BackgroundColor3 = rgb(8, 8, 10), BackgroundTransparency = 0.04,
        GroupTransparency = 1, ZIndex = 5, Parent = self.Overlay })
    local sc = New("UIScale", { Scale = scale * 0.92, Parent = pop })
    Corner(pop, 8)
    Slice(pop, "panel_rim.png", S_PANEL, { Size = UDim2.fromScale(1, 1), ZIndex = 9 })
    local h, s, v = color:ToHSV()
    local sv = New("TextButton", { Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(126, 126), Text = "", AutoButtonColor = false, ZIndex = 6, Parent = pop })
    local wh = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(255, 255, 255), ZIndex = 6, Parent = sv })
    New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = wh })
    local bl = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(0, 0, 0), ZIndex = 6, Parent = sv })
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = bl })
    local cur = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(9, 9), BackgroundTransparency = 1, ZIndex = 7, Parent = sv })
    Corner(cur, 5)
    New("UIStroke", { Color = rgb(255, 255, 255), Thickness = 1.5, Parent = cur })
    local hue = New("TextButton", { Position = UDim2.fromOffset(146, 12), Size = UDim2.fromOffset(18, 126), Text = "", AutoButtonColor = false, BackgroundColor3 = rgb(255, 255, 255), ZIndex = 6, Parent = pop })
    local keys = {}
    for i = 0, 6 do keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i / 6) % 1, 1, 1)) end
    New("UIGradient", { Rotation = 90, Color = ColorSequence.new(keys), Parent = hue })
    local hk = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 4, 0, 4), BackgroundColor3 = rgb(255, 255, 255), ZIndex = 7, Parent = hue })
    Corner(hk, 2)
    local sw = New("Frame", { Position = UDim2.fromOffset(12, 146), Size = UDim2.fromOffset(30, 18), ZIndex = 6, Parent = pop })
    Corner(sw, 4)
    Text(pop, "HEX", 9, Theme.Sub, FW.Medium, { Position = UDim2.fromOffset(50, 146), Size = UDim2.fromOffset(24, 18), ZIndex = 6 })
    local hexF = New("Frame", { Position = UDim2.fromOffset(76, 146), Size = UDim2.fromOffset(88, 18), BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 0.3, ZIndex = 6, Parent = pop })
    Corner(hexF, 5)
    Slice(hexF, "field_rim.png", S_FIELD, { Size = UDim2.fromScale(1, 1), ZIndex = 8 })
    Text(hexF, "#", 9, Theme.Sub, FW.Medium, { Position = UDim2.fromOffset(7, 0), Size = UDim2.fromOffset(10, 18), ZIndex = 7 })
    local hexBox = New("TextBox", { BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 0), Size = UDim2.new(1, -22, 1, 0), FontFace = Font.new(FONT, FW.Medium), TextSize = 10,
        TextColor3 = Theme.Text, Text = "", TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 7, Parent = hexF })
    local rgbL = {}
    for i, ch in ipairs({ "R", "G", "B" }) do
        Text(pop, ch, 9, Theme.Sub, FW.Medium, { Position = UDim2.fromOffset(12 + (i - 1) * 52, 172), Size = UDim2.fromOffset(10, 16), ZIndex = 6 })
        rgbL[i] = Text(pop, "0", 10, Theme.Text, FW.Medium, { Position = UDim2.fromOffset(24 + (i - 1) * 52, 172), Size = UDim2.fromOffset(28, 16), ZIndex = 6 })
    end
    local function refresh(fire)
        local c = Color3.fromHSV(h, s, v)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        cur.Position = UDim2.fromScale(s, 1 - v)
        hk.Position = UDim2.fromScale(0.5, h)
        sw.BackgroundColor3 = c
        hexBox.Text = Hex(c)
        rgbL[1].Text, rgbL[2].Text, rgbL[3].Text = tostring(math.floor(c.R * 255 + 0.5)), tostring(math.floor(c.G * 255 + 0.5)), tostring(math.floor(c.B * 255 + 0.5))
        if fire then onChange(c) end
    end
    refresh(false)
    hexBox.FocusLost:Connect(function()
        local t = string.gsub(hexBox.Text, "#", "")
        if #t == 6 then
            local rr, gg, bb = tonumber(string.sub(t, 1, 2), 16), tonumber(string.sub(t, 3, 4), 16), tonumber(string.sub(t, 5, 6), 16)
            if rr and gg and bb then h, s, v = rgb(rr, gg, bb):ToHSV(); refresh(true) return end
        end
        refresh(false)
    end)
    local mode
    local function apply(p)
        if mode == "sv" then
            s = math.clamp((p.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
            v = 1 - math.clamp((p.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
        elseif mode == "hue" then
            h = math.clamp((p.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 0.999)
        end
        refresh(true)
    end
    sv.InputBegan:Connect(function(i) if IsClick(i) then mode = "sv"; apply(i.Position) end end)
    hue.InputBegan:Connect(function(i) if IsClick(i) then mode = "hue"; apply(i.Position) end end)
    local c1 = UserInputService.InputChanged:Connect(function(i) if mode and IsMove(i) then apply(i.Position) end end)
    local c2 = UserInputService.InputEnded:Connect(function(i) if IsClick(i) then mode = nil end end)
    Tween(pop, 0.25, { GroupTransparency = 0 })
    Tween(sc, 0.4, { Scale = scale }, Enum.EasingStyle.Back)
    self:_OpenPopup({ Owner = owner, Close = function()
        c1:Disconnect(); c2:Disconnect()
        Tween(pop, 0.15, { GroupTransparency = 1 })
        Tween(sc, 0.15, { Scale = scale * 0.94 })
        task.delay(0.17, function() pop:Destroy() end)
    end })
end

function Window:_AccentPopup(anchor)
    self:_ColorPopup(anchor, Theme.Accent or rgb(255, 255, 255), function(c) STRATA:SetAccent(c) end, "accent")
end

------------------------------------------------------------------------ popups, theme, visibility
function Window:_Rel(obj) return obj.AbsolutePosition - self.Overlay.AbsolutePosition end
function Window:_OpenPopup(p) self:ClosePopups(); self.Popup = p; self.Catcher.Visible = true end
function Window:ClosePopups()
    local p = self.Popup
    if not p then return end
    self.Popup = nil
    self.Catcher.Visible = false
    if p.Close then p.Close() end
end

function STRATA:SetAccent(c)
    Theme.Accent = c
    if c and Theme.Mode == "Glass" and STRATA.AutoDark ~= false then Theme.Mode = "Dark" end
    for _, fn in ipairs(STRATA._Hooks) do pcall(fn) end
    local w = STRATA._Window
    if w and w.Current then w:_TileStyle(w.Current, true) end
end

function STRATA:SetMode(m)
    Theme.Mode = m
    for _, fn in ipairs(STRATA._Hooks) do pcall(fn) end
    local w = STRATA._Window
    if w then
        if w.Current then w:_TileStyle(w.Current, true) end
        w:Shimmer()
    end
end

function Window:SetVisible(v)
    self.Visible = v
    self:ClosePopups()
    if v then
        self.Holder.Visible = true
        if self.Acrylic then self.Acrylic:SetEnabled(true) end
        Tween(self.Main, 0.3, { GroupTransparency = 0 })
        Tween(self.Scale, 0.45, { Scale = self.BaseScale or 1 }, Enum.EasingStyle.Back)
        self:Shimmer()
    else
        Tween(self.Main, 0.2, { GroupTransparency = 1 })
        Tween(self.Scale, 0.2, { Scale = (self.BaseScale or 1) * 0.95 })
        task.delay(0.21, function() if not self.Visible then self.Holder.Visible = false; if self.Acrylic then self.Acrylic:SetEnabled(false) end end end)
    end
end
function Window:Toggle() self:SetVisible(not self.Visible) end

function Window:Destroy()
    for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    if self.Acrylic then self.Acrylic:Destroy() end
    self.Gui:Destroy()
end

------------------------------------------------------------------------ config
local function Enc(v) if typeof(v) == "Color3" then return { __c = { v.R, v.G, v.B } } elseif typeof(v) == "EnumItem" then return { __e = tostring(v) } end return v end
local function Dec(v)
    if type(v) == "table" and v.__c then return Color3.new(v.__c[1], v.__c[2], v.__c[3]) end
    if type(v) == "table" and v.__e then local a, b = string.match(v.__e, "^Enum%.(%w+)%.(%w+)$"); return a and Enum[a][b] end
    return v
end
function STRATA:SaveConfig(name)
    if not writefile then return false end
    local d = {}
    for f, el in pairs(STRATA.Options) do local ok, v = pcall(function() return el:Get() end); if ok then d[f] = Enc(v) end end
    if not isfolder(Assets.Folder) then makefolder(Assets.Folder) end
    if not isfolder(Assets.Folder .. "/configs") then makefolder(Assets.Folder .. "/configs") end
    writefile(Assets.Folder .. "/configs/" .. (name or "default") .. ".json", HttpService:JSONEncode(d))
    return true
end
function STRATA:LoadConfig(name)
    local p = Assets.Folder .. "/configs/" .. (name or "default") .. ".json"
    if not (isfile and isfile(p)) then return false end
    local ok, d = pcall(function() return HttpService:JSONDecode(readfile(p)) end)
    if not ok then return false end
    for f, raw in pairs(d) do local el = STRATA.Options[f]; if el and el.Set then pcall(function() el:Set(Dec(raw)) end) end end
    return true
end

print("[STRATA] loaded v" .. STRATA.Version)
return STRATA
