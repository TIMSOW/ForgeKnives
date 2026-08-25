--[[
	Step3Test (Script — type "Server")
	Emplacement : ServerScriptService > Step3Test

	Rôle : script JETABLE de l'étape 3.
	       Il branche les ProximityPrompts et affiche un message dans l'Output
	       pour prouver que l'enclume et les 3 caisses répondent bien.

	Ces branchements seront remplacés par les vrais scripts aux étapes 5 et 6.
--]]

local forgeMap = workspace:WaitForChild("ForgeMap")

---------------------------------------------------------------------
-- L'ENCLUME
---------------------------------------------------------------------
local anvil = forgeMap:WaitForChild("Anvil")
local forgePrompt = anvil:WaitForChild("ForgePrompt")

forgePrompt.Triggered:Connect(function(player)
	print("[TEST] " .. player.Name .. " a activé l'ENCLUME (Forger)")
end)

---------------------------------------------------------------------
-- LES CAISSES
---------------------------------------------------------------------
local cratesFolder = forgeMap:WaitForChild("Crates")

for _, crate in ipairs(cratesFolder:GetChildren()) do
	local cratePrompt = crate:FindFirstChild("CratePrompt")
	if cratePrompt then
		cratePrompt.Triggered:Connect(function(player)
			print("[TEST] " .. player.Name .. " a ouvert la caisse : " .. crate.Name)
		end)
	end
end

print("[TEST] Étape 3 prête : approche-toi et appuie sur E.")
