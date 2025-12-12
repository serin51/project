local qqq = "[debug] script loaded"
print(qqq)
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not ok or not Rayfield then
    warn("ray.err: failed to load rayfield")
    return
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer


local Window = Rayfield:CreateWindow({
    Name = "ZortSaken V0.5",
    LoadingTitle = "ZortSaken [ WIP ] V0.5",
    LoadingSubtitle = "ser.in on discord",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = "ZortSaken",
        FileName = "Config"
    },
    Discord = { Enabled = false },
    KeySystem = false
})

-- tabs
local espTab = Window:CreateTab("ESP")
local StaminaTab = Window:CreateTab("Stamina Modification")
local SurvivorsTab = Window:CreateTab("Survivors")
local KillersTab = Window:CreateTab("Killers")
local GenTab = Window:CreateTab("Generators")
local FunTab = Window:CreateTab("Fun")
local MiscTab = Window:CreateTab("Misc")

-- sections
StaminaTab:CreateSection("Stamina Modification")
KillersTab:CreateSection("Slasher")
SurvivorsTab:CreateSection("Veeronica")
FunTab:CreateSection("device spoofer")

-- esp
local EspEnabled = false
local ShowSurvivors = true
local ShowKillers = true
local ShowGenerators = true
local ShowGenDone = true
local ShowFakeGen = true
local ShowItems = true

-- transparency
local FillTransparency = 0.65
local OutlineTransparency = 0.95

-- customiser
espTab:CreateSection("Transparency customiser")

espTab:CreateInput({
    Name = "Outline transparency (0-1)",
    Flag = "OutTrans",
    PlaceholderText = tostring(OutlineTransparency),
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local num = tonumber(text)
        if num and num >= 0 and num <= 1 then
            OutlineTransparency = num
        end
    end,
})

espTab:CreateInput({
    Name = "Fill transparency (0-1)",
    Flag = "FillTrans",
    PlaceholderText = tostring(FillTransparency),
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local num = tonumber(text)
        if num and num >= 0 and num <= 1 then
            FillTransparency = num
        end
    end,
})

espTab:CreateSection("Highlight ESP")
-- folders
local killersFolder = Workspace:WaitForChild("Players"):WaitForChild("Killers")
local survivorsFolder = Workspace:WaitForChild("Players"):WaitForChild("Survivors")

-- colors
local Colors = {
    Survivor = Color3.fromRGB(0,120,255),
    Killer = Color3.fromRGB(255,50,50),
    FakeNoli = Color3.fromRGB(120,0,0),
    Gen = Color3.fromRGB(170,0,255),
    GenDone = Color3.fromRGB(0,255,0),
    FakeGen = Color3.fromRGB(150,0,0),
    Item = Color3.fromRGB(255,255,0)
}

local highlights = {}
local itemHighlights = {}

-- fake noli scanner
local noliByUsername = {}

local function scanNoli()
    noliByUsername = {}

    for _, killer in ipairs(killersFolder:GetChildren()) do
        if killer:GetAttribute("ActorDisplayName") == "Noli" then
            local uname = killer:GetAttribute("Username")
            if uname then
                noliByUsername[uname] = noliByUsername[uname] or {}
                table.insert(noliByUsername[uname], killer)
            end
        end
    end

    for _, list in pairs(noliByUsername) do
        for i, model in ipairs(list) do
            model:SetAttribute("IsFakeNoli", i > 1)
        end
    end
end

-- highlight utils
local function getHighlight(obj)
    if highlights[obj] then return highlights[obj] end

    local h = Instance.new("Highlight")
    h.Adornee = obj
    h.FillTransparency = FillTransparency
    h.OutlineTransparency = OutlineTransparency
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = obj

    highlights[obj] = h
    return h
end

local function cleanHighlights()
    for obj, h in pairs(highlights) do
        if not obj or not obj.Parent then
            h:Destroy()
            highlights[obj] = nil
        end
    end
end

-- what
local EspEnabled = true
local ShowKillers = true
local ShowSurvivors = true
local ShowGenerators = true
local ShowGenDone = true
local ShowFakeGen = true
local ShowItems = true

RunService.RenderStepped:Connect(function()
    if not EspEnabled then
        for _, h in pairs(highlights) do h.Enabled = false end
        return
    end

    cleanHighlights()
    scanNoli()

    -- survivors
    for _, char in ipairs(survivorsFolder:GetChildren()) do
        local h = getHighlight(char)
        h.Enabled = ShowSurvivors
        h.FillColor = Colors.Survivor
        h.OutlineColor = Colors.Survivor
    end

    -- killers
    for _, char in ipairs(killersFolder:GetChildren()) do
        local h = getHighlight(char)

        local uname = char:GetAttribute("Username")
        local isFake = false

        if uname and noliByUsername[uname] then
            isFake = char:GetAttribute("IsFakeNoli") == true
        end

        if isFake then
            h.FillColor = Colors.FakeNoli
            h.OutlineColor = Colors.FakeNoli
        else
            h.FillColor = Colors.Killer
            h.OutlineColor = Colors.Killer
        end

        h.Enabled = ShowKillers
    end

    -- map stuff
    local mapObj = Workspace:FindFirstChild("Map")
    if mapObj and mapObj:FindFirstChild("Ingame") and mapObj.Ingame:FindFirstChild("Map") then
        for _, obj in ipairs(mapObj.Ingame.Map:GetChildren()) do

            if obj.Name == "Generator" then
                local h = getHighlight(obj)
                local prog = obj:FindFirstChild("Progress") and obj.Progress.Value or 0

                if prog >= 100 then
                    h.FillColor = Colors.GenDone
                    h.OutlineColor = Colors.GenDone
                    h.Enabled = ShowGenDone
                else
                    h.FillColor = Colors.Gen
                    h.OutlineColor = Colors.Gen
                    h.Enabled = ShowGenerators
                end

            elseif obj.Name == "FakeGenerator" then
                local h = getHighlight(obj)
                h.FillColor = Colors.FakeGen
                h.OutlineColor = Colors.FakeGen
                h.Enabled = ShowFakeGen

            elseif obj.Name == "BloxyCola" or obj.Name == "Medkit" then
                if ShowItems then
                    local h = getHighlight(obj)
                    h.FillColor = Colors.Item
                    h.OutlineColor = Colors.Item
                    h.Enabled = true
                end
            end
        end
    end
end)

-- ui
espTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Callback = function(v)
        EspEnabled = v
    end
})

espTab:CreateToggle({
    Name = "Show survivors",
    CurrentValue = true,
    Callback = function(v)
        ShowSurvivors = v
    end
})

espTab:CreateToggle({
    Name = "Show killers",
    CurrentValue = true,
    Callback = function(v)
        ShowKillers = v
    end
})

espTab:CreateToggle({
    Name = "Show generators",
    CurrentValue = true,
    Callback = function(v)
        ShowGenerators = v
    end
})

espTab:CreateToggle({
    Name = "Show green gen when done",
    CurrentValue = true,
    Callback = function(v)
        ShowGenDone = v
    end
})

espTab:CreateToggle({
    Name = "Show fake generators",
    CurrentValue = true,
    Callback = function(v)
        ShowFakeGen = v
    end
})

espTab:CreateToggle({
    Name = "Show items",
    CurrentValue = true,
    Callback = function(v)
        ShowItems = v
    end
})

espTab:CreateSection("Color customiser")
-- col pickers
espTab:CreateColorPicker({
    Name = "Survivor color",
    Color = Colors.Survivor,
    Callback = function(c)
        Colors.Survivor = c
    end
})

espTab:CreateColorPicker({
    Name = "Killer color",
    Color = Colors.Killer,
    Callback = function(c)
        Colors.Killer = c
    end
})

espTab:CreateColorPicker({
    Name = "Generator color",
    Color = Colors.Gen,
    Callback = function(c)
        Colors.Gen = c
    end
})

espTab:CreateColorPicker({
    Name = "Gen done color",
    Color = Colors.GenDone,
    Callback = function(c)
        Colors.GenDone = c
    end
})

espTab:CreateColorPicker({
    Name = "Fake gen color",
    Color = Colors.FakeGen,
    Callback = function(c)
        Colors.FakeGen = c
    end
})

espTab:CreateColorPicker({
    Name = "Item color",
    Color = Colors.Item,
    Callback = function(c)
        Colors.Item = c
    end
})

-- stamina mod
local maxStamina = 100
local minStamina = 0
local staminaGain = 20
local staminaLoss = 10
local sprintSpeed = 26
local staminaLossDisabled = false

StaminaTab:CreateInput({
    Name = "Max stamina",
    PlaceholderText = "100",
    CurrentValue = tostring(maxStamina),
    RemoveTextAfterFocusLost = false,
    Callback = function(t)
        maxStamina = tonumber(t) or maxStamina
    end
})

StaminaTab:CreateInput({
    Name = "Min stamina",
    PlaceholderText = "0",
    CurrentValue = tostring(minStamina),
    RemoveTextAfterFocusLost = false,
    Callback = function(t)
        minStamina = tonumber(t) or minStamina
    end
})

StaminaTab:CreateInput({
    Name = "Stamina gain per sec",
    PlaceholderText = "20",
    CurrentValue = tostring(staminaGain),
    RemoveTextAfterFocusLost = false,
    Callback = function(t)
        staminaGain = tonumber(t) or staminaGain
    end
})

StaminaTab:CreateInput({
    Name = "Stamina loss per sec",
    PlaceholderText = "10",
    CurrentValue = tostring(staminaLoss),
    RemoveTextAfterFocusLost = false,
    Callback = function(t)
        staminaLoss = tonumber(t) or staminaLoss
    end
})

StaminaTab:CreateInput({
    Name = "Sprint speed",
    PlaceholderText = "26",
    CurrentValue = tostring(sprintSpeed),
    RemoveTextAfterFocusLost = false,
    Callback = function(t)
        sprintSpeed = tonumber(t) or sprintSpeed
    end
})

StaminaTab:CreateToggle({
    Name = "Inf stamina",
    CurrentValue = false,
    Callback = function(v)
        staminaLossDisabled = v
    end
})

-- continuously update player stamina values
task.spawn(function()
    local sprintModule = require(ReplicatedStorage.Systems.Character.Game.Sprinting)

    while task.wait() do
        sprintModule.MaxStamina = maxStamina
        sprintModule.MinStamina = minStamina
        sprintModule.StaminaGain = staminaGain
        sprintModule.StaminaLoss = staminaLossDisabled and 0 or staminaLoss
        sprintModule.SprintSpeed = sprintSpeed
        sprintModule.StaminaLossDisabled = staminaLossDisabled
    end
end)

-- vulnnenenenene
local VulTab = Window:CreateTab("Vulnerabilities")

-- 1x
VulTab:CreateSection("1x1x1x1")

local DoLoop = false

VulTab:CreateToggle({
    Name = "Auto close 1x popups (entanglement)",
    CurrentValue = false,
    Flag = "Toggle1x1Popup",
    Callback = function(v)
        DoLoop = v
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local Survivors = workspace:WaitForChild("Players"):WaitForChild("Survivors")
            while DoLoop and task.wait() do
              
               task.wait(getDelay())
               
                local temp = player.PlayerGui:FindFirstChild("TemporaryUI")
                if temp and temp:FindFirstChild("1x1x1x1Popup") then
                    temp["1x1x1x1Popup"]:Destroy()
                end
                for _, survivor in pairs(Survivors:GetChildren()) do
                    if survivor:GetAttribute("Username") == player.Name then
                        local speedMultipliers = survivor:FindFirstChild("SpeedMultipliers")
                        if speedMultipliers then
                            local val = speedMultipliers:FindFirstChild("SlowedStatus")
                            if val and val:IsA("NumberValue") then
                                val.Value = 1
                            end
                        end
                        local fovMultipliers = survivor:FindFirstChild("FOVMultipliers")
                        if fovMultipliers then
                            local val = fovMultipliers:FindFirstChild("SlowedStatus")
                            if val and val:IsA("NumberValue") then
                                val.Value = 1
                            end
                        end
                    end
                end
            end
        end)
    end
})

-- ?
VulTab:CreateSlider({
    Name = "Popup close delay",
    Range = {0, 3},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = DelayTime,
    Callback = function(v)
        DelayTime = v
    end
})

-- auto qte
VulTab:CreateSection("Nosferatu")

local autoQTE = false

VulTab:CreateToggle({
    Name = "Auto do nosferatu qte (mobile)",
    CurrentValue = false,
    Flag = "AutoQTE",
    Callback = function(v)
        autoQTE = v

        task.spawn(function()
            while autoQTE and task.wait() do

                local tempUI = game.Players.LocalPlayer.PlayerGui:FindFirstChild("TemporaryUI")
                if not tempUI then continue end

                local qte = tempUI:FindFirstChild("QTE")
                if not qte then continue end

                local button = qte:FindFirstChild("ActiveButton")
                if not button then continue end

                for _, conn in ipairs(getconnections(button.MouseButton1Down)) do
                    conn.Function()
                end
            end
        end)
    end
})

-- vee auto trick
local veeronicaTrickEnabled = false
local VIM = game:GetService("VirtualInputManager")
local behaviorFolder = ReplicatedStorage:WaitForChild("Assets")
                    :WaitForChild("Survivors")
                    :WaitForChild("Veeronica")
                    :WaitForChild("Behavior")

local activeMonitors = {}
local descendantConn = nil

local function getSprintingButton()
    local mainUI = lp.PlayerGui:FindFirstChild("MainUI")
    if mainUI then
        return mainUI:FindFirstChild("SprintingButton")
    end
end

local function pressSprint()
    if UserInputService.TouchEnabled then
        local btn = getSprintingButton()
        if btn then
            for _, conn in pairs(getconnections(btn.MouseButton1Down)) do
                pcall(conn.Fire, conn)
            end
        end
    else
        VIM:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
    end
end

local function monitorHighlight(highlight)
    if not highlight or activeMonitors[highlight] then return end

    local connections = {}
    local wasOnPlayer = false

    local function cleanup()
        for _, c in ipairs(connections) do
            if c.Connected then c:Disconnect() end
        end
        activeMonitors[highlight] = nil
    end

    local function check()
        if not veeronicaTrickEnabled or not highlight.Parent then
            cleanup()
            return
        end

        local char = lp.Character
        if not char then return end

        local onPlayer = highlight.Adornee and (highlight.Adornee == char or highlight.Adornee:IsDescendantOf(char))
        if onPlayer and not wasOnPlayer then
            pressSprint()
        end
        wasOnPlayer = onPlayer
    end

    table.insert(connections, highlight:GetPropertyChangedSignal("Adornee"):Connect(check))
    table.insert(connections, highlight.AncestryChanged:Connect(check))
    table.insert(connections, lp.CharacterAdded:Connect(check))
    table.insert(connections, lp.CharacterRemoving:Connect(check))

    activeMonitors[highlight] = cleanup
    task.spawn(check)
end

local function startVeeronicaTrick()
    if descendantConn then return end

    for _, obj in behaviorFolder:GetDescendants() do
        if obj:IsA("Highlight") then
            monitorHighlight(obj)
        end
    end

    descendantConn = behaviorFolder.DescendantAdded:Connect(function(child)
        if child:IsA("Highlight") then
            task.wait()
            monitorHighlight(child)
        end
    end)
end

local function stopVeeronicaTrick()
    if descendantConn then
        descendantConn:Disconnect()
        descendantConn = nil
    end

    for _, cleanup in pairs(activeMonitors) do
        pcall(cleanup)
    end

    activeMonitors = {}
end

SurvivorsTab:CreateToggle({
    Name = "Vee auto trick",
    CurrentValue = false,
    Callback = function(v)
        veeronicaTrickEnabled = v
        if v then
            startVeeronicaTrick()
        else
            stopVeeronicaTrick()
        end
    end
})

-- auto gen yeye :p
local enabled = false
local taskRef
local dur = 4  -- default wait duration

GenTab:CreateSection("Auto do gen")

GenTab:CreateToggle({
    Name = "Auto do gen (remote)",
    CurrentValue = false,
    Callback = function(v)
        enabled = v
        if v then
            local last = tick()
            taskRef = task.spawn(function()
                while enabled do
                    task.wait(0.1)
                    if tick() - last >= dur then
                        local map = workspace:FindFirstChild("Map")
                        if map and map:FindFirstChild("Ingame") and map.Ingame:FindFirstChild("Map") then
                            for _, gen in ipairs(map.Ingame.Map:GetChildren()) do
                                if gen.Name == "Generator" and gen:FindFirstChild("Remotes") and gen.Remotes:FindFirstChild("RE") then
                                    gen.Remotes.RE:FireServer()
                                end
                            end
                        end
                        last = tick()
                    end
                end
            end)
        elseif taskRef then
            task.cancel(taskRef)
            taskRef = nil
        end
    end
})

GenTab:CreateSlider({
    Name = "Wait duration between each puzzle",
    Range = {2, 10},
    Increment = 0.5,
    Suffix = " sec",
    CurrentValue = dur,
    Callback = function(v)
        dur = v
    end
})

GenTab:CreateButton({
    Name = "Complete 1 gen puzzle (one-time)",

    Callback = function()
        local m = workspace:FindFirstChild("Map")

        if m 
        and m:FindFirstChild("Ingame") 
        and m.Ingame:FindFirstChild("Map") 
        then
            for _, v in pairs(m.Ingame.Map:GetChildren()) do
                
                if v:IsA("Model") and v.Name == "Generator" then
                    
                    local r = v:FindFirstChild("Remotes") 
                        and v.Remotes:FindFirstChild("RE")

                    if not r then 
                        return 
                    end

                    pcall(function()
                        r:FireServer()
                    end)
                end
            end
        end
    end
})

-- device spoof :3
local Network

-- try require network module
pcall(function()
    if ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Network") then
        Network = require(ReplicatedStorage.Modules.Network)
    elseif ReplicatedStorage:FindFirstChild("Network") then
        Network = require(ReplicatedStorage.Network)
    end
end)

-- detect default device
local function detectOriginalDevice()
    local input = UserInputService:GetLastInputType()
    if input.Name:find("Gamepad") then return "Console" end
    if input.Name:find("Touch") then return "Mobile" end
    return "PC"
end

local originalDevice = detectOriginalDevice()
getgenv().selectedDevice = originalDevice
getgenv().spoofDeviceEnabled = false

-- apply spoof
local function applyDeviceSpoof()
    if not getgenv().spoofDeviceEnabled then return end
    local device = getgenv().selectedDevice
    if Network then
        pcall(function()
            Network:FireServerConnection("SetDevice", "REMOTE_EVENT", device)
        end)
    end
    statusLabel:Set(getDeviceLabel())
end

-- toggle
FunTab:CreateToggle({
    Name = "Device spoofer fe",
    CurrentValue = getgenv().spoofDeviceEnabled,
    Flag = "SpoofDeviceToggle",
    Callback = function(v)
        getgenv().spoofDeviceEnabled = v
        applyDeviceSpoof()
    end,
})

-- dropdown
FunTab:CreateDropdown({
    Name = "Choose device to spoof",
    Options = {"PC", "Mobile", "Console"},
    CurrentOption = {getgenv().selectedDevice},
    MultipleOptions = false,
    Callback = function(selectedOption)
        getgenv().selectedDevice = selectedOption[1]
        if getgenv().spoofDeviceEnabled then
            applyDeviceSpoof()
        end
    end,
})

-- auto raging pace skibidi
local savedRangeRaging = lp:FindFirstChild("RagingPaceRange")
if not savedRangeRaging then
    savedRangeRaging = Instance.new("NumberValue")
    savedRangeRaging.Name = "RagingPaceRange"
    savedRangeRaging.Value = 17.5
    savedRangeRaging.Parent = lp
end

local RANGE_RAGING = savedRangeRaging.Value
local SPAM_DURATION = 3
local COOLDOWN_TIME = 5
local activeCooldownsRaging = {}
local enabledRaging = false

-- anims
local animsToDetectRaging = {
    ["72722244508749"] = false,
    ["77448521277146"] = true,
    ["86096387000557"] = true,
    ["86371356500204"] = true,
    ["86545133269813"] = true,
    ["86709774283672"] = true,
    ["87259391926321"] = true,
    ["89448354637442"] = true,
    ["96959123077498"] = false,
    ["103601716322988"] = true,
    ["108807732150251"] = true,
    ["115194624791339"] = true,
    ["116618003477002"] = true,
    ["119462383658044"] = true,
    ["121255898612475"] = true,
    ["131696603025265"] = true,
    ["133491532453922"] = true,
    ["136007065400978"] = true,
    ["138040001965654"] = true,
    ["140703210927645"] = true,
}

local function fireSkill(skillName)
    local args = {"UseActorAbility", { buffer.fromstring("\""..skillName.."\"") }}
    ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
end

local function isAnimationMatching(anim)
    if not anim or not anim.Animation then return false end
    local id = anim.Animation.AnimationId
    local numId = id:match("%d+")
    return animsToDetectRaging[numId] == true
end

local function detectAndSpam()
    for _, player in ipairs(Players:GetPlayers()) do
        
        if player ~= lp 
        and player.Character 
        and player.Character:FindFirstChild("HumanoidRootPart") 
        then
            local targetHRP = player.Character.HumanoidRootPart
            local myChar = lp.Character

            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                
                local dist = (targetHRP.Position - myChar.HumanoidRootPart.Position).Magnitude

                if dist <= RANGE_RAGING 
                and (not activeCooldownsRaging[player] 
                or tick() - activeCooldownsRaging[player] >= COOLDOWN_TIME) 
                then
                    
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        
                        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                            
                            if isAnimationMatching(track) then
                                
                                activeCooldownsRaging[player] = tick()

                                task.spawn(function()
                                    local startTime = tick()

                                    while tick() - startTime < SPAM_DURATION do
                                        fireSkill("RagingPace")
                                        task.wait(0.05)
                                    end
                                end)

                                break
                            end
                        end
                    end
                end
            end
        end

    end
end

RunService.RenderStepped:Connect(function()
    if enabledRaging then
        detectAndSpam()
    end
end)

KillersTab:CreateToggle({
    Name = "Auto raging pace (parry)",
    CurrentValue = false,
    Flag = "RagingPaceToggle",
    Callback = function(value)
        enabledRaging = value
    end,
})
KillersTab:CreateInput({
    Name = "Raging pace parry range (studs)",
    Flag = "RagingPaceRangestuds",
    PlaceholderText = tostring(RANGE_RAGING),
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local num = tonumber(text)
        if num and num > 0 then
            RANGE_RAGING = num
            savedRangeRaging.Value = num
        end
    end,
})

-- 404
local savedRange404 = lp:FindFirstChild("Error404Range")
if not savedRange404 then
    savedRange404 = Instance.new("NumberValue")
    savedRange404.Name = "Error404Range"
    savedRange404.Value = 17.5
    savedRange404.Parent = lp
end

-- c.e
KillersTab:CreateSection("John sahur")

local savedRangeCorrupt = lp:FindFirstChild("CorruptEnergyRange")
if not savedRangeCorrupt then
    savedRangeCorrupt = Instance.new("NumberValue")
    savedRangeCorrupt.Name = "CorruptEnergyRange"
    savedRangeCorrupt.Value = 19
    savedRangeCorrupt.Parent = lp
end

local RANGE_404 = savedRange404.Value
local RANGE_CORRUPT = savedRangeCorrupt.Value

-- spam
local SPAM_DURATION = 3
local COOLDOWN_TIME = 5
local activeCooldowns404 = {}
local activeCooldownsCorrupt = {}
local enabled404 = false
local enabledCorrupt = false

-- anims
local animsToDetect404 = {
    ["72722244508749"] = false,
    ["77448521277146"] = true,
    ["86096387000557"] = true,
    ["86371356500204"] = true,
    ["86545133269813"] = true,
    ["86709774283672"] = true,
    ["87259391926321"] = true,
    ["89448354637442"] = true,
    ["96959123077498"] = false,
    ["103601716322988"] = true,
    ["108807732150251"] = true,
    ["115194624791339"] = true,
    ["116618003477002"] = true,
    ["119462383658044"] = true,
    ["121255898612475"] = true,
    ["131696603025265"] = true,
    ["133491532453922"] = true,
    ["136007065400978"] = true,
    ["138040001965654"] = true,
    ["140703210927645"] = true,
}
local animsToDetectCorrupt = animsToDetect404

-- fire sigma
local function fireSkill(skillName)
    local args = {"UseActorAbility", { buffer.fromstring("\""..skillName.."\"")}}
    ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
end

-- check
local function isAnimationMatching(anim, animTable)
    if not anim or not anim.Animation then return false end
    local id = anim.Animation.AnimationId
    if type(id) ~= "string" then return false end
    local numId = id:match("%d+")
    if not numId then return false end
    return animTable[numId] == true
end

-- detect
local function detectAndSpam(skillName, range, cooldownTable, animTable)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = player.Character.HumanoidRootPart
            local myChar = lp.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local dist = (targetHRP.Position - myChar.HumanoidRootPart.Position).Magnitude
                if dist <= range and (not cooldownTable[player] or tick() - cooldownTable[player] >= COOLDOWN_TIME) then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                            if isAnimationMatching(track, animTable) then
                                cooldownTable[player] = tick()
                                task.spawn(function()
                                    local startTime = tick()
                                    while tick() - startTime < SPAM_DURATION do
                                        fireSkill(skillName)
                                        task.wait(0.05)
                                    end
                                end)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end

-- loop
RunService.RenderStepped:Connect(function()
    if enabled404 then
        detectAndSpam("404Error", RANGE_404, activeCooldowns404, animsToDetect404)
    end
    if enabledCorrupt then
        detectAndSpam("CorruptEnergy", RANGE_CORRUPT, activeCooldownsCorrupt, animsToDetectCorrupt)
    end
end)

-- ui
KillersTab:CreateToggle({
    Name = "404 parry",
    CurrentValue = false,
    Flag = "Error404Toggle",
    Callback = function(v) enabled404 = v end,
})

KillersTab:CreateInput({
    Name = "404 parry range (studs)",
    Flag = "404ErrorRangestuds",
    PlaceholderText = tostring(RANGE_404),
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num and num > 0 then
            RANGE_404 = num
            savedRange404.Value = num
        end
    end,
})

KillersTab:CreateSection("Corrupt energy")

KillersTab:CreateToggle({
    Name = "Auto corrupt energy parry",
    CurrentValue = false,
    Flag = "CorruptEnergyToggle",
    Callback = function(v) enabledCorrupt = v end,
})

KillersTab:CreateInput({
    Name = "Corrupt energy parry range (studs)",
    Flag = "CorruptEnergyRangestuds",
    PlaceholderText = tostring(RANGE_CORRUPT),
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num and num > 0 then
            RANGE_CORRUPT = num
            savedRangeCorrupt.Value = num
        end
    end,
})

-- aaaa
local camera = workspace.CurrentCamera

-- def conf
local orgspeed = 60

local sk8AnimIds = {
    "117058860640843"
}

-- state vars
local controlsk8Enabled = false
local controlsk8Active  = false
local overrideConnection = nil
local shiftlockEnabled = false
local connection = nil

local savedHumanoidState = {}

-- funcs
local function getHumanoid()
    local char = lp.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end


local function saveHumState(hum)
    if not hum then return end
    if savedHumanoidState[hum] then return end

    local s = {}

    pcall(function()
        s.WalkSpeed = hum.WalkSpeed

        local ok, _ = pcall(function()
            s.JumpPower = hum.JumpPower
        end)

        if not ok then
            pcall(function()
                s.JumpPower = hum.JumpHeight
            end)
        end
        
        local ok2, ar = pcall(function()
            return hum.AutoRotate
        end)

        if ok2 then
            s.AutoRotate = ar
        end

        s.PlatformStand = hum.PlatformStand
    end)

    savedHumanoidState[hum] = s
end


local function restoreHumState(hum)
    if not hum then return end

    local s = savedHumanoidState[hum]
    if not s then return end

    pcall(function()
        if s.WalkSpeed ~= nil then
            hum.WalkSpeed = s.WalkSpeed
        end

        if s.JumpPower ~= nil then
            local ok, _ = pcall(function()
                hum.JumpPower = s.JumpPower
            end)

            if not ok then
                pcall(function()
                    hum.JumpHeight = s.JumpPower
                end)
            end
        end

        if s.AutoRotate ~= nil then
            hum.AutoRotate = s.AutoRotate
        end

        if s.PlatformStand ~= nil then
            hum.PlatformStand = s.PlatformStand
        end
    end)

    savedHumanoidState[hum] = nil
end


local function setShiftlock(state)
    shiftlockEnabled = state

    if connection then
        connection:Disconnect()
        connection = nil
    end

    if state then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

        connection = RunService.RenderStepped:Connect(function()
            local char = lp.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if root then
                local camCF = camera.CFrame

                root.CFrame = CFrame.new(
                    root.Position,
                    Vector3.new(
                        camCF.LookVector.X + root.Position.X,
                        root.Position.Y,
                        camCF.LookVector.Z + root.Position.Z
                    )
                )
            end
        end)

    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end


local function startOverride()
    if controlsk8Active then return end

    local hum = getHumanoid()
    if not hum then return end

    controlsk8Active = true

    saveHumState(hum)

    pcall(function()
        hum.WalkSpeed = orgspeed
        hum.AutoRotate = false
    end)

    setShiftlock(true)

    overrideConnection = RunService.RenderStepped:Connect(function()
        local hum = getHumanoid()
        local rootPart = hum and hum.Parent and hum.Parent:FindFirstChild("HumanoidRootPart")

        if not hum or not rootPart then return end

        pcall(function()
            hum.WalkSpeed = orgspeed
            hum.AutoRotate = false
        end)

        local dir = rootPart.CFrame.LookVector
        local hor = Vector3.new(dir.X, 0, dir.Z)

        if hor.Magnitude > 0 then
            hum:Move(hor.Unit)
        else
            hum:Move(Vector3.new(0, 0, 0))
        end
    end)
end


local function stopOverride()
    if not controlsk8Active then return end

    controlsk8Active = false

    if overrideConnection then
        pcall(function()
            overrideConnection:Disconnect()
        end)

        overrideConnection = nil
    end

    setShiftlock(false)

    local hum = getHumanoid()

    if hum then
        restoreHumState(hum)
        hum:Move(Vector3.new(0, 0, 0))
    end
end


local function detectSkateAnimation()
    local hum = getHumanoid()
    if not hum then return false end

    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        local ok, animId = pcall(function()
            return tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+")
        end)

        if ok and animId and table.find(sk8AnimIds, animId) then
            return true
        end
    end

    return false
end


-- loop, donot change
RunService.RenderStepped:Connect(function()
    if not controlsk8Enabled then
        if controlsk8Active then
            stopOverride()
        end

        return
    end

    local hum = getHumanoid()

    if not hum then
        if controlsk8Active then
            stopOverride()
        end

        return
    end

    local isSkating = detectSkateAnimation()

    if isSkating then
        if not controlsk8Active then
            startOverride()
        end

    else
        if controlsk8Active then
            stopOverride()
        end
    end
end)

lp.CharacterAdded:Connect(function(char)
    task.spawn(function()
        char:WaitForChild("Humanoid", 2)
    end)
end)

SurvivorsTab:CreateToggle({
    Name = "Sk8 control",
    CurrentValue = false,
    Flag = "Controlsk8Toggle",

    Callback = function(v)
        controlsk8Enabled = v

        if not v then
            stopOverride()
        end
    end
})

-- hidden stats or stuff
local hiddenStats = false
local playerAddedConn

MiscTab:CreateSection("Random unnecessary stuff")

MiscTab:CreateToggle({
    Name = "Show hidden stats",
    CurrentValue = false,
    Flag = "ShowHiddenStats",

    Callback = function(v)
        hiddenStats = v

        -- do not modify, or else will cause unbearable lag
        if not hiddenStats then
            if playerAddedConn then
                playerAddedConn:Disconnect()
                playerAddedConn = nil
            end
            return
        end

        -- func
        local function reveal(p)
            local privacy = p:FindFirstChild("PlayerData")
                and p.PlayerData:FindFirstChild("Settings")
                and p.PlayerData.Settings:FindFirstChild("Privacy")

            if not privacy then return end

            for _, name in ipairs({
                "HideSurvivorWins",
                "HidePlaytime",
                "HideKillerWins"
            }) do
                local val = privacy:FindFirstChild(name)
                if val and val:IsA("BoolValue") then
                    val.Value = false
                end
            end
        end

        -- apply
        for _, p in ipairs(Players:GetPlayers()) do
            reveal(p)
        end

        -- hook
        playerAddedConn = Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Wait()
            task.wait(0.2)
            reveal(p)
        end)

        -- auto refresh
        task.spawn(function()
            while hiddenStats do
                task.wait(1)
                for _, p in ipairs(Players:GetPlayers()) do
                    reveal(p)
                end
            end
        end)
    end
})

-- show chat
getgenv().TextChatService = game:GetService("TextChatService")
getgenv().chatEnabled = false
getgenv().connection = nil
MiscTab:CreateToggle({
    Name = "Show chat visibility",
    CurrentValue = false,
    Flag = "ChatWindowToggle",
    Callback = function(v)
        getgenv().chatEnabled = v
        if getgenv().chatEnabled then
            getgenv().connection = RunService.Heartbeat:Connect(function()
                local chatWindow = TextChatService:FindFirstChild("ChatWindowConfiguration")
				chatWindow.Enabled = true
            end)
        else
            if getgenv().connection then
                getgenv().connection:Disconnect()
                getgenv().connection = nil
            end
            local chatWindow = TextChatService:FindFirstChild("ChatWindowConfiguration")
			chatWindow.Enabled = false
        end
    end
})

-- guest 1337
SurvivorsTab:CreateSection("guest 1337")

local testRemote = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent")
local blockAction = "UseActorAbility"
local blockData = { buffer.fromstring("\"Block\"") }
local punchAction = "UseActorAbility"
local punchData = { buffer.fromstring("\"Punch\"") }

local autoBlockEnabled = false
local autoPunchEnabled = false
local detectionRange = 16
local soundHooks = {}
local soundTriggeredUntil = {}

-- ab trigger sounds
local autoBlockTriggerSounds = {
  	["12222216"] = true,
    ["71805956520207"] = true,
    ["71834552297085"] = true,
    ["75330693422988"] = true,
    ["76959687420003"] = true,
    ["79391273191671"] = true,
    ["79980897195554"] = true,
    ["80516583309685"] = true,
    ["81702359653578"] = true,
    ["82221759983649"] = true,
    ["84116622032112"] = true,
    ["84307400688050"] = true,
    ["85853080745515"] = true,
    ["86174610237192"] = true,
    ["86494585504534"] = true,
    ["86833981571073"] = true,
    ["89004992452376"] = true,
    ["95079963655241"] = true,
    ["101199185291628"] = true,
    ["101553872555606"] = true,
    ["101698569375359"] = true,
    ["102228729296384"] = true,
    ["105200830849301"] = true,
    ["105840448036441"] = true,
    ["106300477136129"] = true,
    ["107444859834748"] = true,
    ["108610718831698"] = true,
    ["108907358619313"] = true,
    ["109348678063422"] = true,
    ["109431876587852"] = true,
    ["110372418055226"] = true,
    ["112395455254818"] = true,
    ["112809109188560"] = true,
    ["113037804008732"] = true,
    ["114742322778642"] = true,
    ["115026634746636"] = true,
    ["116581754553533"] = true,
    ["117173212095661"] = true,
    ["117231507259853"] = true,
    ["119089145505438"] = true,
    ["119583605486352"] = true,
    ["119942598489800"] = true,
    ["121954639447247"] = true,
    ["125213046326879"] = true,
    ["127793641088496"] = true,
    ["131406927389838"] = true,
    ["136323728355613"] = true,
    ["140242176732868"] = true,
    ["104910828105172"] = true,
    ["110126546193799"] = true
}

local function extractNumericSoundId(sound)
	if not sound or not sound.SoundId then return nil end
	return tostring(sound.SoundId):match("%d+")
end

local function getSoundWorldPosition(sound)
	if sound.Parent and sound.Parent:IsA("BasePart") then
		return sound.Parent.Position
	elseif sound.Parent and sound.Parent:IsA("Attachment") and sound.Parent.Parent:IsA("BasePart") then
		return sound.Parent.Parent.Position
	end
	local found = sound.Parent and sound.Parent:FindFirstChildWhichIsA("BasePart", true)
	if found then return found.Position end
	return nil
end

local function attemptAutoBlockForSound(sound)
	if not autoBlockEnabled then return end
	if not sound or not sound:IsA("Sound") or not sound.IsPlaying then return end

	local id = extractNumericSoundId(sound)
	if not id or not autoBlockTriggerSounds[id] then return end

	local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end

	if soundTriggeredUntil[sound] and tick() < soundTriggeredUntil[sound] then return end

	local pos = getSoundWorldPosition(sound)
	local shouldTrigger = (not pos) or ((myRoot.Position - pos).Magnitude <= detectionRange)

	if shouldTrigger then
		pcall(function()
			testRemote:FireServer(blockAction, blockData)
		end)
		soundTriggeredUntil[sound] = tick() + 1.2
	end
end

local function attemptAutoPunchForSound(sound)
	if not autoPunchEnabled then return end
	if not sound or not sound:IsA("Sound") or not sound.IsPlaying then return end

	local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end

	local pos = getSoundWorldPosition(sound)
	local shouldTrigger = (not pos) or ((myRoot.Position - pos).Magnitude <= detectionRange)

	if shouldTrigger then
		pcall(function()
			testRemote:FireServer(punchAction, punchData)
		end)
		soundTriggeredUntil[sound] = tick() + 1.2
	end
end

local function hookSound(sound)
	if soundHooks[sound] then return end

	local playedConn = sound.Played:Connect(function()
		attemptAutoBlockForSound(sound)
		attemptAutoPunchForSound(sound)
	end)

	local propConn = sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
		if sound.IsPlaying then
			attemptAutoBlockForSound(sound)
			attemptAutoPunchForSound(sound)
		end
	end)

	local destroyConn = sound.Destroying:Connect(function()
		playedConn:Disconnect()
		propConn:Disconnect()
		destroyConn:Disconnect()
		soundHooks[sound] = nil
		soundTriggeredUntil[sound] = nil
	end)

	soundHooks[sound] = true

	if sound.IsPlaying then
		attemptAutoBlockForSound(sound)
		attemptAutoPunchForSound(sound)
	end
end

-- hook
for _, s in ipairs(game:GetDescendants()) do
	if s:IsA("Sound") then hookSound(s) end
end
game.DescendantAdded:Connect(function(d)
	if d:IsA("Sound") then hookSound(d) end
end)

SurvivorsTab:CreateToggle({
	Name = "Guest 13337 auto block (sound trigger)",
	CurrentValue = false,
	Flag = "AutoBlockEnabled",
	Callback = function(v)
		autoBlockEnabled = v
	end,
})

SurvivorsTab:CreateInput({
	Name = "Auto block trigger range",
	PlaceholderText = tostring(detectionRange),
	RemoveTextAfterFocusLost = false,
	Callback = function(Text)
		 detectionRange = tonumber(Text) or detectionRange
	end
})

SurvivorsTab:CreateSection("Guest 1337 punch")

SurvivorsTab:CreateToggle({
	Name = "Guest 1337 auto parry",
	CurrentValue = false,
	Flag = "AutoPunchEnabled",
	Callback = function(v)
		autoPunchEnabled = v
	end,
})

MiscTab:CreateSection("Hitbox tracking")

local lolz = {}
if getgenv().emergency_stop == nil then
    getgenv().emergency_stop = false
end

-- convert func.
local function StudsIntoPower(studs)
    return (studs * 6)
end

-- func
function lolz:ExtendHitbox(studs, time)
    local distance = StudsIntoPower(studs)
    local start = tick()

    if getgenv().emergency_stop == true then
        getgenv().emergency_stop = false
    end

    repeat
        game:GetService("RunService").Heartbeat:Wait()

        local player = game:GetService("Players").LocalPlayer
        local char = player.Character
        if not (char and char:FindFirstChild("HumanoidRootPart")) then continue end

        local hrp = char.HumanoidRootPart
        local velocity = hrp.Velocity

        -- apply
        hrp.Velocity = velocity * distance + (hrp.CFrame.LookVector * distance)

        game:GetService("RunService").RenderStepped:Wait()

        -- res vel
        if char and char:FindFirstChild("HumanoidRootPart") then
            hrp.Velocity = velocity
        end
    until tick() - start > tonumber(time) or getgenv().emergency_stop == true

    if getgenv().emergency_stop == true then
        getgenv().emergency_stop = false
    end
end

function lolz:StopExtendingHitbox()
    getgenv().emergency_stop = true
end

local hitboxEnabled = false
local studsValue = 2

MiscTab:CreateToggle({
    Name = "Enable hitbox tracking",
    CurrentValue = false,
    Flag = "hitboxToggle",
    Callback = function(v)
        hitboxEnabled = v
        if hitboxEnabled then
            task.spawn(function()
                lolz:ExtendHitbox(studsValue, 9e9)
            end)
        else
            lolz:StopExtendingHitbox()
        end
    end
})

MiscTab:CreateSlider({
    Name = "Hitbox tracking target range",
    Range = {1, 50},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 5,
    Flag = "studsSlider",
    Callback = function(v)
        studsValue = v
    end
})

-- this is stupid, right?
local cloneAction = "UseActorAbility"
local cloneData = { buffer.fromstring("\"Clone\"") }

-- sound trigs
local triggerSounds = table.clone(autoBlockTriggerSounds)

-- vars
local autoCloneEnabled = false
local detectionRange = 16
local soundHooks = {}
local soundTriggeredUntil = {}

-- ?
local function extractNumericSoundId(sound)
      if not sound or not sound.SoundId then return nil end
      return tostring(sound.SoundId):match("%d+")
end

local function getSoundWorldPosition(sound)
      if sound.Parent and sound.Parent:IsA("BasePart") then
            return sound.Parent.Position
      elseif sound.Parent and sound.Parent:IsA("Attachment") and
sound.Parent.Parent:IsA("BasePart") then
            return sound.Parent.Parent.Position
      end
      local found = sound.Parent and
sound.Parent:FindFirstChildWhichIsA("BasePart", true)
      if found then return found.Position end
      return nil
end

-- core log
local function triggerClone()
      pcall(function()
            testRemote:FireServer(cloneAction, cloneData)
      end)
end

local function attemptAutoCloneForSound(sound)
      if not autoCloneEnabled then return end
      if not sound or not sound:IsA("Sound") or not sound.IsPlaying then return end

      local id = extractNumericSoundId(sound)
      if not id or not triggerSounds[id] then return end

      local myRoot = lp.Character and
lp.Character:FindFirstChild("HumanoidRootPart")
      if not myRoot then return end

      if soundTriggeredUntil[sound] and tick() < soundTriggeredUntil[sound] then
return end

      local pos = getSoundWorldPosition(sound)
      local shouldTrigger = (not pos) or ((myRoot.Position - pos).Magnitude <=
detectionRange)

      if shouldTrigger then
            triggerClone()
            soundTriggeredUntil[sound] = tick() + 1.0
      end
end

-- hooker
local function hookSound(sound)
      if soundHooks[sound] then return end

      local playedConn, propConn, destroyConn
      playedConn = sound.Played:Connect(function()
            attemptAutoCloneForSound(sound)
      end)

      propConn = sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
            if sound.IsPlaying then
                  attemptAutoCloneForSound(sound)
            end
      end)

      destroyConn = sound.Destroying:Connect(function()
            if playedConn and playedConn.Disconnect then pcall(function()
playedConn:Disconnect() end) end
            if propConn and propConn.Disconnect then pcall(function()
propConn:Disconnect() end) end
            if destroyConn and destroyConn.Disconnect then pcall(function()
destroyConn:Disconnect() end) end
            soundHooks[sound] = nil
            soundTriggeredUntil[sound] = nil
      end)

      soundHooks[sound] = true

      if sound.IsPlaying then
            attemptAutoCloneForSound(sound)
      end
end

-- hooker (again)
for _, s in ipairs(game:GetDescendants()) do
      if s:IsA("Sound") then hookSound(s) end
end
game.DescendantAdded:Connect(function(d)
      if d:IsA("Sound") then hookSound(d) end
end)

-- ui
SurvivorsTab:CreateSection("007n7")

SurvivorsTab:CreateToggle({
      Name = "007n7 auto clone parry",
      CurrentValue = false,
      Flag = "AutoCloneEnabled",
      Callback = function(v)
            autoCloneEnabled = v
      end
})


SurvivorsTab:CreateInput({
    Name = "Auto clone parry trigger range",
    Flag = "DetRan",
    PlaceholderText = tostring(detectionRange),
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local num = tonumber(text)
            detectionRange = num
    end,
})

VulTab:CreateSection("Effect vulnerabilities")

local disableEffects = false
local effectModules = {
      "Modules.StatusEffects.SurvivorExclusive.Subspaced",
      "Modules.StatusEffects.KillerExclusive.Glitched",
      "Modules.StatusEffects.Blindness",
      "Modules.StatusEffects.Stunned",
      "Modules.StatusEffects.Helpless",
      "Modules.StatusEffects.Slowness"
}

local function getDescendantFromPath(parent, path)
      local current = parent
      for segment in string.gmatch(path, "[^%.]+") do
            current = current:FindFirstChild(segment)
            if not current then
                  return nil
            end
      end
      return current
end

local effectLoop

VulTab:CreateToggle({
      Name = "Anti effects (only some, not all)",
      CurrentValue = false,
      Flag = "DisableStatusEffects",
      Callback = function(state)
            disableEffects = state
            if disableEffects then
                  effectLoop = task.spawn(function()
                        while disableEffects do
                              for _, path in ipairs(effectModules) do
                                    local module =
getDescendantFromPath(game:GetService("ReplicatedStorage"), path)
                                    if module then
                                          pcall(function()
                                                module:Destroy()
                                          end)
                                    end
                              end
                              task.wait(0.5)
                        end
                  end)
            else
                  if effectLoop then
                        task.cancel(effectLoop)
                        effectLoop = nil
                  end
            end
      end
})