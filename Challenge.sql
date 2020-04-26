-- Schema:
-- Creating tables for PH-EmployeeDB
CREATE TABLE departments (
     dept_no VARCHAR(4) NOT NULL,
     dept_name VARCHAR(40) NOT NULL,
     PRIMARY KEY (dept_no),
     UNIQUE (dept_name)
);
CREATE TABLE employees (
	emp_no INT NOT NULL,
     birth_date DATE NOT NULL,
     first_name VARCHAR NOT NULL,
     last_name VARCHAR NOT NULL,
     gender VARCHAR NOT NULL,
     hire_date DATE NOT NULL,
     PRIMARY KEY (emp_no)
);
CREATE TABLE dept_manager (
dept_no VARCHAR(4) NOT NULL,
	emp_no INT NOT NULL,
	from_date DATE NOT NULL,
	to_date DATE NOT NULL,
	FOREIGN KEY (emp_no) REFERENCES employees (emp_no),
	FOREIGN KEY (dept_no) REFERENCES departments (dept_no),
	PRIMARY KEY (emp_no, dept_no)
);
CREATE TABLE salaries (
  emp_no INT NOT NULL,
  salary INT NOT NULL,
  from_date DATE NOT NULL,
  to_date DATE NOT NULL,
  FOREIGN KEY (emp_no) REFERENCES employees (emp_no),
  PRIMARY KEY (emp_no)
);
CREATE TABLE dept_employees (
  emp_no INT NOT NULL,
  dept_no VARCHAR(4) NOT NULL,
  from_date DATE NOT NULL,
  to_date DATE NOT NULL,
  FOREIGN KEY (emp_no) REFERENCES employees (emp_no),
  FOREIGN KEY (dept_no) REFERENCES departments (dept_no),
  PRIMARY KEY (emp_no, dept_no)
);
CREATE TABLE titles (
  emp_no INT NOT NULL,
  title VARCHAR(20) NOT NULL,
  from_date DATE NOT NULL,
  to_date DATE NOT NULL,
  FOREIGN KEY (emp_no) REFERENCES employees (emp_no),
  PRIMARY KEY (emp_no)
);

-- Queries:
-- Create table retirement_info for all retirees (both past and current):
SELECT emp_no, first_name, last_name
INTO retirement_info
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1955-12-31')
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');

-- Create table current_emp for current employees that about to retire
SELECT ri.emp_no,
	ri.first_name,
	ri.last_name,
	de.to_date 
INTO current_emp
FROM retirement_info as ri
LEFT JOIN dept_employees as de
ON ri.emp_no = de.emp_no
WHERE de.to_date = ('9999-01-01'); --to filter on current employees

-- Table 1: Number of Retiring Employees by Title
-- Partition the data to show only most recent title per employee
SELECT 	ce.emp_no,
 		ce.first_name,
 		ce.last_name,
		tmp.title,
		tmp.from_date,
  		s.salary
INTO current_emp_by_titles
FROM
	 (	SELECT *, ROW_NUMBER() 
	  	OVER
			(PARTITION BY (ti.emp_no)
			ORDER BY ti.to_date DESC) rn
		FROM titles AS ti
	 ) AS tmp
INNER JOIN current_emp AS ce ON ce.emp_no = tmp.emp_no
INNER JOIN salaries AS s ON s.emp_no = tmp.emp_no	 
WHERE tmp.rn = 1
ORDER BY ce.emp_no;

-- Group by titles:
SELECT title, COUNT(emp_no)
INTO count_emp_by_titles
FROM current_emp_by_titles
GROUP BY title;

-- Table 2: Mentorship Eligibility
SELECT 	e.emp_no,
 		e.first_name,
 		e.last_name,
		tmp.title,
		tmp.from_date,
  		tmp.to_date
INTO mentor_eligibility
FROM
	 (	SELECT *, ROW_NUMBER() 
	  	OVER
			(PARTITION BY (ti.emp_no)
			ORDER BY ti.to_date DESC) rn
		FROM titles AS ti
	 ) AS tmp
INNER JOIN employees AS e ON e.emp_no = tmp.emp_no
INNER JOIN dept_employees AS de ON e.emp_no = de.emp_no
WHERE (tmp.rn = 1)
	AND (e.birth_date BETWEEN '1965-01-01' AND '1965-12-31') --to filter employees born in 1065 only
	AND (de.to_date = ('9999-01-01')) --to filter only current employees
ORDER BY e.emp_no;

SELECT * FROM mentor_eligibility;