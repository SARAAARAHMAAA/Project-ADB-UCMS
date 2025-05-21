-- ================================
-- 1. INSÉRER UN PROFESSEUR
-- ================================
INSERT INTO Professor VALUES (
  ProfessorType(
    1,
    'Dr. Nadia Bensalem',
    'nadia.bensalem@univ.dz',
    AddressType('Rue des Sciences', 'Alger', '16000'),
    PhoneList('0550123456', '0770123456', '023456789'),
    NULL -- le département sera ajouté après
  )
);

-- ================================
-- 2. INSÉRER UN DÉPARTEMENT
-- ================================
INSERT INTO Department VALUES (
  DepartmentType(
    10,
    'Informatique',
    (SELECT REF(p) FROM Professor p WHERE p.prof_id = 1)
  )
);

-- ================================
-- 3. METTRE À JOUR LE PROFESSEUR AVEC LE DÉPARTEMENT
-- ================================
UPDATE Professor p
SET p.department = (SELECT REF(d) FROM Department d WHERE d.dept_id = 10)
WHERE p.prof_id = 1;

-- ================================
-- 4. INSCRIRE UN ÉTUDIANT VIA LA PROCÉDURE
-- ================================
BEGIN
  enregistrer_etudiant(
    1001,
    'Amine Rezig',
    'amine.rezig@etu.univ.dz',
    TO_DATE('2002-06-15', 'YYYY-MM-DD'),
    'Cité 200 logements',
    'Annaba',
    '23000',
    10
  );
END;
/

-- ================================
-- 5. INSÉRER UNE SALLE
-- ================================
INSERT INTO Classroom VALUES (
  ClassroomType('B204', 40)
);

-- ================================
-- 6. INSÉRER UN CRÉNEAU HORAIRE
-- ================================
INSERT INTO TimeSlot VALUES (
  TimeSlotType(2, 'Wednesday', TO_TIMESTAMP('10:00', 'HH24:MI'), TO_TIMESTAMP('12:00', 'HH24:MI'))
);

-- ================================
-- 7. CRÉER UN COURS
-- ================================
BEGIN
  creer_cours(
    501,
    'Bases de Données Avancées',
    4,
    10, -- dept_id
    1,  -- prof_id
    'B204',
    2   -- timeslot_id
  );
END;
/

-- ================================
-- 8. INSCRIRE L'ÉTUDIANT AU COURS
-- ================================
BEGIN
  inscrire_etudiant(1001, 501);
END;
/

-- ================================
-- 9. AJOUTER UN ASSIGNMENT
-- ================================
BEGIN
  creer_assignment(
    301,
    'TP SQL ORDBMS',
    'Créer une base de données orientée objet relationnelle.',
    TO_DATE('2025-06-01', 'YYYY-MM-DD'),
    501
  );
END;
/

-- ================================
-- 10. ATTRIBUER UNE NOTE
-- ================================
BEGIN
  attribuer_note(1001, 301, 18);
END;
/

-- ================================
-- 11. AFFICHER L'ÂGE DE L'ÉTUDIANT
-- ================================
DECLARE
  s StudentType;
BEGIN
  SELECT VALUE(st) INTO s FROM Student st WHERE st.student_id = 1001;
  DBMS_OUTPUT.PUT_LINE('Âge étudiant : ' || s.getAge);
END;
/

-- ================================
-- 12. AFFICHER LE NOMBRE DE TÉLÉPHONES DU PROFESSEUR
-- ================================
DECLARE
  p ProfessorType;
BEGIN
  SELECT VALUE(pr) INTO p FROM Professor pr WHERE pr.prof_id = 1;
  DBMS_OUTPUT.PUT_LINE('Nombre de téléphones : ' || p.getPhoneCount);
END;
/

-- ================================
-- 13. DÉTAILS DU COURS + NB DE DEVOIRS
-- ================================
DECLARE
  c CourseType;
BEGIN
  SELECT VALUE(co) INTO c FROM Course co WHERE co.course_id = 501;
  DBMS_OUTPUT.PUT_LINE(c.getCourseDetails);
  DBMS_OUTPUT.PUT_LINE('Nombre de devoirs : ' || c.getAssignmentCount);
END;
/

-- ================================
-- 14. AFFICHER LE CONTENU DES VUES
-- ================================
-- Étudiant et ses cours
SELECT * FROM v_students_with_courses;

-- Bulletin détaillé
SELECT * FROM v_student_transcript;

-- Planning hebdomadaire
SELECT * FROM v_weekly_schedule;

-- Nombre total d'étudiants par cours
SELECT * FROM v_total_students_per_course;

-- Étudiants sans notes
SELECT * FROM v_students_without_assignments;

-- Meilleur étudiant
SELECT * FROM v_top_student;

-- Moyenne par cours
SELECT * FROM v_average_grade_per_course;