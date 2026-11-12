# CareerConnect — Integrated Recruitment and Placement Platform

**CSE311L – Database Systems Lab · Group 7 · Section 3 · North South University**
Database implementation (MySQL / MariaDB, XAMPP).

| Member | ID |
|---|---|
| Md. Nawshan Shariar Nishan | 2111578642 |
| Lamia Sultana | 2221282043 |
| Adiba Rahman Namira | 2132024042 |
| Mahmudul Hasan | 2122308642 |

CareerConnect keeps students, companies, jobs/internships, applications, interviews, placements, skills and career events in one relational database, so application progress can be tracked and reported on.

## Files

| File | What it is |
|---|---|
| `careerconnect.sql` | **The submission file**: schema (14 tables, all constraints) + sample data for every table |
| `careerconnect_queries.sql` | Demo queries: dashboard counts, recent applications, placement report, event seats, view |
| `constraint_tests.sql` | 10 statements that are *supposed to fail*, proving the constraints work |
| `docs/ERD.png` | The ERD (Chen notation) this implementation is based on |

## How to import (XAMPP)

1. Start **Apache** and **MySQL** in the XAMPP Control Panel.
2. Open `http://localhost/phpmyadmin` → **Import** → choose `careerconnect.sql` → **Go**.
   (or from a terminal: `mysql -u root < careerconnect.sql`)
3. The database `careerconnect` appears with 14 tables. The file can be imported again at any time; it drops and recreates its own tables.

## Tables and relationships

| # | Table | Purpose | Key relationships |
|---|---|---|---|
| 1 | `users` | Login accounts | 1:1 `companies` (a company is managed by one user) |
| 2 | `companies` | Registered employers | 1:N `jobs`, 1:N `events`, 1:N `placement_records` |
| 3 | `departments` | University departments | 1:N `students` |
| 4 | `students` | Student profile, CGPA, year | N:1 `departments`; 1:N `applications`; M:N `skills`, `events` |
| 5 | `skills` | Skill catalogue | M:N `students` via `student_skills` |
| 6 | `student_skills` | Junction table | composite PK (student_id, skill_id) |
| 7 | `jobs` | Job & internship postings | N:1 `companies`; 1:N `applications`; ISA below |
| 8 | `fulltime_jobs` | ISA subtype of `jobs` | PK = FK to `jobs` |
| 9 | `internship_jobs` | ISA subtype of `jobs` | PK = FK to `jobs` |
| 10 | `applications` | A student's application to a job | N:1 `students`, N:1 `jobs`; 1:N `interviews` |
| 11 | `interviews` | Interview rounds per application | N:1 `applications` |
| 12 | `placement_records` | Final placements | N:1 `companies`, N:1 `students` |
| 13 | `events` | Career events organised by companies | N:1 `companies`; M:N `students` |
| 14 | `event_attendance` | Registration/attendance per student per event | N:1 `students`, N:1 `events` |

## Constraints implemented

* **Primary keys** on every table (composite on `student_skills`); `student_id` is the university ID, the rest are `AUTO_INCREMENT`.
* **Foreign keys** for every relationship, with explicit rules: `ON DELETE CASCADE` where the child cannot exist alone (applications, interviews, attendance, skills, events, jobs) and `ON DELETE RESTRICT` where history must be protected (departments with students, companies with placements, users with a company).
* **UNIQUE**: usernames, e-mails, company names, department names, skill names; one application per (student, job); one interview per (application, round); one attendance record per (student, event); one company per user account (1:1).
* **CHECK**: CGPA 0–4, academic year 1–4, job minimums, salaries ≥ 0, interview score 0–100 and only after the interview took place, event capacity > 0, an offer salary only on `Hired` applications, and more.
* **ENUM** for controlled vocabularies: application status (`Applied, Shortlisted, Interviewed, Hired, Rejected`), job type, job status, event type, attendance status, etc.
* **NOT NULL / DEFAULT** where a value is mandatory (e.g. default status `Applied`, default `created_date`).

## Sample data (all 14 tables)

| Table | Rows | Table | Rows |
|---|---|---|---|
| users | 8 | applications | 41 |
| companies | 8 | interviews | 43 |
| departments | 6 | placement_records | 8 |
| students | 20 | events | 8 |
| skills | 16 | event_attendance | 86 |
| student_skills | 70 | jobs / fulltime / internship | 16 / 10 / 6 |

The data is internally consistent: students only apply to jobs whose CGPA/year/department requirements they meet, every `Hired` application has a matching placement record, interviews only exist for applications that progressed, completed interviews have scores, and no event is over capacity. All names, companies and contact details are fictional. Company accounts use the demo password `Company@123`, stored as a bcrypt hash.

## Design notes (where the SQL interprets the ERD)

* The submitted ERD diagram is implemented in full. The short text schema in the same submission (Students, Companies, Jobs, Applications, Events) is a subset; all of its tables and attributes are present.
* `placement_records.student_id` was added; the ERD lists job title, join date and package but does not say *who* was placed.
* The ERD's *Manages* relationship (Users 1:1 Companies) is `companies.user_id` with a UNIQUE constraint.
* The ERD shows no attributes for the ISA subtypes; `fulltime_jobs` has `benefits`, `probation_months` and `internship_jobs` has `duration_months`, `conversion_possible`.
* Renames to avoid SQL keywords/ambiguity: Students *Year* → `academic_year`, Jobs *Type* → `job_type`, student *Department* → `department_id` (the *Belongs_To* relationship).
* Salaries and packages are monthly, in BDT.
