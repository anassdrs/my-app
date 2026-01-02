# 🎯 Flutter Todo & Habit Tracker App

Une application Flutter complète de gestion de tâches et de suivi d'habitudes avec gamification, notifications intelligentes et analytics avancés.

![Flutter](https://img.shields.io/badge/Flutter-3.11.0-blue)
![Dart](https://img.shields.io/badge/Dart-3.11.0-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Fonctionnalités

### 🎮 Gamification
- **Système XP & Niveaux** : Gagnez 10 XP par habitude complétée
- **Level-up automatique** : Progression basée sur l'expérience
- **Affichage en temps réel** : Niveau et XP visibles sur le dashboard
- **Feedback visuel** : Notifications de récompense

### 🔔 Notifications Intelligentes
- **Rappels quotidiens** : Notifications programmées pour chaque habitude
- **Support timezone** : Gestion précise des fuseaux horaires
- **Permissions automatiques** : Configuration iOS/Android simplifiée
- **Répétition quotidienne** : Rappels récurrents

### 📊 Analytics & Statistiques

#### Dashboard Principal
- Graphique de productivité (7 derniers jours)
- Statistiques des tâches et habitudes
- Affichage du niveau utilisateur

#### Dashboard par Habitude
- **4 Métriques clés** :
  - 🔥 Série actuelle (Current Streak)
  - ✅ Total de jours complétés
  - 🏆 Meilleure série (Best Streak)
  - 📈 Taux de réussite (Success Rate)

- **3 Visualisations** :
  - Graphique mensuel (30 jours)
  - Heatmap hebdomadaire
  - Grille calendrier (30 jours)

### ⚡ Gestion des Habitudes
- Création et édition d'habitudes
- Système de catégories
- Calendrier de complétion
- Suivi des streaks
- Historique détaillé

### ✅ Gestion des Tâches
- Création de todos avec dates
- Marquage de complétion
- Organisation par date
- Interface intuitive

## 🚀 Installation

### Prérequis
- Flutter SDK 3.11.0 ou supérieur
- Dart 3.11.0 ou supérieur
- Android Studio / Xcode (pour émulateurs)

### Étapes

1. **Cloner le repository**
```bash
git clone <votre-repo-url>
cd flutter_todo_habit_app
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Générer les adaptateurs Hive**
```bash
dart run build_runner build --delete-conflicting-outputs
```

4. **Lancer l'application**
```bash
flutter run
```

## 📦 Dépendances Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.5+1
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  fl_chart: ^1.1.1
  google_fonts: ^6.3.3
  flutter_local_notifications: ^19.5.0
  timezone: ^0.10.1
  table_calendar: ^3.2.0
  intl: ^0.20.2
  uuid: ^4.5.2
  font_awesome_flutter: ^10.12.0
  flutter_slidable: ^4.0.3
```

## 🏗️ Architecture

### Structure du Projet
```
lib/
├── models/           # Modèles de données (Hive)
│   ├── todo.dart
│   ├── habit.dart
│   └── user_model.dart
├── providers/        # State management (Provider)
│   ├── todo_provider.dart
│   ├── habit_provider.dart
│   ├── auth_provider.dart
│   └── theme_provider.dart
├── screens/          # Écrans de l'application
│   ├── home_screen.dart
│   ├── dashboard_view.dart
│   ├── habit_view.dart
│   ├── habit_stats_screen.dart
│   └── ...
├── services/         # Services (Notifications, etc.)
│   └── notification_service.dart
├── utils/            # Utilitaires et constantes
│   ├── constants.dart
│   └── boxes.dart
└── widgets/          # Widgets réutilisables
    └── stat_card.dart
```

### Base de Données
- **Hive** : Base de données NoSQL locale
- **Boxes** :
  - `todos_box` : Stockage des tâches
  - `habits_box` : Stockage des habitudes
  - `user_box` : Données d'authentification
  - `user_profiles_box` : Profils utilisateurs (XP, niveaux)

## 📱 Utilisation

### Créer une Habitude
1. Aller dans l'onglet "Habits"
2. Appuyer sur le bouton "+"
3. Remplir le nom, description et heure
4. Sauvegarder

### Voir les Statistiques
1. Cliquer sur l'icône 📊 sur une carte d'habitude
2. Ou ouvrir les détails → Cliquer sur 📊 en haut
3. Explorer les métriques et graphiques

### Gagner de l'XP
1. Compléter une habitude
2. Recevoir +10 XP
3. Vérifier le niveau sur le dashboard

## 🎨 Thèmes

L'application supporte les thèmes clair et sombre :
- Changement automatique selon les préférences système
- Toggle manuel dans les paramètres
- Couleurs cohérentes et modernes

## 📊 Métriques Calculées

### Success Rate
```dart
Success Rate = (Jours complétés / Jours depuis création) × 100
```

### Best Streak
Algorithme de recherche de la plus longue série consécutive dans l'historique.

### Weekly Pattern
```dart
Pourcentage par jour = (Complétions ce jour / Total de ce jour) × 100
```

## 🔧 Configuration

### Notifications Android
Les permissions sont déjà configurées dans `AndroidManifest.xml` :
- `RECEIVE_BOOT_COMPLETED`
- `VIBRATE`
- `SCHEDULE_EXACT_ALARM`
- `POST_NOTIFICATIONS`

### Notifications iOS
Permissions demandées automatiquement au premier lancement.

## 📚 Documentation

- **[IMPROVEMENTS.md](IMPROVEMENTS.md)** - Liste complète des améliorations
- **[QUICK_START.md](QUICK_START.md)** - Guide de démarrage rapide
- **[HABIT_STATS_DASHBOARD.md](HABIT_STATS_DASHBOARD.md)** - Guide du dashboard statistiques
- **[RECAP_FINAL.md](RECAP_FINAL.md)** - Récapitulatif complet

## 🧪 Tests

```bash
# Analyser le code
flutter analyze

# Lancer les tests
flutter test

# Générer un build de production
flutter build apk  # Android
flutter build ios  # iOS
```

## 🐛 Problèmes Connus

- Avertissements de dépréciation `withOpacity` (non bloquants)
- Cloud sync non implémenté (local uniquement)
- Système de badges défini mais non attribué automatiquement

## 🔮 Roadmap

### Version 1.1
- [ ] Corriger les avertissements de dépréciation
- [ ] Animations pour les graphiques
- [ ] Système de badges automatique
- [ ] Catégories personnalisées

### Version 2.0
- [ ] Cloud sync (Firebase/Supabase)
- [ ] Vue annuelle (365 jours)
- [ ] Export PDF des statistiques
- [ ] Système de défis

### Version 3.0
- [ ] Analytics IA avec suggestions
- [ ] Partage social
- [ ] Mode collaboratif
- [ ] Widget écran d'accueil

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 License

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 👨‍💻 Auteur

**Amine**

## 🙏 Remerciements

- Flutter Team pour le framework
- Communauté Flutter pour les packages
- Tous les contributeurs

---

**Fait avec ❤️ et Flutter**

*Dernière mise à jour : 2026-01-01*
