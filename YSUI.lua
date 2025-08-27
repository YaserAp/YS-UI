local ScreenGui = Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui)
local MainFrame = Instance.new("Frame", ScreenGui)
local TitleBar = Instance.new("Frame", MainFrame)
local TitleLabel = Instance.new("TextLabel", TitleBar)
local MinimizeBtn = Instance.new("TextButton", TitleBar)
local CloseBtn = Instance.new("TextButton", TitleBar)
local ContentFrame = Instance.new("Frame", MainFrame)
local ShowUIButton = Instance.new("TextButton", ScreenGui)

-- Styling
ScreenGui.ResetOnSpawn = false

MainFrame.Size = UDim2.new(0, 400, 0, 250)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.Visible = true

TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Text = "YS Script Hub"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18

-- Tombol Minimize
MinimizeBtn.Size = UDim2.new(0, 30, 1, 0)
MinimizeBtn.Position = UDim2.new(1, -60, 0, 0)
MinimizeBtn.Text = "-"
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(170, 170, 0)

-- Tombol Close
CloseBtn.Size = UDim2.new(0, 30, 1, 0)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)

-- Konten
ContentFrame.Size = UDim2.new(1, -20, 1, -50)
ContentFrame.Position = UDim2.new(0, 10, 0, 40)
ContentFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

-- Tombol Show UI
ShowUIButton.Size = UDim2.new(0, 120, 0, 40)
ShowUIButton.Position = UDim2.new(0.5, -60, 0, 0)
ShowUIButton.Text = "Show UI"
ShowUIButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ShowUIButton.Visible = false

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

game:GetService("UserInputService").InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

