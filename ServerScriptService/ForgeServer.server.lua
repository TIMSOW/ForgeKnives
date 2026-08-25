--[[
	ForgeServer (Script — type "Server")
	Emplacement : ServerScriptService > ForgeServer

	Rôle : fait le lien entre l'enclume, le client et ForgeLogic.
	       - le joueur active l'enclume  -> on demande au client d'ouvrir l'interface
	       - le client clique "Fusionner" -> on attend 1,5 s (suspens) puis on fusionne

	Le serveur reste le seul juge : il revérifie la distance,
	le nombre de couteaux et le tier avant toute fusion.
--]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeLogic = require(ServerStorage.ForgeKnives.ForgeLogic)
local InventoryService = require(ServerStorage.ForgeKnives.InventoryService)

local forgeEvent = ReplicatedStorage:WaitForChild("ForgeEvent")

local forgeMap = workspace:WaitForChild("ForgeMap")
local anvil = forgeMap:WaitForChild("Anvil")
local forgePrompt = anvil:WaitForChild("ForgePrompt")

---------------------------------------------------------------------
-- RÉGLAGES
---------------------------------------------------------------------

local SUSPENS = 1.5           -- secondes d'attente avant le tirage
local DISTANCE_MAX = 25       -- studs : au-delà, la fusion est refusée

-- Empêche un joueur de lancer deux fusions en même temps.
local fusionEnCours = {}

---------------------------------------------------------------------
-- OUVERTURE DE L'INTERFACE
---------------------------------------------------------------------

forgePrompt.Triggered:Connect(function(player)
	-- On envoie au client l'inventaire à jour + sa chauffe.
	forgeEvent:FireClient(player, "OpenForge", InventoryService.buildSnapshot(player))
end)

---------------------------------------------------------------------
-- LE CLIENT DEMANDE UNE FUSION
---------------------------------------------------------------------

-- Vérifie que le joueur est bien devant l'enclume.
local function estPresDeLEnclume(player)
	local character = player.Character
	local racine = character and character:FindFirstChild("HumanoidRootPart")
	if not racine then
		return false
	end
	return (racine.Position - anvil.Position).Magnitude <= DISTANCE_MAX
end

forgeEvent.OnServerEvent:Connect(function(player, action, tierId)
	-- On ne traite qu'une seule action venant du client.
	if action ~= "RequestFusion" then
		return
	end

	-- Anti double-clic / anti-spam.
	if fusionEnCours[player] then
		return
	end

	-- Le client doit envoyer un numéro de tier valide.
	if type(tierId) ~= "number" then
		return
	end

	-- Le joueur doit être physiquement devant l'enclume.
	if not estPresDeLEnclume(player) then
		forgeEvent:FireClient(player, "ForgeResult", {
			statut = "invalid",
			texte = "Tu es trop loin de l'enclume.",
			couleur = Color3.fromRGB(255, 200, 100),
		})
		return
	end

	fusionEnCours[player] = true

	-- SUSPENS : on fait patienter avant le verdict.
	task.wait(SUSPENS)

	-- Le joueur a pu quitter le jeu pendant l'attente.
	if not player.Parent then
		fusionEnCours[player] = nil
		return
	end

	-- Le verdict, calculé par ForgeLogic.
	local resultat = ForgeLogic.attemptFusion(player, tierId)

	-- On renvoie le résultat au client : il débloque son bouton
	-- et affiche le message dans le panneau.
	forgeEvent:FireClient(player, "ForgeResult", resultat)
	-- Et le même message en bandeau plein écran.
	forgeEvent:FireClient(player, "Notification", resultat.texte, resultat.couleur)

	print("[Forge] " .. player.Name .. " -> " .. resultat.statut .. " : " .. resultat.texte)

	fusionEnCours[player] = nil
end)

-- Nettoyage si un joueur part pendant une fusion.
game:GetService("Players").PlayerRemoving:Connect(function(player)
	fusionEnCours[player] = nil
end)

print("[Forge] Système de fusion prêt.")
