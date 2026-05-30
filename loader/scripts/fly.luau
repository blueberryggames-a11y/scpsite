--[[
   Stealth Hover GUI v4
   - Enabled/Disabled button (RED when off, GREEN when on)
   - Slider updates speed instantly (even mid‑flight)
   - All original stealth measures retained
   - Only the top‑right grip box moves the window
   - Automatically removes old GUI duplicates
--]]

local player = game:GetService("Players").LocalPlayer
if not player then warn("Client only.") return end

local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

local VEL_NAME = "AirResistance"
local GYRO_NAME = "Stabilizer"
local V_SPEED = 25
local MAX_FORCE = Vector3.new(4000, 25000, 4000)

local H_SPEED = 28         -- current horizontal speed, updated instantly by slider
local flying = false
local bv, bg, heartbeatConn
local gui, speedLabel, mainFrame

-- //////////////////// Flight Functions ////////////////////
local function startFlight()
    if bv or bg then return end
    bv = Instance.new("BodyVelocity")
    bv.Name = VEL_NAME
    bv.MaxForce = MAX_FORCE
    bv.Velocity = Vector3.zero
    bv.P = 600
    bv.Parent = root

    bg = Instance.new("BodyGyro")
    bg.Name = GYRO_NAME
    bg.MaxTorque = Vector3.new(4000, 4000, 4000)
    bg.CFrame = root.CFrame
    bg.D = 80
    bg.P = 2500
    bg.Parent = root

    hum.AutoRotate = false
    hum.JumpPower = 0

    heartbeatConn = game:GetService("RunService").Heartbeat:Connect(function()
        if not flying or not root or not root.Parent then
            stopFlight()
            return
        end

        local cam = workspace.CurrentCamera
        if not cam then return end

        local moveDir = Vector3.zero
        local uis = game:GetService("UserInputService")
        if uis:IsKeyDown(Enum.KeyCode.W) then moveDir += Vector3.new(0,0,-1) end
        if uis:IsKeyDown(Enum.KeyCode.S) then moveDir += Vector3.new(0,0,1) end
        if uis:IsKeyDown(Enum.KeyCode.A) then moveDir += Vector3.new(-1,0,0) end
        if uis:IsKeyDown(Enum.KeyCode.D) then moveDir += Vector3.new(1,0,0) end

        local worldMove = Vector3.zero
        if moveDir.Magnitude > 0 then
            local fwd = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit
            local rgt = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit
            worldMove = (fwd * -moveDir.Z + rgt * moveDir.X).Unit
        end

        local vert = 0
        if uis:IsKeyDown(Enum.KeyCode.E) then
            vert = V_SPEED
        elseif uis:IsKeyDown(Enum.KeyCode.Q) then
            vert = -V_SPEED
        else
            vert = -workspace.Gravity * 0.015
        end

        local noise = Vector3.new(
            (math.random() - 0.5) * 0.1,
            (math.random() - 0.5) * 0.05,
            (math.random() - 0.5) * 0.1
        )

        local vel = worldMove * H_SPEED + Vector3.new(0, vert, 0) + noise
        bv.Velocity = vel

        if worldMove.Magnitude > 0.01 then
            bg.CFrame = CFrame.lookAt(root.Position, root.Position + worldMove)
        else
            bg.CFrame = CFrame.lookAt(root.Position, root.Position + cam.CFrame.LookVector)
        end
    end)
end

local function stopFlight()
    flying = false
    if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
    if bv then bv:Destroy(); bv = nil end
    if bg then bg:Destroy(); bg = nil end
    if hum then
        hum.AutoRotate = true
        hum.JumpPower = 50
    end
end

-- //////////////////// GUI Creation ////////////////////
local function createGUI()
    -- Remove any existing GUI
    local existing = player.PlayerGui:FindFirstChild("StealthHoverGUI")
    if existing then existing:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StealthHoverGUI"
    screenGui.Parent = player.PlayerGui
    gui = screenGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 180, 0, 80)
    frame.Position = UDim2.new(1, -200, 0.5, -40)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.2
    frame.Parent = screenGui
    mainFrame = frame

    -- Drag handle (top‑right corner)
    local dragHandle = Instance.new("TextButton")
    dragHandle.Size = UDim2.new(0, 18, 0, 18)
    dragHandle.Position = UDim2.new(1, -20, 0, 1)
    dragHandle.BackgroundColor3 = Color3.fromRGB(100,100,100)
    dragHandle.Text = ""
    dragHandle.BorderSizePixel = 0
    dragHandle.AutoButtonColor = false
    dragHandle.Active = true
    dragHandle.ZIndex = 5
    dragHandle.Parent = frame

    local gripIcon = Instance.new("Frame")
    gripIcon.Size = UDim2.new(0, 6, 0, 6)
    gripIcon.Position = UDim2.new(0.5, -3, 0.5, -3)
    gripIcon.BackgroundColor3 = Color3.fromRGB(180,180,180)
    gripIcon.BorderSizePixel = 0
    gripIcon.Parent = dragHandle

    local dragStartPos, frameStartPos
    local isDraggingWindow = false

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingWindow = true
            dragStartPos = input.Position
            frameStartPos = frame.AbsolutePosition
            input:Consume()
        end
    end)

    local uis = game:GetService("UserInputService")
    uis.InputChanged:Connect(function(input)
        if not isDraggingWindow then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStartPos
            frame.Position = UDim2.new(0, frameStartPos.X + delta.X, 0, frameStartPos.Y + delta.Y)
        end
    end)

    uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingWindow = false
        end
    end)

    -- Toggle button (DISABLED / ENABLED)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 70, 0, 30)
    toggleBtn.Position = UDim2.new(0, 10, 0, 10)
    toggleBtn.Text = "DISABLED"                     -- initial state = off
    toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)  -- red
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = frame

    -- Speed label
    speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0, 50, 0, 20)
    speedLabel.Position = UDim2.new(1, -60, 0, 5)
    speedLabel.Text = tostring(H_SPEED)
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextColor3 = Color3.new(1,1,1)
    speedLabel.TextXAlignment = Enum.TextXAlignment.Center
    speedLabel.Font = Enum.Font.SourceSansBold
    speedLabel.Parent = frame

    -- Slider bar
    local bar = Instance.new("Frame")
    bar.Name = "SliderBar"
    bar.Size = UDim2.new(1, -20, 0, 10)
    bar.Position = UDim2.new(0, 10, 0, 50)
    bar.BackgroundColor3 = Color3.fromRGB(100,100,100)
    bar.BorderSizePixel = 0
    bar.Parent = frame

    -- Slider knob
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 14, 0, 20)
    knob.Position = UDim2.new(H_SPEED / 300, 0, 0, -5)
    knob.BackgroundColor3 = Color3.fromRGB(200,200,200)
    knob.BorderSizePixel = 0
    knob.Active = true
    knob.ZIndex = 2
    knob.Parent = bar

    -- Knob dragging logic
    local knobDragging = false

    local function updateSpeedFromKnob(knobPosX)
        local barWidth = bar.AbsoluteSize.X
        local knobWidth = knob.AbsoluteSize.X
        local minX = 0
        local maxX = barWidth - knobWidth
        knobPosX = math.clamp(knobPosX, minX, maxX)
        local percent = (knobPosX - minX) / (maxX - minX)
        H_SPEED = math.floor(percent * 300 + 0.5)   -- updates instantly
        speedLabel.Text = tostring(H_SPEED)
        knob.Position = UDim2.new(0, knobPosX, 0, -5)
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            knobDragging = true
            input:Consume()
        end
    end)

    uis.InputChanged:Connect(function(input)
        if not knobDragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = uis:GetMouseLocation()
            local barPos = bar.AbsolutePosition
            local knobSize = knob.AbsoluteSize
            local relativeX = mousePos.X - barPos.X - knobSize.X/2
            updateSpeedFromKnob(relativeX)
        elseif input.UserInputType == Enum.UserInputType.Touch then
            local touchPos = input.Position
            local barPos = bar.AbsolutePosition
            local knobSize = knob.AbsoluteSize
            local relativeX = touchPos.X - barPos.X - knobSize.X/2
            updateSpeedFromKnob(relativeX)
        end
    end)

    uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            knobDragging = false
        end
    end)

    -- Toggle button action
    toggleBtn.MouseButton1Click:Connect(function()
        flying = not flying
        if flying then
            toggleBtn.Text = "ENABLED"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)   -- green
            startFlight()
        else
            toggleBtn.Text = "DISABLED"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)   -- red
            stopFlight()
        end
    end)
end

-- //////////////////// Initial Setup ////////////////////
stopFlight()

player.CharacterAdded:Connect(function(newChar)
    char = newChar
    root = char:WaitForChild("HumanoidRootPart")
    hum = char:WaitForChild("Humanoid")
    stopFlight()
end)

-- F key toggle (syncs button state)
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F then
        flying = not flying
        local btn = gui and gui:FindFirstChild("Frame") and gui.Frame:FindFirstChild("TextButton")
        if flying then
            startFlight()
            if btn then btn.Text = "ENABLED"; btn.BackgroundColor3 = Color3.fromRGB(0,170,0) end
        else
            stopFlight()
            if btn then btn.Text = "DISABLED"; btn.BackgroundColor3 = Color3.fromRGB(200,0,0) end
        end
    end
end)

createGUI()

script.AncestryChanged:Connect(function()
    stopFlight()
    if gui then gui:Destroy() end
end)
