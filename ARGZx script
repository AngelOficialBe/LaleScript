-- ==========================================
-- ARGZx SCRIPT - MUSCLE LEGENDS (PROTEGIDO)
-- ==========================================

local Players = game:GetService("Players")
local plr = Players.LocalPlayer

-- ==========================================
-- 1. WHITELIST (PROTECCIÓN POR ID DE ROBLOX)
-- ==========================================
local allowedIDs = {
    9247989057, -- ID 1 Autorizado
    1806131849  -- ID 2 Autorizado
}

local authorized = false
for _, id in pairs(allowedIDs) do
    if plr.UserId == id then
        authorized = true
        break
    end
end

if not authorized then
    plr:Kick("Acceso Denegado: Tu ID no está autorizado para usar ARGZx Script.")
    return -- Detiene la ejecución del script
end

-- ==========================================
-- 2. VARIABLES Y ANTI-KICK AFK
-- ==========================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local PlayerGui = plr:WaitForChild("PlayerGui")

-- Evita que Roblox te expulse por inactividad (AFK de 20 minutos)
plr.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

repeat task.wait(0.3) until plr:FindFirstChild("muscleEvent") and plr:FindFirstChild("leaderstats")

local muscleEvent = plr.muscleEvent
local FastFarm = false
local AutoRebirth = false
local FarmPower = 70 

-- ==========================================
-- 3. INTERFAZ GRÁFICA (MENÚ)
-- ==========================================
local selectGui = Instance.new("ScreenGui")
selectGui.Name = "ARGZ_Selector"
selectGui.ResetOnSpawn = false
selectGui.Parent = PlayerGui

local selectFrame = Instance.new("Frame")
selectFrame.Size = UDim2.new(0, 320, 0, 220)
selectFrame.Position = UDim2.new(0.5, -160, 0.5, -110)
selectFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
selectFrame.Parent = selectGui
Instance.new("UICorner", selectFrame).CornerRadius = UDim.new(0, 10)

local selectTitle = Instance.new("TextLabel")
selectTitle.Size = UDim2.new(1, 0, 0, 50)
selectTitle.BackgroundTransparency = 1
selectTitle.Text = "ARGZx Script - Private"
selectTitle.TextColor3 = Color3.fromRGB(255, 80, 80)
selectTitle.Font = Enum.Font.GothamBold
selectTitle.TextSize = 20
selectTitle.Parent = selectFrame

local mainBtn = Instance.new("TextButton")
mainBtn.Size = UDim2.new(0.85, 0, 0, 40)
mainBtn.Position = UDim2.new(0.075, 0, 0, 70)
mainBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
mainBtn.Text = "Execute Main Script (Normal)"
mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mainBtn.Font = Enum.Font.GothamBold
mainBtn.TextSize = 14
mainBtn.Parent = selectFrame
Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 8)

local opBtn = Instance.new("TextButton")
opBtn.Size = UDim2.new(0.85, 0, 0, 40)
opBtn.Position = UDim2.new(0.075, 0, 0, 135)
opBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
opBtn.Text = "Execute Fast Farming (OP)"
opBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
opBtn.Font = Enum.Font.GothamBold
opBtn.TextSize = 14
opBtn.Parent = selectFrame
Instance.new("UICorner", opBtn).CornerRadius = UDim.new(0, 8)

-- ==========================================
-- 4. FUNCIÓN PRINCIPAL Y BUCLES SEGUROS
-- ==========================================
local function startScript(isOP)
    selectGui:Destroy()
    
    if isOP then
        FarmPower = 160 -- Modo OP ajustado a 160 reps
    else
        FarmPower = 70  -- Modo Normal intacto en 70
    end
    
    FastFarm = true
    AutoRebirth = true

    -- Fast Farm Seguro (Anti-Detección)
    task.spawn(function()
        while true do
            if FastFarm then
                for i = 1, FarmPower do
                    if not FastFarm then break end
                    muscleEvent:FireServer("rep")
                end
                -- TIEMPO ALEATORIO: Simula clics humanos para burlar al servidor
                task.wait(math.random(30, 70) / 1000) 
            else
                task.wait(0.2)
            end
        end
    end)

    -- Auto Rebirth 
    task.spawn(function()
        local rEvents = ReplicatedStorage:WaitForChild("Events")
        local rebirthRemote = rEvents:WaitForChild("rebirthRemote")
        
        while true do
            if AutoRebirth then
                task.spawn(function()
                    pcall(function()
                        if rebirthRemote:IsA("RemoteFunction") then
                            rebirthRemote:InvokeServer("rebirthRequest")
                        else
                            rebirthRemote:FireServer("rebirthRequest")
                        end
                    end)
                end)
                task.wait(2) -- Pausa segura entre rebirths
            else
                task.wait(0.5)
            end
        end
    end)
end

-- Conectar botones
mainBtn.MouseButton1Click:Connect(function()
    startScript(false)
end)

opBtn.MouseButton1Click:Connect(function()
    startScript(true)
end)
