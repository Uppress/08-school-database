-- Fictional Nigerian sample data. Run schema.sql before this file.

INSERT INTO teachers
    (staff_no, first_name, middle_name, last_name, email, phone, hire_date)
VALUES
    ('STF001', 'Adaeze', 'Ngozi', 'Okafor', 'adaeze.okafor@example.edu.ng', '+2348030001001', '2018-09-03'),
    ('STF002', 'Chinedu', NULL, 'Bello', 'chinedu.bello@example.edu.ng', '+2348030001002', '2016-01-11'),
    ('STF003', 'Ifeoma', 'Grace', 'Adebayo', 'ifeoma.adebayo@example.edu.ng', '+2348030001003', '2020-04-20'),
    ('STF004', 'Tunde', NULL, 'Eze', 'tunde.eze@example.edu.ng', '+2348030001004', '2017-09-18'),
    ('STF005', 'Zainab', 'Maryam', 'Musa', 'zainab.musa@example.edu.ng', '+2348030001005', '2019-02-04'),
    ('STF006', 'Emeka', 'Joseph', 'Olawale', 'emeka.olawale@example.edu.ng', '+2348030001006', '2015-11-02');

INSERT INTO subjects (subject_code, subject_name)
VALUES
    ('ENG', 'English Studies'),
    ('MTH', 'Mathematics'),
    ('BSC', 'Basic Science'),
    ('BST', 'Basic Technology'),
    ('CIV', 'Civic Education'),
    ('CRS', 'Christian Religious Studies'),
    ('BUS', 'Business Studies'),
    ('ICT', 'Computer Studies');

INSERT INTO terms (term_id, academic_year, term_name, start_date, end_date)
VALUES (1, '2026/2027', 'First Term', '2026-09-07', '2026-12-18');

INSERT INTO classes (class_id, class_name, form_teacher_staff_no)
VALUES
    (1, 'JSS1 A', 'STF001'),
    (2, 'JSS2 A', 'STF002'),
    (3, 'JSS3 A', 'STF003');

INSERT INTO students
    (admission_no, first_name, middle_name, last_name, date_of_birth, gender, guardian_name, guardian_phone)
VALUES
    ('ADM26001', 'Amina', 'Hauwa', 'Yusuf', '2013-02-14', 'Female', 'Musa Yusuf', '+2348031000001'),
    ('ADM26002', 'David', 'Chukwudi', 'Okeke', '2013-06-22', 'Male', 'Ngozi Okeke', '+2348031000002'),
    ('ADM26003', 'Grace', NULL, 'Ogunleye', '2013-01-09', 'Female', 'Tunde Ogunleye', '+2348031000003'),
    ('ADM26004', 'Samuel', 'Tobi', 'Adeyemi', '2013-09-03', 'Male', 'Bola Adeyemi', '+2348031000004'),
    ('ADM26005', 'Fatima', 'Zara', 'Abubakar', '2013-04-17', 'Female', 'Ibrahim Abubakar', '+2348031000005'),
    ('ADM26006', 'Chisom', NULL, 'Nwosu', '2013-11-28', 'Female', 'Ada Nwosu', '+2348031000006'),
    ('ADM26007', 'Daniel', 'Emeka', 'Ibrahim', '2013-07-12', 'Male', 'Ruth Ibrahim', '+2348031000007'),
    ('ADM26008', 'Esther', 'Oluwaseun', 'Akinola', '2013-03-30', 'Female', 'Kunle Akinola', '+2348031000008'),
    ('ADM26009', 'Yusuf', 'Sadiq', 'Bello', '2013-08-05', 'Male', 'Aisha Bello', '+2348031000009'),
    ('ADM26010', 'Precious', NULL, 'Eze', '2013-12-19', 'Female', 'Michael Eze', '+2348031000010'),
    ('ADM26011', 'Oluwatobi', 'Femi', 'Balogun', '2012-01-16', 'Male', 'Kemi Balogun', '+2348031000011'),
    ('ADM26012', 'Mary', 'Chiamaka', 'Okafor', '2012-05-24', 'Female', 'Peter Okafor', '+2348031000012'),
    ('ADM26013', 'Abdulrahman', NULL, 'Sani', '2012-10-07', 'Male', 'Hadiza Sani', '+2348031000013'),
    ('ADM26014', 'Joy', 'Efe', 'Aghogho', '2012-03-11', 'Female', 'Osaro Aghogho', '+2348031000014'),
    ('ADM26015', 'Ikenna', 'Paul', 'Umeh', '2012-07-29', 'Male', 'Ngozi Umeh', '+2348031000015'),
    ('ADM26016', 'Halima', 'Binta', 'Garba', '2012-02-02', 'Female', 'Yusuf Garba', '+2348031000016'),
    ('ADM26017', 'Peter', NULL, 'Ojo', '2012-09-14', 'Male', 'Grace Ojo', '+2348031000017'),
    ('ADM26018', 'Ruth', 'Nneka', 'Ezeani', '2012-12-01', 'Female', 'Chike Ezeani', '+2348031000018'),
    ('ADM26019', 'Ibrahim', 'Kola', 'Lawal', '2012-04-08', 'Male', 'Mariam Lawal', '+2348031000019'),
    ('ADM26020', 'Sarah', 'Amaka', 'Nwachukwu', '2012-06-26', 'Female', 'Emeka Nwachukwu', '+2348031000020'),
    ('ADM26021', 'Michael', 'Dare', 'Oladipo', '2011-01-20', 'Male', 'Funmi Oladipo', '+2348031000021'),
    ('ADM26022', 'Aisha', 'Mariam', 'Tanko', '2011-05-06', 'Female', 'Sule Tanko', '+2348031000022'),
    ('ADM26023', 'Obinna', NULL, 'Ekwueme', '2011-08-18', 'Male', 'Ngozi Ekwueme', '+2348031000023'),
    ('ADM26024', 'Miriam', 'Tomi', 'Ojo', '2011-03-27', 'Female', 'Ayo Ojo', '+2348031000024'),
    ('ADM26025', 'Khalid', 'Abubakar', 'Danladi', '2011-11-09', 'Male', 'Zainab Danladi', '+2348031000025'),
    ('ADM26026', 'Efe', 'Osas', 'Igbinosa', '2011-02-13', 'Female', 'Kelvin Igbinosa', '+2348031000026'),
    ('ADM26027', 'Joseph', 'Chukwuemeka', 'Nnamdi', '2011-07-04', 'Male', 'Ifunanya Nnamdi', '+2348031000027'),
    ('ADM26028', 'Zainab', NULL, 'Abdullahi', '2011-10-25', 'Female', 'Bashir Abdullahi', '+2348031000028'),
    ('ADM26029', 'Opeyemi', 'Tunde', 'Shittu', '2011-04-15', 'Male', 'Mojisola Shittu', '+2348031000029'),
    ('ADM26030', 'Chinyere', 'Ada', 'Onyeka', '2011-12-06', 'Female', 'Uche Onyeka', '+2348031000030');

INSERT INTO enrollments (enrollment_id, admission_no, class_id, term_id)
VALUES
    (1, 'ADM26001', 1, 1), (2, 'ADM26002', 1, 1), (3, 'ADM26003', 1, 1),
    (4, 'ADM26004', 1, 1), (5, 'ADM26005', 1, 1), (6, 'ADM26006', 1, 1),
    (7, 'ADM26007', 1, 1), (8, 'ADM26008', 1, 1), (9, 'ADM26009', 1, 1),
    (10, 'ADM26010', 1, 1),
    (11, 'ADM26011', 2, 1), (12, 'ADM26012', 2, 1), (13, 'ADM26013', 2, 1),
    (14, 'ADM26014', 2, 1), (15, 'ADM26015', 2, 1), (16, 'ADM26016', 2, 1),
    (17, 'ADM26017', 2, 1), (18, 'ADM26018', 2, 1), (19, 'ADM26019', 2, 1),
    (20, 'ADM26020', 2, 1),
    (21, 'ADM26021', 3, 1), (22, 'ADM26022', 3, 1), (23, 'ADM26023', 3, 1),
    (24, 'ADM26024', 3, 1), (25, 'ADM26025', 3, 1), (26, 'ADM26026', 3, 1),
    (27, 'ADM26027', 3, 1), (28, 'ADM26028', 3, 1), (29, 'ADM26029', 3, 1),
    (30, 'ADM26030', 3, 1);

INSERT INTO class_subject_offerings
    (offering_id, class_id, subject_code, term_id, teacher_staff_no)
VALUES
    (1, 1, 'ENG', 1, 'STF001'), (2, 1, 'MTH', 1, 'STF002'),
    (3, 1, 'BSC', 1, 'STF003'), (4, 1, 'BST', 1, 'STF004'),
    (5, 1, 'CIV', 1, 'STF005'), (6, 1, 'CRS', 1, 'STF006'),
    (7, 1, 'BUS', 1, 'STF002'), (8, 1, 'ICT', 1, 'STF004'),
    (9, 2, 'ENG', 1, 'STF001'), (10, 2, 'MTH', 1, 'STF002'),
    (11, 2, 'BSC', 1, 'STF003'), (12, 2, 'BST', 1, 'STF004'),
    (13, 2, 'CIV', 1, 'STF005'), (14, 2, 'CRS', 1, 'STF006'),
    (15, 2, 'BUS', 1, 'STF002'), (16, 2, 'ICT', 1, 'STF004'),
    (17, 3, 'ENG', 1, 'STF001'), (18, 3, 'MTH', 1, 'STF002'),
    (19, 3, 'BSC', 1, 'STF003'), (20, 3, 'BST', 1, 'STF004'),
    (21, 3, 'CIV', 1, 'STF005'), (22, 3, 'CRS', 1, 'STF006'),
    (23, 3, 'BUS', 1, 'STF002'), (24, 3, 'ICT', 1, 'STF004');

-- Each enrolled student gets one result for every subject offered to that
-- student's class in the same term. The primary key prevents duplicates.
INSERT INTO results (enrollment_id, offering_id, ca_score, exam_score)
SELECT
    e.enrollment_id,
    o.offering_id,
    CAST(25 + MOD(e.enrollment_id * 7 + o.offering_id * 3, 16) AS DECIMAL(5,2)),
    CAST(40 + MOD(e.enrollment_id * 11 + o.offering_id * 5, 21) AS DECIMAL(5,2))
FROM enrollments AS e
JOIN class_subject_offerings AS o
    ON o.class_id = e.class_id
   AND o.term_id = e.term_id;

-- Five consecutive school days; the composite primary key allows one record
-- per student per date. Statuses are varied deterministically for sample data.
INSERT INTO attendance (admission_no, attendance_date, status)
SELECT
    e.admission_no,
    school_days.attendance_date,
    CASE
        WHEN MOD(e.enrollment_id + school_days.day_number, 17) = 0 THEN 'absent'
        WHEN MOD(e.enrollment_id + school_days.day_number, 11) = 0 THEN 'late'
        ELSE 'present'
    END
FROM enrollments AS e
CROSS JOIN (
    SELECT 1 AS day_number, DATE('2026-09-14') AS attendance_date
    UNION ALL SELECT 2, DATE('2026-09-15')
    UNION ALL SELECT 3, DATE('2026-09-16')
    UNION ALL SELECT 4, DATE('2026-09-17')
    UNION ALL SELECT 5, DATE('2026-09-18')
) AS school_days;
