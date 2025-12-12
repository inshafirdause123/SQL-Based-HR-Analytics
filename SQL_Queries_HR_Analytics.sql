create database hr_analytics;

DESCRIBE hr_analytics;

select * from hr_analytics;

ALTER TABLE hr_analytics
CHANGE COLUMN `ï»¿EmpID` emp_id TEXT;

-- Find total number of employees and total number of employees who left (attrition = Yes).
select distinct count(emp_id) as total_emp , sum(case when attrition ='yes' then 1 else 0 end ) as emp_left
from hr_analytics;

-- List all employees who have attrited along with their Age, Department, and JobRole.
select distinct emp_id , age , department , jobrole
from hr_analytics
where attrition = 'Yes';

-- Find the average MonthlyIncome of all employees.
select round(avg(monthlyincome),2) as avg_emp
from hr_analytics;

-- Get the count of employees in each Department.
select department , count(department) as each_dep
from hr_analytics
group by department;

-- Calculate attrition count and attrition rate for each Department.
SELECT distinct
    department,
    COUNT(*) AS total_emp,
    ROUND((SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*)) * 100,2) AS left_emp,
    ROUND((SUM(CASE WHEN attrition = 'No' THEN 1 ELSE 0 END) / COUNT(*)) * 100,2) AS stay_emp
FROM hr_analytics
GROUP BY department
ORDER BY stay_emp;

-- Find the top 5 employees who live farthest from the company using DistanceFromHome.
SELECT emp_id, distancefromhome
FROM hr_analytics
ORDER BY distancefromhome DESC
LIMIT 5;

-- List the average JobSatisfaction score for each JobRole.
select jobrole , round(avg(jobsatisfaction),2) as avg_emp
from hr_analytics
group by jobrole;

-- Find employees who work overtime but have low WorkLifeBalance (≤2).
select emp_id 
from hr_analytics
where overtime ='Yes' and worklifebalance <=2;

-- Calculate average MonthlyIncome by EducationField.
select educationfield , round(avg(monthlyincome),2) as avg_edu_field
from hr_analytics
group by educationfield;

-- Find number of employees in each AgeGroup.
SELECT  age, COUNT(emp_id) AS emp_count
FROM hr_analytics
GROUP BY age
ORDER BY age;

-- Calculate attrition rate for each AgeGroup.
SELECT age,ROUND((SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*)) * 100,2) AS left_percent,
    ROUND((SUM(CASE WHEN attrition = 'No' THEN 1 ELSE 0 END) / COUNT(*)) * 100,2) AS stay_percent
FROM hr_analytics
GROUP BY age
ORDER BY age;

-- Find the average salary difference between attrited and non-attrited employees.
SELECT AVG(CASE WHEN attrition = 'Yes' THEN monthlyincome END) AS avg_attrited_salary, AVG(CASE WHEN attrition = 'No' THEN monthlyincome END) AS avg_non_attrited_salary,
    AVG(CASE WHEN attrition = 'Yes' THEN monthlyincome END) - AVG(CASE WHEN attrition = 'No' THEN monthlyincome END) AS avg_salary_difference
FROM hr_analytics;

-- Which JobRole has the highest attrition count? Rank them.
SELECT jobrole, SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
    RANK() OVER (ORDER BY SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) DESC) AS attrition_rank
FROM hr_analytics
GROUP BY jobrole
ORDER BY attrition_count DESC;

-- Find average TotalWorkingYears by Department.
select department , avg(totalworkingyears) as avg_working_year
from hr_analytics
group by department
order by avg_working_year desc;

-- Analyze promotion stability: Find employees with > 5 years since last promotion.
select emp_id , department , jobrole ,YearsSinceLastPromotion
from hr_analytics
where YearsSinceLastPromotion > 5
order by YearsSinceLastPromotion desc;

-- Find the relationship between training and attrition: Count how many employees with TrainingTimesLastYear < 2 have attrited.

select  trainingtimeslastyear ,count(emp_id) as total_emp
from hr_analytics
where attrition = 'yes' and trainingtimeslastyear <2
group by trainingtimeslastyear ;

-- Find the average YearsAtCompany for people who left vs stayed.
select (avg(case when attrition = 'yes' then yearsatcompany end)) as left_emp ,
              (avg(case when attrition = 'no' then yearsatcompany end)) as stay_emp
              from hr_analytics;
 
 -- Is manager consistency important? Find attrition count by YearsWithCurrManager group.
 select department , count(*) as total_emp, (count(case when attrition ='yes' then YearsWithCurrManager end )) as left_emp_as_man,
                 (count(case when attrition ='no' then YearsWithCurrManager end )) as stay_emp_as_man
                 from hr_analytics
                 group by department;

-- Do high performers leave? Count attrition by PerformanceRating.
select department , count(*) as total_emp , (count(case when attrition ='yes' then  PerformanceRating end )) as left_per_rate,
                 (count(case when attrition ='no' then  PerformanceRating end )) as stay_per_rate
                 from hr_analytics
                 group by department ;
                 
-- Do salary hikes reduce attrition? Compare PercentSalaryHike between attrited vs retained employees.
SELECT AVG(CASE WHEN Attrition = 'Yes' THEN PercentSalaryHike END) AS avg_hike_attrited, 
AVG(CASE WHEN Attrition = 'No'  THEN PercentSalaryHike END) AS avg_hike_retained
FROM hr_analytics;

-- Find highest MonthlyIncome employee in each Department.
select department , max(MonthlyIncome) as high_income
from hr_analytics
group by department
order by high_income desc;

-- Rank employees by MonthlyIncome within each Department.
SELECT Department, EmployeeNumber, MonthlyIncome,
    RANK() OVER (PARTITION BY Department ORDER BY MonthlyIncome DESC) AS rank_emp
FROM hr_analytics;

-- Find the average JobSatisfaction score per Department using window functions.
select department , round(avg(JobSatisfaction), 1) as avg_satfis
from hr_analytics
group by department;

-- Find the top 3 highest-paid employees in each JobRole.
select jobrole ,  EmployeeNumber, MonthlyIncome, (dense_rank()over(partition by jobrole order by monthlyincome desc)) as high_paid_emp
from hr_analytics
limit 3;

-- calculate the overall attrition rate of the company.
WITH attrition_data AS (
                SELECT COUNT(*) AS total_employees, SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left
    FROM hr_analytics)
    
         SELECT employees_left, total_employees,
    ROUND((employees_left * 100.0) / total_employees, 2) AS attrition_rate_percent
FROM attrition_data;

-- Create a CTE that groups employees into experience buckets (0–2, 3–5, 6–10, 10+ years) and then compute attrition rate for each bucket.
WITH cte AS ( SELECT emp_id , TotalWorkingYears, attrition, CASE 
            WHEN TotalWorkingYears BETWEEN 0 AND 2 THEN '0-2'
            WHEN TotalWorkingYears BETWEEN 3 AND 5 THEN '3-5'
            WHEN TotalWorkingYears BETWEEN 6 AND 10 THEN '6-10'
            ELSE '10+' END AS experience
    FROM hr_analytics )
         SELECT experience, COUNT(*) AS total_emp, SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS left_emp,
    ROUND(SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS exp_rate
FROM cte
GROUP BY experience
ORDER BY exp_rate DESC;

                   
              


