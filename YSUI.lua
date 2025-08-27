local YSSHLibrary = {}
YSSHLibrary.Flags = {}

-- Window
function YSSHLibrary:CreateWindow(settings)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "YSUI"
    ScreenGui.Parent = game.CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 600, 0, 350)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -175)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local Topbar = Instance.new("Frame")
    Topbar.Size = UDim2.new(1, 0, 0, 30)
    Topbar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Topbar.BorderSizePixel = 0
    Topbar.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Text = settings.Name or "YSUI"
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextSize = 16
    Title.Parent = Topbar

    -- Tombol Minimize
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Text = "-"
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.TextSize = 18
    MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
    MinimizeButton.Position = UDim2.new(1, -60, 0, 0)
    MinimizeButton.BackgroundTransparency = 1
    MinimizeButton.TextColor3 = Color3.fromRGB(200,200,200)
    MinimizeButton.Parent = Topbar

    local isMinimized = false
    MinimizeButton.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child ~= Topbar then
                child.Visible = not isMinimized
            end
        end
    end)

    -- Tombol Close
    local CloseButton = Instance.new("TextButton")
    CloseButton.Text = "X"
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 18
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -30, 0, 0)
    CloseButton.BackgroundTransparency = 1
    CloseButton.TextColor3 = Color3.fromRGB(255,100,100)
    CloseButton.Parent = Topbar
    CloseButton.MouseButton1Click:Connect(function()
        MainFrame:Destroy()
    end)

    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 150, 1, -30)
    Sidebar.Position = UDim2.new(0, 0, 0, 30)
    Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local UIList = Instance.new("UIListLayout", Sidebar)
    UIList.SortOrder = Enum.SortOrder.LayoutOrder
    UIList.Padding = UDim.new(0, 5)

    -- TabContainer
    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(1, -150, 1, -30)
    TabContainer.Position = UDim2.new(0, 150, 0, 30)
    TabContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame

    local window = {}
    window.Tabs = {}

    -- CreateTab
    function window:CreateTab(name, icon)
        local TabButton = Instance.new("TextButton")
        TabButton.Text = name
        TabButton.Size = UDim2.new(1, -10, 0, 30)
        TabButton.BackgroundTransparency = 1
        TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.TextSize = 16
        TabButton.Parent = Sidebar

        local tab = {}
        tab.Container = Instance.new("Frame")
        tab.Container.Size = UDim2.new(1, 0, 1, 0)
        tab.Container.Visible = false
        tab.Container.Parent = TabContainer

        local UIList2 = Instance.new("UIListLayout", tab.Container)
        UIList2.Padding = UDim.new(0, 5)

        TabButton.MouseButton1Click:Connect(function()
            for _, t in ipairs(window.Tabs) do
                t.Container.Visible = false
            end
            tab.Container.Visible = true
        end)

        -- Button
        function tab:CreateButton(data)
            local button = Instance.new("TextButton")
            button.Text = data.Name
            button.Size = UDim2.new(0, 200, 0, 30)
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.Font = Enum.Font.Gotham
            button.TextSize = 14
            button.Parent = tab.Container
            button.MouseButton1Click:Connect(data.Callback)
            return button
        end

        -- Toggle
        function tab:CreateToggle(data)
            local toggle = Instance.new("TextButton")
            toggle.Text = "[ ] "..data.Name
            toggle.Size = UDim2.new(0, 200, 0, 30)
            toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
            toggle.Font = Enum.Font.Gotham
            toggle.TextSize = 14
            toggle.Parent = tab.Container

            local state = data.CurrentValue or false
            local function update()
                toggle.Text = (state and "[✔] " or "[ ] ")..data.Name
            end
            update()

            toggle.MouseButton1Click:Connect(function()
                state = not state
                update()
                if data.Callback then data.Callback(state) end
            end)

            return toggle
        end

        -- Slider
        function tab:CreateSlider(data)
            local sliderFrame = Instance.new("Frame")
            sliderFrame.Size = UDim2.new(0, 200, 0, 40)
            sliderFrame.BackgroundTransparency = 1
            sliderFrame.Parent = tab.Container

            local label = Instance.new("TextLabel")
            label.Text = data.Name..": "..data.CurrentValue..(data.Suffix or "")
            label.Size = UDim2.new(1, 0, 0, 20)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(255,255,255)
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.Parent = sliderFrame

            local slider = Instance.new("TextButton")
            slider.Size = UDim2.new(1, 0, 0, 15)
            slider.Position = UDim2.new(0, 0, 0, 20)
            slider.BackgroundColor3 = Color3.fromRGB(80,80,80)
            slider.Text = ""
            slider.Parent = sliderFrame

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((data.CurrentValue-data.Range[1])/(data.Range[2]-data.Range[1]), 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(0,170,255)
            fill.BorderSizePixel = 0
            fill.Parent = slider

            local dragging = false
            slider.MouseButton1Down:Connect(function()
                dragging = true
            end)
            game:GetService("UserInputService").InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            game:GetService("RunService").RenderStepped:Connect(function()
                if dragging then
                    local mouse = game:GetService("UserInputService"):GetMouseLocation().X
                    local rel = math.clamp((mouse - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                    local value = math.floor(data.Range[1] + (data.Range[2]-data.Range[1]) * rel)
                    label.Text = data.Name..": "..value..(data.Suffix or "")
                    fill.Size = UDim2.new(rel,0,1,0)
                    if data.Callback then data.Callback(value) end
                end
            end)
        end

        -- Dropdown
        function tab:CreateDropdown(data)
            local dropdown = Instance.new("TextButton")
            dropdown.Text = data.Name.." ▼"
            dropdown.Size = UDim2.new(0, 200, 0, 30)
            dropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            dropdown.TextColor3 = Color3.fromRGB(255,255,255)
            dropdown.Font = Enum.Font.Gotham
            dropdown.TextSize = 14
            dropdown.Parent = tab.Container

            local listFrame = Instance.new("Frame")
            listFrame.Size = UDim2.new(0, 200, 0, 0)
            listFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
            listFrame.ClipsDescendants = true
            listFrame.Parent = tab.Container

            local layout = Instance.new("UIListLayout", listFrame)

            local expanded = false
            dropdown.MouseButton1Click:Connect(function()
                expanded = not expanded
                listFrame.Size = expanded and UDim2.new(0,200,0,#data.Options*25) or UDim2.new(0,200,0,0)
            end)

            for _,opt in ipairs(data.Options) do
                local btn = Instance.new("TextButton")
                btn.Text = opt
                btn.Size = UDim2.new(1,0,0,25)
                btn.BackgroundTransparency = 1
                btn.TextColor3 = Color3.fromRGB(255,255,255)
                btn.Parent = listFrame
                btn.MouseButton1Click:Connect(function()
                    if data.Callback then data.Callback({opt}) end
                end)
            end

            return dropdown
        end

        table.insert(window.Tabs, tab)
        return tab
    end

    return window
end

-- Notify
function YSSHLibrary:Notify(data)
    local msg = Instance.new("Hint")
    msg.Text = data.Title.." | "..data.Content
    msg.Parent = game.CoreGui
    task.delay(data.Duration or 3, function() msg:Destroy() end)
end

return YSSHLibrary
