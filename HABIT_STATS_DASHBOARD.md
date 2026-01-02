# Dashboard Statistiques par Habitude 📊

## Vue d'ensemble

Chaque habitude dispose maintenant de son propre dashboard de statistiques détaillé avec plusieurs visualisations et métriques.

## Accès aux Statistiques

### Méthode 1 : Depuis la carte d'habitude
- Dans la vue "Habits", cliquez sur l'icône **📊** (bar_chart) en haut à droite de chaque carte d'habitude

### Méthode 2 : Depuis les détails de l'habitude
- Ouvrez les détails d'une habitude
- Cliquez sur l'icône **📊** dans la barre d'application

## Métriques Affichées

### 🔥 Cartes de Statistiques (en haut)

1. **Current Streak** (Série Actuelle)
   - Nombre de jours consécutifs où l'habitude a été complétée
   - Icône : Flamme 🔥
   - Couleur : Orange

2. **Total Days** (Jours Totaux)
   - Nombre total de jours où l'habitude a été complétée
   - Icône : Check Circle ✅
   - Couleur : Vert

3. **Best Streak** (Meilleure Série)
   - La plus longue série de jours consécutifs jamais atteinte
   - Icône : Trophée 🏆
   - Couleur : Ambre

4. **Success Rate** (Taux de Réussite)
   - Pourcentage de jours complétés depuis la création
   - Formule : `(Jours complétés / Jours depuis création) × 100`
   - Icône : Tendance 📈
   - Couleur : Bleu

---

## 📊 Visualisations

### 1. Monthly Progress (Progression Mensuelle)
**Type :** Graphique en barres

**Description :**
- Affiche les 30 derniers jours
- Chaque barre représente un jour
- Barre colorée = habitude complétée
- Barre grise = habitude non complétée

**Utilisation :**
- Visualiser rapidement les tendances du dernier mois
- Identifier les périodes de forte/faible activité
- Les numéros en bas indiquent les jours (1, 6, 11, 16, 21, 26)

---

### 2. Weekly Pattern (Modèle Hebdomadaire)
**Type :** Heatmap horizontale

**Description :**
- Analyse par jour de la semaine (Lun-Dim)
- Barre de progression pour chaque jour
- Pourcentage de réussite affiché

**Calcul :**
```
Taux de réussite = (Nombre de fois complété ce jour / Nombre total de ce jour depuis création) × 100
```

**Exemple :**
- Si vous avez créé l'habitude il y a 4 semaines
- Il y a eu 4 lundis
- Vous avez complété l'habitude 3 lundis sur 4
- Taux de réussite du lundi = 75%

**Utilisation :**
- Identifier vos jours les plus/moins productifs
- Adapter votre planning en fonction
- Exemple : Si le dimanche est à 30%, planifier des rappels supplémentaires

---

### 3. Last 30 Days (Calendrier des 30 Derniers Jours)
**Type :** Grille calendrier

**Description :**
- Grille 7×5 montrant les 30 derniers jours
- Cases colorées = jours complétés
- Cases grises = jours non complétés
- Numéro du jour affiché dans chaque case

**Interaction :**
- Survolez une case pour voir la date exacte (format : "Jan 1")

**Utilisation :**
- Vue d'ensemble rapide du mois
- Repérer visuellement les patterns
- Contribution graph style GitHub

---

## 🧮 Algorithmes de Calcul

### Best Streak (Meilleure Série)
```dart
1. Trier toutes les dates de complétion
2. Parcourir les dates séquentiellement
3. Si deux dates sont consécutives (différence = 1 jour)
   → Incrémenter le compteur de série
4. Sinon, réinitialiser le compteur
5. Garder le maximum trouvé
```

### Success Rate (Taux de Réussite)
```dart
1. Calculer les jours depuis la création de l'habitude
2. Compter le nombre de jours complétés
3. Taux = (jours complétés / jours totaux) × 100
4. Limiter entre 0% et 100%
```

### Weekly Pattern (Modèle Hebdomadaire)
```dart
Pour chaque jour de la semaine (Lun-Dim):
  1. Compter combien de fois ce jour est apparu depuis la création
  2. Compter combien de fois l'habitude a été complétée ce jour
  3. Calculer le pourcentage
```

---

## 🎨 Design & UX

### Couleurs
- **Complété :** Couleur secondaire du thème (généralement jaune/vert)
- **Non complété :** Gris transparent (20% opacity)
- **Icônes :** Couleurs thématiques (orange pour streak, vert pour total, etc.)

### Responsive
- Cartes de stats : 2 colonnes sur mobile
- Graphiques : Largeur pleine avec padding
- Grille calendrier : 7 colonnes fixes

### Animations
- Aucune animation pour l'instant (peut être ajouté)
- Transitions de navigation standard

---

## 💡 Cas d'Usage

### 1. Analyser sa Régularité
**Objectif :** Comprendre si je suis régulier dans mon habitude

**Étapes :**
1. Ouvrir les stats de l'habitude
2. Regarder le "Success Rate"
   - \> 80% = Excellent
   - 60-80% = Bon
   - < 60% = À améliorer
3. Consulter le "Weekly Pattern" pour voir les jours faibles

### 2. Battre son Record
**Objectif :** Dépasser ma meilleure série

**Étapes :**
1. Noter le "Best Streak" actuel
2. Comparer avec "Current Streak"
3. Si proche, rester motivé pour battre le record
4. Utiliser le graphique mensuel pour voir la progression

### 3. Identifier les Patterns
**Objectif :** Comprendre quand je suis le plus productif

**Étapes :**
1. Consulter le "Weekly Pattern"
2. Identifier les jours à > 70%
3. Planifier les tâches importantes ces jours-là
4. Renforcer les jours faibles avec des rappels

---

## 🔧 Fichiers Techniques

### Fichier Principal
`lib/screens/habit_stats_screen.dart`

### Dépendances Utilisées
- `fl_chart` : Pour les graphiques (BarChart)
- `intl` : Pour le formatage des dates
- `flutter/material.dart` : UI components

### Widgets Personnalisés
- `_buildStatCard()` : Cartes de métriques
- `_buildMonthlyChart()` : Graphique en barres
- `_buildWeeklyHeatmap()` : Heatmap hebdomadaire
- `_buildCompletionHistory()` : Grille calendrier

---

## 🚀 Améliorations Futures Possibles

### Fonctionnalités
- [ ] Export des statistiques en PDF/Image
- [ ] Comparaison entre plusieurs habitudes
- [ ] Graphique de tendance (ligne de régression)
- [ ] Prédiction de la prochaine série
- [ ] Notifications de records battus
- [ ] Vue annuelle (heatmap 365 jours)

### Analytics Avancés
- [ ] Temps moyen de complétion
- [ ] Corrélations entre habitudes
- [ ] Score de difficulté basé sur les données
- [ ] Suggestions d'amélioration IA

### Gamification
- [ ] Badges pour les milestones (7, 30, 100 jours)
- [ ] Classement des habitudes par performance
- [ ] Défis hebdomadaires

---

## 📱 Captures d'Écran Attendues

### Vue Principale
```
┌─────────────────────────────────┐
│ ← Statistics              📊    │
├─────────────────────────────────┤
│ Morning Run                     │
│ [Health]                        │
│                                 │
│ ┌──────────┐  ┌──────────┐     │
│ │🔥 7 days │  │✅ 45     │     │
│ │Current   │  │Total Days│     │
│ └──────────┘  └──────────┘     │
│                                 │
│ ┌──────────┐  ┌──────────┐     │
│ │🏆 12 days│  │📈 78%    │     │
│ │Best      │  │Success   │     │
│ └──────────┘  └──────────┘     │
│                                 │
│ Monthly Progress                │
│ [Graphique en barres]           │
│                                 │
│ Weekly Pattern                  │
│ Mon ████████░░ 80%              │
│ Tue ██████░░░░ 60%              │
│ ...                             │
│                                 │
│ Last 30 Days                    │
│ [Grille 7x5]                    │
└─────────────────────────────────┘
```

---

## ✅ Checklist de Test

- [ ] Ouvrir les stats depuis la carte d'habitude
- [ ] Ouvrir les stats depuis les détails
- [ ] Vérifier que les 4 métriques s'affichent
- [ ] Vérifier le graphique mensuel (30 barres)
- [ ] Vérifier le heatmap hebdomadaire (7 jours)
- [ ] Vérifier la grille calendrier (30 cases)
- [ ] Tester avec une habitude sans données
- [ ] Tester avec une habitude avec beaucoup de données
- [ ] Vérifier les calculs de streak
- [ ] Vérifier le success rate
- [ ] Tester le scroll sur petits écrans

---

**Créé le :** 2026-01-01  
**Version :** 1.0  
**Statut :** ✅ Implémenté et fonctionnel
