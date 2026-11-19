# MISSION SAUVETAGE LIVE 0.5.0

Jeu coopératif Windows pour TikTok LIVE, en 3D cartoon et au format vertical 9:16. Les spectateurs construisent, réparent et évacuent les habitants avec des commentaires gratuits.

## Cette version

- 15 missions, réparties entre pont, digue, phare, barrage et héliport ; objectifs secondaires, crises et repères 3D propres à chaque niveau.
- Marathon de 1, 2 ou 3 heures de jeu actif, ou campagne classique. La durée se termine à la fin d'une manche ou d'une opération de soutien, sans couper un sauvetage en cours.
- Trois opérations entre les missions : préparer le convoi, rétablir le courant, sécuriser le refuge. Chacune comporte trois étapes gratuites et un bonus pour la mission suivante.
- Sauvegarde automatique toutes les 10 secondes, à la fermeture normale et au changement de mode ; reprise avec scores, progression et habitants en transit. Copie de secours si le dernier fichier est endommagé.
- Pause organisateur et pause lors d'une déconnexion détectée ; la reconnexion ne supprime pas une pause manuelle.
- Jusqu'à 500 participants comptabilisés, avec au plus 48 ouvriers visibles et plusieurs niveaux de détail. La fluidité doit être mesurée sur le PC de diffusion.
- Personnages riggés Quaternius CC0, accessoires procéduraux, collisions et validation de l'arrivée physique avant attribution des points de sauvetage.
- TikFinity Desktop en réception locale ; TikTools en option avec clé gardée uniquement en mémoire. Mode DEMO identifié, événements du simulateur refusés en LIVE.

## Utilisation

Installer `MISSION-SAUVETAGE-LIVE-0.5.0-Setup-x64.exe`, ou extraire **tout** le ZIP portable puis ouvrir `DEMARRER-MISSION-SAUVETAGE.cmd`. Le paquet contient le moteur et Node.js : aucun logiciel de développement à installer.

Lire [le guide de démarrage](docs/GUIDE_DEMARRAGE.md). F10 ouvre la régie : mode, connexion, format du marathon, nouvelle session, reprise, pause et sauvegarde. Le changement de format s'applique après **NOUVELLE SESSION**.

Les cadeaux sont facultatifs et apportent des ressources de jeu. Aucun gain financier ni participation payante obligatoire. Les assistants du jeu fonctionnent par règles locales ; aucun service d'IA payant n'est nécessaire.

## Validation et livraison

[Recette et limites de la V0.5](docs/RECETTE_V05.md). Les simulations accélérées testent les règles de deux et trois heures, la reprise et les changements d'audience. Elles ne prouvent pas les performances graphiques d'une diffusion réelle de trois heures.

Le workflow de sources teste chaque fichier de `game/tests` et le connecteur. Le workflow Windows teste les sources, exporte le jeu, lance le paquet portable, fabrique l'installateur, l'installe puis lance la version installée. Il conserve les journaux et empreintes SHA-256. Les exports sont limités au déclenchement manuel et à la branche dédiée `release/rescue-v0.5-20261119` ; les commits de production ordinaires ne compilent pas Windows.

La V0.5 est une version à tester sur le PC cible. La validation d'un vrai LIVE TikTok, d'OBS et de la fluidité sur cet ordinateur reste à effectuer avant de qualifier le projet de version 1.0. Aucun certificat de signature Windows n'est inclus.
