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
    ScrollBarImageColor3 = Color3.fromRGB(225, 54, 91),
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()
})
instance(content, "UIListLayout", {Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder})
local status = instance(base, "TextLabel", {
    Position = UDim2.new(0, 15, 1, -33), Size = UDim2.new(1, -30, 0, 25),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11,
    TextColor3 = Color3.fromRGB(255, 174, 190), TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Ready | FPS: -- | Ping: --"
})

local function setMessage(message)
    if running and status.Parent then status.Text = message end
end
local function warnOccasionally(key, message)
    if os.clock() - (lastWarning[key] or -100) > 12 then
        lastWarning[key] = os.clock()
        warn("[RubyHub] " .. message)
    end
end
local function myRoot()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end
local function myTycoon()
    local tycoons = Workspace:FindFirstChild("Tycoons")
    if not tycoons then return nil end
    for _, tycoon in ipairs(tycoons:GetChildren()) do
        local owner = tycoon:FindFirstChild("Owner")
        if owner then
            if owner:IsA("ObjectValue") and owner.Value == player then return tycoon end
            if owner:IsA("StringValue") and (owner.Value == player.Name or owner.Value == tostring(player.UserId)) then return tycoon end
            if owner:IsA("IntValue") and owner.Value == player.UserId then return tycoon end
        end
    end
    return nil
end
local function touchPart(part)
    local root = myRoot()
    if not (root and part and part:IsA("BasePart")) then return false end
    if not touch then
        warnOccasionally("executor", "firetouchinterest no esta disponible; estas acciones no pueden ejecutarse con esta API")
        return false
    end
    local ok, errorText = pcall(function()
        touch(root, part, 0)
        touch(root, part, 1)
    end)
    if not ok then warnOccasionally("touch", tostring(errorText)) end
    return ok
end
local function findPart(model)
    if model:IsA("BasePart") then return model end
    if not model:IsA("Instance") then return nil end
    -- Prefer named touch/collision parts, otherwise first non-invisible base part.
    for _, name in ipairs({"Giver", "Collector", "Collect", "Button", "Hitbox", "TouchPart", "Part"}) do
        local part = model:FindFirstChild(name, true)
        if part and part:IsA("BasePart") then return part end
    end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

-- Cache oil candidates. Avoid scanning the full workspace inside a tight loop.
local oilCandidates = {}
local oilCacheAt = 0
local function updateOilCache()
    if os.clock() - oilCacheAt < 20 then return end
    oilCacheAt = os.clock()
    table.clear(oilCandidates)
    for _, item in ipairs(Workspace:GetDescendants()) do
        if item:IsA("BasePart") then
            local name = item.Name:lower()
            if name:find("oil", 1, true) or name:find("rig", 1, true) then
                table.insert(oilCandidates, item)
            end
        end
    end
end

local function collectCash()
    local tycoon = myTycoon()
    if not tycoon then detected.Cash = "Tycoon no encontrado"; return end
    local essentials = tycoon:FindFirstChild("Essentials")
    local collector = essentials and (essentials:FindFirstChild("Giver") or essentials:FindFirstChild("Collector"))
    if not collector then
        detected.Cash = "Recolector no encontrado"
        warnOccasionally("cash", "Cash collector was not found. Game layout may differ")
        return
    end
    detected.Cash = collector:GetFullName()
    if touchPart(findPart(collector)) then attempts.Cash += 1 end
end
local function buyButtons()
    local tycoon = myTycoon()
    local buttons = tycoon and tycoon:FindFirstChild("Buttons")
    if not buttons then detected.Buy = "Buttons no encontrado"; return end
    detected.Buy = buttons:GetFullName()
    local count = 0
    for _, button in ipairs(buttons:GetChildren()) do
        if count >= 15 then break end -- cap attempts per pass
        local part = findPart(button)
        if part and part.CanTouch then
            if touchPart(part) then attempts.Buy += 1 end
            count += 1
        end
    end
end
local oilIndex = 1
local function collectOil()
    updateOilCache()
    detected.Oil = tostring(#oilCandidates) .. " partes candidatas"
    if #oilCandidates == 0 then
        warnOccasionally("oil", "No oil parts found; candidate names may not match this game")
        return
    end
    -- Only check a few cached parts each cycle.
    for _ = 1, math.min(#oilCandidates, 5) do
        if oilIndex > #oilCandidates then oilIndex = 1 end
        local part = oilCandidates[oilIndex]
        oilIndex += 1
        if part and part.Parent and part.CanTouch then
            if touchPart(part) then attempts.Oil += 1 end
        end
    end
end

local function startWorker(key, delaySeconds, callback)
    generations[key] += 1
    local token = generations[key]
    if not enabled[key] then return end
    task.spawn(function()
        while running and enabled[key] and generations[key] == token do
            local ok, err = pcall(callback)
            if not ok then warnOccasionally(key, tostring(err)) end
            task.wait(delaySeconds)
        end
    end)
end
local function addToggle(title, key, interval, callback)
    local card = instance(content, "Frame", {
        Size = UDim2.new(1, -8, 0, 55), BackgroundColor3 = Color3.fromRGB(43, 17, 28),
        BorderSizePixel = 0
    })
    instance(card, "UICorner", {CornerRadius = UDim.new(0, 9)})
    instance(card, "TextLabel", {
        Size = UDim2.new(1, -108, 1, 0), Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = Color3.fromRGB(244, 223, 230), TextXAlignment = Enum.TextXAlignment.Left
    })
    local button = instance(card, "TextButton", {
        Size = UDim2.fromOffset(73, 29), Position = UDim2.new(1, -86, .5, -14),
        Text = "OFF", TextSize = 12, Font = Enum.Font.GothamBold,
        TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(82, 45, 56), BorderSizePixel = 0
    })
    instance(button, "UICorner", {CornerRadius = UDim.new(0, 7)})
    track(button.MouseButton1Click:Connect(function()
        enabled[key] = not enabled[key]
        button.Text = enabled[key] and "ON" or "OFF"
        TweenService:Create(button, TweenInfo.new(.15), {
            BackgroundColor3 = enabled[key] and Color3.fromRGB(210, 36, 75) or Color3.fromRGB(82, 45, 56)
        }):Play()
        startWorker(key, interval, callback)
        if enabled[key] and not touch then
            setMessage("Sin firetouchinterest: " .. title .. " no puede funcionar")
        else
            setMessage(title .. (enabled[key] and " enabled" or " disabled"))
        end
    end))
end

addToggle("Auto-Collect Cash", "Cash", .75, collectCash)
addToggle("Auto-Buy Tycoon", "Buy", 1.5, buyButtons)
addToggle("Auto-Farm Oil Wells (experimental)", "Oil", 2.5, collectOil)

-- Diagnostic check: prints actual detected paths, without assuming successes.
local diagnostic = instance(content, "TextButton", {
    Size = UDim2.new(1, -8, 0, 34),
    BackgroundColor3 = Color3.fromRGB(110, 33, 56),
    BorderSizePixel = 0,
    Text = "DIAGNOSTICO / VER CONSOLA",
    TextSize = 12, Font = Enum.Font.GothamBold,
    TextColor3 = Color3.new(1, 1, 1)
})
instance(diagnostic, "UICorner", {CornerRadius = UDim.new(0, 7)})
track(diagnostic.MouseButton1Click:Connect(function()
    local tycoon = myTycoon()
    local buttons = tycoon and tycoon:FindFirstChild("Buttons")
    local essentials = tycoon and tycoon:FindFirstChild("Essentials")
    updateOilCache()
    print("[RubyHub] Xeno/Executor touch API:", touch and "Disponible" or "No disponible")
    print("[RubyHub] Tycoon:", tycoon and tycoon:GetFullName() or "No encontrado")
    print("[RubyHub] Essentials:", essentials and essentials:GetFullName() or "No encontrado")
    print("[RubyHub] Buttons:", buttons and (tostring(#buttons:GetChildren()) .. " objetos") or "No encontrado")
    print("[RubyHub] Oil candidates:", #oilCandidates)
    print("[RubyHub] Intentos (NO son recompensas confirmadas):", attempts.Cash, attempts.Buy, attempts.Oil)
    print("[RubyHub] Deteccion:", detected.Cash, detected.Buy, detected.Oil)
    setMessage(touch and "Diagnostico impreso en consola (F9)" or "API touch NO DISPONIBLE: revisa consola (F9)")
end))

local description = instance(content, "TextLabel", {
    Size = UDim2.new(1, -8, 0, 48), BackgroundTransparency = 1,
    TextWrapped = true, Font = Enum.Font.Gotham, TextSize = 11,
    TextColor3 = Color3.fromRGB(199, 148, 165),
    Text = "Experimental: sin confirmar estructuras del juego. Intentos de contacto NO garantizan dinero, compras ni petroleo."
})

local oldSize = base.Size
local minimized = false
track(minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    content.Visible = not minimized
    status.Visible = not minimized
    base.Size = minimized and UDim2.fromOffset(530, 48) or oldSize
    minimize.Text = minimized and "+" or "−"
end))

-- Drag just the header so all the children move with the base.
local dragging, dragStart, startPosition = false, nil, nil
track(header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPosition = true, input.Position, base.Position
    end
end))
track(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end))
track(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        base.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end))

local count, elapsed = 0, os.clock()
track(RunService.RenderStepped:Connect(function()
    count += 1
    if os.clock() - elapsed < 1 then return end
    local fps = math.floor(count / (os.clock() - elapsed) + .5)
    count, elapsed = 0, os.clock()
    local pingText = "--"
    pcall(function()
        local item = Stats.Network.ServerStatsItem["Data Ping"]
        if item then pingText = tostring(math.floor(item:GetValue() + .5)) .. "ms" end
    end)
    if status.Parent then
        status.Text = string.format("Ruby Hub active  |  FPS: %d  |  Ping: %s", fps, pingText)
    end
end))

local function cleanup()
    if not running then return end
    running = false
    for key in pairs(enabled) do
        enabled[key] = false
        generations[key] += 1
    end
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    if screen then screen:Destroy() end
    if env.RubyHubCleanup == cleanup then env.RubyHubCleanup = nil end
end

env.RubyHubCleanup = cleanup
track(close.MouseButton1Click:Connect(cleanup))
print("[RubyHub] GUI creada en", screen.Parent:GetFullName())
print("[RubyHub] Interfaz cargada. Presiona DIAGNOSTICO para revisar compatibilidad y rutas reales.")
