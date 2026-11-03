# Dossier de recette — MISSION SAUVETAGE LIVE V0.1

## Cahier des charges
- Une application Windows x64 en un clic sans logiciels de développement requis.
- 1 niveau vertical 9:16, rendu 2,5D autonome sans ressources graphiques tierces.
- Progression du pont de 14% à 100%, intégrité, bois, événements de tempête, crue et sauvetage des habitants.
- Trois issues visuelles : réussite complète, réussite partielle par score, échec.
- Mission de 180 secondes, variantes de nombre d'habitants, enchaînement automatique des missions.
- Liste authentique des contributeurs, aucune identité simulée en LIVE.
- Mode DEMO distinct, avec IA de démonstration (explicitement étiquetée).
- Intégration TikTok expérimentale par WebSocket local, cadeaux optionnels et commandes gratuites.
- Résultat final 12 secondes puis nouvelle mission.
- Mode diffusion F10 / plein écran F11.

## Tests de recette CI
- [ ] Syntaxe et tests de règles Node.js.
- [ ] Export Godot sans erreur de compilation des scripts.
- [ ] Tester l'inscription gratuite, la construction, l'anti-spam et l'évacuation.
- [ ] Tester effets des cadeaux whitelistés et refus des cadeaux inconnus.
- [ ] Tester tempête et digue, victoire, écran final et mission suivante.
- [ ] Vérifier que la scène Godot s'instancie en mode DEMO.
- [ ] Vérifier bascule LIVE, réception d'événements WebSocket et aucune mission sans participants.
- [ ] Exécuter le .exe Windows en headless et détecter SCRIPT ERROR / Parse Error.
- [ ] Démontrer le port /health et /simulate sur loopback.
- [ ] Générer ZIP portable et installateur.
- [ ] Test manuel de rendu 9:16, fluidité (60 FPS visés), OBS et connexion réelle à TikTok.

## Points à vérifier avant diffusion publique
- Le connecteur TikTok tiers n'est pas officiel et peut cesser de fonctionner ; vérifier sa licence AGPL, ses obligations de redistribution et ses Conditions d'utilisation.
- Les prix/noms de cadeaux varient selon les pays et l'application ; ne pas prétendre que les quantités de matériaux représentent des euros/coins.
- L'application ne promet pas de gains financiers, n'organise aucun jeu de hasard payant et ne nécessite aucun paiement pour jouer.
- Le système n'offre pas d'accès au compte TikTok : aucun mot de passe ni cookie à partager.
- L'installateur n'est pas encore signé : Windows SmartScreen peut avertir.

## Prochaines évolutions produit
D'autres missions avec environnement et catastrophes distinctes, sons originaux, effets physiques plus avancés, workers personnalisés, votes entre choix de tracés réellement différents, statut de connexion détaillé, meilleure accessibilité.
