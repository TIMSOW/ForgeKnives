--[[
	SetupCheck (Script — type "Server")
	Emplacement : ServerScriptService > SetupCheck

	Rôle : script JETABLE de l'étape 1.
	       Il vérifie que toute la structure a bien été créée.
	       Tu pourras le supprimer (ou le désactiver) une fois l'étape 1 validée.
--]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("===== VÉRIFICATION ÉTAPE 1 =====")

-- 1) Le dossier ForgeKnives existe-t-il dans ServerStorage ?
local dossier = ServerStorage:FindFirstChild("ForgeKnives")
if dossier then
	print("[OK] Dossier ServerStorage/ForgeKnives trouvé")
else
	warn("[MANQUE] Dossier ForgeKnives absent de ServerStorage")
	return
end

-- 2) Les deux ModuleScripts existent-ils et se chargent-ils ?
local moduleKnifeData = dossier:FindFirstChild("KnifeData")
if moduleKnifeData then
	local KnifeData = require(moduleKnifeData)
	print("[OK] KnifeData ->", KnifeData.hello())
else
	warn("[MANQUE] ModuleScript KnifeData")
end

local moduleForgeLogic = dossier:FindFirstChild("ForgeLogic")
if moduleForgeLogic then
	local ForgeLogic = require(moduleForgeLogic)
	print("[OK] ForgeLogic ->", ForgeLogic.hello())
else
	warn("[MANQUE] ModuleScript ForgeLogic")
end

-- 3) Le RemoteEvent existe-t-il dans ReplicatedStorage ?
local remote = ReplicatedStorage:FindFirstChild("ForgeEvent")
if remote and remote:IsA("RemoteEvent") then
	print("[OK] RemoteEvent ReplicatedStorage/ForgeEvent trouvé")
elseif remote then
	warn("[ERREUR] 'ForgeEvent' existe mais n'est pas un RemoteEvent")
else
	warn("[MANQUE] RemoteEvent ForgeEvent dans ReplicatedStorage")
end

print("===== FIN DE LA VÉRIFICATION =====")
