--[[
    RED TEAM AUDIT TOOL - HITBOX & FREEZE V8.2
    OPTIMIZED FOR: DELTA EXECUTOR (MOBILE)
    FUNCTION: SELECT ONE -> FREEZE ALL SIMILAR + AUTO-LOCK
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- جداول التحكم
local systemActive = false
local currentSize = 20
local lockedMobNames = {} -- لتخزين أسماء الموبات التي نريد تجميدها دائماً

-- دالة إيجاد الموديل (تأكد أنه عدو)
local function getTargetModel(part)
    local current = part
    while current and current ~= workspace do
        if current:IsA("Model") and (current:FindFirstChildOfClass("Humanoid") or current:FindFirstChild("Head")) then
            return current
        end
        current = current.Parent
    end
    return nil
end

-- دالة تطبيق التجميد والهيتبوكس
local function applyEffects(model)
    if not model then return end
    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("PrimaryPart")
    
    if root then
        pcall(function()
            root.Size = Vector3.new(currentSize, currentSize, currentSize)
            root.Transparency = 0.7
            root.Color = Color3.fromRGB(255, 0, 0)
            root.CanCollide = false
            root.Anchored = true -- تجميد الموب في مكانه
        end)
    end
end

-- ==================== بناء الواجهة (UI) ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SovereignSystemV8"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 350)
frame.Position = UDim2.new(0.1, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Text = "FREEZE AUDITOR V8.2"
title.Size = UDim2.new(1, 0, 0, 40)
title.TextColor3 = Color3.fromRGB(255, 50, 50)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Code
title.TextSize = 18
title.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Text = "Status: Idle (Scanner Off)"
statusLabel.Size = UDim2.new(0.9, 0, 0, 50)
statusLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextWrapped = true
statusLabel.Parent = frame

local scanBtn = Instance.new("TextButton")
scanBtn.Text = "ACTIVATE SCANNER"
scanBtn.Size = UDim2.new(0.9, 0, 0, 40)
scanBtn.Position = UDim2.new(0.05, 0, 0.35, 0)
scanBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
scanBtn.TextColor3 = Color3.white
scanBtn.Parent = frame
Instance.new("UICorner", scanBtn)

-- السلايدر
local sliderFrame = Instance.new("Frame")
sliderFrame.Size = UDim2.new(0.9, 0, 0, 10)
sliderFrame.Position = UDim2.new(0.05, 0, 0.55, 0)
sliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
sliderFrame.Parent = frame

local sliderBar = Instance.new("Frame")
sliderBar.Size = UDim2.new(0.1, 0, 1, 0)
sliderBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
sliderBar.Parent = sliderFrame

local sizeText = Instance.new("TextLabel")
sizeText.Text = "Hitbox Size: 20"
sizeText.Position = UDim2.new(0, 0, -2.5, 0)
sizeText.Size = UDim2.new(1, 0, 2, 0)
sizeText.BackgroundTransparency = 1
sizeText.TextColor3 = Color3.white
sizeText.Parent = sliderFrame

local confirmBtn = Instance.new("TextButton")
confirmBtn.Text = "CONFIRM & FREEZE ALL"
confirmBtn.Size = UDim2.new(0.9, 0, 0, 50)
confirmBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
confirmBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
confirmBtn.TextColor3 = Color3.white
confirmBtn.Visible = false
confirmBtn.Parent = frame
Instance.new("UICorner", confirmBtn)

-- ==================== المنطق التشغيلي ====================

local selectedName = ""

-- 1. تفعيل السكنر
scanBtn.MouseButton1Click:Connect(function()
    systemActive = not systemActive
    scanBtn.Text = systemActive and "SCANNING..." or "ACTIVATE SCANNER"
    scanBtn.BackgroundColor3 = systemActive and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(45, 45, 45)
    statusLabel.Text = systemActive and "Click on a Mob to select it" or "System Idle"
end)

-- 2. منطق السلايدر
sliderFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local function update()
            local inputPos = input.Position.X
            local framePos = sliderFrame.AbsolutePosition.X
            local frameSize = sliderFrame.AbsoluteSize.X
            local percent = math.clamp((inputPos - framePos) / frameSize, 0, 1)
            sliderBar.Size = UDim2.new(percent, 0, 1, 0)
            currentSize = math.floor(percent * 200)
            if currentSize < 1 then currentSize = 1 end
            sizeText.Text = "Hitbox Size: " .. currentSize
        end
        update()
        local moveConnection = UserInputService.InputChanged:Connect(function(moveInput)
            if moveInput.UserInputType == Enum.UserInputType.MouseButton1 or moveInput.UserInputType == Enum.UserInputType.Touch then
                local inputPos = moveInput.Position.X
                local framePos = sliderFrame.AbsolutePosition.X
                local frameSize = sliderFrame.AbsoluteSize.X
                local percent = math.clamp((inputPos - framePos) / frameSize, 0, 1)
                sliderBar.Size = UDim2.new(percent, 0, 1, 0)
                currentSize = math.floor(percent * 200)
                if currentSize < 1 then currentSize = 1 end
                sizeText.Text = "Hitbox Size: " .. currentSize
            end
        end)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                moveConnection:Disconnect()
            end
        end)
    end
end)

-- 3. تحديد الموب (باللمس أو الضغط)
mouse.Button1Down:Connect(function()
    if not systemActive then return end
    
    local target = mouse.Target
    if target then
        -- التأكد أن الهدف ليس خلف اللاعب (Visible check)
        local _, onScreen = camera:WorldToViewportPoint(target.Position)
        if not onScreen then return end
        
        local model = getTargetModel(target)
        if model then
            selectedName = model.Name
            statusLabel.Text = "TARGET FOUND: " .. selectedName .. "\nClick Confirm to freeze all of them."
            confirmBtn.Visible = true
        end
    end
end)

-- 4. تأكيد التجميد (تجميد الكل + القائمة التلقائية)
confirmBtn.MouseButton1Click:Connect(function()
    if selectedName ~= "" then
        if not table.find(lockedMobNames, selectedName) then
            table.insert(lockedMobNames, selectedName)
        end
        statusLabel.Text = "SYSTEM LOCKED ON: " .. selectedName .. "\nFreezing all existing and future spawns."
        confirmBtn.Visible = false
        systemActive = false
        scanBtn.Text = "SYSTEM ACTIVE"
    end
end)

-- 5. حلقة التحديث المستمر (Auto-Freeze)
RunService.RenderStepped:Connect(function()
    if #lockedMobNames > 0 then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and table.find(lockedMobNames, obj.Name) then
                applyEffects(obj)
            end
        end
    end
end)

-- رسالة ترحيبية في الكونسول
print("Sovereign Hitbox V8.2 Loaded - Ready for Delta")
