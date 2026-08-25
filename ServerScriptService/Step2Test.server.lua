--[[
	Step2Test (Script — type "Server")
	Emplacement : ServerScriptService > Step2Test

	Rôle : script JETABLE de l'étape 2.
	       1) Affiche la table des 6 tiers.
	       2) Simule 10 000 ouvertures de caisses pour vérifier que
	          getRandomTier() respecte bien les poids annoncés.

	À supprimer une fois l'étape 2 validée.
--]]

local ServerStorage = game:GetService("ServerStorage")
local KnifeData = require(ServerStorage.ForgeKnives.KnifeData)

print("===== ÉTAPE 2 : TABLE DES TIERS =====")
for tierId, tier in ipairs(KnifeData.Tiers) do
	print(string.format(
		"%d. %-11s | fusion %3d%% | drop %5.1f%% | poids %d",
		tierId,
		tier.Name,
		math.floor(tier.FusionChance * 100),
		KnifeData.getDropPercent(tierId),
		tier.DropWeight
	))
end

print("===== SIMULATION DE 10 000 CAISSES =====")

-- On prépare un compteur à zéro pour chaque tier.
local compteurs = {}
for tierId = 1, KnifeData.TierCount do
	compteurs[tierId] = 0
end

local TIRAGES = 10000
for _ = 1, TIRAGES do
	local tierId = KnifeData.getRandomTier()
	compteurs[tierId] += 1
end

for tierId = 1, KnifeData.TierCount do
	print(string.format(
		"%-11s : %5d fois (%5.2f %% obtenus | %5.2f %% attendus)",
		KnifeData.getTierName(tierId),
		compteurs[tierId],
		(compteurs[tierId] / TIRAGES) * 100,
		KnifeData.getDropPercent(tierId)
	))
end

print("===== TEST DU TIER SUPÉRIEUR =====")
print("Au-dessus de Rare (3)      :", KnifeData.getTierName(KnifeData.getNextTierId(3) or 0))
print("Au-dessus de Mythique (6)  :", KnifeData.getNextTierId(6) == nil and "AUCUN (maximum atteint)" or "ERREUR")

print("===== FIN DU TEST ÉTAPE 2 =====")
