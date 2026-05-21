--[[
    MOB MANAGER V5 - (GHOST & NOCLIP MODE)
    ✅ نظام تأكيد الاختيار (Confirm System)
    ✅ وضع الاختراق: يجعل الموبات تسقط عبر الأرض وتخترق الجدران
    ✅ منع اختيار الأشياء خلف الواجهة
]]--

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- متغيرات النظام
local savedMobNames = {} 
local selectionMode = false
local tempSelectedMob = nil 

-- وظيفة للحصول على مسار الشيء
local function getFullPath(obj)
    local path = obj.Name
    local parent = obj.Parent
    while parent and parent ~= game do
        path = parent.Name .. "." .. path
        parent = parent.Parent
    end
    return path
end

-- صندوق التحديد المرئي
local selectionBox = Instance.new("SelectionBox")
selectionBox.Color3 = Color3.fromRGB(255, 0, 0) -- لون أحمر لوضع الاختراق
selectionBox.LineThickness = 0.2
selectionBox.Parent = workspace

-- ==================== بناء الواجهة ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobGhostManagerV5"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 220)
mainFrame.Position = UDim2.new(0.5, -175, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 10)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true 
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Text = "👻 Mob Ghost Manager V5"
title.Size = UDim2.new(1, 0, 0, 30)
title.TextColor3 = Color3.fromRGB(255, 50, 50)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local infoLabel = Instance.new("TextLabel")
infoLabel.Text = "اختر الموبات التي تريد جعلها تخترق الأرض..."
infoLabel.Size = UDim2.new(0.9, 0, 0, 40)
infoLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
infoLabel.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
infoLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
infoLabel.TextSize = 10
infoLabel.TextWrapped = true
infoLabel.Font = Enum.Font.Code
infoLabel.Parent = mainFrame
Instance.new("UICorner", infoLabel)

-- ==================== الأزرار ====================
local function createBtn(text, pos, size, color)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = mainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local selectBtn = createBtn("🔍 وضع التحديد: OFF", UDim2.new(0.05, 0, 0.38, 0), UDim2.new(0.9, 0, 0, 35), Color3.fromRGB(180, 40, 40))

local confirmBtn = createBtn("✅ تأكيد الإضافة للقائمة", UDim2.new(0.05, 0, 0.58, 0), UDim2.new(0.9, 0, 0, 35), Color3.fromRGB(0, 120, 255))
confirmBtn.Visible = false

local ghostBtn = createBtn("💀 تفعيل الاختراق (سقوط)", UDim2.new(0.05, 0, 0.77, 0), UDim2.new(0.43, 0, 0, 35), Color3.fromRGB(150, 0, 0))
local clearBtn = createBtn("🗑️ مسح القائمة", UDim2.new(0.52, 0, 0.77, 0), UDim2.new(0.43, 0, 0, 35), Color3.fromRGB(80, 80, 80))

-- ==================== المنطق البرمجي ====================

-- 1. اختيار الموب
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if selectionMode and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
        local unitRay = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
        local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000)
        
        if raycastResult and raycastResult.Instance then
            local model = raycastResult.Instance:FindFirstAncestorOfClass("Model")
            if model and model:FindFirstChildOfClass("Humanoid") then
                tempSelectedMob = model
                selectionBox.Adornee = model
                infoLabel.Text = "الموب المختار: " .. model.Name
                confirmBtn.Visible = true
                confirmBtn.Text = "✅ إضافة [ " .. model.Name .. " ]"
            end
        end
    end
end)

-- 2. تأكيد الإضافة
confirmBtn.MouseButton1Click:Connect(function()
    if tempSelectedMob then
        if not table.find(savedMobNames, tempSelectedMob.Name) then
            table.insert(savedMobNames, tempSelectedMob.Name)
            infoLabel.Text = "✅ تمت إضافة النوع " .. tempSelectedMob.Name .. " للقائمة"
        end
        confirmBtn.Visible = false
        selectionBox.Adornee = nil
        tempSelectedMob = nil
    end
end)

-- 3. تبديل وضع التحديد
selectBtn.MouseButton1Click:Connect(function()
    selectionMode = not selectionMode
    selectBtn.Text = selectionMode and "🔍 وضع التحديد: ON" or "🔍 وضع التحديد: OFF"
    selectBtn.BackgroundColor3 = selectionMode and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
    if not selectionMode then 
        confirmBtn.Visible = false 
        selectionBox.Adornee = nil
    end
end)

-- 4. تفعيل وضع الاختراق (Ghost Mode)
ghostBtn.MouseButton1Click:Connect(function()
    if #savedMobNames == 0 then
        infoLabel.Text = "❌ أضف موباً واحداً على الأقل!"
        return
    end

    local count = 0
    for _, item in pairs(workspace:GetDescendants()) do
        if item:IsA("Model") and table.find(savedMobNames, item.Name) then
            -- جعل كل الأجزاء غير قابلة للاصطدام
            for _, part in pairs(item:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    part.CanTouch = false
                    part.CanQuery = false
                end
            end
            
            -- تعطيل توازن الهيومانويد ليتمكن من السقوط عبر الأرض
            local hum = item:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = true
            end
            
            count = count + 1
        end
    end
    infoLabel.Text = "💀 " .. count .. " موب أصبحوا أشباحاً الآن!"
end)

-- 5. مسح القائمة
clearBtn.MouseButton1Click:Connect(function()
    savedMobNames = {}
    infoLabel.Text = "🗑️ تم مسح القائمة"
end)

-- زر إغلاق
local close = createBtn("X", UDim2.new(1, -25, 0, 5), UDim2.new(0, 20, 0, 20), Color3.fromRGB(255, 50, 50))
close.MouseButton1Click:Connect(function() screenGui:Destroy() end)
