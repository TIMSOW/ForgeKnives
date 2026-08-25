--[[
	NotificationClient (LocalScript)
	Emplacement : StarterPlayer > StarterPlayerScripts > NotificationClient

	Rôle : affiche les messages envoyés par le serveur via ForgeEvent,
	       sous forme d'un bandeau coloré en haut de l'écran qui
	       s'efface tout seul après 3 secondes.

	Ce script servira aussi aux étapes 6 et 7 (messages de fusion).
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local forgeEvent = ReplicatedStorage:WaitForChild("ForgeEvent")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- CONSTRUCTION DE L'INTERFACE (une seule fois)
---------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NotificationGui"
screenGui.ResetOnSpawn = false -- le bandeau survit à la mort du personnage
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local bandeau = Instance.new("TextLabel")
bandeau.Name = "Message"
bandeau.AnchorPoint = Vector2.new(0.5, 0)
bandeau.Position = UDim2.new(0.5, 0, 0, 40)
bandeau.Size = UDim2.new(0, 520, 0, 60)
bandeau.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
bandeau.BackgroundTransparency = 1 -- invisible au départ
bandeau.TextTransparency = 1
bandeau.Font = Enum.Font.GothamBold
bandeau.TextSize = 26
bandeau.Text = ""
bandeau.Parent = screenGui

local coins = Instance.new("UICorner")
coins.CornerRadius = UDim.new(0, 10)
coins.Parent = bandeau

---------------------------------------------------------------------
-- AFFICHAGE D'UN MESSAGE
---------------------------------------------------------------------

-- Compteur : si un nouveau message arrive, l'ancien est abandonné.
local messageActuel = 0

local function afficherMessage(texte, couleur)
	messageActuel += 1
	local monNumero = messageActuel

	bandeau.Text = texte
	bandeau.TextColor3 = couleur or Color3.fromRGB(255, 255, 255)

	-- Apparition rapide.
	TweenService:Create(bandeau, TweenInfo.new(0.2), {
		BackgroundTransparency = 0.2,
		TextTransparency = 0,
	}):Play()

	task.wait(3)

	-- Un message plus récent a pris la place : on ne fait rien.
	if monNumero ~= messageActuel then
		return
	end

	-- Disparition en fondu.
	TweenService:Create(bandeau, TweenInfo.new(0.5), {
		BackgroundTransparency = 1,
		TextTransparency = 1,
	}):Play()
end

---------------------------------------------------------------------
-- ÉCOUTE DU SERVEUR
---------------------------------------------------------------------

-- ForgeEvent transporte plusieurs types de messages : on filtre sur "action".
forgeEvent.OnClientEvent:Connect(function(action, texte, couleur)
	if action == "Notification" then
		task.spawn(afficherMessage, texte, couleur)
	end
end)
