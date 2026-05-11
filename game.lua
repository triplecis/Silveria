local PlayersGroupbox = _Tabs.Lobby:AddRightGroupbox('Players')
local CommandsGroupbox = _Tabs.Lobby:AddLeftGroupbox('Commands')

--[[ inGame / Playerslist ]]--

--[[ Commands 
Teleport, Loop TP
Bang, Unbang
Fling, Loop Fling
Spectate, Unspectate
Whitelist, Unwhitelist
Blacklist, Unblacklist

List of players, Selectable or all players 
]]--

local function TeleportPlayer(target)
    local character = game.Players.LocalPlayer.Character
    local targetCharacter = target.Character
    if character and targetCharacter and character:FindFirstChild('HumanoidRootPart') and targetCharacter:FindFirstChild('HumanoidRootPart') then
        character.HumanoidRootPart.CFrame = targetCharacter.HumanoidRootPart.CFrame
    end
end
local function LoopTP(target)
    local loop = true
    spawn(function()
        while loop do
            TeleportPlayer(target)
            wait(0.1)
        end
    end)
    return function() loop = false end -- returns a function to stop the loop
end

--[[ Chat Commands ]]--
local ChatCommandsEnabled = false

PlayersGroupbox:AddLabel('Players in game: ' .. #game:GetService('Players'):GetPlayers())
local PlayersLabel = PlayersGroupbox:AddLabel('')

CommandsGroupbox:AddLabel('Commands coming soon!')
CommandsGroupbox:AddToggle('Toggle Chat Commands', nil, function(state)
    if state then
        ChatCommandsEnabled = true
        CommandsGroupbox:AddLabel('Chat commands enabled! Type !help for a list of commands.')
    else
        ChatCommandsEnabled = false
        CommandsGroupbox:AddLabel('Chat commands disabled!')
    end
end)

game:GetService('Players').PlayerAdded:Connect(function(player)
    PlayersGroupbox:AddLabel(player.Name .. ' has joined the game! Total players: ' .. #game:GetService('Players'):GetPlayers())
end)

game:GetService('Players').PlayerRemoving:Connect(function(player)
    PlayersGroupbox:AddLabel(player.Name .. ' has left the game! Total players: ' .. #game:GetService('Players'):GetPlayers())
end)
