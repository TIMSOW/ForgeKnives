--[[
	MapBuilder — À COLLER DANS LA BARRE DE COMMANDE (Command Bar), PAS DANS UN SCRIPT.
	View > Command Bar, coller la ligne unique fournie dans le guide, puis Entrée.

	Ce code construit la map de l'étape 3 :
	  Workspace > ForgeMap (Folder)
	     ├── Anvil        (Part + ProximityPrompt "Forger")
	     └── Crates       (Folder)
	          ├── Crate1  (Part + ProximityPrompt "Ouvrir")
	          ├── Crate2
	          └── Crate3

	Les objets créés sont PERMANENTS (visibles dans l'Explorateur, sauvegardés
	avec le lieu), contrairement à ce que créerait un Script au runtime.
--]]

-- On repart d'une map propre si on relance le builder.
local ancienne = workspace:FindFirstChild("ForgeMap")
if ancienne then
	ancienne:Destroy()
end

local forgeMap = Instance.new("Folder")
forgeMap.Name = "ForgeMap"
forgeMap.Parent = workspace

---------------------------------------------------------------------
-- 1) L'ENCLUME
---------------------------------------------------------------------
local anvil = Instance.new("Part")
anvil.Name = "Anvil"
anvil.Size = Vector3.new(4, 3, 2)
anvil.Position = Vector3.new(0, 1.5, -15) -- posée sur la baseplate (moitié de la hauteur)
anvil.Anchored = true
anvil.Material = Enum.Material.Metal
anvil.Color = Color3.fromRGB(60, 60, 65)
anvil.TopSurface = Enum.SurfaceType.Smooth
anvil.BottomSurface = Enum.SurfaceType.Smooth
anvil.Parent = forgeMap

local forgePrompt = Instance.new("ProximityPrompt")
forgePrompt.Name = "ForgePrompt"
forgePrompt.ActionText = "Forger"
forgePrompt.ObjectText = "Enclume"
forgePrompt.KeyboardKeyCode = Enum.KeyCode.E
forgePrompt.HoldDuration = 0
forgePrompt.MaxActivationDistance = 10
forgePrompt.RequiresLineOfSight = false
forgePrompt.Parent = anvil

---------------------------------------------------------------------
-- 2) LES 3 CAISSES
---------------------------------------------------------------------
local cratesFolder = Instance.new("Folder")
cratesFolder.Name = "Crates"
cratesFolder.Parent = forgeMap

-- Les trois positions, alignées face à l'enclume.
local positions = {
	Vector3.new(-8, 2, 12),
	Vector3.new(0, 2, 12),
	Vector3.new(8, 2, 12),
}

for index, position in ipairs(positions) do
	local crate = Instance.new("Part")
	crate.Name = "Crate" .. index
	crate.Size = Vector3.new(4, 4, 4)
	crate.Position = position
	crate.Anchored = true
	crate.Material = Enum.Material.WoodPlanks
	crate.Color = Color3.fromRGB(140, 95, 50)
	crate.Parent = cratesFolder

	-- On mémorise la position d'origine : l'étape 5 en aura besoin
	-- pour le tremblement puis la réapparition de la caisse.
	crate:SetAttribute("HomePosition", position)

	local cratePrompt = Instance.new("ProximityPrompt")
	cratePrompt.Name = "CratePrompt"
	cratePrompt.ActionText = "Ouvrir"
	cratePrompt.ObjectText = "Caisse"
	cratePrompt.KeyboardKeyCode = Enum.KeyCode.E
	cratePrompt.HoldDuration = 0
	cratePrompt.MaxActivationDistance = 10
	cratePrompt.RequiresLineOfSight = false
	cratePrompt.Parent = crate
end

print("[MapBuilder] ForgeMap créée : 1 enclume + 3 caisses.")
