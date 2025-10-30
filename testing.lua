local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "gb script ig",
   LoadingTitle = "gb script ig",
   LoadingSubtitle = "made by serin",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "gbscriptig",
      FileName = "autojump"
   },
   Discord = {
      Enabled = true,
      Invite = "64dxtKzx",
      RememberJoins = true
   },
   KeySystem = false
})

local autotab = Window:CreateTab("auto")

-- AUTO JUMP
local autoenabled = false
autotab:CreateToggle({
   Name = "auto jump on swing",
   CurrentValue = false,
   Flag = "autojumptoggle",
   Callback = function(v) autoenabled = v end
})

local currentmode = "on swing"
autotab:CreateDropdown({
   Name = "jump mode",
   Options = {"on swing", "on hold"},
   CurrentOption = "on swing",
   Flag = "jumpmode",
   Callback = function(v)
      currentmode = v
      updatetargetanims()
   end
})

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function tryjump()
   local char = player.Character
   if char then
      local hum = char:FindFirstChildOfClass("Humanoid")
      if hum and hum.FloorMaterial ~= Enum.Material.Air then
         hum:ChangeState(Enum.HumanoidStateType.Jumping)
      end
   end
end

local targetanims = {}

local onswinganims = {
   "rbxassetid://12591948314","rbxassetid://12591938344","rbxassetid://12591940500",
   "rbxassetid://130572381552413","rbxassetid://12710321303","rbxassetid://12647442109",
   "rbxassetid://122656127657623","rbxassetid://109640334668996","rbxassetid://132625890664732",
   "rbxassetid://12710318141","rbxassetid://13728291683","rbxassetid://13728286238",
   "rbxassetid://15669224658","rbxassetid://17406564344","rbxassetid://17406571129",
   "rbxassetid://17406577733"
}

local onholdanims = {
   "rbxassetid://12591946055","rbxassetid://12591937154","rbxassetid://12591934696",
   "rbxassetid://12647444624","rbxassetid://12710320691","rbxassetid://12710317308",
   "rbxassetid://95447629170951","rbxassetid://81725236115626","rbxassetid://13728290003",
   "rbxassetid://13736285745","rbxassetid://17406562512","rbxassetid://15669225862",
   "rbxassetid://136219674299887","rbxassetid://17406569146","rbxassetid://17406575581"
}

local function updatetargetanims()
   targetanims = currentmode == "on swing" and onswinganims or onholdanims
end
updatetargetanims()

local function watchhumanoid(hum)
   hum.AnimationPlayed:Connect(function(track)
      if autoenabled and table.find(targetanims, track.Animation.AnimationId) then
         tryjump()
      end
   end)
end

player.CharacterAdded:Connect(function(char)
   local hum = char:WaitForChild("Humanoid", 5)
   if hum then watchhumanoid(hum) end
end)

if player.Character then
   local hum = player.Character:FindFirstChildOfClass("Humanoid")
   if hum then watchhumanoid(hum) end
end


-- KILL AURA
local killAuraEnabled = false
autotab:CreateToggle({
   Name = "kill aura",
   CurrentValue = false,
   Flag = "killaura",
   Callback = function(v)
      killAuraEnabled = v
      if v then
         task.spawn(function()
            local LocalPlayer = game:GetService("Players").LocalPlayer
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude

            local params = OverlapParams.new()
            params.FilterDescendantsInstances = {LocalPlayer.Character}

            local isDead = false

            function checkEquipTool()
               local childrens = LocalPlayer.Character:GetChildren()
               for i, children in pairs(childrens) do
                  if children:IsA("Tool") and children:FindFirstChild("MeleeBase") then
                     return children
                  end
               end
            end

            function detectEnemy(hitbox, hrp)
               while killAuraEnabled do
                  if isDead then isDead = false return end
                  local parts = workspace:GetPartsInPart(hitbox, params)
                  for i, part in pairs(parts) do
                     if part.Parent.Name == "m_Zombie" then
                        local Origin = part.Parent:WaitForChild("Orig")
                        if Origin.Value ~= nil then
                           local zombie = Origin.Value:WaitForChild("Zombie")
                           local toolEquip = checkEquipTool()
                           if toolEquip then
                              local hit = Origin.Value
                              local zombieHead = workspace:Raycast(hrp.CFrame.Position, hit.Head.CFrame.Position - hrp.CFrame.Position)
                              local calc = (zombieHead.Position - hrp.CFrame.Position)
                              if calc:Dot(calc) > 1 then calc = calc.Unit end
                              if LocalPlayer:DistanceFromCharacter(Origin.Value:FindFirstChild("HumanoidRootPart").CFrame.Position) < 13 then
                                 if zombie.WalkSpeed > 16 then
                                    game:GetService("ReplicatedStorage").Remotes.Gib:FireServer(hit, "Head", hit.Head.CFrame.Position, zombieHead.Normal, true)
                                    game:GetService("Workspace").Players[LocalPlayer.Name][toolEquip.Name].RemoteEvent:FireServer("Swing", "Thrust")
                                    game:GetService("Workspace").Players[LocalPlayer.Name][toolEquip.Name].RemoteEvent:FireServer("HitZombie", hit, hit.Head.CFrame.Position, true, calc * 25, "Head", zombieHead.Normal)
                                 else
                                    if part.Parent:FindFirstChild("Barrel") == nil then
                                       game:GetService("ReplicatedStorage").Remotes.Gib:FireServer(hit, "Head", hit.Head.CFrame.Position, zombieHead.Normal, true)
                                       game:GetService("Workspace").Players[LocalPlayer.Name][toolEquip.Name].RemoteEvent:FireServer("Swing", "Thrust")
                                       game:GetService("Workspace").Players[LocalPlayer.Name][toolEquip.Name].RemoteEvent:FireServer("HitZombie", hit, hit.Head.CFrame.Position, true, calc * 25, "Head", zombieHead.Normal)
                                    end
                                 end
                              end
                           end
                        end
                     end
                  end
                  task.wait(0.1)
               end
            end

            LocalPlayer.CharacterRemoving:Connect(function()
               isDead = true
            end)

            workspace.Players.ChildAdded:Connect(function(child)
               if child.Name == LocalPlayer.Name then
                  local torso = child:WaitForChild("HumanoidRootPart")
                  local hitbox = Instance.new("Part", torso)
                  local weld = Instance.new("WeldConstraint", torso)
                  weld.Part0 = hitbox
                  weld.Part1 = child.HumanoidRootPart
                  hitbox.Name = "Hitbox"
                  hitbox.Anchored = false
                  hitbox.Massless = true
                  hitbox.CanCollide = false
                  hitbox.CanTouch = true
                  hitbox.Transparency  = 1
                  hitbox.Size = Vector3.new(13, 7, 12.5)
                  hitbox.Position = Vector3.new(torso.Position.X, torso.Position.Y, torso.Position.Z-7.8)
                  detectEnemy(LocalPlayer.Character.HumanoidRootPart:WaitForChild("Hitbox"), LocalPlayer.Character.HumanoidRootPart)
               end
            end)
         end)
      end
   end
})