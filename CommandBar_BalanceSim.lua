--[[
	BalanceSim — À COLLER DANS LA BARRE DE COMMANDE (Command Bar).

	Simule 2000 parties complètes "ouvrir des caisses + tout fusionner"
	et affiche combien de caisses et de fusions il faut, en moyenne,
	pour décrocher un Mythique.

	Sert à valider un changement d'équilibrage SANS jouer 40 minutes.
	Ne modifie rien dans le jeu : lecture seule.
--]]

local KnifeData = require(game.ServerStorage.ForgeKnives.KnifeData)

local HEAT_STEP = 0.02
local HEAT_MAX = 0.40
local PARTIES = 2000

local nbTiers = #KnifeData.Tiers
local poidsTotal = 0
for _, tier in ipairs(KnifeData.Tiers) do
	poidsTotal += tier.DropWeight
end

-- Tire un tier comme le fait getRandomTier().
local function tirerTier()
	local r = math.random() * poidsTotal
	for id, tier in ipairs(KnifeData.Tiers) do
		r -= tier.DropWeight
		if r <= 0 then
			return id
		end
	end
	return 1
end

local totalCaisses, totalFusions = 0, 0

for _ = 1, PARTIES do
	local inv = {}
	for i = 1, nbTiers do
		inv[i] = 0
	end

	local chauffe, caisses, fusions = 0, 0, 0

	while inv[nbTiers] == 0 do
		-- 1) On ouvre une caisse.
		inv[tirerTier()] += 1
		caisses += 1

		-- 2) On fusionne tout ce qui peut l'être, du plus rare au plus commun.
		local encore = true
		while encore do
			encore = false
			for t = nbTiers - 1, 1, -1 do
				while inv[t] >= 2 do
					fusions += 1
					local chance = math.min(KnifeData.Tiers[t].FusionChance + chauffe, 1)
					inv[t] -= 1 -- un couteau perdu dans tous les cas
					if math.random() <= chance then
						inv[t] -= 1
						inv[t + 1] += 1
						chauffe = 0
					else
						chauffe = math.min(chauffe + HEAT_STEP, HEAT_MAX)
					end
					encore = true
				end
			end
		end
	end

	totalCaisses += caisses
	totalFusions += fusions
end

print("===== SIMULATION D'ÉQUILIBRAGE (" .. PARTIES .. " parties) =====")
print(string.format("Caisses à ouvrir pour 1 Mythique : %.1f en moyenne", totalCaisses / PARTIES))
print(string.format("Fusions à réaliser               : %.1f en moyenne", totalFusions / PARTIES))
print(string.format("Temps estimé (2 s/caisse, 3,5 s/fusion) : %.1f minutes",
	((totalCaisses / PARTIES) * 2 + (totalFusions / PARTIES) * 3.5) / 60))
