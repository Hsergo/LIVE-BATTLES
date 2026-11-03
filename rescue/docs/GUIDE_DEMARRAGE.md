# Guide simple — MISSION SAUVETAGE LIVE V0.2

## 1. Installer sans logiciel de développement

1. Extraire l'archive Windows téléchargée depuis GitHub Actions, puis ouvrir `MISSION-SAUVETAGE-LIVE-Setup-x64.exe`, ou ouvrir directement le ZIP portable.
2. Suivre l'installateur (Windows 10/11 x64).
3. Double-cliquer sur **MISSION SAUVETAGE LIVE**. Le lanceur ouvre automatiquement la passerelle locale puis le jeu.
4. Par défaut, la **DEMO** s'anime seule pour permettre de découvrir le pont, les habitants, la pluie, les catastrophes et l'écran de fin. Aucun faux spectateur n'est présenté comme réel.

L'installation ne nécessite ni Godot, ni Blender, ni Node.js.

## 2. Découvrir les trois actions

- **CONSTRUIRE** : placer des sections du pont. Il doit être terminé à 100 % avant de laisser passer les habitants.
- **REPARER** : renforcer la structure après les vagues et les tempêtes. Si l'intégrité descend trop bas, l'évacuation est dangereuse.
- **EVACUER** : faire traverser un habitant lorsqu'un pont complet et suffisamment solide est disponible.

En démonstration, ces commandes sont accessibles en bas de la fenêtre. Les commandes manuelles sont désactivées en LIVE pour éviter de les présenter comme des participations réelles.

## 3. Connecter TikTok LIVE

1. Lancer un véritable TikTok LIVE avec son compte TikTok, selon les possibilités de ce compte et les règles du service.
2. Démarrer le jeu Windows ; sélectionner **MODE LIVE**.
3. Saisir le **pseudonyme public** TikTok (sans @) et cliquer **CONNECTER LIVE**.
4. Lire le statut. Ne considérer la connexion comme active que lorsque le jeu affiche une confirmation de connexion.
5. Le jeu ne démarre sa mission LIVE qu'après le premier `!join` d'un spectateur, ou la réception de son cadeau reconnu.
6. Le pseudonyme peut être mémorisé localement pour une prochaine ouverture ; ni mot de passe ni cookie ne sont enregistrés.

Le connecteur TikTok est communautaire, non officiel. Même si les tests automatiques fonctionnent, la connexion réelle dépend d'un LIVE autorisé et du fonctionnement actuel de TikTok. Aucun accès à un compte ou à ses paramètres n'est demandé.

## 4. Commandes pour les spectateurs

| Commentaire | Action |
| --- | --- |
| `!join` | Rejoindre les sauveteurs, voir son pseudonyme |
| `!build` / `!construire` | Construire |
| `!repair` / `!reparer` | Réparer le pont |
| `!rescue` / `!sauver` | Lancer un sauvetage |
| `1` | Vote pour renforcer les piliers |
| `2` | Vote pour accélérer la construction |
| `3` | Vote pour prioriser l'évacuation |

Les commandes sont gratuites. Les répétitions trop rapprochées peuvent être ignorées pour préserver la fluidité et éviter le spam.

## 5. Cadeaux TikTok (facultatifs)

| Cadeau reconnu | Matériaux fictifs |
| --- | ---: |
| Rose | +4 |
| Finger Heart | +12 |
| Doughnut | +40 |
| Galaxy | +120 |

Certains cadeaux donnent automatiquement des effets supplémentaires : hélicoptère, grue et digue temporaire. **Ce tableau ne représente PAS le prix des cadeaux en pièces TikTok ou en euros.** Leur disponibilité et leurs noms exacts peuvent varier. Le public peut participer et gagner sans achat.

## 6. Capture et diffusion

La fenêtre de jeu est conçue pour une vidéo **verticale 9:16, 720 × 1280**. Dans OBS ou un logiciel de diffusion compatible, capturer la fenêtre du jeu et choisir un canevas vertical. Tester le rendu, les performances, la lisibilité et le niveau sonore en privé avant la première diffusion.

- **F10** : masquer/afficher les commandes de l'organisateur.
- **F11** : plein écran / fenêtre.
- **F9** : couper/réactiver les effets sonores originaux.

## 7. Si quelque chose ne fonctionne pas

- **Le jeu reste en attente :** sans participant LIVE, aucune mission réelle n'est lancée. Tester d'abord en DEMO.
- **Les commentaires ne déclenchent rien :** contrôler le statut de connexion, puis vérifier que le vrai LIVE est actif.
- **Le pont ne laisse pas passer les habitants :** il doit être construit à 100 % et suffisamment solide.
- **Le jeu ne s'ouvre pas :** vérifier la présence du ZIP portable complet. Les journaux se trouvent dans `%LOCALAPPDATA%\MissionSauvetageLIVE\logs`.
- **Windows SmartScreen affiche un avertissement :** le programme n'est pas encore signé numériquement ; ne désactiver aucune protection de sécurité sans vérifier le fichier et sa provenance.

## 8. Limites de livraison

Les tests automatisés contrôlent le gameplay et le démarrage Windows mais ne valident pas le rendu réel sur chaque PC ni un LIVE TikTok réel. Le lien avec TikTok reste expérimental. La commercialisation et la redistribution du connecteur doivent tenir compte des licences des dépendances, notamment de ses obligations de logiciel libre. Voir le code public et la documentation du fournisseur.
