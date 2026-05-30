--[[
    speed.lua – Draggable Speed Bar (Walk & Run Fast)
    • Default: normal speed, GUI hidden until you toggle it.
    • Press "V" to show/hide the speed slider.
    • Drag the green bar horizontally to change speed.
    • Keeps Humanoid.WalkSpeed – looks like normal movement.
    • Cleans up old versions if you re‑run the script.
    • Safe max speed = 50; you can unlock unsafe mode in settings.
]]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- ==================== CLEANUP OLD VERSION ====================
if _G.speedHack then
    -- Destroy GUI
    if _G.speedHack.gui then
        _G.speedHack.gui:Destroy()
    end
    -- Disconnect events
    for _, conn in pairs(_G.speedHack.connections) do
        conn:Disconnect()
    end
    _G.speedHack = nil
    StarterGui:SetCore("SendNotification", {
        Title = "Speed Script",
        Text = "Old version cleared.",
        Duration = 1.5
    })
end

-- ==================== SETTINGS ====================
local maxSafeSpeed = 50        -- keep below 50 to avoid basic speed checks
local allowUnsafe = false      -- set true to allow speeds above 50 (use at own risk)
local initialSpeed = 16        -- typical default walkspeed
local minSpeed = 2
local maxSliderSpeed = allowUnsafe and 200 or maxSafeSpeed

-- ==================== VARIABLES ====================
local gui = nil
local mainFrame = nil
local sliderFrame = nil
local barFrame = nil
local handleButton = nil
local speedLabel = nil
local toggleButton = nil

local dragging = false
local dragStartX = 0
local sliderStartPos = 0
local sliderWidth = 0

local connections = {}
local currentSpeed = initialSpeed
local guiVisible = false

-- ==================== SPEED CONTROL ====================
local function applySpeed(speed)
    speed = math.clamp(speed, minSpeed, maxSliderSpeed)
    currentSpeed = speed
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = speed
        end
    end
end

-- Update slider position and label based on speed
local function updateGUI()
    if not sliderFrame or not handleButton or not speedLabel then return end
    local fraction = (currentSpeed - minSpeed) / (maxSliderSpeed - minSpeed)
    fraction = math.clamp(fraction, 0, 1)
    local maxHandleX = sliderFrame.AbsoluteSize.X - handleButton.AbsoluteSize.X
    handleButton.Position = UDim2.new(fraction, 0, 0, 0)
    speedLabel.Text = string.format("Speed: %d", currentSpeed)
    -- Color code: green -> yellow -> red
    local r = math.clamp((currentSpeed - minSpeed) / (maxSliderSpeed - minSpeed) * 2, 0, 1)
    local g = math.clamp(2 - r, 0, 1)
    barFrame.BackgroundColor3 = Color3.fromRGB(r*255, g*255, 0)
end

-- Move handle based on mouse input
local function updateSliderPosition(input)
    if not dragging or not handleButton or not sliderFrame then return end
    local mousePos = UserInputService:GetMouseLocation()
    local sliderAbsX = sliderFrame.AbsolutePosition.X
    local sliderSizeX = sliderFrame.AbsoluteSize.X
    local handleSizeX = handleButton.AbsoluteSize.X
    local relativeX = mousePos.X - sliderAbsX - handleSizeX/2
    local fraction = math.clamp(relativeX / (sliderSizeX - handleSizeX), 0, 1)
    local newSpeed = math.floor(minSpeed + fraction * (maxSliderSpeed - minSpeed) + 0.5)
    applySpeed(newSpeed)
    updateGUI()
end

-- ==================== BUILD GUI ====================
local function createGUI()
    if gui then gui:Destroy() end
    gui = Instance.new("ScreenGui")
    gui.Name = "SpeedHackGUI"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")
    gui.Enabled = guiVisible

    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 280, 0, 70)
    mainFrame.Position = UDim2.new(0.5, -140, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Text = "SPEED HACK (Drag green bar)"
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 16
    titleLabel.Parent = mainFrame

    sliderFrame = Instance.new("Frame")
    sliderFrame.Name = "SliderFrame"
    sliderFrame.Size = UDim2.new(1, -20, 0, 20)
    sliderFrame.Position = UDim2.new(0, 10, 0, 30)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = mainFrame

    barFrame = Instance.new("Frame")
    barFrame.Name = "BarFrame"
    barFrame.Size = UDim2.new(0, 0, 1, 0)
    barFrame.Position = UDim2.new(0, 0, 0, 0)
    barFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    barFrame.BorderSizePixel = 0
    barFrame.Parent = sliderFrame

    handleButton = Instance.new("TextButton")
    handleButton.Name = "Handle"
    handleButton.Size = UDim2.new(0, 20, 1, 0)
    handleButton.Position = UDim2.new(0, 0, 0, 0)
    handleButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    handleButton.BorderSizePixel = 0
    handleButton.Text = ""
    handleButton.AutoButtonColor = false
    handleButton.Parent = sliderFrame

    speedLabel = Instance.new("TextLabel")
    speedLabel.Name = "SpeedLabel"
    speedLabel.Size = UDim2.new(1, 0, 0, 20)
    speedLabel.Position = UDim2.new(0, 0, 0, 55)
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedLabel.Text = "Speed: " .. currentSpeed
    speedLabel.Font = Enum.Font.SourceSans
    speedLabel.TextSize = 14
    speedLabel.Parent = mainFrame

    -- Toggle button (visible/hidden)
    toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleBtn"
    toggleButton.Size = UDim2.new(0, 30, 0, 30)
    toggleButton.Position = UDim2.new(0, 5, 0, 35)
    toggleButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    toggleButton.Text = "V"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.TextSize = 14
    toggleButton.AutoButtonColor = false
    toggleButton.Parent = nil  -- we'll make a separate toggle button or just use keyboard
    -- We'll use a small toggle button to show/hide the GUI
    -- Actually, we'll just use a keybind, but having a button to hide is nice. I'll add it to top right.
    local hideBtn = Instance.new("TextButton")
    hideBtn.Size = UDim2.new(0, 20, 0, 20)
    hideBtn.Position = UDim2.new(1, -25, 0, 0)
    hideBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    hideBtn.Text = "X"
    hideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    hideBtn.Font = Enum.Font.SourceSansBold
    hideBtn.TextSize = 14
    hideBtn.Parent = mainFrame
    hideBtn.MouseButton1Click:Connect(function()
        guiVisible = false
        gui.Enabled = false
    end)

    -- Dragging functionality for handle
    handleButton.MouseButton1Down:Connect(function()
        dragging = true
        handleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragging then
                dragging = false
                handleButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
    end)

    -- Update on mouse move while dragging
    RunService.RenderStepped:Connect(function()
        if dragging then
            updateSliderPosition()
        end
    end)

    -- Respawn handling: re-apply speed when character respawns
    local charConn = player.CharacterAdded:Connect(function(character)
        applySpeed(currentSpeed)
    end)

    -- Initial apply
    if player.Character then
        applySpeed(currentSpeed)
    end

    -- Store connections for cleanup
    table.insert(connections, charConn)

    -- Update bar width when speed changes
    local function updateBar()
        if barFrame and sliderFrame then
            local frac = math.clamp((currentSpeed - minSpeed) / (maxSliderSpeed - minSpeed), 0, 1)
            local maxWidth = sliderFrame.AbsoluteSize.X - handleButton.AbsoluteSize.X
            barFrame.Size = UDim2.new(0, frac * maxWidth, 1, 0)
        end
    end
    barFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateBar) -- just a rough update
    RunService.RenderStepped:Connect(updateBar)

    updateGUI()
end

-- ==================== TOGGLE GUI VISIBILITY ====================
local function toggleGUI()
    guiVisible = not guiVisible
    if gui then
        gui.Enabled = guiVisible
    end
end

-- Keyboard shortcut: V
local keyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.V then
        toggleGUI()
    end
end)

-- ==================== STARTUP ====================
createGUI()
guiVisible = true  -- show on first run
gui.Enabled = true

-- Save everything for cleanup on re-run
_G.speedHack = {
    gui = gui,
    connections = {keyConn, charConn}  -- charConn is already in connections table
}

StarterGui:SetCore("SendNotification", {
    Title = "Speed Script",
    Text = "Press V to show/hide speed slider. Drag green bar to change speed.",
    Duration = 4
})
