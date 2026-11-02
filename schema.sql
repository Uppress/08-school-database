-- School database schema for MySQL/MariaDB (InnoDB, utf8mb4).

SET NAMES utf8mb4;

DROP TABLE IF EXISTS results;
DROP TABLE IF EXISTS attendance;
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS class_subject_offerings;
DROP TABLE IF EXISTS classes;
DROP TABLE IF EXISTS subjects;
DROP TABLE IF EXISTS terms;
DROP TABLE IF EXISTS teachers;
DROP TABLE IF EXISTS students;

CREATE TABLE students (
    admission_no VARCHAR(20) NOT NULL,
    first_name VARCHAR(60) NOT NULL,
    middle_name VARCHAR(60) NULL,
    last_name VARCHAR(60) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('Male', 'Female') NOT NULL,
    guardian_name VARCHAR(150) NOT NULL,
    guardian_phone VARCHAR(20) NOT NULL,
    PRIMARY KEY (admission_no)
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE teachers (
    staff_no VARCHAR(20) NOT NULL,
    first_name VARCHAR(60) NOT NULL,
    middle_name VARCHAR(60) NULL,
    last_name VARCHAR(60) NOT NULL,
    email VARCHAR(254) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    hire_date DATE NOT NULL,
    PRIMARY KEY (staff_no),
    UNIQUE KEY uq_teachers_email (email)
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE subjects (
    subject_code VARCHAR(12) NOT NULL,
    subject_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (subject_code),
    UNIQUE KEY uq_subjects_name (subject_name)
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE terms (
    term_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    academic_year VARCHAR(9) NOT NULL,
    term_name ENUM('First Term', 'Second Term', 'Third Term') NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    PRIMARY KEY (term_id),
    UNIQUE KEY uq_terms_year_name (academic_year, term_name),
    CONSTRAINT chk_terms_date_order CHECK (end_date >= start_date)
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE classes (
    class_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    class_name VARCHAR(30) NOT NULL,
    form_teacher_staff_no VARCHAR(20) NOT NULL,
    PRIMARY KEY (class_id),
    UNIQUE KEY uq_classes_name (class_name),
    CONSTRAINT fk_classes_form_teacher
        FOREIGN KEY (form_teacher_staff_no) REFERENCES teachers (staff_no)
        -- RESTRICT prevents deleting a teacher who is still assigned; CASCADE
        -- preserves the reference if the teacher's natural key is corrected.
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE enrollments (
    enrollment_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    admission_no VARCHAR(20) NOT NULL,
    class_id INT UNSIGNED NOT NULL,
    term_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (enrollment_id),
    UNIQUE KEY uq_enrollments_student_term (admission_no, term_id),
    UNIQUE KEY uq_enrollments_id_class_term (enrollment_id, class_id, term_id),
    CONSTRAINT fk_enrollments_student
        FOREIGN KEY (admission_no) REFERENCES students (admission_no)
        -- RESTRICT protects academic history; CASCADE follows admission-number
        -- corrections to the student's natural primary key.
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_enrollments_class
        FOREIGN KEY (class_id) REFERENCES classes (class_id)
        -- RESTRICT prevents deleting a class with enrollment history; CASCADE
        -- keeps references valid if its surrogate key is changed.
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_enrollments_term
        FOREIGN KEY (term_id) REFERENCES terms (term_id)
        -- RESTRICT protects term history; CASCADE keeps references valid if
        -- the term's surrogate key is changed.
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE class_subject_offerings (
    offering_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    class_id INT UNSIGNED NOT NULL,
    subject_code VARCHAR(12) NOT NULL,
    term_id INT UNSIGNED NOT NULL,
    teacher_staff_no VARCHAR(20) NOT NULL,
    PRIMARY KEY (offering_id),
    UNIQUE KEY uq_offerings_class_subject_term (class_id, subject_code, term_id),
    UNIQUE KEY uq_offerings_id_class_term (offering_id, class_id, term_id),
    CONSTRAINT fk_offerings_class
        FOREIGN KEY (class_id) REFERENCES classes (class_id)
        -- RESTRICT retains classes referenced by teaching history; CASCADE
        -- follows a corrected surrogate key.
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_offerings_subject
        FOREIGN KEY (subject_code) REFERENCES subjects (subject_code)
        -- RESTRICT retains subjects used by offerings; CASCADE follows a
        -- corrected subject-code natural key.
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_offerings_term
        FOREIGN KEY (term_id) REFERENCES terms (term_id)
        -- RESTRICT retains term history; CASCADE follows a corrected key.
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_offerings_teacher
        FOREIGN KEY (teacher_staff_no) REFERENCES teachers (staff_no)
        -- RESTRICT protects teaching history; CASCADE follows staff-number
        -- corrections to the teacher's natural key.
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE results (
    enrollment_id INT UNSIGNED NOT NULL,
    offering_id INT UNSIGNED NOT NULL,
    ca_score DECIMAL(5,2) NOT NULL,
    exam_score DECIMAL(5,2) NOT NULL,
    -- This composite primary key is the UNIQUE constraint: one result per
    -- enrollment and class-subject offering. Combined with the unique
    -- student/term enrollment and class/subject/term offering keys, it gives
    -- one result per student, subject, and term for valid class assignments.
    PRIMARY KEY (enrollment_id, offering_id),
    CONSTRAINT chk_results_ca_score CHECK (ca_score >= 0 AND ca_score <= 40),
    CONSTRAINT chk_results_exam_score CHECK (exam_score >= 0 AND exam_score <= 60),
    CONSTRAINT fk_results_enrollment
        FOREIGN KEY (enrollment_id) REFERENCES enrollments (enrollment_id)
        -- RESTRICT avoids accidental loss of student results; CASCADE follows
        -- a corrected enrollment identifier.
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_results_offering
        FOREIGN KEY (offering_id) REFERENCES class_subject_offerings (offering_id)
        -- RESTRICT protects result history; CASCADE follows a corrected
        -- offering identifier.
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE attendance (
    admission_no VARCHAR(20) NOT NULL,
    attendance_date DATE NOT NULL,
    status ENUM('present', 'absent', 'late') NOT NULL,
    -- This composite primary key is the UNIQUE constraint: one row per
    -- student per calendar date.
    PRIMARY KEY (admission_no, attendance_date),
    CONSTRAINT fk_attendance_student
        FOREIGN KEY (admission_no) REFERENCES students (admission_no)
        -- RESTRICT protects attendance history; CASCADE follows admission-
        -- number corrections to the student's natural primary key.
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
