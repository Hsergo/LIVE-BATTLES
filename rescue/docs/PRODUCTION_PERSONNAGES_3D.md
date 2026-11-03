# Phase artistique : ouvriers et villageois 3D

**Branche de travail :** `production/characters-and-rescue-3d`

**Instruction du commanditaire :** produire les changements de personnages et du rendu **avant toute compilation**. Il ne faut ni fusionner sur `main` ni déclencher GitHub Actions/Windows tant que la vérification visuelle et les tests n'ont pas été autorisés.

## Diagnostic visuel source

Capture utilisateur : `Screen Recording 2026-11-03 084536.mp4` (59,4 secondes, 670 × 1182, 30 FPS).

Principaux défauts observés :
- Caméra orbitale montrant souvent trop de décor vide et des personnages trop petits.
- Ouvriers trop homogènes, certains modèles CC0 humains non visibles en raison du masquage de leur conteneur.
- Villageois difficiles à distinguer des constructeurs ; sauvetage insuffisamment incarné.
- Rétroaction du sauvetage perçue comme une mise à jour de compteur ; écrans et textes trop envahissants.

## Ce qui a été modifié dans le code source

1. **Ouvriers du LIVE :** pseudonymes rattachés à la racine du personnage, et non à son maillage de secours. Le modèle humain skinné CC0 reste visible lorsqu'il remplace la silhouette procédurale. Casque, bande réfléchissante et sac d'équipement sur le personnage ; gestes animés et rotation selon la trajectoire réelle.
2. **Équipe plus visible :** les 12 ouvriers de la démonstration et les ouvriers inscrits au LIVE ont une zone de rassemblement près du chantier ; les personnes qui agissent se déplacent vers une zone de travail sûre au lieu de traverser le lit de la rivière.
3. **Villageois :** distinguer adultes, enfants et aînés, vêtements et accessoires par situation (sac, canne, gilet de sauvetage pour les missions maritimes). Les squelettes CC0 sont visibles, sans masquer leur propre ancêtre. En plus des avatars riggés, une silhouette procédurale conserve de la diversité et un budget GPU raisonnable.
4. **Comportements :** rassemblement animé en continu, inquiétude et gestes d'appel pendant les catastrophes, traversée physique, étiquette `EN ROUTE`, puis célébration et `SAUVE` pendant quelques secondes après l'arrivée. Aucun villageois n'est présenté comme un spectateur TikTok.
5. **Rendu du site :** poste médical, refuge, véhicule de secours, barrières, balisage lumineux, nuages et eau, hélicoptère avec rotor animé. Les objets servent d'indices visuels sur le sens du sauvetage.
6. **Caméra :** angle légèrement plus lisible en vertical, priorité temporaire au villageois qui traverse puis au sauvetage réussi ; la rotation 360 reste possible.
7. **HUD :** afficher joueurs/ouvriers, personnes en attente, en cours d'évacuation et sauvées ; conserver les classements des constructeurs et donateurs.

## Différence entre ouvriers et villageois

| Sujet | Origine | Interaction | Animation | Statut visible |
|---|---|---|---|---|
| Ouvrier | Pseudo réel après action LIVE valide, ou DEMO clairement identifié | Construit, répare, escorte, aide | Casque/gilet, marche, travail avec outils | Pseudo et action |
| Villageois | PNJ propre au scénario, jamais faux compte TikTok | Attend, appelle, se déplace, traverse, célèbre | Sac, canne, cheveux, marche et gestes d'urgence | EN ROUTE puis SAUVE |
| Superviseur/rescue | Règles du jeu (non connecté au chat) | Sécurité et timing | Signaux, véhicules et caméra | Bandeau minimal |

## Contraintes et limites honnêtes

- Les silhouettes restent **semi-réalistes / stylisées**. Une partie des ouvriers et des adultes utilise le modèle riggé CC0 présent dans le dépôt. Ce n'est pas de la photogrammétrie, et il ne faut pas prétendre au photoréalisme.
- Le système de collisions des `CharacterBody3D` est conservé. Les anciens tests dédiés aux collisions et aux traversées demeurent dans le dépôt.
- Jusqu'à 48 ouvriers sont affichés simultanément ; un spectateur non affiché conserve ses contributions et peut être ramené à l'écran lorsqu'il agit.
- Chaque niveau du catalogue a sa propre population et son effectif. Les modèles de villageois sont purement fictionnels, indépendants des utilisateurs TikTok.
- **Aucun export, compilation ou test de FPS sur Windows n'a été effectué dans cette phase.** Les changements peuvent révéler des erreurs Godot à la validation et ne doivent pas être considérés comme une build livrée.

## Recette avant première compilation autorisée

- Contrôle des scripts et des ressources du dépôt, sans exécuter Godot.
- Lors d'une future QA autorisée : lancer `res://tests/character_stage_qa.gd`, `character_visual_rules.gd`, `art_production_qa.gd` et `crowd_physics_rules.gd`.
- Capturer 20 secondes par angle de caméra et vérifier que les adultes skinnés sont vraiment visibles (plus d'avatars masqués).
- Voir au moins 12 ouvriers visibles dans le mode DEMO, sans collisions anormales ; puis valider 50+ pseudos artificiels uniquement dans une batterie de tests.
- Vérifier que les villageois passent bien entre `attente -> EN ROUTE -> SAUVE` et que leurs positions suivent la progression.
- Mesurer les FPS en 9:16 sur ordinateur portable ; ajuster nombre de personnages riggés, éclairage et densité des décors selon les résultats.
- Vérifier séparément la connexion TikFinity sur un véritable LIVE. La version de production est un système **de lecture** du chat, elle ne peut pas répondre spontanément à tous les nouveaux entrants.

## Prochaine étape artistique

Faire valider les personnages et le parcours d'évacuation sur trois angles (plan large, caméra rapprochée sur l'ouvrier actif, suivi d'un villageois). Ensuite seulement, décider de l'import de personnages glTF supplémentaires sous licences adaptées et de la préparation du premier export d'intégration.
