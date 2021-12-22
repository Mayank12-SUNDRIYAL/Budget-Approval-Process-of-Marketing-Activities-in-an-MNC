
----CREATE TABLES-------------------------------
------------------------------------------------


CREATE TABLE BRANDS(
    brand_id CHAR (3),
    category CHAR (3) not null,
    brand_name VARCHAR2(20) not null,
    CONSTRAINT brand_id_pk PRIMARY KEY(brand_id));

SELECT * FROM brands;

CREATE TABLE BRAND_BUDGET (
    budget_code CHAR (7),
    brand_id CHAR(3) not null,
    year int not null ,
    budget_amount INT not null,
    CONSTRAINT budget_code_pk PRIMARY KEY(budget_code),
    CONSTRAINT brand_id_fk FOREIGN KEY(brand_id) REFERENCES BRANDS(brand_id));
    
SELECT * FROM brand_budget;

CREATE TABLE MARKETING_ACTIVITIES (
    activity_code CHAR (4),
    activity_name VARCHAR2 (40) not null,
    --description VARCHAR2 (40),
    CONSTRAINT activity_code_pk PRIMARY KEY(activity_code));
    
SELECT * FROM marketing_activities;
    
    
CREATE TABLE EMPLOYEE_TABLE (
    employee_id CHAR (6),
    last_name VARCHAR2 (20) not null ,
    first_name VARCHAR2 (20) not null,
    title VARCHAR2(20),
    email_address VARCHAR2 (30) not null,
    department VARCHAR2 (20) not null,
    CONSTRAINT employee_id_pk PRIMARY KEY(employee_id));
    
SELECT * FROM employee_table;
    
CREATE TABLE ACTIVITY_BUDGET (
    expense_code CHAR(12),
    budget_code CHAR (7) not null,
    activity_code CHAR (4) not null,
    expense_owner_emp char(6) not null,
    budget_request numeric(10,2) ,
    budget_approved numeric(10,2) ,
    CONSTRAINT expense_code_pk PRIMARY KEY(expense_code),
    CONSTRAINT ab_budget_code_fk FOREIGN KEY(budget_code) REFERENCES BRAND_BUDGET(budget_code),
    CONSTRAINT ab_activity_code_fk FOREIGN KEY(activity_code) REFERENCES MARKETING_ACTIVITIES(activity_code),
    CONSTRAINT ab_expense_owner_emp_fk FOREIGN KEY(expense_owner_emp) REFERENCES EMPLOYEE_TABLE(employee_id));

SELECT * FROM activity_budget;

    
    CREATE TABLE APPROVAL_STATUS(
    request_code CHAR (17),
    expense_code CHAR(12) not null,
    last_update_date DATE not null,
    request_date DATE not null,
    approver_id_emp CHAR(6) not null,
    status VARCHAR2(8) not null,
    budget_request numeric(10,2) not null,
    CONSTRAINT request_code_pk PRIMARY KEY(request_code),
    CONSTRAINT approver_id_emp_id_fk FOREIGN KEY(approver_id_emp) REFERENCES EMPLOYEE_TABLE(employee_id),
    CONSTRAINT as_expense_code_fk FOREIGN KEY(expense_code) REFERENCES ACTIVITY_BUDGET(expense_code));
        
  

    
CREATE TABLE PURCHASE_REQUEST (
    pr_code CHAR (8),
    expense_code CHAR(12) not null,
    pr_value INT not null,
    CONSTRAINT pr_code_pk PRIMARY KEY(pr_code),
    CONSTRAINT pr_expense_code_fk FOREIGN KEY(expense_code) REFERENCES ACTIVITY_BUDGET(expense_code));
    
SELECT * FROM purchase_request;   
    


-----INSERT DATE---------------------------------------------------------------
-------------------------------------------------------------------------------
---DATA IS INSERTED TO TABLES USING IMPORTING DATA FROM EXCEL FUNCTION IN ORACLE SQL---



----REPORTS---------------------------------------------------------------------

--The total budget request and total approved budget of  by brand---------------

with a AS (
SELECT
b.brand_name,
bb.budget_code,
bb.year,
SUM(ab.budget_request) AS Budget_Requested,
SUM(ab.budget_approved) AS Budget_Approved

FROM
activity_budget ab
LEFT OUTER JOIN brand_budget bb ON ab.budget_code = bb.budget_code
LEFT OUTER JOIN brands b ON bb.brand_id = b.brand_id
GROUP BY
b.brand_name,
bb.budget_code,
bb.year
ORDER BY
b.brand_name,
bb.year ASC)

SELECT a.brand_name,a.year,
'$' || budget_amount AS Total_Budget,
'$' || Budget_Requested AS Budget_Requested,
'$' || Budget_Approved AS Budget_Approved,
'$' || (budget_amount-Budget_Approved) AS Available_budget
FROM brand_budget bb JOIN a ON bb.budget_code=a.budget_code;



--The total budget request and total approved budget by marketing activities---

SELECT ma.activity_code,ma.activity_name,
'$' || SUM(ab.budget_request) AS "TOTAL_BUDGET_REQUEST",
'$' || SUM(ab.budget_approved) AS "TOTAL_BUDGET_APPROVED"
FROM marketing_activities ma JOIN activity_budget ab ON ma.activity_code=ab.activity_code
group by ma.activity_code,ma.activity_name
ORDER BY activity_name ASC ;

--The number of requests pending for approval, current approvers, and pending time until current system date--

SELECT APPROVER_ID_EMP,EMAIL_ADDRESS, STATUS, REQUEST_CODE, TRUNC(SYSDATE-LAST_UPDATE_DATE) AS "PENDING_DAYS"
FROM APPROVAL_STATUS a JOIN employee_table e ON a.approver_id_emp=e.employee_id
WHERE STATUS = 'Pending';


--The total value of purchase requests per marketing activities--------------

with a AS (SELECT p.EXPENSE_CODE, M.ACTIVITY_NAME, SUM(pr_value) AS pr_value
FROM PURCHASE_REQUEST P
LEFT OUTER JOIN ACTIVITY_BUDGET B
ON (P.EXPENSE_CODE = B.EXPENSE_CODE)
LEFT OUTER JOIN MARKETING_ACTIVITIES M
ON (M.ACTIVITY_CODE = B.ACTIVITY_CODE)
GROUP BY p.EXPENSE_CODE,ACTIVITY_NAME)

SELECT a.expense_code,a.activity_name,'$'|| PR_VALUE as pr_value,'$'|| budget_approved AS budget_approved, '$'|| (budget_approved-pr_value) AS available_amount,
ROUND(pr_value/budget_approved,2)*100 AS Percent_usage
FROM activity_budget ab JOIN a ON ab.expense_code=a.expense_code;

--The total time (in days) required for a request to be finally approved-----

SELECT request_code,
request_date "BUDGET_REQUESTED_DATE",
last_update_date "BUDGET_APPROVED_DATE",
approver_id_emp,
trunc(last_update_date - request_date) AS "TOTAL_DAYS_FOR_APPROVAL"
FROM approval_status
WHERE
status = 'Approve'
ORDER BY TRUNC ( LAST_UPDATE_DATE - REQUEST_DATE ) DESC