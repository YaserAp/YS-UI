local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- GUI utama
local ScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
ScreenGui.ResetOnSpawn = false

-- Frame utama
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 250)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.Visible = true
MainFrame.Active = true -- penting untuk drag

-- Title bar
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TitleBar.Active = true

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Text = "YS Script Hub"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18

-- Tombol Minimize
local MinimizeBtn = Instance.new("TextButton", TitleBar)
MinimizeBtn.Size = UDim2.new(0, 30, 1, 0)
MinimizeBtn.Position = UDim2.new(1, -60, 0, 0)
MinimizeBtn.Text = "-"
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(170, 170, 0)

-- Tombol Close
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 30, 1, 0)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)

-- Konten
local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -20, 1, -50)
ContentFrame.Position = UDim2.new(0, 10, 0, 40)
ContentFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

-- Tombol Show UI
local ShowUIButton = Instance.new("TextButton", ScreenGui)
ShowUIButton.Size = UDim2.new(0, 120, 0, 40)
ShowUIButton.AnchorPoint = Vector2.new(0.5, 1) -- titik anchor di bawah tengah
ShowUIButton.Position = UDim2.new(0.5, 0, 0.5, -60) -- pas di atas logo tengah
ShowUIButton.Text = "Show UI"
ShowUIButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ShowUIButton.Visible = false
ShowUIButton.Active = true

-- === Functionalitas ===

-- Close → Hilangin Window, munculin tombol Show UI
CloseBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
	ShowUIButton.Visible = true
end)

-- Show UI → Balikin Window
ShowUIButton.MouseButton1Click:Connect(function()
	MainFrame.Visible = true
	ShowUIButton.Visible = false
end)

-- Minimize → Kecilkan frame, bukan sembunyikan
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
	if minimized then
		MainFrame.Size = UDim2.new(0, 400, 0, 250)
		minimized = false
	else
		MainFrame.Size = UDim2.new(0, 400, 0, 40) -- jadi taskbar mini
		minimized = true
	end
end)

-- Bisa drag tombol Show UI
local dragging = false
local dragInput, mousePos, framePos

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

-- === Drag MainFrame (lewat TitleBar) ===
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
