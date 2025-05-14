SET SERVEROUTPUT ON;

DECLARE
  s StudentType;
  p ProfessorType;
  c1 CourseType;
  c2 CourseType;
  a1 AssignmentType;
  a2 AssignmentType;
BEGIN
  -- 🔹 Test 1 : getAge()
  s := StudentType(
    1001,
    'Alice Dupont',
    'alice@mail.com',
    AddressType('12 rue des Lilas', 'Paris', '75012'),
    TO_DATE('2003-06-15', 'YYYY-MM-DD'),
    AssignmentList()
  );
  DBMS_OUTPUT.PUT_LINE('Âge de l’étudiant : ' || s.getAge());

  -- 🔹 Test 2 : getPhoneCount()
  p := ProfessorType(
    2001,
    'Dr. Lemoine',
    'lemoine@mail.com',
    AddressType('10 avenue des Sciences', 'Lyon', '69000'),
    PhoneList('0601020304', '0602030405', '0603040506')
  );
  DBMS_OUTPUT.PUT_LINE('Nombre de numéros du prof : ' || p.getPhoneCount());

  -- 🔹 Test 3 : getCourseDetails() sans devoirs
  c1 := CourseType(
    3001,
    'Programmation Objet',
    5,
    NULL,  -- department REF
    NULL,  -- professor REF
    AssignmentList()
  );
  DBMS_OUTPUT.PUT_LINE('Détails du cours 1 : ' || c1.getCourseDetails());

  -- 🔹 Test 4 : getAssignmentCount() avec devoirs
  a1 := AssignmentType(1, 'TP1', 'Créer un type objet', TO_DATE('2025-05-10', 'YYYY-MM-DD'));
  a2 := AssignmentType(2, 'TP2', 'Méthodes d’objet', TO_DATE('2025-05-17', 'YYYY-MM-DD'));

  c2 := CourseType(
    3002,
    'Bases de Données',
    4,
    NULL,  -- department REF
    NULL,  -- professor REF
    AssignmentList(a1, a2)
  );
  DBMS_OUTPUT.PUT_LINE('Nb devoirs dans cours 2 : ' || c2.getAssignmentCount());

END;
/