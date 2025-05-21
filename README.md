# Project-ADB-UCMS
University Course Management System (UCMS)
📘 Description
Ce projet implémente un système de gestion des cours universitaires (UCMS) à l’aide d’un SGBD Oracle SQL3 en exploitant des fonctionnalités avancées object-relationnelles : types objets, types REF, tables imbriquées, vues, triggers, méthodes, procédures, etc.

Le système permet de gérer efficacement :

Étudiants

Professeurs

Départements

Cours

Inscriptions

Salles de cours

Devoirs

Notes

📂 Structure du dépôt
pgsql
Copier
Modifier
UCMS/
├── types_et_tables/
│   ├── create_object_types.sql
│   ├── create_tables.sql
│   └── create_relationships.sql
│
├── methodes_procedures/
│   ├── course_methods.sql
│   └── procedures_utilitaires.sql
│
├── triggers/
│   ├── trigger_no_duplicate_enrollments.sql
│   ├── trigger_course_deletion_protection.sql
│   ├── trigger_classroom_capacity_check.sql
│   └── trigger_time_conflict_check.sql
│
├── views/
│   ├── view_enrolled_students.sql
│   ├── view_transcript.sql
│   ├── view_weekly_schedule.sql
│   ├── view_course_student_counts.sql
│   ├── view_students_no_submissions.sql
│   ├── view_top_student.sql
│   └── view_average_grades.sql
│
├── tests/
│   ├── insert_sample_data.sql
│   ├── test_triggers.sql
│   ├── test_views.sql
│   └── test_procedures.sql
│
├── final_document/
│   ├── final_document_declaration.sql
│   ├── final_document_tests.sql
│   └── final_document.sql
│
└── README.md
▶️ Exécution
📌 Fichier principal à exécuter :
final_document/final_document.sql

Ce fichier regroupe toutes les étapes d’installation et de test pour dérouler entièrement le projet :

Création des types, tables, vues, triggers et procédures.

Insertion de données d'exemple.

Tests de validation.

⚠️ Ce fichier contient aussi quelques cas de test par défaut. Vous pouvez le modifier pour ajouter vos propres scénarios de test.

✅ Fonctionnalités principales
Détection des conflits d’horaire entre cours dans une même salle.

Validation de capacité des salles de classe.

Protection contre la suppression de cours avec des étudiants inscrits.

Gestion des notes et des devoirs par étudiant et par cours.

Vues dynamiques pour les transcriptions, les emplois du temps, les statistiques de cours, etc.

Utilisation de REF, TABLE() et méthodes d’objet pour les requêtes avancées.

📜 Liste des livrables
Fichier	Description
types_et_tables/*.sql	Création des types objets et tables relationnelles
methodes_procedures/*.sql	Définition de méthodes et procédures liées aux objets
triggers/*.sql	Triggers pour les règles métier et contraintes
views/*.sql	Création des vues demandées
tests/*.sql	Insertion de données d'exemple et jeux de tests
final_document_declaration.sql	Déclarations globales
final_document_tests.sql	Tests regroupés
final_document.sql	Script principal à exécuter

🔎 Auteurs
Étudiantes :
  -Sadaoui Sara Rahma
  -Dahmani Naila 
  -Chetouh Amira

Année : 2024/2025

Université : USTHB

Module : Base de Données Avancée (SQL3)

🛠️ Prérequis
Oracle SQL (version avec support des objets)

SQL*Plus, SQL Developer, ou tout autre outil Oracle compatible
