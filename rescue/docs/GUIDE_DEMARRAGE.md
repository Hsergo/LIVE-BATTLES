# MISSION SAUVETAGE LIVE 0.5.0 — Guide de démarrage

## 1. Installer et découvrir

Windows x64. Ouvrir `MISSION-SAUVETAGE-LIVE-0.5.0-Setup-x64.exe`, puis le raccourci du jeu. Avec le ZIP portable, faire « Extraire tout » avant de double-cliquer sur `DEMARRER-MISSION-SAUVETAGE.cmd`. Ne pas lancer le jeu à l'intérieur du ZIP.

Le lanceur démarre la passerelle et le jeu. Godot, Node.js et Blender ne sont pas à installer. Le jeu démarre en DEMO, sauf si une préférence LIVE mémorisée provoque une reconnexion. La DEMO utilise des actions simulées explicitement signalées à l'écran.

En cas d'avertissement Windows, vérifier la provenance du fichier : cette version n'est pas signée numériquement. Les empreintes SHA-256 sont fournies avec la livraison. Aucune désactivation d'antivirus n'est nécessaire.

## 2. Choisir la session

Ouvrir le panneau organisateur avec **F10**.

| Commande | Effet |
| --- | --- |
| Format « Classique » | Les 15 missions se répètent sans durée globale imposée |
| « Marathon 1 h / 2 h / 3 h » | Enchaîne missions et opérations de soutien jusqu'à la durée choisie |
| NOUVELLE SESSION | Applique le format choisi et remet la progression à zéro, après confirmation |
| REPRENDRE | Charge la dernière sauvegarde du mode actuellement choisi |
| PAUSE / CONTINUER | Suspend ou reprend le jeu ; une panne de connexion peut maintenir la pause |
| SAUVEGARDER | Enregistre immédiatement la progression courante |
| MASQUER / F10 | Cache les commandes pour la diffusion |

**Le temps du marathon est du temps de jeu actif.** Les pauses et l'attente initiale d'un participant ne le consomment pas. Le bilan arrive à une fin de manche ou d'opération de soutien : la session peut donc dépasser légèrement la durée prévue. Un ordinateur très lent peut également allonger le temps réel.

Les opérations de soutien alternent : convoi, courant, refuge. Suivre la commande affichée pour avancer plus vite. Les trois étapes donnent un bonus de ressources, de protection ou de solidité à la mission suivante. À l'expiration du délai de soutien, la campagne continue même si les trois étapes ne sont pas terminées. Les cadeaux pendant le soutien réservent des matériaux pour la suite ; ils ne valident pas les étapes.

## 3. Préparer TikTok LIVE

1. Ouvrir un véritable LIVE TikTok avec le compte créateur.
2. Sur le même PC, démarrer **TikFinity Desktop** et le connecter à ce LIVE.
3. Dans la régie du jeu, passer en **MODE LIVE**, sélectionner **TikFinity Desktop**, saisir le pseudonyme du créateur sans `@`, puis **CONNECTER LIVE**.
4. Attendre la confirmation de réception des événements. Une simple connexion à l'application TikFinity n'est pas la preuve que le chat TikTok est reçu.
5. Faire envoyer `!join`, puis `!build` depuis un compte spectateur. Vérifier son pseudo, les points et l'animation.

Le jeu utilise la source déjà sélectionnée dans TikFinity Desktop ; saisir un pseudonyme dans le jeu ne change pas à lui seul le compte connecté dans TikFinity.

Alternative : choisir **TikTools API**, saisir le pseudo et une clé valide. La clé reste en mémoire et doit être ressaisie après redémarrage. La disponibilité du service, ses quotas et son éventuel coût relèvent du fournisseur. Aucune souscription n'est effectuée par le jeu.

La connexion réelle dépend de TikTok et du fournisseur. La passerelle lit les événements ; elle ne publie aucun message dans le chat TikTok. Le chatbot doit être configuré séparément dans l'application du fournisseur si souhaité.

## 4. Jouer gratuitement

Envoyer `!join` pour rejoindre, puis :

| Commentaire | Action |
| --- | --- |
| `!build` / `!construire` | Construction ou étape de soutien |
| `!repair` / `!reparer` | Réparation ou étape de soutien |
| `!rescue` / `!sauver` | Départ en sécurité, après construction et sécurisation du passage |
| `!special` | Action collective adaptée à la mission ; aussi affichée sous un nom spécifique |
| `1`, `2`, `3` | Vote collectif |
| `!regles` / `!aide` | Rappel des commandes à l'écran du jeu |

Les répétitions trop rapprochées sont limitées. Un sauvetage donne ses points quand le personnage atteint effectivement la zone sûre, pas au moment où il se met en route.

Les cadeaux reconnus sont facultatifs : Rose +4, Finger Heart +12, Doughnut +40, Galaxy +120 unités fictives avant les plafonds du jeu. Ce sont des ressources de jeu, pas des prix en pièces ou en euros. La disponibilité et les noms des cadeaux dépendent de TikTok. Aucune dépense n'est nécessaire pour valider la recette des commandes gratuites.

## 5. Reprendre après interruption

Une sauvegarde distincte existe pour DEMO et LIVE. Le jeu enregistre environ toutes les 10 secondes, à la fermeture normale et lors du changement de mode. Après un arrêt brutal, les dernières secondes depuis la sauvegarde peuvent être perdues.

Relancer le jeu, passer en LIVE : sa sauvegarde est reprise automatiquement lorsqu'elle est valide. **REPRENDRE** permet aussi de recharger explicitement la sauvegarde du mode courant. Le message « COPIE DE SECOURS » indique que la sauvegarde précédente a servi après un fichier endommagé. Dans ce cas, un peu plus de progression peut être perdu.

Les scores, le niveau, le marathon et les habitants en route sont restaurés. La partie reste en pause tant que la réception LIVE n'est pas confirmée. Si une pause manuelle avait été enregistrée, cliquer **CONTINUER** après la reconnexion. Les événements survenus pendant la déconnexion ne sont pas rejoués par le jeu.

Données locales : `%APPDATA%\Godot\app_userdata\MISSION SAUVETAGE LIVE`. Fermer le jeu avant toute manipulation de ce dossier. Les fichiers `session_live.json`, `session_demo.json` et leurs copies `.bak` contiennent les pseudos et scores ; ils ne contiennent pas de clé API. Pour repartir sans historique, choisir **NOUVELLE SESSION**, puis sauvegarder. Pour effacer aussi les anciennes copies, supprimer les fichiers de session correspondants et leurs `.bak` après fermeture.

## 6. Diffuser

Le rendu est vertical, 720 × 1280 ; la fenêtre s'ouvre à 540 × 960. Capturer la fenêtre dans OBS ou le logiciel de diffusion autorisé pour le compte. Masquer la régie avec F10, puis vérifier que le cadre, le texte et le son sont lisibles depuis un téléphone.

- F6 : basculer entre la scène 3D et la vue 2D historique. La 3D présente les nouveaux objets de soutien.
- F7 : arrêter ou relancer la rotation de caméra.
- F9 : couper ou réactiver les effets sonores.
- F10 : afficher ou masquer la régie.
- F11 : plein écran ou fenêtre.

Le contrôle visuel de développement a été réalisé avec le moteur Godot sous Linux. Le démarrage automatisé de Windows ne mesure pas les FPS du PC de diffusion. Faire un essai local avec OBS avant le premier LIVE public.

## 7. Diagnostic rapide

| Symptôme | Vérification |
| --- | --- |
| HORS LIGNE / pause réseau | TikFinity ouvert et connecté au bon LIVE ; attendre un événement réel |
| Aucun joueur | Envoyer `!join` depuis un vrai compte spectateur |
| Les habitants restent en attente | Terminer le passage, réparer puis utiliser `!rescue` |
| Reconnexion réussie mais jeu en pause | Dans F10, cliquer CONTINUER si la pause organisateur est active |
| Aucune sauvegarde | Attendre une partie démarrée ou cliquer SAUVEGARDER ; vérifier le message affiché |
| Port 8766 occupé | Fermer une ancienne version de la passerelle ou du jeu puis relancer ; le lanceur ne tue pas les autres applications |
| Fichier absent / démarrage impossible | Réextraire tout le ZIP ou réinstaller ; conserver les journaux |

Journaux : `%LOCALAPPDATA%\MissionSauvetageLIVE\logs` (`game.log`, `bridge-out.log`, `bridge-error.log`). Pour signaler un problème, fournir le numéro de version, le message affiché et la séquence d'actions. Éviter de partager une clé API ou tout autre secret.

## 8. Vérification finale sur le compte créateur

Tester une mission avec commentaires gratuits, une sauvegarde/reprise, une coupure/reconnexion de la source, puis la capture OBS. Un test de cadeau est facultatif et doit rester un choix explicite du créateur. Cette étape avec un vrai LIVE n'a pas été effectuée à distance et reste nécessaire pour valider l'exploitation du jeu.
