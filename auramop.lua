--[[
    RED TEAM AUDIT TOOL - HITBOX EXTENDER V8
    DESIGNED FOR: DELTA EXECUTOR
    FEATURES: FULL MODEL SELECTION, PATH TRACING, SLIDER SCALE 1-200
]]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- متغيرات التحكم
local systemActive = false
local currentSize = 1
local selectedMob = nil
local mobList = {}

-- دالة استخراج المسار الكامل للموب
local function getFullPath(obj)
    local path = obj.Name
    local p = obj.Parent
    while p and p ~= game do
        path = p.Name .. "." .. path
        p = p.Parent
    end
    return path
end

-- دالة إيجاد الموديل الكامل
local function getFullModel(part)
    local current = part
    while current and current ~= workspace do
        if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
            return current
        end
        current = current.Parent
    end
    return nil
end

-- ==================== بناء الواجهة (UI) ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SovereignHitboxV8"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 380)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Text = "SYSTEM AUDITOR V8"
title.Size = UDim2.new(1, 0, 0, 40)
title.TextColor3 = Color3.fromRGB(255, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Code
title.TextSize = 18
title.Parent = frame

local logLabel = Instance.new("TextLabel")
logLabel.Text = "Status: Awaiting Target..."
logLabel.Size = UDim2.new(0.9, 0, 0, 60)
logLabel.Position = UDim2.new(0.05, 0, 0.12, 0)
logLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
logLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
logLabel.TextWrapped = true
logLabel.TextSize = 12
logLabel.Parent = frame

local startBtn = Instance.new("TextButton")
startBtn.Text = "ACTIVATE SCANNER"
startBtn.Size = UDim2.new(0.9, 0, 0, 40)
startBtn.Position = UDim2.new(0.05, 0, 0.32, 0)
startBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
startBtn.TextColor3 = Color3.white
startBtn.Parent = frame
Instance.new("UICorner", startBtn)

-- السلايدر (Slider)
local sliderBackground = Instance.new("Frame")
sliderBackground.Size = UDim2.new(0.9, 0, 0, 12)
sliderBackground.Position = UDim2.new(0.05, 0, 0.55, 0)
sliderBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
sliderBackground.Parent = frame

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
sliderFill.Parent = sliderBackground

local sliderBtn = Instance.new("TextButton")
sliderBtn.Size = UDim2.new(0, 20, 0, 20)
sliderBtn.Position = UDim2.new(0, -10, -0.3, 0)
sliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderBtn.Text = ""
sliderBtn.Parent = sliderBackground
Instance.new("UICorner", sliderBtn)

local sizeLabel = Instance.new("TextLabel")
sizeLabel.Text = "Hitbox Size: 1"
sizeLabel.Position = UDim2.new(0, 0, -2, 0)
sizeLabel.Size = UDim2.new(1, 0, 1, 0)
sizeLabel.BackgroundTransparency = 1
sizeLabel.TextColor3 = Color3.white
sizeLabel.Parent = sliderBackground

local confirmBtn = Instance.new("TextButton")
confirmBtn.Text = "CONFIRM & APPLY"
confirmBtn.Size = UDim2.new(0.9, 0, 0, 45)
confirmBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 85, 255)
confirmBtn.TextColor3 = Color3.white
confirmBtn.Visible = false
confirmBtn.Parent = frame
Instance.new("UICorner", confirmBtn)

-- ==================== المنطق البرمجي ====================

-- 1. منطق السلايدر (تحريك مستطيل الحجم)
local isDragging = false
sliderBtn.MouseButton1Down:Connect(function() isDragging = true end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end end)

mouse.Move:Connect(function()
    if isDragging then
        local xOffset = math.clamp((mouse.X - sliderBackground.AbsolutePosition.X) / sliderBackground.AbsoluteSize.X, 0, 1)
        sliderBtn.Position = UDim2.new(xOffset, -10, -0.3, 0)
        sliderFill.Size = UDim2.new(xOffset, 0, 1, 0)
        currentSize = math.floor(xOffset * 200)
        if currentSize < 1 then currentSize = 1 end
        sizeLabel.Text = "Hitbox Size: " .. currentSize
    end
end)

-- 2. تفعيل النظام
startBtn.MouseButton1Click:Connect(function()
    systemActive = not systemActive
    startBtn.Text = systemActive and "SCANNER: ON" or "SCANNER: OFF"
    startBtn.BackgroundColor3 = systemActive and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(40, 40, 40)
end)

-- 3. تحديد الموب (فحص الوجه + المسار)
mouse.Button1Down:Connect(function()
    if not systemActive then return end
    
    local target = mouse.Target
    if target then
        -- فحص هل الهدف خلف الكاميرا؟
        local screenPos, onScreen = camera:WorldToViewportPoint(target.Position)
        if not onScreen then return end
        
        local fullMob = getFullModel(target)
        if fullMob then
            selectedMob = fullMob
            logLabel.Text = "SELECTED: " .. fullMob.Name .. "\nPATH: " .. getFullPath(fullMob)
            confirmBtn.Visible = true
        end
    end
end)

-- 4. التأكيد وتطبيق الـ Hitbox
confirmBtn.MouseButton1Click:Connect(function()
    if selectedMob then
        local root = selectedMob:FindFirstChild("HumanoidRootPart")
        if root then
            table.insert(mobList, {model = selectedMob, size = currentSize})
            logLabel.Text = "LOCKED: " .. selectedMob.Name .. " at Size " .. currentSize
            confirmBtn.Visible = false
        end
    end
end)

-- 5. التحديث المستمر للـ Hitbox (Enforcement)
RunService.RenderStepped:Connect(function()
    for _, data in pairs(mobList) do
        pcall(function()
            local root = data.model:FindFirstChild("HumanoidRootPart")
            if root then
                root.Size = Vector3.new(data.size, data.size, data.size)
                root.Transparency = 0.8
                root.Color = Color3.fromRGB(255, 0, 0)
                root.CanCollide = false -- لمنع الطيران عند لمس الموب
            end
        end)
    end
end)
