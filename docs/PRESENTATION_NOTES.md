# 5-minute walkthrough (in-class review)

Open phpMyAdmin with `careerconnect` selected. One person talks, others switch screens. Everyone must be there.

**0:00 – 0:30  What it is.** "CareerConnect stores students, companies, jobs, applications, interviews, placements, skills and events, so a placement office can see where every application stands."

**0:30 – 1:30  Tables (Designer view in phpMyAdmin).** 14 tables. Point at the middle: `students` and `jobs` are linked through `applications`. `jobs` has two subtypes (full-time, internship). `student_skills` and `event_attendance` are the two many-to-many junction tables. `users` is 1:1 with `companies`.

**1:30 – 2:30  Constraints.** Show `applications` → Structure: PK, two FKs, `UNIQUE(student_id, job_id)`, status ENUM. Then run `constraint_tests.sql` (or two of its statements: CGPA 4.5, duplicate application). They fail with errors — that is the point.

**2:30 – 4:00  Data.** Click through a few tables: `students`, `jobs`, `applications`. Run from `careerconnect_queries.sql`: query 1 (dashboard counts), query 2 (recent applications, 4-table JOIN), query 6 (placement report).

**4:00 – 4:40  Consistency.** "Every Hired application has a placement record; students only applied to jobs they are eligible for." (Show `v_application_overview` filtered on Hired next to `placement_records`.)

**4:40 – 5:00  Close.** Say the GitHub link is submitted and the SQL file imports into a fresh XAMPP in one step.

## Questions he may ask
* *Why is `student_id` not AUTO_INCREMENT?* It is the university ID, so it comes from outside.
* *Why two tables for jobs?* ISA from the ERD: shared columns in `jobs`, type-specific ones in the subtype tables.
* *Why is `placement_records.student_id` there?* The ERD did not say which student was placed; a placement needs one.
* *Cascade vs restrict?* Cascade where a child row means nothing without its parent (e.g. interviews of a deleted application); restrict where we must not lose history (a company that has placements).
