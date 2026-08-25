--[[
	InventoryBoardBuilder — À COLLER DANS LA BARRE DE COMMANDE (Command Bar).
	Crée le panneau d'affichage de l'inventaire :

	Workspace > ForgeMap > InventoryBoard (Part)
	                        └── InventoryGui (SurfaceGui)
	                             └── Root (Frame)
	                                  ├── Title (TextLabel)
	                                  └── List  (Frame + UIListLayout)  <- rempli par le client

	Le panneau est volontairement VIDE au départ : c'est le LocalScript
	InventoryClient qui crée les lignes, pour que chaque joueur voie SON inventaire.
--]]

local forgeMap = workspace:WaitForChild("ForgeMap")

local ancien = forgeMap:FindFirstChild("InventoryBoard")
if ancien then
	ancien:Destroy()
end

-- Le support physique du panneau.
local board = Instance.new("Part")
board.Name = "InventoryBoard"
board.Size = Vector3.new(14, 9, 0.5)
board.Position = Vector3.new(0, 5.5, 18) -- derrière les caisses, face au spawn
board.Anchored = true
board.Material = Enum.Material.SmoothPlastic
board.Color = Color3.fromRGB(30, 30, 35)
board.Parent = forgeMap

-- La SurfaceGui s'affiche sur la face "Front" de la Part (côté -Z).
local gui = Instance.new("SurfaceGui")
gui.Name = "InventoryGui"
gui.Face = Enum.NormalId.Front
gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
gui.PixelsPerStud = 50
gui.LightInfluence = 0 -- texte toujours bien lisible, quelle que soit la lumière
gui.Parent = board

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
root.BorderSizePixel = 0
root.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0.16, 0)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
title.BorderSizePixel = 0
title.Font = Enum.Font.GothamBold
title.Text = "INVENTAIRE"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Parent = root

local list = Instance.new("Frame")
list.Name = "List"
list.Position = UDim2.new(0, 0, 0.16, 0)
list.Size = UDim2.new(1, 0, 0.84, 0)
list.BackgroundTransparency = 1
list.Parent = root

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 20)
padding.PaddingRight = UDim.new(0, 20)
padding.PaddingTop = UDim.new(0, 10)
padding.Parent = list

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 4)
layout.Parent = list

print("[Builder] InventoryBoard créé dans ForgeMap.")
