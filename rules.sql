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
DROP TRIGGER prevent_classroom_overlap;