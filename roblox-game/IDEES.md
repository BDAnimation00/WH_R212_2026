# 5 idées de jeux Roblox (octobre 2026)

Ce qui marche en ce moment, d'après les classements de joueurs connectés (mi-octobre 2026) :
**Steal An Egg** (n°1, environ 800 000 joueurs en même temps), Steal a Brainrot, Brookhaven, Adopt Me!,
Murder Mystery 2, Blox Fruits, 99 Nights in the Forest. Les mécaniques qui reviennent partout :

- **Le hasard et la rareté** : œufs, graines, mutations, objets « Secret ».
- **La base perso qui rapporte de l'argent même quand on ne joue pas** (logique tycoon).
- **Voler et se faire voler** : ça crée de la tension sociale, et les joueurs en font des vidéos TikTok et YouTube.
- **Des événements à heure fixe** (météo, boss, boutique qui se renouvelle) : ça donne une raison de revenir.
- **Des sessions courtes** qu'on peut jouer sur téléphone (la majorité des joueurs).

---

## 1. Dragon Heist (« vole un œuf », version dragons)
**Inspiré de :** Steal An Egg / Steal a Brainrot.
**Boucle :** tu sors de ta base, tu voles des œufs dans des nids gardés par des dragons PNJ (ou dans la base des autres joueurs), tu les ramènes, tu les fais éclore, et chaque dragon rapporte de l'or par seconde. L'or sert à acheter de la vitesse, des portes blindées et des emplacements d'incubateur.
**Ce qui le distingue :** l'œuf est **mystère** jusqu'à l'éclosion (la rareté se révèle pendant une animation à suspense), et des **mutations par la météo** (orage → dragon électrique x3).
**Ton atout 3D :** les dragons, les œufs et les animations d'éclosion font tout le jeu.
**Difficulté du code :** moyenne. **Potentiel :** très élevé, mais le genre est saturé, donc la direction artistique doit faire la différence.

## 2. Monster Garden (fusion « jardin » + « pets »)
**Inspiré de :** Grow a Garden.
**Boucle :** tu plantes des graines, elles poussent en temps réel et donnent des **créatures** à collectionner au lieu de légumes. Tu les vends ou tu les gardes comme pets qui donnent des bonus.
**Ce qui le distingue :** la boutique de graines se renouvelle toutes les 5 minutes pour tout le serveur, il y a des événements météo à mutations, et on peut échanger entre joueurs.
**Ton atout 3D :** les plantes-monstres (stades de croissance visibles).
**Difficulté du code :** moyenne. **Potentiel :** élevé, avec un public plus jeune et très fidèle.

## 3. Deep Catch (pêche + aquarium tycoon)
**Inspiré de :** Fisch et les jeux de pêche.
**Boucle :** tu pêches avec un mini-jeu de timing, chaque zone a ses poissons rares, et tes prises remplissent ton **aquarium**, qui rapporte de l'argent grâce aux visiteurs PNJ.
**Ce qui le distingue :** des poissons « Secret » à 1/10 000 et des zones qui se débloquent (abysses, lave, glace).
**Ton atout 3D :** les biomes sous-marins et les créatures.
**Difficulté du code :** moyenne. **Potentiel :** bon, et c'est moins saturé.

## 4. 30 Nuits au Camp (survie coop entre potes)
**Inspiré de :** 99 Nights in the Forest / DOORS.
**Boucle :** de 2 à 6 joueurs survivent la nuit dans une forêt hantée. Ils récoltent du bois et de la nourriture, gardent le feu allumé et sauvent des PNJ perdus. Les classes de personnages se débloquent avec de la monnaie.
**Ce qui le distingue :** c'est le plus fun à jouer avec tes potes, et l'ambiance horreur est très visuelle.
**Ton atout 3D :** l'éclairage, l'ambiance, les monstres.
**Difficulté du code :** élevée (IA des monstres, multijoueur, équilibrage). **Potentiel :** élevé, mais c'est plus long à sortir.

## 5. Run Before the Wave (course + collection)
**Inspiré de :** Escape Tsunami For Brainrots.
**Boucle :** une vague géante arrive toutes les X secondes. Tu cours ramasser des objets rares sur la plage et tu reviens en zone sûre avant qu'elle t'emporte. Les objets rapportent de l'argent dans ta base, et tu améliores ta vitesse.
**Ce qui le distingue :** c'est simple, nerveux et très « clipable ».
**Ton atout 3D :** la map en couloir avec des zones de rareté de plus en plus loin.
**Difficulté du code :** faible. **Potentiel :** bon, et c'est le plus rapide à sortir.

---

## Recommandation
- **Premier jeu : n°1 (Dragon Heist)** si on vise le plus gros potentiel, ou **n°5** si on veut sortir quelque chose vite pour apprendre la publication et la monétisation.
- **Monétisation** (pour les cinq) : game passes (vitesse x2, emplacement en plus, porte auto-verrouillée), Developer Products (œufs premium, boosts de chance), abonnement VIP.
- **Règles Roblox à respecter :** afficher les **probabilités** de tout objet aléatoire payant en Robux, et ne pas copier les noms, modèles ou assets des autres jeux (on reprend les mécaniques, pas le contenu).

## Comment on travaille ensemble
1. J'écris tout le code (Luau) dans ce dépôt GitHub.
2. Tu récupères le jeu sur ton PC de l'une de ces deux façons :
   - **Simple :** je génère un fichier `.rbxlx` que tu ouvres directement dans Roblox Studio.
   - **Pratique à long terme :** le plugin **Rojo** dans Studio synchronise le code automatiquement, sans copier-coller.
3. Tu fais la 3D (modèles, map, déco) dans Studio ou Blender. Je te laisse des emplacements nommés (`Spawn`, `Base_1`, `NestZone`…) pour savoir où placer chaque chose.
