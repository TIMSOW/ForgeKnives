--[[
	KnifeData (ModuleScript)
	Emplacement : ServerStorage > ForgeKnives > KnifeData

	Rôle : source unique de vérité pour les 6 tiers de couteaux.
	       - Name         : nom affiché
	       - Color        : couleur du couteau / de l'interface
	       - FusionChance : chance de base de réussir une fusion DE ce tier (0 à 1)
	       - DropWeight   : poids de tirage dans les caisses (plus grand = plus fréquent)

	IMPORTANT : l'ordre du tableau EST la hiérarchie.
	            Tiers[1] = le plus commun, Tiers[6] = le plus rare.
	            Partout dans le jeu, un couteau est identifié par son NUMÉRO de tier (1 à 6).
--]]

local KnifeData = {}

-- Somme des poids = 1000, ce qui rend les pourcentages faciles à lire :
--   600 -> 60 %   |   250 -> 25 %   |   100 -> 10 %
--    40 -> 4 %    |     9 -> 0,9 %  |     1 -> 0,1 %
KnifeData.Tiers = {
	{
		Name = "Commun",
		Color = Color3.fromRGB(160, 160, 160), -- gris
		FusionChance = 1.00,                   -- 100 % de réussite
		DropWeight = 600,
	},
	{
		Name = "Inhabituel",
		Color = Color3.fromRGB(70, 200, 70),   -- vert
		FusionChance = 0.90,                   -- 90 %
		DropWeight = 250,
	},
	{
		Name = "Rare",
		Color = Color3.fromRGB(60, 130, 240),  -- bleu
		FusionChance = 0.75,                   -- 75 %
		DropWeight = 100,
	},
	{
		Name = "Épique",
		Color = Color3.fromRGB(160, 70, 220),  -- violet
		FusionChance = 0.60,                   -- 60 %
		DropWeight = 40,
	},
	{
		Name = "Légendaire",
		Color = Color3.fromRGB(240, 190, 40),  -- or
		FusionChance = 0.45,                   -- 45 %
		DropWeight = 9,
	},
	{
		Name = "Mythique",
		Color = Color3.fromRGB(220, 50, 50),   -- rouge
		FusionChance = 0.30,                   -- 30 % (mais aucun tier au-dessus)
		DropWeight = 1,
	},
}

-- Nombre total de tiers (pratique pour les boucles et les cas limites).
KnifeData.TierCount = #KnifeData.Tiers

-- Générateur aléatoire dédié : plus propre que math.random global.
local rng = Random.new()

-- Somme des poids, calculée une seule fois au chargement du module.
local poidsTotal = 0
for _, tier in ipairs(KnifeData.Tiers) do
	poidsTotal += tier.DropWeight
end

--[[
	getTier(tierId)
	Renvoie la table de données d'un tier, ou nil si le numéro est invalide.
	Exemple : KnifeData.getTier(3).Name --> "Rare"
--]]
function KnifeData.getTier(tierId)
	return KnifeData.Tiers[tierId]
end

--[[
	getTierName(tierId)
	Renvoie juste le nom du tier (ou "?" si invalide). Pratique pour les messages.
--]]
function KnifeData.getTierName(tierId)
	local tier = KnifeData.Tiers[tierId]
	return tier and tier.Name or "?"
end

--[[
	getNextTierId(tierId)
	Renvoie le numéro du tier juste au-dessus, ou nil si on est déjà au maximum.
	Servira à l'étape 6 pour le cas "Déjà au maximum !".
--]]
function KnifeData.getNextTierId(tierId)
	if tierId >= KnifeData.TierCount then
		return nil -- Mythique : rien au-dessus
	end
	return tierId + 1
end

--[[
	getRandomTier()
	Tire un tier au hasard, pondéré par les DropWeight.
	Renvoie le NUMÉRO du tier (1 à 6).

	Principe de la "roue pondérée" :
	on tire un nombre entre 0 et poidsTotal, puis on avance tier par tier
	en retirant leur poids jusqu'à tomber en dessous de zéro.
--]]
function KnifeData.getRandomTier()
	local tirage = rng:NextNumber(0, poidsTotal)

	for tierId, tier in ipairs(KnifeData.Tiers) do
		tirage -= tier.DropWeight
		if tirage <= 0 then
			return tierId
		end
	end

	-- Sécurité : ne devrait jamais arriver (erreurs d'arrondi flottant).
	return 1
end

--[[
	getDropPercent(tierId)
	Renvoie la probabilité de drop du tier en POURCENTAGE (ex : 25 pour 25 %).
	Utile pour l'affichage et pour l'équilibrage de l'étape 8.
--]]
function KnifeData.getDropPercent(tierId)
	local tier = KnifeData.Tiers[tierId]
	if not tier then
		return 0
	end
	return (tier.DropWeight / poidsTotal) * 100
end

return KnifeData
