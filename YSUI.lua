--copyright BY YSSH--

--[[

  YSSH UI Library (Scrollable Edition)
  - Window tetap berukuran fix (default 640x420), tetapi:
    * Konten tab (kanan) pakai ScrollingFrame + auto CanvasSize
    * Tabbar (kiri) juga ScrollingFrame + auto CanvasSize
  - Drag jendela auto-clamp ke layar
  - UIScale (opsional) untuk menyesuaikan di layar kecil
  - Config saving (flags) jika executor mendukung writefile/isfile/makefolder
  - Dropdown sudah pakai ScrollingFrame internal (tetap)

  Catatan:
  - Kamu bisa ubah ukuran default window di bagian "Main Window Config".
  - Kalau ingin benar-benar resizable (ubah ukuran via drag sudut), tinggal aktifkan
    blok "ResizeHandle" di bawah (sudah disiapkan, default OFF agar konsisten
    dengan "fix size" yang kamu minta).

]]--

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------
-- Basic environment / executor checks
----------------------------------------------------------------

local function isExecutor()
  -- Rough heuristic (tanpa memaksa)
  return (syn or KRNL_LOADED or identifyexecutor or writefile) ~= nil
end

local function safeWrap(fn)
  return function(...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("YSSH Error:", err) end
  end
end

----------------------------------------------------------------
-- Themes
----------------------------------------------------------------

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
    Overlay = Color3.fromRGB(0, 0, 0),
    Shadow = Color3.fromRGB(0, 0, 0),
  },
}

----------------------------------------------------------------
-- Utilities
----------------------------------------------------------------

local function make(className, props, children)
  local obj = Instance.new(className)
  for k, v in pairs(props or {}) do
    obj[k] = v
  end
  for _, child in ipairs(children or {}) do
    child.Parent = obj
  end
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

----------------------------------------------------------------
-- Persistence helpers
----------------------------------------------------------------

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

----------------------------------------------------------------
-- Root
----------------------------------------------------------------

local YSSHLibrary = {
  Flags = {},
  Theme = THEMES.Default
}

----------------------------------------------------------------
-- Notifications (stacked, bottom-right)
----------------------------------------------------------------

function YSSHLibrary:Notify(opts)
  opts = opts or {}
  local title = opts.Title or "Notice"
  local content = opts.Content or ""
  local duration = tonumber(opts.Duration) or 3

  local gui = CoreGui:FindFirstChild("YSSH_Notify") or make("ScreenGui", {
    Name = "YSSH_Notify",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  }, {})
  gui.Parent = CoreGui

  local holder = gui:FindFirstChild("Holder")
  if not holder then
    holder = make("Frame", {
      Name = "Holder",
      AnchorPoint = Vector2.new(1, 1),
      Position = UDim2.new(1, -16, 1, -16),
      Size = UDim2.new(0, 320, 0, 0),
      BackgroundTransparency = 1,
    }, {
      make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Bottom
      }),
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
    make("UIPadding", {
      PaddingTop = UDim.new(0, 10),
      PaddingBottom = UDim.new(0, 10),
      PaddingLeft = UDim.new(0, 10),
      PaddingRight = UDim.new(0, 10)
    }),
  })
  card.Parent = holder

  local titleLbl = make("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = title,
    TextColor3 = self.Theme.Text,
    TextSize = 14,
    AutomaticSize = Enum.AutomaticSize.XY,
    TextXAlignment = Enum.TextXAlignment.Left,
  }, {})
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
  }, {})
  contentLbl.Parent = card

  card.Size = UDim2.new(1, 0, 0, 0)
  tween(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    Size = UDim2.new(1, 0, 0, card.AbsoluteSize.Y + 20)
  }):Play()

  task.spawn(function()
    task.wait(duration)
    local t = tween(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
      BackgroundTransparency = 1
    })
    t:Play(); t.Completed:Wait()
    card:Destroy()
  end)
end

----------------------------------------------------------------
-- Drag helper + clamp-to-screen
----------------------------------------------------------------

local function clampToScreen(frame)
  if not frame or not frame.Parent then return end
  local parent = frame.Parent
  if not parent then return end

  local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
  local guiInset = GuiService:GetGuiInset()
  local insetY = guiInset.Y
  -- Limit so topbar tetap kelihatan
  local minX = -frame.AbsoluteSize.X + 40
  local maxX = vp.X - 40
  local minY = -frame.AbsoluteSize.Y + 40 + insetY
  local maxY = vp.Y - 40

  local pos = frame.Position
  local ox = pos.X.Scale == 0 and pos.X.Offset or 0
  local oy = pos.Y.Scale == 0 and pos.Y.Offset or 0

  ox = math.clamp(ox, minX, maxX)
  oy = math.clamp(oy, minY, maxY)

  frame.Position = UDim2.new(0, ox, 0, oy)
end

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
        if input.UserInputState == Enum.UserInputState.End then
          dragging = false
          clampToScreen(frame)
        end
      end)
    end
  end)

  dragArea.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
      if dragging then update(input) end
    end
  end)
end

----------------------------------------------------------------
-- Window builder
----------------------------------------------------------------

function YSSHLibrary:CreateWindow(settings)
  settings = settings or {}

  if not isExecutor() and not settings.DisableBuildWarnings then
    warn("[YSSH] Running outside exploit environment may break HttpGet/loadstring/CoreGui parenting.")
  end

  local themeKey = settings.Theme or "Default"
  self.Theme = THEMES[themeKey] or THEMES.Default

  ----------------------------------------------------------------
  -- ScreenGui root
  ----------------------------------------------------------------

  local gui = make("ScreenGui", {
    Name = "YSSH_UI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
    IgnoreGuiInset = true,
  }, {})
  gui.Parent = CoreGui

  ----------------------------------------------------------------
  -- Optional: Adaptive UIScale (OFF by default)
  -- Aktifkan dengan settings.AutoScale = true
  ----------------------------------------------------------------

  local uiScale
  if settings.AutoScale then
    uiScale = make("UIScale", { Scale = 1 }, {})
    uiScale.Parent = gui

    local function recalcScale()
      local cam = workspace.CurrentCamera
      if not cam then return end
      local vp = cam.ViewportSize
      -- Skema sederhana: target ketinggian 720 -> scale = vp.Y / 720 (dibatasi)
      local targetH = 720
      local s = math.clamp(vp.Y / targetH, 0.75, 1.25)
      uiScale.Scale = s
    end

    local con
    con = RunService.RenderStepped:Connect(function()
      recalcScale()
      -- cukup sekali tiap 0.5s, hemat
    end)
    task.delay(0.6, function()
      if con then con:Disconnect() end
    end)
    recalcScale()
  end

  ----------------------------------------------------------------
  -- Loading splash (opsional)
  ----------------------------------------------------------------

  if settings.LoadingTitle or settings.LoadingSubtitle then
    local splash = make("Frame", {
      Size = UDim2.new(1,0,1,0),
      BackgroundColor3 = self.Theme.Overlay,
      BackgroundTransparency = 0.2,
    }, {
      make("TextLabel", {
        Text = (settings.LoadingTitle or "Loading"),
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0.5,0,0.5,-12)
      }),
      make("TextLabel", {
        Text = (settings.LoadingSubtitle or ""),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(220,220,220),
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0.5,0,0.5,12)
      }),
    })
    splash.Parent = gui
    task.delay(0.6, function()
      if splash then splash:Destroy() end
    end)
  end

  ----------------------------------------------------------------
  -- Main Window Config (fix size)
  ----------------------------------------------------------------

  local window = {}

  local MAIN_WIDTH = settings.Width or 520
  local MAIN_HEIGHT = settings.Height or 315

  local main = make("Frame", {
    Name = "Main",
    Size = UDim2.new(0, MAIN_WIDTH, 0, MAIN_HEIGHT),
    Position = UDim2.new(0.5, -MAIN_WIDTH//2, 0.5, -MAIN_HEIGHT//2),
    BackgroundColor3 = self.Theme.Bg,
    BorderSizePixel = 0,
  }, {
    make("UICorner", {CornerRadius = UDim.new(0, 12)}),
    make("UIStroke", {Color = self.Theme.Stroke, Thickness = 1}),
    -- drop shadow halus
    make("ImageLabel", {
      Name = "Shadow",
      BackgroundTransparency = 1,
      Image = "rbxassetid://1316045217",
      ImageColor3 = self.Theme.Shadow,
      ImageTransparency = 0.9,
      ScaleType = Enum.ScaleType.Slice,
      SliceCenter = Rect.new(10, 10, 118, 118),
      Size = UDim2.new(1, 40, 1, 40),
      Position = UDim2.new(0, -20, 0, -20),
      ZIndex = 0
    }, {}),
  })
  main.Parent = gui

  ----------------------------------------------------------------
  -- Topbar
  ----------------------------------------------------------------

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
    Size = UDim2.new(1, -120, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = (settings.Name or settings.Title or "YSSH UI"),
    TextColor3 = self.Theme.Text,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
  }, {})
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
    Text = "-",
    TextColor3 = self.Theme.Text,
    TextSize = 14,
    AutoButtonColor = false,
  }, { make("UICorner", {CornerRadius = UDim.new(0, 4)}) })
  minimizeBtn.Parent = topbar

  closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
  end)

  closeBtn.MouseEnter:Connect(function()
    tween(closeBtn, TweenInfo.new(0.1), { BackgroundColor3 = self.Theme.Bad }):Play()
  end)
  closeBtn.MouseLeave:Connect(function()
    tween(closeBtn, TweenInfo.new(0.1), { BackgroundColor3 = self.Theme.Topbar }):Play()
  end)

  minimizeBtn.MouseEnter:Connect(function()
    tween(minimizeBtn, TweenInfo.new(0.1), { BackgroundColor3 = self.Theme.Stroke }):Play()
  end)
  minimizeBtn.MouseLeave:Connect(function()
    tween(minimizeBtn, TweenInfo.new(0.1), { BackgroundColor3 = self.Theme.Topbar }):Play()
  end)

  makeDraggable(main, topbar)
  clampToScreen(main)

  ----------------------------------------------------------------
  -- Left Tabbar (NOW SCROLLABLE)
  ----------------------------------------------------------------

  local TABBAR_WIDTH = 180

  local tabbar = make("Frame", {
    Name = "Tabbar",
    Position = UDim2.new(0, 0, 0, 40),
    Size = UDim2.new(0, TABBAR_WIDTH, 1, -40),
    BackgroundColor3 = self.Theme.Panel,
    BorderSizePixel = 0,
  }, {
    make("UIStroke", {Color = self.Theme.Stroke, Thickness = 1}),
  })
  tabbar.Parent = main

  -- Scrolling container untuk button tab
  local tabScroll = make("ScrollingFrame", {
      Name = "TabScroll",
      BackgroundTransparency = 1,
      Size = UDim2.new(1, 0, 1, 0),
      CanvasSize = UDim2.new(0, 0, 0, 0),
      ScrollBarThickness = 6,
      ScrollBarImageColor3 = Color3.fromRGB(120, 120, 120),
      ScrollingDirection = Enum.ScrollingDirection.Y,
      Active = true,
      BorderSizePixel = 0,
  }, {})

  tabScroll.Parent = tabbar

  local tabList = make("Frame", {
      BackgroundTransparency = 1,
      Size = UDim2.new(1, -16, 0, 0),
      Position = UDim2.new(0, 8, 0, 8),
      AutomaticSize = Enum.AutomaticSize.Y,
  }, {
      make("UIListLayout", { 
          SortOrder = Enum.SortOrder.LayoutOrder, 
          Padding = UDim.new(0, 6) 
      }),
  })
  tabList.Parent = tabScroll

  -- 🔥 Auto-update CanvasSize biar scroll aktif
  tabList.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
      tabScroll.CanvasSize = UDim2.new(0, 0, 0, tabList.UIListLayout.AbsoluteContentSize.Y + 20)
  end)

  -- Auto CanvasSize untuk TabScroll
  local tabListLayout = tabList:FindFirstChildOfClass("UIListLayout")
  local function refreshTabScrollCanvas()
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, tabListLayout.AbsoluteContentSize.Y + 16)
  end
  tabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshTabScrollCanvas)
  refreshTabScrollCanvas()

  ----------------------------------------------------------------
  -- Right Content Area (SCROLLABLE per-page)
  ----------------------------------------------------------------

  local content = make("Frame", {
    Name = "Content",
    Position = UDim2.new(0, TABBAR_WIDTH, 0, 40),
    Size = UDim2.new(1, -TABBAR_WIDTH, 1, -40),
    BackgroundColor3 = self.Theme.Panel,
    BorderSizePixel = 0,
  }, {
    make("UIStroke", {Color = self.Theme.Stroke, Thickness = 1}),
  })
  content.Parent = main

  local pageFolder = make("Folder", {Name = "Pages"}, {})
  pageFolder.Parent = content

  ----------------------------------------------------------------
  -- Minimize handling (height collapse)
  ----------------------------------------------------------------

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
      clampToScreen(main)
    end
  end)

  ----------------------------------------------------------------
  -- Keybind toggle visibility
  ----------------------------------------------------------------

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

  ----------------------------------------------------------------
  -- Config preload
  ----------------------------------------------------------------

  local config = nil
  if settings.ConfigurationSaving and settings.ConfigurationSaving.Enabled then
    config = loadConfig(settings.ConfigurationSaving.FolderName, settings.ConfigurationSaving.FileName) or {}
    if config.Flags then
      for k, v in pairs(config.Flags) do self.Flags[k] = v end
    end
  end

  ----------------------------------------------------------------
  -- Switch page helper
  ----------------------------------------------------------------

  local function switchTo(page)
    for _, p in ipairs(pageFolder:GetChildren()) do
      if p:IsA("ScrollingFrame") or p:IsA("Frame") then
        p.Visible = (p == page)
      end
    end
  end

  ----------------------------------------------------------------
  -- Window API
  ----------------------------------------------------------------

  function window:CreateTab(name, iconId)
    name = name or "Tab"

    local tabBtn = make("TextButton", {
      Name = "TabButton",
      Size = UDim2.new(1, 0, 0, 34),
      BackgroundColor3 = Color3.fromRGB(0,0,0),
      BackgroundTransparency = 0.7,
      Text = "",
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
        Name = "Icon",
        BackgroundTransparency = 1,
        Image = "rbxassetid://"..tostring(iconId),
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 12, 0.5, -9),
      }, {})
      icon.Parent = tabBtn

      local label = make("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -42, 1, 0),
        Position = UDim2.new(0, 40, 0, 0),
        Font = Enum.Font.Gotham,
        Text = name,
        TextColor3 = YSSHLibrary.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
      }, {})
      label.Parent = tabBtn
    else
      tabBtn.Text = "    "..name
    end

    tabBtn.Parent = tabList
    refreshTabScrollCanvas()

    -- Page untuk tab (SCROLLABLE)
    local page = make("ScrollingFrame", {
      Name = name,
      Size = UDim2.new(1, -16, 1, -16),
      Position = UDim2.new(0, 8, 0, 8),
      BackgroundTransparency = 1,
      Visible = false,
      BorderSizePixel = 0,
      ScrollBarThickness = 6,
      ScrollBarImageColor3 = Color3.fromRGB(120,120,120),
      CanvasSize = UDim2.new(0,0,0,0),
      ScrollingDirection = Enum.ScrollingDirection.Y,
      Active = true,
    }, {
      make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
    })
    page.Parent = pageFolder

    -- Auto CanvasSize halaman
    local layout = page:FindFirstChildOfClass("UIListLayout")
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
      page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
    end)

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

    -- Switch default ke tab pertama yg dibuat
    local btnCount = 0
    for _, b in ipairs(tabList:GetChildren()) do
      if b:IsA("TextButton") then btnCount += 1 end
    end
    if btnCount == 1 then
      tabBtn.BackgroundTransparency = 0.3
      page.Visible = true
    end

    ----------------------------------------------------------------
    -- Element builders
    ----------------------------------------------------------------

    local function addCard(height)
      local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = YSSHLibrary.Theme.Bg,
      }, {
        make("UICorner", {CornerRadius = UDim.new(0, 10)}),
        make("UIStroke", {Color = YSSHLibrary.Theme.Stroke, Thickness = 1}),
        make("UIPadding", {
          PaddingTop = UDim.new(0, 10),
          PaddingBottom = UDim.new(0, 10),
          PaddingLeft = UDim.new(0, 12),
          PaddingRight = UDim.new(0, 12)
        }),
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

      btn.MouseEnter:Connect(function()
        tween(btn, TweenInfo.new(0.12), {BackgroundTransparency = 0.1}):Play()
      end)
      btn.MouseLeave:Connect(function()
        tween(btn, TweenInfo.new(0.12), {BackgroundTransparency = 0}):Play()
      end)

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
      }, {})
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
      }, {})
      lbl.Parent = card

      local bar = make("Frame", {
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 0, 28),
        BackgroundColor3 = YSSHLibrary.Theme.Panel
      }, {
        make("UICorner", {CornerRadius = UDim.new(0, 6)}),
        make("UIStroke", {Color = YSSHLibrary.Theme.Stroke, Thickness = 1}),
      })
      bar.Parent = card

      local fill = make("Frame", {
        Size = UDim2.new((value-min)/(max-min), 0, 1, 0),
        BackgroundColor3 = YSSHLibrary.Theme.Accent
      }, {
        make("UICorner", {CornerRadius = UDim.new(0, 6)})
      })
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

      -- initialize posisi fill
      setValueFromX(bar.AbsolutePosition.X + bar.AbsoluteSize.X * ((value - min) / (max - min)), false)

      return setmetatable({}, {
        __index = {
          Set = function(_, v)
            setValueFromX(bar.AbsolutePosition.X + bar.AbsoluteSize.X * ((math.clamp(v, min, max) - min) / (max - min)), true)
          end
        }
      })
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
        TextColor3 = YSSHLibrary.Theme.SubText, -- placeholder awal
        AutoButtonColor = false,
      }, {
        make("UICorner", {CornerRadius = UDim.new(0, 8)}),
      })
      btn.Parent = card

      local listFrame = make("ScrollingFrame", {
        Visible = false,
        BackgroundColor3 = Color3.fromRGB(35, 35, 40),
        Size = UDim2.new(1, 0, 0, 150),
        Position = UDim2.new(0, 0, 1, 4),
        ZIndex = 100,
        BorderSizePixel = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollingEnabled = true,
        Active = true,
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(120,120,120),
      }, {
        make("UICorner", {CornerRadius = UDim.new(0, 8)}),
        make("UIStroke", {Color = YSSHLibrary.Theme.Stroke, Thickness = 1}),
        make("UIPadding", {
          PaddingTop = UDim.new(0, 4),
          PaddingBottom = UDim.new(0, 4),
          PaddingLeft = UDim.new(0, 6),
          PaddingRight = UDim.new(0, 6),
        }),
      })
      listFrame.Parent = card

      local layout = make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4)
      }, {})
      layout.Parent = listFrame

      layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local pad = listFrame:FindFirstChildOfClass("UIPadding")
        local extra = 0
        if pad then
          extra = pad.PaddingTop.Offset + pad.PaddingBottom.Offset
        end
        listFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + extra)
      end)

      local function applyChoice(choice)
        current = { choice }
        YSSHLibrary.Flags[flag or (data.Name or "")] = choice
        btn.Text = (data.Name or "Dropdown") .. ": " .. tostring(choice)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        if data.Callback then safeWrap(data.Callback)(current) end
      end

      local function rebuild(opts, reset)
        for _, c in ipairs(listFrame:GetChildren()) do
          if c:IsA("TextButton") then c:Destroy() end
        end

        for _, opt in ipairs(opts) do
          local item = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 0,
            BackgroundColor3 = Color3.fromRGB(45, 45, 55),
            Text = tostring(opt),
            Font = Enum.Font.GothamSemibold,
            TextSize = 14,
            TextColor3 = YSSHLibrary.Theme.Text,
            AutoButtonColor = true,
            ZIndex = 100,
            TextXAlignment = Enum.TextXAlignment.Left,
          }, {
            make("UICorner", {CornerRadius = UDim.new(0, 6)}),
            make("UIStroke", {Color = Color3.fromRGB(80, 80, 90), Thickness = 1}),
            make("UIPadding", { PaddingLeft = UDim.new(0, 8) })
          })
          item.Parent = listFrame

          item.MouseEnter:Connect(function()
            item.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
            item.TextColor3 = YSSHLibrary.Theme.Accent
          end)
          item.MouseLeave:Connect(function()
            item.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            item.TextColor3 = YSSHLibrary.Theme.Text
          end)

          item.MouseButton1Click:Connect(function()
            applyChoice(opt)
            listFrame.Visible = false
          end)
        end

        if reset then
          current = nil
          btn.Text = (data.Name or "Dropdown") .. " ▾"
          btn.TextColor3 = YSSHLibrary.Theme.SubText
        end
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

    ----------------------------------------------------------------
    -- Bonus: Label, Paragraph, Separator, Keybind, Input, etc.
    -- (Disediakan agar mudah menambah komponen & memperbanyak baris UI)
    ----------------------------------------------------------------

    function tabObj:CreateLabel(data)
      data = data or {}
      local text = data.Text or "Label"
      local card = addCard(36)
      local lbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Text = text,
        TextColor3 = YSSHLibrary.Theme.Text,
        TextSize = 14,
      }, {})
      lbl.Parent = card
      return {
        Set = function(_, t) lbl.Text = t end
      }
    end

    function tabObj:CreateParagraph(data)
      data = data or {}
      local title = data.Title or "Title"
      local body = data.Content or "Content"
      local card = addCard(96)

      local tl = make("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 18),
        Text = title,
        TextSize = 14,
        TextColor3 = YSSHLibrary.Theme.Text,
      }, {})
      tl.Parent = card

      local bd = make("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 1, -22),
        Position = UDim2.new(0, 0, 0, 22),
        Text = body,
        TextSize = 13,
        TextColor3 = YSSHLibrary.Theme.SubText,
      }, {})
      bd.Parent = card

      return {
        Set = function(_, t) bd.Text = t end
      }
    end

    function tabObj:CreateSeparator()
      local card = addCard(14)
      local line = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, -8, 0, 2),
        BackgroundColor3 = YSSHLibrary.Theme.Stroke,
      }, {
        make("UICorner", {CornerRadius = UDim.new(0, 1)})
      })
      line.Parent = card
      return line
    end

    function tabObj:CreateInput(data)
      data = data or {}
      local placeholder = data.Placeholder or "Type here..."
      local default = data.Default or ""
      local flag = data.Flag

      local card = addCard(50)
      local box = make("TextBox", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = YSSHLibrary.Theme.Panel,
        Font = Enum.Font.Gotham,
        Text = default ~= "" and default or "",
        PlaceholderText = placeholder,
        TextSize = 14,
        TextColor3 = YSSHLibrary.Theme.Text,
        PlaceholderColor3 = YSSHLibrary.Theme.SubText,
        ClearTextOnFocus = false,
      }, {
        make("UICorner", {CornerRadius = UDim.new(0, 8)}),
        make("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}),
        make("UIStroke", {Color = YSSHLibrary.Theme.Stroke, Thickness = 1}),
      })
      box.Parent = card

      local function commit(text)
        YSSHLibrary.Flags[flag or (data.Name or "Input")] = text
        if data.Callback then safeWrap(data.Callback)(text) end
      end

      box.FocusLost:Connect(function(enterPressed)
        commit(box.Text)
      end)

      return {
        Set = function(_, t)
          box.Text = t
          commit(t)
        end,
        Get = function()
          return box.Text
        end
      }
    end

    function tabObj:CreateKeybind(data)
      data = data or {}
      local titleText = data.Name or "Keybind"
      local defKey = getKeyCodeFromString(data.Default or "None")
      local flag = data.Flag

      local card = addCard(50)
      local lbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -120, 1, 0),
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = titleText,
        TextColor3 = YSSHLibrary.Theme.Text,
        TextSize = 14,
      }, {})
      lbl.Parent = card

      local btn = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -2, 0.5, 0),
        Size = UDim2.new(0, 108, 0, 26),
        BackgroundColor3 = YSSHLibrary.Theme.Panel,
        Font = Enum.Font.Gotham,
        Text = defKey ~= Enum.KeyCode.None and defKey.Name or "Unbound",
        TextColor3 = YSSHLibrary.Theme.Text,
        TextSize = 14,
        AutoButtonColor = false,
      }, {
        make("UICorner", {CornerRadius = UDim.new(0, 8)}),
        make("UIStroke", {Color = YSSHLibrary.Theme.Stroke, Thickness = 1}),
      })
      btn.Parent = card

      local currentKey = defKey
      YSSHLibrary.Flags[flag or titleText] = currentKey.Name

      local listening = false
      btn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        btn.Text = "Press a key..."
        local con
        con = UserInputService.InputBegan:Connect(function(inp, gpe)
          if gpe then return end
          if inp.UserInputType == Enum.UserInputType.Keyboard then
            currentKey = inp.KeyCode
            btn.Text = currentKey.Name
            listening = false
            if con then con:Disconnect() end
            YSSHLibrary.Flags[flag or titleText] = currentKey.Name
            if data.Callback then safeWrap(data.Callback)(currentKey) end
          end
        end)
      end)

      return {
        Set = function(_, k)
          currentKey = getKeyCodeFromString(k)
          btn.Text = currentKey.Name
          YSSHLibrary.Flags[flag or titleText] = currentKey.Name
          if data.Callback then safeWrap(data.Callback)(currentKey) end
        end,
        Get = function()
          return currentKey
        end
      }
    end

    function tabObj:CreateCheckbox(data)
      data = data or {}
      local flag = data.Flag
      local state = (flag and YSSHLibrary.Flags[flag]) or (data.CurrentValue == true) or false

      local card = addCard(44)

      local box = make("TextButton", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(0, 2, 0.5, -11),
        BackgroundColor3 = YSSHLibrary.Theme.Panel,
        Text = state and "✓" or "",
        Font = Enum.Font.GothamBold,
        TextColor3 = YSSHLibrary.Theme.Text,
        TextSize = 16,
        AutoButtonColor = false,
      }, {
        make("UICorner", {CornerRadius = UDim.new(0, 6)}),
        make("UIStroke", {Color = YSSHLibrary.Theme.Stroke, Thickness = 1}),
      })
      box.Parent = card

      local lbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(1, -36, 1, 0),
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = data.Name or "Checkbox",
        TextColor3 = YSSHLibrary.Theme.Text,
        TextSize = 14,
      }, {})
      lbl.Parent = card

      local function setState(v, fire)
        state = v and true or false
        box.Text = state and "✓" or ""
        YSSHLibrary.Flags[flag or (data.Name or "Checkbox")] = state
        if fire and data.Callback then safeWrap(data.Callback)(state) end
      end

      box.MouseButton1Click:Connect(function()
        setState(not state, true)
      end)

      setState(state, false)
      return setmetatable({}, { __index = { Set = setState } })
    end

    function tabObj:CreateDropdownMulti(data)
      -- Dropdown multi pilihan (contoh tambahan)
      data = data or {}
      local options = data.Options or {}
      local selected = {}  -- set (string -> true)
      local flag = data.Flag

      local function selectionList()
        local arr = {}
        for k in pairs(selected) do table.insert(arr, k) end
        table.sort(arr)
        return arr
      end

      local card = addCard(60)
      local btn = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = YSSHLibrary.Theme.Panel,
        Text = (data.Name or "Multi Select") .. " ▾",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = YSSHLibrary.Theme.SubText,
        AutoButtonColor = false,
      }, {
        make("UICorner", {CornerRadius = UDim.new(0, 8)}),
      })
      btn.Parent = card

      local picked = make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 34),
        Size = UDim2.new(1, 0, 0, 22),
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "None selected",
        TextColor3 = YSSHLibrary.Theme.SubText,
        TextSize = 13,
      }, {})
      picked.Parent = card

      local listFrame = make("ScrollingFrame", {
        Visible = false,
        BackgroundColor3 = Color3.fromRGB(35, 35, 40),
        Size = UDim2.new(1, 0, 0, 180),
        Position = UDim2.new(0, 0, 0, 60),
        ZIndex = 100,
        BorderSizePixel = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Active = true,
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(120,120,120),
      }, {
        make("UICorner", {CornerRadius = UDim.new(0, 8)}),
        make("UIStroke", {Color = YSSHLibrary.Theme.Stroke, Thickness = 1}),
        make("UIPadding", {
          PaddingTop = UDim.new(0, 6),
          PaddingBottom = UDim.new(0, 6),
          PaddingLeft = UDim.new(0, 6),
          PaddingRight = UDim.new(0, 6),
        }),
      })
      listFrame.Parent = card

      local layout = make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6)
      }, {})
      layout.Parent = listFrame

      local function refreshPickedLabel()
        local arr = selectionList()
        if #arr == 0 then
          picked.Text = "None selected"
          picked.TextColor3 = YSSHLibrary.Theme.SubText
        else
          picked.Text = table.concat(arr, ", ")
          picked.TextColor3 = YSSHLibrary.Theme.Text
        end
      end

      layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local pad = listFrame:FindFirstChildOfClass("UIPadding")
        local extra = 0
        if pad then
          extra = pad.PaddingTop.Offset + pad.PaddingBottom.Offset
        end
        listFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + extra)
      end)

      local function rebuild(opts)
        for _, c in ipairs(listFrame:GetChildren()) do
          if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in ipairs(opts) do
          local item = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 0,
            BackgroundColor3 = Color3.fromRGB(45, 45, 55),
            Text = tostring(opt),
            Font = Enum.Font.GothamSemibold,
            TextSize = 14,
            TextColor3 = YSSHLibrary.Theme.Text,
            AutoButtonColor = true,
            ZIndex = 100,
            TextXAlignment = Enum.TextXAlignment.Left,
          }, {
            make("UICorner", {CornerRadius = UDim.new(0, 6)}),
            make("UIStroke", {Color = Color3.fromRGB(80, 80, 90), Thickness = 1}),
            make("UIPadding", { PaddingLeft = UDim.new(0, 8) })
          })
          item.Parent = listFrame

          local pickedIcon = make("TextLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.new(0, 18, 0, 18),
            Text = "",
            TextColor3 = YSSHLibrary.Theme.Good,
            TextSize = 18,
            Font = Enum.Font.GothamBold,
          }, {})
          pickedIcon.Parent = item

          local function setVisual()
            if selected[opt] then
              item.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
              pickedIcon.Text = "✓"
            else
              item.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
              pickedIcon.Text = ""
            end
          end
          setVisual()

          item.MouseEnter:Connect(function()
            if not selected[opt] then
              item.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            end
          end)
          item.MouseLeave:Connect(function()
            setVisual()
          end)

          item.MouseButton1Click:Connect(function()
            selected[opt] = not selected[opt]
            setVisual()
            refreshPickedLabel()
            local arr = selectionList()
            YSSHLibrary.Flags[flag or (data.Name or "Multi")] = arr
            if data.Callback then safeWrap(data.Callback)(arr) end
          end)
        end
      end

      btn.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
      end)

      rebuild(options)
      refreshPickedLabel()

      return {
        SetSelected = function(_, list)
          selected = {}
          if typeof(list) == "table" then
            for _, v in ipairs(list) do selected[v] = true end
          end
          rebuild(options)
          refreshPickedLabel()
        end,
        Refresh = function(_, newOpts)
          options = newOpts or {}
          rebuild(options)
          refreshPickedLabel()
        end
      }
    end

    return tabObj
  end

  ----------------------------------------------------------------
  -- Periodic config save
  ----------------------------------------------------------------

  if settings.ConfigurationSaving and settings.ConfigurationSaving.Enabled then
    task.spawn(function()
      while gui.Parent do
        task.wait(2)
        saveConfig(settings.ConfigurationSaving.FolderName, settings.ConfigurationSaving.FileName, {
          Flags = YSSHLibrary.Flags
        })
      end
    end)
  end

  ----------------------------------------------------------------
  -- OPTIONAL: Resize handle (DISABLED to keep fixed size)
  -- Aktifkan dengan mengubah ENABLE_RESIZE ke true jika kamu ingin bisa drag ukuran window.
  ----------------------------------------------------------------

  local ENABLE_RESIZE = false
  if ENABLE_RESIZE then
    local handle = make("Frame", {
      AnchorPoint = Vector2.new(1, 1),
      Position = UDim2.new(1, -4, 1, -4),
      Size = UDim2.new(0, 12, 0, 12),
      BackgroundColor3 = self.Theme.Stroke,
    }, { make("UICorner", {CornerRadius = UDim.new(0, 3)}) })
    handle.Parent = main
    handle.Active = true

    local resizing = false
    local startPos, startSize, startInput
    handle.InputBegan:Connect(function(inp)
      if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = true
        startInput = inp
        startPos = UserInputService:GetMouseLocation()
        startSize = main.Size
        inp.Changed:Connect(function()
          if inp.UserInputState == Enum.UserInputState.End then
            resizing = false
            clampToScreen(main)
          end
        end)
      end
    end)

    UserInputService.InputChanged:Connect(function(inp)
      if resizing and (inp == startInput or inp.UserInputType == Enum.UserInputType.MouseMovement) then
        local cur = UserInputService:GetMouseLocation()
        local dx = cur.X - startPos.X
        local dy = cur.Y - startPos.Y
        local nw = math.max(480, startSize.X.Offset + dx)
        local nh = math.max(320, startSize.Y.Offset + dy)
        main.Size = UDim2.new(0, nw, 0, nh)
      end
    end)
  end

  ----------------------------------------------------------------
  -- Return window (inherit library methods)
  ----------------------------------------------------------------

  return setmetatable(window, { __index = self })
end

----------------------------------------------------------------
-- Module return
----------------------------------------------------------------

return YSSHLibrary


