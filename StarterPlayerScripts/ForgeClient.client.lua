--[[
	ForgeClient (LocalScript)
	Emplacement : StarterPlayer > StarterPlayerScripts > ForgeClient

	Rôle : l'interface de fusion.
	       - s'ouvre quand le serveur envoie "OpenForge"
	       - liste les 6 tiers, seuls ceux avec 2 couteaux ou plus sont cliquables
	       - affiche la chance de réussite (tier + chauffe)
	       - le bouton "Fusionner" envoie la demande au serveur

	L'interface est entièrement construite par ce script : rien à monter
	à la main dans l'Explorateur.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local forgeEvent = ReplicatedStorage:WaitForChild("ForgeEvent")
local getInventory = ReplicatedStorage:WaitForChild("GetInventory")
local inventoryUpdated = ReplicatedStorage:WaitForChild("InventoryUpdated")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- ÉTAT DU CLIENT
---------------------------------------------------------------------

local snapshot = nil        -- dernière photo de l'inventaire reçue
local tierSelectionne = nil -- numéro du tier choisi par le joueur
local enAttente = false     -- true pendant les 1,5 s de suspens

---------------------------------------------------------------------
-- CONSTRUCTION DE L'INTERFACE
---------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ForgeGui"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false -- fermée au départ
screenGui.Parent = playerGui

-- Le panneau principal.
local panneau = Instance.new("Frame")
panneau.Name = "Panel"
panneau.AnchorPoint = Vector2.new(0.5, 0.5)
panneau.Position = UDim2.fromScale(0.5, 0.5)
panneau.Size = UDim2.fromOffset(520, 540)
panneau.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
panneau.BorderSizePixel = 0
panneau.Parent = screenGui

local coinsPanneau = Instance.new("UICorner")
coinsPanneau.CornerRadius = UDim.new(0, 14)
coinsPanneau.Parent = panneau

-- Le titre.
local titre = Instance.new("TextLabel")
titre.Size = UDim2.new(1, 0, 0, 54)
titre.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
titre.BorderSizePixel = 0
titre.Font = Enum.Font.GothamBold
titre.Text = "FORGE"
titre.TextColor3 = Color3.fromRGB(255, 220, 150)
titre.TextSize = 28
titre.Parent = panneau

local coinsTitre = Instance.new("UICorner")
coinsTitre.CornerRadius = UDim.new(0, 14)
coinsTitre.Parent = titre

-- Le bouton de fermeture.
local boutonFermer = Instance.new("TextButton")
boutonFermer.AnchorPoint = Vector2.new(1, 0)
boutonFermer.Position = UDim2.new(1, -10, 0, 10)
boutonFermer.Size = UDim2.fromOffset(34, 34)
boutonFermer.BackgroundColor3 = Color3.fromRGB(90, 40, 45)
boutonFermer.BorderSizePixel = 0
boutonFermer.Font = Enum.Font.GothamBold
boutonFermer.Text = "X"
boutonFermer.TextColor3 = Color3.fromRGB(255, 255, 255)
boutonFermer.TextSize = 18
boutonFermer.Parent = panneau

local coinsFermer = Instance.new("UICorner")
coinsFermer.CornerRadius = UDim.new(0, 8)
coinsFermer.Parent = boutonFermer

-- La consigne.
local consigne = Instance.new("TextLabel")
consigne.Position = UDim2.new(0, 0, 0, 58)
consigne.Size = UDim2.new(1, 0, 0, 26)
consigne.BackgroundTransparency = 1
consigne.Font = Enum.Font.Gotham
consigne.Text = "Choisis 2 couteaux IDENTIQUES à fusionner"
consigne.TextColor3 = Color3.fromRGB(180, 180, 195)
consigne.TextSize = 15
consigne.Parent = panneau

-- La liste des tiers.
local liste = Instance.new("Frame")
liste.Name = "List"
liste.Position = UDim2.new(0, 16, 0, 92)
liste.Size = UDim2.new(1, -32, 0, 288)
liste.BackgroundTransparency = 1
liste.Parent = panneau

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = liste

-- L'encadré qui affiche le calcul de la chance.
local infoChance = Instance.new("TextLabel")
infoChance.Position = UDim2.new(0, 16, 0, 390)
infoChance.Size = UDim2.new(1, -32, 0, 60)
infoChance.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
infoChance.BorderSizePixel = 0
infoChance.Font = Enum.Font.GothamMedium
infoChance.Text = "Sélectionne un couteau ci-dessus."
infoChance.TextColor3 = Color3.fromRGB(200, 200, 215)
infoChance.TextSize = 17
infoChance.Parent = panneau

local coinsInfo = Instance.new("UICorner")
coinsInfo.CornerRadius = UDim.new(0, 8)
coinsInfo.Parent = infoChance

-- Le gros bouton d'action.
local boutonFusionner = Instance.new("TextButton")
boutonFusionner.Position = UDim2.new(0, 16, 0, 462)
boutonFusionner.Size = UDim2.new(1, -32, 0, 60)
boutonFusionner.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
boutonFusionner.BorderSizePixel = 0
boutonFusionner.Font = Enum.Font.GothamBold
boutonFusionner.Text = "FUSIONNER"
boutonFusionner.TextColor3 = Color3.fromRGB(140, 140, 150)
boutonFusionner.TextSize = 24
boutonFusionner.AutoButtonColor = false
boutonFusionner.Parent = panneau

local coinsBouton = Instance.new("UICorner")
coinsBouton.CornerRadius = UDim.new(0, 8)
coinsBouton.Parent = boutonFusionner

---------------------------------------------------------------------
-- AFFICHAGE
---------------------------------------------------------------------

-- Met à jour l'encadré de chance et l'aspect du bouton.
local function rafraichirChance()
	-- Pendant le suspens, on ne touche à rien.
	if enAttente then
		return
	end

	if not tierSelectionne or not snapshot then
		infoChance.Text = "Sélectionne un couteau ci-dessus."
		boutonFusionner.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
		boutonFusionner.TextColor3 = Color3.fromRGB(140, 140, 150)
		boutonFusionner.Text = "FUSIONNER"
		return
	end

	local info = snapshot.tiers[tierSelectionne]

	-- Cas limite : le Mythique n'a pas de tier au-dessus.
	if tierSelectionne == #snapshot.tiers then
		infoChance.Text = "Déjà au maximum !\nAucun couteau au-dessus du " .. info.name .. "."
		boutonFusionner.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
		boutonFusionner.TextColor3 = Color3.fromRGB(140, 140, 150)
		return
	end

	-- Le même calcul que ForgeLogic.getChance() côté serveur.
	local base = info.fusionChance
	local chauffe = snapshot.heat
	local total = math.min(base + chauffe, 1)

	infoChance.Text = string.format(
		"%s  ->  %s\nChance : %d %%  +  %d %% de chauffe  =  %d %%",
		info.name,
		snapshot.tiers[tierSelectionne + 1].name,
		math.floor(base * 100 + 0.5),
		math.floor(chauffe * 100 + 0.5),
		math.floor(total * 100 + 0.5)
	)

	boutonFusionner.BackgroundColor3 = Color3.fromRGB(200, 130, 40)
	boutonFusionner.TextColor3 = Color3.fromRGB(255, 255, 255)
	boutonFusionner.Text = "FUSIONNER"
end

-- Reconstruit la liste des 6 tiers.
local function rafraichirListe()
	for _, enfant in ipairs(liste:GetChildren()) do
		if enfant:IsA("TextButton") then
			enfant:Destroy()
		end
	end

	if not snapshot then
		return
	end

	for _, info in ipairs(snapshot.tiers) do
		local disponible = (info.count >= 2)

		local ligne = Instance.new("TextButton")
		ligne.Name = "Tier" .. info.id
		ligne.LayoutOrder = info.id
		ligne.Size = UDim2.new(1, 0, 0, 42)
		ligne.BorderSizePixel = 0
		ligne.Font = Enum.Font.GothamMedium
		ligne.TextSize = 18
		ligne.TextXAlignment = Enum.TextXAlignment.Left
		ligne.AutoButtonColor = false
		ligne.Text = string.format("   %s   x%d", info.name, info.count)
		ligne.TextColor3 = info.color
		ligne.Parent = liste

		local coins = Instance.new("UICorner")
		coins.CornerRadius = UDim.new(0, 6)
		coins.Parent = ligne

		-- Le tier sélectionné est mis en évidence par une bordure de sa couleur.
		if info.id == tierSelectionne then
			ligne.BackgroundColor3 = Color3.fromRGB(60, 60, 78)
			local bordure = Instance.new("UIStroke")
			bordure.Color = info.color
			bordure.Thickness = 2
			bordure.Parent = ligne
		else
			ligne.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
		end

		if disponible then
			-- Cliquable : on peut le choisir.
			ligne.MouseButton1Click:Connect(function()
				if enAttente then
					return
				end
				tierSelectionne = info.id
				rafraichirListe()
				rafraichirChance()
			end)
		else
			-- Moins de 2 couteaux : grisé et non cliquable.
			ligne.TextTransparency = 0.55
			ligne.Text = string.format("   %s   x%d   (il en faut 2)", info.name, info.count)
		end
	end
end

-- Rafraîchit tout d'un coup.
local function rafraichirTout()
	-- Si le tier choisi n'a plus assez de couteaux, on désélectionne.
	if snapshot and tierSelectionne then
		if snapshot.tiers[tierSelectionne].count < 2 then
			tierSelectionne = nil
		end
	end

	rafraichirListe()
	rafraichirChance()
end

---------------------------------------------------------------------
-- ACTIONS DU JOUEUR
---------------------------------------------------------------------

boutonFermer.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

boutonFusionner.MouseButton1Click:Connect(function()
	-- Rien de sélectionné, ou fusion déjà en cours.
	if not tierSelectionne or enAttente or not snapshot then
		return
	end

	-- Le Mythique : on prévient sans même déranger le serveur.
	if tierSelectionne == #snapshot.tiers then
		infoChance.Text = "Déjà au maximum !\nAucun couteau au-dessus du Mythique."
		return
	end

	-- On verrouille l'interface pendant le suspens.
	enAttente = true
	boutonFusionner.Text = "MARTELAGE EN COURS..."
	boutonFusionner.BackgroundColor3 = Color3.fromRGB(90, 70, 40)
	infoChance.Text = "Le marteau s'abat sur l'enclume..."

	forgeEvent:FireServer("RequestFusion", tierSelectionne)
end)

---------------------------------------------------------------------
-- MESSAGES DU SERVEUR
---------------------------------------------------------------------

forgeEvent.OnClientEvent:Connect(function(action, donnees)
	if action == "OpenForge" then
		snapshot = donnees
		tierSelectionne = nil
		enAttente = false
		screenGui.Enabled = true
		rafraichirTout()

	elseif action == "ForgeResult" then
		enAttente = false

		-- On déverrouille tout de suite le bouton.
		boutonFusionner.Text = "FUSIONNER"
		boutonFusionner.BackgroundColor3 = Color3.fromRGB(200, 130, 40)
		boutonFusionner.TextColor3 = Color3.fromRGB(255, 255, 255)

		-- Le message du serveur s'affiche dans le panneau, dans sa couleur.
		infoChance.Text = donnees.texte
		infoChance.TextColor3 = donnees.couleur or Color3.fromRGB(200, 200, 215)

		-- On laisse le message visible 2 secondes avant de réafficher le calcul.
		task.delay(2, function()
			if not enAttente then
				infoChance.TextColor3 = Color3.fromRGB(200, 200, 215)
				rafraichirChance()
			end
		end)

		rafraichirListe()
	end
end)

-- L'inventaire change (caisse ouverte, fusion...) : on garde la photo à jour.
inventoryUpdated.OnClientEvent:Connect(function(nouveauSnapshot)
	snapshot = nouveauSnapshot
	if screenGui.Enabled then
		rafraichirTout()
	end
end)

-- Photo initiale, au cas où le joueur ouvre la forge très vite.
snapshot = getInventory:InvokeServer()
