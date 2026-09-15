# Prompt complet — Partie Administrateur de l’application My Doctor

## Contexte

Construire et intégrer la **partie administrateur complète** de l’application Flutter **My Doctor**. Cette partie doit fournir une console sécurisée permettant à l’administration de superviser les utilisateurs, les médecins, les patients, les cartes patient, les rendez-vous, les demandes de médecin traitant, les conversations, les retraits financiers et la configuration générale du système.

L’interface doit être en français, professionnelle, responsive et utilisable sur téléphone, tablette et ordinateur. Elle doit privilégier une navigation persistante par barre latérale sur grand écran et un menu sécurisé sur mobile. Aucun écran ne doit rester blanc en cas d’erreur ou de données absentes.

La partie administrateur doit être intégrée au projet existant sans casser les espaces patient et médecin. Avant toute modification, inspecter les routes, modèles, providers, services et données déjà présents afin de réutiliser le code existant.

## Objectifs principaux

L’administrateur doit pouvoir :

1. se connecter à un portail sécurisé ;
2. accéder à un tableau de bord global ;
3. consulter les indicateurs de la plateforme ;
4. gérer les comptes utilisateurs ;
5. valider, suspendre ou réactiver les médecins ;
6. consulter et gérer les patients ;
7. gérer les cartes d’identité patient et les cartes CMU ;
8. superviser les rendez-vous ;
9. traiter les demandes de médecin traitant ;
10. superviser les conversations et les quotas de messagerie ;
11. traiter les demandes de retrait des médecins ;
12. consulter les paramètres et les données de démonstration ;
13. se déconnecter en supprimant correctement la session administrative.

## Technologies et architecture

Utiliser Flutter et Dart 3 avec Material 3. Utiliser Provider pour la gestion d’état et Hive, SharedPreferences ou Supabase pour la persistance selon l’architecture existante. Utiliser `intl` pour les dates françaises et une bibliothèque d’icônes cohérente comme `flutter_lucide`.

Séparer clairement les responsabilités :

```text
lib/
  core/
    routing/
    theme/
    constants/
  models/
  providers/
  services/
  screens/
    admin/
      admin_dashboard_screen.dart
      components/
        admin_header.dart
        admin_sidebar.dart
        admin_kpi_card.dart
      views/
        admin_overview_view.dart
        admin_users_view.dart
        admin_doctors_view.dart
        admin_patients_view.dart
        admin_patient_cards_view.dart
        admin_appointments_view.dart
        admin_requests_view.dart
        admin_conversations_view.dart
        admin_withdrawals_view.dart
        admin_settings_view.dart
```

La logique métier ne doit pas être placée directement dans les widgets. Les vues doivent communiquer avec `DatabaseService`, `AuthProvider`, `MessageProvider`, `TreatingRequestProvider` et les autres providers existants.

## Identité visuelle

Créer une console d’administration avec une apparence sérieuse et médicale :

- bleu nuit ou bleu marine pour la sidebar ;
- bleu clair, turquoise et vert pour les états positifs ;
- orange pour les éléments en attente ;
- rouge ou corail pour les erreurs, suspensions et refus ;
- fond gris très clair pour la zone de travail ;
- cartes blanches avec coins arrondis et ombres légères ;
- titres lisibles, hiérarchie visuelle claire et espaces réguliers ;
- badges de statut toujours explicites ;
- boutons avec libellés en français ;
- interface accessible aux écrans étroits ;
- aucun débordement horizontal involontaire ;
- aucune page blanche en cas d’exception.

Prévoir des états de chargement, d’erreur, de données vides et de succès dans chaque vue.

## Sécurité et contrôle des rôles

L’accès à la console doit être strictement réservé aux utilisateurs dont le rôle est `admin`.

Implémenter une garde d’authentification qui vérifie :

- que l’utilisateur est authentifié ;
- que `currentUser.role == UserRole.admin` ;
- que le compte administratif est actif ;
- que les routes admin ne sont pas accessibles à un patient ou à un médecin ;
- qu’un utilisateur non connecté est redirigé vers l’écran de connexion ;
- qu’un utilisateur connecté avec un mauvais rôle est redirigé vers son espace correspondant ;
- qu’une session expirée ne donne pas accès aux données privées.

La déconnexion doit :

1. supprimer la session locale ;
2. effacer les routes et onglets admin persistés ;
3. supprimer ou invalider les données sensibles en mémoire ;
4. retourner vers l’écran de connexion ;
5. empêcher le retour arrière vers la console.

Ne jamais cacher uniquement les boutons côté interface. Les actions sensibles doivent également être protégées côté logique métier et service de données.

## Authentification administrateur

Créer un écran d’accès administrateur séparé ou un formulaire sécurisé dans le portail admin. Il doit contenir :

- identifiant, téléphone ou e-mail ;
- mot de passe ;
- bouton « Connexion administrateur » ;
- affichage ou masquage du mot de passe ;
- indicateur de chargement ;
- message d’erreur explicite ;
- bouton de retour à l’accueil ;
- redirection vers `/admin` après authentification réussie.

Ne jamais afficher ou révéler un mot de passe dans les logs. Les identifiants de démonstration doivent être utilisés uniquement dans un environnement de test clairement identifié.

## Tableau de bord administrateur

Créer `AdminDashboardScreen` comme conteneur principal de la console.

Sur grand écran :

- afficher une sidebar fixe ;
- afficher un header supérieur ;
- afficher la vue active dans une zone de contenu flexible ;
- permettre le redimensionnement sans overflow.

Sur mobile :

- afficher un bouton pour ouvrir un `Drawer` ;
- afficher une barre de navigation inférieure limitée aux sections principales ;
- afficher des onglets horizontaux défilants si nécessaire ;
- fermer le drawer après sélection ;
- conserver la vue sélectionnée après fermeture du drawer.

La navigation doit contenir les sections suivantes :

1. Vue d’ensemble ;
2. Cartes d’identité patient ;
3. Finances et retraits médecins ;
4. Gestion des médecins ;
5. Gestion des patients ;
6. Rendez-vous ;
7. Demandes médecin traitant ;
8. Conversations et audit ;
9. Configuration et paramètres.

La navigation doit utiliser des index valides, toujours compris entre 0 et le nombre d’onglets disponibles. Les valeurs restaurées depuis la persistance doivent être vérifiées et converties correctement en `int`.

## Header administrateur

Le header doit afficher :

- le titre de la vue active ;
- un sous-titre explicatif ;
- le nom de l’administrateur connecté ;
- un avatar ou ses initiales ;
- un indicateur de rôle « Administrateur » ;
- un bouton de rafraîchissement ;
- un bouton d’ouverture du menu sur mobile ;
- un accès à la déconnexion.

Le bouton de rafraîchissement doit recharger les données de la vue active sans recréer une route invalide ni provoquer une mise à jour après destruction du widget.

## Vue d’ensemble

Créer `AdminOverviewView` avec des indicateurs globaux :

- nombre total d’utilisateurs ;
- nombre de patients ;
- nombre total de médecins ;
- médecins actifs ;
- médecins en attente de validation ;
- cartes patient actives ;
- retraits en attente ;
- rendez-vous du système ;
- demandes médecin traitant en attente ;
- conversations ouvertes ;
- nombre total de messages ;
- patients ayant atteint leur quota de messages.

Chaque carte KPI doit être interactive et ouvrir la vue correspondante. Les indicateurs doivent afficher une valeur `0` et un état vide propre lorsque aucune donnée n’est disponible.

Ajouter une section d’alertes rapides :

- médecins en attente de validation ;
- cartes à vérifier ;
- retraits à traiter ;
- demandes non traitées ;
- erreurs de synchronisation éventuelles.

Les boutons « Voir », « Valider » ou « Traiter » doivent réellement naviguer vers la vue concernée.

## Gestion des médecins

Créer `AdminDoctorsView` avec :

- recherche par nom ;
- recherche par spécialité ;
- recherche par numéro d’ordre ;
- recherche par téléphone ;
- filtre « Tous » ;
- filtre « En attente » ;
- filtre « Validés » ;
- filtre « Suspendus » ;
- liste des médecins ;
- avatar ou initiales ;
- nom complet ;
- spécialité ;
- téléphone ;
- numéro d’ordre ;
- statut ;
- nombre de demandes reçues ;
- nombre de demandes acceptées ;
- date d’inscription.

Actions disponibles :

- consulter le profil ;
- valider un médecin en attente ;
- suspendre un médecin actif ;
- réactiver un médecin suspendu ;
- refuser une inscription ;
- consulter ses rendez-vous ;
- consulter ses retraits ;
- afficher une confirmation avant chaque action sensible.

Règles métier :

- un médecin en attente ne doit pas apparaître comme actif pour les patients ;
- une validation doit mettre à jour le statut persistant ;
- une suspension doit empêcher la connexion ou l’utilisation des fonctions protégées ;
- les listes doivent se rafraîchir après une action ;
- les actions doivent afficher un message de succès ou d’erreur.

## Gestion des patients

Créer `AdminPatientsView` avec :

- recherche par nom ;
- recherche par téléphone ;
- recherche par e-mail ;
- recherche par numéro CMU ;
- filtre actif, suspendu ou en attente ;
- fiche patient ;
- nombre de demandes médecin traitant ;
- quota de messages utilisé ;
- plan d’abonnement ;
- statut de carte ;
- date d’inscription.

Actions :

- consulter le profil ;
- consulter la carte patient ;
- suspendre le patient ;
- réactiver le patient ;
- réinitialiser le quota de messages si cette action est autorisée ;
- consulter ses rendez-vous ;
- consulter ses demandes ;
- ouvrir un dialogue de confirmation pour les actions sensibles.

Un patient suspendu ne doit plus pouvoir se connecter. Les changements de statut doivent être persistés et reflétés dans les autres vues.

## Gestion des utilisateurs

Créer `AdminUsersView` pour une vue globale de tous les comptes :

- patients ;
- médecins ;
- administrateurs ;
- comptes en attente ;
- comptes actifs ;
- comptes suspendus ;
- comptes refusés.

Ajouter des filtres par rôle et par statut. Afficher les informations essentielles sans exposer de données sensibles inutiles.

Actions possibles :

- consulter un compte ;
- modifier le statut selon les permissions ;
- réactiver un compte ;
- suspendre un compte ;
- afficher les informations de vérification ;
- empêcher la suspension du dernier compte administrateur sans confirmation renforcée.

Un compte administrateur ne doit pas être modifiable comme un patient ou un médecin sans règle spécifique.

## Cartes d’identité patient et CMU

Créer `AdminPatientCardsView` pour gérer les cartes patient :

- liste des cartes ;
- recherche par nom ou identifiant ;
- statut de carte ;
- numéro CMU ;
- date de création ;
- date de validation ;
- QR code ou identifiant de vérification ;
- informations manquantes.

Actions :

- consulter une carte ;
- valider une carte ;
- suspendre une carte ;
- réactiver une carte ;
- signaler des informations incomplètes ;
- vérifier la cohérence entre la carte et le compte patient.

Ne jamais afficher un QR code ou une donnée sensible d’un autre patient sans contrôle d’accès admin.

## Finances et retraits médecins

Créer `AdminWithdrawalsView` avec :

- liste des demandes de retrait ;
- médecin concerné ;
- téléphone ;
- montant brut ;
- commission ;
- montant net ;
- moyen de paiement ;
- date de demande ;
- statut en attente, approuvé, traité ou rejeté ;
- note administrative.

Ajouter les filtres :

- tous ;
- en attente ;
- approuvés ;
- traités ;
- rejetés.

Actions :

- consulter le détail ;
- approuver ;
- rejeter avec motif ;
- marquer comme traité ;
- ajouter une note ;
- afficher une confirmation avant validation.

Règles financières :

- calculer clairement commission et montant net ;
- ne jamais approuver deux fois le même retrait ;
- ne jamais marquer un paiement comme réalisé sans action confirmée ;
- désactiver les boutons pendant une opération ;
- afficher une erreur si la sauvegarde échoue ;
- conserver l’historique du changement de statut.

## Gestion des rendez-vous

Créer `AdminAppointmentsView` avec :

- tous les rendez-vous ;
- recherche par patient ou médecin ;
- filtre par date ;
- filtre par statut ;
- filtre présentiel ou téléconsultation ;
- date et heure ;
- patient ;
- médecin ;
- spécialité ;
- prix ;
- statut ;
- mode de consultation.

Actions :

- consulter le détail ;
- voir le profil patient ;
- voir le profil médecin ;
- annuler un rendez-vous avec motif ;
- filtrer les rendez-vous du jour ;
- afficher un état vide clair.

Les dates doivent être affichées en français et les rendez-vous doivent être triés de façon cohérente.

## Demandes de médecin traitant

Créer `AdminRequestsView` avec :

- toutes les demandes ;
- demandes en attente ;
- demandes acceptées ;
- demandes refusées ;
- demandes annulées ;
- patient ;
- médecin ;
- spécialité ;
- montant éventuel ;
- date de création ;
- date de mise à jour ;
- motif du refus.

Ajouter une recherche par patient, médecin ou spécialité et des filtres par statut.

L’administrateur doit pouvoir :

- consulter le détail d’une demande ;
- vérifier l’existence des deux comptes ;
- voir si une conversation a été créée ;
- suivre les demandes bloquées ;
- éventuellement annuler une demande avec confirmation si la règle métier l’autorise.

Les demandes doivent être mises à jour sans redémarrer l’application.

## Audit des conversations et quotas

Créer `AdminConversationsView` avec :

- conversations ouvertes ;
- patient ;
- médecin ;
- nombre de messages ;
- derniers échanges ;
- date du dernier message ;
- statut de la conversation ;
- quota patient utilisé ;
- quota restant ;
- indicateur de blocage.

L’administrateur doit pouvoir superviser les métriques et quotas sans modifier le contenu privé des messages de façon abusive. Toute action de réinitialisation de quota doit être confirmée et enregistrée.

Vérifier les règles suivantes :

- les messages du médecin ne consomment pas le quota patient ;
- un patient bloqué ne peut pas envoyer de nouveaux messages ;
- une conversation acceptée est liée au bon patient et au bon médecin ;
- les compteurs se recalculent après modification.

## Paramètres système

Créer `AdminSettingsView` avec :

- paramètres de quota gratuit ;
- nombre de messages autorisés ;
- commission de retrait ;
- activation ou désactivation de certaines fonctions ;
- configuration des notifications ;
- état des données de démonstration ;
- actions de réinitialisation contrôlées ;
- informations de version.

Pour les opérations dangereuses :

- afficher un avertissement explicite ;
- demander une confirmation ;
- désactiver le bouton pendant l’exécution ;
- afficher un résultat clair ;
- ne jamais supprimer des données réelles sans procédure protégée.

La régénération des données de démonstration doit être distincte des données réelles et clairement identifiée.

## Navigation et persistance des onglets

Prévoir les routes :

```text
/admin
/admin/overview
/admin/cards
/admin/patient-cards
/admin/withdrawals
/admin/doctors
/admin/patients
/admin/users
/admin/appointments
/admin/requests
/admin/conversations
/admin/audit
/admin/settings
```

Lorsqu’un onglet est sauvegardé, vérifier que sa valeur est comprise entre 0 et 8. Utiliser une conversion explicite en entier après `clamp`. Si la valeur est invalide, revenir à l’onglet 0.

Les clics de sidebar, les cartes KPI, les onglets mobiles, les boutons du drawer et les routes nommées doivent tous appeler la même méthode de navigation centrale afin d’éviter les incohérences.

Après sélection d’un item dans un drawer mobile :

1. changer l’onglet actif ;
2. sauvegarder l’onglet ;
3. fermer le drawer ;
4. afficher immédiatement la vue correspondante.

## Gestion des erreurs et page blanche

Chaque vue admin doit traiter :

- chargement ;
- données disponibles ;
- liste vide ;
- erreur de base de données ;
- erreur réseau ;
- session absente ;
- mauvais rôle ;
- action en cours ;
- action réussie ;
- action échouée ;
- widget démonté pendant une opération asynchrone ;
- écran étroit ;
- texte agrandi.

Ne pas masquer silencieusement les exceptions importantes avec un `ErrorWidget` vide. En cas d’erreur, afficher un écran de secours avec :

- une explication courte ;
- un bouton « Réessayer » ;
- un bouton « Retour au tableau de bord » ;
- un log développeur non sensible.

Utiliser `mounted` ou `context.mounted` après les opérations asynchrones avant d’appeler `setState`, `Navigator` ou `ScaffoldMessenger`.

## Tests obligatoires

Créer ou maintenir les tests suivants.

### Tests des rôles et de la sécurité

- un patient ne peut pas afficher `AdminDashboardScreen` ;
- un médecin ne peut pas afficher `AdminDashboardScreen` ;
- un administrateur actif peut accéder à la console ;
- un utilisateur non connecté voit l’écran d’accès ;
- la déconnexion admin supprime la session et bloque le retour arrière ;
- une route inconnue ne provoque pas d’écran blanc ;
- une valeur d’onglet invalide revient à l’onglet 0.

### Tests des données admin

- les données de démonstration créent plusieurs médecins ;
- les statuts actif, en attente et suspendu sont correctement calculés ;
- les patients sont correctement comptabilisés ;
- les demandes médecin traitant sont regroupées par statut ;
- les conversations et messages sont correctement comptés ;
- les retraits sont regroupés par statut ;
- la validation d’un médecin modifie réellement son statut ;
- la suspension d’un utilisateur est persistée ;
- la réinitialisation d’un quota met à jour la valeur.

### Tests widget

Vérifier que les écrans suivants se construisent sans exception ni page blanche :

- `AdminDashboardScreen` ;
- `AdminOverviewView` ;
- `AdminDoctorsView` ;
- `AdminPatientsView` ;
- `AdminUsersView` ;
- `AdminPatientCardsView` ;
- `AdminAppointmentsView` ;
- `AdminRequestsView` ;
- `AdminConversationsView` ;
- `AdminWithdrawalsView` ;
- `AdminSettingsView`.

Tester les interactions suivantes :

- clic sur chaque item de la sidebar ;
- clic sur chaque onglet mobile ;
- ouverture et fermeture du drawer ;
- clic sur les cartes KPI ;
- recherche ;
- filtres ;
- validation et suspension avec confirmation ;
- changement de statut d’un retrait ;
- rafraîchissement ;
- déconnexion.

## Critères d’acceptation finale

La partie administrateur est terminée uniquement si :

1. l’accès est réservé au rôle admin ;
2. un patient ou un médecin ne peut pas contourner la garde ;
3. la console s’affiche sans page blanche ;
4. la sidebar desktop fonctionne ;
5. le drawer mobile fonctionne ;
6. tous les onglets changent de vue ;
7. les routes admin sont cohérentes ;
8. la persistance d’onglet ne provoque pas d’index invalide ;
9. les KPI ouvrent les bonnes sections ;
10. les médecins peuvent être validés, suspendus et réactivés ;
11. les patients peuvent être recherchés et gérés ;
12. les cartes patient peuvent être supervisées ;
13. les rendez-vous sont consultables ;
14. les demandes médecin traitant sont filtrables ;
15. les conversations et quotas sont supervisables ;
16. les retraits sont traités avec confirmation et statut persistant ;
17. les paramètres système affichent des actions sécurisées ;
18. les listes vides et erreurs disposent d’un affichage utile ;
19. aucune action principale ne reste sans comportement ;
20. les tests admin dédiés passent ;
21. les opérations asynchrones ne déclenchent pas d’erreur après démontage ;
22. la déconnexion supprime réellement l’accès à la console.

## Consigne finale à l’agent développeur

Inspecter d’abord le projet existant. Ne pas réécrire inutilement les écrans déjà fonctionnels. Corriger prioritairement les erreurs de navigation, de contrôle de rôle, de rendu et de persistance. Après chaque modification, exécuter `dart format`, `flutter analyze` et les tests ciblés admin. Tester séparément les formats mobile et desktop. Ne jamais considérer un simple écran affiché comme suffisant : vérifier les clics, changements d’onglet, dialogues, sauvegardes, rafraîchissements, états vides et erreurs. Livrer une archive ou un projet final vérifié, avec un résumé des corrections effectuées et des éventuelles fonctionnalités encore dépendantes d’un backend réel.
