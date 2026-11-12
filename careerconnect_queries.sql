-- CareerConnect : demo queries for the in-class review (run after careerconnect.sql)
USE careerconnect;

-- 1. Dashboard counts (feature: Dashboard and Application Overview)
SELECT (SELECT COUNT(*) FROM students)     AS students,
       (SELECT COUNT(*) FROM companies)    AS companies,
       (SELECT COUNT(*) FROM jobs)         AS jobs,
       (SELECT COUNT(*) FROM applications) AS applications;

-- 2. Five most recent applications (JOIN of 4 tables)
SELECT a.application_id, s.name AS student, j.title AS job, c.company_name, a.status, a.applied_date
FROM applications a
JOIN students  s ON s.student_id = a.student_id
JOIN jobs      j ON j.job_id     = a.job_id
JOIN companies c ON c.company_id = j.company_id
ORDER BY a.applied_date DESC, a.application_id DESC
LIMIT 5;

-- 3. Applications per status (GROUP BY)
SELECT status, COUNT(*) AS total FROM applications GROUP BY status ORDER BY total DESC;

-- 4. Jobs with number of applicants, including jobs nobody applied to (LEFT JOIN)
SELECT j.title, c.company_name, j.job_type, j.status, COUNT(a.application_id) AS applicants
FROM jobs j
JOIN companies c ON c.company_id = j.company_id
LEFT JOIN applications a ON a.job_id = j.job_id
GROUP BY j.job_id, j.title, c.company_name, j.job_type, j.status
ORDER BY applicants DESC, j.title;

-- 5. Students who are eligible for a given job but have not applied yet (NOT EXISTS subquery)
SELECT s.student_id, s.name, s.cgpa
FROM jobs j
JOIN students s ON s.cgpa >= j.min_cgpa AND s.academic_year >= j.min_year
JOIN departments d ON d.department_id = s.department_id
WHERE j.job_id = 1
  AND (j.department = 'Any' OR j.department = d.department_name)
  AND NOT EXISTS (SELECT 1 FROM applications a WHERE a.student_id = s.student_id AND a.job_id = j.job_id);

-- 6. Placement report: who got placed where, and the average package per company
SELECT c.company_name, COUNT(*) AS placed, ROUND(AVG(p.salary_package), 0) AS avg_monthly_package
FROM placement_records p
JOIN companies c ON c.company_id = p.company_id
GROUP BY c.company_id, c.company_name
ORDER BY placed DESC;

-- 7. Placement rate per department (students placed / all students)
SELECT d.department_name, COUNT(DISTINCT s.student_id) AS students,
       COUNT(DISTINCT p.student_id) AS placed,
       ROUND(100 * COUNT(DISTINCT p.student_id) / COUNT(DISTINCT s.student_id), 1) AS placed_pct
FROM departments d
JOIN students s ON s.department_id = d.department_id
LEFT JOIN placement_records p ON p.student_id = s.student_id
GROUP BY d.department_id, d.department_name
ORDER BY placed_pct DESC;

-- 8. Events with seats taken and seats left (feature: Event Management)
SELECT e.title, e.event_type, e.event_date, e.max_attendees,
       SUM(t.attended_status <> 'Cancelled') AS registered,
       e.max_attendees - SUM(t.attended_status <> 'Cancelled') AS seats_left
FROM events e
LEFT JOIN event_attendance t ON t.event_id = e.event_id
GROUP BY e.event_id, e.title, e.event_type, e.event_date, e.max_attendees
ORDER BY e.event_date;

-- 9. Average interview score per company (only completed interviews)
SELECT c.company_name, COUNT(i.interview_id) AS interviews_done, ROUND(AVG(i.score), 1) AS avg_score
FROM interviews i
JOIN applications a ON a.application_id = i.application_id
JOIN jobs j ON j.job_id = a.job_id
JOIN companies c ON c.company_id = j.company_id
WHERE i.actual_date IS NOT NULL
GROUP BY c.company_id, c.company_name
ORDER BY avg_score DESC;

-- 10. Views used by the dashboard
CREATE OR REPLACE VIEW v_application_overview AS
SELECT a.application_id, s.student_id, s.name AS student_name, s.cgpa,
       j.title AS job_title, j.job_type, c.company_name, a.status, a.applied_date
FROM applications a
JOIN students  s ON s.student_id = a.student_id
JOIN jobs      j ON j.job_id     = a.job_id
JOIN companies c ON c.company_id = j.company_id;

SELECT * FROM v_application_overview WHERE status = 'Hired';
