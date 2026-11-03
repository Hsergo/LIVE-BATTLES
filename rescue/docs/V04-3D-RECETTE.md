# Recette V0.4 — Monde 3D, animation de groupe et impact des spectateurs

## Retour client pris en compte

Le jeu de V0.3 utilisait un decor essentiellement fixe et une poignée de personnages schématiques. La V0.4 remplace par défaut ce plateau par une **scene 3D native Godot**, avec géométrie en volume, végétation, relief, eau, bâtiments et environnements différents pour le pont, la digue et le phare. La caméra orbite continuellement sur **360 degrés** ; F7 permet de l'immobiliser et F6 active l'ancienne vue 2D pour comparaison.

## Personnages

Les ouvriers 3D ont des casques, gilets, chaussures, bras et jambes articulés, animations de marche, de chantier et de réaction, palettes de peau et d'uniformes variées. **Il s'agit encore de personnages stylisés et procéduraux : pas de graphismes photoréalistes ni de motion capture.** Ce réalisme nécessiterait ensuite un pack de modèles 3D professionnels riggés et de nouveaux décors.

L'application affiche au maximum **48 ouvriers en même temps**, pour préserver la fluidité. Au-delà, tous les commentaires valides, cadeaux et contributions sont comptabilisés (jusqu'à 500 inscrits), et un participant qui agit peut remplacer temporairement l'ouvrier le moins récemment actif. Les pseudos réels, et non de faux bots, sont affichés en mode LIVE. Le mode DEMO reste explicitement identifié.

## Attribution des contributions

Une commande acceptée crée un événement nominatif, met à jour les points et déclenche sur un vrai personnage un déplacement vers le chantier, un mouvement des bras et une étiquette décrivant l'action (construction/réparation/sauvetage/renfort). Un bandeau rappelle l'auteur de la dernière action. Les classements **Top constructeurs** et **Top donateurs** sont séparés ; un cadeau n'est pas présenté comme une construction manuelle.

Les points sont cumulés par mission ; les vrais joueurs restent inscrits entre missions. Il n'existe ni gain financier ni achat obligatoire.

## Déroulé visuel

1. Plateau 3D en mouvement : panoramique orbital lent de 39 secondes pour 360°, variation de hauteur.
2. Gros plan temporaire sur l'ouvrier actif lorsqu'une commande arrive.
3. Construction visible pièce par pièce, après l'action des spectateurs.
4. Eau qui monte, nuages mobiles, risque de tempête et variations de l'intégrité du chantier.
5. Evacués qui traversent le pont et bateaux qui se déplacent dans les scènes concernées.
6. Classement final, écran de résultat puis mission suivante.

## Défis différenciés

- **Pont** : terminer le passage en bois et sauver les habitants avant la crue.
- **Digue** : ériger des sections de défense contre des vagues plus puissantes, puis évacuer la zone.
- **Phare** : reconstruire la tour lumineuse et guider les bateaux en mer.

Ces missions disposent de décors, de cibles et de dangers distincts. **Leur logique d'action de base reste commune** (!build, !repair, !rescue), ce qui doit évoluer avant de qualifier le jeu de produit commercial complet.

## Tests automatiques à valider

- Règles Godot et passerelle Node.js réussies.
- Export Windows sans script Godot invalide.
- Instanciation du monde 3D, caméra, sections volumétriques et plusieurs ouvriers.
- Réception TikTok simulée de vrais événements du fournisseur sans mélanger les simulations au LIVE.
- Scénario de 65 vrais participants reconnus, avec au plus 48 ouvriers simultanés.
- UI des classements et contrôle de la visibilité du panneau organisateur.

## Vérifications manuelles encore obligatoires

Lancer la V0.4 sur le PC Windows cible et filmer le rendu 9:16 dans OBS, la fluidité sous charge d'une salle de 50+ personnes, les noms à l'écran, la rotation 360 et la lisibilité. Tester un vrai commentaire TikTok et éventuellement un cadeau avec TikFinity Desktop lors d'un LIVE actif. Aucun test Godot en environnement automatisé ne peut attester d'une performance graphique réelle sur le PC de l'organisateur.

## Pistes d'amélioration restantes

Optimiser la densité du décor avec des LOD et objets instanciés, importer des personnages 3D professionnels libres de droits (en respectant leur licence), ajouter des cascades de risques propres à chaque mission, des rôles spécialisés et des variations de la caméra selon le moment de la partie.
