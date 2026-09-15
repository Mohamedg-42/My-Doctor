# Règles de Développement - My-Doctor (Flutter)

Ce fichier définit les règles obligatoires et systématiques applicables à tout le code Flutter généré ou modifié dans ce projet.

---

## 1. Règles Strictes Anti-Overflow (RenderFlex Protection)

Tout widget `Row`, `Column`, `Card`, `Container`, `Dialog` ou `BottomSheet` doit être immunisé contre les erreurs **`RenderFlex overflowed by X pixels`** (bandes jaunes et noires).

### A. Dans les `Row`
1. **Jamais de `Text` à contenu variable ou dynamique sans contrainte** :
   - Tout widget `Text` dont le contenu est dynamique (nom, prénom, adresse, téléphone, montants, dates, messages, etc.) ou potentiellement long placé dans un `Row` **DOIT** être enveloppé dans un `Expanded` ou `Flexible`.
   - Toujours spécifier `overflow: TextOverflow.ellipsis` et si nécessaire un `maxLines` (ex: `maxLines: 1` ou `maxLines: 2`).
2. **Utiliser `Wrap` plutôt que `Row` pour les éléments multiples** :
   - Pour les listes de badges, tags, puces (chips), filtres, ou suites de boutons qui peuvent ne pas tenir sur une seule ligne (notamment sur les petits écrans de 320px à 375px), utiliser systématiquement un `Wrap` avec `spacing` et `runSpacing`.
3. **Utiliser `FittedBox` pour les éléments numériques critiques** :
   - Pour les grands nombres, compteurs ou prix dans un espace contraint, utiliser `FittedBox(fit: BoxFit.scaleDown, child: Text(...))`.

### B. Dans les `Column`
1. **Défilement obligatoire pour le contenu vertical variable** :
   - Tout formulaire, fiche descriptive, écran de confirmation, ou liste de détails dans une `Column` doit être enveloppé dans un `SingleChildScrollView` (ou `ListView`).
   - Ne jamais supposer que la hauteur d'écran est infinie (ex: ouverture du clavier virtuel `MediaQuery.of(context).viewInsets.bottom` ou petit écran 568px).
2. **Protection des Dialogs et BottomSheets** :
   - Tout dialogue (`showDialog`, `AlertDialog`, `Dialog`) ou modale (`showModalBottomSheet`) contenant des champs ou plusieurs lignes de texte doit avoir son corps enveloppé dans `SingleChildScrollView` avec `mainAxisSize: MainAxisSize.min`.

### C. Dimensionnement & Responsive Design
1. **Bannir les largeurs fixes excessives codées en dur** :
   - Proscrire les `width: 350`, `width: 400`, etc. Utiliser `double.infinity`, `MediaQuery.of(context).size.width` ou des contraintes relatives (`FractionallySizedBox`, `BoxConstraints`).
2. **Test mental sur petit écran (320px - 360px)** :
   - Avant de valider tout layout, s'assurer qu'il s'affiche parfaitement sur un écran de 320px de large (type iPhone SE 1ère génération) et 360px (standard Android compact).
3. **Padding et Espacements adaptatifs** :
   - Éviter les espacements horizontaux rigides `SizedBox(width: 32)` entre éléments dans un `Row` contraint ; préférer `Spacer()` ou des marges réduites (`8` à `12`).

---

## 2. Checklist Obligatoire pour tout nouveau Widget / Écran

Avant de finaliser une modification :
- [ ] Tous les textes dans les `Row` ont-ils un `Expanded` ou `Flexible` + `TextOverflow.ellipsis` ?
- [ ] Les suites de chips ou boutons risquant de déborder utilisent-ils `Wrap` ?
- [ ] Les dialogues et modales peuvent-ils défiler si le clavier s'ouvre ?
- [ ] Le layout a-t-il été validé sans erreur d'overflow sur `Size(320, 568)` et `Size(360, 640)` ?
