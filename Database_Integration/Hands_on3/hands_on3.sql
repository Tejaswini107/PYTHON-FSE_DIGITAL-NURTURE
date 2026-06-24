-- HANDS-ON 3 Advanced SQL — Subqueries, Views & Transactions
-- Task 1: Subqueries

-- Students enrolled in more courses than the average number of enrollments per student
SELECT 
    s.student_id,
    s.first_name || ' ' || s.last_name AS student_name,
    COUNT(e.course_id) AS course_count
FROM students s
JOIN enrollments e
ON s.student_id = e.student_id
GROUP BY s.student_id, s.first_name, s.last_name
HAVING COUNT(e.course_id) >
(
    SELECT AVG(course_count)
    FROM (
        SELECT COUNT(course_id) AS course_count
        FROM enrollments
        GROUP BY student_id
    ) AS avg_enrollments
);

-- Courses in which all enrolled students received grade 'A'
SELECT 
    c.course_id,
    c.course_name,
    c.course_code
FROM courses c
WHERE EXISTS (
    SELECT 1
    FROM enrollments e
    WHERE e.course_id = c.course_id
)
AND NOT EXISTS (
    SELECT 1
    FROM enrollments e
    WHERE e.course_id = c.course_id
    AND e.grade <> 'A'
);

-- Professor with highest salary in each department
SELECT 
    p.professor_id,
    p.prof_name,
    d.dept_name,
    p.salary
FROM professors p
JOIN departments d
ON p.department_id = d.department_id
WHERE p.salary = (
    SELECT MAX(p2.salary)
    FROM professors p2
    WHERE p2.department_id = p.department_id
);

-- Departments where average professor salary exceeds 85000
SELECT 
   dept_name,
    avg_salary
FROM (
    SELECT 
        d.dept_name,
        AVG(p.salary) AS avg_salary
    FROM departments d
    JOIN professors p
    ON d.department_id = p.department_id
    GROUP BY d.dept_name
) AS dept_avg
WHERE avg_salary > 85000;

-- Task 2: Creating and Using Views

-- Create view: student enrollment summary with GPA
CREATE OR REPLACE VIEW vw_student_enrollment_summary AS
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name AS student_name,
    d.dept_name,
    COUNT(e.course_id) AS number_of_courses,
    ROUND(
        AVG(
            CASE
                WHEN e.grade = 'A' THEN 4
                WHEN e.grade = 'B' THEN 3
                WHEN e.grade = 'C' THEN 2
                WHEN e.grade = 'D' THEN 1
                WHEN e.grade = 'F' THEN 0
            END
        ), 2
    ) AS gpa
FROM students s
JOIN departments d
ON s.department_id = d.department_id
LEFT JOIN enrollments e
ON s.student_id = e.student_id
GROUP BY s.student_id, student_name, d.dept_name;


-- Create view: course statistics
CREATE OR REPLACE VIEW vw_course_stats AS
SELECT
    c.course_name,
    c.course_code,
    COUNT(e.enrollment_id) AS total_enrollments,
    ROUND(
        AVG(
            CASE
                WHEN e.grade = 'A' THEN 4
                WHEN e.grade = 'B' THEN 3
                WHEN e.grade = 'C' THEN 2
                WHEN e.grade = 'D' THEN 1
                WHEN e.grade = 'F' THEN 0
            END
        ), 2
    ) AS avg_gpa
FROM courses c
LEFT JOIN enrollments e
ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_name, c.course_code;


-- Students with GPA above 3.0
SELECT *
FROM vw_student_enrollment_summary
WHERE gpa > 3.0;


-- Attempt to update multi-table view
-- This update may fail because the view is based on joins, aggregation, GROUP BY, COUNT, and AVG.
-- Such views are generally not directly updatable because PostgreSQL cannot map the update clearly
-- back to one single base table row.

-- Example attempt:
-- UPDATE vw_student_enrollment_summary
-- SET student_name = 'Updated Name'
-- WHERE student_id = 1;


-- Drop both views
DROP VIEW IF EXISTS vw_course_stats;
DROP VIEW IF EXISTS vw_student_enrollment_summary;


-- Recreate vw_student_enrollment_summary as a single-table subset view WITH CHECK OPTION
CREATE OR REPLACE VIEW vw_student_enrollment_summary AS
SELECT
    student_id,
    first_name,
    last_name,
    email,
    enrollment_year
FROM students
WHERE enrollment_year >= 2022
WITH CHECK OPTION;


-- TASK 3 : Functions, Transactions, Rollback and Savepoints

-- Create Function fn_enroll_student
CREATE OR REPLACE FUNCTION fn_enroll_student(
    p_student_id INT,
    p_course_id INT,
    p_enrollment_date DATE
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN

    IF EXISTS (
        SELECT 1
        FROM enrollments
        WHERE student_id = p_student_id
          AND course_id = p_course_id
    )
    THEN
        RAISE EXCEPTION 'Student already enrolled in this course';
    END IF;

    INSERT INTO enrollments (
        student_id,
        course_id,
        enrollment_date
    )
    VALUES (
        p_student_id,
        p_course_id,
        p_enrollment_date
    );

    RETURN 'Enrollment Successful';

END;
$$;

-- Test Function
SELECT fn_enroll_student(1, 3, '2024-01-10');

-- Department Transfer Transaction
CREATE TABLE IF NOT EXISTS department_transfer_log (
    log_id SERIAL PRIMARY KEY,
    student_id INT,
    old_department INT,
    new_department INT,
    transfer_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

BEGIN;

UPDATE students
SET department_id = 2
WHERE student_id = 1;

INSERT INTO department_transfer_log (
    student_id,
    old_department,
    new_department
)
VALUES (
    1,
    1,
    2
);

COMMIT;

-- Rollback Demonstration
BEGIN;

UPDATE students
SET department_id = 3
WHERE student_id = 2;

-- Check value before rollback
SELECT *
FROM students
WHERE student_id = 2;

ROLLBACK;

-- Verify rollback worked
SELECT *
FROM students
WHERE student_id = 2;

-- SAVEPOINT Demonstration
BEGIN;

INSERT INTO enrollments (
    student_id,
    course_id,
    enrollment_date,
    grade
)
VALUES (
    10,
    2,
    CURRENT_DATE,
    'A'
);

SAVEPOINT first_insert;

-- Intentional error
INSERT INTO enrollments (
    student_id,
    course_id,
    enrollment_date,
    grade
)
VALUES (
    999,
    2,
    CURRENT_DATE,
    'A'
);

ROLLBACK TO SAVEPOINT first_insert;

COMMIT;



-- -----------------------------------------------------
-- Analysis Comments
-- -----------------------------------------------------

-- Transactions ensure data consistency and reliability.
-- COMMIT permanently saves changes to the database.
-- ROLLBACK cancels all changes made in the current transaction.
-- SAVEPOINT creates an intermediate checkpoint within a transaction.
-- fn_enroll_student prevents duplicate student-course enrollments.
-- Department transfer uses a transaction so both update and logging succeed together.