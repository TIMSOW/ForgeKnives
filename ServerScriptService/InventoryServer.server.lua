--[[
	InventoryServer (Script — type "Server")
	Emplacement : ServerScriptService > InventoryServer

	Rôle : le "chef d'orchestre" de l'inventaire côté serveur.
	       - crée un inventaire quand un joueur arrive
	       - le supprime quand il part
	       - répond au client qui demande son inventaire (RemoteFunction)

	Ce script reste en place jusqu'à la fin du projet.
--]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryService = require(ServerStorage.ForgeKnives.InventoryService)

local getInventory = ReplicatedStorage:WaitForChild("GetInventory")

---------------------------------------------------------------------
-- ARRIVÉE / DÉPART DES JOUEURS
---------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
	InventoryService.setup(player)
	print("[Inventaire] Inventaire créé pour " .. player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
	InventoryService.cleanup(player)
end)

-- Sécurité : si le script démarre après qu'un joueur soit déjà là
-- (cas fréquent quand on lance "Play" dans Studio).
for _, player in ipairs(Players:GetPlayers()) do
	InventoryService.setup(player)
end

---------------------------------------------------------------------
-- LE CLIENT DEMANDE SON INVENTAIRE
---------------------------------------------------------------------

-- OnServerInvoke : le client appelle, le serveur répond.
-- Le joueur est TOUJOURS le premier argument, ajouté par Roblox :
-- impossible pour un client de demander l'inventaire d'un autre.
getInventory.OnServerInvoke = function(player)
	return InventoryService.buildSnapshot(player)
end

print("[Inventaire] Serveur d'inventaire prêt.")
