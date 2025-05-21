-- ===== Types and Tables =====

CREATE OR REPLACE TYPE AddressType AS OBJECT (
  street  VARCHAR2(100),
  city    VARCHAR2(50),
  zip     VARCHAR2(10)
);
/
CREATE OR REPLACE TYPE PhoneList AS VARRAY(3) OF VARCHAR2(20);
/
CREATE OR REPLACE TYPE AssignmentType AS OBJECT (
  assignment_id NUMBER,
  title         VARCHAR2(100),
  description   VARCHAR2(4000),
  due_date      DATE
);
/
CREATE OR REPLACE TYPE AssignmentList AS TABLE OF AssignmentType;
/
CREATE OR REPLACE TYPE TimeSlotType AS OBJECT (
  timeslot_id   NUMBER,
  day_of_week   VARCHAR2(10),
  start_time    TIMESTAMP,
  end_time      TIMESTAMP
);
/
CREATE OR REPLACE TYPE ClassroomType AS OBJECT (
  room_number VARCHAR2(10),
  capacity    NUMBER
);
/
-- 1. D'abord créer DepartmentType (sans le REF vers ProfessorType)
CREATE OR REPLACE TYPE DepartmentType AS OBJECT (
  dept_id        NUMBER,
  name           VARCHAR2(100)
);
/

-- 2. Ensuite créer ProfessorType
CREATE OR REPLACE TYPE ProfessorType AS OBJECT (
  prof_id        NUMBER,
  name           VARCHAR2(100),
  email          VARCHAR2(100),
  address        AddressType,
  phone_numbers  PhoneList,
  MEMBER FUNCTION getPhoneCount RETURN NUMBER
);
/

-- 3. Puis faire les ALTER pour ajouter les REF mutuels
ALTER TYPE DepartmentType ADD ATTRIBUTE head_professor REF ProfessorType CASCADE;
ALTER TYPE ProfessorType ADD ATTRIBUTE department REF DepartmentType CASCADE;
/
CREATE OR REPLACE TYPE StudentType AS OBJECT (
  student_id     NUMBER,
  name           VARCHAR2(100),
  email          VARCHAR2(100),
  address        AddressType,
  date_of_birth  DATE,
  assignments    AssignmentList,
  MEMBER FUNCTION getAge RETURN NUMBER
);
/
CREATE OR REPLACE TYPE CourseType AS OBJECT (
  course_id    NUMBER,
  course_name  VARCHAR2(100),
  coefficient  NUMBER,
  department   REF DepartmentType,
  professor    REF ProfessorType,
  classroom    REF ClassroomType,
  time_slot    REF TimeSlotType, 
  assignments  AssignmentList,
  MEMBER FUNCTION getCourseDetails RETURN VARCHAR2,
  MEMBER FUNCTION getAssignmentCount RETURN NUMBER
);
/
CREATE TABLE Professor OF ProfessorType (
  PRIMARY KEY (prof_id)
);

CREATE TABLE Department OF DepartmentType (
  PRIMARY KEY (dept_id),
  SCOPE FOR (head_professor) IS Professor
);
/

CREATE TABLE Student OF StudentType (
  PRIMARY KEY (student_id)
)
NESTED TABLE assignments STORE AS assignments_table;
/

CREATE TABLE Classroom OF ClassroomType (
  PRIMARY KEY (room_number)
);
/
CREATE TABLE TimeSlot OF TimeSlotType (
  PRIMARY KEY (timeslot_id)
);
/
CREATE TABLE Course OF CourseType (
  PRIMARY KEY (course_id)
)
NESTED TABLE assignments STORE AS course_assignments_table;
/

ALTER TABLE Course ADD SCOPE FOR (department) IS Department;
ALTER TABLE Course ADD SCOPE FOR (professor) IS Professor;
ALTER TABLE Course ADD SCOPE FOR (classroom) IS Classroom;
ALTER TABLE Course ADD SCOPE FOR (time_slot) IS TimeSlot;

/
CREATE TABLE Enrollment (
  student_id NUMBER,
  course_id  NUMBER,
  student_ref REF StudentType SCOPE IS Student,
  course_ref  REF CourseType SCOPE IS Course,
  enrollment_date DATE,
  PRIMARY KEY (student_id, course_id)
);
/

CREATE TABLE Grade (
  student_id NUMBER,
  assignment_id NUMBER,
  student REF StudentType SCOPE IS Student,
  assignment AssignmentType,
  score NUMBER,
  PRIMARY KEY (student_id, assignment_id)
);
/
CREATE TABLE Assignment (
  assignment_id NUMBER PRIMARY KEY,
  title         VARCHAR2(100),
  description   VARCHAR2(4000),
  due_date      DATE,
  course_ref    REF CourseType SCOPE IS Course
);
/

-- ===== Procedures =====

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

-- ===== Triggers and Constraints =====

-- 1. Empêcher un étudiant de s'inscrire au même cours plus d'une fois
CREATE OR REPLACE TRIGGER prevent_duplicate_enrollment
BEFORE INSERT OR UPDATE ON Enrollment
FOR EACH ROW
DECLARE
  existing_count NUMBER;
BEGIN
  SELECT COUNT(*)
  INTO existing_count
  FROM Enrollment
  WHERE DEREF(:NEW.student_ref).student_id = DEREF(:NEW.student_ref).student_id
  AND DEREF(:NEW.course_ref).course_id = DEREF(:NEW.course_ref).course_id;
  
  IF (existing_count > 0) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Un étudiant ne peut pas s''inscrire au même cours plus d''une fois.');
  END IF;
END;
/


-- 2. Vérifier que chaque département a un chef qui est un professeur
CREATE OR REPLACE TRIGGER check_department_head
BEFORE INSERT OR UPDATE ON Department
FOR EACH ROW
DECLARE
  head_prof_count NUMBER;
BEGIN
  IF (:NEW.head_professor IS NULL) THEN
    RAISE_APPLICATION_ERROR(-20002, 'Chaque département doit avoir un chef professeur.');
  END IF;
  
  -- Vérifier qu'un professeur ne dirige pas plus d'un département
  IF (:NEW.head_professor IS NOT NULL) THEN
    SELECT COUNT(*)
    INTO head_prof_count
    FROM Department
    WHERE DEREF(head_professor).prof_id = DEREF(:NEW.head_professor).prof_id;
    
    IF (head_prof_count > 0) THEN
      RAISE_APPLICATION_ERROR(-20003, 'Un professeur ne peut diriger qu''un seul département.');
    END IF;
  END IF;
END;
/

-- 3. Vérifier que la salle de classe a une capacité suffisante pour le cours
CREATE OR REPLACE TRIGGER check_classroom_capacity
BEFORE INSERT OR UPDATE ON Course
FOR EACH ROW
DECLARE
  class_capacity NUMBER;
  enrolled_students NUMBER;
  classroom_row ClassroomType;
BEGIN
  -- Récupérer la salle de classe via DEREF
  SELECT DEREF(:NEW.classroom)
  INTO classroom_row
  FROM dual;

  class_capacity := classroom_row.capacity;

  -- Compter les étudiants inscrits au cours
  SELECT COUNT(*)
  INTO enrolled_students
  FROM Enrollment
  WHERE course_id = :NEW.course_id;

  IF enrolled_students > class_capacity THEN
    RAISE_APPLICATION_ERROR(-20004,
      'La salle ' || classroom_row.room_number ||
      ' ne peut pas accueillir tous les étudiants (' || enrolled_students || '/' || class_capacity || ').');
  END IF;
END;
/


-- 4. Empêcher les chevauchements de cours dans une même salle
CREATE OR REPLACE TRIGGER prevent_classroom_overlap
FOR INSERT OR UPDATE ON Course
COMPOUND TRIGGER

  TYPE course_info_rec IS RECORD (
    course_id    NUMBER,
    classroom    REF ClassroomType,
    time_slot    REF TimeSlotType
  );

  TYPE course_info_tab IS TABLE OF course_info_rec INDEX BY PLS_INTEGER;
  course_info_list course_info_tab;
  idx PLS_INTEGER := 0;

BEFORE EACH ROW IS
BEGIN
  idx := idx + 1;
  course_info_list(idx).course_id := :NEW.course_id;
  course_info_list(idx).classroom := :NEW.classroom;
  course_info_list(idx).time_slot := :NEW.time_slot;
END BEFORE EACH ROW;

AFTER STATEMENT IS
  overlap_count NUMBER;
  new_start TIMESTAMP;
  new_end   TIMESTAMP;
  new_day   VARCHAR2(10);
  ts_slot   TimeSlotType;
BEGIN
  FOR i IN 1 .. course_info_list.COUNT LOOP
    SELECT DEREF(course_info_list(i).time_slot)
    INTO ts_slot
    FROM dual;

    new_start := ts_slot.start_time;
    new_end   := ts_slot.end_time;
    new_day   := ts_slot.day_of_week;

    SELECT COUNT(*)
    INTO overlap_count
    FROM Course c
    WHERE c.course_id != course_info_list(i).course_id
      AND DEREF(c.classroom).room_number = DEREF(course_info_list(i).classroom).room_number
      AND DEREF(c.time_slot).day_of_week = new_day
      AND (
        (DEREF(c.time_slot).start_time <= new_start AND DEREF(c.time_slot).end_time > new_start) OR
        (DEREF(c.time_slot).start_time < new_end AND DEREF(c.time_slot).end_time >= new_end) OR
        (DEREF(c.time_slot).start_time >= new_start AND DEREF(c.time_slot).end_time <= new_end)
      );

    IF overlap_count > 0 THEN
      RAISE_APPLICATION_ERROR(-20005, 'Chevauchement horaire détecté. La salle est déjà occupée pendant ce créneau.');
    END IF;
  END LOOP;
END AFTER STATEMENT;

END prevent_classroom_overlap;
/


-- 5. Empêcher la suppression d'un cours si des étudiants y sont inscrits
CREATE OR REPLACE TRIGGER prevent_course_deletion
BEFORE DELETE ON Course
FOR EACH ROW
DECLARE
  student_count NUMBER;
BEGIN
  SELECT COUNT(*)
  INTO student_count
  FROM Enrollment
  WHERE course_id = :OLD.course_id;

  IF (student_count > 0) THEN
    RAISE_APPLICATION_ERROR(-20006, 'Impossible de supprimer le cours. ' || student_count || 
                           ' étudiant(s) sont encore inscrits à ce cours.');
  END IF;
END;
/


-- 6. S'assurer que chaque devoir appartient à un seul cours
CREATE OR REPLACE TRIGGER check_assignment_course
BEFORE INSERT OR UPDATE ON Assignment
FOR EACH ROW
BEGIN
  IF (:NEW.course_ref IS NULL) THEN
    RAISE_APPLICATION_ERROR(-20007, 'Chaque devoir doit être associé à un cours.');
  END IF;
END;
/



-- 7. Vérifier que les notes sont comprises entre 0 et 100
CREATE OR REPLACE TRIGGER check_assignment_grade
BEFORE INSERT OR UPDATE ON Grade
FOR EACH ROW
BEGIN
  IF (:NEW.score < 0 OR :NEW.score > 100) THEN
    RAISE_APPLICATION_ERROR(-20008, 'La note doit être comprise entre 0 et 100.');
  END IF;
END;
/


-- ===== Views =====

CREATE OR REPLACE VIEW v_students_with_courses AS
SELECT
  s.student_id,
  s.name AS student_name,
  s.email,
  c.course_id,
  c.course_name,
  c.coefficient
FROM
  Enrollment e
  JOIN Student s ON e.student_id = s.student_id
  JOIN Course c ON e.course_id = c.course_id;
/
CREATE OR REPLACE VIEW v_student_transcript AS
SELECT
  s.student_id,
  s.name AS student_name,
  a.assignment_id,
  a.title AS assignment_title,
  a.due_date,
  c.course_id,
  c.course_name,
  g.score
FROM
  Grade g
  JOIN Student s ON g.student_id = s.student_id
  JOIN Assignment a ON g.assignment_id = a.assignment_id
  JOIN Course c ON a.course_ref = REF(c);

/
CREATE OR REPLACE VIEW v_weekly_schedule AS
SELECT
  c.course_id,
  c.course_name,
  ts.day_of_week,
  TO_CHAR(ts.start_time, 'HH24:MI') AS start_time,
  TO_CHAR(ts.end_time, 'HH24:MI') AS end_time,
  cl.room_number,
  cl.capacity,
  s.student_id,
  s.name AS student_name,
  p.prof_id,
  p.name AS professor_name
FROM
  Course c
  JOIN TimeSlot ts ON c.time_slot = REF(ts)
  JOIN Classroom cl ON c.classroom = REF(cl)
  LEFT JOIN Enrollment e ON c.course_id = e.course_id
  LEFT JOIN Student s ON e.student_id = s.student_id
  LEFT JOIN Professor p ON c.professor = REF(p);
/
CREATE OR REPLACE VIEW v_total_students_per_course AS
SELECT
  c.course_id,
  c.course_name,
  COUNT(e.student_id) AS total_students
FROM
  Course c
  LEFT JOIN Enrollment e ON c.course_id = e.course_id
GROUP BY
  c.course_id,
  c.course_name;
/
CREATE OR REPLACE VIEW v_students_without_assignments AS
SELECT
  s.student_id,
  s.name AS student_name,
  s.email
FROM
  Student s
WHERE
  NOT EXISTS (
    SELECT 1
    FROM Grade g
    WHERE g.student_id = s.student_id
  );
/
CREATE OR REPLACE VIEW v_top_student AS
SELECT
  student_id,
  student_name,
  ROUND(average_score, 2) AS average_score
FROM (
  SELECT
    s.student_id,
    s.name AS student_name,
    AVG(g.score) AS average_score
  FROM
    Student s
    JOIN Grade g ON s.student_id = g.student_id
  GROUP BY
    s.student_id,
    s.name
  ORDER BY
    average_score DESC
)
WHERE ROWNUM = 1;
/
CREATE OR REPLACE VIEW v_average_grade_per_course AS
SELECT
  c.course_id,
  c.course_name,
  ROUND(AVG(g.score), 2) AS average_score
FROM
  Grade g
  JOIN Assignment a ON g.assignment_id = a.assignment_id
  JOIN Course c ON a.course_ref = REF(c)
GROUP BY
  c.course_id,
  c.course_name;

-- ===== Methods =====

-- CourseType methods
CREATE OR REPLACE TYPE BODY CourseType AS
  MEMBER FUNCTION getCourseDetails RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Course: ' || course_name || 
           ', ID: ' || course_id || 
           ', Coef: ' || coefficient;
  END;

  MEMBER FUNCTION getAssignmentCount RETURN NUMBER IS
  BEGIN
    RETURN assignments.COUNT;
  END;
END;
/
-- StudentType methods
CREATE OR REPLACE TYPE BODY StudentType AS
  MEMBER FUNCTION getAge RETURN NUMBER IS
  BEGIN
    RETURN FLOOR(MONTHS_BETWEEN(SYSDATE, date_of_birth) / 12);
  END;
END;
/
-- ProfessorType methods
CREATE OR REPLACE TYPE BODY ProfessorType AS
  MEMBER FUNCTION getPhoneCount RETURN NUMBER IS
  BEGIN
    RETURN phone_numbers.COUNT;
  END;
END;
/


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