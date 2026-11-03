# LIVRAISON INTERMEDIAIRE — Production 3D et foule (sans compilation)

## But de cette etape
Passer d'un jeu a jauges et personnages simplifies a une base de **sauvetage 3D lisible**, avec des personnes a sauver et des ouvriers animes et physiquement distincts. Le projet reste organise autour de quinze missions et cinq sites.

## Modifications du moteur 3D publiees
- _Moteur de personnage_ \`character_motor_3d.gd\` : \`CharacterBody3D\`, capsule de collision, mouvement calcule a la frequence physique, \`move_and_slide()\` et masques differents pour ouvriers et civils.
- \`villagers_3d.gd\` : mouvements des villageois avec capsules et trajectoires en plusieurs sections, tailles specifiques pour les enfants, allure personnalisee pour les personnages ages et les enfants, toujours sous l'identifiant \`person_index\`.
- \`world_3d.gd\` : ouvriers beneficiant de collisions, limites physiques sur les garde-corps du pont, vrais sauveteurs diriges vers le groupe a evacuer, animation des bras et jambes toujours visible, camera orbitale plus serree, eclairage et eau moins surexposes.
- \`mission.gd\` : duree de passage des villageois moderee pour correspondre a une marche animee plutot qu'un deplacement rapide.
- \`main.gd\` : HUD vertical avec zones centrales degagees, noms et evenements ponctuels, classement et statistiques de foule en bas du flux.
- Rester en DEMO clairement identifie et ne jamais montrer un faux spectateur LIVE.

## Ce qui n'est pas encore valide
- Nouvelle capture de la V0.4 apres ces changements.
- Collision en temps reel : un test Godot \`crowd_physics_rules.gd\` est redige, pas encore execute.
- Animations professionnelles avec vrais squelettes/glTF : les personnages de production rigges **ne sont pas encore importes**. Le modele reste procedural et ameliore.
- Mesures de performances avec 24 villageois, 48 ouvriers, OBS actif.
- Une vraie session TikTok recevant des commentaires/cadeaux.

## Prochain verrou de production : les modeles 3D
- Selectionner des modeles de **civilils vetus** et des **ouvriers de chantier**, avec licence claire et redistribution autorisee.
- Preferer les packs glTF 2.0 / GLB avec armature et animations Idle/Walk/Work/Rescue.
- Preparer une hierarchie \`assets/characters/worker/\`, \`civilian/\` et un manifeste de licence dans \`assets/licenses/\`.
- Tester une silhouette modele a la fois ; fallback procedural lorsque l'asset est absent ou incompatible.
- Ne pas importer un corps anatomique non vetu, un fichier d'origine incertaine ou un asset incompatible avec les couts GPU du PC.

## Controles autonomes
Le workflow \`.github/workflows/rescue-production-checks.yml\` execute exclusivement l'audit statique \`node rescue/tools/production-preflight.js\`. Il **ne compile pas le jeu**.

Le workflow \`.github/workflows/rescue-windows.yml\` reste lance uniquement par \`workflow_dispatch\`. Ne le declencher qu'apres validation artistique et tests Godot.

## Definition de cette phase
Les changements de source sont une **integration non compilee**. L'audit de code ne prouve pas les collisions physiques, la vitesse d'affichage, le rendu Windows ni la tenue d'un LIVE TikTok.
