# 🎓 University Course Management System (UCMS)

## 📘 Description

Ce projet implémente un **système de gestion des cours universitaires** (UCMS) à l’aide d’un **SGBD Oracle SQL3**, en exploitant des **fonctionnalités avancées object-relationnelles** : types objets, types REF, tables imbriquées, vues, triggers, méthodes, procédures, etc.

Le système permet de gérer :
- Étudiants
- Professeurs
- Départements
- Cours
- Inscriptions
- Salles de cours
- Devoirs
- Notes

---

## 📁 Structure du dépôt

UCMS/
├── typesandtables.sql : contient la creation de tout les types et toutes les tables
│
├── methodes.sql
│
├── procedures.sql
│
├── rules.sql : triggers
│
├── views.sql
│
├── tests....sql: il  a un fichier test pour chaque parie 
│
├── final_document:
│ ├── final_document_declaration.sql
│ ├── final_document_tests.sql
│ └── final_document.sql
│
└── README.md

---

## ▶️ Exécution

### 📌 Fichier principal à exécuter :

**`final_document/final_document.sql`**

Ce fichier est le **script central**. Il regroupe toutes les étapes nécessaires pour exécuter le projet :
- Création des types, tables, vues, triggers, et procédures
- Insertion de données d'exemple
- Tests automatiques

> 🔧 Vous pouvez **modifier ce fichier** pour ajouter d'autres scénarios de test si nécessaire.

---

## ✅ Fonctionnalités prises en charge

- Détection des conflits horaires de cours dans une même salle
- Validation de la capacité des salles de classe
- Interdiction de suppression d’un cours avec des étudiants inscrits
- Inscription unique d’un étudiant à un cours (enforcement via trigger)
- Affectation d’un chef de département unique (1 seul chef par département)
- Assignation des devoirs par cours, notés par les professeurs
- Vues dynamiques pour : bulletins, emplois du temps, statistiques, etc.
- Moyenne des notes, étudiants non soumis, top étudiant, etc.
- Utilisation de types objets, REF, TABLE() pour manipulations avancées

---

## 🧪 Jeux de tests

Des tests unitaires sont fournis dans :
- les fichiers tests pour chaque section pour les données, triggers, vues, procédures
- `final_document_tests.sql` pour un regroupement simplifié

---

## 📜 Livrables

| Fichier | Description |
|--------|-------------|
| `typesandtables/*.sql` | Création des types objets et tables relationnelles |
| `methodes/*.sql` | Méthodes objets |
| `procedures/*.sql` | les procedures |
| `rules/*.sql` | Déclencheurs (triggers) liés aux règles métiers |
| `views/*.sql` | Vues pour accès facilité aux données |
| `test.../*.sql` | Données d'exemple et scénarios de test pour chaque partie|
| `final_document/*.sql` | Scripts de déploiement final, à exécuter dans l'ordre |
| `README.md` | Documentation du projet |

---

## 🏫 Informations sur le projet

- 🎓 Université : USTHB – Faculté d’Informatique
- 🧑‍🎓 Étudiantes:
       -Sadaoui Sara Rahma
       -Dahmani Naila
       -Chetouh Amira
- 📅 Année : 2024/2025
- 📚 Module : Base de Données Avancée (SQL3)
- 👨‍🏫 Encadrant : *[Nom de l’enseignant]*

---

## 🛠️ Prérequis techniques

- Oracle SQL (avec support Oracle Object-Relational SQL)
- Outils recommandés : SQL*Plus, Oracle SQL Developer, ou équivalent

---

## 📝 Remarques

- Le projet respecte les contraintes métier spécifiées dans le cahier des charges.
- Le code est commenté et modulaire pour faciliter la compréhension.
- L’exécution complète peut être faite via le fichier :  
  👉 **`final_document.sql`**

---
