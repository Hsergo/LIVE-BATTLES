# Accueil TikTok LIVE — configuration manuelle et règles

## Limitation technique vérifiée

La passerelle TikFinity Desktop expose `ws://localhost:21213/` pour **recevoir** les événements chat/gift/etc. Cette route ne permet pas d'envoyer un message TikTok LIVE. Le jeu ne doit pas inventer un mécanisme d'écriture et ne doit pas utiliser des cookies ou services non autorisés.

Pour les **réponses dans le chat**, activer la fonction **TikFinity Chatbot** depuis l'application Desktop, connectée au compte créateur en diffusion. Le chatbot envoie depuis le compte créateur et peut être limité par TikTok (TikFinity recommande un maximum d'un message toutes les 15 secondes).

## Configuration à saisir dans le chatbot TikFinity

- Commande `!regles` : `Bienvenue dans LIVE RESCUE ! !join pour participer, !build construire, !repair reparer, !rescue sauver. Le jeu est gratuit.`
- Commande `!aide` : `Ton pseudo apparaitra sur un ouvrier du chantier. Agis avec !build, !repair ou !rescue et gagne des points.`
- Commande `!mission` : `Regarde le titre et le compte a rebours a l'ecran. L'objectif est collectif et tous les commentaires comptent.`
- Message d'accueil épinglé par le créateur : `LIVE RESCUE : participe avec !join et !build. Tape !regles pour apprendre.`

Éviter toute réponse automatique à chaque entrée d'un spectateur : l'intégration ne dispose pas d'un événement fiable listant toutes les personnes qui ouvrent le LIVE et un chat floodé nuirait à l'expérience. L'écran du jeu salue uniquement les pseudos ayant réellement envoyé leur première commande acceptée.

## Cadeaux et consentement

Les cadeaux sont optionnels ; ils déclenchent des effets de jeu sans promesse de valeur financière, ni blocage payant d'un niveau. Aucun message ne doit prétendre qu'une personne réelle risque quelque chose si aucun cadeau n'est envoyé. Le créateur doit pouvoir désactiver les effets de cadeaux.

## Vérifications avant LIVE public

1. Démarrer TikFinity Desktop et un vrai LIVE.
2. Vérifier le statut de réception dans le jeu.
3. Depuis un autre compte envoyer `!regles` et `!build` ; vérifier que le chatbot répond et que le personnage se déplace.
4. Depuis un compte adulte autorisé, facultativement tester un cadeau reconnu et inspecter les points du donateur.
5. Vérifier que le chatbot n'envoie pas des messages indésirables en rafale ; désactiver les réponses concernées si TikTok filtre ou bloque.
