# Étape 1 — Structure du projet + map

## Arborescence cible dans l'Explorateur

```
Workspace
 └── Baseplate                      (Part, ancrée)

ServerStorage
 └── ForgeKnives                    (Folder)
      ├── KnifeData                 (ModuleScript)
      └── ForgeLogic                (ModuleScript)

ReplicatedStorage
 └── ForgeEvent                     (RemoteEvent)

ServerScriptService
 └── SetupCheck                     (Script)   <-- jetable, étape 1 uniquement
```

## Fichiers de ce dossier → où les coller

| Fichier du workspace | Objet Roblox | Emplacement |
|---|---|---|
| `ServerStorage/ForgeKnives/KnifeData.lua`  | ModuleScript `KnifeData`  | ServerStorage > ForgeKnives |
| `ServerStorage/ForgeKnives/ForgeLogic.lua` | ModuleScript `ForgeLogic` | ServerStorage > ForgeKnives |
| `ServerScriptService/SetupCheck.server.lua`| Script `SetupCheck`       | ServerScriptService |

## Résultat attendu dans la Sortie (F9 / View > Output)

```
===== VÉRIFICATION ÉTAPE 1 =====
[OK] Dossier ServerStorage/ForgeKnives trouvé
[OK] KnifeData -> KnifeData chargé !
[OK] ForgeLogic -> ForgeLogic chargé !
[OK] RemoteEvent ReplicatedStorage/ForgeEvent trouvé
===== FIN DE LA VÉRIFICATION =====
```
