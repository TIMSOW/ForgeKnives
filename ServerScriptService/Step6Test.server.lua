--[[
	Step6Test (Script — type "Server")
	Emplacement : ServerScriptService > Step6Test

	Rôle : script JETABLE de l'étape 6.
	       Donne au joueur 4 couteaux de CHAQUE tier dès son arrivée,
	       pour pouvoir tester toutes les fusions sans farmer les caisses
	       (y compris le cas limite "2 Mythiques").

	À SUPPRIMER avant l'étape 8 (tests en conditions réelles).
--]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local KnifeData = require(ServerStorage.ForgeKnives.KnifeData)
local InventoryService = require(ServerStorage.ForgeKnives.InventoryService)

Players.PlayerAdded:Connect(function(player)
	task.wait(2) -- on laisse le client charger ses interfaces

	for tierId = 1, KnifeData.TierCount do
		InventoryService.addKnife(player, tierId, 4)
	end

	print("[TEST] 4 couteaux de chaque tier donnés à " .. player.Name)
end)
