-- Record or update one student's result for a subject in a term.
-- Run after schema.sql; MySQL 5.7+ and current MariaDB versions support SIGNAL
-- and INSERT ... ON DUPLICATE KEY UPDATE.
DELIMITER //

DROP PROCEDURE IF EXISTS sp_record_result//

CREATE PROCEDURE sp_record_result(
    IN p_student VARCHAR(20),
    IN p_subject VARCHAR(12),
    IN p_term INT UNSIGNED,
    IN p_ca DECIMAL(5,2),
    IN p_exam DECIMAL(5,2)
)
BEGIN
    DECLARE v_enrollment_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_offering_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_not_found BOOLEAN DEFAULT FALSE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = TRUE;

    IF p_student IS NULL OR p_subject IS NULL OR p_term IS NULL
       OR p_ca IS NULL OR p_exam IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student, subject, term, and scores are required';
    END IF;

    IF p_ca < 0 OR p_ca > 40 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'CA score must be between 0 and 40';
    END IF;

    IF p_exam < 0 OR p_exam > 60 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Exam score must be between 0 and 60';
    END IF;

    SELECT e.enrollment_id, o.offering_id
      INTO v_enrollment_id, v_offering_id
    FROM enrollments AS e
    JOIN class_subject_offerings AS o
      ON o.class_id = e.class_id
     AND o.term_id = e.term_id
    WHERE e.admission_no = p_student
      AND o.subject_code = p_subject
      AND e.term_id = p_term
    LIMIT 1;

    IF v_not_found OR v_enrollment_id IS NULL OR v_offering_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No matching student enrollment and class subject offering';
    END IF;

    INSERT INTO results (enrollment_id, offering_id, ca_score, exam_score)
    VALUES (v_enrollment_id, v_offering_id, p_ca, p_exam)
    ON DUPLICATE KEY UPDATE
        ca_score = p_ca,
        exam_score = p_exam;
END//

DELIMITER ;

-- Example:
-- CALL sp_record_result('ADM26001', 'ENG', 1, 34.00, 52.00);
