--[[
	ForgeLogic (ModuleScript)
	Emplacement : ServerStorage > ForgeKnives > ForgeLogic

	Rôle : TOUTE la logique de fusion. C'est le cerveau du jeu.
	       Ce module ne connaît rien aux interfaces : il reçoit un joueur
	       et un tier, il applique les règles, il renvoie un résultat.

	RÈGLE ANTI-FRUSTRATION :
	  - Succès : les 2 couteaux partent, 1 couteau du tier supérieur arrive,
	             la chauffe est remise à zéro.
	  - Échec  : UN SEUL couteau est perdu, l'autre reste,
	             et la chauffe monte de +2 % (plafond +40 %).
--]]

local ServerStorage = game:GetService("ServerStorage")

local KnifeData = require(ServerStorage.ForgeKnives.KnifeData)
local InventoryService = require(ServerStorage.ForgeKnives.InventoryService)

local ForgeLogic = {}

-- Générateur aléatoire dédié à la forge.
local rng = Random.new()

---------------------------------------------------------------------
-- CALCUL DE LA CHANCE
---------------------------------------------------------------------

--[[
	getChance(player, tierId)
	Renvoie 3 valeurs, toutes en décimal (0.81 = 81 %) :
	  chanceBase   -> la chance du tier seule
	  chauffe      -> le bonus de chauffe du joueur
	  chanceTotale -> la somme, plafonnée à 100 %

	Utilisé DEUX fois : pour l'affichage dans l'interface,
	et pour le tirage réel. Ainsi le joueur voit toujours le vrai chiffre.
--]]
function ForgeLogic.getChance(player, tierId)
	local tier = KnifeData.getTier(tierId)
	if not tier then
		return 0, 0, 0
	end

	local chanceBase = tier.FusionChance
	local chauffe = InventoryService.getHeat(player)
	local chanceTotale = math.min(chanceBase + chauffe, 1)

	return chanceBase, chauffe, chanceTotale
end

---------------------------------------------------------------------
-- LA FUSION
---------------------------------------------------------------------

--[[
	attemptFusion(player, tierId)
	Tente de fusionner 2 couteaux du tier donné.

	Renvoie une table résultat :
	  { statut = "success" | "fail" | "max" | "notenough" | "invalid",
	    texte  = message à afficher,
	    couleur = Color3 du message }

	IMPORTANT : cette fonction fait CONFIANCE à personne.
	Elle revérifie tout, même si le client a déjà vérifié de son côté.
--]]
function ForgeLogic.attemptFusion(player, tierId)
	local tier = KnifeData.getTier(tierId)

	-- Cas 0 : le client a envoyé n'importe quoi.
	if not tier then
		return {
			statut = "invalid",
			texte = "Couteau inconnu.",
			couleur = Color3.fromRGB(255, 255, 255),
		}
	end

	-- Cas 1 : déjà au tier maximum (Mythique). On ne consomme RIEN.
	local tierSuperieurId = KnifeData.getNextTierId(tierId)
	if not tierSuperieurId then
		return {
			statut = "max",
			texte = "Déjà au maximum ! Aucun couteau au-dessus du " .. tier.Name .. ".",
			couleur = tier.Color,
		}
	end

	-- Cas 2 : pas assez de couteaux. On ne consomme RIEN.
	if InventoryService.getCount(player, tierId) < 2 then
		return {
			statut = "notenough",
			texte = "Il te faut 2 couteaux " .. tier.Name .. " identiques.",
			couleur = Color3.fromRGB(255, 200, 100),
		}
	end

	-- On calcule la chance AVANT de toucher à quoi que ce soit.
	local _, _, chanceTotale = ForgeLogic.getChance(player, tierId)

	-- Le premier couteau est consommé dans TOUS les cas.
	InventoryService.removeKnife(player, tierId, 1)

	-- Le tirage : un nombre entre 0 et 1.
	local tirage = rng:NextNumber()
	local reussi = (tirage <= chanceTotale)

	if reussi then
		-- SUCCÈS : le second couteau part aussi, le tier supérieur arrive.
		InventoryService.removeKnife(player, tierId, 1)
		InventoryService.addKnife(player, tierSuperieurId, 1)
		InventoryService.resetHeat(player) -- la forge redescend en température

		local tierSuperieur = KnifeData.getTier(tierSuperieurId)
		return {
			statut = "success",
			texte = "Fusion réussie ! Tu obtiens un " .. tierSuperieur.Name .. " !",
			couleur = tierSuperieur.Color,
		}
	else
		-- ÉCHEC : le second couteau est SAUVÉ, mais la forge chauffe.
		local nouvelleChauffe = InventoryService.addHeat(player)

		return {
			statut = "fail",
			texte = string.format(
				"La fusion a échoué... mais la forge chauffe (+2 %%) ! Bonus total : +%d %%",
				math.floor(nouvelleChauffe * 100 + 0.5)
			),
			couleur = Color3.fromRGB(255, 120, 90),
		}
	end
end

return ForgeLogic
