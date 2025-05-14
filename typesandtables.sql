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
CREATE OR REPLACE TYPE ProfessorType AS OBJECT (
  prof_id        NUMBER,
  name           VARCHAR2(100),
  email          VARCHAR2(100),
  address        AddressType,
  phone_numbers  PhoneList,
  MEMBER FUNCTION getPhoneCount RETURN NUMBER
);
/
ALTER TYPE ProfessorType ADD ATTRIBUTE department REF DepartmentType CASCADE;
/
CREATE OR REPLACE TYPE DepartmentType AS OBJECT (
  dept_id        NUMBER,
  name           VARCHAR2(100),
  head_professor REF ProfessorType
);
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
DROP TABLE Course ;/
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