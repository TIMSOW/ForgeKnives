--[[
	CodexBoardBuilder — À COLLER DANS LA BARRE DE COMMANDE (Command Bar).

	Crée le panneau cliquable du Codex :

	Workspace > ForgeMap > CodexBoard (Part)
	                        ├── CodexGui  (SurfaceGui)  -> l'étiquette "CODEX"
	                        └── ClickDetector           -> ouvre l'interface
--]]

local forgeMap = workspace:WaitForChild("ForgeMap")

local ancien = forgeMap:FindFirstChild("CodexBoard")
if ancien then
	ancien:Destroy()
end

local board = Instance.new("Part")
board.Name = "CodexBoard"
board.Size = Vector3.new(6, 7, 0.5)
board.Position = Vector3.new(-16, 4.5, 18) -- à gauche du panneau d'inventaire
board.Anchored = true
board.Material = Enum.Material.WoodPlanks
board.Color = Color3.fromRGB(70, 50, 35)
board.Parent = forgeMap

-- L'étiquette visible dans le monde.
local gui = Instance.new("SurfaceGui")
gui.Name = "CodexGui"
gui.Face = Enum.NormalId.Front
gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
gui.PixelsPerStud = 50
gui.LightInfluence = 0
gui.Parent = board

local fond = Instance.new("Frame")
fond.Size = UDim2.fromScale(1, 1)
fond.BackgroundColor3 = Color3.fromRGB(35, 28, 20)
fond.BorderSizePixel = 0
fond.Parent = gui

local titre = Instance.new("TextLabel")
titre.Size = UDim2.new(1, 0, 0.4, 0)
titre.Position = UDim2.new(0, 0, 0.15, 0)
titre.BackgroundTransparency = 1
titre.Font = Enum.Font.GothamBold
titre.Text = "CODEX"
titre.TextColor3 = Color3.fromRGB(255, 215, 140)
titre.TextScaled = true
titre.Parent = fond

local aide = Instance.new("TextLabel")
aide.Size = UDim2.new(1, 0, 0.15, 0)
aide.Position = UDim2.new(0, 0, 0.58, 0)
aide.BackgroundTransparency = 1
aide.Font = Enum.Font.Gotham
aide.Text = "Clique pour ouvrir"
aide.TextColor3 = Color3.fromRGB(190, 175, 155)
aide.TextScaled = true
aide.Parent = fond

-- Le ClickDetector rend la Part cliquable à la souris.
local clic = Instance.new("ClickDetector")
clic.MaxActivationDistance = 20
clic.Parent = board

print("[Builder] CodexBoard créé dans ForgeMap.")
