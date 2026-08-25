--[[
	InventoryClient (LocalScript)
	Emplacement : StarterPlayer > StarterPlayerScripts > InventoryClient

	Rôle : remplit le panneau SurfaceGui avec l'inventaire du joueur local.
	       - au démarrage : demande l'inventaire au serveur (RemoteFunction)
	       - ensuite      : écoute le RemoteEvent "InventoryUpdated"

	Comme le panneau est dessiné par CHAQUE client, chaque joueur
	voit son propre inventaire sur la même Part.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getInventory = ReplicatedStorage:WaitForChild("GetInventory")
local inventoryUpdated = ReplicatedStorage:WaitForChild("InventoryUpdated")

-- On attend que le panneau existe dans le monde.
local forgeMap = workspace:WaitForChild("ForgeMap")
local board = forgeMap:WaitForChild("InventoryBoard")
local gui = board:WaitForChild("InventoryGui")
local root = gui:WaitForChild("Root")
local list = root:WaitForChild("List")

---------------------------------------------------------------------
-- CRÉATION D'UNE LIGNE DU TABLEAU
---------------------------------------------------------------------

-- Fabrique une ligne "● Rare .......... x3" pour un tier donné.
local function creerLigne(tierInfo)
	local ligne = Instance.new("TextLabel")
	ligne.Name = "Tier" .. tierInfo.id
	ligne.LayoutOrder = tierInfo.id
	ligne.Size = UDim2.new(1, 0, 0, 48)
	ligne.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	ligne.BackgroundTransparency = 0.3
	ligne.BorderSizePixel = 0
	ligne.Font = Enum.Font.GothamMedium
	ligne.TextSize = 30
	ligne.TextXAlignment = Enum.TextXAlignment.Left
	-- La couleur du texte EST la couleur du tier : lecture immédiate.
	ligne.TextColor3 = tierInfo.color
	ligne.Text = string.format("  %s", tierInfo.name)

	-- La quantité, alignée à droite dans la même ligne.
	local quantite = Instance.new("TextLabel")
	quantite.Name = "Count"
	quantite.Size = UDim2.fromScale(1, 1)
	quantite.BackgroundTransparency = 1
	quantite.Font = Enum.Font.GothamBold
	quantite.TextSize = 30
	quantite.TextXAlignment = Enum.TextXAlignment.Right
	quantite.TextColor3 = tierInfo.color
	quantite.Text = "x" .. tierInfo.count .. "  "
	quantite.Parent = ligne

	-- Un tier qu'on ne possède pas est grisé.
	if tierInfo.count == 0 then
		ligne.TextTransparency = 0.6
		quantite.TextTransparency = 0.6
	end

	return ligne
end

---------------------------------------------------------------------
-- MISE À JOUR COMPLÈTE DU PANNEAU
---------------------------------------------------------------------

local function afficher(snapshot)
	if not snapshot then
		return
	end

	-- On efface les anciennes lignes (on garde le UIListLayout et le UIPadding).
	for _, enfant in ipairs(list:GetChildren()) do
		if enfant:IsA("TextLabel") then
			enfant:Destroy()
		end
	end

	-- On redessine les 6 lignes.
	for _, tierInfo in ipairs(snapshot.tiers) do
		creerLigne(tierInfo).Parent = list
	end

	-- Le titre affiche aussi la chauffe de forge (utile dès l'étape 6).
	local titre = root:FindFirstChild("Title")
	if titre then
		if snapshot.heat > 0 then
			titre.Text = string.format("INVENTAIRE  —  Chauffe +%d%%", math.floor(snapshot.heat * 100 + 0.5))
		else
			titre.Text = "INVENTAIRE"
		end
	end
end

---------------------------------------------------------------------
-- BRANCHEMENTS
---------------------------------------------------------------------

-- Le serveur pousse une mise à jour à chaque changement.
inventoryUpdated.OnClientEvent:Connect(afficher)

-- Premier affichage : on demande l'état actuel.
afficher(getInventory:InvokeServer())
