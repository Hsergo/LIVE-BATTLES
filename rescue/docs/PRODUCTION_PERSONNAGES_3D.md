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


## Production suivante : chorégraphie des sauvetages (source intégrée)

Ce lot complète le premier travail sur les personnages. Il ne déclenche aucune compilation.

### Parcours et véhicules distincts

| Terrain | Route matérialisée dans le moteur | Arrivée |
|---|---|---|
| Pont | Rassemblement, accès au tablier, traversée, rampe, poste médical | Marche et escorte par l'ouvrier du spectateur |
| Digue | Quai de rassemblement, embarquement, traversée en ferry, quai opposé | Refuge installé sur la rive du débarquement |
| Barrage | Quai de secours éloigné des vannes, bateau de traversée | Refuge sur la rive protégée |
| Phare | Embarquement en bateau, navigation, débarquement | Poste de secours du port |
| Héliport | Approche de l'aire, embarquement, vol et dépose au refuge | Zone médicale et hélicoptère suivi par la caméra |

Les trajectoires passent par le module réutilisable `rescue_routes_3d.gd`. Le moteur des villageois et le moteur des véhicules utilisent les **mêmes positions et les mêmes étapes**, au lieu de deux animations indépendantes susceptibles de se décaler.

### Attribution nominative du résultat

Une commande `!rescue` acceptée ajoute le vrai pseudo du spectateur à la file d'embarquement. L'entrée en transit conserve ce pseudo ainsi que l'identifiant stable du villageois ; lorsque la personne arrive réellement en sécurité dans la simulation, le même spectateur reçoit des points de sauvetage supplémentaires et un événement visible. Une action refusée car le chantier est incomplet ou déjà à 100 % n'augmente pas artificiellement les points de construction.

L'ouvrier qui a initié l'évacuation accompagne son villageois sur les missions de pont ; pour les missions maritimes ou aériennes, il se rend au quai ou à l'aire d'embarquement. Aucun villageois n'est présenté comme un compte TikTok.

### Effets et lisibilité

- Réorganisation de la zone des ouvriers pour ne pas les confondre avec la file des civils.
- Socle des rives relevé pour que les pieds soient proches du terrain visible.
- Quai, ferry, zone médicale, hélicoptère et effets visuels synchronisés au déplacement.
- Effets de construction, réparation et arrivée en sécurité plafonnés à **64 petites particules**.
- Environnement météo différencié : pluie, neige et braises selon le scénario.
- Caméra 360 conservée ; suivi temporaire de la personne en cours d'évacuation.
- Les passagers ont une collision neutralisée pendant le transport, puis restaurée au débarquement.

### Fichiers de cette phase

- `rescue/game/scripts/rescue_routes_3d.gd` — positions et phases d'évacuation.
- `rescue/game/scripts/villagers_3d.gd` — animation physique, embarquement, arrivé.
- `rescue/game/scripts/world_3d.gd` — bateaux, aéronef, escorte et caméra.
- `rescue/game/scripts/mission.gd` — propriétaire de l'évacuation et points réellement gagnés.
- `rescue/game/tests/rescue_routes_qa.gd` — tests prévus de tous les types de trajets.
- `rescue/game/tests/rescue_choreography_qa.gd` — tests prévus des escortes, du chat et des arrivées.

### État exact et dernière validation nécessaire

**Modifié dans le dépôt : oui. Tests source de cohérence : prévus. Tests d'exécution Godot : non encore lancés. Compilateur et export Windows : non déclenchés.**

La prochaine étape de recette exige l'import des ressources du moteur, les tests de physiques/animations et un contrôle visuel sur Windows, plus l'essai auprès du vrai créateur TikTok. Il faudra aussi confirmer que les modèles humains riggés sous licence sont visibles dans les trois situations de caméra et que 48 ouvriers restent fluides sur le PC cible.

Ne pas présenter cette phase comme un jeu photoréaliste terminé : les modèles restent mixtes (riggés et procéduraux) et les mouvements ne sont pas issus de mocap professionnelle.

## Cycle suivant : fiabilisation des évacuations et du rendu de foule

**État : changements dans le code source, pas encore de validation moteur.** Cette production conserve la demande de ne créer aucun nouvel installateur avant la recette des personnages.

### Avancées intégrées

- L'événement d'évacuation garde `person_index`, le pseudonyme responsable et une voie distincte (maximum trois voies en simultané ; un transport héliporté à la fois). Les autres demandes restent en file sans disparaître.
- La cadence de trajet est devenue plus progressive pour laisser du temps aux mouvements corporels et aux véhicules.
- **Arrivée physique vérifiée :** en mode 3D, `mission.gd` consulte le callback `arrival_gate` du monde 3D. Le compteur n'augmente qu'une fois le civil à proximité de sa position de refuge ; les points d'arrivée ne peuvent pas être doublés. En mode de règles pures sans 3D, le callback est facultatif.
- En cas de plusieurs évacuations terminées dans le désordre, l'indice du dernier villageois effectivement sauvé permet de guider la caméra vers **la bonne personne**.
- Les personnages de démonstration peuvent accompagner les villageois, sans être présentés comme des spectateurs réels.
- La nouvelle scène ne rejoue plus les anciennes commandes du chat : `last_event` est aligné sur l'identifiant d'événement courant du modèle.
- **Optimisation GPU :** 48 ouvriers simultanément visibles dans le budget de rendu, dont jusqu'à 18 en modèle détaillé ; les autres ont une silhouette 3D allégée. Le système donne priorité à la proximité de la caméra et aux auteurs récents, avec un recalcul environ toutes les 0,6 secondes. Les points et pseudos des personnes hors affichage continuent d'être suivis.
- Les animations de squelettes humains cachés sont suspendues pour ne pas consommer inutilement du temps processeur.

### Vérifications d'intégration prévues, sans compilation immédiate

- `tests/physical_arrival_qa.gd` : ordre d'arrivée inversé, points uniques, file de quatre personnes, trois voies de ferry, fonctionnement sans scène graphique.
- `tests/crew_lod_qa.gd` : 60 spectateurs, 48 ouvriers rendus, 18 modèles détaillés, priorité au dernier auteur d'une action.
- `tests/rescue_choreography_qa.gd` et `tests/rescue_routes_qa.gd` : trajets à pied, embarquement, vol et sécurité des collisions.
- Les tests sont **déclarés dans le workflow Windows**, mais celui-ci est configuré pour un déclenchement manuel et n'a pas été lancé dans ce cycle.

### Points ouverts avant de qualifier le jeu de complet

1. Validation de l'import Godot des modèles riggés, syntaxe GDScript, collisions et animation réellement visible.
2. Comparaison visuelle côte-à-côte de 15 missions, enrichissement de leurs dangers **propres**, pas seulement d'un texte ou d'un multiplicateur de difficulté.
3. Contrôle de stabilité sur une séance de 2 h, notamment avec 50+ spectateurs, et reprise après coupure du pont TikTok.
4. Refonte supplémentaire de la qualité des assets 3D si les personnages restent trop schématiques ; ne pas qualifier de photoréaliste.
5. Validation du connecteur TikTok sur une vraie session avant de dire qu'un LIVE public est prêt.
