# LIVE BATTLES — Cahier des charges et recette V0.1

## Objectif
Jeu Windows 10/11 x64 lancé par raccourci, combat Rouge/Bleu automatisé pour TikTok LIVE, affichage vertical 9:16. Le client final ne configure pas Godot, Blender ou Node.

## Portée actuelle
1. Arène 3D procédurale et deux combattants 3D stylisés provisoires.
2. Manche de 90 s, points de vie, soins, boucliers et récompenses.
3. Commentaires : !join red, !join blue, !attack, !defend, !heal, !status.
4. Cadeaux : points de jeu configurés dans bridge/config/gifts.json.
5. Likes : un point de bonus pour chaque groupe de 50 likes, pour joueurs inscrits.
6. Simulateur local indépendant de TikTok, port 8765 lié à localhost.
7. Connecteur TikTok communautaire optionnel non garanti.
8. Pipeline Windows (tests Node, export Godot, installateur Inno Setup, artefacts).
9. Démo navigateur séparée (simulation illustrative).

## Critères d'acceptation
- [ ] Le CI GitHub vérifie la passerelle et compile le jeu.
- [ ] L'installateur produit un exe Windows utilisable sans Godot / Node global.
- [ ] Double-clic lance le jeu et son pont d'événements.
- [ ] OBS capture le jeu sans déformation du format vertical.
- [ ] Les commandes de simulation sont reçues et influencent combat et scores.
- [ ] Les manches redémarrent automatiquement.
- [ ] Les classements sont cohérents et les cadeaux en série non comptés plusieurs fois.
- [ ] La connexion TikTok réelle est éprouvée avec un compte LIVE autorisé.
- [ ] La fermeture arrête le pont local.
- [ ] La licence de la bibliothèque TikTok et des ressources est vérifiée avant distribution.

## Risques et restrictions
La disponibilité des événements TikTok n'est pas garantie ; pas de mot de passe ni cookies demandés. La bibliothèque tierce `tiktok-live-connector` est sous licence AGPL-3.0-only : examiner les implications avant distribution ou commercialisation. La version actuelle est un prototype de développement, **pas une application commerciale finie**.

## Étapes suivantes
Compiler dans GitHub Actions, lire les logs, corriger Godot si nécessaire, télécharger l'installateur de CI, réaliser test Windows réel, tester OBS et TikTok en conditions autorisées, améliorer graphismes et animations.

## V0.4 — Ame, equipes authentiques et matchs de trois manches

Les personnages actifs sont uniquement ceux des spectateurs effectivement inscrits. Les places vacantes restent invisibles ; aucun pseudonyme BOT n'est utilise. Sans un joueur reel de chaque equipe, le timer ne commence pas. Les commandes gratuites restent possibles.

Regles : 3 manches de 60 secondes maximum ; resultat affiche apres la troisieme (victoire Rouge, Bleu ou egalite), 11 secondes de ceremonie, puis nouveau match en manche 1. Les inscriptions persistent, mais les victoires et classements du match precedent sont remis a zero.

Cadeaux et AMES DE JEU (configuration dans bridge/config/gifts.json) :
- Rose : 1 ame
- GG : 1 ame
- Finger Heart : 6 ames
- Doughnut : 35 ames
- Galaxy : 150 ames

Ces quantites ne sont **pas** les prix TikTok. Les noms de cadeaux et disponibilites peuvent varier selon la region. Les cadeaux inconnus n'octroient pas d'ames. Les cadeux non associes a une equipe sont mis en attente, pas attribues aleatoirement.

Pouvoirs automatiques, depenses de la jauge equipe :
- 10 ames : FLAMME, coups d'epee plus rapides pendant 6 s.
- 35 ames : BOUCLIER, parade et soin de groupe.
- 120 ames : TEMPETE, charge amelioree 12 s.

Les dons ne permettent ni pari, ni gain financier, ni prix en argent. La verification des regles de la plateforme et des droits du connecteur reste indispensable avant la monetisation publique.

Tests V0.4 : `game/tests/match_rules.gd` et `game/tests/combat_physics.gd`.
