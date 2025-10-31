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
   "rbxassetid://12591948314",
   "rbxassetid://12591938344",
   "rbxassetid://12591940500",
   "rbxassetid://130572381552413",
   "rbxassetid://12710321303",
   "rbxassetid://12647442109",
   "rbxassetid://122656127657623",
   "rbxassetid://109640334668996",
   "rbxassetid://132625890664732",
   "rbxassetid://12710318141",
   "rbxassetid://13728291683",
   "rbxassetid://13728286238",
   "rbxassetid://15669224658",
   "rbxassetid://17406564344",
   "rbxassetid://17406571129",
   "rbxassetid://17406577733"
}

local onholdanims = {
   "rbxassetid://12591946055",
   "rbxassetid://12591937154",
   "rbxassetid://12591934696",
   "rbxassetid://12647444624",
   "rbxassetid://12710320691",
   "rbxassetid://12710317308",
   "rbxassetid://95447629170951",
   "rbxassetid://81725236115626",
   "rbxassetid://13728290003",
   "rbxassetid://13736285745",
   "rbxassetid://17406562512",
   "rbxassetid://15669225862",
   "rbxassetid://136219674299887",
   "rbxassetid://17406569146",
   "rbxassetid://17406575581"
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

