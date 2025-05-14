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
  JOIN Course c ON e.course_id = c.cour
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