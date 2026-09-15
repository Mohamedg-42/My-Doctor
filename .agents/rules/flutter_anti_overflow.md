# Règle : Prévention Systématique des RenderFlex Overflow (Flutter)

## Contexte et Déclenchement
Cette règle s'applique à toute création ou modification de code UI Flutter dans le projet `My-Doctor`.

## Directives Strictes

1. **Rows & Contenu Texte Dynamique** :
   - Tout widget `Text` placé dans un `Row` aux côtés d'autres éléments (icônes, boutons, badges, autres textes) DOIT être enveloppé dans `Expanded` ou `Flexible`.
   - Tout `Text` affichant des données dynamiques (noms, adresses, descriptions, prix, statuts) doit inclure `overflow: TextOverflow.ellipsis` et si pertinent `maxLines: 1` ou `maxLines: 2`.

2. **Éléments Multiples & Tags** :
   - Remplacer systématiquement les `Row` alignant des puces/tags/actions par `Wrap(spacing: 8, runSpacing: 8, children: [...])`.

3. **Modales, Dialogues & Formulaires** :
   - Toute `Column` dans un `showDialog`, `AlertDialog` ou `showModalBottomSheet` doit être enveloppée dans un `SingleChildScrollView` avec `mainAxisSize: MainAxisSize.min` pour prévenir les overflows verticaux en cas de petit écran ou d'affichage du clavier.

4. **Tailles Fixes & Contraintes** :
   - Interdiction des largeurs ou hauteurs fixes strictes supérieures à 320px sur les conteneurs de contenu textuel.
   - Utiliser `double.infinity`, `BoxConstraints`, ou `LayoutBuilder` / `MediaQuery`.

5. **Validation Mobile Compact** :
   - Toujours tester le comportement responsive sous `Size(320, 568)` (écran compact) et `Size(360, 640)` (Android standard).
