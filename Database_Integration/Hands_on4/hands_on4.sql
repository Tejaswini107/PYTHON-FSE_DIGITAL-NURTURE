-- HANDS-ON 4
-- Task 1: Baseline Performance (No Indexes)
EXPLAIN
SELECT
    s.first_name,
    s.last_name,
    c.course_name
FROM enrollments e
JOIN students s
ON s.student_id = e.student_id
JOIN courses c
ON c.course_id = e.course_id
WHERE s.enrollment_year = 2022;

-- Observation:
-- PostgreSQL performs Sequential Scan on one or more tables.
-- Since no indexes exist yet, it reads all rows to find matching records.
-- Seq Scan means PostgreSQL checks every row of the table.
-- This is acceptable for small tables but inefficient for
-- very large tables.
-- Estimated Cost:
-- cost = 0.00..25.70

-- Task 2: Add Indexes and Compare Plans

-- Create B-Tree index on students.enrollment_year
CREATE INDEX idx_students_enrollment_year
ON students(enrollment_year);

-- Create composite UNIQUE index on enrollments(student_id, course_id)
CREATE UNIQUE INDEX idx_unique_enrollment_student_course
ON enrollments(student_id, course_id);

-- Create index on courses.course_code
CREATE INDEX idx_courses_course_code
ON courses(course_code);

-- Re-run EXPLAIN after creating indexes
EXPLAIN
SELECT
    s.first_name,
    s.last_name,
    c.course_name
FROM enrollments e
JOIN students s
ON s.student_id = e.student_id
JOIN courses c
ON c.course_id = e.course_id
WHERE s.enrollment_year = 2022;

-- Create partial index for unevaluated enrollments
CREATE INDEX idx_enrollments_student_grade_null
ON enrollments(student_id)
WHERE grade IS NULL;