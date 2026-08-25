# ÉTAPE 8 — Checklist finale

## Structure attendue

```
Workspace
 ├── Baseplate
 └── ForgeMap
      ├── Anvil            (ForgePrompt "Forger")
      ├── Crates           (Crate1/2/3 + CratePrompt "Ouvrir")
      ├── InventoryBoard   (InventoryGui)
      └── CodexBoard       (CodexGui + ClickDetector)

ServerStorage > ForgeKnives
 ├── KnifeData             (6 tiers + getRandomTier)
 ├── ForgeLogic            (attemptFusion + getChance)
 └── InventoryService      (inventaire + chauffe + snapshot)

ReplicatedStorage
 ├── ForgeEvent            (RemoteEvent)
 ├── GetInventory          (RemoteFunction)
 └── InventoryUpdated      (RemoteEvent)

ServerScriptService
 ├── InventoryServer
 ├── CrateServer
 └── ForgeServer

StarterPlayer > StarterPlayerScripts
 ├── InventoryClient
 ├── NotificationClient
 ├── ForgeClient
 └── CodexClient
```

## Scripts jetables à SUPPRIMER

- [ ] SetupCheck
- [ ] Step2Test
- [ ] Step3Test
- [ ] Step4Test
- [ ] Step6Test

## Réglages à remettre

- [ ] CrateServer : `DUREE_RESPAWN = 5`
- [ ] CrateServer : `DUREE_TREMBLEMENT = 1`
- [ ] ForgeServer : `SUSPENS = 1.5`

## Boucle de jeu à valider

1. Ouvrir une caisse -> tremblement -> couteau -> respawn 5 s
2. Panneau INVENTAIRE mis à jour
3. Codex coché en temps réel
4. Fusion réussie -> tier supérieur, chauffe remise à 0
5. Fusion ratée -> 1 seul couteau perdu, chauffe +2 %
6. Chauffe plafonnée à +40 %
7. 2 Mythiques -> "Déjà au maximum !", rien de consommé
8. Aucune ligne rouge dans l'Output
