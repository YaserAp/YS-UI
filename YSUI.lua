-- YSUI.lua — YSSH Full (Rayfield-style) ~650+ lines
-- Complete replacement UI library with Theme, Config, Loading, KeySystem, Prompt, Animations
-- API aims to be drop-in compatible with Rayfield where practical

--[===[
USAGE EXAMPLE
local YSUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/YaserAp/YS-UI/main/YSUI.lua"))()
local Window = YSUI:CreateWindow({ Name = "YS Script Hub", LoadingTitle = "YS Script Hub", LoadingSubtitle = "by YS", Theme = "Default", ToggleUIKeybind = "K", ConfigurationSaving = { Enabled = true, FolderName = "YS-UI", FileName = "config" }, KeySystem = true })
local Tab = Window:CreateTab("Player", 4483362458)
Tab:CreateToggle({ Name = "Infinite Jump", CurrentValue = false, Flag = "infjump", Callback = function(v) end })
Tab:CreateSlider({ Name = "WalkSpeed", Range = {1,100}, Increment = 1, CurrentValue = 16, Suffix = "Speed", Flag = "walkspeed", Callback = function(v) end })
local dd = Tab:CreateDropdown({ Name = "Pilih Pemain", Options = {}, Flag = "tp" , Callback = function(t) end })
dd:Refresh({"A","B","C"}, true)
YSUI:Notify({ Title = "Ready", Content = "YSUI aktif", Duration = 3 })
]===]

-- Services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Environment checks
local function isExecutor()
    return (syn ~= nil) or (KRNL_LOADED ~= nil) or (identifyexecutor ~= nil) or (writefile ~= nil)
end

-- Utilities
local function safe_pcall(fn, ...) local ok, res = pcall(fn, ...) if not ok then warn("YSUI internal error:", res) end return ok, res end
local function clamp(v,a,b) if v < a then return a elseif v > b then return b else return v end end
local function round(n, dec) local mult = 10^(dec or 0) return math.floor(n*mult+0.5)/mult end
local function join(...) local t={} for i=1,select('#',...) do t[i]=select(i,...) end return table.concat(t,'/') end

-- Persistence helpers
local function canSave() return type(writefile) == 'function' and type(isfile) == 'function' and type(makefolder) == 'function' end
local function ensureFolder(path)
    if not isfolder(path) then makefolder(path) end
end
local function saveJSON(path, data)
    if not canSave() then return false end
    local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok then return false end
    writefile(path, json)
    return true
end
local function loadJSON(path)
    if not canSave() then return nil end
    if not isfile(path) then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if ok then return data end
    return nil
end

-- Basic UI factory
local function make(class, props, children)
    local obj = Instance.new(class)
    if props then for k,v in pairs(props) do pcall(function() obj[k] = v end) end end
    if children then for _,c in ipairs(children) do c.Parent = obj end end
    return obj
end
local function tween(obj, info, goal) return TweenService:Create(obj, info, goal) end

-- Default themes
local THEMES = {
    Default = {
        Bg = Color3.fromRGB(20,20,22),
        Panel = Color3.fromRGB(28,28,34),
        Topbar = Color3.fromRGB(32,32,38),
        Accent = Color3.fromRGB(90,139,255),
        Accent2 = Color3.fromRGB(120,86,255),
        Text = Color3.fromRGB(230,230,235),
        SubText = Color3.fromRGB(160,160,170),
        Stroke = Color3.fromRGB(40,40,48),
        Good = Color3.fromRGB(75,200,130),
        Bad = Color3.fromRGB(255,85,115),
    },
    Light = {
        Bg = Color3.fromRGB(245,245,247),
        Panel = Color3.fromRGB(255,255,255),
        Topbar = Color3.fromRGB(240,240,245),
        Accent = Color3.fromRGB(40,120,255),
        Accent2 = Color3.fromRGB(120,86,255),
        Text = Color3.fromRGB(20,20,24),
        SubText = Color3.fromRGB(90,90,100),
        Stroke = Color3.fromRGB(220,220,230),
        Good = Color3.fromRGB(30,160,80),
        Bad = Color3.fromRGB(200,50,70),
    }
}

-- Library root
local YS = {}
YS.Flags = {}
YS.Theme = THEMES.Default
YS._internal = {}

-- Notification stack
YS._internal.notifyGui = nil
YS._internal.notifyList = {}

function YS:Notify(opts)
    opts = opts or {}
    local title = opts.Title or "Notice"
    local content = opts.Content or ""
    local dur = tonumber(opts.Duration) or 3

    if not YS._internal.notifyGui or not YS._internal.notifyGui.Parent then
        local gui = make('ScreenGui',{Name='YSS_Notify',ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
        gui.Parent = CoreGui
        YS._internal.notifyGui = gui
        local holder = make('Frame',{Name='Holder',AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-16,1,-16),Size=UDim2.new(0,300,0,0),BackgroundTransparency=1}, {
            make('UIListLayout',{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8),VerticalAlignment=Enum.VerticalAlignment.Bottom}),
        })
        holder.Parent = gui
    end

    local holder = YS._internal.notifyGui:FindFirstChild('Holder')
    if not holder then return end

    local card = make('Frame',{BackgroundColor3=YS.Theme.Panel,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,ClipsDescendants=true}, {
        make('UICorner',{CornerRadius=UDim.new(0,8)}),
        make('UIStroke',{Color=YS.Theme.Stroke,Thickness=1}),
        make('UIPadding',{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)}),
    })
    card.Parent = holder
    local titleLbl = make('TextLabel',{BackgroundTransparency=1,Font=Enum.Font.GothamBold,Text=title,TextColor3=YS.Theme.Text,TextSize=14,AutomaticSize=Enum.AutomaticSize.XY})
    titleLbl.Parent = card
    local contLbl = make('TextLabel',{BackgroundTransparency=1,Font=Enum.Font.Gotham,Text=content,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,Text=content,TextColor3=YS.Theme.SubText,TextSize=13,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y})
    contLbl.Parent = card

    tween(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1,0,0,card.AbsoluteSize.Y + 20)}):Play()

    task.spawn(function()
        task.wait(dur)
        local t = tween(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
        t:Play(); pcall(function() t.Completed:Wait() end)
        pcall(function() card:Destroy() end)
    end)
end

-- Key prompt helper
local function createPrompt(params)
    params = params or {}
    local title = params.Title or 'Prompt'
    local content = params.Content or ''
    local buttons = params.Buttons or { {Text='OK',Return=true} }
    local callback = params.Callback

    local gui = make('ScreenGui',{Name='YSS_Prompt',ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    gui.Parent = CoreGui
    local overlay = make('Frame',{Size=UDim2.new(1,0,1,0),BackgroundTransparency=0.6,BackgroundColor3=Color3.fromRGB(0,0,0)})
    overlay.Parent = gui
    local card = make('Frame',{Size=UDim2.new(0,420,0,160),Position=UDim2.new(0.5,-210,0.5,-80),BackgroundColor3=YS.Theme.Panel,BorderSizePixel=0}, {
        make('UICorner',{CornerRadius=UDim.new(0,10)}),
        make('UIStroke',{Color=YS.Theme.Stroke,Thickness=1}),
        make('UIPadding',{PaddingTop=UDim.new(0,12),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)}),
    })
    card.Parent = overlay
    local titleLbl = make('TextLabel',{BackgroundTransparency=1,Font=Enum.Font.GothamBold,Text=title,TextColor3=YS.Theme.Text,TextSize=16,Position=UDim2.new(0,0,0,0)})
    titleLbl.Parent = card
    local contLbl = make('TextLabel',{BackgroundTransparency=1,Font=Enum.Font.Gotham,Text=content,TextColor3=YS.Theme.SubText,TextWrapped=true,Size=UDim2.new(1,0,0,64),Position=UDim2.new(0,0,0,28),TextSize=13})
    contLbl.Parent = card
    local btnHolder = make('Frame',{Size=UDim2.new(1,0,0,36),Position=UDim2.new(0,0,1,-40),BackgroundTransparency=1}, { make('UIListLayout',{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Right,Padding=UDim.new(0,8)}) })
    btnHolder.Parent = card

    for _,b in ipairs(buttons) do
        local tb = make('TextButton',{Text=b.Text,Size=UDim2.new(0,100,1,0),Font=Enum.Font.Gotham,TextSize=14,BackgroundColor3=YS.Theme.Accent,TextColor3=Color3.new(1,1,1)})
        tb.Parent = btnHolder
        tb.MouseButton1Click:Connect(function()
            local ret = b.Return or b.Value or true
            pcall(function() if callback then callback(ret) end end)
            gui:Destroy()
        end)
    end
    return gui
end

-- KeySystem modal (simple)
function YS:KeySystem(opts)
    opts = opts or {}
    if not opts.Enabled then return false end
    local title = opts.Title or 'Key System'
    local subtitle = opts.Subtitle or ''
    local note = opts.Note or ''
    local validKeys = opts.Key or {}

    local gui = make('ScreenGui',{Name='YSS_Key',ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling}) gui.Parent = CoreGui
    local overlay = make('Frame',{Size=UDim2.new(1,0,1,0),BackgroundTransparency=0.6,BackgroundColor3=Color3.fromRGB(0,0,0)}) overlay.Parent = gui
    local card = make('Frame',{Size=UDim2.new(0,420,0,220),Position=UDim2.new(0.5,-210,0.5,-110),BackgroundColor3=YS.Theme.Panel,BorderSizePixel=0}, {
        make('UICorner',{CornerRadius=UDim.new(0,12)}), make('UIStroke',{Color=YS.Theme.Stroke,Thickness=1}), make('UIPadding',{PaddingTop=UDim.new(0,12),PaddingLeft=UDim.new(0,12)})
    }) card.Parent = overlay
    make('TextLabel',{BackgroundTransparency=1,Font=Enum.Font.GothamBold,Text=title,TextColor3=YS.Theme.Text,TextSize=18,Position=UDim2.new(0,0,0,0)}).Parent=card
    make('TextLabel',{BackgroundTransparency=1,Font=Enum.Font.Gotham,Text=subtitle,TextColor3=YS.Theme.SubText,TextSize=13,Position=UDim2.new(0,0,0,28)}).Parent=card
    local input = make('TextBox',{Size=UDim2.new(1,0,0,32),Position=UDim2.new(0,0,0,64),Text='',Font=Enum.Font.Gotham,TextSize=16,ClearTextOnFocus=false,PlaceholderText='Masukkan key di sini'})
    input.Parent = card
    local noteLbl = make('TextLabel',{BackgroundTransparency=1,Font=Enum.Font.Gotham,Text=note,TextColor3=YS.Theme.SubText,TextSize=12,Position=UDim2.new(0,0,0,100)}) noteLbl.Parent = card
    local btn = make('TextButton',{Text='Submit',Size=UDim2.new(0,120,0,36),Position=UDim2.new(1,-132,1,-44),Font=Enum.Font.Gotham,TextSize=14,BackgroundColor3=YS.Theme.Accent,TextColor3=Color3.new(1,1,1)}) btn.Parent = card

    local function onSubmit()
        local val = input.Text
        for _,k in ipairs(validKeys) do if tostring(k) == tostring(val) then gui:Destroy(); return true end end
        createPrompt({ Title = 'Key Invalid', Content = 'Key tidak valid', Buttons = {{Text='OK', Return=false}} })
        return false
    end
    btn.MouseButton1Click:Connect(onSubmit)
    return gui
end

-- Main Window builder (full)
function YS:CreateWindow(settings)
    settings = settings or {}
    if settings.Theme and THEMES[settings.Theme] then self.Theme = THEMES[settings.Theme] else self.Theme = THEMES.Default end

    -- screen
    local gui = make('ScreenGui',{Name='YSSH_UI',ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Global}) gui.Parent = CoreGui

    -- loading splash
    if settings.LoadingTitle or settings.LoadingSubtitle then
        local splash = make('Frame',{Size=UDim2.new(1,0,1,0),BackgroundTransparency=0.2,BackgroundColor3=Color3.new(0,0,0)}) splash.Parent = gui
        local t = make('TextLabel',{BackgroundTransparency=1,Font=Enum.Font.GothamBold,Text=settings.LoadingTitle or 'Loading',TextColor3=Color3.new(1,1,1),TextSize=22,Position=UDim2.new(0.5,-150,0.5,-12)}) t.Parent = splash
        local s = make('TextLabel',{BackgroundTransparency=1,Font=Enum.Font.Gotham,Text=settings.LoadingSubtitle or '',TextColor3=Color3.fromRGB(230,230,230),TextSize=14,Position=UDim2.new(0.5,-150,0.5,18)}) s.Parent = splash
        task.delay(0.6, function() pcall(function() splash:Destroy() end) end)
    end

    -- main window
    local main = make('Frame',{Name='Main',Size=UDim2.new(0,680,0,460),Position=UDim2.new(0.5,-340,0.5,-230),BackgroundColor3=self.Theme.Bg,BorderSizePixel=0}, {
        make('UICorner',{CornerRadius=UDim.new(0,14)}), make('UIStroke',{Color=self.Theme.Stroke,Thickness=1}),
    })
    main.Parent = gui

    -- topbar
    local top = make('Frame',{Name='Topbar',Size=UDim2.new(1,0,0,44),BackgroundColor3=self.Theme.Topbar,BorderSizePixel=0}, { make('UICorner',{CornerRadius=UDim.new(0,14)}) })
    top.Parent = main
    local title = make('TextLabel',{BackgroundTransparency=1,Position=UDim2.new(0,16,0,0),Size=UDim2.new(1,-120,1,0),Font=Enum.Font.GothamBold,Text=(settings.Name or settings.Title or 'YSSH UI'),TextColor3=self.Theme.Text,TextSize=18,TextXAlignment=Enum.TextXAlignment.Left})
    title.Parent = top

    -- controls (minimize, close)
    local btnMin = make('TextButton',{Text='-',Font=Enum.Font.GothamBold,TextSize=20,Size=UDim2.new(0,36,0,36),Position=UDim2.new(1,-84,0,4),BackgroundTransparency=1,TextColor3=self.Theme.Text}) btnMin.Parent=top
    local btnClose = make('TextButton',{Text='X',Font=Enum.Font.GothamBold,TextSize=20,Size=UDim2.new(0,36,0,36),Position=UDim2.new(1,-44,0,4),BackgroundTransparency=1,TextColor3=self.Theme.Bad}) btnClose.Parent=top

    local content = make('Frame',{Name='Content',Position=UDim2.new(0,0,0,44),Size=UDim2.new(1,0,1,-44),BackgroundColor3=self.Theme.Panel,BorderSizePixel=0}, { make('UIStroke',{Color=self.Theme.Stroke,Thickness=1}) })
    content.Parent = main

    -- left tabbar
    local tabbar = make('Frame',{Name='Tabbar',Size=UDim2.new(0,200,1,0),Position=UDim2.new(0,0,0,0),BackgroundColor3=self.Theme.Panel,BorderSizePixel=0}) tabbar.Parent=content
    local tabList = make('Frame',{Name='TabList',BackgroundTransparency=1,Size=UDim2.new(1,0,1,0)}, { make('UIListLayout',{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)}), make('UIPadding',{PaddingTop=UDim.new(0,8),PaddingLeft=UDim.new(0,12)}) })
    tabList.Parent = tabbar

    -- pages container
    local pages = make('Frame',{Name='Pages',Position=UDim2.new(0,200,0,0),Size=UDim2.new(1,-200,1,0),BackgroundTransparency=1}) pages.Parent = content

    -- draggable
    local function makeDraggable(frame, drag)
        drag = drag or frame
        local dragging=false local dragStart, startPos
        drag.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=inp.Position; startPos=frame.Position; inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end) end
        end)
        drag.InputChanged:Connect(function(inp) if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement) then local delta=inp.Position - dragStart; frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y) end end)
    end
    makeDraggable(main, top)

    -- keybind toggle
    local keycode = (settings.ToggleUIKeybind and (typeof(settings.ToggleUIKeybind)=='string' and Enum.KeyCode[settings.ToggleUIKeybind:upper()] or settings.ToggleUIKeybind)) or Enum.KeyCode.K
    local hidden=false
    UserInputService.InputBegan:Connect(function(inp,gpe)
        if gpe then return end
        if inp.KeyCode==keycode then
            hidden = not hidden
            tween(main, TweenInfo.new(0.2), {BackgroundTransparency = hidden and 1 or 0}):Play()
            main.Visible = not hidden
        end
    end)

    -- config load/save
    local configData = {}
    local confPath
    if settings.ConfigurationSaving and settings.ConfigurationSaving.Enabled and canSave() then
        local folder = settings.ConfigurationSaving.FolderName or 'YSUI'
        local file = settings.ConfigurationSaving.FileName or 'config'
        ensureFolder('YSUI')
        ensureFolder(join('YSUI', folder))
        confPath = join('YSUI', folder, file..'.json')
        local loaded = loadJSON(confPath)
        if loaded and loaded.Flags then configData.Flags = loaded.Flags end
        if configData.Flags then for k,v in pairs(configData.Flags) do YS.Flags[k]=v end end
    end

    -- window API
    local window = {}
    window.Tabs = {}

    local function switchTo(page)
        for _,c in ipairs(pages:GetChildren()) do if c:IsA('Frame') then c.Visible=false end end
        if page then page.Visible=true end
    end

    function window:CreateTab(name, iconId)
        name = name or 'Tab'
        local btn = make('TextButton',{Text='  '..name,Size=UDim2.new(1,-24,0,36),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.7,Font=Enum.Font.Gotham,TextSize=15,TextColor3=YS.Theme.Text,AutoButtonColor=false}, { make('UICorner',{CornerRadius=UDim.new(0,8)}), make('UIPadding',{PaddingLeft=UDim.new(0,28)}) })
        btn.Parent = tabList
        if iconId and tonumber(iconId) then
            local ico = make('ImageLabel',{Image='rbxassetid://'..tostring(iconId),Size=UDim2.new(0,18,0,18),BackgroundTransparency=1,Position=UDim2.new(0,6,0,9)}) ico.Parent = btn
        end
        local page = make('Frame',{Size=UDim2.new(1,-24,1,-24),Position=UDim2.new(0,12,0,12),BackgroundTransparency=1,Visible=false}, { make('UIListLayout',{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)}), make('UIPadding',{PaddingTop=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)}) })
        page.Parent = pages

        btn.MouseButton1Click:Connect(function()
            for _,c in ipairs(tabList:GetChildren()) do if c:IsA('TextButton') then tween(c, TweenInfo.new(0.12), {BackgroundTransparency=0.7}):Play() end end
            tween(btn, TweenInfo.new(0.12), {BackgroundTransparency=0.3}):Play()
            switchTo(page)
        end)

        if #tabList:GetChildren()==1 then btn.BackgroundTransparency=0.3; page.Visible=true end

        local tabObj = {}

        -- Button element
        function tabObj:CreateButton(data)
            data = data or {}
            local card = make('Frame',{Size=UDim2.new(1,0,0,44),BackgroundColor3=YS.Theme.Bg}, { make('UICorner',{CornerRadius=UDim.new(0,8)}), make('UIStroke',{Color=YS.Theme.Stroke,Thickness=1}), make('UIPadding',{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)}) })
            card.Parent = page
            local btn = make('TextButton',{Size=UDim2.new(1,0,1,0),BackgroundColor3=YS.Theme.Panel,Text=data.Name or 'Button',Font=Enum.Font.Gotham,TextSize=14,TextColor3=YS.Theme.Text,AutoButtonColor=false}, { make('UICorner',{CornerRadius=UDim.new(0,8)}) })
            btn.Parent = card
            btn.MouseButton1Click:Connect(safe_pcall(function() if data.Callback then data.Callback() end end))
            btn.MouseEnter:Connect(function() tween(btn, TweenInfo.new(0.12), {BackgroundTransparency=0.1}):Play() end)
            btn.MouseLeave:Connect(function() tween(btn, TweenInfo.new(0.12), {BackgroundTransparency=0}):Play() end)
            return btn
        end

        -- Toggle element
        function tabObj:CreateToggle(data)
            data = data or {}
            local flag = data.Flag or data.Name
            local state = (YS.Flags[flag]~=nil) and YS.Flags[flag] or (data.CurrentValue==true)
            local card = make('Frame',{Size=UDim2.new(1,0,0,48),BackgroundColor3=YS.Theme.Bg}, { make('UICorner',{CornerRadius=UDim.new(0,8)}), make('UIStroke',{Color=YS.Theme.Stroke,Thickness=1}), make('UIPadding',{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)}) })
            card.Parent = page
            local lbl = make('TextLabel',{BackgroundTransparency=1,Size=UDim2.new(1,-80,1,0),Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Text=data.Name or 'Toggle',TextColor3=YS.Theme.Text,TextSize=14}) lbl.Parent=card
            local sw = make('Frame',{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),Size=UDim2.new(0,56,0,28),BackgroundColor3=(state and YS.Theme.Accent or YS.Theme.Panel)}, { make('UICorner',{CornerRadius=UDim.new(1,0)}), make('UIStroke',{Color=YS.Theme.Stroke,Thickness=1}) }) sw.Parent=card
            local knob = make('Frame',{Size=UDim2.new(0,24,0,24),Position=UDim2.new(0, state and 30 or 2,0,2),BackgroundColor3=Color3.new(1,1,1)}, { make('UICorner',{CornerRadius=UDim.new(1,0)}) }) knob.Parent=sw

            local function setState(v, fire)
                state = not not v
                YS.Flags[flag]=state
                tween(sw, TweenInfo.new(0.14), {BackgroundColor3 = state and YS.Theme.Accent or YS.Theme.Panel}):Play()
                tween(knob, TweenInfo.new(0.14), {Position = UDim2.new(0, state and 30 or 2, 0, 2)}):Play()
                if fire and data.Callback then safe_pcall(data.Callback, state) end
            end
            sw.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then setState(not state, true) end end)
            setState(state,false)
            return setmetatable({}, { __index = { Set = setState } })
        end

        -- Slider element
        function tabObj:CreateSlider(data)
            data = data or {}
            local min = (data.Range and data.Range[1]) or 0
            local max = (data.Range and data.Range[2]) or 100
            local inc = data.Increment or 1
            local val = clamp(tonumber(data.CurrentValue) or min, min, max)
            local flag = data.Flag or data.Name

            local card = make('Frame',{Size=UDim2.new(1,0,0,72),BackgroundColor3=YS.Theme.Bg}, { make('UICorner',{CornerRadius=UDim.new(0,8)}), make('UIStroke',{Color=YS.Theme.Stroke,Thickness=1}), make('UIPadding',{PaddingTop=UDim.new(0,8),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)}) })
            card.Parent = page
            local lbl = make('TextLabel',{BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Text=(data.Name or 'Slider')..' ('..tostring(val)..(data.Suffix or '')..')',TextColor3=YS.Theme.Text,TextSize=14}) lbl.Parent=card
            local bar = make('Frame',{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,0,32),BackgroundColor3=YS.Theme.Panel}, { make('UICorner',{CornerRadius=UDim.new(0,8)}), make('UIStroke',{Color=YS.Theme.Stroke,Thickness=1}) }) bar.Parent = card
            local fill = make('Frame',{Size=UDim2.new((val-min)/(max-min),0,1,0),BackgroundColor3=YS.Theme.Accent}, { make('UICorner',{CornerRadius=UDim.new(0,8)}) }) fill.Parent = bar

            local dragging=false
            local function setFromX(x, fire)
                local rel = clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
                local raw = min + rel*(max-min)
                local snapped = clamp(round(raw/inc)*inc, min, max)
                val = snapped
                YS.Flags[flag] = val
                lbl.Text = (data.Name or 'Slider')..' ('..tostring(val)..(data.Suffix or '')..')'
                fill.Size = UDim2.new((val-min)/(max-min),0,1,0)
                if fire and data.Callback then safe_pcall(data.Callback, val) end
            end

            bar.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; setFromX(inp.Position.X, true) end end)
            UserInputService.InputChanged:Connect(function(inp) if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then setFromX(inp.Position.X, true) end end)
            UserInputService.InputEnded:Connect(function(inp) if dragging and inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)

            -- initialize
            pcall(function() setFromX(bar.AbsolutePosition.X + bar.AbsoluteSize.X * ((val-min)/(max-min)), false) end)

            return setmetatable({}, { __index = { Set = function(_,v) pcall(function() setFromX(bar.AbsolutePosition.X + bar.AbsoluteSize.X * ((clamp(v,min,max)-min)/(max-min)), true) end) end } })
        end

        -- Dropdown element
        function tabObj:CreateDropdown(data)
            data = data or {}
            local options = data.Options or {}
            local current = data.CurrentOption
            local flag = data.Flag or data.Name

            local card = make('Frame',{Size=UDim2.new(1,0,0,44),BackgroundColor3=YS.Theme.Bg}, { make('UICorner',{CornerRadius=UDim.new(0,8)}), make('UIStroke',{Color=YS.Theme.Stroke,Thickness=1}), make('UIPadding',{PaddingTop=UDim.new(0,8),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)}) }) card.Parent=page
            local btn = make('TextButton',{Size=UDim2.new(1,0,1,0),BackgroundColor3=YS.Theme.Panel,Text=(data.Name or 'Dropdown')..' ▾',Font=Enum.Font.Gotham,TextSize=14,TextColor3=YS.Theme.Text,AutoButtonColor=false}, { make('UICorner',{CornerRadius=UDim.new(0,8)}) }) btn.Parent=card
            local list = make('Frame',{Visible=false,BackgroundColor3=YS.Theme.Panel,Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,1,6),ZIndex=5}, { make('UICorner',{CornerRadius=UDim.new(0,8)}), make('UIStroke',{Color=YS.Theme.Stroke,Thickness=1}), make('UIListLayout',{Padding=UDim.new(0,4)}), make('UIPadding',{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4),PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6)}) }) list.Parent = card

            local function apply(choice)
                current = {choice}
                YS.Flags[flag] = choice
                btn.Text = (data.Name or 'Dropdown')..': '..tostring(choice)
                if data.Callback then safe_pcall(data.Callback, current) end
            end

            local function rebuild(opts, reset)
                for _,c in ipairs(list:GetChildren()) do if c:IsA('TextButton') then c:Destroy() end end
                list.Size = UDim2.new(1,0,0,8 + (#opts * 28))
                for _,opt in ipairs(opts) do
                    local it = make('TextButton',{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text=tostring(opt),Font=Enum.Font.Gotham,TextSize=14,TextColor3=YS.Theme.Text,AutoButtonColor=true})
                    it.Parent = list
                    it.MouseButton1Click:Connect(function() apply(opt); list.Visible=false end)
                end
                if reset then current=nil; btn.Text=(data.Name or 'Dropdown')..' ▾' end
            end

            btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
            rebuild(options, true)
            if type(current)=='table' and current[1] then apply(current[1]) end

            local api = {}
            function api:Refresh(newOpts, reset) options = newOpts or {} ; rebuild(options, reset) end
            return api
        end

        -- Input box
        function tabObj:CreateInput(data)
            data = data or {}
            local card = make('Frame',{Size=UDim2.new(1,0,0,48),BackgroundColor3=YS.Theme.Bg}, { make('UICorner',{CornerRadius=UDim.new(0,8)}), make('UIStroke',{Color=YS.Theme.Stroke,Thickness=1}), make('UIPadding',{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,12)}) }) card.Parent=page
            local tb = make('TextBox',{Size=UDim2.new(1,0,0,28),Text=data.Text or '',ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=14,PlaceholderText=data.Placeholder or ''}) tb.Parent=card
            tb.FocusLost:Connect(function(enter) if enter and data.Callback then safe_pcall(data.Callback, tb.Text) end end)
            return tb
        end

        table.insert(window.Tabs, tabObj)
        return tabObj
    end

    -- minimize / close behavior
    local minimized = false
    btnMin.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            tween(main, TweenInfo.new(0.15), {Size = UDim2.new(0,680,0,44)}):Play()
            for _,c in ipairs(content:GetChildren()) do if c~=tabbar then c.Visible=false end end
        else
            tween(main, TweenInfo.new(0.15), {Size = UDim2.new(0,680,0,460)}):Play()
            for _,c in ipairs(content:GetChildren()) do c.Visible=true end
        end
    end)
    btnClose.MouseButton1Click:Connect(function() pcall(function() gui:Destroy() end) end)

    -- configuration autosave
    if settings.ConfigurationSaving and settings.ConfigurationSaving.Enabled and confPath then
        task.spawn(function()
            while gui.Parent do
                task.wait(2)
                saveJSON(confPath, { Flags = YS.Flags })
            end
        end)
    end

    -- optional KeySystem
    if settings.KeySystem and settings.KeySettings then
        -- open key modal automatically if configured
        if settings.KeySystem==true then
            local ks = settings.KeySettings
            -- show prompt
            local modal = YS:KeySystem({ Enabled=true, Title=ks.Title or 'Key', Subtitle=ks.Subtitle, Note=ks.Note, Key=ks.Key or {} })
        end
    end

    return setmetatable(window, { __index = self })
end

-- Expose library
return YS
