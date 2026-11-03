# LIVE BATTLES — jeu interactif TikTok LIVE

**Statut : V0.1 en développement.** Les sources sont publiées ici, mais la compilation Windows et la connexion TikTok LIVE doivent être validées avant tout usage public.

Le jeu vise une application Windows **à lancer en un clic** : combat Rouge contre Bleu, arène 3D cartoon, affichage vertical 9:16, manches automatiques, classements et interactions par commentaires, cadeaux et likes. Le client final n'a pas besoin de Godot, Blender ni Node.js.

## Dossiers
- `game/` : projet Godot 4, arène procédurale 3D et règles des manches.
- `bridge/` : passerelle WebSocket locale et connecteur TikTok facultatif.
- `launcher/` : lancement coordonné du jeu et de sa passerelle sur Windows.
- `installer/` : configuration de l'installateur Inno Setup.
- `.github/workflows/` : tests et compilation automatique Windows.
- `docs/` : cahier des charges et protocole de recette.
- `DEMO-NAVIGATEUR.html` : démonstration autonome hors ligne (distincte du moteur 3D Godot).

## Programme de test / compilation
Le workflow GitHub Actions `LIVE BATTLES Windows` est prévu pour vérifier les tests Node, exporter Godot et créer un fichier `LIVE-BATTLE-Setup-x64.exe` ainsi qu'un ZIP portable. Regarder son exécution dans l'onglet **Actions**. **Ne pas annoncer la disponibilité du Setup tant qu'un workflow réussi et un test sur Windows ne l'ont pas confirmé.**

En mode développement uniquement, la passerelle peut recevoir des événements sur `127.0.0.1:8765` via WebSocket, et une simulation HTTP `POST /simulate`.

## Commandes de spectateurs
`!join red`, `!join blue`, `!attack`, `!defend`, `!heal`, `!status`.

## Sécurité / disponibilité
- Aucun mot de passe ni cookie TikTok nécessaire.
- Port local accessible uniquement via `127.0.0.1`.
- Les points offerts par les cadeaux sont des variables de jeu, non de l'argent.
- Le connecteur `tiktok-live-connector` est **non officiel** et diffusé sous licence **AGPL-3.0-only** ; vérifier obligations de distribution et compatibilité avant commercialisation. Sa connexion à un LIVE n'est pas garantie.
- Les graphismes actuels sont des bases 3D générées par code et non des assets professionnels finaux.

**Source / propriétaire :** dépôt `Hsergo/LIVE-BATTLES`.
