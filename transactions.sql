-- Class-move transaction examples.
-- Requires schema.sql, including the class_transfers audit table.

-- Example 1: move one student's enrollment to a known class and record the
-- change atomically. Replace the sample admission number, term, and class ID.
SET @move_student = 'ADM26001';
SET @move_term_id = 1;
SET @target_class_id = 2;

START TRANSACTION;

-- Lock and remember the old class before changing the enrollment.
SELECT class_id
INTO @source_class_id
FROM enrollments
WHERE admission_no = @move_student
  AND term_id = @move_term_id
FOR UPDATE;

UPDATE enrollments
SET class_id = @target_class_id
WHERE admission_no = @move_student
  AND term_id = @move_term_id;

INSERT INTO class_transfers
    (enrollment_id, from_class_id, to_class_id)
SELECT enrollment_id, @source_class_id, @target_class_id
FROM enrollments
WHERE admission_no = @move_student
  AND term_id = @move_term_id;

COMMIT;

-- Example 2: checked version. The procedure explicitly rolls back if the
-- target class or the student's term enrollment does not exist. Any other SQL
-- exception also rolls back and is re-raised to the caller.
DELIMITER //

DROP PROCEDURE IF EXISTS sp_move_student//

CREATE PROCEDURE sp_move_student(
    IN p_student VARCHAR(20),
    IN p_term_id INT UNSIGNED,
    IN p_target_class_id INT UNSIGNED
)
BEGIN
    DECLARE v_source_class_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_checked_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_not_found BOOLEAN DEFAULT FALSE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT class_id
      INTO v_checked_id
    FROM classes
    WHERE class_id = p_target_class_id
    FOR UPDATE;

    IF v_not_found OR v_checked_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Target class does not exist; move rolled back';
    END IF;

    SET v_not_found = FALSE;
    SET v_checked_id = NULL;

    SELECT enrollment_id, class_id
      INTO v_checked_id, v_source_class_id
    FROM enrollments
    WHERE admission_no = p_student
      AND term_id = p_term_id
    FOR UPDATE;

    IF v_not_found OR v_checked_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student has no enrollment in that term; move rolled back';
    END IF;

    IF v_source_class_id = p_target_class_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student is already in the target class';
    END IF;

    UPDATE enrollments
    SET class_id = p_target_class_id
    WHERE enrollment_id = v_checked_id;

    INSERT INTO class_transfers
        (enrollment_id, from_class_id, to_class_id)
    VALUES (v_checked_id, v_source_class_id, p_target_class_id);

    COMMIT;
END//

DELIMITER ;

-- Valid example:
-- CALL sp_move_student('ADM26001', 1, 2);
--
-- Missing-target example: target ID 999999 does not exist in the seed data.
-- The procedure raises an error and its EXIT handler rolls back the transaction.
-- CALL sp_move_student('ADM26001', 1, 999999);
