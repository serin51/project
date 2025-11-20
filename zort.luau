local Players = game:GetService("Players") 
local ReplicatedStorage = game:GetService("ReplicatedStorage") 
local RunService = game:GetService("RunService") 
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer


local screenGui = Instance.new("ScreenGui") 
screenGui.Name = "BackstabToggleGui" 
screenGui.ResetOnSpawn = false 
screenGui.Parent = lp:WaitForChild("PlayerGui")


local toggleButton = Instance.new("TextButton") 
toggleButton.Size = UDim2.new(0, 150, 0, 40) 
toggleButton.Position = UDim2.new(0, 10, 0, 10) 
toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30) 
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255) 
toggleButton.Font = Enum.Font.SourceSansBold 
toggleButton.TextSize = 20 
toggleButton.Text = "Backstab: OFF" 
toggleButton.Parent = screenGui


local rangeLabel = Instance.new("TextLabel") 
rangeLabel.Size = UDim2.new(0, 150, 0, 20) 
rangeLabel.Position = UDim2.new(0, 10, 0, 55) 
rangeLabel.BackgroundTransparency = 1 
rangeLabel.TextColor3 = Color3.fromRGB(255, 255, 255) 
rangeLabel.Font = Enum.Font.SourceSans 
rangeLabel.TextSize = 16 
rangeLabel.Text = "Range:" 
rangeLabel.Parent = screenGui


local rangeBox = Instance.new("TextBox") 
rangeBox.Size = UDim2.new(0, 150, 0, 25) 
rangeBox.Position = UDim2.new(0, 10, 0, 75) 
rangeBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50) 
rangeBox.TextColor3 = Color3.fromRGB(255, 255, 255) 
rangeBox.Font = Enum.Font.SourceSans 
rangeBox.TextSize = 16 
rangeBox.PlaceholderText = "studs" 
rangeBox.Text = "8" 
rangeBox.ClearTextOnFocus = false 
rangeBox.Parent = screenGui


local enabled = false 
local cooldown = false 
local lastTarget = nil 
local range = 8
local daggerRemote = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent") 
local killersFolder = workspace:WaitForChild("Players"):WaitForChild("Killers")


local KILLER_OFFSETS = {
    ["Guest666"] = 4.9,
    ["c00lkidd"] = 2.5,
    ["Slasher"] = 2.5,
    ["JohnDoe"] = 2.6,
    ["1x1x1x1"] = 2.7,
    ["Noli"] = 2.5
}


local spawnGrace = true
local GRACE_TIME = 6

local function startGracePeriod()
    spawnGrace = true
    task.delay(GRACE_TIME, function()
        spawnGrace = false
    end)
end

lp.CharacterAdded:Connect(startGracePeriod)
startGracePeriod()


toggleButton.MouseButton1Click:Connect(function() 
    enabled = not enabled 
    toggleButton.Text = "Backstab: " .. (enabled and "ON" or "OFF") 
    toggleButton.BackgroundColor3 = enabled and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(30, 30, 30) 
end)


rangeBox.FocusLost:Connect(function() 
    local input = tonumber(rangeBox.Text) 
    if input and input >= 1 then 
        range = input 
    else 
        rangeBox.Text = tostring(range) 
    end 
end)


local hideButton = Instance.new("TextButton")
hideButton.Size = UDim2.new(0, 50, 0, 40)
hideButton.Position = UDim2.new(0, 165, 0, 10)
hideButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
hideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hideButton.Font = Enum.Font.SourceSansBold
hideButton.TextSize = 20
hideButton.Text = "Hide"
hideButton.Parent = screenGui

local guiHidden = false
local guiElements = {}
for _, obj in ipairs(screenGui:GetChildren()) do
    if obj ~= hideButton then
        table.insert(guiElements, obj)
    end
end
hideButton.MouseButton1Click:Connect(function()
    guiHidden = not guiHidden
    hideButton.Text = guiHidden and "Show" or "Hide"
    for _, obj in ipairs(guiElements) do
        obj.Visible = not guiHidden
    end
end)


local function easeInOutSine(t)
    return -(math.cos(math.pi * t) - 1) / 2
end


local daggerCooldownText
local function refreshDaggerRef()
    local mainui = lp:FindFirstChild("PlayerGui"):FindFirstChild("MainUI")
    if mainui and mainui:FindFirstChild("AbilityContainer") then
        local dagger = mainui.AbilityContainer:FindFirstChild("Dagger")
        if dagger and dagger:FindFirstChild("CooldownTime") then
            daggerCooldownText = dagger.CooldownTime
            return
        end
    end
    daggerCooldownText = nil
end
lp.PlayerGui.DescendantAdded:Connect(refreshDaggerRef)
lp.PlayerGui.DescendantRemoving:Connect(function(obj)
    if obj == daggerCooldownText then
        daggerCooldownText = nil
    end
end)
refreshDaggerRef()


RunService.Heartbeat:Connect(function()
    if spawnGrace then return end 
    if not daggerCooldownText or not daggerCooldownText.Parent then return end
    if tonumber(daggerCooldownText.Text) then return end -- still on cooldown
    if not enabled or cooldown then return end
    
    local char = lp.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
    local hrp = char.HumanoidRootPart
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    for _, killer in ipairs(killersFolder:GetChildren()) do
        if killer:FindFirstChild("HumanoidRootPart") then
            local kHRP = killer.HumanoidRootPart
            local name = killer.Name
            local dist = (kHRP.Position - hrp.Position).Magnitude
            
            if dist <= range and not cooldown then
                cooldown = true
                lastTarget = killer

                if hum then
                    local oldSpeed = hum.WalkSpeed
                    hum.WalkSpeed = 0

                    local duration = 0.65 + math.random(15)/100
                    local fireTime = 0.325 + math.random(8)/100 
                    local offset = KILLER_OFFSETS[name] or 2.5
                    local start = tick()
                    local daggerFired = false
                    local followConn
                    
                    followConn = RunService.Heartbeat:Connect(function()
                        if not (char and kHRP and kHRP.Parent and hrp) then
                            if followConn then followConn:Disconnect() end
                            return
                        end

                        local elapsed = tick() - start
                        local alpha = math.clamp(elapsed / duration, 0, 1)
                        local eased = easeInOutSine(alpha)

                        local noise = Vector3.new(
                            math.noise(elapsed*10)*0.06, 0, math.noise(0,elapsed*10)*0.06
                        )
                        local targetCF = CFrame.new(
                            kHRP.Position - (kHRP.CFrame.LookVector * offset) + noise,
                            kHRP.Position
                        )

                        hrp.CFrame = hrp.CFrame:Lerp(targetCF, eased)

                        if not daggerFired and elapsed >= fireTime then
                            pcall(function()
                                daggerRemote:FireServer("UseActorAbility", "Dagger")
                            end)
                            daggerFired = true
                            if hum and hum.Parent then
                                hum.WalkSpeed = oldSpeed
                            end
                        end

                        if elapsed >= duration then
                            if followConn then followConn:Disconnect() end
                        end
                    end)

                    task.delay(duration + 0.2, function()
                        if hum and hum.Parent then
                            hum.WalkSpeed = oldSpeed
                        end
                        cooldown = false
                        lastTarget = nil
                    end)
                end
                return
            end
        end
    end
end)

-- what am i doing with my life