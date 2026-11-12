-- =====================================================================
--  CareerConnect : An Integrated Recruitment and Placement Platform
--  CSE311L - Database Systems Lab | Group 7 | Section 3
--  Database Implementation (schema + sample data)  -  MySQL / MariaDB (XAMPP)
--
--  Based on the submitted ERD (Chen notation). Naming: ERD "Student_ID" -> student_id,
--  ERD "Type" on Jobs -> job_type, ERD "Year" on Students -> academic_year
--  (avoids the SQL keyword YEAR). Tables are lower-case so the file also works on Linux.
--
--  Re-runnable: it creates the database if needed and drops/recreates its own tables.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS careerconnect
    CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE careerconnect;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS event_attendance, student_skills, interviews, placement_records,
                     applications, internship_jobs, fulltime_jobs, jobs, events, skills,
                     students, departments, companies, users;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- 1. users   (ERD: Users  --Manages 1:1-->  Companies)
-- ---------------------------------------------------------------------
CREATE TABLE users (
    user_id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
    username      VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) NOT NULL,
    password      VARCHAR(255) NOT NULL,                 -- stores a password HASH, never plain text
    status        ENUM('Active','Inactive','Suspended') NOT NULL DEFAULT 'Active',
    last_login    DATETIME NULL,
    created_date  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    UNIQUE KEY uq_users_username (username),
    UNIQUE KEY uq_users_email (email)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 2. companies   (each company is managed by exactly one user account: 1:1)
-- ---------------------------------------------------------------------
CREATE TABLE companies (
    company_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id       INT UNSIGNED NOT NULL,                 -- "Manages" relationship (UNIQUE => 1:1)
    company_name  VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL,
    phone         VARCHAR(20),
    industry      VARCHAR(60),
    website       VARCHAR(150),
    description   TEXT,
    created_date  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (company_id),
    UNIQUE KEY uq_companies_user (user_id),
    UNIQUE KEY uq_companies_name (company_name),
    UNIQUE KEY uq_companies_email (email),
    CONSTRAINT fk_companies_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 3. departments   (ERD: Departments --Belongs_To 1:N--> Students)
-- ---------------------------------------------------------------------
CREATE TABLE departments (
    department_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    department_name  VARCHAR(100) NOT NULL,
    department_head  VARCHAR(100),
    contact_email    VARCHAR(100),
    established_year SMALLINT UNSIGNED,
    PRIMARY KEY (department_id),
    UNIQUE KEY uq_departments_name (department_name),
    CONSTRAINT chk_dept_year CHECK (established_year IS NULL OR established_year BETWEEN 1900 AND 2100)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 4. students   (student_id is the university ID, e.g. 2111578642, so it is NOT auto-generated)
-- ---------------------------------------------------------------------
CREATE TABLE students (
    student_id     INT UNSIGNED NOT NULL,
    department_id  INT UNSIGNED NOT NULL,
    name           VARCHAR(100) NOT NULL,
    email          VARCHAR(100) NOT NULL,
    phone          VARCHAR(20),
    academic_year  TINYINT UNSIGNED NOT NULL,            -- ERD attribute "Year" (1st-4th year)
    cgpa           DECIMAL(3,2) NOT NULL,
    resume_path    VARCHAR(255),
    created_date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (student_id),
    UNIQUE KEY uq_students_email (email),
    KEY idx_students_department (department_id),
    CONSTRAINT fk_students_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_students_year CHECK (academic_year BETWEEN 1 AND 4),
    CONSTRAINT chk_students_cgpa CHECK (cgpa BETWEEN 0.00 AND 4.00)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 5. skills  and  6. student_skills   (Students M:N Skills)
-- ---------------------------------------------------------------------
CREATE TABLE skills (
    skill_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    skill_name   VARCHAR(60) NOT NULL,
    category     VARCHAR(40),
    description  VARCHAR(255),
    PRIMARY KEY (skill_id),
    UNIQUE KEY uq_skills_name (skill_name)
) ENGINE = InnoDB;

CREATE TABLE student_skills (
    student_id  INT UNSIGNED NOT NULL,
    skill_id    INT UNSIGNED NOT NULL,
    PRIMARY KEY (student_id, skill_id),                  -- composite key from the ERD (Student_ID PF, Skill_ID FK)
    KEY idx_ss_skill (skill_id),
    CONSTRAINT fk_ss_student FOREIGN KEY (student_id) REFERENCES students(student_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ss_skill FOREIGN KEY (skill_id) REFERENCES skills(skill_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 7. jobs   (Companies --Posts 1:N--> Jobs)   + ISA: fulltime_jobs / internship_jobs
-- ---------------------------------------------------------------------
CREATE TABLE jobs (
    job_id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    company_id    INT UNSIGNED NOT NULL,
    title         VARCHAR(100) NOT NULL,
    description   TEXT,
    job_type      ENUM('Full-Time','Internship') NOT NULL,   -- ISA discriminator
    department    VARCHAR(100),                              -- target department ('Any' = open to all)
    min_cgpa      DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    min_year      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    salary        DECIMAL(10,2),                             -- monthly, BDT (stipend for internships)
    location      VARCHAR(100),
    deadline      DATE,
    status        ENUM('Open','Closed','Draft') NOT NULL DEFAULT 'Open',
    created_date  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (job_id),
    KEY idx_jobs_company (company_id),
    KEY idx_jobs_status (status),
    CONSTRAINT fk_jobs_company FOREIGN KEY (company_id) REFERENCES companies(company_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_jobs_min_cgpa CHECK (min_cgpa BETWEEN 0.00 AND 4.00),
    CONSTRAINT chk_jobs_min_year CHECK (min_year BETWEEN 1 AND 4),
    CONSTRAINT chk_jobs_salary   CHECK (salary IS NULL OR salary >= 0)
) ENGINE = InnoDB;

CREATE TABLE fulltime_jobs (
    job_id           INT UNSIGNED NOT NULL,
    benefits         VARCHAR(255),
    probation_months TINYINT UNSIGNED NOT NULL DEFAULT 3,
    PRIMARY KEY (job_id),
    CONSTRAINT fk_ft_job FOREIGN KEY (job_id) REFERENCES jobs(job_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_ft_probation CHECK (probation_months BETWEEN 0 AND 12)
) ENGINE = InnoDB;

CREATE TABLE internship_jobs (
    job_id               INT UNSIGNED NOT NULL,
    duration_months      TINYINT UNSIGNED NOT NULL,
    conversion_possible  BOOLEAN NOT NULL DEFAULT FALSE,     -- may convert to a full-time offer
    PRIMARY KEY (job_id),
    CONSTRAINT fk_in_job FOREIGN KEY (job_id) REFERENCES jobs(job_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_in_duration CHECK (duration_months BETWEEN 1 AND 12)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 8. applications   (Students --Applies_For 1:N-- Applications --Has N:1-- Jobs)
-- ---------------------------------------------------------------------
CREATE TABLE applications (
    application_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    student_id       INT UNSIGNED NOT NULL,
    job_id           INT UNSIGNED NOT NULL,
    status           ENUM('Applied','Shortlisted','Interviewed','Hired','Rejected') NOT NULL DEFAULT 'Applied',
    applied_date     DATE NOT NULL,
    interview_date   DATETIME NULL,
    interview_notes  TEXT,
    offer_salary     DECIMAL(10,2) NULL,
    PRIMARY KEY (application_id),
    UNIQUE KEY uq_app_student_job (student_id, job_id),      -- a student applies to a job only once
    KEY idx_app_job (job_id),
    KEY idx_app_status (status),
    CONSTRAINT fk_app_student FOREIGN KEY (student_id) REFERENCES students(student_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_app_job FOREIGN KEY (job_id) REFERENCES jobs(job_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_app_offer CHECK (offer_salary IS NULL OR (offer_salary >= 0 AND status = 'Hired'))
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 9. interviews   (Applications --Schedules 1:N--> Interviews)
-- ---------------------------------------------------------------------
CREATE TABLE interviews (
    interview_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    application_id    INT UNSIGNED NOT NULL,
    interview_name    VARCHAR(80) NOT NULL,
    interview_type    ENUM('Online','On-site','Phone') NOT NULL,
    interview_round   TINYINT UNSIGNED NOT NULL DEFAULT 1,
    scheduled_date    DATETIME NOT NULL,
    actual_date       DATETIME NULL,                         -- NULL until the interview has taken place
    duration_minutes  SMALLINT UNSIGNED,
    score             DECIMAL(5,2) NULL,
    feedback          TEXT,
    PRIMARY KEY (interview_id),
    UNIQUE KEY uq_interview_round (application_id, interview_round),
    CONSTRAINT fk_int_app FOREIGN KEY (application_id) REFERENCES applications(application_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_int_round    CHECK (interview_round >= 1),
    CONSTRAINT chk_int_duration CHECK (duration_minutes IS NULL OR duration_minutes BETWEEN 5 AND 480),
    CONSTRAINT chk_int_score    CHECK (score IS NULL OR (score BETWEEN 0 AND 100 AND actual_date IS NOT NULL))
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 10. placement_records   (Companies --Has 1:N--> Placement_Records)
--     student_id added: the ERD attributes (job title, join date, package) only make sense
--     if the record says WHICH student was placed.
-- ---------------------------------------------------------------------
CREATE TABLE placement_records (
    placement_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    student_id       INT UNSIGNED NOT NULL,
    company_id       INT UNSIGNED NOT NULL,
    job_title        VARCHAR(100) NOT NULL,
    join_date        DATE NOT NULL,
    salary_package   DECIMAL(10,2) NOT NULL,                 -- monthly, BDT
    employment_type  ENUM('Full-Time','Internship','Part-Time','Contract') NOT NULL,
    academic_year    VARCHAR(9) NOT NULL,                    -- e.g. 2026-2027
    created_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (placement_id),
    KEY idx_pl_student (student_id),
    KEY idx_pl_company (company_id),
    CONSTRAINT fk_pl_student FOREIGN KEY (student_id) REFERENCES students(student_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pl_company FOREIGN KEY (company_id) REFERENCES companies(company_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_pl_salary CHECK (salary_package >= 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 11. events   (Companies --Organizes 1:N--> Events)
-- ---------------------------------------------------------------------
CREATE TABLE events (
    event_id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
    company_id     INT UNSIGNED NOT NULL,
    title          VARCHAR(150) NOT NULL,
    description    TEXT,
    event_type     ENUM('Workshop','Seminar','Info Session','Recruitment Drive','Career Fair','Competition') NOT NULL,
    event_date     DATETIME NOT NULL,
    location       VARCHAR(100),
    max_attendees  SMALLINT UNSIGNED NOT NULL,
    created_date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id),
    KEY idx_events_company (company_id),
    KEY idx_events_date (event_date),
    CONSTRAINT fk_events_company FOREIGN KEY (company_id) REFERENCES companies(company_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_events_capacity CHECK (max_attendees > 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 12. event_attendance   (Students M:N Events, with its own attributes)
-- ---------------------------------------------------------------------
CREATE TABLE event_attendance (
    attendance_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    student_id         INT UNSIGNED NOT NULL,
    event_id           INT UNSIGNED NOT NULL,
    attended_status    ENUM('Registered','Attended','Absent','Cancelled') NOT NULL DEFAULT 'Registered',
    feedback           TEXT,
    registration_date  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (attendance_id),
    UNIQUE KEY uq_attendance (student_id, event_id),         -- one registration per student per event
    KEY idx_att_event (event_id),
    CONSTRAINT fk_att_student FOREIGN KEY (student_id) REFERENCES students(student_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_att_event FOREIGN KEY (event_id) REFERENCES events(event_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;


-- =====================================================================
--  SAMPLE DATA
--  (All names, companies, numbers and e-mails are fictional. Company accounts use the
--  demo password  Company@123  stored as a bcrypt hash.)
-- =====================================================================

-- users
INSERT INTO users (user_id, username, email, password, status, last_login, created_date) VALUES
(1, 'nexora_hr', 'nexora@nexora-tech.example', '$2y$10$GArwcDzCz7cNnDRXXOaATeZNZG6h8Xp02tiGluQ6qV9ZLnuMTIaQu', 'Active', '2026-11-05 13:46:00', '2026-08-02 11:00:00'),
(2, 'jamuna_careers', 'jamuna@jamunafintech.example', '$2y$10$ac6oOG5hLrDfkebdWO2pu.MY3wZe7PmwO9huCwWRQx6sV385MmzVO', 'Active', '2026-11-08 11:17:00', '2026-08-09 11:00:00'),
(3, 'bluedelta_talent', 'bluedelta@bluedelta.example', '$2y$10$htfsyMwR8ZAD1P99BxNlk.FnvJmSCPA90XfaWnn8h9HaZKTsiIZEq', 'Active', '2026-11-09 15:14:00', '2026-08-12 11:00:00'),
(4, 'shonar_hr', 'shonar@shonartextiles.example', '$2y$10$QLnJy7gvOaXZSa1Z.EFhhe96EDBXXGzW/Z4H8Ay5on5k8eaGOUhYy', 'Active', '2026-11-05 10:47:00', '2026-08-03 11:00:00'),
(5, 'greengrid_jobs', 'greengrid@greengrid-energy.example', '$2y$10$YQ1fCOEw4agofc5q2uhXXewZFVmEpoW/5qnQvCFiHDHeKiVmBcSJG', 'Active', '2026-11-05 13:54:00', '2026-08-02 11:00:00'),
(6, 'brainwave_hiring', 'brainwave@brainwave-analytics.example', '$2y$10$9vugUvCRZirNBYlB4vOueO5mxSSWb8dkK8j3Nda5yNAGQjsRwMZX.', 'Active', '2026-11-04 18:16:00', '2026-08-06 11:00:00'),
(7, 'urbancanvas_hr', 'urbancanvas@urbancanvas.example', '$2y$10$NeMc4.ESNp/u5pek1TJfeOuSzqV195/il8nSiedPEkxjAs9IWK0hS', 'Active', '2026-11-08 16:49:00', '2026-08-15 11:00:00'),
(8, 'orbit_careers', 'orbit@orbitlogistics.example', '$2y$10$cV7eYJyCQRARKOAspGaFC.oIQmMJcPg8dkjYBrA/RfXE7nGuh5REC', 'Active', '2026-11-01 13:48:00', '2026-08-02 11:00:00');

-- companies
INSERT INTO companies (company_id, user_id, company_name, email, phone, industry, website, description, created_date) VALUES
(1, 1, 'Nexora Technologies', 'careers@nexora-tech.example', '+8801700000001', 'Software & IT Services', 'www.nexora-tech.example', 'Dhaka-based software house building web and mobile products for banks and retailers.', '2026-08-07 11:00:00'),
(2, 2, 'Jamuna Fintech Ltd', 'careers@jamunafintech.example', '+8801700000002', 'Financial Technology', 'www.jamunafintech.example', 'Digital payments and mobile banking platform serving over two million users.', '2026-08-01 11:00:00'),
(3, 3, 'BlueDelta Telecom', 'careers@bluedelta.example', '+8801700000003', 'Telecommunications', 'www.bluedelta.example', 'Mobile network operator running 4G/5G rollout across Bangladesh.', '2026-08-06 11:00:00'),
(4, 4, 'Shonar Textiles & Apparel', 'careers@shonartextiles.example', '+8801700000004', 'Manufacturing', 'www.shonartextiles.example', 'Export-oriented garment manufacturer with factories in Gazipur and Narayanganj.', '2026-08-10 11:00:00'),
(5, 5, 'GreenGrid Energy', 'careers@greengrid-energy.example', '+8801700000005', 'Renewable Energy', 'www.greengrid-energy.example', 'Solar and grid-modernisation projects for rural and industrial customers.', '2026-08-10 11:00:00'),
(6, 6, 'Brainwave Analytics', 'careers@brainwave-analytics.example', '+8801700000006', 'Data & AI', 'www.brainwave-analytics.example', 'Analytics consultancy delivering forecasting and machine-learning solutions.', '2026-08-05 11:00:00'),
(7, 7, 'Urban Canvas Architects', 'careers@urbancanvas.example', '+8801700000007', 'Architecture & Design', 'www.urbancanvas.example', 'Architecture and urban design studio working on residential and public projects.', '2026-08-15 11:00:00'),
(8, 8, 'Orbit Logistics', 'careers@orbitlogistics.example', '+8801700000008', 'Logistics & Supply Chain', 'www.orbitlogistics.example', 'Last-mile delivery and warehousing company operating in eight divisions.', '2026-08-13 11:00:00');

-- departments
INSERT INTO departments (department_id, department_name, department_head, contact_email, established_year) VALUES
(1, 'Computer Science & Engineering', 'Dr. Farhana Rahman', 'cse@sample-nsu.edu', 2003),
(2, 'Electrical & Electronic Engineering', 'Dr. Mahbub Alam', 'eee@sample-nsu.edu', 2001),
(3, 'Business Administration', 'Dr. Nasrin Sultana', 'bba@sample-nsu.edu', 1996),
(4, 'Economics', 'Dr. Kamrul Hasan', 'econ@sample-nsu.edu', 1998),
(5, 'Architecture', 'Dr. Rezaul Karim', 'arch@sample-nsu.edu', 2004),
(6, 'Civil & Environmental Engineering', 'Dr. Shirin Akhter', 'cee@sample-nsu.edu', 2006);

-- students
INSERT INTO students (student_id, department_id, name, email, phone, academic_year, cgpa, resume_path, created_date) VALUES
(2111001042, 1, 'Tanvir Ahmed', 'tanvir.ahmed@student.sample-nsu.edu', '+8801813606716', 4, 3.62, 'resumes/2111001042_tanvir_ahmed.pdf', '2025-09-19 12:00:00'),
(2111002042, 1, 'Nusrat Jahan', 'nusrat.jahan@student.sample-nsu.edu', '+8801887263842', 4, 3.88, 'resumes/2111002042_nusrat_jahan.pdf', '2025-12-04 12:00:00'),
(2121003042, 1, 'Rafiul Islam', 'rafiul.islam@student.sample-nsu.edu', '+8801872631566', 3, 3.15, 'resumes/2121003042_rafiul_islam.pdf', '2025-04-05 12:00:00'),
(2121004042, 1, 'Sadia Afrin', 'sadia.afrin@student.sample-nsu.edu', '+8801817252094', 3, 3.41, 'resumes/2121004042_sadia_afrin.pdf', '2025-12-15 12:00:00'),
(2211005042, 1, 'Fahim Hossain', 'fahim.hossain@student.sample-nsu.edu', '+8801849908057', 4, 2.95, 'resumes/2211005042_fahim_hossain.pdf', '2025-12-27 12:00:00'),
(2211006042, 1, 'Maliha Khan', 'maliha.khan@student.sample-nsu.edu', '+8801891558206', 3, 3.72, 'resumes/2211006042_maliha_khan.pdf', '2025-01-07 12:00:00'),
(2221007042, 1, 'Arif Chowdhury', 'arif.chowdhury@student.sample-nsu.edu', '+8801821893613', 2, 3.05, 'resumes/2221007042_arif_chowdhury.pdf', '2025-01-19 12:00:00'),
(2111008042, 2, 'Tasnim Akter', 'tasnim.akter@student.sample-nsu.edu', '+8801836417726', 4, 3.34, 'resumes/2111008042_tasnim_akter.pdf', '2025-12-22 12:00:00'),
(2121009042, 2, 'Imran Sarker', 'imran.sarker@student.sample-nsu.edu', '+8801878958447', 3, 2.86, 'resumes/2121009042_imran_sarker.pdf', '2025-08-21 12:00:00'),
(2211010042, 2, 'Sumaiya Rahman', 'sumaiya.rahman@student.sample-nsu.edu', '+8801892996626', 4, 3.57, 'resumes/2211010042_sumaiya_rahman.pdf', '2025-01-10 12:00:00'),
(2111011042, 3, 'Mehedi Hasan', 'mehedi.hasan@student.sample-nsu.edu', '+8801826273244', 4, 3.2, 'resumes/2111011042_mehedi_hasan.pdf', '2025-06-27 12:00:00'),
(2121012042, 3, 'Farzana Yasmin', 'farzana.yasmin@student.sample-nsu.edu', '+8801881141858', 4, 3.48, 'resumes/2121012042_farzana_yasmin.pdf', '2025-01-18 12:00:00'),
(2211013042, 3, 'Shakib Anwar', 'shakib.anwar@student.sample-nsu.edu', '+8801856319237', 3, 2.91, 'resumes/2211013042_shakib_anwar.pdf', '2025-08-10 12:00:00'),
(2221014042, 3, 'Nabila Sultana', 'nabila.sultana@student.sample-nsu.edu', '+8801829559907', 3, 3.66, 'resumes/2221014042_nabila_sultana.pdf', '2025-12-19 12:00:00'),
(2111015042, 4, 'Rakibul Karim', 'rakibul.karim@student.sample-nsu.edu', '+8801835511124', 4, 3.1, 'resumes/2111015042_rakibul_karim.pdf', '2025-02-04 12:00:00'),
(2121016042, 4, 'Anika Tabassum', 'anika.tabassum@student.sample-nsu.edu', '+8801891299858', 3, 3.52, 'resumes/2121016042_anika_tabassum.pdf', '2025-09-27 12:00:00'),
(2111017042, 5, 'Jubayer Alam', 'jubayer.alam@student.sample-nsu.edu', '+8801832898513', 4, 3.28, 'resumes/2111017042_jubayer_alam.pdf', '2025-10-02 12:00:00'),
(2211018042, 5, 'Lamisa Noor', 'lamisa.noor@student.sample-nsu.edu', '+8801820340698', 3, 3.44, 'resumes/2211018042_lamisa_noor.pdf', '2025-05-20 12:00:00'),
(2111019042, 6, 'Ashik Mahmud', 'ashik.mahmud@student.sample-nsu.edu', '+8801894427593', 4, 3.02, 'resumes/2111019042_ashik_mahmud.pdf', '2025-12-18 12:00:00'),
(2121020042, 6, 'Priya Das', 'priya.das@student.sample-nsu.edu', '+8801858544321', 3, 3.3, 'resumes/2121020042_priya_das.pdf', '2025-11-19 12:00:00');

-- skills
INSERT INTO skills (skill_id, skill_name, category, description) VALUES
(1, 'Python', 'Programming', 'General-purpose programming and scripting'),
(2, 'Java', 'Programming', 'Object-oriented application development'),
(3, 'SQL', 'Database', 'Querying and designing relational databases'),
(4, 'JavaScript', 'Programming', 'Front-end and Node.js development'),
(5, 'PHP', 'Programming', 'Server-side web development'),
(6, 'C++', 'Programming', 'Systems and competitive programming'),
(7, 'Machine Learning', 'Data Science', 'Building predictive models'),
(8, 'Data Analysis', 'Data Science', 'Cleaning, exploring and visualising data'),
(9, 'MS Excel', 'Tools', 'Spreadsheets, pivot tables and formulas'),
(10, 'Communication', 'Soft Skill', 'Clear written and verbal communication'),
(11, 'Teamwork', 'Soft Skill', 'Working effectively in a team'),
(12, 'Project Management', 'Soft Skill', 'Planning and delivering projects'),
(13, 'AutoCAD', 'Design', '2D drafting and technical drawing'),
(14, 'Circuit Design', 'Engineering', 'Analog and digital circuit design'),
(15, 'Financial Modeling', 'Finance', 'Budgeting, forecasting and valuation'),
(16, 'Network Configuration', 'Engineering', 'Routing, switching and network setup');

-- student_skills
INSERT INTO student_skills (student_id, skill_id) VALUES
(2111001042, 4),
(2111001042, 6),
(2111001042, 5),
(2111002042, 6),
(2111002042, 4),
(2111002042, 5),
(2121003042, 11),
(2121003042, 10),
(2121003042, 7),
(2121003042, 1),
(2121004042, 8),
(2121004042, 4),
(2121004042, 6),
(2121004042, 2),
(2211005042, 1),
(2211005042, 6),
(2211005042, 7),
(2211006042, 1),
(2211006042, 2),
(2211006042, 8),
(2211006042, 11),
(2221007042, 8),
(2221007042, 11),
(2221007042, 1),
(2111008042, 1),
(2111008042, 6),
(2111008042, 16),
(2111008042, 14),
(2121009042, 12),
(2121009042, 1),
(2121009042, 14),
(2121009042, 11),
(2211010042, 14),
(2211010042, 11),
(2211010042, 1),
(2211010042, 12),
(2111011042, 9),
(2111011042, 10),
(2111011042, 8),
(2111011042, 11),
(2121012042, 9),
(2121012042, 11),
(2121012042, 8),
(2121012042, 10),
(2211013042, 10),
(2211013042, 15),
(2211013042, 11),
(2221014042, 15),
(2221014042, 12),
(2221014042, 8),
(2111015042, 15),
(2111015042, 1),
(2111015042, 8),
(2121016042, 8),
(2121016042, 1),
(2121016042, 15),
(2121016042, 10),
(2111017042, 11),
(2111017042, 12),
(2111017042, 10),
(2211018042, 11),
(2211018042, 13),
(2211018042, 12),
(2211018042, 10),
(2111019042, 9),
(2111019042, 12),
(2111019042, 13),
(2121020042, 9),
(2121020042, 12),
(2121020042, 13);

-- jobs
INSERT INTO jobs (job_id, company_id, title, description, job_type, department, min_cgpa, min_year, salary, location, deadline, status, created_date) VALUES
(1, 1, 'Junior Software Engineer', 'Build and maintain REST APIs and web front ends in an agile team.', 'Full-Time', 'Computer Science & Engineering', 3.0, 4, 55000, 'Dhaka (Gulshan)', '2026-12-10', 'Open', '2026-08-21 10:00:00'),
(2, 1, 'Backend Developer (PHP/MySQL)', 'Develop PHP and MySQL back ends for banking and retail clients.', 'Full-Time', 'Computer Science & Engineering', 2.8, 3, 50000, 'Dhaka (Gulshan)', '2026-12-15', 'Open', '2026-08-20 10:00:00'),
(3, 2, 'Management Trainee Officer', '12-month rotational programme across payments, risk and operations.', 'Full-Time', 'Business Administration', 3.0, 4, 45000, 'Dhaka (Motijheel)', '2026-12-05', 'Open', '2026-08-22 10:00:00'),
(4, 6, 'Data Analyst', 'Analyse client datasets and build dashboards and forecasting reports.', 'Full-Time', 'Any', 3.2, 4, 60000, 'Dhaka (Banani)', '2026-12-12', 'Open', '2026-08-31 10:00:00'),
(5, 3, 'Network Engineer', 'Plan, configure and monitor core and access network equipment.', 'Full-Time', 'Electrical & Electronic Engineering', 3.0, 4, 52000, 'Dhaka (Mohakhali)', '2026-11-30', 'Open', '2026-08-31 10:00:00'),
(6, 5, 'Electrical Engineer - Solar Projects', 'Design and commission rooftop and utility-scale solar installations.', 'Full-Time', 'Electrical & Electronic Engineering', 3.1, 4, 58000, 'Dhaka / Field visits', '2026-12-20', 'Open', '2026-08-21 10:00:00'),
(7, 4, 'Production Planning Officer', 'Plan production schedules and coordinate between sourcing and factory floor.', 'Full-Time', 'Business Administration', 2.8, 4, 40000, 'Gazipur', '2026-10-31', 'Closed', '2026-08-26 10:00:00'),
(8, 7, 'Junior Architect', 'Prepare design drawings and 3D models for residential and public projects.', 'Full-Time', 'Architecture', 3.0, 4, 38000, 'Dhaka (Dhanmondi)', '2026-12-08', 'Open', '2026-08-23 10:00:00'),
(9, 8, 'Supply Chain Executive', 'Manage inbound/outbound flows, vendor follow-up and warehouse reporting.', 'Full-Time', 'Any', 2.9, 4, 42000, 'Dhaka (Tejgaon)', '2026-12-18', 'Open', '2026-08-30 10:00:00'),
(10, 5, 'Site Engineer - Solar Civil Works', 'Supervise foundation and structural works at solar installation sites.', 'Full-Time', 'Civil & Environmental Engineering', 3.0, 4, 45000, 'Field-based (Rajshahi)', '2026-12-22', 'Open', '2026-08-21 10:00:00'),
(11, 1, 'Software Engineering Intern', 'Three-month internship contributing to real client projects.', 'Internship', 'Computer Science & Engineering', 2.8, 3, 15000, 'Dhaka (Gulshan)', '2026-11-28', 'Open', '2026-08-21 10:00:00'),
(12, 6, 'Data Science Intern', 'Support the analytics team with data cleaning, modelling and reporting.', 'Internship', 'Computer Science & Engineering', 3.0, 3, 20000, 'Dhaka (Banani)', '2026-11-30', 'Open', '2026-08-27 10:00:00'),
(13, 2, 'Finance Intern', 'Assist with reconciliation, reporting and payment operations.', 'Internship', 'Business Administration', 2.8, 3, 12000, 'Dhaka (Motijheel)', '2026-11-25', 'Open', '2026-08-22 10:00:00'),
(14, 3, 'Telecom Network Intern', 'Shadow network engineers on site surveys and performance tests.', 'Internship', 'Electrical & Electronic Engineering', 2.8, 2, 10000, 'Dhaka (Mohakhali)', '2026-11-27', 'Open', '2026-08-30 10:00:00'),
(15, 7, 'Architectural Intern', 'Assist with drafting, model making and site documentation.', 'Internship', 'Architecture', 2.7, 2, 8000, 'Dhaka (Dhanmondi)', '2026-11-26', 'Open', '2026-08-30 10:00:00'),
(16, 8, 'Operations Intern', 'Work with the dispatch team on route planning and delivery tracking.', 'Internship', 'Any', 2.5, 2, 10000, 'Dhaka (Tejgaon)', '2026-12-01', 'Open', '2026-08-21 10:00:00');

-- fulltime_jobs
INSERT INTO fulltime_jobs (job_id, benefits, probation_months) VALUES
(1, 'Health insurance, performance bonus, flexible hours', 3),
(2, 'Health insurance, 2 festival bonuses, provident fund', 3),
(3, 'Health insurance, 2 festival bonuses, provident fund', 3),
(4, 'Health insurance, performance bonus, flexible hours', 3),
(5, 'Life and health insurance, annual bonus, learning budget', 3),
(6, 'Health insurance, performance bonus, flexible hours', 3),
(7, 'Medical allowance, 2 festival bonuses, transport allowance', 3),
(8, 'Life and health insurance, annual bonus, learning budget', 3),
(9, 'Health insurance, performance bonus, flexible hours', 6),
(10, 'Health insurance, performance bonus, flexible hours', 6);

-- internship_jobs
INSERT INTO internship_jobs (job_id, duration_months, conversion_possible) VALUES
(11, 3, 1),
(12, 6, 1),
(13, 3, 1),
(14, 3, 0),
(15, 3, 0),
(16, 3, 1);

-- applications
INSERT INTO applications (application_id, student_id, job_id, status, applied_date, interview_date, interview_notes, offer_salary) VALUES
(1, 2111002042, 2, 'Applied', '2026-11-02', NULL, NULL, NULL),
(2, 2121004042, 2, 'Hired', '2026-10-02', '2026-10-28 15:00:00', 'Cleared all rounds; offer accepted.', 53000),
(3, 2211005042, 2, 'Rejected', '2026-10-12', '2026-10-23 10:00:00', 'Rejected after interview.', NULL),
(4, 2211006042, 2, 'Applied', '2026-11-02', NULL, NULL, NULL),
(5, 2111011042, 3, 'Shortlisted', '2026-10-15', '2026-11-22 14:30:00', 'Shortlisted from CV screening; interview scheduled.', NULL),
(6, 2121012042, 3, 'Hired', '2026-09-23', '2026-10-16 11:30:00', 'Cleared all rounds; offer accepted.', 45000),
(7, 2111011042, 4, 'Hired', '2026-09-27', '2026-10-20 14:30:00', 'Cleared all rounds; offer accepted.', 60000),
(8, 2111008042, 5, 'Interviewed', '2026-09-17', '2026-09-27 10:00:00', 'Interview rounds completed; final decision pending.', NULL),
(9, 2211010042, 5, 'Hired', '2026-09-11', '2026-10-05 14:00:00', 'Cleared all rounds; offer accepted.', 54000),
(10, 2111017042, 8, 'Shortlisted', '2026-10-13', '2026-11-23 10:30:00', 'Shortlisted from CV screening; interview scheduled.', NULL),
(11, 2111002042, 9, 'Hired', '2026-09-27', '2026-10-14 11:00:00', 'Cleared all rounds; offer accepted.', 44000),
(12, 2111015042, 9, 'Shortlisted', '2026-10-25', '2026-11-26 10:30:00', 'Shortlisted from CV screening; interview scheduled.', NULL),
(13, 2111019042, 9, 'Rejected', '2026-09-24', '2026-10-02 10:00:00', 'Rejected after interview.', NULL),
(14, 2111019042, 10, 'Hired', '2026-09-14', '2026-10-12 15:00:00', 'Cleared all rounds; offer accepted.', 45000),
(15, 2111001042, 11, 'Applied', '2026-10-30', NULL, NULL, NULL),
(16, 2121003042, 11, 'Hired', '2026-09-10', '2026-10-07 10:30:00', 'Cleared all rounds; offer accepted.', 18000),
(17, 2121004042, 11, 'Interviewed', '2026-09-05', '2026-09-13 14:30:00', 'Interview rounds completed; final decision pending.', NULL),
(18, 2211005042, 11, 'Interviewed', '2026-09-14', '2026-10-01 10:30:00', 'Interview rounds completed; final decision pending.', NULL),
(19, 2121004042, 12, 'Rejected', '2026-09-10', '2026-09-20 10:30:00', 'Rejected after interview.', NULL),
(20, 2211006042, 12, 'Shortlisted', '2026-11-02', '2026-11-26 11:00:00', 'Shortlisted from CV screening; interview scheduled.', NULL),
(21, 2211013042, 13, 'Rejected', '2026-10-07', '2026-10-18 11:30:00', 'Rejected after interview.', NULL),
(22, 2221014042, 13, 'Applied', '2026-10-20', NULL, NULL, NULL),
(23, 2111008042, 14, 'Applied', '2026-11-05', NULL, NULL, NULL),
(24, 2121009042, 14, 'Rejected', '2026-10-11', '2026-10-19 14:30:00', 'Rejected after interview.', NULL),
(25, 2211010042, 14, 'Applied', '2026-11-01', NULL, NULL, NULL),
(26, 2111017042, 15, 'Rejected', '2026-09-13', NULL, 'Did not meet screening criteria.', NULL),
(27, 2211018042, 15, 'Applied', '2026-10-24', NULL, NULL, NULL),
(28, 2111001042, 16, 'Rejected', '2026-09-26', NULL, 'Did not meet screening criteria.', NULL),
(29, 2111002042, 16, 'Applied', '2026-10-21', NULL, NULL, NULL),
(30, 2111015042, 16, 'Interviewed', '2026-09-20', '2026-10-01 15:00:00', 'Interview rounds completed; final decision pending.', NULL),
(31, 2111019042, 16, 'Applied', '2026-11-11', NULL, NULL, NULL),
(32, 2121003042, 16, 'Interviewed', '2026-09-06', '2026-09-18 14:00:00', 'Interview rounds completed; final decision pending.', NULL),
(33, 2121009042, 16, 'Shortlisted', '2026-10-11', '2026-11-23 10:30:00', 'Shortlisted from CV screening; interview scheduled.', NULL),
(34, 2121012042, 16, 'Applied', '2026-11-03', NULL, NULL, NULL),
(35, 2121016042, 16, 'Rejected', '2026-10-04', NULL, 'Did not meet screening criteria.', NULL),
(36, 2121020042, 16, 'Interviewed', '2026-09-21', '2026-09-28 15:30:00', 'Interview rounds completed; final decision pending.', NULL),
(37, 2211005042, 16, 'Hired', '2026-09-11', '2026-10-02 14:30:00', 'Cleared all rounds; offer accepted.', 13000),
(38, 2211013042, 16, 'Shortlisted', '2026-10-30', '2026-11-16 14:30:00', 'Shortlisted from CV screening; interview scheduled.', NULL),
(39, 2211018042, 16, 'Rejected', '2026-10-04', '2026-10-16 11:00:00', 'Rejected after interview.', NULL),
(40, 2221007042, 16, 'Interviewed', '2026-09-05', '2026-09-16 14:00:00', 'Interview rounds completed; final decision pending.', NULL),
(41, 2221014042, 16, 'Applied', '2026-10-22', NULL, NULL, NULL);

-- interviews
INSERT INTO interviews (interview_id, application_id, interview_name, interview_type, interview_round, scheduled_date, actual_date, duration_minutes, score, feedback) VALUES
(1, 2, 'Technical Interview', 'Phone', 1, '2026-10-12 15:00:00', '2026-10-12 15:05:00', 45, 94.02, 'Strong fundamentals and clear communication; recommended to proceed.'),
(2, 2, 'HR Interview', 'On-site', 2, '2026-10-19 15:00:00', '2026-10-19 15:00:00', 60, 89.61, 'Strong fundamentals and clear communication; recommended to proceed.'),
(3, 2, 'Final Interview', 'On-site', 3, '2026-10-28 15:00:00', '2026-10-28 15:00:00', 60, 93.49, 'Strong fundamentals and clear communication; recommended to proceed.'),
(4, 3, 'Technical Interview', 'Online', 1, '2026-10-23 10:00:00', '2026-10-23 10:10:00', 40, 50.69, 'Did not meet the required technical depth for this role.'),
(5, 5, 'Technical Interview', 'On-site', 1, '2026-11-22 14:30:00', NULL, 45, NULL, NULL),
(6, 6, 'Technical Interview', 'Online', 1, '2026-09-30 11:30:00', '2026-09-30 11:30:00', 40, 85.62, 'Strong fundamentals and clear communication; recommended to proceed.'),
(7, 6, 'HR Interview', 'On-site', 2, '2026-10-05 14:30:00', '2026-10-05 14:35:00', 30, 86.03, 'Strong fundamentals and clear communication; recommended to proceed.'),
(8, 6, 'Final Interview', 'On-site', 3, '2026-10-16 11:30:00', '2026-10-16 11:30:00', 30, 85.1, 'Strong fundamentals and clear communication; recommended to proceed.'),
(9, 7, 'Technical Interview', 'Online', 1, '2026-10-04 10:00:00', '2026-10-04 10:05:00', 40, 81.82, 'Strong fundamentals and clear communication; recommended to proceed.'),
(10, 7, 'HR Interview', 'On-site', 2, '2026-10-11 15:30:00', '2026-10-11 15:30:00', 25, 85.59, 'Strong fundamentals and clear communication; recommended to proceed.'),
(11, 7, 'Final Interview', 'On-site', 3, '2026-10-20 14:30:00', '2026-10-20 14:30:00', 30, 88.11, 'Strong fundamentals and clear communication; recommended to proceed.'),
(12, 8, 'Technical Interview', 'Phone', 1, '2026-09-27 10:00:00', '2026-09-27 10:00:00', 45, 72.08, 'Good potential; waiting for the panel decision.'),
(13, 9, 'Technical Interview', 'Online', 1, '2026-09-21 15:00:00', '2026-09-21 15:00:00', 40, 93.71, 'Strong fundamentals and clear communication; recommended to proceed.'),
(14, 9, 'HR Interview', 'On-site', 2, '2026-09-29 11:00:00', '2026-09-29 11:00:00', 25, 92.31, 'Strong fundamentals and clear communication; recommended to proceed.'),
(15, 9, 'Final Interview', 'Online', 3, '2026-10-05 14:00:00', '2026-10-05 14:05:00', 60, 87.84, 'Strong fundamentals and clear communication; recommended to proceed.'),
(16, 10, 'Technical Interview', 'Online', 1, '2026-11-23 10:30:00', NULL, 30, NULL, NULL),
(17, 11, 'Technical Interview', 'Online', 1, '2026-10-08 15:30:00', '2026-10-08 15:40:00', 30, 79.5, 'Strong fundamentals and clear communication; recommended to proceed.'),
(18, 11, 'HR Interview', 'On-site', 2, '2026-10-14 11:00:00', '2026-10-14 11:10:00', 60, 88.86, 'Strong fundamentals and clear communication; recommended to proceed.'),
(19, 12, 'Technical Interview', 'Phone', 1, '2026-11-26 10:30:00', NULL, 30, NULL, NULL),
(20, 13, 'Technical Interview', 'Phone', 1, '2026-10-02 10:00:00', '2026-10-02 10:05:00', 60, 37.81, 'Did not meet the required technical depth for this role.'),
(21, 14, 'Technical Interview', 'On-site', 1, '2026-09-26 15:30:00', '2026-09-26 15:30:00', 30, 86.46, 'Strong fundamentals and clear communication; recommended to proceed.'),
(22, 14, 'HR Interview', 'On-site', 2, '2026-10-02 15:00:00', '2026-10-02 15:10:00', 30, 88.68, 'Strong fundamentals and clear communication; recommended to proceed.'),
(23, 14, 'Final Interview', 'Online', 3, '2026-10-12 15:00:00', '2026-10-12 15:00:00', 40, 94.97, 'Strong fundamentals and clear communication; recommended to proceed.'),
(24, 16, 'Screening Call', 'Online', 1, '2026-09-21 11:00:00', '2026-09-21 11:00:00', 30, 84.94, 'Strong fundamentals and clear communication; recommended to proceed.'),
(25, 16, 'Technical Interview', 'On-site', 2, '2026-09-28 11:00:00', '2026-09-28 11:00:00', 30, 85.67, 'Strong fundamentals and clear communication; recommended to proceed.'),
(26, 16, 'HR Interview', 'On-site', 3, '2026-10-07 10:30:00', '2026-10-07 10:40:00', 25, 92.88, 'Strong fundamentals and clear communication; recommended to proceed.'),
(27, 17, 'Screening Call', 'Online', 1, '2026-09-13 14:30:00', '2026-09-13 14:40:00', 40, 73.92, 'Good potential; waiting for the panel decision.'),
(28, 18, 'Screening Call', 'On-site', 1, '2026-09-23 10:30:00', '2026-09-23 10:35:00', 25, 76.18, 'Good potential; waiting for the panel decision.'),
(29, 18, 'Technical Interview', 'Online', 2, '2026-10-01 10:30:00', '2026-10-01 10:30:00', 30, 83.93, 'Good potential; waiting for the panel decision.'),
(30, 19, 'Screening Call', 'On-site', 1, '2026-09-20 10:30:00', '2026-09-20 10:40:00', 40, 49.4, 'Did not meet the required technical depth for this role.'),
(31, 20, 'Screening Call', 'Online', 1, '2026-11-26 11:00:00', NULL, 45, NULL, NULL),
(32, 21, 'Screening Call', 'Phone', 1, '2026-10-18 11:30:00', '2026-10-18 11:35:00', 60, 46.88, 'Did not meet the required technical depth for this role.'),
(33, 24, 'Screening Call', 'Online', 1, '2026-10-19 14:30:00', '2026-10-19 14:30:00', 60, 54.61, 'Did not meet the required technical depth for this role.'),
(34, 30, 'Screening Call', 'Phone', 1, '2026-10-01 15:00:00', '2026-10-01 15:05:00', 30, 77.35, 'Good potential; waiting for the panel decision.'),
(35, 32, 'Screening Call', 'Phone', 1, '2026-09-18 14:00:00', '2026-09-18 14:10:00', 25, 67.91, 'Good potential; waiting for the panel decision.'),
(36, 33, 'Screening Call', 'Online', 1, '2026-11-23 10:30:00', NULL, 45, NULL, NULL),
(37, 36, 'Screening Call', 'Online', 1, '2026-09-28 15:30:00', '2026-09-28 15:30:00', 40, 75.56, 'Good potential; waiting for the panel decision.'),
(38, 37, 'Screening Call', 'Online', 1, '2026-09-20 11:00:00', '2026-09-20 11:05:00', 60, 79.34, 'Strong fundamentals and clear communication; recommended to proceed.'),
(39, 37, 'Technical Interview', 'Online', 2, '2026-09-27 14:30:00', '2026-09-27 14:35:00', 25, 78.46, 'Strong fundamentals and clear communication; recommended to proceed.'),
(40, 37, 'HR Interview', 'Online', 3, '2026-10-02 14:30:00', '2026-10-02 14:30:00', 45, 89.76, 'Strong fundamentals and clear communication; recommended to proceed.'),
(41, 38, 'Screening Call', 'Online', 1, '2026-11-16 14:30:00', NULL, 45, NULL, NULL),
(42, 39, 'Screening Call', 'Online', 1, '2026-10-16 11:00:00', '2026-10-16 11:00:00', 60, 42.78, 'Did not meet the required technical depth for this role.'),
(43, 40, 'Screening Call', 'Online', 1, '2026-09-16 14:00:00', '2026-09-16 14:00:00', 60, 84.06, 'Good potential; waiting for the panel decision.');

-- placement_records
INSERT INTO placement_records (placement_id, student_id, company_id, job_title, join_date, salary_package, employment_type, academic_year, created_date) VALUES
(1, 2121004042, 1, 'Backend Developer (PHP/MySQL)', '2027-01-16', 53000, 'Full-Time', '2026-2027', '2026-10-30 15:00:00'),
(2, 2121012042, 2, 'Management Trainee Officer', '2027-01-19', 45000, 'Full-Time', '2026-2027', '2026-10-18 15:00:00'),
(3, 2111011042, 6, 'Data Analyst', '2027-01-24', 60000, 'Full-Time', '2026-2027', '2026-10-22 15:00:00'),
(4, 2211010042, 3, 'Network Engineer', '2027-01-22', 54000, 'Full-Time', '2026-2027', '2026-10-07 15:00:00'),
(5, 2111002042, 8, 'Supply Chain Executive', '2027-01-08', 44000, 'Full-Time', '2026-2027', '2026-10-16 15:00:00'),
(6, 2111019042, 5, 'Site Engineer - Solar Civil Works', '2027-01-22', 45000, 'Full-Time', '2026-2027', '2026-10-14 15:00:00'),
(7, 2121003042, 1, 'Software Engineering Intern', '2026-12-02', 18000, 'Internship', '2026-2027', '2026-10-09 15:00:00'),
(8, 2211005042, 8, 'Operations Intern', '2026-12-16', 13000, 'Internship', '2026-2027', '2026-10-04 15:00:00');

-- events
INSERT INTO events (event_id, company_id, title, description, event_type, event_date, location, max_attendees, created_date) VALUES
(1, 1, 'Nexora Tech Talk: Building Scalable APIs', 'Engineers from Nexora walk through designing and scaling REST APIs, followed by Q&A.', 'Seminar', '2026-10-14 15:00:00', 'NSU Auditorium', 120, '2026-09-23 12:00:00'),
(2, 6, 'Data Science Bootcamp', 'Hands-on one-day bootcamp on data cleaning and basic forecasting with Python.', 'Workshop', '2026-10-24 10:00:00', 'Lab 5, Block B', 40, '2026-09-17 12:00:00'),
(3, 2, 'Jamuna Fintech Career Info Session', 'Overview of fintech careers, the management trainee programme and how to apply.', 'Info Session', '2026-11-05 14:00:00', 'Room 301, Block A', 80, '2026-09-16 12:00:00'),
(4, 3, 'BlueDelta Campus Recruitment Drive', 'Walk-in screening for network engineer and intern positions.', 'Recruitment Drive', '2026-11-09 10:00:00', 'Student Plaza', 150, '2026-09-13 12:00:00'),
(5, 5, 'Green Energy Careers Seminar', 'Talk on solar and grid careers, with a short project showcase.', 'Seminar', '2026-11-19 15:00:00', 'Room 215, Block C', 70, '2026-09-13 12:00:00'),
(6, 8, 'Orbit Logistics Operations Day', 'Warehouse and dispatch walkthrough plus an operations case challenge.', 'Workshop', '2026-11-26 11:00:00', 'Seminar Hall 2', 50, '2026-09-22 12:00:00'),
(7, 7, 'Urban Canvas Portfolio Review Day', 'Architecture students get one-to-one portfolio feedback from studio architects.', 'Workshop', '2026-12-03 10:00:00', 'Design Studio, Block D', 30, '2026-09-28 12:00:00'),
(8, 1, 'Nexora Code Sprint Competition', 'Three-hour team coding contest with internship interview fast-track for finalists.', 'Competition', '2026-12-12 09:00:00', 'Lab 3, Block B', 60, '2026-09-28 12:00:00');

-- event_attendance
INSERT INTO event_attendance (attendance_id, student_id, event_id, attended_status, feedback, registration_date) VALUES
(1, 2221007042, 1, 'Attended', NULL, '2026-09-29 13:00:00'),
(2, 2211013042, 1, 'Attended', 'Great speakers and well organised.', '2026-10-03 12:00:00'),
(3, 2111001042, 1, 'Attended', 'Good content, would like more hands-on time.', '2026-09-28 15:00:00'),
(4, 2111011042, 1, 'Attended', NULL, '2026-10-10 11:00:00'),
(5, 2211006042, 1, 'Cancelled', NULL, '2026-10-05 14:00:00'),
(6, 2121012042, 1, 'Attended', NULL, '2026-09-24 12:00:00'),
(7, 2221014042, 1, 'Attended', NULL, '2026-09-26 14:00:00'),
(8, 2121020042, 1, 'Attended', 'Very useful session, learned a lot.', '2026-10-08 13:00:00'),
(9, 2111002042, 1, 'Attended', NULL, '2026-10-10 13:00:00'),
(10, 2121009042, 2, 'Attended', 'Great speakers and well organised.', '2026-10-05 05:00:00'),
(11, 2121016042, 2, 'Absent', NULL, '2026-10-10 08:00:00'),
(12, 2111015042, 2, 'Attended', 'Good content, would like more hands-on time.', '2026-10-12 05:00:00'),
(13, 2211005042, 2, 'Cancelled', NULL, '2026-10-15 06:00:00'),
(14, 2211006042, 2, 'Attended', 'Very useful session, learned a lot.', '2026-10-17 06:00:00'),
(15, 2121012042, 2, 'Attended', 'Very useful session, learned a lot.', '2026-10-12 10:00:00'),
(16, 2221007042, 2, 'Attended', 'Great speakers and well organised.', '2026-10-08 08:00:00'),
(17, 2111017042, 2, 'Absent', NULL, '2026-10-09 10:00:00'),
(18, 2221014042, 2, 'Attended', 'Very useful session, learned a lot.', '2026-10-15 07:00:00'),
(19, 2121004042, 2, 'Attended', 'Very useful session, learned a lot.', '2026-10-19 08:00:00'),
(20, 2211013042, 2, 'Attended', NULL, '2026-10-17 08:00:00'),
(21, 2221007042, 3, 'Attended', NULL, '2026-10-25 09:00:00'),
(22, 2111002042, 3, 'Attended', 'Very useful session, learned a lot.', '2026-10-18 12:00:00'),
(23, 2121020042, 3, 'Attended', NULL, '2026-10-26 12:00:00'),
(24, 2111008042, 3, 'Attended', NULL, '2026-11-01 11:00:00'),
(25, 2121009042, 3, 'Attended', NULL, '2026-10-31 13:00:00'),
(26, 2121003042, 3, 'Absent', NULL, '2026-10-23 11:00:00'),
(27, 2111001042, 3, 'Attended', NULL, '2026-10-29 14:00:00'),
(28, 2221014042, 3, 'Attended', 'Very useful session, learned a lot.', '2026-10-22 09:00:00'),
(29, 2211005042, 3, 'Attended', NULL, '2026-10-16 12:00:00'),
(30, 2211013042, 3, 'Attended', NULL, '2026-10-28 10:00:00'),
(31, 2111017042, 3, 'Attended', 'Great speakers and well organised.', '2026-10-30 13:00:00'),
(32, 2121012042, 4, 'Attended', 'Good content, would like more hands-on time.', '2026-10-28 09:00:00'),
(33, 2121003042, 4, 'Cancelled', NULL, '2026-10-23 07:00:00'),
(34, 2211005042, 4, 'Attended', NULL, '2026-10-24 05:00:00'),
(35, 2211018042, 4, 'Attended', 'Great speakers and well organised.', '2026-10-21 08:00:00'),
(36, 2211013042, 4, 'Attended', 'Very useful session, learned a lot.', '2026-10-24 07:00:00'),
(37, 2121004042, 4, 'Attended', NULL, '2026-10-24 06:00:00'),
(38, 2111019042, 4, 'Attended', 'Great speakers and well organised.', '2026-11-05 09:00:00'),
(39, 2121016042, 4, 'Attended', 'Great speakers and well organised.', '2026-10-24 09:00:00'),
(40, 2111001042, 4, 'Cancelled', NULL, '2026-10-28 07:00:00'),
(41, 2211006042, 4, 'Attended', 'Very useful session, learned a lot.', '2026-10-31 05:00:00'),
(42, 2111015042, 4, 'Absent', NULL, '2026-10-26 05:00:00'),
(43, 2111011042, 5, 'Registered', NULL, '2026-11-07 12:00:00'),
(44, 2121020042, 5, 'Registered', NULL, '2026-11-12 15:00:00'),
(45, 2121016042, 5, 'Registered', NULL, '2026-11-01 14:00:00'),
(46, 2121004042, 5, 'Registered', NULL, '2026-11-08 14:00:00'),
(47, 2121009042, 5, 'Registered', NULL, '2026-11-11 15:00:00'),
(48, 2111015042, 5, 'Registered', NULL, '2026-11-13 15:00:00'),
(49, 2211006042, 5, 'Registered', NULL, '2026-11-03 14:00:00'),
(50, 2111017042, 5, 'Registered', NULL, '2026-11-15 10:00:00'),
(51, 2211010042, 5, 'Registered', NULL, '2026-11-10 10:00:00'),
(52, 2221007042, 5, 'Registered', NULL, '2026-11-08 14:00:00'),
(53, 2121003042, 5, 'Registered', NULL, '2026-11-04 15:00:00'),
(54, 2211013042, 6, 'Cancelled', NULL, '2026-11-07 10:00:00'),
(55, 2121009042, 6, 'Registered', NULL, '2026-11-12 11:00:00'),
(56, 2111002042, 6, 'Registered', NULL, '2026-11-11 10:00:00'),
(57, 2111019042, 6, 'Cancelled', NULL, '2026-11-17 08:00:00'),
(58, 2121003042, 6, 'Registered', NULL, '2026-11-20 09:00:00'),
(59, 2211005042, 6, 'Registered', NULL, '2026-11-22 07:00:00'),
(60, 2111015042, 6, 'Registered', NULL, '2026-11-14 09:00:00'),
(61, 2221014042, 6, 'Registered', NULL, '2026-11-11 10:00:00'),
(62, 2121012042, 6, 'Registered', NULL, '2026-11-22 08:00:00'),
(63, 2111001042, 6, 'Registered', NULL, '2026-11-17 08:00:00'),
(64, 2211006042, 6, 'Registered', NULL, '2026-11-21 06:00:00'),
(65, 2211018042, 6, 'Registered', NULL, '2026-11-15 07:00:00'),
(66, 2221007042, 6, 'Registered', NULL, '2026-11-19 08:00:00'),
(67, 2121016042, 6, 'Registered', NULL, '2026-11-14 07:00:00'),
(68, 2111015042, 7, 'Cancelled', NULL, '2026-11-17 10:00:00'),
(69, 2111019042, 7, 'Registered', NULL, '2026-11-23 10:00:00'),
(70, 2121020042, 7, 'Registered', NULL, '2026-11-15 10:00:00'),
(71, 2111001042, 7, 'Registered', NULL, '2026-11-21 09:00:00'),
(72, 2221007042, 7, 'Registered', NULL, '2026-11-15 05:00:00'),
(73, 2111008042, 7, 'Registered', NULL, '2026-11-27 10:00:00'),
(74, 2121004042, 7, 'Registered', NULL, '2026-11-19 09:00:00'),
(75, 2121012042, 7, 'Registered', NULL, '2026-11-23 08:00:00'),
(76, 2121016042, 7, 'Registered', NULL, '2026-11-15 07:00:00'),
(77, 2211010042, 7, 'Registered', NULL, '2026-11-13 05:00:00'),
(78, 2111017042, 8, 'Registered', NULL, '2026-12-04 09:00:00'),
(79, 2221007042, 8, 'Registered', NULL, '2026-11-28 09:00:00'),
(80, 2111019042, 8, 'Registered', NULL, '2026-11-25 04:00:00'),
(81, 2121003042, 8, 'Registered', NULL, '2026-12-02 04:00:00'),
(82, 2211013042, 8, 'Registered', NULL, '2026-12-03 09:00:00'),
(83, 2211005042, 8, 'Registered', NULL, '2026-11-23 07:00:00'),
(84, 2111002042, 8, 'Registered', NULL, '2026-12-08 08:00:00'),
(85, 2121016042, 8, 'Cancelled', NULL, '2026-11-27 07:00:00'),
(86, 2111011042, 8, 'Registered', NULL, '2026-11-26 08:00:00');

