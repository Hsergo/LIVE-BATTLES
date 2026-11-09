# LIVE RESCUE — PLAN DIRECTEUR ET CRITERES DU JEU COMPLET

**Statut de référence :** dossier maître du projet, et non une nouvelle démonstration. Une version Windows ne sera qualifiée de **1.0 complète** qu'après validation de l'intégralité des jalons et une séance TikTok LIVE réelle.

**Public :** TikTok LIVE francophone ; créateur non développeur sur Windows ; 9:16 ; spectacle de construction et de sauvetage 3D coopératif. Les spectateurs jouent dans les commentaires et voient leur propre personnage intervenir. Les cadeaux restent facultatifs pour la réussite, sans jeu d'argent, tirage au sort payant ou promesse de contrepartie monétaire.

## 1. Engagement final produit

- **15 vraies missions, 5 familles de terrains 3D** : pont, digue, phare, barrage, héliport.
- Chaque mission possède son identifiant, son objectif, son niveau de risque, un événement catastrophique et une commande spéciale gratuite. Les variantes graphiques, scripts événementiels et difficultés seront affinés avant la 1.0.
- **Campagne longue :** total de 125 min 50 s de temps maximal affiché sur 15 niveaux. Si les équipes réussissent rapidement, les manches peuvent être beaucoup plus courtes : cela ne garantit donc pas 2 h de jeu. La version finale proposera des actes intermédiaires, des objectifs bonus et un mode marathon.
- **Participation massivement multijoueur :** jusqu'à 500 pseudos comptés dans le modèle, 48 ouvriers 3D rendus simultanément pour ne pas saturer les GPU d'entrée de gamme ; les places visibles tournent en faveur des auteurs d'actions récentes. Les limites devront être validées en test de charge réel.
- **Démonstration honnête :** un mode DEMO clairement identifié, sans identité ou cadeau fictivement présenté comme réel. Le mode LIVE n'accepte pas les événements du simulateur.
- **Un seul installateur Windows**, lancement automatique du pont local, sans installation de Godot, Node ou Blender.

## 2. Les 15 missions

| # | Chapitre / mission | Mécanique et crise | Objectif / durée limite |
|---:|---|---|---|
| 01 | Pont du dernier espoir | Travées à construire avant la crue ; escorte | 12 habitants / 7 min 30 |
| 02 | Convoi médical | Glissement de terrain et évacuation prioritaire | 10 transports / 7 min 50 |
| 03 | Pont suspendu | Rafales et maintien de l'intégrité | 16 habitants / 8 min |
| 04 | Première digue | Construction de mur et pompage | 14 habitants / 7 min 40 |
| 05 | Quartier submergé | Eau qui contourne la protection | 18 habitants / 8 min 10 |
| 06 | Tsunami du port | Vague rapide et renforcement d'urgence | 20 habitants / 8 min 30 |
| 07 | Phare des naufrages | Réparer le phare et guider les bateaux | 10 navires / 7 min 50 |
| 08 | Nuit sans courant | Gestion des coupures et signal lumineux | 12 navires / 8 min 20 |
| 09 | Ouragan des pêcheurs | Vent extrême et guidage en mer | 18 équipages / 8 min 40 |
| 10 | Barrage de la vallée | Pression de l'eau et réparation des vannes | 16 familles / 8 min 10 |
| 11 | Failles sismiques | Répliques et reconstruction du barrage | 18 familles / 8 min 50 |
| 12 | Vannes en panne | Pannes de mécanismes et seuils de sécurité | 20 familles / 9 min |
| 13 | Flammes de la forêt | Héliport de secours, fumée et incendie | 14 personnes / 8 min 20 |
| 14 | Blizzard en montagne | Missions aériennes, froid et visibilité | 17 alpinistes / 9 min |
| 15 | Cyclone final | Héliport à protéger, dernière évacuation | 24 réfugiés / 10 min |

Les **15 définitions de missions sont écrites** dans `game/scripts/mission_catalog.gd` ; les cinq structures 3D ont une base construite dans `world_3d.gd`. Les objets, risques et objectifs avancés ne sont pas encore tous aussi différenciés qu'ils doivent l'être dans la version finale.

## 3. Les trois boucles d'engagement

**Boucle 1, immédiate (5 secondes) :** une commande valide déclenche une animation sur un ouvrier nommé, ajoute une section ou soigne un composant, augmente son score personnel et déclenche un retour visuel positif sans masquer l'arène.

**Boucle 2, collective (30 à 120 secondes) :** un nouveau danger s'annonce ; les spectateurs choisissent la stratégie par les votes 1/2/3, réparent et construisent, puis voient une conséquence physique (eau, fumée, structures, bateaux, véhicules).

**Boucle 3, campagne (8 minutes environ) :** objectif principal, bonus de sauvetage, classement des constructeurs, des sauveteurs et des donateurs, bilan, prochain niveau, difficulté rehaussée, éventuellement défis de communauté. Le jeu n'affiche jamais de faux spectateurs pendant le LIVE.

## 4. Rôles des cadeaux — facultatifs mais spectaculaires

| Entrée | Effet du jeu | Autre voie de progression |
|---|---|---|
| Commentaire !build | Travée / module de chantier construit ; points au constructeur | Gratuit |
| !repair | Restaure solidité / sécurité ; points | Gratuit |
| !rescue | Envoie une personne ou un bateau en sécurité | Gratuit |
| Action spéciale (!escort / !pump / !signal / !valve / !launch) | Intervention d'équipe spécifique au terrain | Gratuit, avec délai anti-spam |
| Rose | Matériaux et animation de livraison | !build, !repair et coopération |
| Finger Heart | Matériaux, déclenchement éventuel d'hélicoptère de ressources | Ressources gagnées par la construction / réapprovisionnement |
| Doughnut | Renfort du chantier et intervention de grue si seuil atteint | !special / votes |
| Galaxy | Renfort majeur, protection temporaire et effets de mise en scène | Réparation coordonnée et action spéciale gratuite |

Les valeurs **+4/+12/+40/+120** sont des unités fictives propres au jeu, pas les tarifs en Pièces TikTok. Pas de prix en argent, pari, lot aléatoire payant ou obligation de cadeau pour terminer une mission. Les cadeaux doivent produire un effet déterministe, plafonné, visible et attribué au vrai donateur.

**Garde-fous avant activation publique :** conformité des conditions des articles virtuels TikTok, test de réception du combo, déduplication, plafond d'impact, transparence sur le coût réel côté TikTok, option d'arrêt des cadeaux côté organisateur.

## 5. Accueil, messages et agents IA

| Agent | Entrées | Décisions / sorties | Limites |
|---|---|---|---|
| Directeur de mission | Chrono, progression, nombre de participants, niveau | Déroulé des objectifs, montée des risques, déclenchement événementiel | Ne crée pas de faux spectateurs |
| Sécurité | Solidité, intégrité, risques, charges | Alerte, recommandations de réparation, pause éventuelle | Pas de panique ou d'incitation à payer |
| Accueil / personnalisation | Premier !join / commentaire valide | Bienvenue avec vrai pseudo à l'écran, mini-règles | Pas d'autopost chat sans connecteur autorisé |
| Animation / communauté | Actions et classements | Met en avant les nouveaux constructeurs, micro-défis, donateurs | Pas de spam ni manipulation |
| Régie / performance (jalon futur) | FPS, latence, charge et réseau | Réduit particules, nombre de personnages et densité d'effets | Jamais d'action de paiement |

**Le WebSocket TikFinity est un canal de réception, PAS un accès d'écriture au chat.** L'envoi automatique de réponses nécessite le **Chatbot TikFinity activé dans son application**, et donc la connexion du créateur. TikFinity recommande une limite d'un message toutes les 15 secondes. Il n'est pas possible d'assurer qu'un message individuel est envoyé à chaque personne qui ouvre le LIVE ; aucun événement de visite garanti n'existe dans notre intégration.

Expérience visée :
- Message épinglé par le créateur : `LIVE RESCUE : !join • !build • !repair • !rescue • !regles`.
- Réponse chatbot **sur demande** à `!regles` ou `!aide`, avec une configuration TikFinity conforme.
- Bienvenue personnalisée dans le rendu du jeu après la première action valide (sans faux compte).
- Rappel visuel compact et vocal facultatif ; jamais une grande colonne de texte masquant le plateau.

## 6. Architecture technique — cible

| Composant | Aujourd'hui | Cible de production |
|---|---|---|
| Moteur Godot | Godot 4.5.2 / rendu 3D procédural | Migrer d'abord sur branche de test vers Godot **4.7.2 stable** après vérification des plugins et FPS |
| Physique et collisions | Structure du pont liée à des jauges | Jolt Physics, zones de collision, animation de rupture et obstacles |
| Personnages | Corps procéduraux articulés | Personnages 3D riggés sous licence, glTF 2.0, AnimationTree, variation de tenues et LOD |
| Terrains | 5 bases de décors générées | 15 variantes mises en scène, VFX, météo localisée, caméra événementielle |
| Foules | 48 acteurs visibles / modèle jusqu'à 500 pseudos | LOD / pooling / GPU instancing MultiMesh, réglages qualité automatiques |
| Son | Sons synthétisés | Ambiance originale, bruitages par événement, voix d'accueil optionnelle et sous-titres |
| TikTok LIVE | Passerelle TikFinity locale / TikTools optionnel | Diagnostics automatiques, tests vrai LIVE, reconnexion et logs anonymisables |
| IA | Assistants déterministes à règles | Orchestration de risques, conseils contextuels, régie de performance ; génératif facultatif uniquement avec filtre |
| Persistance | Pseudonyme créateur enregistré | Sauvegarde de campagne, scores et préférences avec suppression des données |
| Windows | GitHub Actions + installateur Inno Setup | Signature de code, auto-update vérifié, télémétrie opt-in, compatibilité OBS |

Godot 4.7.2 stable est disponible depuis le 18 août 2026. Les mises à niveau du moteur ne doivent **pas** être improvisées sur une build dont les tests sont verts ; réaliser migration et benchmarking sur branche distincte.

## 7. Grille de livraison vers la version 1.0

| Jalon | Contenu à rendre | Statut honnête | Test de sortie |
|---|---|---|---|
| J0 | Architecture, dépôt et compilation Windows | ✅ Existants | Compilation GitHub vérifiée |
| J1 | 15 missions dans catalogue, 5 sites, commandes spéciales | 🟡 Codés, validation CI à terminer | 15 chargements + événements et sauvegarde des scènes |
| J2 | Gameplay 3 phases par mission et crises réellement différentes | 🟡 15 objectifs secondaires, 15 crises distinctes, 15 repères 3D codés ; 11 suites de tests source réussies | Équilibrage 2 h, tests visuels Windows et vrais joueurs restent nécessaires |
| J3 | Direction artistique, modèles riggés, animation et caméra 360 | 🟡 Caméra/3D procédurale, 15 repères uniques, modèles riggés partiels ; assets pros non intégrés | Contrôle sur PC Windows, lisibilité 9:16, FPS |
| J4 | Système de personnages pour 50+ spectateurs | 🟡 Comptage et rendu basiques ; stress test réel manquant | 50/100/500 participants simulés, aucun événement perdu |
| J5 | Cadeaux spectaculaires, classement et équité | 🟡 Matériaux et classements existants, équilibrage manquant | Test dons réels, déduplication, aucun blocage payant |
| J6 | Agents IA, accueil et chatbot TikFinity | 🟡 Agents d'affichage existants, chat TikTok non connecté en écriture | Test de `!regles` et de la fonction chatbot depuis un vrai LIVE |
| J7 | Mode marathon, sauvegarde, crash recovery, anti-spam | ⬜ À développer | 2 à 3 h sans crash, reconnexion et reprise de partie |
| J8 | Optimisation 3D et intégration Godot 4.7.2 | ⬜ À tester sur branche séparée | Objectif 30 FPS mini sur PC cible ; 60 FPS souhaités |
| J9 | Validation qualité et conformité TikTok LIVE | ⬜ Nécessite vrai LIVE avec créateur | Commentaire, cadeau, OBS, chat et UX confirmés |
| J10 | **Build Windows LIVE RESCUE 1.0** | ⬜ Non livrée | Tous les jalons signés et installateur validé |

**Définition stricte de "terminé" :** 15 niveaux sans crash ni temps mort imposé, aucune fausse identité en mode LIVE, chaque commande donnant un résultat explicite, 50+ participants supportés avec des performances acceptables, relance automatique après incident, installation en un clic, audio/visuels conformes, connexion TikTok réelle validée, guide final et journal des tests.

## 8. Évaluation des risques

- **Technique :** le connecteur TikTok tiers peut cesser de fonctionner ou ne pas exposer certains événements ; prévoir fallback et transparence du statut.
- **Graphique :** un plateau photoréaliste et 50 rigs complets exigent une optimisation, un GPU adéquat et des assets sous licence. La qualité d'un rendu ne se déduit pas d'un test headless.
- **Produit :** 15 niveaux simplement renommés ne suffiraient pas ; imposer des objectifs, dangers et compositions différents.
- **Éthique et règles :** ni cadeaux obligatoires pour éviter une catastrophe, ni récompenses en argent, ni pression émotionnelle ; vérifier les conditions TikTok.
- **Données :** les pseudos, scores, logs et clés API doivent être minimisés ; aucun cookie TikTok ni secret ne doit être stocké en clair.
- **Business :** mesurer spectateurs uniques, participants actifs, temps médian de visionnage, commandes par minute, retour d'un LIVE à l'autre et dons **sans sollicitation répétitive**.

## 9. Répartition des responsabilités

**Assistant développeur :** architecture, code, tests, intégration GitHub, builds Windows, guides, optimisation algorithmique, préparation d'assets libres ou autorisés, diagnostics.

**Créateur (minimum nécessaire) :** installer et ouvrir la build, lancer un LIVE TikTok authentifié, connecter TikFinity Desktop au compte réel, confirmer que les commentaires et cadeaux sont reçus, envoyer une capture ou un enregistrement des problèmes d'affichage. Ni programmation ni Blender exigés.

**Lien du dossier maître :** `rescue/docs/PLAN_DIRECTEUR_LIVE_RESCUE.md`.


## État du jalon J2 — 9 novembre 2026

- Quatre modes de contribution gratuite : construction, réparation, secours et action spéciale ; progression de l'objectif secondaire différente pour chaque mission.
- Trois actes nommés par mission ; niveau de crise, incidents et conséquences spécifiques, renfort collectif gratuit sans cadeau obligatoire.
- Quinze repères 3D procéduraux avec progression de chantier visible et signaux de danger.
- **Validation du code source :** onze suites Godot headless réussies sur la branche de production, run https://github.com/Hsergo/LIVE-BATTLES/actions/runs/42693933282 (aucun export Windows).
- **Non validé :** réalisme graphique, rythme réel sur 2 h, latence TikFinity et performances du PC Windows. Ces tests sont les portes d'entrée du jalon suivant ; ne pas déclarer le jeu 1.0 complet.
