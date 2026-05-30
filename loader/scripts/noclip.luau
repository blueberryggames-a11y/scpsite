--[[
    n.lua – Client‑side Noclip (No flying, no Y‑lock, passes through ALL parts)
    • Default: OFF – press N to toggle.
    • Disables collisions on every BasePart in your character.
    • NO vertical lock – you will fall through floors if you don't fly.
    • Works on MeshParts, Unions, Models (everything is a BasePart).
    • Clean‑up on re‑run / disable / respawn.
]]--

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ==================== CLEANUP OLD VERSION ====================
if _G.noclipData then
    _G.noclipData.enabled = false
    for _, conn in ipairs(_G.noclipData.connections) do
        conn:Disconnect()
    end
    if _G.noclipData.lastChar then
        for _, part in ipairs(_G.noclipData.lastChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    _G.noclipData = nil
    StarterGui:SetCore("SendNotification", {
        Title = "N Script",
        Text = "Old version cleared. Ready.",
        Duration = 1.5
    })
end

-- ==================== STATE ====================
local noclipEnabled = false
local currentCharacter = nil
local connections = {}

local function disableNoclip()
    noclipEnabled = false
    if currentCharacter then
        for _, part in ipairs(currentCharacter:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    StarterGui:SetCore("SendNotification", {
        Title = "N Script",
        Text = "Noclip OFF",
        Duration = 1.5
    })
end

local function enableNoclip(character)
    currentCharacter = character
    -- Disable collisions on EVERY BasePart (includes MeshParts, UnionOperations, etc.)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    noclipEnabled = true
    StarterGui:SetCore("SendNotification", {
        Title = "N Script",
        Text = "Noclip ON – walk through everything (will fall through floors)",
        Duration = 2
    })
end

local function toggleNoclip()
    if not noclipEnabled then
        if player.Character then
            enableNoclip(player.Character)
        end
    else
        disableNoclip()
    end
end

-- ==================== EVENT HOOKS ====================
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.N then
        toggleNoclip()
    end
end))

table.insert(connections, player.CharacterAdded:Connect(function(character)
    if noclipEnabled then
        enableNoclip(character)
    else
        currentCharacter = nil
    end
end))

-- ==================== STORE FOR CLEANUP ====================
_G.noclipData = {
    enabled = false,
    connections = connections,
    lastChar = currentCharacter,
}

StarterGui:SetCore("SendNotification", {
    Title = "N Script",
    Text = "Ready – Press N to toggle noclip (NO Y‑lock, will fall through floors)",
    Duration = 3
})
