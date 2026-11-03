# Guide simple — MISSION SAUVETAGE LIVE V0.3

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

## Nouvelle réception TikTok LIVE — TikFinity par défaut

Le connecteur historique `tiktok-live-connector` a été retiré de MISSION SAUVETAGE LIVE. La passerelle locale propose deux alternatives.

**A — TikFinity Desktop (conseillé).** Installer l'application TikFinity Desktop sur le **même PC Windows** que le jeu, créer ou ouvrir son compte TikFinity puis la connecter à son LIVE TikTok actif. La documentation de TikFinity indique une passerelle locale `ws://localhost:21213/`. Dans le jeu, ouvrir les commandes (F10), sélectionner **TikFinity Desktop**, saisir le pseudonyme du créateur, puis cliquer **CONNECTER LIVE**. Si TikFinity n'est pas lancé, le jeu affiche un message de reconnexion et réessaie automatiquement. L'accès direct à TikFinity est nécessaire ; le jeu ne peut pas l'installer ou se connecter à ton compte à ta place.

**B — TikTools API (secours).** Sélectionner **TikTools API**, saisir le pseudo du créateur et une clé API TikTools. La clé est envoyée au pont local, reste **en mémoire uniquement**, et n'est jamais inscrite dans le fichier des préférences du jeu ni sur GitHub. La connexion distante est chiffrée en `wss://`. La disponibilité et la gratuité des offres doivent être vérifiées auprès de TikTools. Re-saisir la clé après redémarrage.

**Signal de réussite réel :** le statut doit indiquer `TIKTOK LIVE CONNECTE VIA ... • EVENEMENTS RECUS`, et le jeu doit réagir à une commande envoyée depuis un vrai spectateur. Une simple liaison avec TikFinity Desktop ne constitue pas à elle seule la preuve que le LIVE est reçu. Le mode démonstration et les tests locaux ne constituent pas une validation TikTok LIVE.

La passerelle n'envoie aucun message, achat ou action vers TikTok : elle ne fait **que lire** les événements destinés à la partie. Aucune dépense n'est nécessaire pour rejoindre, construire, réparer ou participer.

## Agents de jeu intégrés

Quatre assistants décisionnels locaux, sans appel à un service de génération payant :
- **Accueil** : affiche un message avec le pseudonyme réel du nouvel arrivant, une fois par joueur.
- **Sécurité** : prévient lorsqu'une tempête ou une structure fragile demande une réparation.
- **Directeur de mission** : signale les objectifs en cours et la fin des sauvetages.
- **Animation / personnalisation** : félicite les contributions et présente occasionnellement les cadeaux comme **optionnels**, sans obligation ni pression financière.

Il s'agit d'une IA **à règles** : ses décisions utilisent l'état du jeu. Il ne s'agit pas de modèles génératifs ou de bots TikTok. Aucun faux spectateur ni faux cadeau n'est affiché.

## Niveaux jouables

1. **Le pont de la dernière chance** : construire le passage et faire traverser les habitants.
2. **La digue de la tempête** : établir une protection face aux vagues et évacuer les riverains.
3. **Le phare des naufrages** : réparer le phare et guider les bateaux jusqu'à la côte.

Les niveaux disposent de décors distincts, de populations cibles et de coefficients de danger différents. Ils s'enchaînent automatiquement ; les vrais spectateurs restent inscrits, et les délais de commande sont remis à zéro à chaque mission.

## Procédure de validation LIVE à réaliser sur ton compte

1. Démarrer un véritable LIVE TikTok et vérifier sa réception dans TikFinity Desktop (ou TikTools).
2. Dans le jeu, sélectionner la même source. Vérifier le statut de connexion puis les premiers événements.
3. Depuis un autre compte spectateur, envoyer `!build`, `!repair`, `!rescue` et un vote `1`. Vérifier qu'ils provoquent des actions et que le pseudonyme s'affiche.
4. **Facultatif** : envoyer un cadeau TikTok disponible (par exemple une Rose), vérifier l'attribution unique des matériaux et l'animation sans double crédit.
5. Vérifier une reconnexion après une brève interruption de la source et la fluidité dans OBS en 9:16.

La validation de cette dernière étape nécessite une diffusion active et ne peut être simulée comme si elle avait été effectuée.
