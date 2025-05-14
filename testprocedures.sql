SET SERVEROUTPUT ON;

-- Nettoyage préalable
BEGIN
  DELETE FROM Grade;
  DELETE FROM Assignment;
  DELETE FROM Enrollment;
  DELETE FROM Course;
  DELETE FROM Student;
  DELETE FROM Professor;
  DELETE FROM Department;
  DELETE FROM Classroom;
  DELETE FROM TimeSlot;
  COMMIT;
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Salle
INSERT INTO Classroom VALUES (
  ClassroomType('B101', 50)
);

-- Créneau horaire
INSERT INTO TimeSlot VALUES (
  TimeSlotType(1, 'Monday', TO_TIMESTAMP('08:00', 'HH24:MI'), TO_TIMESTAMP('10:00', 'HH24:MI'))
);

-- Professeur (doit être créé en premier pour qu’il puisse être chef de département)
INSERT INTO Professor VALUES (
  ProfessorType(
    201,
    'Dr. Lamiri',
    'lamiri@usthb.dz',
    NULL, -- address
    PhoneList('0555123456'),
    NULL  -- department (rempli après)
  )
);


-- Département (le chef doit déjà exister)
DECLARE
  v_prof REF ProfessorType;
  v_dept REF DepartmentType;
  v_prof_obj ProfessorType;
BEGIN
  -- Obtenir REF vers le professeur
  SELECT REF(p) INTO v_prof FROM Professor p WHERE p.prof_id = 201;

  -- Insérer le département avec ce professeur comme chef
  INSERT INTO Department VALUES (
    DepartmentType(
      1,
      'Informatique',
      v_prof
    )
  );

  -- Obtenir REF vers le département nouvellement inséré
  SELECT REF(d) INTO v_dept FROM Department d WHERE d.dept_id = 1;

  -- Récupérer l'objet professeur actuel
  SELECT VALUE(p) INTO v_prof_obj FROM Professor p WHERE p.prof_id = 201;

  -- Mettre à jour l’objet professeur avec le REF du département
  v_prof_obj.department := v_dept;

  -- Réécrire l’objet professeur dans la table
  UPDATE Professor p
  SET VALUE(p) = v_prof_obj
  WHERE p.prof_id = 201;
END;
/



-- Étudiant
BEGIN
  enregistrer_etudiant(
    p_student_id => 101,
    p_name       => 'Ali Meziane',
    p_email      => 'ali.meziane@etu.usthb.dz',
    p_dob        => TO_DATE('2000-01-01', 'YYYY-MM-DD'),
    p_street     => 'Rue 123',
    p_city       => 'Alger',
    p_zip        => '16000',
    p_dept_id    => 1
  );
END;
/

-- Cours
BEGIN
  creer_cours(
    p_course_id    => 1001,
    p_course_name  => 'Bases de Données Avancées',
    p_coefficient  => 4,
    p_dept_id      => 1,
    p_prof_id      => 201,
    p_room_number  => 'B101',
    p_timeslot_id  => 1
  );
END;
/

-- Inscription
BEGIN
  inscrire_etudiant(
    p_student_id => 101,
    p_course_id  => 1001
  );
END;
/

-- Assignment 1
BEGIN
  creer_assignment(
    p_assignment_id => 501,
    p_title         => 'TP Oracle',
    p_description   => 'Créer des procédures et des types',
    p_due_date      => TO_DATE('2025-06-01', 'YYYY-MM-DD'),
    p_course_id     => 1001
  );
END;
/

-- Assignment 2
BEGIN
  ajouter_assignment(
    p_course_id      => 1001,
    p_assignment_id  => 502,
    p_title          => 'Projet UCMS',
    p_description    => 'Projet final UCMS',
    p_due_date       => TO_DATE('2025-06-10', 'YYYY-MM-DD')
  );
END;
/

-- Note pour Assignment 1
BEGIN
  attribuer_note(
    p_student_id    => 101,
    p_assignment_id => 501,
    p_score         => 17
  );
END;
/

-- Note pour Assignment 2
BEGIN
  enregistrer_note_assignment(
    p_student_id    => 101,
    p_assignment_id => 502,
    p_score         => 18.5
  );
END;
/

-- Vérification finale
BEGIN
  DBMS_OUTPUT.PUT_LINE('✅ Tous les tests exécutés avec succès.');
END;
/