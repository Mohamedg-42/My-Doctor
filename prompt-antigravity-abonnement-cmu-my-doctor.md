# PROMPT ANTIGRAVITY — Intégration exacte des abonnements patient et de la carte CMU-CI

## Mission

Dans mon application existante, intégrer uniquement les deux fonctionnalités suivantes de l’application de référence My Doctor :

1. **Abonnements Santé patient** ;
2. **Carte CMU-CI patient**.

Je veux reproduire exactement les mêmes écrans, la même organisation, les mêmes textes, les mêmes plans, les mêmes informations, les mêmes interactions, les mêmes couleurs, les mêmes comportements et les mêmes règles métier que dans la description ci-dessous.

Ne pas créer une version simplifiée. Ne pas remplacer les fonctions par des placeholders. Ne pas supprimer les fonctionnalités existantes de mon application. Inspecter d’abord mon architecture, mes modèles, mes providers, mes services, mes routes, mon système d’authentification et mon thème, puis intégrer les fonctionnalités en respectant les conventions déjà utilisées dans mon projet.

L’interface doit être en français et responsive sur téléphone, tablette et écran étroit. Les écrans doivent fonctionner sans page blanche, avec gestion des chargements, états vides, erreurs et données manquantes.

---

# PARTIE 1 — ABONNEMENTS SANTÉ

## Écran et route

Créer ou intégrer un écran nommé `PatientSubscriptionScreen`, accessible depuis le profil et le tableau de bord patient.

La route attendue est :

```text
/patient/subscription
```

Cette route doit être réservée à un utilisateur authentifié ayant le rôle patient.

L’écran doit utiliser un `Scaffold` avec :

- fond clair médical ;
- AppBar blanche ;
- bouton retour avec icône flèche gauche ;
- titre exact : `Abonnements Santé` ;
- sous-titre exact : `Du Plan Gratuit au Pack Famille` ;
- contenu défilable verticalement ;
- marges horizontales de 16 pixels environ.

## Ordre exact du contenu

L’écran doit afficher les éléments dans cet ordre :

1. bannière du plan actuel ;
2. section des membres famille uniquement si le plan Famille est actif ;
3. sélecteur de cycle Mensuel / Annuel ;
4. liste complète des quatre plans ;
5. tableau comparatif des fonctionnalités ;
6. section FAQ ;
7. espace inférieur pour éviter que le dernier contenu touche le bord de l’écran.

## Modèle des plans

Créer les enums suivants :

```dart
enum PatientPlanType {
  gratuit,
  essentiel,
  confort,
  famille,
}

enum SubscriptionBillingCycle {
  mensuel,
  annuel,
}
```

Créer un modèle `PatientSubscriptionPlan` contenant au minimum :

```dart
class PatientSubscriptionPlan {
  final String id;
  final PatientPlanType type;
  final String name;
  final String tagline;
  final int monthlyPrice;
  final int yearlyPrice;
  final String? badge;
  final Color accentColor;
  final IconData icon;
  final int maxFamilyMembers;
  final int teleconsultationsIncluded;
  final List<String> features;
  final List<String> highlightedPerks;
}
```

Ajouter les getters et méthodes suivants :

- `isFree` retourne vrai lorsque le prix mensuel vaut zéro ;
- `priceFor(cycle)` retourne le prix mensuel ou annuel ;
- `priceFormatted(cycle)` formate le montant avec des espaces entre les milliers et ajoute `FCFA/mois` ou `FCFA/an`.

## Plans exacts à intégrer

### 1. Plan Gratuit

```text
id : gratuit
nom : Plan Gratuit
type : gratuit
slogan : L'accès essentiel à la santé en ligne
prix mensuel : 0 FCFA
prix annuel : 0 FCFA
badge : Découverte
couleur : gris ardoise
icône : bouclier
membres famille maximum : 1
téléconsultations incluses : 0
```

Fonctionnalités exactes :

- Carte CMU digitale sécurisée ;
- Prise de rendez-vous en cabinet & clinique ;
- Téléconsultation avec paiement à l’acte ;
- 1 profil patient personnel ;
- Rappels SMS de rendez-vous ;
- Recherche géolocalisée de pharmacies de garde.

Avantages mis en avant :

- Carte CMU incluse à vie ;
- Sans engagement, 100% gratuit.

### 2. Plan Essentiel

```text
id : essentiel
nom : Plan Essentiel
type : essentiel
slogan : Pour un suivi médical régulier et connecté
prix mensuel : 1 500 FCFA
prix annuel : 15 000 FCFA
badge : Économique
couleur : bleu
icône : stéthoscope
membres famille maximum : 1
téléconsultations incluses : 1
```

Fonctionnalités exactes :

- Tout ce qui est inclus dans le Plan Gratuit ;
- 1 téléconsultation offerte par mois, valeur 5 000 FCFA ;
- Messagerie directe sécurisée avec les médecins ;
- Dossier médical cloud et prescriptions électroniques ;
- Rappels automatiques de prises d’ordonnances ;
- Support client dédié 7j/7.

Avantages mis en avant :

- 1 téléconsultation gratuite par mois ;
- Messagerie directe avec le médecin traitant.

### 3. Plan Confort

```text
id : confort
nom : Plan Confort
type : confort
slogan : La formule individuelle complète & prioritaire
prix mensuel : 3 500 FCFA
prix annuel : 35 000 FCFA
badge : Le Plus Choisi
couleur : vert turquoise
icône : cœur avec pulsation
membres famille maximum : 1
téléconsultations incluses : 3
```

Fonctionnalités exactes :

- Tout ce qui est inclus dans le Plan Essentiel ;
- 3 téléconsultations complètes incluses chaque mois ;
- Ligne prioritaire Urgences & SAMU 24h/24 ;
- Suivi intelligent des constantes, notamment tension et glycémie ;
- Historique et archivage illimité des examens de laboratoire ;
- Remises exclusives jusqu’à -15% en pharmacies partenaires ;
- Télé-expertise auprès de spécialistes.

Avantages mis en avant :

- 3 téléconsultations incluses par mois ;
- Accès prioritaire 24h/24 et réductions pharmacie.

### 4. Plan Famille

```text
id : famille
nom : Plan Famille
type : famille
slogan : Sérénité totale pour toute votre famille jusqu’à 6 personnes
prix mensuel : 6 500 FCFA
prix annuel : 65 000 FCFA
badge : Pack Famille (Jusqu’à 6)
couleur : orange doré
icône : utilisateurs
membres famille maximum : 6
téléconsultations incluses : 6
```

Fonctionnalités exactes :

- Couverture complète pour 6 membres : conjoint, enfants, parents ;
- 6 téléconsultations partagées par mois pour la famille ;
- Carnet de santé et vaccination pédiatrique pour les enfants ;
- Cartes CMU centralisées pour tous les membres du foyer ;
- Assistance médicale SOS Famille prioritaire 24/7 ;
- Consultations pédiatriques et gynécologiques prioritaires ;
- Partage simplifié des bilans de santé aux proches ;
- Économie de deux mois complets en paiement annuel.

Avantages mis en avant :

- Jusqu’à 6 personnes couvertes ;
- 6 téléconsultations par mois et suivi pédiatrique.

## Bannière du plan actuel

En haut de l’écran, afficher une carte en dégradé indiquant :

- badge `PLAN ACTIF` ;
- icône du plan ;
- nom du plan ;
- slogan du plan ;
- nombre de téléconsultations incluses ;
- date de fin pour les plans payants ;
- texte `Actif à vie` pour le Plan Gratuit ;
- badge `Mensuel` ou `Annuel` pour un plan payant.

Pour le Plan Gratuit, afficher :

```text
Téléconsultations : à l’acte
Actif à vie
```

Pour un plan payant, afficher :

```text
X téléconsult. incluses/mois
Jusqu’au JJ/MM/AAAA
```

## Sélecteur de facturation

Créer un sélecteur visuel à deux choix :

- `Mensuel` ;
- `Annuel`.

Le cycle mensuel est sélectionné par défaut. Le changement de cycle doit immédiatement recalculer le prix affiché dans toutes les cartes de plan.

## Cartes des plans

Chaque plan doit être présenté dans une carte avec :

- couleur d’accent du plan ;
- icône ;
- badge commercial lorsque présent ;
- nom ;
- slogan ;
- prix du cycle sélectionné ;
- liste des fonctionnalités ;
- avantages mis en évidence ;
- bouton de sélection ;
- indication visuelle lorsqu’il s’agit du plan courant.

Le bouton du plan courant doit afficher que le plan est déjà actif. Cliquer dessus ne doit pas ouvrir de paiement et doit afficher :

```text
Vous êtes déjà sur le [nom du plan].
```

## Passage à un plan payant

Lorsqu’un patient sélectionne un plan payant différent du plan actif, ouvrir une modal de checkout ou une bottom sheet.

La bottom sheet doit afficher :

- le plan choisi ;
- le cycle Mensuel ou Annuel ;
- le prix total ;
- le montant périodique ;
- les avantages principaux ;
- le moyen de paiement ;
- un bouton de confirmation ;
- un bouton d’annulation.

Afficher un indicateur de chargement pendant l’opération et empêcher les doubles clics.

L’état d’abonnement doit contenir au minimum :

```dart
class PatientSubscription {
  final String patientId;
  final String planId;
  final SubscriptionBillingCycle cycle;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String paymentMethod;
  final List<FamilyMember> familyMembers;
}
```

Après confirmation réussie :

- créer le nouvel abonnement ;
- sauvegarder le plan ;
- sauvegarder le cycle ;
- enregistrer le moyen de paiement ;
- calculer une durée de 30 jours pour le mensuel ;
- calculer une durée de 365 jours pour l’annuel ;
- rafraîchir la bannière ;
- afficher un message de succès ;
- fermer la modal.

Si le projet n’a pas encore de vraie API de paiement, conserver une couche de service séparée et utiliser une simulation clairement identifiée en mode développement. Ne jamais afficher un paiement réel comme confirmé avant le retour positif de la passerelle de paiement.

## Retour au Plan Gratuit

Lorsque le patient sélectionne le Plan Gratuit alors qu’il possède un plan payant, afficher une confirmation avec exactement cette idée :

```text
Passer au Plan Gratuit
En revenant au Plan Gratuit, vos téléconsultations incluses et avantages famille prendront fin à la date d’échéance.
```

Boutons :

- `Annuler` ;
- `Confirmer`.

Après confirmation, le plan devient Gratuit, les avantages famille sont supprimés et la sauvegarde est mise à jour. Afficher :

```text
Votre abonnement est désormais le Plan Gratuit.
```

## Plan Famille et membres

Afficher la section `Membres de la Famille` uniquement lorsque le plan actif est Famille.

Afficher :

```text
Membres de la Famille
X / 6 membres enregistrés
```

Ajouter un bouton `Ajouter` tant que le nombre de membres est inférieur à six.

Si aucun membre n’existe, afficher :

```text
Ajoutez jusqu’à 6 membres (enfants, conjoint, parents) pour leur faire bénéficier de votre couverture santé.
```

Chaque membre doit contenir :

```dart
class FamilyMember {
  final String id;
  final String fullName;
  final String relationship;
  final String? cmuNumber;
  final DateTime? birthDate;
}
```

Le dialogue d’ajout doit contenir :

- champ `Nom & Prénoms *` ;
- champ ou liste `Lien de parenté` ;
- choix `Conjoint(e)` ;
- choix `Enfant` ;
- choix `Parent (Père/Mère)` ;
- choix `Autre proche` ;
- champ `Numéro CMU (optionnel)` ;
- bouton `Annuler` ;
- bouton `Ajouter`.

Le nom est obligatoire. Si le nom est vide, ne pas ajouter le membre et afficher une validation. Générer un identifiant unique pour chaque membre. Afficher le nom, la relation et le numéro CMU lorsqu’il existe. Ajouter une icône de suppression avec confirmation si nécessaire.

Limiter strictement le nombre à six membres et sauvegarder les membres dans l’abonnement du patient.

## Tableau comparatif et FAQ

Ajouter sous les plans un tableau comparatif des fonctionnalités reprenant les différences entre :

- Plan Gratuit ;
- Plan Essentiel ;
- Plan Confort ;
- Plan Famille.

Ajouter ensuite une FAQ sous forme de sections extensibles. Utiliser des composants Material correctement entourés par `Material` afin d’éviter les erreurs Flutter avec `ExpansionTile`.

La FAQ doit expliquer :

- la différence entre Mensuel et Annuel ;
- les téléconsultations incluses ;
- le fonctionnement du Plan Famille ;
- l’arrêt ou le changement d’abonnement ;
- la conservation de la carte CMU ;
- les paiements et moyens de paiement.

## Persistance abonnement

Créer un provider équivalent à `PatientSubscriptionProvider` avec :

- liste statique des quatre plans ;
- abonnement courant ;
- cycle sélectionné ;
- état de chargement ;
- identifiant du patient courant ;
- initialisation pour le patient connecté ;
- abonnement à un plan ;
- ajout d’un membre famille ;
- suppression d’un membre famille ;
- annulation d’abonnement ;
- sauvegarde locale par identifiant patient.

La clé de persistance doit être isolée par patient, par exemple :

```text
patient_sub_[patientId]
```

Lorsqu’aucun abonnement n’existe, créer automatiquement le Plan Gratuit avec :

- `isActive = true` ;
- moyen de paiement `Gratuit` ;
- durée très longue ou comportement équivalent à `Actif à vie`.

---

# PARTIE 2 — CARTE CMU-CI

## Écran et route

Créer ou intégrer un écran nommé `CmuScreen`, accessible par :

```text
/patient/cmu
/patient/my-card
/cmu
```

Les trois routes doivent ouvrir le même écran et être protégées par le rôle patient.

L’écran doit utiliser un `Scaffold` avec :

- AppBar bleu CMU ;
- bouton retour uniquement si la route peut être quittée ;
- logo rond ou badge contenant `CMU` ;
- titre exact `CMU-CI` ;
- sous-titre exact `Couverture Maladie Universelle` ;
- TabBar de quatre onglets ;
- TabBarView correspondant aux quatre onglets.

## Les quatre onglets exacts

Les onglets doivent être :

1. `Ma Carte` avec icône carte bancaire ;
2. `Économies` avec icône comparaison ;
3. `Santé` avec icône cœur ;
4. `Couverture` avec icône bouclier.

Utiliser un `TabController(length: 4)` correctement détruit dans `dispose()`.

## Modèle de carte CMU

Créer ou adapter un modèle `CmuCard` contenant :

```dart
class CmuCard {
  final String cmuNumber;
  final String lastName;
  final String firstName;
  final String gender;
  final String profession;
  final String commune;
  final String city;
  final DateTime birthDate;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String? photoUrl;
  final String? photoBase64;
  final bool isActive;
}
```

Ajouter les getters :

- `fullName` ;
- `formattedBirthDate` au format `JJ/MM/AAAA` ;
- `formattedIssueDate` au format `JJ/MM/AAAA` ;
- `formattedExpiryDate` au format `JJ/MM/AAAA` ;
- `isExpired`.

## Initialisation depuis l’utilisateur connecté

La carte ne doit pas utiliser un nom ou une photo codés en dur. La construire à partir du `UserModel` connecté :

- numéro CMU : `user.cmuNumber`, ou valeur de secours clairement identifiée si absent ;
- nom en majuscules ;
- prénom ;
- sexe ;
- profession ;
- commune ;
- ville ;
- date de naissance ;
- date de création comme date d’émission ;
- date d’expiration deux ans après la date de création ;
- photo locale base64 prioritaire ;
- photo URL en second choix ;
- carte active si le statut du compte est actif.

Initialiser la carte après la connexion patient et la remettre à `null` lors de la déconnexion.

## Onglet Ma Carte

Si aucune carte n’est disponible, afficher exactement un état vide utile :

```text
Aucune carte CMU enregistrée
```

Si une carte existe, afficher une carte digitale CMU-CI avec :

- dégradé bleu `#185FA5`, bleu foncé et vert ;
- motif de sécurité en arrière-plan ;
- mini-drapeau ivoirien orange, blanc, vert ;
- logo bouclier ;
- texte CMU-CI ;
- nom complet ;
- numéro CMU ;
- date de naissance ;
- commune et ville ;
- date d’émission ;
- date d’expiration ;
- photo utilisateur si disponible ;
- état actif, expiré ou inactif.

Masquer le numéro CMU par défaut. Ajouter un bouton ou une interaction pour afficher/masquer le numéro complet.

Ajouter les actions :

- `Télécharger` ;
- `Partager` ;
- `Afficher QR Code complet`.

Le bouton Télécharger doit afficher un retour de succès comme :

```text
Carte téléchargée avec succès
```

Si le téléchargement réel n’est pas encore branché, créer un service d’export séparé et afficher clairement le mode simulation en développement.

Le bouton Partager doit ouvrir une bottom sheet blanche arrondie avec le titre :

```text
Partager avec
```

Afficher quatre choix :

- Médecin ;
- Pharmacie ;
- Laboratoire ;
- Imprimer.

Le bouton QR Code doit afficher une boîte de dialogue avec :

- titre `QR Code CMU` ;
- QR code généré à partir des informations de la carte ;
- numéro CMU ;
- texte `Scanner pour vérifier la validité de la carte` ;
- bouton `Fermer`.

La donnée QR doit reprendre au minimum le numéro CMU, le nom complet et la date de naissance formatée, par exemple :

```text
[cmuNumber]|[fullName]|[formattedBirthDate]
```

## Informations de couverture

Sous la carte digitale, afficher une section d’informations avec les données de la carte et une section de statut.

Le statut doit différencier :

- carte active ;
- carte expirée ;
- compte inactif ;
- données manquantes.

Afficher les dates au format français et utiliser des badges de couleur faciles à comprendre.

## Onglet Économies

Créer l’onglet de comparaison des coûts avec la liste exacte de données suivante :

| Prestation | Description | Sans CMU | Avec CMU | Catégorie |
|---|---|---:|---:|---|
| Consultation généraliste | Visite chez le médecin traitant | 10 000 FCFA | 3 000 FCFA | Consultation |
| Consultation cardiologue | Spécialiste cardiologie | 25 000 FCFA | 10 000 FCFA | Consultation |
| Consultation pédiatre | Spécialiste enfants | 20 000 FCFA | 8 000 FCFA | Consultation |
| Hospitalisation 3 jours | Séjour en chambre commune | 150 000 FCFA | 30 000 FCFA | Hospitalisation |
| Appendicite (opération) | Chirurgie + hospitalisation | 500 000 FCFA | 125 000 FCFA | Hospitalisation |
| Paracétamol 500mg x30 | Antalgique courant | 2 000 FCFA | 400 FCFA | Médicaments |
| Amoxicilline 500mg x21 | Antibiotique | 8 000 FCFA | 1 600 FCFA | Médicaments |
| Prise de sang complète | NFS + bilan métabolique | 25 000 FCFA | 7 500 FCFA | Examens |
| Échographie abdominale | Imagerie médicale | 40 000 FCFA | 14 000 FCFA | Examens |
| Accouchement normal | Maternité + séjour 3j | 200 000 FCFA | 0 FCFA | Maternité |

Créer un modèle `CostComparison` avec :

- type de soin ;
- description ;
- montant sans CMU ;
- montant avec CMU ;
- catégorie ;
- économie calculée ;
- pourcentage d’économie calculé.

Afficher :

- le total des économies ;
- les montants sans CMU et avec CMU ;
- les économies en FCFA ;
- les catégories avec filtres éventuels ;
- une présentation visuelle claire avec barres ou cartes comparatives.

## Onglet Santé

Créer un tableau de suivi de constantes basé sur le modèle `HealthMetric`.

Types pris en charge :

```dart
enum HealthMetricType {
  bloodPressure,
  bloodSugar,
  heartRate,
  weight,
  temperature,
  oxygenSaturation,
}
```

Chaque mesure contient :

- identifiant ;
- type ;
- valeur principale ;
- deuxième valeur optionnelle pour la tension ;
- unité ;
- date d’enregistrement ;
- note facultative.

Afficher les dernières valeurs disponibles pour :

- tension artérielle ;
- glycémie ;
- fréquence cardiaque ;
- poids ;
- saturation en oxygène ;
- température si elle existe.

Données de démonstration de référence à afficher si le mode démo est activé :

- tension : 120/80, 118/78, 125/82, 122/79, 119/77, 117/76, 121/80 ;
- glycémie : 0,95, 0,98, 1,02, 0,97 g/L ;
- fréquence cardiaque : 72, 75, 70, 73 bpm ;
- poids : 78,5, 78,2, 77,9 kg ;
- saturation O2 : 98%, 97%, 98%.

Calculer les statuts :

- tension basse, normale, élevée ou haute ;
- glycémie hypoglycémie, normale, pré-diabète ou diabète ;
- fréquence cardiaque bradycardie, normale ou tachycardie ;
- saturation normale, faible ou critique.

Ajouter la possibilité d’ajouter une nouvelle mesure via un formulaire. Après ajout, recalculer le résumé et rafraîchir l’écran.

Afficher une mention claire indiquant que les données sont informatives et ne remplacent pas un avis médical.

## Onglet Couverture

Créer une liste des prestations CMU avec le modèle `CmuBenefit`.

Afficher exactement les prestations suivantes :

| Catégorie | Prestation | Description | Couverture | Plafond |
|---|---|---|---:|---:|
| Consultations | Consultation généraliste | Consultation chez un médecin généraliste | 70% | 10 000 FCFA |
| Consultations | Consultation spécialiste | Consultation chez un médecin spécialiste | 60% | 15 000 FCFA |
| Hospitalisation | Frais de séjour | Frais d’hospitalisation en chambre commune | 80% | 500 000 FCFA |
| Hospitalisation | Actes chirurgicaux | Interventions chirurgicales couvertes | 75% | 800 000 FCFA |
| Médicaments | Médicaments essentiels | Médicaments sur la liste CMU | 80% | 50 000 FCFA |
| Médicaments | Médicaments chroniques | Traitements longue durée | 90% | 100 000 FCFA |
| Examens | Analyses biologiques | Examens de laboratoire prescrits | 70% | 30 000 FCFA |
| Examens | Radiologie / Imagerie | Radio, échographie, scanner | 65% | 80 000 FCFA |
| Maternité | Suivi de grossesse | Consultations prénatales et accouchement | 100% | 300 000 FCFA |
| Urgences | Soins d’urgence | Urgences médicales et SAMU | 100% | 200 000 FCFA |

Permettre de filtrer ou regrouper les prestations par catégorie. Chaque ligne doit afficher le taux de couverture, le plafond et la description.

## Demandes CMU

Créer un modèle `CmuRequest` avec :

- identifiant ;
- type ;
- description ;
- statut ;
- date de création ;
- réponse éventuelle.

Statuts exacts :

```dart
enum CmuRequestStatus {
  pending,
  inProgress,
  resolved,
  rejected,
}
```

Libellés français :

- `En attente` ;
- `En cours` ;
- `Résolu` ;
- `Rejeté`.

Données de démonstration de référence :

1. Demande de remboursement consultation du 15/01/2025, statut Résolu, réponse : remboursement de 7 000 FCFA effectué sur Orange Money le 25/01/2025 ;
2. Changement d’adresse suite à déménagement, statut En cours.

Afficher ces demandes dans l’onglet Couverture ou dans une section dédiée de l’espace CMU. Ajouter un bouton pour créer une nouvelle demande si cette fonctionnalité existe dans mon application.

## Provider CMU

Créer ou adapter un `CmuProvider` avec les propriétés suivantes :

- `CmuCard? card` ;
- `List<HealthMetric> healthMetrics` ;
- `List<CmuBenefit> benefits` ;
- `List<CostComparison> costComparisons` ;
- `List<CmuRequest> requests` ;
- `bool isLoading` ;
- `bool hasCard`.

Méthodes attendues :

- `initFromUser(UserModel user)` ;
- `reset()` ;
- `addHealthMetric(HealthMetric metric)` ;
- `addRequest(CmuRequest request)` ;
- `getMetricsByType(HealthMetricType type)` ;
- `getLatestMetric(HealthMetricType type)` ;
- `getHealthSummary()` ;
- `totalSavings` ;
- `savingsByCategory`.

Initialiser les données statiques de démonstration dans le provider sans les mélanger avec les données réelles de l’utilisateur. Préparer une couche de service permettant de remplacer les données de démonstration par une API réelle plus tard.

## Photo patient

Réutiliser le sélecteur de photo existant si disponible. La priorité d’affichage doit être :

1. photo base64 locale ;
2. photo URL ;
3. initiales du patient.

Ne jamais planter si la photo est absente, corrompue ou inaccessible.

---

# INTÉGRATION DANS L’APPLICATION EXISTANTE

## Routes à ajouter ou vérifier

Ajouter ou vérifier les routes suivantes :

```text
/patient/subscription
/patient/cmu
/patient/my-card
/cmu
```

Chaque route doit être protégée par l’authentification patient.

Depuis `PatientHomeScreen`, ajouter les accès directs suivants :

- une carte ou un bouton `Mon abonnement` ouvrant `/patient/subscription` ;
- une carte ou un bouton `Ma Carte CMU` ouvrant `/patient/cmu`.

Depuis le profil patient, ajouter également ces deux entrées si elles n’existent pas déjà.

## Providers à enregistrer

Enregistrer les providers dans l’arbre de l’application :

```text
AuthProvider
CmuProvider
PatientSubscriptionProvider
```

Lorsqu’un patient se connecte :

1. initialiser l’abonnement avec l’utilisateur courant ;
2. initialiser la carte CMU avec le même utilisateur ;
3. notifier les écrans ;
4. afficher les données sans redémarrage manuel.

Lors de la déconnexion :

1. réinitialiser `CmuProvider` ;
2. réinitialiser l’abonnement courant ;
3. supprimer les données privées en mémoire ;
4. empêcher l’accès par retour arrière.

## Compatibilité avec mon projet

Avant d’écrire du code :

- identifier le modèle utilisateur existant ;
- identifier le rôle patient existant ;
- identifier le système de routes ;
- identifier le thème et les couleurs déjà utilisés ;
- identifier les services de stockage ;
- identifier les providers déjà enregistrés ;
- identifier les composants d’avatar et de notification ;
- réutiliser les dépendances déjà présentes dans `pubspec.yaml`.

Ne pas ajouter une dépendance si une solution existante est déjà disponible dans mon projet. Ne pas renommer les classes existantes sans raison. Si un modèle existe déjà, l’étendre proprement au lieu de créer un doublon incompatible.

## Gestion des erreurs obligatoire

Tous les écrans doivent gérer :

- patient non connecté ;
- utilisateur non patient ;
- carte absente ;
- données d’abonnement absentes ;
- erreur de stockage ;
- erreur de paiement ;
- erreur de chargement ;
- liste vide ;
- photo absente ;
- QR code impossible à générer ;
- opération asynchrone terminée après fermeture de l’écran.

Après chaque `await`, vérifier que le widget est encore monté avant d’utiliser `context`, `Navigator`, `setState` ou `ScaffoldMessenger`.

Aucune erreur ne doit produire une page blanche. Afficher un composant avec :

- un message clair en français ;
- un bouton `Réessayer` ;
- un bouton retour lorsque nécessaire.

## Tests obligatoires

Créer des tests unitaires pour :

- les quatre plans ;
- les prix mensuels et annuels ;
- le formatage FCFA ;
- les dates de début et de fin ;
- l’expiration d’un abonnement ;
- l’ajout et la suppression d’un membre famille ;
- la limite de six membres ;
- la conversion JSON de l’abonnement ;
- la création d’une carte CMU depuis un utilisateur ;
- le calcul de l’expiration CMU après deux ans ;
- le masquage et l’affichage du numéro CMU ;
- le calcul des économies ;
- les statuts des constantes de santé ;
- les statuts des demandes CMU.

Créer des tests widget pour vérifier que les écrans suivants s’affichent sans exception ni page blanche :

- `PatientSubscriptionScreen` avec le Plan Gratuit ;
- `PatientSubscriptionScreen` avec le Plan Famille ;
- checkout d’un plan payant ;
- dialogue de retour au Plan Gratuit ;
- ajout d’un membre famille ;
- `CmuScreen` avec une carte ;
- `CmuScreen` sans carte ;
- onglet Économies ;
- onglet Santé ;
- onglet Couverture ;
- dialogue QR Code ;
- bottom sheet de partage.

Tester également :

- ouverture depuis le tableau de bord patient ;
- ouverture depuis le profil patient ;
- retour arrière ;
- changement d’onglet CMU ;
- changement Mensuel / Annuel ;
- abonnement sauvegardé après redémarrage ;
- carte reconstruite après reconnexion ;
- nettoyage après déconnexion.

## Critères d’acceptation

Le travail est terminé uniquement si :

1. l’écran d’abonnement ressemble à l’écran de référence ;
2. les quatre plans et leurs prix exacts sont présents ;
3. les cycles Mensuel et Annuel recalculent les prix ;
4. la bannière du plan actuel est correcte ;
5. le checkout est fonctionnel ou relié à un service de paiement clairement séparé ;
6. le retour au Plan Gratuit demande confirmation ;
7. le Plan Famille gère jusqu’à six membres ;
8. les membres famille sont sauvegardés par patient ;
9. l’écran CMU contient les quatre onglets exacts ;
10. la carte CMU est construite à partir de l’utilisateur connecté ;
11. le numéro CMU peut être masqué et affiché ;
12. les boutons Télécharger, Partager et QR Code donnent un retour fonctionnel ;
13. les économies utilisent les montants exacts ;
14. les constantes de santé affichent les valeurs et statuts attendus ;
15. les prestations de couverture affichent les taux et plafonds exacts ;
16. les demandes CMU affichent leurs statuts en français ;
17. les données privées sont isolées par patient ;
18. la déconnexion nettoie les données privées ;
19. aucun écran ne devient blanc en cas d’erreur ;
20. les tests ciblés passent ;
21. `dart format` ne remonte pas de problème ;
22. `flutter analyze` ne remonte aucune erreur bloquante.

## Commandes de validation

Après implémentation, exécuter :

```bash
dart format lib/
flutter analyze
flutter test
```

Puis exécuter au minimum les tests ciblés abonnement et CMU :

```bash
flutter test test/patient_subscription_test.dart
flutter test test/cmu_test.dart
flutter test test/patient_home_screen_test.dart
```

Si les fichiers de test n’existent pas, les créer. Fournir à la fin un résumé des fichiers modifiés, des routes ajoutées, des tests exécutés et des éventuelles dépendances backend restantes.

## Consigne finale

Implémenter exactement cette fonctionnalité dans mon application existante. Ne pas seulement créer des maquettes. Les boutons, les sélections, les dialogues, les sauvegardes, les changements d’onglets, les données du patient, la carte CMU et l’abonnement doivent fonctionner. Conserver les mêmes noms de plans, prix, avantages, onglets, textes et règles métier. Toute différence nécessaire due à l’architecture de mon application doit être signalée à la fin.
