import psycopg2
import time

conn = psycopg2.connect(
    host="localhost",
    database="college_db",
    user="postgres",
    password="postgres123"
)

cursor = conn.cursor()

# Version 1: N+1 Problem
start = time.time()

query_count = 0

cursor.execute("SELECT enrollment_id, student_id, course_id FROM enrollments")
enrollments = cursor.fetchall()
query_count += 1

for enrollment in enrollments:
    student_id = enrollment[1]

    cursor.execute(
        "SELECT first_name, last_name FROM students WHERE student_id = %s",
        (student_id,)
    )
    student = cursor.fetchone()
    query_count += 1

    print(enrollment[0], student[0], student[1])

end = time.time()

print("N+1 version queries executed:", query_count)
print("N+1 version time:", end - start)


print("\n-----------------------------\n")


# Version 2: Fixed using JOIN
start = time.time()

query_count = 0

cursor.execute("""
    SELECT 
        e.enrollment_id,
        s.first_name,
        s.last_name,
        c.course_name
    FROM enrollments e
    JOIN students s
    ON e.student_id = s.student_id
    JOIN courses c
    ON e.course_id = c.course_id
""")

results = cursor.fetchall()
query_count += 1

for row in results:
    print(row[0], row[1], row[2], row[3])

end = time.time()

print("JOIN version queries executed:", query_count)
print("JOIN version time:", end - start)

cursor.close()
conn.close()
