-- Script de test pour les triggers du projet UCMS

-- Nettoyage si nécessaire (ordre respecté pour contraintes FK)
DELETE FROM Grade;
DELETE FROM Enrollment;
DELETE FROM Assignment;
DELETE FROM Course;
DELETE FROM Student;
DELETE FROM Department;
DELETE FROM Professor;
DELETE FROM Classroom;
DELETE FROM TimeSlot;

-- Insertion de données de base
INSERT INTO Classroom VALUES ('A101', 2);

INSERT INTO Professor VALUES (
  ProfessorType(1, 'Dr. Smith', 'smith@uni.edu',
    AddressType('123 Rue A', 'Alger', '16000'),
    PhoneList('0550123456', '0660123456')
  )
);

INSERT INTO Department VALUES (
  10, 'Informatique',
  (SELECT REF(p) FROM Professor p WHERE p.prof_id = 1)
);

INSERT INTO TimeSlot VALUES (
  100, 'Monday', TO_TIMESTAMP('08:00', 'HH24:MI'), TO_TIMESTAMP('10:00', 'HH24:MI')
);

INSERT INTO TimeSlot VALUES (
  101, 'Monday', TO_TIMESTAMP('09:00', 'HH24:MI'), TO_TIMESTAMP('11:00', 'HH24:MI')
);

-- Insertion d'un premier cours valide
DECLARE
  dept_ref REF DepartmentType;
  prof_ref REF ProfessorType;
  class_ref REF ClassroomType;
  slot_ref REF TimeSlotType;
BEGIN
  SELECT REF(d) INTO dept_ref FROM Department d WHERE d.dept_id = 10;
  SELECT REF(p) INTO prof_ref FROM Professor p WHERE p.prof_id = 1;
  SELECT REF(c) INTO class_ref FROM Classroom c WHERE c.room_number = 'A101';
  SELECT REF(ts) INTO slot_ref FROM TimeSlot ts WHERE ts.timeslot_id = 100;

  INSERT INTO Course VALUES (
    1000, 'Bases de données', 3,
    dept_ref, prof_ref, class_ref, slot_ref,
    AssignmentList()
  );
END;
/

-- Insertion d'un cours qui chevauche (devrait échouer le trigger overlap)
DECLARE
  dept_ref REF DepartmentType;
  prof_ref REF ProfessorType;
  class_ref REF ClassroomType;
  slot_ref REF TimeSlotType;
BEGIN
  SELECT REF(d) INTO dept_ref FROM Department d WHERE d.dept_id = 10;
  SELECT REF(p) INTO prof_ref FROM Professor p WHERE p.prof_id = 1;
  SELECT REF(c) INTO class_ref FROM Classroom c WHERE c.room_number = 'A101';
  SELECT REF(ts) INTO slot_ref FROM TimeSlot ts WHERE ts.timeslot_id = 101;

  INSERT INTO Course VALUES (
    1001, 'Maths', 2,
    dept_ref, prof_ref, class_ref, slot_ref,
    AssignmentList()
  );
END;
/

-- Insertion d'étudiants
INSERT INTO Student VALUES (
  StudentType(1, 'Ali', 'ali@etu.dz', AddressType('1 rue B', 'Oran', '31000'), TO_DATE('2000-05-01', 'YYYY-MM-DD'), AssignmentList())
);
INSERT INTO Student VALUES (
  StudentType(2, 'Samira', 'samira@etu.dz', AddressType('2 rue C', 'Annaba', '23000'), TO_DATE('1999-08-20', 'YYYY-MM-DD'), AssignmentList())
);

-- Inscription (Enrollment)
DECLARE
  student_ref REF StudentType;
  course_ref REF CourseType;
BEGIN
  SELECT REF(s) INTO student_ref FROM Student s WHERE s.student_id = 1;
  SELECT REF(c) INTO course_ref FROM Course c WHERE c.course_id = 1000;

  INSERT INTO Enrollment VALUES (1, 1000, student_ref, course_ref, SYSDATE);
END;
/

-- Test trigger de suppression d’un cours avec inscriptions (devrait échouer)
BEGIN
  DELETE FROM Course WHERE course_id = 1000;
END;
/

-- Test trigger d’insertion de devoir sans cours (devrait échouer)
INSERT INTO Assignment VALUES (
  200, 'Projet SQL', 'Faire une BD relationnelle.', TO_DATE('2025-06-01', 'YYYY-MM-DD'), NULL
);