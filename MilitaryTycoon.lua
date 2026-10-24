-- RUBY HUB | Military Tycoon - rebuilt base
-- Client-side utility. Object layouts can change as the game updates.
-- Executor-specific touch functions are optional; no success is implied if missing.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then return end
-- Display in PlayerGui first: CoreGui/gethui may be unavailable or invisible.
local guiParent = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 10)
if not guiParent then
    warn("[RubyHub] PlayerGui unavailable: cannot display UI")
    return
end

-- Make re-execution idempotent: stop previous loops and disconnect listeners.
local env = _G
if type(getgenv) == "function" then
    local ok, candidate = pcall(getgenv)
    if ok and type(candidate) == "table" then env = candidate end
end
if env.RubyHubCleanup then pcall(env.RubyHubCleanup) end

local running = true
local connections = {}
local enabled = {Cash = false, Buy = false, Oil = false}
local generations = {Cash = 0, Buy = 0, Oil = 0}
local touch = type(firetouchinterest) == "function" and firetouchinterest or nil
local attempts = {Cash = 0, Buy = 0, Oil = 0}
local detected = {Cash = "Unknown", Buy = "Unknown", Oil = "Unknown"}
local lastWarning = {}

local function track(connection)
    table.insert(connections, connection)
    return connection
end

local function instance(parent, kind, props)
    local object = Instance.new(kind)
    for property, value in pairs(props or {}) do object[property] = value end
    object.Parent = parent
    return object
end

local existing = guiParent:FindFirstChild("RubyGlassHub")
if existing then existing:Destroy() end
-- Remove older versions left in CoreGui, if accessible.
pcall(function()
    local previous = game:GetService("CoreGui"):FindFirstChild("RubyGlassHub")
    if previous then previous:Destroy() end
end)

local screen = instance(guiParent, "ScreenGui", {
    Name = "RubyGlassHub", ResetOnSpawn = false, Enabled = true, DisplayOrder = 1000,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

local base = instance(screen, "Frame", {
    Size = UDim2.fromOffset(510, 340), Position = UDim2.new(.5, -255, .5, -170),
    BackgroundColor3 = Color3.fromRGB(22, 9, 15), BorderSizePixel = 0,
    Active = true
})
instance(base, "UICorner", {CornerRadius = UDim.new(0, 12)})
instance(base, "UIStroke", {Color = Color3.fromRGB(235, 43, 80), Thickness = 1.5, Transparency = .15})

local header = instance(base, "Frame", {
    Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = Color3.fromRGB(47, 12, 25), BorderSizePixel = 0
})
instance(header, "UICorner", {CornerRadius = UDim.new(0, 12)})
instance(header, "TextLabel", {
    Size = UDim2.new(1, -104, 1, 0), Position = UDim2.fromOffset(15, 0),
    BackgroundTransparency = 1, Text = "RUBY HUB  |  MILITARY TYCOON",
    TextColor3 = Color3.fromRGB(255, 234, 241), Font = Enum.Font.GothamBold,
    TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
})
local minimize = instance(header, "TextButton", {
    Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -72, 0, 10),
    Text = "−", TextSize = 20, Font = Enum.Font.GothamBold,
    TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(92, 28, 43), BorderSizePixel = 0
})
instance(minimize, "UICorner", {CornerRadius = UDim.new(0, 6)})
local close = instance(header, "TextButton", {
    Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -38, 0, 10),
    Text = "×", TextSize = 20, Font = Enum.Font.GothamBold,
    TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(130, 28, 52), BorderSizePixel = 0
})
instance(close, "UICorner", {CornerRadius = UDim.new(0, 6)})

local content = instance(base, "ScrollingFrame", {
    Position = UDim2.fromOffset(12, 58), Size = UDim2.new(1, -24, 1, -96),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
