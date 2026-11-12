-- CareerConnect : constraint tests for the report. EVERY statement below is EXPECTED TO FAIL.
USE careerconnect;

-- 1. CGPA above 4.00                      -> CHECK chk_students_cgpa
INSERT INTO students (student_id, department_id, name, email, academic_year, cgpa)
VALUES (2299999042, 1, 'Test Student', 'test1@example.com', 2, 4.50);

-- 2. Academic year 5                      -> CHECK chk_students_year
INSERT INTO students (student_id, department_id, name, email, academic_year, cgpa)
VALUES (2299998042, 1, 'Test Student', 'test2@example.com', 5, 3.00);

-- 3. Student in a department that does not exist -> FOREIGN KEY fk_students_department
INSERT INTO students (student_id, department_id, name, email, academic_year, cgpa)
VALUES (2299997042, 99, 'Test Student', 'test3@example.com', 2, 3.00);

-- 4. Same student applies to the same job twice  -> UNIQUE uq_app_student_job
INSERT INTO applications (student_id, job_id, status, applied_date)
VALUES (2111001042, 11, 'Applied', '2026-11-05');

-- 5. Invalid application status           -> ENUM
INSERT INTO applications (student_id, job_id, status, applied_date)
VALUES (2111002042, 1, 'Pending', '2026-11-05');

-- 6. Offer salary on an application that is not Hired -> CHECK chk_app_offer
INSERT INTO applications (student_id, job_id, status, applied_date, offer_salary)
VALUES (2111002042, 3, 'Applied', '2026-11-05', 50000);

-- 7. Interview score before the interview has happened -> CHECK chk_int_score
INSERT INTO interviews (application_id, interview_name, interview_type, scheduled_date, score)
VALUES (1, 'Extra Round', 'Online', '2026-12-20 10:00:00', 90);

-- 8. Event with zero capacity             -> CHECK chk_events_capacity
INSERT INTO events (company_id, title, event_type, event_date, max_attendees)
VALUES (1, 'Empty Event', 'Seminar', '2026-12-20 10:00:00', 0);

-- 9. Second company for the same user account -> UNIQUE uq_companies_user (1:1 relationship)
INSERT INTO companies (user_id, company_name, email) VALUES (1, 'Duplicate Owner Ltd', 'dup@example.com');

-- 10. Delete a company that has placement records -> FOREIGN KEY fk_pl_company (RESTRICT)
DELETE FROM companies WHERE company_id = 1;
