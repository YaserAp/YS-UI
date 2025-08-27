--[[
  YSUI.lua — YSSH Library (Rayfield‑style)
  API (intended 1:1 where practical):
    local YSUI = loadstring(game:HttpGet("<raw-url>/YSUI.lua"))()
    local Window = YSUI:CreateWindow({
      Name = "YS Script Hub",
      Icon = 0,
      LoadingTitle = "Loading...",
      LoadingSubtitle = "by You",
      ShowText = "YS",
      Theme = "Default",
      ToggleUIKeybind = "K",
      DisableRayfieldPrompts = false,
      DisableBuildWarnings = false,
      ConfigurationSaving = { Enabled = true, FolderName = "YSSH", FileName = "config" },
      Discord = { Enabled = false, Invite = "", RememberJoins = false },
      KeySystem = false,
      KeySettings = { Title = "", Subtitle = "", Note = "", FileName = "", SaveKey = true, GrabKeyFromSite = false, Key = {"Hello"} },
    })

    local Tab = Window:CreateTab("Player", 4483362458)
    local Toggle = Tab:CreateToggle({ Name = "Infinite Jump", CurrentValue = false, Flag = "InfJump", Callback = function(v) end })
    local Slider = Tab:CreateSlider({ Name = "WalkSpeed", Range = {1, 100}, Increment = 1, Suffix = "Speed", CurrentValue = 16, Flag = "WS", Callback = function(v) end })
    local Dropdown = Tab:CreateDropdown({ Name = "Pilih Pemain", Options = {"Alice","Bob"}, CurrentOption = nil, Flag = "TP", Callback = function(optTbl) end })
    Dropdown:Refresh({"Alice","Bob","Charlie"}, true) -- optional
    YSUI:Notify({ Title = "Hello", Content = "World", Duration = 3 })

  Notes:
    - This is an original implementation re‑creating a compatible API, not a copy.
    - Requires exploit environment (CoreGui access, loadstring). Studio may block HttpGet/loadstring.
    - Config saving uses writefile/readfile if available.
--]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function isExecutor() -- rough check for exploit env
  return (syn or KRNL_LOADED or identifyexecutor or writefile) ~= nil
end

local function safeWrap(fn)
  return function(...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("YSSH Error:", err) end
  end
end

-- Theme presets
local THEMES = {
  Default = {
    Bg = Color3.fromRGB(18, 18, 20),
    Panel = Color3.fromRGB(24, 24, 28),
    Topbar = Color3.fromRGB(28, 28, 34),
    Accent = Color3.fromRGB(90, 139, 255),
    Accent2 = Color3.fromRGB(120, 86, 255),
    Text = Color3.fromRGB(230, 230, 235),
    SubText = Color3.fromRGB(150, 150, 160),
    Stroke = Color3.fromRGB(50, 50, 60),
    Good = Color3.fromRGB(75, 200, 130),
    Bad = Color3.fromRGB(255, 85, 115),
  },
}

-- Utilities
local function make(instance, props, children)
  local obj = Instance.new(instance)
  for k, v in pairs(props or {}) do obj[k] = v end
  for _, child in ipairs(children or {}) do child.Parent = obj end
  return obj
end

local function tween(o, ti, goal)
  return TweenService:Create(o, ti, goal)
end

local function round(n, inc)
  if not inc or inc <= 0 then return n end
  return math.floor((n / inc) + 0.5) * inc
end

local function getKeyCodeFromString(s)
  if typeof(s) == "EnumItem" and s.EnumType == Enum.KeyCode then return s end
  if type(s) ~= "string" then return Enum.KeyCode.K end
  local upper = s:upper()
  if Enum.KeyCode[upper] then return Enum.KeyCode[upper] end
  return Enum.KeyCode.K
end

-- Persistence helpers
local function joinPaths(...)
  return table.concat({...}, "/")
end

local function canSave()
  return typeof(writefile) == "function" and typeof(isfile) == "function" and typeof(makefolder) == "function"
end

local function saveConfig(folder, file, data)
  if not canSave() then return false end
  local pathFolder = folder and ("YSSH/"..folder) or "YSSH"
  local pathFile = joinPaths(pathFolder, (file or "config")..".json")
  if not isfolder("YSSH") then makefolder("YSSH") end
  if folder and not isfolder(pathFolder) then makefolder(pathFolder) end
  local json = HttpService:JSONEncode(data)
  writefile(pathFile, json)
  return true
end

local function loadConfig(folder, file)
  if not canSave() then return nil end
  local pathFolder = folder and ("YSSH/"..folder) or "YSSH"
  local pathFile = joinPaths(pathFolder, (file or "config")..".json")
  if isfile(pathFile) then
    local ok, decoded = pcall(function()
      return HttpService:JSONDecode(readfile(pathFile))
    end)
    if ok then return decoded end
  end
  return nil
end

-- Library root
local YSSHLibrary = { Flags = {}, Theme = THEMES.Default }

-- Notifications
function YSSHLibrary:Notify(opts)
  opts = opts or {}
  local title = opts.Title or "Notice"
  local content = opts.Content or ""
  local duration = tonumber(opts.Duration) or 3

  local gui = CoreGui:FindFirstChild("YSSH_Notify") or make("ScreenGui", {Name = "YSSH_Notify", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, {})
  gui.Parent = CoreGui

  local holder = gui:FindFirstChild("Holder")
  if not holder then
    holder = make("Frame", {
      Name = "Holder",
      AnchorPoint = Vector2.new(1, 1),
      Position = UDim2.new(1, -16, 1, -16),
      Size = UDim2.new(0, 300, 0, 0),
      BackgroundTransparency = 1,
    }, {
      make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom }),
    })
    holder.Parent = gui
  end

  local card = make("Frame", {
    BackgroundColor3 = self.Theme.Panel,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    ClipsDescendants = true,
  }, {
    make("UICorner", {CornerRadius = UDim.new(0, 10)}),
    make("UIStroke", {Color = self.Theme.Stroke, Thickness = 1}),
    make("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}),
  })
  card.Parent = holder

  local titleLbl = make("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = title,
    TextColor3 = self.Theme.Text,
    TextSize = 14,
    AutomaticSize = Enum.AutomaticSize.XY,
  })
  titleLbl.Parent = card

  local contentLbl = make("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = content,
    TextColor3 = self.Theme.SubText,
    TextSize = 13,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
  })
  contentLbl.Parent = card

  card.Size = UDim2.new(1, 0, 0, 0)
  tween(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, card.AbsoluteSize.Y + 20)}):Play()

  task.spawn(function()
    task.wait(duration)
    local t = tween(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
    t:Play(); t.Completed:Wait()
    card:Destroy()
  end)
end

-- Drag helper
local function makeDraggable(frame, dragArea)
  dragArea = dragArea or frame
  local dragging = false
  local dragStart, startPos

  local function update(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
  end

  dragArea.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
      dragging = true
      dragStart = input.Position
      startPos = frame.Position
      input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then dragging = false end
      end)
    end
  end)

  dragArea.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
      if dragging then update(input) end
    end
  end)
end

-- Build Window
function YSSHLibrary:CreateWindow(settings)
  settings = settings or {}

  if not isExecutor() and not settings.DisableBuildWarnings then
    warn("[YSSH] Running outside exploit environment may break HttpGet/loadstring/CoreGui parenting.")
  end

  local themeKey = settings.Theme or "Default"
  self.Theme = THEMES[themeKey] or THEMES.Default

  -- ScreenGui
  local gui = make("ScreenGui", { Name = "YSSH_UI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Global })
  gui.Parent = CoreGui

  -- Loading splash (simple)
  if settings.LoadingTitle or settings.LoadingSubtitle then
    local splash = make("Frame", {Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.2}, {
      make("TextLabel", {Text = (settings.LoadingTitle or "Loading"), Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = Color3.new(1,1,1), BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,-12)}),
      make("TextLabel", {Text = (settings.LoadingSubtitle or ""), Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(220,220,220), BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,12)}),
    })
    splash.Parent = gui
    task.delay(0.6, function() if splash then splash:Destroy() end end)
  end

  -- Main Window
  local window = {}

  local main = make("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 640, 0, 420),
    Position = UDim2.new(0.5, -320, 0.5, -210),
    BackgroundColor3 = self.Theme.Bg,
    BorderSizePixel = 0,
  }, {
    make("UICorner", {CornerRadius = UDim.new(0, 12)}),
    make("UIStroke", {Color = self.Theme.Stroke, Thickness = 1}),
  })
  main.Parent = gui

  -- Topbar
  local topbar = make("Frame", {
    Name = "Topbar",
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = self.Theme.Topbar,
    BorderSizePixel = 0,
  }, {
    make("UICorner", {CornerRadius = UDim.new(0, 12)}),
  })
  topbar.Parent = main

  local title = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 16, 0, 0),
    Size = UDim2.new(1, -80, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = (settings.Name or settings.Title or "YSSH UI"),
    TextColor3 = self.Theme.Text,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
  })
  title.Parent = topbar

  local closeBtn = make("TextButton", {
    Name = "CloseButton",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.new(0, 20, 0, 20),
    BackgroundColor3 = self.Theme.Topbar,
    Font = Enum.Font.GothamBold,
    Text = "X",
    TextColor3 = self.Theme.Text,
    TextSize = 14,
    AutoButtonColor = false,
  }, { make("UICorner", {CornerRadius = UDim.new(0, 4)}) })
  closeBtn.Parent = topbar

  local minimizeBtn = make("TextButton", {
    Name = "MinimizeButton",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -40, 0.5, 0),
    Size = UDim2.new(0, 20, 0, 20),
    BackgroundColor3 = self.Theme.Topbar,
    Font = Enum.Font.GothamBold,
    Text = "_",
    TextColor3 = self.Theme.Text,
    TextSize = 14,
    AutoButtonColor = false,
  }, { make("UICorner", {CornerRadius = UDim.new(0, 4)}) })
  minimizeBtn.Parent = topbar

  closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
  end)

  local isMinimized = false
  local originalSize = main.Size
  minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
      content.Visible = false
      tabbar.Visible = false
      tween(main, TweenInfo.new(0.2), { Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 40) }):Play()
    else
      content.Visible = true
      tabbar.Visible = true
      tween(main, TweenInfo.new(0.2), { Size = originalSize }):Play()
    end
  end)

  closeBtn.MouseEnter:Connect(function() tween(closeBtn, TweenInfo.new(0.1), { BackgroundColor3 = self.Theme.Bad }):Play() end)
  closeBtn.MouseLeave:Connect(function() tween(closeBtn, TweenInfo.new(0.1), { BackgroundColor3 = self.Theme.Topbar }):Play() end)
  minimizeBtn.MouseEnter:Connect(function() tween(minimizeBtn, TweenInfo.new(0.1), { BackgroundColor3 = self.Theme.Stroke }):Play() end)
  minimizeBtn.MouseLeave:Connect(function() tween(minimizeBtn, TweenInfo.new(0.1), { BackgroundColor3 = self.Theme.Topbar }):Play() end)

  makeDraggable(main, topbar)

  -- Left tab bar
  local tabbar = make("Frame", {
    Name = "Tabbar",
    Position = UDim2.new(0, 0, 0, 40),
    Size = UDim2.new(0, 170, 1, -40),
    BackgroundColor3 = self.Theme.Panel,
    BorderSizePixel = 0,
  }, {
    make("UIStroke", {Color = self.Theme.Stroke, Thickness = 1}),
  })
  tabbar.Parent = main

  local tabList = make("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
  }, {
    make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
    make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
  })
  tabList.Parent = tabbar

  -- Right content area
  local content = make("Frame", {
    Name = "Content",
    Position = UDim2.new(0, 170, 0, 40),
    Size = UDim2.new(1, -170, 1, -40),
    BackgroundColor3 = self.Theme.Panel,
    BorderSizePixel = 0,
  }, {
    make("UIStroke", {Color = self.Theme.Stroke, Thickness = 1}),
  })
  content.Parent = main

  local pageFolder = make("Folder", {Name = "Pages"}, {})
  pageFolder.Parent = content

  local function switchTo(page)
    for _, p in ipairs(pageFolder:GetChildren()) do
      if p:IsA("Frame") then p.Visible = (p == page) end
    end
  end

  -- Keybind toggle
  local keycode = getKeyCodeFromString(settings.ToggleUIKeybind or "K")
  local hidden = false
  UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == keycode then
      hidden = not hidden
      local goal = { BackgroundTransparency = hidden and 1 or 0 }
      tween(main, TweenInfo.new(0.2), goal):Play()
      main.Visible = not hidden
    end
  end)

  -- Config load
  local config = nil
  if settings.ConfigurationSaving and settings.ConfigurationSaving.Enabled then
    config = loadConfig(settings.ConfigurationSaving.FolderName, settings.ConfigurationSaving.FileName) or {}
    -- Preload flags
    if config.Flags then
      for k, v in pairs(config.Flags) do self.Flags[k] = v end
    end
  end

  -- Window object API
  function window:CreateTab(name, iconId)
    name = name or "Tab"
    local tabBtn = make("TextButton", {
      Size = UDim2.new(1, -0, 0, 34),
      BackgroundColor3 = Color3.fromRGB(0,0,0),
      BackgroundTransparency = 0.7,
      Text = "  "..name,
      Font = Enum.Font.Gotham,
      TextColor3 = YSSHLibrary.Theme.Text,
      TextSize = 14,
      TextXAlignment = Enum.TextXAlignment.Left,
      AutoButtonColor = false,
    }, {
      make("UICorner", {CornerRadius = UDim.new(0, 8)}),
    })

    if iconId and tonumber(iconId) then
      local icon = make("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "rbxassetid://"..tostring(iconId),
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 8, 0.5, -9),
      })
      icon.Parent = tabBtn
      tabBtn.TextXAlignment = Enum.TextXAlignment.Left
      tabBtn.Text = "      "..name
    end

    tabBtn.Parent = tabList

    local page = make("Frame", {
      Name = name,
      Size = UDim2.new(1, -16, 1, -16),
      Position = UDim2.new(0, 8, 0, 8),
      BackgroundTransparency = 1,
      Visible = false,
    }, {
      make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
    })
    page.Parent = pageFolder

    local tabObj = {}

    tabBtn.MouseButton1Click:Connect(function()
      for _, b in ipairs(tabList:GetChildren()) do
        if b:IsA("TextButton") then
          tween(b, TweenInfo.new(0.15), {BackgroundTransparency = 0.7}):Play()
        end
      end
      tween(tabBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
      switchTo(page)
    end)

    -- Switch to first created tab by default
    if #tabList:GetChildren() == 1 then
      tabBtn.BackgroundTransparency = 0.3
      page.Visible = true
    end

    -- Element builders
    local function addCard(height)
      local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = YSSHLibrary.Theme.Bg,
      }, {
        make("UICorner", {CornerRadius = UDim.new(0, 10)}),
        make("UIStroke", {Color = YSSHLibrary.Theme.Stroke, Thickness = 1}),
        make("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}),
      })
      card.Parent = page
      return card
    end

    function tabObj:CreateButton(data)
      data = data or {}
      local card = addCard(44)
      local btn = make("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = YSSHLibrary.Theme.Panel,
        Text = data.Name or "Button",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = YSSHLibrary.Theme.Text,
        AutoButtonColor = false,
      }, {
        make("UICorner", {CornerRadius = UDim.new(0, 8)}),
      })
      btn.Parent = card
      btn.MouseButton1Click:Connect(safeWrap(function()
        if data.Callback then data.Callback() end
      end))
      btn.MouseEnter:Connect(function() tween(btn, TweenInfo.new(0.12), {BackgroundTransparency = 0.1}):Play() end)
      btn.MouseLeave:Connect(function() tween(btn, TweenInfo.new(0.12), {BackgroundTransparency = 0}):Play() end)
      return btn
    end

    function tabObj:CreateToggle(data)
      data = data or {}
      local flag = data.Flag
      local state = (flag and YSSHLibrary.Flags[flag])
        or (data.CurrentValue == true)
        or false

      local card = addCard(50)
      local lbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = data.Name or "Toggle",
        TextColor3 = YSSHLibrary.Theme.Text,
        TextSize = 14,
      })
      lbl.Parent = card

      local sw = make("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -2, 0.5, 0),
        Size = UDim2.new(0, 54, 0, 26),
        BackgroundColor3 = state and YSSHLibrary.Theme.Accent or YSSHLibrary.Theme.Panel,
      }, {
        make("UICorner", {CornerRadius = UDim.new(1, 0)}),
        make("UIStroke", {Color = YSSHLibrary.Theme.Stroke, Thickness = 1}),
      })
      sw.Parent = card

      local knob = make("Frame", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(0, state and 30 or 2, 0, 2),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
      }, {
        make("UICorner", {CornerRadius = UDim.new(1, 0)}),
      })
      knob.Parent = sw

      local function setState(v, fire)
        state = v and true or false
        YSSHLibrary.Flags[flag or (data.Name or "")] = state
        tween(sw, TweenInfo.new(0.15), {BackgroundColor3 = state and YSSHLibrary.Theme.Accent or YSSHLibrary.Theme.Panel}):Play()
        tween(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, state and 30 or 2, 0, 2)}):Play()
        if fire and data.Callback then safeWrap(data.Callback)(state) end
      end

      sw.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
          setState(not state, true)
        end
      end)

      setState(state, false)
      return setmetatable({}, { __index = { Set = setState } })
    end

    function tabObj:CreateSlider(data)
      data = data or {}
      local min, max = (data.Range and data.Range[1]) or 0, (data.Range and data.Range[2]) or 100
      local inc = data.Increment or 1
      local value = math.clamp(data.CurrentValue or min, min, max)
      local suffix = data.Suffix or ""
      local flag = data.Flag

      local card = addCard(64)
      local lbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = (data.Name or "Slider") .. " (" .. tostring(value) .. (suffix ~= "" and (" "..suffix) or "") .. ")",
        TextColor3 = YSSHLibrary.Theme.Text,
        TextSize = 14,
      })
      lbl.Parent = card

      local bar = make("Frame", { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 0, 28), BackgroundColor3 = YSSHLibrary.Theme.Panel }, {
        make("UICorner", {CornerRadius = UDim.new(0, 6)}),
        make("UIStroke", {Color = YSSHLibrary.Theme.Stroke, Thickness = 1}),
      })
      bar.Parent = card

      local fill = make("Frame", { Size = UDim2.new((value-min)/(max-min), 0, 1, 0), BackgroundColor3 = YSSHLibrary.Theme.Accent }, { make("UICorner", {CornerRadius = UDim.new(0, 6)}) })
      fill.Parent = bar

      local dragging = false

      local function setValueFromX(x, fire)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local raw = min + rel * (max - min)
        local snapped = math.clamp(round(raw, inc), min, max)
        value = snapped
        YSSHLibrary.Flags[flag or (data.Name or "")] = value
        lbl.Text = (data.Name or "Slider") .. " (" .. tostring(value) .. (suffix ~= "" and (" "..suffix) or "") .. ")"
        fill.Size = UDim2.new((value-min)/(max-min), 0, 1, 0)
        if fire and data.Callback then safeWrap(data.Callback)(value) end
      end

      bar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
          dragging = true
          setValueFromX(inp.Position.X, true)
        end
      end)

      UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
          setValueFromX(inp.Position.X, true)
        end
      end)

      UserInputService.InputEnded:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
          dragging = false
        end
      end)

      -- initialize
      setValueFromX(bar.AbsolutePosition.X + bar.AbsoluteSize.X * ((value - min) / (max - min)), false)

      return setmetatable({}, { __index = {
        Set = function(_, v) setValueFromX(bar.AbsolutePosition.X + bar.AbsoluteSize.X * ((math.clamp(v, min, max) - min) / (max - min)), true) end
      }})
    end

    function tabObj:CreateDropdown(data)
      data = data or {}
      local options = data.Options or {}
      local current = data.CurrentOption
      local flag = data.Flag

      local card = addCard(44)
      local btn = make("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = YSSHLibrary.Theme.Panel,
        Text = (data.Name or "Dropdown") .. " ▾",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = YSSHLibrary.Theme.Text,
        AutoButtonColor = false,
      }, {
        make("UICorner", {CornerRadius = UDim.new(0, 8)}),
      })
      btn.Parent = card

      local listFrame = make("Frame", {
        Visible = false,
        BackgroundColor3 = YSSHLibrary.Theme.Panel,
        Size = UDim2.new(1, 0, 0, 8 + (#options * 28)),
        Position = UDim2.new(0, 0, 1, 4),
        ZIndex = 5,
      }, {
        make("UICorner", {CornerRadius = UDim.new(0, 8)}),
        make("UIStroke", {Color = YSSHLibrary.Theme.Stroke, Thickness = 1}),
        make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
        make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
      })
      listFrame.Parent = card

      local function applyChoice(choice)
        current = { choice }
        YSSHLibrary.Flags[flag or (data.Name or "")] = choice
        btn.Text = (data.Name or "Dropdown") .. ": " .. tostring(choice)
        if data.Callback then safeWrap(data.Callback)(current) end
      end

      local function rebuild(opts, reset)
        for _, c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        listFrame.Size = UDim2.new(1, 0, 0, 8 + (#opts * 28))
        for _, opt in ipairs(opts) do
          local item = make("TextButton", {
            Size = UDim2.new(1, -0, 0, 24),
            BackgroundTransparency = 1,
            Text = tostring(opt),
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = YSSHLibrary.Theme.Text,
            AutoButtonColor = true,
          })
          item.Parent = listFrame
          item.MouseButton1Click:Connect(function()
            applyChoice(opt)
            listFrame.Visible = false
          end)
        end
        if reset then current = nil; btn.Text = (data.Name or "Dropdown") .. " ▾" end
      end

      btn.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
      end)

      rebuild(options, true)
      if type(current) == "table" and current[1] then applyChoice(current[1]) end

      local api = {}
      function api:Refresh(newOptions, reset)
        options = newOptions or {}
        rebuild(options, reset)
      end
      return api
    end

    return tabObj
  end

  -- Save flags on change (periodic)
  if settings.ConfigurationSaving and settings.ConfigurationSaving.Enabled then
    task.spawn(function()
      while gui.Parent do
        task.wait(2)
        saveConfig(settings.ConfigurationSaving.FolderName, settings.ConfigurationSaving.FileName, { Flags = YSSHLibrary.Flags })
      end
    end)
  end

  return setmetatable(window, { __index = self })
end

return YSSHLibrary
