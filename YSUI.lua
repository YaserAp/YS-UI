-- YS UI System (Update with Minimize + Draggable Show UI)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hapus UI lama kalau ada
if playerGui:FindFirstChild("YS_UI") then
    playerGui.YS_UI:Destroy()
end

-- Buat ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "YS_UI"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

-- Window Utama
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 250)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
titleBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.BackgroundTransparency = 1
title.Text = "YS Script Hub"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = titleBar

-- Content frame
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 1, -50)
contentFrame.Position = UDim2.new(0, 10, 0, 40)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Contoh button
local testButton = Instance.new("TextButton")
testButton.Size = UDim2.new(1, 0, 0, 40)
testButton.Position = UDim2.new(0, 0, 0, 0)
testButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
testButton.Text = "Test Button"
testButton.TextColor3 = Color3.new(1, 1, 1)
testButton.Parent = contentFrame

-- Tombol kontrol (Hide, Minimize, Close)
local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 30, 0, 30)
hideBtn.Position = UDim2.new(1, -90, 0, 0)
hideBtn.Text = "H"
hideBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
hideBtn.TextColor3 = Color3.new(1,1,1)
hideBtn.Parent = titleBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -60, 0, 0)
minimizeBtn.Text = "-"
minimizeBtn.BackgroundColor3 = Color3.fromRGB(140, 140, 0)
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.Text = "X"
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Parent = titleBar

-- Tombol Show UI (draggable)
local showBtn = Instance.new("TextButton")
showBtn.Size = UDim2.new(0, 100, 0, 40)
showBtn.Position = UDim2.new(0.5, -50, 0, 10) -- atas tengah
showBtn.Text = "Show UI"
showBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
showBtn.TextColor3 = Color3.new(1, 1, 1)
showBtn.Visible = false
showBtn.Parent = screenGui

-- Fungsi tombol
hideBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    showBtn.Visible = true
end)

minimizeBtn.MouseButton1Click:Connect(function()
    contentFrame.Visible = not contentFrame.Visible
end)

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    showBtn.Visible = true
end)

showBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    showBtn.Visible = false
end)

-- Fungsi draggable untuk Show UI
local dragging = false
local dragInput, mousePos, framePos

local function update(input)
    local delta = input.Position - mousePos
    showBtn.Position = UDim2.new(
        framePos.X.Scale, framePos.X.Offset + delta.X,
        framePos.Y.Scale, framePos.Y.Offset + delta.Y
    )
end

showBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = showBtn.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

showBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)
