--[[
    LOADER HUB - Easy to expand
    Add your own scripts in the SCRIPTS table below.
    Format: {name = "Display Name", url = "raw_script_url"}
]]

local Player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")

-- Remove any existing hub to avoid duplicates
if game:GetService("CoreGui"):FindFirstChild("LoaderHub") then
    game:GetService("CoreGui").LoaderHub:Destroy()
end

-- ====== SCRIPTS TABLE (JUST ADD NEW ENTRIES HERE) ======
local SCRIPTS = {
    {name = "Fly",    url = "https://raw.githubusercontent.com/blueberryggames-a11y/scpsite/refs/heads/main/loader/scripts/fly.luau"},
    {name = "Speed",  url = "https://raw.githubusercontent.com/blueberryggames-a11y/scpsite/refs/heads/main/loader/scripts/speed.luau"},
    {name = "Noclip", url = "https://raw.githubusercontent.com/blueberryggames-a11y/scpsite/refs/heads/main/loader/scripts/noclip.luau"},
    {name = "Noclip V2", url = "https://raw.githubusercontent.com/blueberryggames-a11y/scpsite/refs/heads/main/loader/scripts/noclipv2.luau"},
}
-- =======================================================

local function notify(text)
    spawn(function()
        local gui = game:GetService("CoreGui"):FindFirstChild("LoaderHub")
        if not gui then return end
        local notif = gui.Main.Notification
        notif.Text = text
        notif.Visible = true
        notif.BackgroundTransparency = 0
        wait(2)
        local tween = TS:Create(notif, TweenInfo.new(0.5), {BackgroundTransparency = 1})
        tween:Play()
        tween.Completed:Wait()
        notif.Visible = false
    end)
end

local function loadScript(url, button)
    button.Text = "Loading..."
    button.Interactable = false
    spawn(function()
        local success, result = pcall(function()
            local response = game:HttpGet(url)
            local fn, err = loadstring(response)
            if not fn then
                error("Invalid script: " .. tostring(err))
            end
            fn()
            return true
        end)
        if success then
            notify("Loaded " .. button.Name)
        else
            notify("Error: " .. tostring(result))
            warn("Loader Hub Error:", result)
        end
        button.Text = button.Name
        button.Interactable = true
    end)
end

-- ====== CREATE UI ======
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LoaderHub"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 260, 0, 310)
Main.Position = UDim2.new(0.5, -130, 0.5, -155)
Main.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 35))
}
MainGradient.Parent = Main

-- Shadow behind Main
local Shadow = Instance.new("Frame")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(1, 6, 1, 6)
Shadow.Position = UDim2.new(0, -3, 0, -3)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.5
Shadow.BorderSizePixel = 0
Shadow.ZIndex = 0
Shadow.Parent = Main
local ShadowCorner = Instance.new("UICorner")
ShadowCorner.CornerRadius = UDim.new(0, 14)
ShadowCorner.Parent = Shadow

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 2
TitleBar.Parent = Main

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 42)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 26))
}
TitleGradient.Parent = TitleBar

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

-- Title text with rocket icon
local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -50, 1, 0)
TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "🚀 Loader Hub"
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 18
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

-- Close button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 26, 0, 26)
CloseButton.Position = UDim2.new(1, -30, 0, 6)
CloseButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CloseButton.Text = "✕"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.BorderSizePixel = 0
CloseButton.AutoButtonColor = false
CloseButton.Parent = TitleBar
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(240, 80, 80)
end)
CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
end)
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Drag functionality
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Notification label (bottom)
local Notification = Instance.new("TextLabel")
Notification.Name = "Notification"
Notification.Size = UDim2.new(1, -20, 0, 30)
Notification.Position = UDim2.new(0, 10, 1, -40)
Notification.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
Notification.BackgroundTransparency = 1
Notification.Text = ""
Notification.Font = Enum.Font.Gotham
Notification.TextSize = 14
Notification.TextColor3 = Color3.fromRGB(255, 255, 255)
Notification.BorderSizePixel = 0
Notification.Visible = false
Notification.Parent = Main
local NotifCorner = Instance.new("UICorner")
NotifCorner.CornerRadius = UDim.new(0, 8)
NotifCorner.Parent = Notification

-- Scroll area for buttons
local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -20, 1, -88) -- accounts for title + padding
Content.Position = UDim2.new(0, 10, 0, 48)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 140)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Main

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = Content

-- Button creation function
local function addButton(scriptData)
    local btn = Instance.new("TextButton")
    btn.Name = scriptData.name
    btn.Size = UDim2.new(1, 0, 0, 44)
    btn.BackgroundColor3 = Color3.fromRGB(72, 138, 245)
    btn.Text = scriptData.name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = Content

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = btn

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(90, 155, 255)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(72, 138, 245)
    end)

    btn.MouseButton1Click:Connect(function()
        loadScript(scriptData.url, btn)
    end)
    return btn
end

-- Add all buttons from the table
for _, scriptEntry in ipairs(SCRIPTS) do
    addButton(scriptEntry)
end

print("Loader Hub loaded! Drag the header to move. Add more scripts in the SCRIPTS table.")
