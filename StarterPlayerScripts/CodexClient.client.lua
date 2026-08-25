--[[
	CodexClient (LocalScript)
	Emplacement : StarterPlayer > StarterPlayerScripts > CodexClient

	Rôle : le Codex, c'est-à-dire la collection du joueur.
	       - on clique sur le panneau CodexBoard -> l'interface s'ouvre/se ferme
	       - chaque tier possédé (au moins 1 couteau) reçoit une coche verte
	       - la mise à jour est immédiate grâce à InventoryUpdated

	AUCUN nouveau RemoteEvent : on réutilise ceux de l'étape 4.
	Tout est calculé côté client à partir de la photo de l'inventaire.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getInventory = ReplicatedStorage:WaitForChild("GetInventory")
local inventoryUpdated = ReplicatedStorage:WaitForChild("InventoryUpdated")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Le panneau physique dans le monde.
local forgeMap = workspace:WaitForChild("ForgeMap")
local codexBoard = forgeMap:WaitForChild("CodexBoard")
local clickDetector = codexBoard:WaitForChild("ClickDetector")

local snapshot = nil

-- Variante "découverte permanente" : une fois vu, un tier reste coché
-- même si le joueur n'en possède plus aucun exemplaire.
local dejaVus = {}

---------------------------------------------------------------------
-- CONSTRUCTION DE L'INTERFACE
---------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CodexGui"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = playerGui

local panneau = Instance.new("Frame")
panneau.AnchorPoint = Vector2.new(0.5, 0.5)
panneau.Position = UDim2.fromScale(0.5, 0.5)
panneau.Size = UDim2.fromOffset(460, 470)
panneau.BackgroundColor3 = Color3.fromRGB(28, 24, 20)
panneau.BorderSizePixel = 0
panneau.Parent = screenGui

local coinsPanneau = Instance.new("UICorner")
coinsPanneau.CornerRadius = UDim.new(0, 14)
coinsPanneau.Parent = panneau

local titre = Instance.new("TextLabel")
titre.Size = UDim2.new(1, 0, 0, 54)
titre.BackgroundColor3 = Color3.fromRGB(55, 44, 30)
titre.BorderSizePixel = 0
titre.Font = Enum.Font.GothamBold
titre.Text = "CODEX"
titre.TextColor3 = Color3.fromRGB(255, 215, 140)
titre.TextSize = 28
titre.Parent = panneau

local coinsTitre = Instance.new("UICorner")
coinsTitre.CornerRadius = UDim.new(0, 14)
coinsTitre.Parent = titre

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

-- La ligne de progression "3 / 6 couteaux découverts".
local progression = Instance.new("TextLabel")
progression.Position = UDim2.new(0, 0, 0, 58)
progression.Size = UDim2.new(1, 0, 0, 28)
progression.BackgroundTransparency = 1
progression.Font = Enum.Font.GothamMedium
progression.Text = "0 / 6"
progression.TextColor3 = Color3.fromRGB(190, 190, 200)
progression.TextSize = 17
progression.Parent = panneau

local liste = Instance.new("Frame")
liste.Name = "List"
liste.Position = UDim2.new(0, 16, 0, 94)
liste.Size = UDim2.new(1, -32, 1, -110)
liste.BackgroundTransparency = 1
liste.Parent = panneau

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)
layout.Parent = liste

---------------------------------------------------------------------
-- REMPLISSAGE
---------------------------------------------------------------------

local function rafraichir()
	if not snapshot then
		return
	end

	for _, enfant in ipairs(liste:GetChildren()) do
		if enfant:IsA("Frame") then
			enfant:Destroy()
		end
	end

	local decouverts = 0

	for _, info in ipairs(snapshot.tiers) do
		-- Le critère du Codex : avoir possédé au moins 1 couteau de ce tier,
		-- ne serait-ce qu'une fois dans la partie.
		if info.count >= 1 then
			dejaVus[info.id] = true
		end
		local possede = (dejaVus[info.id] == true)
		if possede then
			decouverts += 1
		end

		local ligne = Instance.new("Frame")
		ligne.Name = "Tier" .. info.id
		ligne.LayoutOrder = info.id
		ligne.Size = UDim2.new(1, 0, 0, 48)
		ligne.BackgroundColor3 = possede and Color3.fromRGB(42, 42, 52) or Color3.fromRGB(30, 30, 36)
		ligne.BorderSizePixel = 0
		ligne.Parent = liste

		local coins = Instance.new("UICorner")
		coins.CornerRadius = UDim.new(0, 8)
		coins.Parent = ligne

		-- Une bordure de la couleur du tier, uniquement si découvert.
		if possede then
			local bordure = Instance.new("UIStroke")
			bordure.Color = info.color
			bordure.Thickness = 2
			bordure.Parent = ligne
		end

		-- La coche (ou la case vide).
		local coche = Instance.new("TextLabel")
		coche.Position = UDim2.new(0, 12, 0, 0)
		coche.Size = UDim2.new(0, 40, 1, 0)
		coche.BackgroundTransparency = 1
		coche.Font = Enum.Font.GothamBold
		coche.TextSize = 26
		coche.Text = possede and "✔" or "✖"
		coche.TextColor3 = possede and Color3.fromRGB(90, 220, 110) or Color3.fromRGB(90, 90, 100)
		coche.Parent = ligne

		-- Le nom du tier (masqué tant qu'il n'est pas découvert).
		local nom = Instance.new("TextLabel")
		nom.Position = UDim2.new(0, 60, 0, 0)
		nom.Size = UDim2.new(1, -140, 1, 0)
		nom.BackgroundTransparency = 1
		nom.Font = Enum.Font.GothamBold
		nom.TextSize = 20
		nom.TextXAlignment = Enum.TextXAlignment.Left
		nom.Text = possede and info.name or "???"
		nom.TextColor3 = possede and info.color or Color3.fromRGB(85, 85, 95)
		nom.Parent = ligne

		-- La quantité possédée, à droite.
		local quantite = Instance.new("TextLabel")
		quantite.AnchorPoint = Vector2.new(1, 0)
		quantite.Position = UDim2.new(1, -14, 0, 0)
		quantite.Size = UDim2.new(0, 70, 1, 0)
		quantite.BackgroundTransparency = 1
		quantite.Font = Enum.Font.GothamMedium
		quantite.TextSize = 18
		quantite.TextXAlignment = Enum.TextXAlignment.Right
		quantite.Text = possede and ("x" .. info.count) or "-"
		quantite.TextColor3 = possede and Color3.fromRGB(220, 220, 230) or Color3.fromRGB(85, 85, 95)
		quantite.Parent = ligne
	end

	local total = #snapshot.tiers
	progression.Text = decouverts .. " / " .. total .. " couteaux découverts"

	-- Collection complète : on félicite le joueur.
	if decouverts == total then
		progression.Text = "COLLECTION COMPLÈTE ! " .. decouverts .. " / " .. total
		progression.TextColor3 = Color3.fromRGB(255, 215, 100)
	else
		progression.TextColor3 = Color3.fromRGB(190, 190, 200)
	end
end

---------------------------------------------------------------------
-- OUVERTURE / FERMETURE
---------------------------------------------------------------------

-- MouseClick se déclenche aussi côté client, pour le joueur qui a cliqué.
clickDetector.MouseClick:Connect(function()
	screenGui.Enabled = not screenGui.Enabled
	if screenGui.Enabled then
		rafraichir()
	end
end)

boutonFermer.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

---------------------------------------------------------------------
-- SUIVI EN TEMPS RÉEL
---------------------------------------------------------------------

-- Chaque changement d'inventaire met le Codex à jour, même ouvert.
inventoryUpdated.OnClientEvent:Connect(function(nouveauSnapshot)
	snapshot = nouveauSnapshot
	if screenGui.Enabled then
		rafraichir()
	end
end)

-- État initial.
snapshot = getInventory:InvokeServer()
rafraichir()
