# My Doctor — Spécifications frontend

## 1. Objet

Ce document définit les tokens visuels et les règles d’implémentation frontend de l’application mobile **My Doctor**. Il couvre les couleurs, la typographie, l’espacement, les composants principaux et les états d’interface nécessaires aux écrans patient.

La spécification reprend l’identité fournie : un symbole circulaire de soin, un signe plus central et une signature typographique arrondie. Les exemples CSS sont directement transposables dans une application web, Flutter ou React Native après adaptation de la syntaxe.

## 2. Direction visuelle

L’interface doit être **médicale, rassurante, accessible et mobile-first**. Le bleu porte la confiance et l’action principale. Le turquoise porte la vitalité, la validation et les éléments de santé. Le corail signale les urgences, erreurs et actions critiques. Le bleu profond structure les textes et les surfaces à fort contraste.

Utiliser des surfaces claires, des composants arrondis et une hiérarchie respirante. Éviter les ombres lourdes, les dégradés décoratifs, les textes trop petits et les écrans surchargés.

## 3. Couleurs

### 3.1 Couleurs de marque

| Token | HEX | RGB | Usage recommandé |
|---|---|---|---|
| `brand-blue` | `#2D9CDB` | `45, 156, 219` | Action principale, liens, sélection active, éléments de navigation |
| `brand-turquoise` | `#27AE60` | `39, 174, 96` | Succès, validation, état sain, confirmation positive |
| `brand-coral` | `#EB5757` | `235, 87, 87` | Urgence, erreur, suppression, déconnexion, notification critique |
| `brand-navy` | `#1A365D` | `26, 54, 93` | Titres, texte fort, en-tête du profil, contraste premium |

> **Note d’implémentation.** Le logo fourni présente un turquoise visuel plus proche du cyan. Pour l’interface produit, conserver `#27AE60` comme couleur sémantique de validation utilisée dans les maquettes actuelles. Si une correspondance stricte avec le fichier logo est demandée, créer un token séparé `logo-turquoise` sans remplacer `brand-turquoise` dans les états fonctionnels.

### 3.2 Neutres

| Token | HEX | RGB | Usage recommandé |
|---|---|---|---|
| `surface-app` | `#FDFCF8` | `253, 252, 248` | Fond général ivoire de l’application |
| `surface-subtle` | `#F7FAFC` | `247, 250, 252` | Champs, éléments secondaires, listes |
| `surface-card` | `#FFFFFF` | `255, 255, 255` | Cartes et surfaces élevées |
| `border-subtle` | `#EDF2F7` | `237, 242, 247` | Bordures discrètes et séparateurs |
| `text-primary` | `#1A365D` | `26, 54, 93` | Titres, libellés importants et contenu principal |
| `text-secondary` | `#4A5568` | `74, 85, 104` | Paragraphes, descriptions et informations secondaires |
| `text-muted` | `#718096` | `113, 128, 150` | Métadonnées, aides, états désactivés |
| `text-on-color` | `#FFFFFF` | `255, 255, 255` | Texte sur bouton ou surface colorée |

### 3.3 États d’interface

| État | Fond | Texte / icône | Règle |
|---|---|---|---|
| Succès | `#E9F7EF` | `#27AE60` | Ajouter une icône ou un libellé, pas uniquement une couleur |
| Alerte | `#FFF4E8` | `#C05621` | Utiliser pour une information nécessitant l’attention |
| Erreur | `#FFF0F0` | `#EB5757` | Décrire l’erreur et indiquer comment la corriger |
| Désactivé | `#EDF2F7` | `#A0AEC0` | Réduire l’intensité sans supprimer la lisibilité |
| Sélection | `#E7F3FB` | `#2D9CDB` | Combiner fond teinté, bordure ou indicateur explicite |

## 4. Variables CSS de référence

```css
:root {
  --color-brand-blue: #2D9CDB;
  --color-brand-turquoise: #27AE60;
  --color-brand-coral: #EB5757;
  --color-brand-navy: #1A365D;

  --color-surface-app: #FDFCF8;
  --color-surface-subtle: #F7FAFC;
  --color-surface-card: #FFFFFF;
  --color-border-subtle: #EDF2F7;

  --color-text-primary: #1A365D;
  --color-text-secondary: #4A5568;
  --color-text-muted: #718096;
  --color-text-on-color: #FFFFFF;

  --color-success-bg: #E9F7EF;
  --color-warning-bg: #FFF4E8;
  --color-error-bg: #FFF0F0;
  --color-selected-bg: #E7F3FB;

  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-5: 20px;
  --space-6: 24px;
  --space-8: 32px;
  --space-10: 40px;
  --space-12: 48px;

  --radius-control: 12px;
  --radius-card: 20px;
  --radius-feature: 24px;
  --radius-phone: 48px;

  --shadow-card: 0 10px 30px rgba(26, 54, 93, 0.06);
  --shadow-phone: 0 30px 60px rgba(26, 54, 93, 0.12);
}
```

## 5. Typographie

### 5.1 Famille principale

Utiliser **Outfit** comme famille principale. Elle reprend le caractère arrondi et accessible de la signature « my doctor » tout en restant lisible sur mobile.

```css
@import url('https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&display=swap');

:root {
  --font-family-brand: 'Outfit', sans-serif;
}
```

Dans une application mobile native, embarquer les fichiers de police localement si la politique de déploiement l’exige. Prévoir les graisses `400`, `500`, `600` et `700`.

### 5.2 Échelle typographique

| Style | Taille | Graisse | Hauteur de ligne | Usage |
|---|---:|---:|---:|---|
| `display` | 32 px | 700 | 38 px | Titre d’accueil ou écran exceptionnel |
| `h1` | 28 px | 700 | 34 px | Titre principal d’écran |
| `h2` | 22 px | 600 | 28 px | Titre de section |
| `h3` | 18 px | 600 | 24 px | Titre de carte ou groupe |
| `body-lg` | 17 px | 400 | 26 px | Introduction et texte important |
| `body` | 16 px | 400 | 24 px | Texte courant par défaut |
| `label` | 14 px | 600 | 20 px | Labels, boutons et champs |
| `caption` | 12 px | 500 | 16 px | Métadonnées et aide secondaire |

Utiliser `text-primary` pour les titres et `text-secondary` pour le texte courant. Ne pas descendre sous 12 px pour du contenu lisible par l’utilisateur.

## 6. Espacement et grille mobile

Utiliser une grille basée sur des multiples de 4 px, avec 8 px comme unité principale. Les écrans mobiles doivent employer une marge horizontale minimale de **20 px** et une marge de **24 px** pour les écrans à forte densité de contenu.

| Élément | Valeur recommandée |
|---|---:|
| Marge horizontale écran | 20–24 px |
| Espacement entre sections | 24–32 px |
| Espacement entre éléments liés | 8–16 px |
| Hauteur minimale d’un bouton | 52 px |
| Zone tactile minimale | 44 × 44 px |
| Hauteur de champ | 52–56 px |
| Rayon champ / bouton | 12 px |
| Rayon carte | 20 px |

Respecter les zones sûres du système, en particulier autour de la barre d’état, de l’encoche et de la barre de navigation inférieure.

## 7. Composants principaux

### Bouton primaire

- Fond : `brand-blue`.
- Texte : `text-on-color`, 16 px, poids 600.
- Hauteur : 52 px minimum.
- Rayon : 12 px.
- État pressé : assombrir légèrement le fond ou ajouter une bordure interne ; ne pas modifier la taille.
- État désactivé : fond `#CBD5E0`, texte `#718096`.

### Bouton secondaire

- Fond : transparent ou `surface-card`.
- Bordure : 1 px `brand-blue`.
- Texte : `brand-blue`, 16 px, poids 600.
- Utiliser pour les actions alternatives, jamais pour l’action critique principale.

### Carte rendez-vous

- Fond : `brand-blue` pour la carte prioritaire.
- Texte : blanc.
- Rayon : 24 px.
- Padding : 20 px.
- Afficher médecin, date, heure et mode de consultation dans cet ordre.
- Ajouter une action explicite pour modifier, rejoindre ou annuler le rendez-vous.

### Carte CMU

- Afficher le numéro CMU masqué par défaut.
- Prévoir l’accès au QR code ou code-barres.
- Afficher l’expiration de la carte avec un libellé clair.
- Ne pas rendre les informations critiques dépendantes d’une couleur seule.

### Barre de navigation

- Position : bas de l’écran.
- Hauteur : 64–72 px hors zone sûre.
- Maximum : quatre ou cinq destinations principales.
- Icône accompagnée d’un libellé court si l’icône n’est pas universelle.
- Onglet actif : `brand-blue` et indicateur visible.
- Onglet inactif : `text-muted`.

### Champs et recherche

- Fond : `surface-subtle`.
- Rayon : 12–16 px.
- Hauteur : 52–56 px.
- Placeholder : `text-muted`.
- Focus : bordure 2 px `brand-blue` et libellé conservé.
- Erreur : bordure `brand-coral`, message explicatif sous le champ.

## 8. Règles par écran

### Accueil patient

Mettre en avant la carte CMU, les accès urgences et la recherche de médecins. Afficher ensuite les rendez-vous à venir, les médecins recommandés et les accès au dossier médical ou au carnet de vaccination.

Les actions urgentes, telles que SAMU et Pompiers, doivent être reconnaissables par leur libellé et leur icône. Ne pas les représenter uniquement par un bouton rouge.

### Prise de rendez-vous

Respecter le parcours : recherche ou médecin sélectionné, date, créneau, confirmation, puis paiement si nécessaire. Utiliser le turquoise pour le créneau sélectionné et le bleu pour l’action finale.

Indiquer explicitement que les rendez-vous sont actuellement stockés localement et temporairement si l’interface est utilisée dans une version de démonstration.

### Profil patient

Regrouper identité, numéro CMU, dossier médical, vaccinations, notifications, apparence, sécurité, FAQ et support. Protéger par défaut les données sensibles et fournir des libellés compréhensibles.

Utiliser le corail uniquement pour la déconnexion, la suppression ou les alertes critiques. Les paramètres courants doivent rester neutres.

## 9. Accessibilité et qualité

- Vérifier le contraste du texte et des contrôles sur chaque fond.
- Ajouter un nom accessible à chaque bouton uniquement représenté par une icône.
- Ne jamais utiliser la couleur comme seul signal de succès, erreur ou sélection.
- Respecter une zone tactile minimale de 44 × 44 px.
- Tester l’interface avec une taille de texte augmentée.
- Prévoir les états chargement, vide, erreur, succès et désactivé.
- Éviter les paragraphes trop longs dans les cartes mobiles.
- Conserver les informations de santé lisibles sans animation obligatoire.

## 10. Mapping Flutter indicatif

```dart
const brandBlue = Color(0xFF2D9CDB);
const brandTurquoise = Color(0xFF27AE60);
const brandCoral = Color(0xFFEB5757);
const brandNavy = Color(0xFF1A365D);
const surfaceApp = Color(0xFFFDFCF8);
const surfaceSubtle = Color(0xFFF7FAFC);
const surfaceCard = Color(0xFFFFFFFF);
const borderSubtle = Color(0xFFEDF2F7);
const textSecondary = Color(0xFF4A5568);
const textMuted = Color(0xFF718096);
```

Pour Flutter, associer `fontFamily: 'Outfit'` au thème global et déclarer les fichiers `.ttf` ou `.otf` dans `pubspec.yaml` si la police est embarquée localement.

## 11. Checklist de livraison frontend

| Vérification | Attendu |
|---|---|
| Couleurs | Aucun HEX hors tokens sans justification |
| Typographie | Outfit et graisses 400/500/600/700 disponibles |
| Mobile | Zones tactiles de 44 px minimum |
| États | Loading, empty, error, success et disabled implémentés |
| Accessibilité | Icônes importantes accompagnées d’un libellé accessible |
| Données santé | Informations sensibles masquées ou protégées par défaut |
| Navigation | Accueil, rendez-vous, messages et profil accessibles en peu d’actions |
| Cohérence | Rayons, espacements et couleurs identiques sur les trois écrans |

## Références

[1]: file:///home/ubuntu/upload/my_doctor_logo_03.png "Logo My Doctor fourni comme source de l’identité visuelle"
