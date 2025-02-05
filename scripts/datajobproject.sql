/* 1. How many rows are in the data_analyst_jobs table? 

Answer: 1793 */

SELECT COUNT(*)
FROM data_analyst_jobs; 

/* 2. Write a query to look at just the first 10 rows. What company is associated with the job posting on the 10th row? 

Answer: ExxonMobil */

SELECT *
FROM data_analyst_jobs
LIMIT 10;


/* 3. How many postings are in Tennessee? How many are there in either Tennessee or Kentucky? 

Answer: 21, 27 */


SELECT COUNT(*) 
FROM data_analyst_jobs
WHERE location = 'TN';


SELECT COUNT(*) 
FROM data_analyst_jobs
WHERE location IN ('TN', 'KY');


/* 4. How many postings in Tennessee have a star rating above 4? 
Answer: 3 */

SELECT COUNT(*)
FROM data_analyst_jobs
WHERE location = 'TN' AND star_rating > 4;

/* 5. How many postings in the dataset have a review count between 500 and 1000?

Answer: 151 */

SELECT COUNT (*)
FROM data_analyst_jobs 
WHERE review_count BETWEEN 500 AND 1000;

/* 6. Show the average star rating for companies in each state.
The output should show the state as `state` and the average rating for the state as `avg_rating`. 
Which state shows the highest average rating?

Answer: Nebraska */ 

SELECT location AS state, AVG(star_rating) AS avg_rating
FROM data_analyst_jobs 
GROUP BY state
ORDER BY avg_rating DESC;

/* 7. Select unique job titles from the data_analyst_jobs table. How many are there?

Answer: 881 */

SELECT COUNT(DISTINCT title) AS unique
FROM data_analyst_jobs;

/* 8. How many unique job titles are there for California companies?

Answer: 230 */

SELECT COUNT(DISTINCT title) AS unique
FROM data_analyst_jobs
WHERE location = 'CA';


/* 9. Find the name of each company and its average star rating for all companies that have more than 5000 
reviews across all locations. 

How many companies are there with more that 5000 reviews across all locations?

Answer: 70 but 71 if counting the [null] */


SELECT company, AVG(star_rating)
FROM data_analyst_jobs
GROUP BY company 
HAVING SUM(review_count) > 5000;


/* 10. Add the code to order the query in #9 from highest to lowest average star rating. Which company with more than 5000 reviews across all locations in the dataset has the highest star rating? What is that rating?

Answer: Google, their rating in 4.3 */


SELECT company, AVG(star_rating) AS average_star_rating
FROM data_analyst_jobs
GROUP BY company 
HAVING SUM(review_count) > 5000
ORDER BY average_star_rating DESC;


/* 11. Find all the job titles that contain the word ‘Analyst’. How many different job titles are there? 

Answer: 754 */

SELECT COUNT(DISTINCT title) 
FROM data_analyst_jobs
WHERE title LIKE '%Analyst%';


/* 12. How many different job titles do not contain either the word ‘Analyst’ or the word ‘Analytics’? What word do these positions have in common?

Answer: 26, they all have spelling errors  */ 


SELECT COUNT (DISTINCT title)
FROM data_analyst_jobs
WHERE title NOT LIKE '%Analyst%' AND title NOT LIKE '%Analytics%';

SELECT DISTINCT title 
FROM data_analyst_jobs
WHERE title NOT LIKE '%Analyst%' AND title NOT LIKE '%Analytics%';


