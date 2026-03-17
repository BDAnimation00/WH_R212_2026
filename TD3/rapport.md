# Rapport — [TD3]

## Points clés

### 1. Modéle événement-état-rendu

La rubrique événement montre ce qu'à fait l'utilisateur par exemple: clic sur fermer chrome ❌
Celle de l'état c'est qu'est ce que ça fait par exemple: chrome se ferme
Et celle du rendu c'est le résultat de cette action par exemple: retirer classe .is-visible (chrome)

### 2. En quoi classList.toggle est la passerelle entre JS et CSS ?

classList.toggle est une passerelle car elle permet au JS de piloter uniquement l'état sans toucher au design. 
Le JS se contente d'ajouter ou retirer une classe, laissant ainsi toute la responsabilité du rendu visuel au CSS. Ca respecte la séparation des rôles : le JS gère "quand" ça change et le CSS gère "comment" ça change.

 
## Aucune IA utilisée lors de cette séance ##

<!-- Si aucune IA n'a été utilisée, remplacez tout le bloc ci-dessus par :
"Aucune IA utilisée lors de cette séance." -->
