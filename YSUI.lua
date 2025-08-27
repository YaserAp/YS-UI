--[[ 
YS Custom Hub (Modifikasi dari Rayfield)
Sudah dihapus semua yang berhubungan dengan Rayfield
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- GUI utama
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YS_CustomHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame utama
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 420, 0, 260)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 40, 55) -- biru abu modern
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 30, 45)
TitleBar.Active = true
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Text = "YS Custom Hub"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Tombol minimize
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 1, 0)
MinimizeBtn.Position = UDim2.new(1, -60, 0, 0)
MinimizeBtn.Text = "-"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 18
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
MinimizeBtn.Parent = TitleBar

-- Tombol close
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 1, 0)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Parent = TitleBar

-- Konten
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 1, -50)
ContentFrame.Position = UDim2.new(0, 10, 0, 40)
ContentFrame.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
ContentFrame.Parent = MainFrame

local ContentLabel = Instance.new("TextLabel")
ContentLabel.Size = UDim2.new(1, 0, 1, 0)
ContentLabel.BackgroundTransparency = 1
ContentLabel.Text = "Selamat datang di YS Custom Hub!"
ContentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ContentLabel.Font = Enum.Font.Gotham
ContentLabel.TextSize = 16
ContentLabel.Parent = ContentFrame

-- Tombol Show UI
local ShowUIButton = Instance.new("TextButton")
ShowUIButton.Size = UDim2.new(0, 120, 0, 40)
ShowUIButton.AnchorPoint = Vector2.new(0.5, 0)
ShowUIButton.Position = UDim2.new(0.5, 0, 0.5, -100) -- tepat di atas logo tengah
ShowUIButton.Text = "Show UI"
ShowUIButton.Font = Enum.Font.GothamBold
ShowUIButton.TextSize = 16
ShowUIButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ShowUIButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
ShowUIButton.Visible = false
ShowUIButton.Active = true
ShowUIButton.Parent = ScreenGui

-- === Functionalitas ===

-- Close
CloseBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
	ShowUIButton.Visible = true
end)

-- Show UI
ShowUIButton.MouseButton1Click:Connect(function()
	MainFrame.Visible = true
	ShowUIButton.Visible = false
end)

-- Minimize
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
	if minimized then
		MainFrame.Size = UDim2.new(0, 420, 0, 260)
		minimized = false
	else
		MainFrame.Size = UDim2.new(0, 420, 0, 40)
		minimized = true
	end
end)

-- Drag Show UI
local dragging = false
local mousePos, framePos

ShowUIButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		mousePos = input.Position
		framePos = ShowUIButton.Position
	end
end)

ShowUIButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
		local delta = input.Position - mousePos
		ShowUIButton.Position = UDim2.new(
			framePos.X.Scale, framePos.X.Offset + delta.X,
			framePos.Y.Scale, framePos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

-- Drag MainFrame (via TitleBar)
local frameDragging = false
local frameMousePos, frameStartPos

TitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		frameDragging = true
		frameMousePos = input.Position
		frameStartPos = MainFrame.Position
	end
end)

TitleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and frameDragging then
		local delta = input.Position - frameMousePos
		MainFrame.Position = UDim2.new(
			frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
			frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		frameDragging = false
	end
end)
