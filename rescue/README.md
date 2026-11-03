# MISSION SAUVETAGE LIVE V0.4 — Chantiers 3D et camera 360

Projet coopératif TikTok LIVE pour Windows (jeu distinct de l'ancien LIVE BATTLES).

**Téléchargement :** onglet GitHub Actions > workflow `MISSION SAUVETAGE LIVE — Windows` > dernier job réussi > artefact `MISSION-SAUVETAGE-LIVE-WINDOWS`. Le fichier contient un installateur .exe et un ZIP portable.

Guide utilisateur : [Lancer le jeu, connecter TikTok et diffuser](docs/GUIDE_DEMARRAGE.md).

- 3 missions : pont, digue et phare ; progression de sauvetage et catastrophe distincte.
- **Nouvelle scene 3D native Godot** : terrain, eau, habitations, grues, pont, digue et phare en volume, ouvriers animes, camera orbitale 360 degres.
- Ouvriers actifs au pseudo du spectateur (maximum 48 visibles pour preserver les performances, jusqu'a 500 spectateurs inscrits et comptabilises).
- Classements distincts : meilleurs constructeurs et meilleurs donateurs ; chaque action active visuellement l'ouvrier correspondant.
- Commandes gratuites : `!join`, `!build`, `!repair`, `!rescue`, votes 1/2/3.
- Cadeaux optionnels = matériaux de jeu, **pas de pari ni gain financier**.
- DEMO autonome et clairement marquée ; LIVE sans pseudo fictif.
- TikFinity Desktop (source locale prioritaire) ou TikTools API avec clé facultative.
- Quatre agents décisionnels locaux : accueil, sécurité, directeur de mission et animation.
- Auto-connexion TikFinity par pseudonyme public enregistré localement ; pas de mot de passe.
- F9 son, F10 interface organisateur, F11 plein écran.

**Important :** les tests automatisés et compilations Windows ne valident ni un vrai TikTok LIVE ni le rendu OBS sur le PC final. La bibliothèque TikTok est non officielle et sa licence doit être respectée.

**Commandes camera :** F7 activer/desactiver rotation 360 ; F6 basculer entre la scene 3D et l'ancienne vue 2D ; F9 son ; F10 panneau organisateur ; F11 plein ecran.
