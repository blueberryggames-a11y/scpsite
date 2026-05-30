-- Ground‑walking Noclip for SCP: Site Roleplay
-- Toggle key: F
-- Works with Potassium executor

local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")

local noclipEnabled = false
local connection
local bodyPosition

local RAY_LENGTH = 50            -- how far down to check for the floor
local GROUND_OFFSET = 3         -- typical distance from root part to feet
local VERTICAL_FORCE = 1e6      -- strong force to keep you on the floor

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

-- Create the BodyPosition inside the character’s root part
local function setupBodyPosition(char)
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not root then return nil end

    -- Remove old BodyPosition if exists
    for _, obj in ipairs(root:GetChildren()) do
        if obj:IsA("BodyPosition") then
            obj:Destroy()
        end
    end

    local bp = Instance.new("BodyPosition")
    bp.MaxForce = Vector3.new(0, VERTICAL_FORCE, 0)  -- only vertical force
    bp.P = 10000
    bp.D = 1000
    bp.Position = root.Position  -- initial position
    bp.Parent = root
    return bp
end

-- Make all parts non‑collidable (so you walk through everything)
local function setCollisions(char, state)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = state
        end
    end
end

-- The main loop: keeps you at ground level
local function noclipLoop()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not root then return end

    -- Raycast straight down from the root part
    local rayOrigin = root.Position
    local rayDirection = Vector3.new(0, -RAY_LENGTH, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {char}   -- ignore your own character
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

    if rayResult then
        local floorY = rayResult.Position.Y + GROUND_OFFSET
        if bodyPosition then
            bodyPosition.Position = Vector3.new(root.Position.X, floorY, root.Position.Z)
        end
    end
end

local function enableNoclip()
    local char = getCharacter()
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Make sure we can walk normally
    hum.PlatformStand = false

    -- Disable all collisions
    setCollisions(char, false)

    -- Create the vertical holder
    bodyPosition = setupBodyPosition(char)

    -- Stop any previous connection
    if connection then connection:Disconnect() end

    -- Run every frame
    connection = runService.Stepped:Connect(function()
        if not noclipEnabled then return end
        noclipLoop()
    end)
end

local function disableNoclip()
    noclipEnabled = false
    if connection then
        connection:Disconnect()
        connection = nil
    end

    -- Remove the BodyPosition
    if bodyPosition then
        bodyPosition:Destroy()
        bodyPosition = nil
    end

    local char = player.Character
    if char then
        setCollisions(char, true)  -- restore collisions
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
        end
    end
end

local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    if noclipEnabled then
        enableNoclip()
        print("Noclip ON – walk through doors/walls, stay on ground")
    else
        disableNoclip()
        print("Noclip OFF")
    end
end

-- Reapply after respawn
player.CharacterAdded:Connect(function(char)
    if noclipEnabled then
        task.wait(0.5)
        enableNoclip()
    end
end)

-- Toggle with F key
uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then
        toggleNoclip()
    end
end)

print("Ground‑walking noclip loaded. Press F to toggle.")
