-- YSUI.lua
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local YSUI = {}

-- Buat Window
function YSUI:CreateWindow(settings)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = settings.Name or "YSUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local Window = Instance.new("Frame")
    Window.Size = UDim2.new(0, 300, 0, 250)
    Window.Position = UDim2.new(0.5, -150, 0.5, -125)
    Window.BackgroundColor3 = Color3.fromRGB(25,25,25)
    Window.Active = true
    Window.Draggable = true
    Window.Parent = ScreenGui

    local Title = Instance.new("TextLabel", Window)
    Title.Size = UDim2.new(1,0,0,30)
    Title.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Title.Text = settings.Title or "YSUI Window"
    Title.TextColor3 = Color3.fromRGB(255,255,255)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18

    -- buat container untuk isi tab
    local Content = Instance.new("Frame", Window)
    Content.Size = UDim2.new(1, -20, 1, -50)
    Content.Position = UDim2.new(0,10,0,40)
    Content.BackgroundTransparency = 1

    -- kasih layout otomatis
    local Layout = Instance.new("UIListLayout", Content)
    Layout.Padding = UDim.new(0, 5)

    local API = {}

    -- contoh API: bikin tombol
    function API:CreateButton(text, callback)
        local btn = Instance.new("TextButton", Content)
        btn.Size = UDim2.new(1,0,0,40)
        btn.Text = text
        btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 16
        btn.MouseButton1Click:Connect(function()
            if callback then callback() end
        end)
        return btn
    end

    -- contoh API: bikin toggle
    function API:CreateToggle(text, default, callback)
        local frame = Instance.new("Frame", Content)
        frame.Size = UDim2.new(1,0,0,40)
        frame.BackgroundColor3 = Color3.fromRGB(40,40,40)

        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0,40,1,0)
        btn.BackgroundColor3 = default and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0)

        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1,-50,1,0)
        label.Position = UDim2.new(0,50,0,0)
        label.BackgroundTransparency = 1
        label.Text = text..": "..(default and "ON" or "OFF")
        label.TextColor3 = Color3.fromRGB(255,255,255)
        label.TextXAlignment = Enum.TextXAlignment.Left

        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.BackgroundColor3 = state and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0)
            label.Text = text..": "..(state and "ON" or "OFF")
            if callback then callback(state) end
        end)

        return frame
    end

    return API
end

return YSUI
