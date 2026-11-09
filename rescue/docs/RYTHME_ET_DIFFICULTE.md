# MISSION SAUVETAGE LIVE — Rythme et participation active

État du 9 novembre 2026 : premier réglage intégré aux sources de la branche
`production/characters-and-rescue-3d`. Aucun export Windows dans ce lot.

## Comportement livré

- Un participant devient actif après une commande gratuite acceptée. Une simple
  inscription, un cadeau, une commande invalide ou une répétition bloquée ne
  renforcent pas la difficulté.
- L'activité est mesurée sur les 45 dernières secondes, avec un rafraîchissement
  toutes les secondes. Les commandes restent attribuées au vrai pseudo.
- Construction, réparation et objectif collectif demandent davantage de travail
  quand plusieurs personnes participent. Chaque commande acceptée contribue et
  conserve ses points personnels : même une petite progression reste affichée
  avec deux décimales. Un afflux dans la même image est pris en compte.
- Après une baisse de participation, le travail demandé diminue progressivement.
  Les pourcentages déjà gagnés et le nombre de personnes à sauver ne changent pas.
- La pression des incidents reste entre 85 % et 115 % de sa valeur de référence.
  Les cadeaux ne sont jamais une condition de réussite.
- L'acte II peut commencer à 55 % de construction et l'acte III au départ d'une
  évacuation autorisée. Les seuils temporels de 30 % et 68 % restent des solutions
  de repli. Une catastrophe ne fait jamais reculer l'acte déjà atteint.
- Le bandeau distingue les joueurs inscrits des joueurs actifs. Le mode DEMO
  conserve son rythme antérieur et n'invente aucun participant LIVE.

## Réglage initial

Le coefficient de travail est `max(1, joueurs_actifs)^0,75`. Il s'applique aux
gains de construction et de réparation, à l'objectif secondaire, aux actions
spéciales et aux bonus de construction. Les matériaux donnés et les points des
participants gardent leurs valeurs de référence. Les temps de transport et les
confirmations d'arrivée physique restent ceux des missions existantes.

Le coefficient monte à chaque nouvel auteur d'action admise. Il redescend avec
un lissage lorsque l'activité expire. Le danger évolue au maximum de 0,025 point
de coefficient par seconde. L'activité récente se conserve entre deux missions,
mais une nouvelle session ou un changement de mode la réinitialise.

## Vérification effectuée

Godot **4.5.2**, Linux, exécution headless : **12 suites réussies**. La nouvelle
suite `mission_pacing_qa.gd` exécute 49 parties déterministes, sans aucun cadeau :

| Équipe simulée | Missions testées | Durées observées par mission |
|---|---|---|
| 1 joueur | Les 15 | 95,7 à 267,4 s |
| 5 joueurs | Les 15 | 82,2 à 258,2 s |
| 50 joueurs | Les 15 | 60,0 à 227,4 s |
| 100 joueurs | Missions 1 et 15 | 55,5 et 223,5 s |
| 500 joueurs | Missions 1 et 15 | 45,8 et 213,9 s |

Le scénario de test donne à chaque joueur une commande toutes les trois secondes,
avec une stratégie coordonnée : réparer, construire, puis évacuer. Les 49 parties
atteignent leur objectif, sans modifier artificiellement la progression ni le
compteur des personnes sauvées. Ces durées sont celles du modèle de règles ;
elles ne prédisent pas celles de vrais spectateurs ou du rendu 3D physique.

Autres vérifications : afflux de 500 commandes de construction avec 500 auteurs
crédités, exclusion des inscrits inactifs et des dons, anti-spam, baisse de 500 à
5 actifs, préservation du chantier, expiration de l'activité, progression des
actes, fin par expiration du temps et séparation DEMO/LIVE.

Les onze suites précédentes passent également : catalogue, mécaniques de
mission, règles, campagne, routes, arrivées physiques, personnages, production
artistique, niveaux de détail de la foule, chorégraphie et instanciation de scène.
Le contrôle statique de production passe ses 18 vérifications.

## Limites et prochaine recette

Ce réglage n'assure pas encore deux heures de campagne. Avec les joueurs
simulés parfaitement coordonnés, les 15 missions représentent environ 24 à
34 minutes, hors écrans de résultat. Il reste à développer les défis
intermédiaires et le mode marathon, puis à régler le rythme avec de vrais joueurs.

Les tests de règles à 500 joueurs ne sont pas un test réseau TikFinity, une
mesure de FPS ou une preuve que toutes les animations sont visibles en direct.
La limite graphique reste de 48 ouvriers simultanés. Le rendu Windows, la
stabilité pendant deux heures et la réception d'événements TikTok réels restent
à valider. Aucune fusion vers `main`, publication de version ou compilation
Windows n'accompagne ce changement.

## Reproduction

Après import des ressources dans Godot 4.5.2 :

```sh
godot --headless --path rescue/game --script res://tests/mission_pacing_qa.gd
```

La suite fait aussi partie du workflow `rescue-source-qa.yml` : ce workflow
vérifie les sources et ne produit aucun installateur.
