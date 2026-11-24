-- ==========================================
-- ROBLOX SQUID GAME X - KORUMA (GUARD) V38
-- (Daraltılmış Coffin Room Radarı + %100 İsabet)
-- ==========================================
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(1)

local genv = (typeof(getgenv) == "function" and getgenv()) or _G
if typeof(genv.GuardCleanup) == "function" then pcall(genv.GuardCleanup) end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Guard V38 Aktif",
        Text = "Coffin Room sınırları daraltıldı ve Yükseklik(Kat) kontrolü eklendi.",
        Duration = 5
    })
end)

-- ==========================================
-- AYARLAR VE ÇAPRAZ FİLTRELEME
-- ==========================================
genv.AutoGuardExecute = false
genv.AutoGuardClean = false
genv.AutoGuardBurn = false
genv.AutoKitchen = false

local CONFIG = {
    WeaponNames = {
        "mps-5", "vector-9", "golden mps-5", "beatblaster", "skull spray", 
        "ar-47", "m4", "aux-9", "raptor-12", "revolver", "gun", "pistol", "weapon", "silah", "rifle", "shotgun"
    },
    BodyKeywords = {"clean", "temizle", "body", "corpse", "ceset"},
    CoffinKeywords = {"coffin", "tabut", "box", "pick up", "grab", "take"},
    BurnKeywords = {"burn", "incinerator", "fire", "yak", "fırın", "interact", "furnace"},
    KitchenBeefKeywords = {"beef", "meat", "et"},
    KitchenPotatoKeywords = {"potato", "patates"},
    KitchenCookKeywords = {"cook", "pişir", "stove", "oven"},
    KitchenStoreKeywords = {"store", "depo", "fridge", "tray", "drop"},
    KitchenReadyKeywords = {"cooked", "take food", "pick up food", "hazır"},
    
    BodyBlacklist = {"coffin", "tabut", "beef", "potato", "kitchen", "cook", "store", "food"},
    CoffinBlacklist = {"beef", "potato", "kitchen", "cook", "store", "food", "clean", "temizle", "door", "room", "equip", "outfit", "buy", "shop", "exit"},
    KitchenBlacklist = {
        "coffin", "tabut", "body", "corpse", "ceset", "burn", "incinerator", "clean", 
        "sith", "skin", "guard", "equip", "buy", "outfit", "room", "door", "exit"
    },

    MovementMode = "Tween",
    TweenSpeed = 95,
    NoclipOnMove = true,
    MaxCleanDistance = 250
}

local CoffinData = { State = "PICKUP" }
local Connections = {}
local MainLoopRunning = false
local ActiveTween = nil
local IsMoving = false 

-- ==========================================
-- ARAYÜZ (GUI)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SGX_Guard_V38_" .. tostring(math.random(100, 999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999

local function mountGui(gui)
    local success = pcall(function()
        if typeof(gethui) == "function" then gui.Parent = gethui() else gui.Parent = game:GetService("CoreGui") end
    end)
    if not success then
        local pGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if pGui then gui.Parent = pGui end
    end
end
mountGui(ScreenGui)

local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Size = UDim2.new(0, 50, 0, 50)
FloatingBtn.Position = UDim2.new(1, -60, 0.5, -25)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(30, 33, 42)
FloatingBtn.Text = "GRD-38"
FloatingBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.TextSize = 12
FloatingBtn.Parent = ScreenGui
Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(0, 255, 100)
FloatStroke.Thickness = 2
FloatStroke.Parent = FloatingBtn

local dragFloatToggle, dragFloatInput, dragFloatStart, floatStartPos
table.insert(Connections, FloatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragFloatToggle = true; dragFloatStart = input.Position; floatStartPos = FloatingBtn.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragFloatToggle = false end end)
    end
end))
table.insert(Connections, FloatingBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragFloatInput = input end
end))
table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if input == dragFloatInput and dragFloatToggle then
        local delta = input.Position - dragFloatStart
        FloatingBtn.Position = UDim2.new(floatStartPos.X.Scale, floatStartPos.X.Offset + delta.X, floatStartPos.Y.Scale, floatStartPos.Y.Offset + delta.Y)
    end
end))

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 360)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = true 
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -75, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SQUID GAME X | Koruma V38"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 12
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -31, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -24, 0, 30)
StatusLabel.Position = UDim2.new(0, 12, 0, 46)
StatusLabel.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
StatusLabel.Text = " Durum: V38 Bekliyor..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 205, 85)
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 8)

local function updateUIStatus(text)
    if StatusLabel then StatusLabel.Text = " Durum: " .. text end
end

local ExecBtn = Instance.new("TextButton")
ExecBtn.Size = UDim2.new(1, -24, 0, 36)
ExecBtn.Position = UDim2.new(0, 12, 0, 86)
ExecBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 60)
ExecBtn.Text = "1. OTO-İNFAZ (100% İSABET): KAPALI"
ExecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecBtn.Font = Enum.Font.GothamBold
ExecBtn.TextSize = 11
ExecBtn.Parent = MainFrame
Instance.new("UICorner", ExecBtn).CornerRadius = UDim.new(0, 8)

local CleanBtn = Instance.new("TextButton")
CleanBtn.Size = UDim2.new(1, -24, 0, 36)
CleanBtn.Position = UDim2.new(0, 12, 0, 128)
CleanBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 60)
CleanBtn.Text = "2. BÖLGESEL BEDEN TEMİZLİĞİ: KAPALI"
CleanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CleanBtn.Font = Enum.Font.GothamBold
CleanBtn.TextSize = 12
CleanBtn.Parent = MainFrame
Instance.new("UICorner", CleanBtn).CornerRadius = UDim.new(0, 8)

local BurnBtn = Instance.new("TextButton")
BurnBtn.Size = UDim2.new(1, -24, 0, 36)
BurnBtn.Position = UDim2.new(0, 12, 0, 170)
BurnBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 60)
BurnBtn.Text = "3. OTO TABUT (V38 SIRALI DÖNGÜ): KAPALI"
BurnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BurnBtn.Font = Enum.Font.GothamBold
BurnBtn.TextSize = 11
BurnBtn.Parent = MainFrame
Instance.new("UICorner", BurnBtn).CornerRadius = UDim.new(0, 8)

local KitchenBtn = Instance.new("TextButton")
KitchenBtn.Size = UDim2.new(1, -24, 0, 36)
KitchenBtn.Position = UDim2.new(0, 12, 0, 212)
KitchenBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 60)
KitchenBtn.Text = "4. KITCHEN OTO-FARM (ZEKİ YAPAY ZEKA): KAPALI"
KitchenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KitchenBtn.Font = Enum.Font.GothamBold
KitchenBtn.TextSize = 10
KitchenBtn.Parent = MainFrame
Instance.new("UICorner", KitchenBtn).CornerRadius = UDim.new(0, 8)

local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(1, -24, 0, 32)
ModeBtn.Position = UDim2.new(0, 12, 0, 258)
ModeBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 64)
ModeBtn.Text = "Hareket: Tween (Akıcı)"
ModeBtn.TextColor3 = Color3.fromRGB(230, 235, 245)
ModeBtn.Font = Enum.Font.GothamBold
ModeBtn.TextSize = 11
ModeBtn.Parent = MainFrame
Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 8)

-- ==========================================
-- GÜVENLİ POZİSYON KONTROLÜ
-- ==========================================
local function isSafePos(pos, myRootPos)
    if not pos or typeof(pos) ~= "Vector3" then return false end
    if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z then return false end
    if myRootPos and pos.Y < (myRootPos.Y - 55) then return false end
    return true
end

-- ==========================================
-- AKILLI KELİME ARAMA & PROMPT GETİRİCİ
-- ==========================================
local function getPromptPos(desc)
    if not desc or not desc.Parent then return nil end
    if desc.Parent:IsA("BasePart") then return desc.Parent.Position end
    if desc.Parent:IsA("Model") then 
        if desc.Parent.PrimaryPart then return desc.Parent.PrimaryPart.Position end
        return desc.Parent:GetPivot().Position
    end
    return nil
end

local function getPrompt(includeKws, excludeKws, ignoreEnabled)
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") and desc.Parent then
            if ignoreEnabled or desc.Enabled then
                local isValidParent = desc.Parent:IsA("BasePart") or desc.Parent:IsA("Model")
                if isValidParent then
                    local fullText = string.lower((desc.ActionText or "").." "..(desc.ObjectText or "").." "..desc.Name.." "..desc.Parent.Name)
                    if desc.Parent.Parent then fullText = fullText .. " " .. string.lower(desc.Parent.Parent.Name) end

                    local blacklisted = false
                    if excludeKws then
                        for _, ex in ipairs(excludeKws) do
                            if string.find(fullText, ex, 1, true) then blacklisted = true; break end
                        end
                    end

                    if not blacklisted and includeKws then
                        for _, inc in ipairs(includeKws) do
                            if string.find(fullText, inc, 1, true) then return desc end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function getOvenPrompt()
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            if desc.Enabled then
                local act = string.lower(desc.ActionText or "")
                local pName = desc.Parent and string.lower(desc.Parent.Name) or ""
                if act == "interact" or string.find(act, "burn") or string.find(pName, "burn") or string.find(pName, "incin") or string.find(pName, "oven") then
                    if not string.find(pName, "door") and not string.find(pName, "exit") and not string.find(pName, "room") then
                        return desc
                    end
                end
            end
        end
    end
    return nil
end

-- ==========================================
-- COFFIN ROOM KONTROLÜ (V38 KUSURSUS RADAR)
-- ==========================================
local function isInCoffinRoom(rootPart)
    if not rootPart then return false end
    
    -- 300'den 75'e düşürüldü. Ayrıca aynı katta(Y ekseni) olup olmadığı kontrolü eklendi.
    local maxDistance = 75
    local maxYDiff = 20
    
    local ovenPrompt = getOvenPrompt()
    if ovenPrompt then
        local ovenPos = getPromptPos(ovenPrompt)
        if ovenPos then
            local dist = (rootPart.Position - ovenPos).Magnitude
            local yDiff = math.abs(rootPart.Position.Y - ovenPos.Y)
            if dist <= maxDistance and yDiff <= maxYDiff then
                return true
            end
        end
    end
    
    local coffinPrompt = getPrompt(CONFIG.CoffinKeywords, CONFIG.CoffinBlacklist, false)
    if coffinPrompt then
        local coffinPos = getPromptPos(coffinPrompt)
        if coffinPos then
            local dist = (rootPart.Position - coffinPos).Magnitude
            local yDiff = math.abs(rootPart.Position.Y - coffinPos.Y)
            if dist <= maxDistance and yDiff <= maxYDiff then
                return true
            end
        end
    end
    
    return false
end

-- ==========================================
-- YARDIMCI FONKSİYONLAR & HAREKET MOTORU
-- ==========================================
local function getCharacterParts()
    local character = LocalPlayer.Character
    if not character then return nil, nil, nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if rootPart and humanoid and humanoid.Health > 0 then return character, rootPart, humanoid end
    return nil, nil, nil
end

table.insert(Connections, RunService.Stepped:Connect(function()
    if IsMoving and CONFIG.NoclipOnMove and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end
end))

local function moveToPosition(targetPos, speedMultiplier)
    local _, rootPart, humanoid = getCharacterParts()
    if not rootPart or not humanoid then return false end
    if not isSafePos(targetPos, rootPart.Position) then return false end

    local multiplier = speedMultiplier or 1
    local safeOffset = Vector3.new(1.0, 2.5, 1.0) 
    local dest = targetPos + safeOffset

    IsMoving = true 

    if CONFIG.MovementMode == "Teleport" then
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.CFrame = CFrame.new(dest)
        task.wait(0.25)
        IsMoving = false
        return true
    else
        local distance = (rootPart.Position - dest).Magnitude
        local activeSpeed = CONFIG.TweenSpeed * multiplier
        local duration = math.clamp(distance / activeSpeed, 0.1, 12.0)
        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        
        local originalAnchored = rootPart.Anchored
        rootPart.Anchored = true
        rootPart.AssemblyLinearVelocity = Vector3.zero
        
        ActiveTween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(dest)})
        ActiveTween:Play()

        local completed = false
        local tweenConn
        tweenConn = ActiveTween.Completed:Connect(function() completed = true end)
        
        while not completed do
            if not (genv.AutoGuardExecute or genv.AutoGuardClean or genv.AutoGuardBurn or genv.AutoKitchen) then 
                ActiveTween:Cancel(); break 
            end
            task.wait(0.05)
        end
        
        if tweenConn then tweenConn:Disconnect() end 
        IsMoving = false 
        rootPart.AssemblyLinearVelocity = Vector3.zero
        task.wait(0.05) 
        rootPart.Anchored = originalAnchored 
        task.wait(0.05)
        
        return completed
    end
end

local function firePrompt(prompt, rootPart, targetPos, fastMode)
    if not prompt or not prompt.Parent or not targetPos then return false end
    
    local distance = (rootPart.Position - targetPos).Magnitude
    if distance > 30 then return false end 
    
    if not fastMode then
        local lookPos = Vector3.new(targetPos.X, rootPart.Position.Y, targetPos.Z)
        pcall(function() rootPart.CFrame = CFrame.lookAt(rootPart.Position, lookPos) end)
        task.wait(0.1)
    end
    
    if prompt and prompt.Parent and prompt:IsDescendantOf(Workspace) then
        local origHold = prompt.HoldDuration or 0
        local origLoS = prompt.RequiresLineOfSight
        pcall(function() prompt.RequiresLineOfSight = false end)
        
        if typeof(fireproximityprompt) == "function" then
            pcall(function() fireproximityprompt(prompt, 1, true) end)
        else
            pcall(function() prompt:InputHoldBegin() end)
            task.wait(origHold > 0 and origHold or 0.1)
            pcall(function() prompt:InputHoldEnd() end)
        end
        
        pcall(function() prompt.RequiresLineOfSight = origLoS end)
        return true
    end
    return false
end

-- ==========================================
-- GÖREV 1:
-- ==========================================
local function equipWeapon()
    local _, _, humanoid = getCharacterParts()
    local function checkTool(tool)
        if not tool:IsA("Tool") then return false end
        local lowerName = string.lower(tool.Name)
        for _, w in ipairs(CONFIG.WeaponNames) do if string.find(lowerName, w, 1, true) then return true end end
        return false
    end
    
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack and humanoid then
        for _, tool in ipairs(backpack:GetChildren()) do
            if checkTool(tool) then pcall(function() humanoid:EquipTool(tool) end) return tool end
        end
    end
    if LocalPlayer.Character then
        for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do if checkTool(tool) then return tool end end
    end
    return nil
end

local function checkAndExecuteTargets()
    if not genv.AutoGuardExecute then return false end
    local targetChar = nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local isEliminated = false
            for _, desc in ipairs(plr.Character:GetDescendants()) do
                if (desc:IsA("Highlight") and desc.FillColor.R > 0.5 and desc.FillColor.G < 0.5) or (desc:IsA("TextLabel") and string.find(string.lower(desc.Text), "eliminated")) then
                    isEliminated = true; break
                end
            end
            if isEliminated then targetChar = plr.Character; break end
        end
    end
    
    if targetChar then
        local weapon = equipWeapon()
        if not weapon then updateUIStatus("Silah Aranıyor..."); return false end
        task.wait(0.2) 
        
        local _, rootPart, humanoid = getCharacterParts()
        if rootPart then
            updateUIStatus("İnfaz Ediliyor: " .. targetChar.Name)
            local execStartTime = os.clock()
            local executed = false
            
            if humanoid then humanoid.AutoRotate = false end
            local tRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Head")
            if not tRoot then return false end

            -- 1. Hitbox'ı aşırı büyütme (7 birim mesafede içine girmemek için max 4-5 yap)
            
           local origSize = tRoot.Size
            local origTrans = tRoot.Transparency
            local origCamType = Camera and Camera.CameraType or Enum.CameraType.Custom
            local origMouseBehavior = UserInputService.MouseBehavior

            pcall(function()
                tRoot.Size = Vector3.new(4, 4, 4)
                tRoot.Transparency = 1
                -- Oyunun kamerasını devre dışı bırak ve fareyi ekranın tam ortasına kilitle
                if Camera then Camera.CameraType = Enum.CameraType.Scriptable end
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            end)
            
            local aimConn
            aimConn = RunService.RenderStepped:Connect(function()
                if targetChar and tRoot and rootPart and targetChar:FindFirstChild("Humanoid") and targetChar.Humanoid.Health > 0 then
                    local velocity = tRoot.AssemblyLinearVelocity
                    local aimPos = tRoot.Position + (velocity * 0.08) 
                    
                    local forwardDir = tRoot.CFrame.LookVector
                    local distance = 8
                    
                    local standPos = aimPos + (forwardDir * distance)
                    standPos = Vector3.new(standPos.X, aimPos.Y, standPos.Z)
                    
                    pcall(function()
                        -- Fareyi her karede ortada tut (oyun sıfırlarsa diye)
                        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

                        local lookCFrame = CFrame.lookAt(standPos, aimPos)
                        rootPart.CFrame = lookCFrame
                        
                        if Camera then
                            -- Kamerayı karakterin hemen arkasına/üstüne koy ve tam hedefe baktır
                            local camOffset = lookCFrame * CFrame.new(0, 1.5, 4)
                            Camera.CFrame = CFrame.lookAt(camOffset.Position, aimPos)
                        end
                    end)
                end
            end)

            -- Karakterin ve kameranın hedefe oturması için 1 kare bekle, sonra ateş et
            RunService.RenderStepped:Wait()
            pcall(function() weapon:Activate() end)
            
            while targetChar and targetChar:FindFirstChild("Humanoid") and targetChar.Humanoid.Health > 0 and genv.AutoGuardExecute do
                if os.clock() - execStartTime > 5 then break end 
                IsMoving = true
                -- Yarı otomatik silahlarda tek sefer Activate yetmeyebilir, döngüde tetikle
                pcall(function() weapon:Activate() end)
                task.wait(0.05) 
                executed = true
            end
            
            if aimConn then aimConn:Disconnect() end
            if humanoid then humanoid.AutoRotate = true end
            
            -- Her şeyi eski haline döndür
            pcall(function()
                if Camera then Camera.CameraType = origCamType end
                UserInputService.MouseBehavior = origMouseBehavior
                if tRoot then
                    tRoot.Size = origSize
                    tRoot.Transparency = origTrans
                end
            end)

            IsMoving = false
            pcall(function() weapon:Deactivate() end)
            
            return executed
        end
    end
    return false
end

-- ==========================================
-- GÖREV 2: BÖLGESEL BEDEN TEMİZLİĞİ
-- ==========================================
local function checkAndCleanBodies()
    if not genv.AutoGuardClean then return false end
    local _, myRoot, _ = getCharacterParts()
    if not myRoot then return false end

    local bodyPrompt = getPrompt(CONFIG.BodyKeywords, CONFIG.BodyBlacklist, false)
    if bodyPrompt then
        local targetPos = getPromptPos(bodyPrompt)
        if isSafePos(targetPos, myRoot.Position) and (myRoot.Position - targetPos).Magnitude <= CONFIG.MaxCleanDistance then
            updateUIStatus("Hızlı Beden Temizliği...")
            if moveToPosition(targetPos, 1.6) then
                local _, rPart, _ = getCharacterParts()
                if rPart then 
                    firePrompt(bodyPrompt, rPart, targetPos, true)
                    task.wait(0.1) 
                    return true 
                end
            end
        end
    end
    return false
end

-- ==========================================
-- GÖREV 3: OTO TABUT (Kati Coffin Room Kontrollü)
-- ==========================================
local function checkAndBurnCoffins()
    if not genv.AutoGuardBurn then return false end
    local _, myRoot, _ = getCharacterParts()
    if not myRoot then return false end
    
    if not isInCoffinRoom(myRoot) then
        updateUIStatus("Uyarı: Coffin Room'da olmalısınız!")
        task.wait(1.5)
        return false 
    end
    
    if CoffinData.State == "PICKUP" then
        local coffinPrompt = getPrompt(CONFIG.CoffinKeywords, CONFIG.CoffinBlacklist, false)
        if coffinPrompt then
            local targetPos = getPromptPos(coffinPrompt)
            if targetPos then
                updateUIStatus("1. Adım: Tabut Alınıyor")
                if moveToPosition(targetPos, 0.8) then 
                    local _, rPart, _ = getCharacterParts()
                    if rPart then 
                        firePrompt(coffinPrompt, rPart, targetPos, false)
                        task.wait(0.8) 
                        CoffinData.State = "WALK_TO_OVEN"
                        return true
                    end
                end
            end
        else
            updateUIStatus("Tabut: Bekleniyor/Aranıyor...")
        end

    elseif CoffinData.State == "WALK_TO_OVEN" then
        updateUIStatus("2. Adım: Fırına Yürünüyor")
        local ovenPos
        local ovenP = getOvenPrompt()
        if ovenP then ovenPos = getPromptPos(ovenP) end
        
        if not ovenPos then
            for _, desc in ipairs(Workspace:GetDescendants()) do
                if desc:IsA("ParticleEmitter") or desc:IsA("Fire") then
                    local pN = string.lower(desc.Parent.Name)
                    if string.find(pN, "burn") or string.find(pN, "oven") or string.find(pN, "fire") or string.find(pN, "part") then
                        ovenPos = desc.Parent.Position
                        break
                    end
                end
            end
        end
        
        if ovenPos then
            if moveToPosition(ovenPos, 0.8) then
                task.wait(0.3) 
                CoffinData.State = "BURN"
                return true
            end
        else
            updateUIStatus("Tabut: Fırın Bulunamadı!")
            task.wait(1)
            CoffinData.State = "PICKUP"
        end

    elseif CoffinData.State == "BURN" then
        updateUIStatus("3. Adım: Fırına Atılıyor")
        local burnPrompt = getOvenPrompt()
        if burnPrompt then
            local targetPos = getPromptPos(burnPrompt)
            if targetPos then
                local _, rPart, _ = getCharacterParts()
                if rPart then 
                    firePrompt(burnPrompt, rPart, targetPos, false)
                    task.wait(1.5) 
                    CoffinData.State = "PICKUP"
                    return true
                end
            end
        else
            CoffinData.State = "PICKUP"
        end
    end
    
    return false
end

-- ==========================================
-- GÖREV 4: AKILLI KITCHEN 
-- ==========================================
local function checkAndKitchenFarm()
    if not genv.AutoKitchen then return false end
    local _, myRoot, _ = getCharacterParts()
    if not myRoot then return false end
    
    local readyFood = getPrompt(CONFIG.KitchenReadyKeywords, CONFIG.KitchenBlacklist, false)
    local store = getPrompt(CONFIG.KitchenStoreKeywords, CONFIG.KitchenBlacklist, false)
    
    if readyFood and store then
        local readyPos = getPromptPos(readyFood)
        local storePos = getPromptPos(store)

        if readyPos and storePos then
            updateUIStatus("Zeka: Yemek Alınıyor...")
            if moveToPosition(readyPos, 0.6) then
                local _, rPart, _ = getCharacterParts()
                if rPart then firePrompt(readyFood, rPart, readyPos, false) end
                task.wait(0.3)
            end
            
            updateUIStatus("Zeka: Yemek Depolanıyor...")
            if moveToPosition(storePos, 0.6) then
                local _, rPart, _ = getCharacterParts()
                if rPart then firePrompt(store, rPart, storePos, false) end
                task.wait(0.3)
            end
            return true
        end
    end

    local stove = getPrompt(CONFIG.KitchenCookKeywords, CONFIG.KitchenBlacklist, false)
    local beef = getPrompt(CONFIG.KitchenBeefKeywords, CONFIG.KitchenBlacklist, false)
    local potato = getPrompt(CONFIG.KitchenPotatoKeywords, CONFIG.KitchenBlacklist, false)
    
    if stove and beef and potato then
        local beefPos = getPromptPos(beef)
        local potatoPos = getPromptPos(potato)
        local stovePos = getPromptPos(stove)

        if beefPos and potatoPos and stovePos then
            updateUIStatus("Zeka: Malzemeler Alınıyor...")
            if moveToPosition(beefPos, 0.6) then
                local _, rPart, _ = getCharacterParts()
                if rPart then firePrompt(beef, rPart, beefPos, false) end
                task.wait(0.3)
            end
            
            if moveToPosition(potatoPos, 0.6) then
                local _, rPart, _ = getCharacterParts()
                if rPart then firePrompt(potato, rPart, potatoPos, false) end
                task.wait(0.3)
            end
            
            updateUIStatus("Zeka: Ocağa Koyuluyor...")
            if moveToPosition(stovePos, 0.6) then
                local _, rPart, _ = getCharacterParts()
                if rPart then firePrompt(stove, rPart, stovePos, false) end
                task.wait(0.5)
            end
            return true
        end
    end
    
    if not beef or not potato then
        updateUIStatus("Zeka: Malzeme (Et/Patates) kalmadı, bekleniyor...")
    else
        updateUIStatus("Zeka: Yemekler pişiyor. Yeni eylem bekleniyor...")
    end
    
    task.wait(1) 
    return false
end

-- ==========================================
-- ANA DÖNGÜ
-- ==========================================
local function startGuardLogicLoop()
    if MainLoopRunning then return end
    MainLoopRunning = true
    while genv.AutoGuardExecute or genv.AutoGuardClean or genv.AutoGuardBurn or genv.AutoKitchen do
        local ok, err = pcall(function()
            local acted = false
            if genv.AutoGuardExecute then acted = checkAndExecuteTargets() end
            if not acted and genv.AutoGuardClean then acted = checkAndCleanBodies() end
            if not acted and genv.AutoKitchen then acted = checkAndKitchenFarm() end 
            if not acted and genv.AutoGuardBurn then acted = checkAndBurnCoffins() end
            
            if not acted then updateUIStatus("Bekleniyor..."); task.wait(0.5)
            else task.wait(0.2) end
        end)
        if not ok then task.wait(1) end
    end
    MainLoopRunning = false
    updateUIStatus("Durduruldu")
end

local function triggerLoop()
    if not MainLoopRunning and (genv.AutoGuardExecute or genv.AutoGuardClean or genv.AutoGuardBurn or genv.AutoKitchen) then task.spawn(startGuardLogicLoop) end
end

-- ==========================================
-- BUTON ETKİLEŞİMLERİ
-- ==========================================
FloatingBtn.Activated:Connect(function() MainFrame.Visible = not MainFrame.Visible end)
CloseBtn.Activated:Connect(function() MainFrame.Visible = false end)

ExecBtn.Activated:Connect(function()
    genv.AutoGuardExecute = not genv.AutoGuardExecute
    if genv.AutoGuardExecute then ExecBtn.BackgroundColor3 = Color3.fromRGB(46, 170, 95); ExecBtn.Text = "1. OTO-İNFAZ (100% İSABET): AÇIK"; triggerLoop()
    else ExecBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 60); ExecBtn.Text = "1. OTO-İNFAZ (100% İSABET): KAPALI" end
end)

CleanBtn.Activated:Connect(function()
    genv.AutoGuardClean = not genv.AutoGuardClean
    if genv.AutoGuardClean then CleanBtn.BackgroundColor3 = Color3.fromRGB(46, 170, 95); CleanBtn.Text = "2. BÖLGESEL BEDEN TEMİZLİĞİ: AÇIK"; triggerLoop()
    else CleanBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 60); CleanBtn.Text = "2. BÖLGESEL BEDEN TEMİZLİĞİ: KAPALI" end
end)

BurnBtn.Activated:Connect(function()
    genv.AutoGuardBurn = not genv.AutoGuardBurn
    if genv.AutoGuardBurn then 
        CoffinData.State = "PICKUP"
        BurnBtn.BackgroundColor3 = Color3.fromRGB(46, 170, 95); 
        BurnBtn.Text = "3. OTO TABUT (V38 SIRALI DÖNGÜ): AÇIK"; 
        triggerLoop()
    else 
        BurnBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 60); 
        BurnBtn.Text = "3. OTO TABUT (V38 SIRALI DÖNGÜ): KAPALI" 
    end
end)

KitchenBtn.Activated:Connect(function()
    genv.AutoKitchen = not genv.AutoKitchen
    if genv.AutoKitchen then 
        KitchenBtn.BackgroundColor3 = Color3.fromRGB(46, 170, 95)
        KitchenBtn.Text = "4. KITCHEN OTO-FARM (ZEKİ YAPAY ZEKA): AÇIK"
        triggerLoop()
    else 
        KitchenBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 60)
        KitchenBtn.Text = "4. KITCHEN OTO-FARM (ZEKİ YAPAY ZEKA): KAPALI" 
    end
end)

ModeBtn.Activated:Connect(function()
    if CONFIG.MovementMode == "Tween" then 
        CONFIG.MovementMode = "Teleport"; ModeBtn.Text = "Hareket: Teleport"
    else 
        CONFIG.MovementMode = "Tween"; ModeBtn.Text = "Hareket: Tween" 
    end
end)

genv.GuardCleanup = function()
    genv.AutoGuardExecute = false; genv.AutoGuardClean = false; genv.AutoGuardBurn = false; genv.AutoKitchen = false
    if ActiveTween then pcall(function() ActiveTween:Cancel() end) end
    for _, conn in ipairs(Connections) do pcall(function() conn:Disconnect() end) end
    table.clear(Connections)
    if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
end
