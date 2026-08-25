--[[
	CrateServer (Script — type "Server")
	Emplacement : ServerScriptService > CrateServer

	Rôle : gère l'ouverture des caisses.
	       1) la caisse tremble pendant 1 seconde (TweenService)
	       2) le joueur reçoit 1 couteau aléatoire
	       3) la caisse disparaît, puis réapparaît 5 secondes plus tard

	Toute la logique est CÔTÉ SERVEUR : le client ne fait que déclencher
	le ProximityPrompt, il ne décide jamais du couteau obtenu.
--]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local KnifeData = require(ServerStorage.ForgeKnives.KnifeData)
local InventoryService = require(ServerStorage.ForgeKnives.InventoryService)

local forgeEvent = ReplicatedStorage:WaitForChild("ForgeEvent")

local forgeMap = workspace:WaitForChild("ForgeMap")
local cratesFolder = forgeMap:WaitForChild("Crates")

---------------------------------------------------------------------
-- RÉGLAGES (à ajuster à l'étape 8)
---------------------------------------------------------------------

local DUREE_TREMBLEMENT = 1     -- secondes de tremblement
local DUREE_RESPAWN = 5         -- secondes avant que la caisse revienne
local PAS_TREMBLEMENT = 0.06    -- durée d'une secousse

-- Une secousse = un petit tween très court.
local INFO_SECOUSSE = TweenInfo.new(PAS_TREMBLEMENT, Enum.EasingStyle.Sine)
-- Disparition / réapparition.
local INFO_FONDU = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Mémorise quelles caisses sont déjà en cours d'ouverture.
-- Sans ça, un joueur pourrait spammer E et obtenir 10 couteaux d'un coup.
local caissesOccupees = {}

---------------------------------------------------------------------
-- ANIMATIONS
---------------------------------------------------------------------

-- Fait trembler la caisse sur place pendant DUREE_TREMBLEMENT secondes.
local function faireTrembler(crate, cframeOrigine)
	local ecoule = 0

	while ecoule < DUREE_TREMBLEMENT do
		-- Un petit décalage aléatoire : rotation + léger déplacement.
		local decalage = CFrame.new(
			math.random(-3, 3) / 10,
			math.random(0, 2) / 10,
			math.random(-3, 3) / 10
		) * CFrame.Angles(
			math.rad(math.random(-6, 6)),
			math.rad(math.random(-12, 12)),
			math.rad(math.random(-6, 6))
		)

		local tween = TweenService:Create(crate, INFO_SECOUSSE, { CFrame = cframeOrigine * decalage })
		tween:Play()
		tween.Completed:Wait()

		ecoule += PAS_TREMBLEMENT
	end

	-- On remet la caisse parfaitement droite.
	local retour = TweenService:Create(crate, INFO_SECOUSSE, { CFrame = cframeOrigine })
	retour:Play()
	retour.Completed:Wait()
end

-- La caisse rétrécit et s'efface.
local function faireDisparaitre(crate, tailleOrigine)
	local tween = TweenService:Create(crate, INFO_FONDU, {
		Size = tailleOrigine * 0.1,
		Transparency = 1,
	})
	tween:Play()
	tween.Completed:Wait()
	crate.CanCollide = false
end

-- La caisse revient à sa taille normale.
local function faireReapparaitre(crate, tailleOrigine, cframeOrigine)
	crate.CFrame = cframeOrigine -- au cas où elle aurait glissé
	crate.CanCollide = true

	local tween = TweenService:Create(crate, INFO_FONDU, {
		Size = tailleOrigine,
		Transparency = 0,
	})
	tween:Play()
	tween.Completed:Wait()
end

---------------------------------------------------------------------
-- OUVERTURE D'UNE CAISSE
---------------------------------------------------------------------

local function ouvrirCaisse(crate, prompt, player)
	-- Déjà en cours ? On ignore.
	if caissesOccupees[crate] then
		return
	end
	caissesOccupees[crate] = true

	-- On coupe le prompt pendant toute l'animation.
	prompt.Enabled = false

	-- On mémorise l'état d'origine pour pouvoir tout restaurer.
	local cframeOrigine = crate.CFrame
	local tailleOrigine = crate.Size

	-- 1) Suspens : la caisse tremble.
	faireTrembler(crate, cframeOrigine)

	-- 2) Tirage du couteau (pondéré par les DropWeight de KnifeData).
	local tierId = KnifeData.getRandomTier()
	local tier = KnifeData.getTier(tierId)

	-- 3) On l'ajoute à l'inventaire.
	--    addKnife() rafraîchit tout seul le panneau du joueur.
	InventoryService.addKnife(player, tierId, 1)

	-- 4) On prévient le joueur avec un message coloré.
	forgeEvent:FireClient(player, "Notification", "Tu as obtenu : " .. tier.Name .. " !", tier.Color)

	print("[Caisse] " .. player.Name .. " a obtenu 1 " .. tier.Name .. " (" .. crate.Name .. ")")

	-- 5) La caisse disparaît...
	faireDisparaitre(crate, tailleOrigine)

	-- ... attend DUREE_RESPAWN secondes...
	task.wait(DUREE_RESPAWN)

	-- ... puis revient.
	faireReapparaitre(crate, tailleOrigine, cframeOrigine)

	prompt.Enabled = true
	caissesOccupees[crate] = nil
end

---------------------------------------------------------------------
-- BRANCHEMENT DES 3 CAISSES
---------------------------------------------------------------------

for _, crate in ipairs(cratesFolder:GetChildren()) do
	local prompt = crate:FindFirstChild("CratePrompt")

	if prompt then
		prompt.Triggered:Connect(function(player)
			ouvrirCaisse(crate, prompt, player)
		end)
	else
		warn("[Caisse] " .. crate.Name .. " n'a pas de ProximityPrompt nommé CratePrompt")
	end
end

print("[Caisse] Système de caisses prêt (" .. #cratesFolder:GetChildren() .. " caisses).")
