# DIRECTION ARTISTIQUE — LIVE RESCUE (PHASE PRODUCTION)

**Statut :** document de production, non certificat de livraison. Aucun nouveau package Windows ne doit être créé avant accord sur cette phase.

## Cible graphique

Style semi-réaliste, coloré et lisible sur TikTok vertical ; matériaux physiques simples, éclairage cohérent et animations humaines fluides. Ce style est préférable à un photoréalisme trop coûteux pour un ordinateur portable et une capture OBS simultanée.

L'écran doit montrer en priorité **le plateau et ses personnages**. Les panneaux d'information doivent rester compacts.

## Personnages à distinguer

| Groupe | Objectif visuel | Fonction |
| --- | --- | --- |
| Ouvriers constructeurs | Gilets haute visibilité, casque, gants, outils, silhouettes différentes | Représentent **uniquement** les véritables participants ayant rejoint le LIVE |
| Techniciens/réparateurs | Varier outils, équipements et gestes | Leur commande !repair doit se traduire par un mouvement de réparation |
| Sauveteurs | Équipement distinct lors de !rescue, gestes de guidage | Déclenchent une évacuation et sont crédités au score |
| Villageois adultes | Vêtements civils variés, sacs, expressions simples | Attendent, se déplacent et rejoignent la zone de sécurité |
| Enfants | Silhouettes plus petites et vêtements colorés | Même logique d'évacuation, jamais identités TikTok |
| Personnes âgées | Marches plus lentes et accessoires distincts | Donnent du sens à l'urgence et aux routes d'évacuation |
| Équipages / marins | Bande de sauvetage, accessoires marins | Visibles avec de vrais bateaux exclusivement dans les missions maritimes |

**Règle des identités :** un villageois est un personnage du scénario et ne doit jamais afficher un faux pseudonyme de spectateur. Les ouvriers LIVE sont créés uniquement à partir des pseudos réellement reçus.

## Cycle de vie complet d'un villageois

1. En attente dans le village, avec animation de respiration / attente ; il compte dans les habitants non sauvés.
2. Dès qu'un participant accepte une action d'évacuation sur un ouvrage sécurisé, affectation de son `person_index` stable.
3. Départ de sa position réelle (pas de téléportation) et marche sur un parcours spécifique au niveau.
4. Pour un pont : traversée sur les sections physiques du tablier. Pour une digue/barrage : contournement d'une zone de protection. Pour un phare : embarquement / guidage maritime. Pour un héliport : progression jusqu'au point d'embarquement.
5. Arrivée au refuge, mouvement de célébration et incrément du score. Le personnage reste visible du côté sauvé.
6. Réinitialisation de la population uniquement au démarrage du niveau suivant.

## Gestion de la foule

- Jusqu'à 500 comptes participants dans le modèle de score ; seuls leurs véritables pseudos sont visibles sur les ouvriers.
- Maximum de 48 ouvriers simultanés à l'écran pour conserver une marge de performance. Le système remplace le moins actif quand un nouveau participant agit.
- Jusqu'à 24 villageois 3D dans une mission. Les états sont conservés par personne.
- Journal des contributions en file de 256 événements, consommation de 12 événements maximum par image pour éviter de bloquer le rendu.
- Les noms d'ouvriers non actifs sont masqués au-delà de 18 personnages pour éviter l'encombrement.

## Production déjà intégrée au code

- Nouveau gestionnaire de villageois `villagers_3d.gd`.
- Apparences procédurales variées, animations simples des bras et des jambes.
- Ouvriers avec protections, gilet réfléchissant, outils visibles seulement lors d'une action.
- Caméra 360° et gros plan temporaire lors d'un sauvetage.
- Eau mobile, pluie selon danger et lumière du refuge.
- Suppression de l'utilisation des bateaux pour représenter une traversée de pont.
- Reconnexion des animations aux actions attribuées aux vrais participants.

Ces fonctionnalités n'ont **pas encore été compilées ni testées visuellement** depuis la mise en pause du workflow.

## Phase suivante : personnages 3D riggés de production

Les modèles actuels sont un **fallback**, pas la qualité artistique définitive. Pipeline cible : modèles glTF 2.0 / GLB riggés, textures optimisées, états Idle / Walk / Work / Repair / Rescue / Cheer, AnimationPlayer et AnimationTree Godot, LOD, tests de nombreuses instances et taille des ressources.

Sources potentielles avec licences à vérifier avant import :
- **Kenney Animated Characters** — packs CC0, silhouettes low-poly riggées et animées ; bon banc d'essai de retargeting.
- **Quaternius RPG Characters** — six personnages riggés animés en glTF et licence CC0 ; attention au style fantasy.
- **Gobkit Free Character Pack Vol.1** — personnes ordinaires riggées/animées GLB sous CC0 (ex. enfant, grand-mère, caissier, coursier), visuellement appropriées pour les villageois.

L'intégration de ces packs n'est **pas encore effectuée**. Ne pas leur attribuer une présence dans le jeu avant import effectif. Conserver dans `assets/licenses/` une copie du fichier de licence et de l'URL de téléchargement avec date. Ne jamais recopier des modèles sans licence.

## Validation exigée avant compilation

1. Relecture statique du nouveau code et exécution prévue des tests `character_visual_rules.gd` et `view_smoke.gd`.
2. Retargeting et animations de la future famille GLB testés pour Idle, Walk et Run.
3. Plateau lisible en 9:16 à 720x1280, lumière de jour et météo.
4. 12 à 24 villageois visibles : aucun véhicule utilisé comme personnage, aucun téléport, aucune collision visuelle grossière.
5. 50+ commandes simulées sur 3 secondes : toutes créditées, animation des nouveaux arrivants, pas de plantage.
6. Évaluer les compromis entre 30 et 60 FPS sur le PC Windows final, OBS lancé.
7. Déclenchement manuel de GitHub Actions seulement après ces vérifications.

**Décision :** ne pas compiler aujourd'hui ; continuer production des personnages, assets et animation avant le paquet Windows.
