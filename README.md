# Secondary School Database

This MySQL/MariaDB project models students, teachers, classes, subjects,
terms, term enrollments, class-subject offerings, results, attendance, and
class-transfer audit history. Tables use InnoDB and `utf8mb4`.

## Load the database

Create an empty database, then run the files in this order:

1. `schema.sql` — creates the tables and constraints.
2. `seed.sql` — inserts fictional sample data.
3. `indexes.sql` — runs before/after `EXPLAIN` examples and adds a reporting
   index. This index script is intended to be run once.
4. `procedures.sql` — defines `sp_record_result`.
5. `queries.sql` — runs the reports and creates the two views.

For example, from a command prompt in this folder:

```text
mysql -u root -p -e "CREATE DATABASE school_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
mysql -u root -p school_db < schema.sql
mysql -u root -p school_db < seed.sql
mysql -u root -p school_db < indexes.sql
mysql -u root -p school_db < procedures.sql
mysql -u root -p school_db < queries.sql
```

In phpMyAdmin, select `school_db`, open **Import**, choose each file in the
same order, and click **Import**. `queries.sql` sets `@term_id = 1`; change
that value to report on another term.

## Export the full database from phpMyAdmin

1. Select the `school_db` database in the left sidebar (not an individual table).
2. Open **Export**.
3. Choose **Quick** and **SQL** so phpMyAdmin includes all tables, their
   structure, and their data.
4. Click **Export** or **Go** to download the SQL dump.
5. If phpMyAdmin names it `school_db.sql`, rename the downloaded file to
   `database.sql` if that exact filename is required.

**Important:** `schema.sql` begins by dropping the project tables. Use it only
on a new/empty project database or when you intentionally want to replace the
existing schema and data. `seed.sql` is sample data and is not designed to be
inserted repeatedly.

`transactions.sql` contains a sample class move that changes sample data.
Review its parameters before running it; its checked procedure can be called
separately to demonstrate rollback for an invalid target class.

## File guide

| File | Purpose |
|---|---|
| `schema.sql` | Tables, keys, constraints, foreign-key delete/update rules, and drop order |
| `seed.sql` | Fictional Nigerian sample data: 3 classes, 8 subjects, 6 teachers, 30 students, 1 term, 240 results, 150 attendance rows |
| `queries.sql` | Eight numbered reports, an older-MySQL ranking fallback, and two views |
| `indexes.sql` | Before/after `EXPLAIN` statements and the reporting index |
| `procedures.sql` | Validated `sp_record_result` procedure with an upsert |
| `transactions.sql` | Atomic class-move example, audit insert, and checked rollback procedure |

## Entity relationship diagram

```mermaid
erDiagram
    STUDENT {
        string admission_no PK
        string first_name
        string middle_name
        string last_name
        date date_of_birth
        string gender
        string guardian_name
        string guardian_phone
    }

    TEACHER {
        string staff_no PK
        string first_name
        string middle_name
        string last_name
        string email UK
        string phone
        date hire_date
    }

    CLASS {
        int class_id PK
        string class_name UK
        string form_teacher_staff_no FK
    }

    SUBJECT {
        string subject_code PK
        string subject_name UK
    }

    TERM {
        int term_id PK
        string academic_year
        string term_name
        date start_date
        date end_date
    }

    ENROLLMENT {
        int enrollment_id PK
        string admission_no FK
        int class_id FK
        int term_id FK
    }

    CLASS_SUBJECT_OFFERING {
        int offering_id PK
        int class_id FK
        string subject_code FK
        int term_id FK
        string teacher_staff_no FK
    }

    RESULT {
        int enrollment_id PK, FK
        int offering_id PK, FK
        decimal ca_score
        decimal exam_score
    }

    ATTENDANCE {
        string admission_no PK, FK
        date attendance_date PK
        string status
    }

    CLASS_TRANSFER {
        int transfer_id PK
        int enrollment_id FK
        int from_class_id FK
        int to_class_id FK
        datetime transferred_at
    }

    TEACHER ||--o{ CLASS : "form teacher"
    STUDENT ||--o{ ENROLLMENT : enrolls
    CLASS ||--o{ ENROLLMENT : contains
    TERM ||--o{ ENROLLMENT : covers
    CLASS ||--o{ CLASS_SUBJECT_OFFERING : offers
    SUBJECT ||--o{ CLASS_SUBJECT_OFFERING : included_in
    TERM ||--o{ CLASS_SUBJECT_OFFERING : scheduled_in
    TEACHER ||--o{ CLASS_SUBJECT_OFFERING : teaches
    ENROLLMENT ||--o{ RESULT : receives
    CLASS_SUBJECT_OFFERING ||--o{ RESULT : has_results
    STUDENT ||--o{ ATTENDANCE : has
    ENROLLMENT ||--o{ CLASS_TRANSFER : transfer_history
    CLASS ||--o{ CLASS_TRANSFER : source_or_destination
```

An enrollment identifies the student's class for a particular term. A
class-subject offering identifies the teacher assigned to that subject,
class, and term. Results belong to an enrollment/offering pair. Attendance is
keyed by student and calendar day, while class transfers retain the source
and destination class IDs for audit history.

## Three useful reports to explore

The full runnable versions, including column names and join details, are in
`queries.sql`. They all use `@term_id` to select the reporting term.

### 1. Class position by average score (query 3)

This first groups each student's subject totals into an average. The window
function then ranks students independently inside each class and term:

```sql
RANK() OVER (
    PARTITION BY sa.class_id, sa.term_id
    ORDER BY sa.average_score DESC
) AS class_position
```

`RANK()` gives tied averages the same position and leaves a gap after a tie.
The query requires MySQL 8.0+ or a compatible MariaDB version; `queries.sql`
also includes a correlated-subquery fallback for older MySQL.

### 2. At least two failed subjects (query 5)

Conditional aggregation counts a student's results below 40. `HAVING` filters
after the query has grouped result rows by student:

```sql
HAVING SUM(CASE WHEN r.ca_score + r.exam_score < 40 THEN 1 ELSE 0 END) >= 2
```

This distinguishes `HAVING` from `WHERE`: the condition depends on an
aggregate count rather than on a single row. The supplied sample scores may
not produce any failing students, but the query works with real scores.

### 3. Attendance below 80% (query 7)

The report counts `present` and `late` as attendance, divides by the days with
a recorded attendance row during the term, and keeps students with no records
in the output at 0%. `NULLIF` avoids division by zero; `COALESCE` handles the
no-record case. This percentage means "of days recorded", so it represents a
full-term rate only after attendance has been entered for all school days.

## Understanding `EXPLAIN` and the index

`indexes.sql` runs `EXPLAIN` for queries 3, 5, and 7 before and after creating
`ix_enrollments_term_class_enrollment_student`. I could not run these against
a live MySQL/MariaDB server in this workspace, so the exact `type`, `key`, and
`rows` values must be read from your server's output rather than assumed.

In each `EXPLAIN` row:

- **`type`** describes the access method. `ALL` is a table scan; `range` scans
  an index range; `ref` looks up matching index values; `eq_ref` is at most
  one matching row via a unique/primary key.
- **`key`** is the index the optimizer selected, or `NULL` if it chose no
  index for that table access.
- **`rows`** is the optimizer's estimate of rows it will examine, not a
  guaranteed actual count.

Before the new index, `enrollments` has no index beginning with `term_id`, so
the optimizer may scan it (`type = ALL`, `key = NULL`) to find the requested
term. Afterward, when the optimizer chooses the new index, expect a `range`
or `ref` access using `ix_enrollments_term_class_enrollment_student`; `rows`
estimates the enrollment rows matching that term. The expected comparison is:

| Plan | `type` | `key` | `rows` |
|---|---|---|---|
| Before, if scanning | `ALL` | `NULL` | Estimate for the full enrollment table |
| After, if using the index | `range` or `ref` | `ix_enrollments_term_class_enrollment_student` | Estimate for rows in the selected term |

These are plan patterns to look for, not captured output or guaranteed values.
The supplied seed has only 30 enrollments and all are in one term, so the
optimizer may choose `ALL` before and after: the new index cannot reduce the
number of matching rows in that data. Use a larger dataset with multiple
terms to assess whether filtering by term lowers the estimate and improves
execution. The optimizer may still prefer a scan when that is cheaper.
Estimates depend on data distribution, table statistics, and server version.

The result primary key `(enrollment_id, offering_id)` already supports the
result joins in queries 3 and 5. Attendance's primary key
`(admission_no, attendance_date)` already supports query 7's per-student date
range; adding a redundant index for those same columns would use extra storage.
`ANALYZE TABLE` in `indexes.sql` refreshes statistics before the after plans.

The index is a measured starting point, not a promise of faster execution on
every dataset. Compare plans on realistic data, and consider `EXPLAIN
ANALYZE` on supported MySQL versions when actual timing and row counts are
needed.

## Recording and moving data safely

`sp_record_result` validates student/subject/term enrollment and score
boundaries, then inserts or updates the result using the result composite
primary key. For example:

```sql
CALL sp_record_result('ADM26001', 'ENG', 1, 34.00, 52.00);
```

The class-move example updates the enrollment and inserts its source/destination
audit record in one transaction. `sp_move_student` adds target/enrollment
checks; an invalid target raises an error and rolls back both changes.
