--[[
	Step4Test (Script — type "Server")
	Emplacement : ServerScriptService > Step4Test

	Rôle : script JETABLE de l'étape 4.
	       Donne un couteau aléatoire au joueur toutes les 3 secondes
	       pour vérifier que le panneau se met bien à jour tout seul.
	       Teste aussi la chauffe et le refus de retrait impossible.

	À supprimer une fois l'étape 4 validée (l'étape 5 le remplacera
	par les vraies caisses).
--]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local KnifeData = require(ServerStorage.ForgeKnives.KnifeData)
local InventoryService = require(ServerStorage.ForgeKnives.InventoryService)

Players.PlayerAdded:Connect(function(player)
	task.wait(3) -- on laisse le client charger son interface

	-- Test 1 : on refuse de retirer un couteau qu'il n'a pas.
	local ok = InventoryService.removeKnife(player, 1, 1)
	print("[TEST] Retirer un couteau inexistant -> " .. tostring(ok) .. " (doit être false)")

	-- Test 2 : un couteau aléatoire toutes les 3 secondes.
	for _ = 1, 10 do
		local tierId = KnifeData.getRandomTier()
		InventoryService.addKnife(player, tierId, 1)
		print("[TEST] +1 " .. KnifeData.getTierName(tierId))
		task.wait(3)
	end

	-- Test 3 : la chauffe monte et se bloque à 40 %.
	print("[TEST] Montée de la chauffe...")
	for _ = 1, 25 do
		InventoryService.addHeat(player)
		task.wait(0.2)
	end
	print("[TEST] Chauffe finale : " .. math.floor(InventoryService.getHeat(player) * 100) .. "% (doit être 40)")
end)
