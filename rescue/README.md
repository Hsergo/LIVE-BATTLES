# MISSION SAUVETAGE LIVE — Le pont de la dernière chance

**Nouvelle expérience autonome** dans le dépôt historique `Hsergo/LIVE-BATTLES`. Le jeu de combat d'origine reste archivé dans `game/`, `bridge/`, `launcher/` et l'ancien workflow. **Cette application est totalement distincte** et produit son propre installateur Windows.

## Expérience

Mission coopérative verticale 9:16 : construire un pont pour évacuer les habitants d'un village menacé par une crue. L'eau monte, la tempête endommage le pont, des ouvriers construisent et des habitants traversent physiquement la scène. Le score correspond au nombre d'habitants sauvés. Il n'y a **aucun prix en argent**, aucun pari ni moyen de retirer les ressources virtuelles.

En mode DEMO : simulation **explicitement étiquetée**, initialement active pour découvrir le jeu, sans faux pseudonymes de spectateurs. Les boutons CONSTRUIRE, REPARER, EVACUER sont des outils de test.

En mode LIVE : les spectateurs TikTok écrivent `!join`, `!build`, `!repair`, `!rescue` (ou `!construire`, `!reparer`, `!sauver`), et votent avec `1`, `2` ou `3`. Le jeu n'avance pas avant qu'au moins un véritable participant ait rejoint. Les commentaires sont gratuits et peuvent suffire à gagner.

## Cadeaux (optionnels)

Leur valeur en **matériaux fictifs** est déterminée dans `bridge/gifts.json`. Elle ne représente ni le prix ni la valeur officielle des cadeaux. Rose (+4), Finger Heart (+12), Doughnut (+40), Galaxy (+120) selon disponibilité réelle. Les matériaux accélèrent les constructions, la grue ou la digue. Aucun spectateur n'est obligé de dépenser de l'argent pour être utile.

## Windows, 1 clic

Dans l'artefact GitHub Actions, récupérer `MISSION-SAUVETAGE-LIVE-Setup-x64.exe`, l'installer puis utiliser le raccourci. Godot et Node sont embarqués. L'opérateur peut connecter son pseudo TikTok via le bouton **CONNECTER LIVE**. La liaison est non officielle, expérimentale et exige que le compte soit actuellement en LIVE. Ne pas donner de mot de passe ni de cookie de session.

## Architecture

`rescue/game/` Godot 4.5.2 — rendu 2,5D, animations et interface.
`rescue/game/scripts/mission.gd` — règles indépendantes du rendu, testables.
`rescue/bridge/` — passerelle locale localhost:8766, commandes normalisées et connecteur TikTok.
`rescue/launcher/` — lancement coordonné et fermeture de la passerelle.
`rescue/installer/` — générateur de Setup Windows.
`.github/workflows/rescue-windows.yml` — tests, compilation Windows et distribution.

## Commandes de l'opérateur

F11 : plein écran. F10 : masquer les commandes administrateur pendant la diffusion.

## Tests et état

Le pipeline CI doit valider les tests Node, les règles Godot, la scène, le démarrage Windows et le packaging avant toute livraison. Cela ne remplace pas un test graphique avec OBS ni la validation d'un vrai LIVE TikTok.

Les décors sont dessinés par le moteur ; pas de Blender à installer, pas de ressources achetées, ni de faux avis.
