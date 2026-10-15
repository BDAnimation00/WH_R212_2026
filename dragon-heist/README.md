# 🐉 Dragon Heist

Jeu Roblox de vol d'œufs de dragons, d'éclosion et de base qui rapporte de l'or.
Inspiré des mécaniques de Steal An Egg (voir `../roblox-game/ETUDE_MARCHE.md`).

## ▶️ Ouvrir le jeu (sans coder)
1. Télécharge **`DragonHeist.rbxlx`** : sur GitHub, ouvre le fichier puis clique sur « Download raw file ».
2. Double-clique dessus, ou ouvre-le depuis Roblox Studio (**Fichier > Ouvrir**).
3. Clique sur **Play** : tu apparais dans ta base.

Pour que la sauvegarde marche dans Studio : **Accueil > Paramètres du jeu > Sécurité > Enable Studio Access to API Services**.
Pour publier : mets **Max joueurs = 8**, parce qu'il y a 8 bases.

## 🎮 Ce qui marche déjà
| Système | Détail |
|---|---|
| **Jour / nuit** | 10 min de jour, 2 min 30 de nuit. Bandeau en haut de l'écran avec le compte à rebours. |
| **Éclosion en temps réel** | Hors ligne : temps réel. Connecté le jour : **x2**. Connecté la nuit : **x10**. |
| **Nids** | Ils se remplissent toutes les **5 min** pour tout le serveur. 3 zones : Forêt → Volcan → Ciel (de plus en plus rare). La nuit, les œufs rares apparaissent 3x plus. Les œufs Cosmiques et plus rares sont annoncés à tout le serveur. |
| **10 œufs, 9 raretés** | De Commun (10 s) à Éternel (20 h). |
| **Mutations** | Argenté 6 % (x1,2), Doré 4 % (x2), Arc-en-ciel 1 % (x3), et **Lunaire 5 % (x2,5), seulement si l'œuf éclot la nuit**. |
| **Vol** | On maintient E 2 s sur l'incubateur d'un autre joueur, puis on ramène l'œuf chez soi. Le propriétaire est prévenu. |
| **Porte verrouillable** | Bouton rouge dans la base : la porte bloque les autres pendant 60 s (le propriétaire passe), puis 30 s d'attente. |
| **Porter un œuf** | L'œuf flotte au-dessus de la tête et ralentit le joueur. Si le joueur meurt, l'œuf est perdu. |
| **Dragons** | Ils s'affichent sur les 8 socles, rapportent de l'or par seconde et se revendent. |
| **Progression** | Vitesse améliorable (bouton en bas), incubateurs à acheter (de 3 à 6), sauvegarde automatique. |

## ⚙️ Changer l'équilibrage
Tout se règle dans **`src/shared/Config.luau`** (durée du jour et de la nuit, vitesse x10, prix…)
et **`src/shared/Eggs.luau`** (liste des œufs, temps d'éclosion, revenus, chances).
Tu me demandes la modification, je la fais et je te renvoie un nouveau fichier.

**Pour tester vite :** demande-moi un « mode test » (nuits plus fréquentes, éclosions accélérées).

## 🎨 Où mettre ta 3D
- **Map** : tout est dans `Workspace > Map`. Tu peux déplacer, redécorer ou remplacer, à condition de **garder les noms** :
  - `Map/Bases/Base_1` à `Base_8`, chacune avec : `Floor`, `Door`, `LockButton`, `Spawn`, `Sign`, `Incubators/Incubator_1..6`, `DragonPads/Pad_1..8`
  - `Map/NestZones/*` : les surfaces où les œufs apparaissent. Chacune porte un attribut `Zone` (1, 2 ou 3).
- **Œufs et dragons** : mets un Model dans `ReplicatedStorage > Assets > Eggs` ou `Assets > Dragons`,
  avec **exactement l'Id de l'œuf** comme nom (`Ember`, `Moss`, `Storm`, `Magma`, `Obsidian`, `Solar`, `Celestial`, `Nebula`, `Void`, `Primordial`).
  Il remplace automatiquement le cube ou la sphère.
- Plan de la map : `docs/plan-map.png` (image) ou `docs/plan-map.svg`.

## 🔄 Recevoir les mises à jour du code sans perdre ta map
Quand tu auras commencé à modifier la map, n'ouvre plus un nouveau `.rbxlx`. Il faut alors installer **Rojo** :
1. Installe le plugin **Rojo** dans Studio (onglet Plugins > Manage plugins, ou depuis la boutique).
2. Installe Rojo sur ton PC (https://rojo.space/docs).
3. Dans le dossier du projet, lance `rojo serve`, puis clique sur **Connect** dans le plugin.

Le code se met alors à jour tout seul dans Studio, et ta map n'est pas touchée.

## 🗺️ Prochaines étapes
1. Dragons gardiens (PNJ) qui protègent les nids du Volcan et du Ciel.
2. Affichage des probabilités (obligatoire avant de vendre des œufs en Robux).
3. Game passes : vitesse x2, incubateur VIP, verrou plus long. Produits : boost de chance, œuf premium.
4. Événements météo (orage, éclipse) avec des mutations dédiées, et une mise à jour par semaine.
5. Classement global, échanges entre joueurs, rebirth.

## 🛠️ Pour Claude / les devs
- Code : `src/` (Luau), structure Rojo dans `default.project.json`.
- Générer le fichier de jeu : `rojo build default.project.json -o build/code.rbxlx && lune run tools/build-place.luau`
- La map est générée par `src/server/WorldBuilder.luau`. Elle n'est reconstruite en jeu que si `workspace.Map` n'existe pas.
