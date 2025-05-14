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