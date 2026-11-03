# Dossier de livraison technique — MISSION SAUVETAGE LIVE

## Produit
Nouvelle application Windows indépendante de LIVE BATTLES (jeu de combat conservé en archives). Mission coopérative : construire un pont et sauver le village avant la crue. Gameplay gratuit en commentaires, cadeaux optionnels, trois vagues, résultats et missions automatiques.

## Composants présents
- Godot 4.5.2 : moteur de mission, rendu vectoriel 2,5D, personnages, animation de traversée et caméra.
- Sons originaux entièrement synthétisés par le jeu (F9 coupe le son).
- Règles vérifiées : construction à 100% avant évacuation, tempêtes, limite de temps, victoire/échec, points des contributeurs, cadeaux.
- WebSocket local sur 127.0.0.1:8766, normalisation des commentaires, anti-spam, cadeaux de type streak, reconnexion au LIVE sur disponibilité.
- Démarrage unique Windows avec Node embarqué, installateur Inno Setup, ZIP portable.
- Tests CI Node, Godot mission, UI, API localhost et exécutable Windows.
- Guide utilisateur non technique : `docs/GUIDE_DEMARRAGE.md`.

## État de validation
Les tests automatisés ne peuvent pas prouver la compatibilité de chaque version de TikTok LIVE ni la fluidité sur tous les PC. Une validation finale en LIVE réel et une capture OBS restent nécessaires avant une diffusion commerciale.

## Risques
- Connecteur TikTok non officiel, susceptibles de modifications ; licence AGPL-3.0-only à vérifier et respecter avant distribution.
- Noms et disponibilité des cadeaux selon région.
- Aucune garantie de revenu ou de nombre de spectateurs.
- Application non signée ; Windows peut avertir.
- Les évacués sont des personnages fictifs du scénario, **pas des spectateurs ni des identités réelles**.

## Recommandations
Déployer d'abord en diffusion-test avec les commandes gratuites, mesurer la participation, les missions terminées et le nombre de nouveaux spectateurs ; activer les cadeaux seulement après validation technique et conformité aux règles TikTok.
