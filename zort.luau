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
toggleButton.Text = "backstab: off" 
toggleButton.Parent = screenGui


local rangeLabel = Instance.new("TextLabel") 
rangeLabel.Size = UDim2.new(0, 150, 0, 20) 
rangeLabel.Position = UDim2.new(0, 10, 0, 55) 
rangeLabel.BackgroundTransparency = 1 
rangeLabel.TextColor3 = Color3.fromRGB(255, 255, 255) 
rangeLabel.Font = Enum.Font.SourceSans 
rangeLabel.TextSize = 16 
rangeLabel.Text = "range:" 
rangeLabel.Parent = screenGui


local rangeBox = Instance.new("TextBox") 
rangeBox.Size = UDim2.new(0, 150, 0, 25) 
rangeBox.Position = UDim2.new(0, 10, 0, 75) 
rangeBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50) 
rangeBox.TextColor3 = Color3.fromRGB(255, 255, 255) 
rangeBox.Font = Enum.Font.SourceSans 
rangeBox.TextSize = 16 
rangeBox.PlaceholderText = "studs" 
rangeBox.Text = "4" 
rangeBox.ClearTextOnFocus = false 
rangeBox.Parent = screenGui

-- vars, do not change or else won't work
local enabled = false 
local cooldown = false 
local lastTarget = nil 
local range = 4 
local daggerRemote = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent") 
local killerNames = { "Slasher", "c00lkidd", "JohnDoe", "1x1x1x1", "Noli", "Guest666" }
local killersFolder = workspace:WaitForChild("Players"):WaitForChild("Killers")


local spawnGrace = true
local GRACE_TIME = 6

local function startGracePeriod()
	spawnGrace = true
	task.delay(GRACE_TIME, function()
		spawnGrace = false
	end)
end

lp.CharacterAdded:Connect(startGracePeriod)
startGracePeriod() -- initial


toggleButton.MouseButton1Click:Connect(function() 
    enabled = not enabled 
    toggleButton.Text = "Backstab: " .. (enabled and "on" or "off") 
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


local mode = "behind" 
local modeButton = Instance.new("TextButton") 
modeButton.Size = UDim2.new(0, 150, 0, 25) 
modeButton.Position = UDim2.new(0, 10, 0, 105) 
modeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70) 
modeButton.TextColor3 = Color3.fromRGB(255, 255, 255) 
modeButton.Font = Enum.Font.SourceSans 
modeButton.TextSize = 16 
modeButton.Text = "mode: behind" 
modeButton.Parent = screenGui

modeButton.MouseButton1Click:Connect(function() 
    mode = (mode == "Behind") and "around" or "behind" 
    modeButton.Text = "mode: " .. mode 
end)


local attackType = "normal"
local attackButton = Instance.new("TextButton")
attackButton.Size = UDim2.new(0, 150, 0, 25)
attackButton.Position = UDim2.new(0, 10, 0, 135)
attackButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
attackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
attackButton.Font = Enum.Font.SourceSans
attackButton.TextSize = 16
attackButton.Text = "backstab Type: normal"
attackButton.Parent = screenGui

attackButton.MouseButton1Click:Connect(function()
    if attackType == "normal" then
        attackType = "counter"
    elseif attackType == "counter" then
        attackType = "legit"
    elseif attackType == "legit" then
        attackType = "normal"
    end
    attackButton.Text = "backstab type: " .. attackType
end)


local hideButton = Instance.new("TextButton")
hideButton.Size = UDim2.new(0, 50, 0, 40)
hideButton.Position = UDim2.new(0, 165, 0, 10)
hideButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
hideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hideButton.Font = Enum.Font.SourceSansBold
hideButton.TextSize = 20
hideButton.Text = "hide"
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
	hideButton.Text = guiHidden and "show" or "hide"
	for _, obj in ipairs(guiElements) do
		obj.Visible = not guiHidden
	end
end)


local counterAnimIDs = {
	"126830014841198","126355327951215","121086746534252","18885909645",
	"98456918873918","105458270463374","83829782357897","125403313786645",
	"118298475669935","82113744478546","70371667919898","99135633258223",
	"97167027849946","109230267448394","139835501033932","126896426760253",
	"109667959938617","126681776859538","129976080405072","121293883585738",
	"81639435858902","137314737492715","92173139187970"
}

local function killerPlayingCounterAnim(killer)
    local humanoid = killer:FindFirstChildOfClass("Humanoid")
    if not humanoid or not humanoid:FindFirstChildOfClass("Animator") then return false end
    for _, track in ipairs(humanoid.Animator:GetPlayingAnimationTracks()) do
        if track.Animation and track.Animation.AnimationId then
            local animIdNum = track.Animation.AnimationId:match("%d+")
            for _, id in ipairs(counterAnimIDs) do
                if tostring(animIdNum) == id then
                    return true
                end
            end
        end
    end
    return false
end


local function isBehindTarget(hrp, targetHRP) 
    local distance = (hrp.Position - targetHRP.Position).Magnitude 
    if distance > range then return false end 
    if mode == "around" then return true end 
    local direction = -targetHRP.CFrame.LookVector 
    local toPlayer = (hrp.Position - targetHRP.Position) 
    return toPlayer:Dot(direction) > 0.5 
end


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


RunService.RenderStepped:Connect(function()
    if spawnGrace then return end 
    if not daggerCooldownText or not daggerCooldownText.Parent then return end
    if tonumber(daggerCooldownText.Text) then return end -- still on cooldown
    if not enabled or cooldown then return end
    
	local char = lp.Character
	if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
	local hrp = char.HumanoidRootPart
	
	for _, name in ipairs(killerNames) do
		local killer = killersFolder:FindFirstChild(name)
		if killer and killer:FindFirstChild("HumanoidRootPart") then
			local kHRP = killer.HumanoidRootPart

            -- comolo muevelo
            if attackType == "legit" then
                local dist = (kHRP.Position - hrp.Position).Magnitude
                if dist <= range and not cooldown then
                    cooldown = true
                    lastTarget = killer

                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local oldSpeed = hum.WalkSpeed
                        hum.WalkSpeed = 0 -- lock movement

                        local start = tick()
                        local daggerFired = false
                        local followConn
                        followConn = RunService.Heartbeat:Connect(function()
                            if not (char and kHRP and kHRP.Parent and hrp and hrp.Parent) then
                                if followConn then followConn:Disconnect() end
                                return
                            end

                            local elapsed = tick() - start
                            local alpha = math.clamp(elapsed / 0.8, 0, 1)
                            local eased = easeInOutSine(alpha)

                            
                            local G_666 = (name == "Guest666")

local baseStart = G_666 and 4 or 1.75
local baseEnd = G_666 and 5 or 3

local offset
if elapsed <= 0.25 then
    offset = baseStart
else
    local t = math.clamp((elapsed - 0.25) / 0.55, 0, 1)
    offset = baseStart + (baseEnd - baseStart) * t
end
                            local targetCF = CFrame.new(
                                kHRP.Position - (kHRP.CFrame.LookVector * offset),
                                kHRP.Position
                            )

                            hrp.CFrame = hrp.CFrame:Lerp(targetCF, eased)

                            if not daggerFired and elapsed >= 0.4 then
                                daggerRemote:FireServer("UseActorAbility", "Dagger")
                                daggerFired = true
                            end

                            if elapsed >= 0.8 then
                                if followConn then followConn:Disconnect() end
                            end
                        end)

                        task.delay(0.7, function()
                            if hum and hum.Parent then
                                hum.WalkSpeed = oldSpeed
                            end
                            cooldown = false
                            lastTarget = nil
                        end)
                    end
                end
                return
            end

            
            if attackType == "counter" and not killerPlayingCounterAnim(killer) then
            	continue
            end

            
			if isBehindTarget(hrp, kHRP) and killer ~= lastTarget then
				cooldown = true
				lastTarget = killer

				hrp.CFrame = CFrame.new(
                    kHRP.Position - (kHRP.CFrame.LookVector * 0.3),
                    kHRP.Position
                )
				daggerRemote:FireServer("UseActorAbility", "Dagger")

				task.delay(2, function()
					lastTarget = nil
					cooldown = false
				end)
				break
			end
		end
	end
end)

-- what am i doing with my life
print("ahahassjhahajsjjsjwlwlznnz")