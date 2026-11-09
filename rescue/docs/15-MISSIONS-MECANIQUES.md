# MISSION SAUVETAGE LIVE — Les 15 mécaniques de mission
**Branche :** `production/characters-and-rescue-3d` — jalon de production **non compilé**.

Ce tableau est synchronisé avec `game/scripts/mission_dynamics.gd`. **Les 11 suites de tests automatisés Godot 4.5.2 passent** (source QA run #4, 9 novembre 2026), notamment les 15 mécaniques, les scènes 3D, la foule, les embarquements et les arrivées physiques.

Preuve : https://github.com/Hsergo/LIVE-BATTLES/actions/runs/42693933282

**Cela ne valide pas encore le rendu sur le GPU Windows, un vrai LIVE TikTok ou la qualité visuelle finale.** Aucune compilation Windows nouvelle n'a été déclenchée.

## Les 15 boucles de jeu

| Niveau | Scénario | Objectif secondaire collectif | Action gratuite efficace | Danger différenciant | Renfort obtenu sans don |
|---|---|---|---|---|---|
| 01 | Pont du dernier espoir | BARRIERES ANTI-CRUE | !build | EAU EN HAUSSE | protection collective temporaire |
| 02 | Convoi médical | COULOIR MEDICAL | !rescue | CONVOI BLOQUE | réapprovisionnement |
| 03 | Pont suspendu | CABLES DE MAINTIEN | !repair | HAUBANS SOUS TENSION | renforcement de la solidité |
| 04 | Première digue | STATION DE POMPAGE | action spéciale gratuite | DIGUE EN SURCHARGE | protection collective temporaire |
| 05 | Quartier submergé | CANAL DE DELESTAGE | !repair | INFILTRATIONS DETECTEES | renforcement de la solidité |
| 06 | Tsunami du port | BARRIERES DU PORT | !build | VAGUE SUR LE PORT | protection collective temporaire |
| 07 | Phare des naufragés | FEU DE GUIDAGE | action spéciale gratuite | VISIBILITE REDUITE | accélération des travaux |
| 08 | Nuit sans courant | GENERATEUR DE SECOURS | !repair | GENERATEUR EN PANNE | réapprovisionnement |
| 09 | Ouragan des pêcheurs | RADIO DES PECHEURS | !rescue | COMMUNICATIONS BROUILLEES | évacuation prioritaire / ressources |
| 10 | Barrage de la vallée | VANNES DE DECHARGE | action spéciale gratuite | PRESSION DU RESERVOIR | protection collective temporaire |
| 11 | Failles sismiques | FONDATIONS ANTISISMIQUES | !repair | REPLIQUES EN COURS | renforcement de la solidité |
| 12 | Vannes en panne | VANNES DE SECOURS | action spéciale gratuite | MECANISME BLOQUE | accélération des travaux |
| 13 | Flammes de la forêt | COULOIR COUPE-FEU | !build | INCENDIE EN APPROCHE | protection collective temporaire |
| 14 | Blizzard en montagne | DEGIVRAGE DU ROTOR | !repair | GIVRAGE DES ROTORS | accélération des travaux |
| 15 | Cyclone final | CENTRE DE COMMANDE | !rescue | CYCLONE SUR LA BASE | évacuation prioritaire / ressources |

### Les trois actes de chaque niveau

Chaque mission affiche trois actes spécifiques, définis dans le catalogue `mission_dynamics.gd`. Les transitions sont calculées autour de 30 % puis de 68 % du temps du niveau, avec indication discrète sur le HUD. Les mêmes commandes `!build`, `!repair`, `!rescue`, `!escort / !pump / !signal / !valve / !launch` restent disponibles tout au long de la partie, sans cadeau obligatoire.

### La jauge d'objectif collectif

L'action centrale de chaque mission apporte davantage de progression que les autres, mais **toute action gratuite admise contribue** ; ainsi, les joueurs ne sont jamais bloqués faute de dons ou de participants experts. Le bonus n'est attribué qu'une fois et influe réellement sur les matériaux, la solidité, la construction, la protection ou les sauvetages selon le scénario.

### La pression des catastrophes

Le danger augmente au fil du temps. Les trois catastrophes principales déjà présentes sont conservées ; le système ajoute des incidents typés (glissement de terrain, vent, panne de courant, tsunami, pression du barrage, séisme, incendie, blizzard, cyclone). Une réussite collective atténue cette pression. Les événements de crise n'inventent pas de dons TikTok et ne simulent pas d'autres spectateurs.

### Les 15 repères 3D spécifiques

Le nouveau script `game/scripts/mission_setpieces.gd` génère un repère différent pour chacun des 15 niveaux. Exemples : sirène d'alerte, véhicule médical, câble de soutien, pompe, canal, vague, feu de guidage, générateur, radar, vannes, fissures, extincteur de feu, neige, centre de commandement. Un indicateur 3D monte physiquement lorsque le collectif avance ; son signal lumineux suit la pression ou devient vert à l'atteinte de l'objectif.

### Affichage LIVE minimaliste

Un bandeau compact présente le titre de l'acte, l'objectif secondaire et le pourcentage de risque. Les conseils de l'agent de stratégie apparaissent ponctuellement, surtout lorsqu'un risque se renforce ; il ne s'agit pas d'un agent ayant des droits d'envoi automatique sur TikTok.

### Conditions avant toute version Windows

1. Faire passer les tests Godot source `mission_dynamics_qa.gd` et `catalog_rules.gd`.
2. Vérifier que les 15 repères s'affichent correctement et restent lisibles en portrait 9:16, sans gêner les villageois.
3. Mesurer le comportement des jauges avec de nombreux événements simultanés et aucune contribution payante.
4. Vérifier les événements, l'absence de doubles points et les 15 résultats victoire/défaite.
5. Évaluer les FPS et le rendu réel sur ordinateur Windows, puis seulement envisager une compilation d'essai.

**Limite actuelle :** les repères sont des géométries procédurales Godot, pas des assets photoréalistes. Les épisodes ont désormais des objectifs et dangers différents dans le code, mais la finition cinématique et l'équilibrage de chaque mission nécessitent des essais.
