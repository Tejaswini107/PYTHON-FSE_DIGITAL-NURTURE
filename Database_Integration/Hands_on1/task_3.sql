-- Task 3: Alter and Extend the Schema

-- Step 10: Add phone_number column to students
ALTER TABLE students
ADD COLUMN phone_number VARCHAR(15);

-- Step 11: Add max_seats column to courses with default value 60
ALTER TABLE courses
ADD COLUMN max_seats INT DEFAULT 60;

-- Step 12: Add CHECK constraint for valid grades
ALTER TABLE enrollments
ADD CONSTRAINT chk_valid_grade
CHECK (grade IN ('A', 'B', 'C', 'D', 'F') OR grade IS NULL);

-- Step 13: Rename hod_name column to head_of_dept
ALTER TABLE departments
RENAME COLUMN hod_name TO head_of_dept;

-- Step 14: Drop phone_number column from students
ALTER TABLE students
DROP COLUMN phone_number;

SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;