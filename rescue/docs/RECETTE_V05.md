# Recette V0.5 — Marathon et reprise

Lot préparé le 19 novembre 2026. Les résultats d'exécution font foi dans les journaux associés au commit de livraison ; ce document précise le périmètre des contrôles.

## Contrôles automatisés

- Toutes les suites `game/tests/*.gd`, après import des ressources sous Godot 4.5.2 : catalogue, missions, rythme, campagne gratuite, agents, rigs, collisions, routes, arrivée physique, attribution des points, foules/LOD et scène.
- Marathon accéléré avec 1, 5 et 50 joueurs sur 2 heures de temps simulé ; 50 joueurs sur 3 heures ; variation d'audience de 50 à 5 ; restaurations périodiques toutes les 900 secondes simulées.
- Rotation des trois opérations de soutien, étapes gratuites, bonus et expiration ; absence de progression du soutien par un cadeau.
- Sauvegarde en pleine traversée, personnages arrivés dans un ordre différent, rejet atomique d'états incohérents, copie de secours après corruption, reprise sans double crédit.
- Pause réseau et pause organisateur indépendantes ; reprise de la scène avec les positions enregistrées.
- Connecteur Node : normalisation, combinaisons de cadeaux, reconnexion via serveur TikFinity factice, expiration et limites mémoire des caches, serveur HTTP/WebSocket et rejet des origines web.

## Contrôle visuel

Six captures natives Godot : régie, mission, chacun des trois soutiens et bilan final. Rendu OpenGL logiciel sous Linux, à ne pas présenter comme une mesure du GPU Windows. Les scènes de recette affichent DEMO. Les chronos et compteurs des captures sont des états de test.

## Chaîne Windows

Le workflow effectue les tests source avant l'export. Il prépare un paquet avec moteur, passerelle et runtime Node, exécute le vrai lanceur en mode headless de contrôle, génère l'installateur, réalise une installation silencieuse dans un chemin comportant des espaces puis relance la version installée. Les erreurs de script, codes de sortie non nuls et délais dépassés font échouer la livraison. Les SHA-256 sont joints aux artefacts.

L'option technique `start.ps1 -SmokeTest` sert uniquement à cette recette : elle lance le jeu sans affichage et le ferme après 90 images. Le raccourci utilisateur lance la fenêtre normale.

## Limites restant à vérifier en situation réelle

- TikFinity/TikTools et un véritable LIVE du compte créateur ; aucune session TikTok authentifiée n'a été testée ici.
- Trois heures réelles avec OBS, réseau et GPU du PC cible. Une simulation accélérée ne mesure ni la chauffe, ni les FPS, ni la stabilité du pilote pendant cette durée.
- Les événements manqués pendant une coupure ne sont pas récupérés ; la progression est mise en pause quand la déconnexion est détectée.
- Le nombre de personnages visibles est limité ; 500 participants comptabilisés ne signifie pas 500 modèles complets simultanément à l'écran.
- Les objets de soutien restent des éléments 3D stylisés procéduraux. Le kit de personnages riggés est CC0 ; les licences redistribuées figurent dans le paquet.
- L'exécutable n'est pas signé par un certificat commercial. Ni mise à jour automatique, ni télémétrie, ni service payant ne sont activés.

La version porte le numéro **0.5.0**. Elle n'est pas présentée comme la 1.0 acceptée en LIVE.
