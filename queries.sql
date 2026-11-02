-- Query examples for the school database.
-- Change this value to the term_id you want to report on.
SET @term_id = 1;

-- 1. Which students are enrolled in JSS1 A, and who is their form teacher?
-- Technique: JOIN follows each student's term enrollment to their class,
-- then joins the class's assigned form teacher.
SELECT
    c.class_name,
    s.admission_no,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    CONCAT_WS(' ', t.first_name, t.middle_name, t.last_name) AS form_teacher_name
FROM enrollments AS e
JOIN students AS s
    ON s.admission_no = e.admission_no
JOIN classes AS c
    ON c.class_id = e.class_id
JOIN teachers AS t
    ON t.staff_no = c.form_teacher_staff_no
WHERE c.class_name = 'JSS1 A'
  AND e.term_id = @term_id
ORDER BY s.last_name, s.first_name;

-- 2. What is each student's total and letter grade in each subject this term?
-- Technique: CASE maps each CA+exam total to the stated A-F grade bands:
-- A >= 70, B >= 60, C >= 50, D >= 45, E >= 40, otherwise F.
SELECT
    s.admission_no,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    c.class_name,
    sub.subject_code,
    sub.subject_name,
    r.ca_score,
    r.exam_score,
    r.ca_score + r.exam_score AS total_score,
    CASE
        WHEN r.ca_score + r.exam_score >= 70 THEN 'A'
        WHEN r.ca_score + r.exam_score >= 60 THEN 'B'
        WHEN r.ca_score + r.exam_score >= 50 THEN 'C'
        WHEN r.ca_score + r.exam_score >= 45 THEN 'D'
        WHEN r.ca_score + r.exam_score >= 40 THEN 'E'
        ELSE 'F'
    END AS grade
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
JOIN subjects AS sub
    ON sub.subject_code = o.subject_code
WHERE e.term_id = @term_id
ORDER BY c.class_name, s.last_name, sub.subject_name;

-- 3. What is each student's average total score and position in their class?
-- Technique: first aggregate each student's subject totals, then use
-- RANK() OVER(PARTITION BY class, term) so ties share a rank and later ranks
-- have gaps. This version requires MySQL 8.0+ or a compatible MariaDB release.
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

-- Older MySQL fallback for query 3 (MySQL 5.7; ties receive the same rank).
-- Technique: a correlated subquery counts classmates with a strictly higher
-- average, then adds one. Uncomment and run this query instead of query 3
-- when the server does not support CTEs or window functions.
/*
SELECT
    c.class_name,
    s.admission_no,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    sa.average_score,
    1 + (
        SELECT COUNT(*)
        FROM enrollments AS peer_e
        WHERE peer_e.class_id = sa.class_id
          AND peer_e.term_id = sa.term_id
          AND (
              SELECT AVG(peer_r.ca_score + peer_r.exam_score)
              FROM results AS peer_r
              JOIN class_subject_offerings AS peer_o
                  ON peer_o.offering_id = peer_r.offering_id
                 AND peer_o.class_id = peer_e.class_id
                 AND peer_o.term_id = peer_e.term_id
              WHERE peer_r.enrollment_id = peer_e.enrollment_id
          ) > sa.average_score
    ) AS class_position
FROM (
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
) AS sa
JOIN students AS s
    ON s.admission_no = sa.admission_no
JOIN classes AS c
    ON c.class_id = sa.class_id
ORDER BY c.class_name, class_position, s.last_name, s.first_name;
*/

-- 4. What are the average, highest, and lowest student totals per subject
--    in each class this term?
-- Technique: GROUP BY forms one group per class and subject; AVG, MAX, and
-- MIN summarize the individual students' CA+exam totals in that group.
SELECT
    c.class_name,
    sub.subject_code,
    sub.subject_name,
    AVG(r.ca_score + r.exam_score) AS average_score,
    MAX(r.ca_score + r.exam_score) AS highest_score,
    MIN(r.ca_score + r.exam_score) AS lowest_score
FROM results AS r
JOIN enrollments AS e
    ON e.enrollment_id = r.enrollment_id
JOIN classes AS c
    ON c.class_id = e.class_id
JOIN class_subject_offerings AS o
    ON o.offering_id = r.offering_id
   AND o.class_id = e.class_id
   AND o.term_id = e.term_id
JOIN subjects AS sub
    ON sub.subject_code = o.subject_code
WHERE e.term_id = @term_id
GROUP BY c.class_id, c.class_name, sub.subject_code, sub.subject_name
ORDER BY c.class_name, sub.subject_name;

-- 5. Which students failed (total below 40) in at least two subjects?
-- Technique: conditional aggregation counts failed subject rows per student;
-- HAVING filters the grouped results after aggregation.
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

-- 6. How many different subjects and classes does each teacher teach this term?
-- Technique: LEFT JOIN keeps teachers with no offerings in the selected term;
-- COUNT(DISTINCT ...) avoids counting repeat offerings as separate classes or
-- subjects.
SELECT
    t.staff_no,
    CONCAT_WS(' ', t.first_name, t.middle_name, t.last_name) AS teacher_name,
    COUNT(DISTINCT o.subject_code) AS subject_count,
    COUNT(DISTINCT o.class_id) AS class_count
FROM teachers AS t
LEFT JOIN class_subject_offerings AS o
    ON o.teacher_staff_no = t.staff_no
   AND o.term_id = @term_id
GROUP BY t.staff_no, t.first_name, t.middle_name, t.last_name
ORDER BY teacher_name;

-- 7. Which students attended fewer than 80% of the recorded days this term?
-- Technique: LEFT JOIN retains students with no attendance rows, conditional
-- aggregation counts present and late as attended, and HAVING filters the
-- calculated percentage. The denominator is days with an attendance record.
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

-- 8. Who is the top-scoring student (including tied students) in each class?
-- Technique: aggregate each student's average, then RANK() partitions results
-- by class and filters to rank 1, preserving all ties. Requires MySQL 8.0+.
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
),
ranked_students AS (
    SELECT
        sa.*,
        RANK() OVER (
            PARTITION BY sa.class_id, sa.term_id
            ORDER BY sa.average_score DESC
        ) AS class_position
    FROM student_averages AS sa
)
SELECT
    c.class_name,
    s.admission_no,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    rs.average_score
FROM ranked_students AS rs
JOIN students AS s
    ON s.admission_no = rs.admission_no
JOIN classes AS c
    ON c.class_id = rs.class_id
WHERE rs.class_position = 1
ORDER BY c.class_name, s.last_name, s.first_name;

-- View 1: one row per recorded student/subject result, including term,
-- class, total, and the same A-F grade bands used in query 2.
CREATE OR REPLACE VIEW v_student_results AS
SELECT
    s.admission_no,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    c.class_name,
    t.term_id,
    t.academic_year,
    t.term_name,
    sub.subject_code,
    sub.subject_name,
    r.ca_score,
    r.exam_score,
    r.ca_score + r.exam_score AS total_score,
    CASE
        WHEN r.ca_score + r.exam_score >= 70 THEN 'A'
        WHEN r.ca_score + r.exam_score >= 60 THEN 'B'
        WHEN r.ca_score + r.exam_score >= 50 THEN 'C'
        WHEN r.ca_score + r.exam_score >= 45 THEN 'D'
        WHEN r.ca_score + r.exam_score >= 40 THEN 'E'
        ELSE 'F'
    END AS grade
FROM results AS r
JOIN enrollments AS e
    ON e.enrollment_id = r.enrollment_id
JOIN students AS s
    ON s.admission_no = e.admission_no
JOIN classes AS c
    ON c.class_id = e.class_id
JOIN terms AS t
    ON t.term_id = e.term_id
JOIN class_subject_offerings AS o
    ON o.offering_id = r.offering_id
   AND o.class_id = e.class_id
   AND o.term_id = e.term_id
JOIN subjects AS sub
    ON sub.subject_code = o.subject_code;

-- View 2: one summary row per class and term with enrollment, offered-subject,
-- result counts, and the average total over recorded results.
-- LEFT JOIN retains a class-term offering even when it has no enrollment or
-- result rows yet.
CREATE OR REPLACE VIEW v_class_summary AS
SELECT
    c.class_id,
    c.class_name,
    t.term_id,
    t.academic_year,
    t.term_name,
    COUNT(DISTINCT e.admission_no) AS student_count,
    COUNT(DISTINCT o.subject_code) AS subject_count,
    COUNT(r.enrollment_id) AS result_count,
    AVG(r.ca_score + r.exam_score) AS class_average_score
FROM classes AS c
JOIN class_subject_offerings AS o
    ON o.class_id = c.class_id
JOIN terms AS t
    ON t.term_id = o.term_id
LEFT JOIN enrollments AS e
    ON e.class_id = c.class_id
   AND e.term_id = o.term_id
LEFT JOIN results AS r
    ON r.enrollment_id = e.enrollment_id
   AND r.offering_id = o.offering_id
GROUP BY c.class_id, c.class_name, t.term_id, t.academic_year, t.term_name;
