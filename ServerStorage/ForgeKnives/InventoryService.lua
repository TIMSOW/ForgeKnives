--[[
	InventoryService (ModuleScript)
	Emplacement : ServerStorage > ForgeKnives > InventoryService

	Rôle : gère l'inventaire de chaque joueur, CÔTÉ SERVEUR UNIQUEMENT.
	       Un inventaire = une simple table { [numéroDeTier] = quantité }.
	       On stocke aussi la "chauffe de forge" du joueur (0 à 0.40).

	C'est le seul endroit du jeu qui a le droit de modifier un inventaire.
	Les étapes 5 (caisses) et 6 (fusion) passeront par ce module.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local KnifeData = require(ServerStorage.ForgeKnives.KnifeData)

-- RemoteEvent qui prévient le client "ton inventaire a changé".
local inventoryUpdated = ReplicatedStorage:WaitForChild("InventoryUpdated")

local InventoryService = {}

-- Toutes les données joueurs vivent ici, en mémoire serveur.
-- Clé = l'objet Player, valeur = { knives = {...}, heat = 0 }
local donnees = {}

-- Plafond de la chauffe de forge : +40 %.
InventoryService.HEAT_MAX = 0.40
-- Gain de chauffe à chaque échec : +2 %.
InventoryService.HEAT_STEP = 0.02

---------------------------------------------------------------------
-- CRÉATION / SUPPRESSION
---------------------------------------------------------------------

-- Prépare un inventaire vide pour un joueur qui arrive.
function InventoryService.setup(player)
	local knives = {}
	for tierId = 1, KnifeData.TierCount do
		knives[tierId] = 0
	end

	donnees[player] = {
		knives = knives,
		heat = 0,
	}
end

-- Libère la mémoire quand le joueur part.
function InventoryService.cleanup(player)
	donnees[player] = nil
end

---------------------------------------------------------------------
-- LECTURE
---------------------------------------------------------------------

-- Combien de couteaux de ce tier le joueur possède-t-il ?
function InventoryService.getCount(player, tierId)
	local data = donnees[player]
	if not data then
		return 0
	end
	return data.knives[tierId] or 0
end

-- La chauffe actuelle du joueur, en décimal (0.06 = +6 %).
function InventoryService.getHeat(player)
	local data = donnees[player]
	return data and data.heat or 0
end

---------------------------------------------------------------------
-- ÉCRITURE
---------------------------------------------------------------------

-- Ajoute des couteaux (quantite vaut 1 par défaut).
function InventoryService.addKnife(player, tierId, quantite)
	local data = donnees[player]
	if not data or not KnifeData.getTier(tierId) then
		return false
	end

	quantite = quantite or 1
	data.knives[tierId] += quantite

	InventoryService.push(player) -- on prévient tout de suite l'interface
	return true
end

-- Retire des couteaux. Renvoie false si le joueur n'en a pas assez.
function InventoryService.removeKnife(player, tierId, quantite)
	local data = donnees[player]
	if not data or not KnifeData.getTier(tierId) then
		return false
	end

	quantite = quantite or 1
	if data.knives[tierId] < quantite then
		return false -- on refuse : jamais de quantité négative
	end

	data.knives[tierId] -= quantite

	InventoryService.push(player)
	return true
end

-- Augmente la chauffe (utilisé à l'étape 6 en cas d'échec), avec plafond.
function InventoryService.addHeat(player)
	local data = donnees[player]
	if not data then
		return 0
	end

	data.heat = math.min(data.heat + InventoryService.HEAT_STEP, InventoryService.HEAT_MAX)

	InventoryService.push(player)
	return data.heat
end

-- Remet la chauffe à zéro (après une fusion réussie).
function InventoryService.resetHeat(player)
	local data = donnees[player]
	if not data then
		return
	end

	data.heat = 0
	InventoryService.push(player)
end

---------------------------------------------------------------------
-- COMMUNICATION AVEC LE CLIENT
---------------------------------------------------------------------

--[[
	buildSnapshot(player)
	Fabrique la "photo" de l'inventaire envoyée au client.

	Pourquoi ne pas envoyer la table brute ?
	Parce que KnifeData vit dans ServerStorage : le client n'y a PAS accès.
	On lui envoie donc aussi les noms et les couleurs des tiers.
--]]
function InventoryService.buildSnapshot(player)
	local snapshot = {
		heat = InventoryService.getHeat(player),
		tiers = {},
	}

	for tierId = 1, KnifeData.TierCount do
		local tier = KnifeData.getTier(tierId)
		table.insert(snapshot.tiers, {
			id = tierId,
			name = tier.Name,
			color = tier.Color,
			count = InventoryService.getCount(player, tierId),
			-- Ajouté à l'étape 6 : l'interface de forge affiche le % de réussite.
			fusionChance = tier.FusionChance,
		})
	end

	return snapshot
end

-- Envoie la photo au client concerné.
function InventoryService.push(player)
	if not donnees[player] then
		return
	end
	inventoryUpdated:FireClient(player, InventoryService.buildSnapshot(player))
end

return InventoryService
