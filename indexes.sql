-- EXPLAIN examples for queries 3, 5, and 7 in queries.sql.
-- Run against the school database after schema.sql and seed.sql.
-- Query-plan details vary with server version, statistics, and table size.
SET @term_id = 1;

-- BEFORE INDEX: Query 3, class average and RANK().
EXPLAIN
WITH student_averages AS (
    SELECT
        e.enrollment_id,
        e.admission_no,
        e.class_id,
        e.term_id,
        AVG(r.ca_score + r.exam_score) AS average_score
    FROM enrollments AS e
    JOIN results AS r
        ON r.enrollment_id = e.enrollment_id
    JOIN class_subject_offerings AS o
        ON o.offering_id = r.offering_id
       AND o.class_id = e.class_id
       AND o.term_id = e.term_id
    WHERE e.term_id = @term_id
    GROUP BY e.enrollment_id, e.admission_no, e.class_id, e.term_id
)
SELECT
    c.class_name,
    s.admission_no,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    sa.average_score,
    RANK() OVER (
        PARTITION BY sa.class_id, sa.term_id
        ORDER BY sa.average_score DESC
    ) AS class_position
FROM student_averages AS sa
JOIN students AS s
    ON s.admission_no = sa.admission_no
JOIN classes AS c
    ON c.class_id = sa.class_id
ORDER BY c.class_name, class_position, s.last_name, s.first_name;

-- BEFORE INDEX: Query 5, students failing at least two subjects.
EXPLAIN
SELECT
    s.admission_no,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    c.class_name,
    SUM(CASE WHEN r.ca_score + r.exam_score < 40 THEN 1 ELSE 0 END) AS failed_subjects
FROM results AS r
JOIN enrollments AS e
    ON e.enrollment_id = r.enrollment_id
JOIN students AS s
    ON s.admission_no = e.admission_no
JOIN classes AS c
    ON c.class_id = e.class_id
JOIN class_subject_offerings AS o
    ON o.offering_id = r.offering_id
   AND o.class_id = e.class_id
   AND o.term_id = e.term_id
WHERE e.term_id = @term_id
GROUP BY s.admission_no, s.first_name, s.middle_name, s.last_name, c.class_id, c.class_name
HAVING SUM(CASE WHEN r.ca_score + r.exam_score < 40 THEN 1 ELSE 0 END) >= 2
ORDER BY c.class_name, failed_subjects DESC, s.last_name, s.first_name;

-- BEFORE INDEX: Query 7, attendance percentage below 80%.
EXPLAIN
SELECT
    s.admission_no,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    c.class_name,
    COALESCE(
        100.0 * SUM(CASE WHEN a.status IN ('present', 'late') THEN 1 ELSE 0 END)
        / NULLIF(COUNT(a.attendance_date), 0),
        0
    ) AS attendance_percentage
FROM enrollments AS e
JOIN students AS s
    ON s.admission_no = e.admission_no
JOIN classes AS c
    ON c.class_id = e.class_id
JOIN terms AS t
    ON t.term_id = e.term_id
LEFT JOIN attendance AS a
    ON a.admission_no = e.admission_no
   AND a.attendance_date BETWEEN t.start_date AND t.end_date
WHERE e.term_id = @term_id
GROUP BY s.admission_no, s.first_name, s.middle_name, s.last_name, c.class_id, c.class_name
HAVING COALESCE(
    100.0 * SUM(CASE WHEN a.status IN ('present', 'late') THEN 1 ELSE 0 END)
    / NULLIF(COUNT(a.attendance_date), 0),
    0
) < 80
ORDER BY attendance_percentage, c.class_name, s.last_name, s.first_name;

-- Existing indexes already support the other joins:
-- results PRIMARY KEY (enrollment_id, offering_id);
-- attendance PRIMARY KEY (admission_no, attendance_date);
-- class_subject_offerings UNIQUE (offering_id, class_id, term_id).
-- The attendance primary key is already ideal for a per-student date range,
-- so adding another index with the same leading columns would waste space.
--
-- The new enrollment index starts with term_id for the report filter, then
-- class_id for grouping/partitioning, and carries the enrollment/student
-- identifiers needed for result and student joins.
CREATE INDEX ix_enrollments_term_class_enrollment_student
    ON enrollments (term_id, class_id, enrollment_id, admission_no);

ANALYZE TABLE enrollments, attendance, results, class_subject_offerings;

-- AFTER INDEX: Repeat the same three EXPLAIN plans.
EXPLAIN
WITH student_averages AS (
    SELECT
        e.enrollment_id,
        e.admission_no,
        e.class_id,
        e.term_id,
        AVG(r.ca_score + r.exam_score) AS average_score
    FROM enrollments AS e
    JOIN results AS r
        ON r.enrollment_id = e.enrollment_id
    JOIN class_subject_offerings AS o
        ON o.offering_id = r.offering_id
       AND o.class_id = e.class_id
       AND o.term_id = e.term_id
    WHERE e.term_id = @term_id
    GROUP BY e.enrollment_id, e.admission_no, e.class_id, e.term_id
)
SELECT
    c.class_name,
    s.admission_no,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    sa.average_score,
    RANK() OVER (
        PARTITION BY sa.class_id, sa.term_id
        ORDER BY sa.average_score DESC
    ) AS class_position
FROM student_averages AS sa
JOIN students AS s
    ON s.admission_no = sa.admission_no
JOIN classes AS c
    ON c.class_id = sa.class_id
ORDER BY c.class_name, class_position, s.last_name, s.first_name;

EXPLAIN
SELECT
    s.admission_no,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    c.class_name,
    SUM(CASE WHEN r.ca_score + r.exam_score < 40 THEN 1 ELSE 0 END) AS failed_subjects
FROM results AS r
JOIN enrollments AS e
    ON e.enrollment_id = r.enrollment_id
JOIN students AS s
    ON s.admission_no = e.admission_no
JOIN classes AS c
    ON c.class_id = e.class_id
JOIN class_subject_offerings AS o
    ON o.offering_id = r.offering_id
   AND o.class_id = e.class_id
   AND o.term_id = e.term_id
WHERE e.term_id = @term_id
GROUP BY s.admission_no, s.first_name, s.middle_name, s.last_name, c.class_id, c.class_name
HAVING SUM(CASE WHEN r.ca_score + r.exam_score < 40 THEN 1 ELSE 0 END) >= 2
ORDER BY c.class_name, failed_subjects DESC, s.last_name, s.first_name;

EXPLAIN
SELECT
    s.admission_no,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    c.class_name,
    COALESCE(
        100.0 * SUM(CASE WHEN a.status IN ('present', 'late') THEN 1 ELSE 0 END)
        / NULLIF(COUNT(a.attendance_date), 0),
        0
    ) AS attendance_percentage
FROM enrollments AS e
JOIN students AS s
    ON s.admission_no = e.admission_no
JOIN classes AS c
    ON c.class_id = e.class_id
JOIN terms AS t
    ON t.term_id = e.term_id
LEFT JOIN attendance AS a
    ON a.admission_no = e.admission_no
   AND a.attendance_date BETWEEN t.start_date AND t.end_date
WHERE e.term_id = @term_id
GROUP BY s.admission_no, s.first_name, s.middle_name, s.last_name, c.class_id, c.class_name
HAVING COALESCE(
    100.0 * SUM(CASE WHEN a.status IN ('present', 'late') THEN 1 ELSE 0 END)
    / NULLIF(COUNT(a.attendance_date), 0),
    0
) < 80
ORDER BY attendance_percentage, c.class_name, s.last_name, s.first_name;
