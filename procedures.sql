--inscription des étudiants
CREATE OR REPLACE PROCEDURE inscrire_etudiant(
  p_student_id IN NUMBER,
  p_course_id  IN NUMBER
) AS
  v_count NUMBER;
  v_student_ref REF StudentType;
  v_course_ref  REF CourseType;
BEGIN
  -- Vérifier si l'inscription existe déjà
  SELECT COUNT(*) INTO v_count
  FROM Enrollment
  WHERE student_id = p_student_id AND course_id = p_course_id;

  IF v_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Étudiant déjà inscrit à ce cours.');
  END IF;

  -- Récupérer les REFs
  SELECT REF(s) INTO v_student_ref FROM Student s WHERE s.student_id = p_student_id;
  SELECT REF(c) INTO v_course_ref  FROM Course c  WHERE c.course_id = p_course_id;

  -- Insérer l'inscription
  INSERT INTO Enrollment(student_id, course_id, student_ref, course_ref, enrollment_date)
  VALUES(p_student_id, p_course_id, v_student_ref, v_course_ref, SYSDATE);

  DBMS_OUTPUT.PUT_LINE('Inscription réussie.');
END;
/


--attribution des notes au devoirs 
CREATE OR REPLACE PROCEDURE attribuer_note (
    p_student_id     IN NUMBER,
    p_assignment_id  IN NUMBER,
    p_score          IN NUMBER
) IS
    v_student_ref  REF StudentType;
    v_assignment   AssignmentType;
    v_exists       NUMBER;
BEGIN
    IF p_score < 0 OR p_score > 20 THEN
        RAISE_APPLICATION_ERROR(-20001, 'La note doit être comprise entre 0 et 20.');
    END IF;

    SELECT REF(s)
    INTO v_student_ref
    FROM Student s
    WHERE s.student_id = p_student_id;

    SELECT AssignmentType(
             assignment_id,
             title,
             description,
             due_date
           )
    INTO v_assignment
    FROM Assignment
    WHERE assignment_id = p_assignment_id;

    SELECT COUNT(*)
    INTO v_exists
    FROM Grade
    WHERE student_id = p_student_id AND assignment_id = p_assignment_id;

    IF v_exists > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Note déjà attribuée pour cet assignment.');
    END IF;

    INSERT INTO Grade (
        student_id, assignment_id, student, assignment, score
    ) VALUES (
        p_student_id, p_assignment_id, v_student_ref, v_assignment, p_score
    );

    DBMS_OUTPUT.PUT_LINE('Note insérée avec succès.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Étudiant ou assignment introuvable.');
END;
/




--nouvel assignment pour un cours 
CREATE OR REPLACE PROCEDURE creer_assignment (
    p_assignment_id   IN NUMBER,
    p_title           IN VARCHAR2,
    p_description     IN VARCHAR2,
    p_due_date        IN DATE,
    p_course_id       IN NUMBER
) IS
    v_course_ref  REF CourseType;
BEGIN
    -- Vérifier l'existence du cours
    SELECT REF(c)
    INTO v_course_ref
    FROM Course c
    WHERE c.course_id = p_course_id;

    -- Insérer l'assignment
    INSERT INTO Assignment (
        assignment_id, title, description, due_date, course_ref
    ) VALUES (
        p_assignment_id, p_title, p_description, p_due_date, v_course_ref
    );

    DBMS_OUTPUT.PUT_LINE('Assignment créé avec succès.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20010, 'Cours non trouvé.');
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20011, 'ID de devoir déjà existant.');
END;
/



--nouvel étudiant dans un département
CREATE OR REPLACE PROCEDURE enregistrer_etudiant (
    p_student_id IN NUMBER,
    p_name       IN VARCHAR2,
    p_email      IN VARCHAR2,
    p_dob        IN DATE,
    p_street     IN VARCHAR2,
    p_city       IN VARCHAR2,
    p_zip        IN VARCHAR2,
    p_dept_id    IN NUMBER
) IS
    v_dept_ref REF DepartmentType;
BEGIN
    -- Vérifier que le département existe
    SELECT REF(d)
    INTO v_dept_ref
    FROM Department d
    WHERE d.dept_id = p_dept_id;

    -- Insérer l'étudiant
    INSERT INTO Student VALUES (
        StudentType(
            p_student_id,
            p_name,
            p_email,
            AddressType(p_street, p_city, p_zip),
            p_dob,
            AssignmentList() -- liste vide d'assignments
        )
    );

    DBMS_OUTPUT.PUT_LINE('Étudiant enregistré avec succès.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20020, 'Département non trouvé.');
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20021, 'ID étudiant déjà existant.');
END;
/


--Créer un cours
CREATE OR REPLACE PROCEDURE creer_cours (
    p_course_id    IN NUMBER,
    p_course_name  IN VARCHAR2,
    p_coefficient  IN NUMBER,
    p_dept_id      IN NUMBER,
    p_prof_id      IN NUMBER,
    p_room_number  IN VARCHAR2,
    p_timeslot_id  IN NUMBER
) IS
    v_dept_ref    REF DepartmentType;
    v_prof_ref    REF ProfessorType;
    v_classroom_ref REF ClassroomType;
    v_timeslot_ref  REF TimeSlotType;
BEGIN
    -- Obtenir les références
    SELECT REF(d) INTO v_dept_ref FROM Department d WHERE d.dept_id = p_dept_id;
    SELECT REF(p) INTO v_prof_ref FROM Professor p WHERE p.prof_id = p_prof_id;
    SELECT REF(c) INTO v_classroom_ref FROM Classroom c WHERE c.room_number = p_room_number;
    SELECT REF(t) INTO v_timeslot_ref FROM TimeSlot t WHERE t.timeslot_id = p_timeslot_id;
    
    -- Insérer le cours
    INSERT INTO Course VALUES (
        CourseType(
            p_course_id,
            p_course_name,
            p_coefficient,
            v_dept_ref,
            v_prof_ref,
            v_classroom_ref,
            v_timeslot_ref,
            AssignmentList() -- liste vide au départ
        )
    );

    DBMS_OUTPUT.PUT_LINE('Cours créé avec succès.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20030, 'Un ou plusieurs éléments référencés sont introuvables.');
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20031, 'ID du cours déjà existant.');
END;
/


--ajouter un devoir a un cours
CREATE OR REPLACE PROCEDURE ajouter_assignment (
    p_course_id      IN NUMBER,
    p_assignment_id  IN NUMBER,
    p_title          IN VARCHAR2,
    p_description    IN VARCHAR2,
    p_due_date       IN DATE
) IS
    v_course CourseType;
BEGIN
    -- Récupérer le cours
    SELECT VALUE(c) INTO v_course FROM Course c WHERE c.course_id = p_course_id;

    -- Ajouter l'assignment à la liste existante
    v_course.assignments.EXTEND;
    v_course.assignments(v_course.assignments.LAST) := AssignmentType(
        p_assignment_id,
        p_title,
        p_description,
        p_due_date
    );

    -- Mettre à jour le cours avec la nouvelle liste d’assignments
    UPDATE Course c
    SET VALUE(c) = v_course
    WHERE c.course_id = p_course_id;

    DBMS_OUTPUT.PUT_LINE('Assignment ajouté avec succès au cours.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20040, 'Cours introuvable.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20041, 'Erreur lors de l’ajout de l’assignment : ' || SQLERRM);
END;
/

--Enregistrer une note pour un devoir donné d’un étudiant
CREATE OR REPLACE PROCEDURE enregistrer_note_assignment (
    p_student_id     IN NUMBER,
    p_assignment_id  IN NUMBER,
    p_score          IN NUMBER
) IS
    v_student_ref REF StudentType;
BEGIN
    -- Vérifier que l'étudiant existe
    SELECT REF(s) INTO v_student_ref FROM Student s WHERE s.student_id = p_student_id;

    -- Enregistrer la note
    INSERT INTO Grade (
        student_id,
        assignment_id,
        student,
        assignment,
        score
    ) VALUES (
        p_student_id,
        p_assignment_id,
        v_student_ref,
        AssignmentType(p_assignment_id, NULL, NULL, NULL),
        p_score
    );

    DBMS_OUTPUT.PUT_LINE('Note enregistrée avec succès.');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20050, 'Note déjà enregistrée pour cet assignment et cet étudiant.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20051, 'Étudiant introuvable.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20052, 'Erreur lors de l’enregistrement de la note : ' || SQLERRM);
END;
/


CREATE OR REPLACE PROCEDURE verifier_chevauchement_salle (
  p_classroom REF ClassroomType,
  p_time_slot REF TimeSlotType,
  p_course_id NUMBER
) IS
  overlap_count NUMBER;
  new_start TIMESTAMP;
  new_end   TIMESTAMP;
  new_day   VARCHAR2(10);
  ts_slot    TimeSlotType;
BEGIN
  SELECT DEREF(p_time_slot)
  INTO ts_slot
  FROM dual;

  new_start := ts_slot.start_time;
  new_end   := ts_slot.end_time;
  new_day   := ts_slot.day_of_week;

  SELECT COUNT(*)
  INTO overlap_count
  FROM Course c
  WHERE c.course_id != p_course_id
    AND DEREF(c.classroom).room_number = DEREF(p_classroom).room_number
    AND DEREF(c.time_slot).day_of_week = new_day
    AND (
      (DEREF(c.time_slot).start_time <= new_start AND DEREF(c.time_slot).end_time > new_start) OR
      (DEREF(c.time_slot).start_time < new_end AND DEREF(c.time_slot).end_time >= new_end) OR
      (DEREF(c.time_slot).start_time >= new_start AND DEREF(c.time_slot).end_time <= new_end)
    );

  IF overlap_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20041, 'Erreur lors de l’ajout de l’assignment : chevauchement horaire dans la salle.');
  END IF;
END;
/