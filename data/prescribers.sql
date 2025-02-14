-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.





-- Answer: 1881634483, 99707 number of claims


select 
	r.npi,
	sum(n.total_claim_count) total_claim_count
from prescriber r
join prescription n 
on r.npi = n.npi 
group by r.npi
order by total_claim_count desc
limit 1;



    --     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.


select 
	r.npi,
	r.nppes_provider_first_name,
	r.nppes_provider_last_org_name,
	r.specialty_description,
	sum(n.total_claim_count) total_claim_count
from prescriber r
join prescription n 
on r.npi = n.npi 
group by r.npi, r.nppes_provider_first_name, r.nppes_provider_last_org_name, r.specialty_description
order by total_claim_count desc
limit 1;






-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?


select 
	r.specialty_description,
	sum(n.total_claim_count) total_claim_count
from prescriber r
join prescription n 
	on r.npi = n.npi 
group by r.specialty_description	
order by total_claim_count desc
limit 1;



-- Answer: Family Practice



--     b. Which specialty had the most total number of claims for opioids?


select 
	r.specialty_description,
	sum(n.total_claim_count) total_claim_count
from prescriber r 
inner join prescription n
	on r.npi = n.npi 
inner join drug d
	on n.drug_name = d.drug_name
where opioid_drug_flag = 'Y' 
group by r.specialty_description
order by total_claim_count desc 


-- Answer: Nurse Practioner 



--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

select 
	d.generic_name,
	sum(n.total_drug_cost) total_drug_cost
from drug d 
inner join prescription n
	on d.drug_name = n.drug_name
group by d.generic_name	
order by total_drug_cost desc	


-- Answer: INSULIN GLARGINE,HUM.REC.ANALOG



--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

select 
	d.generic_name,
	round(sum(n.total_drug_cost) / nullif(sum(total_day_supply), 0), 2) cost_per_day
from prescription n 
inner join drug d 
	on d.drug_name = n.drug_name
where n.total_day_supply > 0
group by d.generic_name
order by cost_per_day desc

-- Answer: C1 ESTERASE INHIBITOR





-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 


select 
	drug_name,
	case 
		when opioid_drug_flag = 'Y' then 'opioid'
		when long_acting_opioid_drug_flag = 'Y' then 'opioid'
		when antibiotic_drug_flag = 'Y' then 'antibiotic'
		else 'neither'
	end as drug_type
from drug 






--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.


select 
	case 
		when d.opioid_drug_flag = 'Y' then 'opioid'
		when d.long_acting_opioid_drug_flag = 'Y' then 'opioid'
		when d.antibiotic_drug_flag = 'Y' then 'antibiotic'
		else 'neither'
	end as drug_type,
	cast(sum(n.total_drug_cost) as money) as total_spent
from prescription n
inner join drug d 
	on d.drug_name = n.drug_name
where d.opioid_drug_flag = 'Y' or d.long_acting_opioid_drug_flag = 'Y' or d.antibiotic_drug_flag = 'Y'
group by drug_type
order by total_spent desc





-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

-- Answer: 42

select 
count(*)
from cbsa c
join fips_county f
on c.fipscounty = f.fipscounty
where f.state = 'TN';






select 
f.fipscounty,
f.state,
count(c.cbsaname) cbsa_name
from cbsa c
inner join fips_county f
	on c.fipscounty = f.fipscounty
where c.cbsaname like '%, TN%'
or c.cbsaname like '% TN%'
and c.cbsaname not like '%-TN%'
and c.cbsaname not like '%TN-%'
group by f.fipscounty, f.state
order by cbsa_name







--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

-- Answer: largest: 	CBSA name: Nashville-Davidson-Mufreesboro-Franklin, TN
-- 						total population: 1,830,410
--		   smallest: 	CBSA name: Morris, Town
-- 						total population: 116,352


select 
c.cbsaname,
sum(u.population) total_population 
from cbsa c
inner join population u
	on c.fipscounty = u.fipscounty
group by c.cbsaname
order by total_population desc
limit 1;

select 
c.cbsaname,
sum(u.population) total_population 
from cbsa c
inner join population u
	on c.fipscounty = u.fipscounty
group by c.cbsaname
order by total_population 
limit 1;






--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

-- Answer: Sevier, 95,523



select 
f.county,
u.population
from population u
inner join fips_county f 
	on u.fipscounty = f.fipscounty
left join cbsa c 
	on u.fipscounty = c.fipscounty
where c.fipscounty is null 	
order by u.population desc 	




-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

select 
	drug_name,
	total_claim_count 
from prescription 	
where total_claim_count >= 3000
order by total_claim_count desc


--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

select 
	n.drug_name,
	n.total_claim_count total_claim_count,
	d.opioid_drug_flag
from prescription n	
left join drug d 
	on n.drug_name = d.drug_name
where total_claim_count >= 3000
order by n.drug_name



--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

select 
	r.nppes_provider_first_name,
	r.nppes_provider_last_org_name,
	n.drug_name,
	n.total_claim_count total_claim_count,
	d.opioid_drug_flag
from prescription n	
inner join drug d 
	on n.drug_name = d.drug_name
inner join prescriber r 
	on n.npi = r.npi
where total_claim_count >= 3000





-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.


--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.


select 
r.npi, 
d.drug_name
from drug d, prescriber r
where r.specialty_description = 'Pain Management'	
and r.nppes_provider_city = 'NASHVILLE'
and d.opioid_drug_flag = 'Y'




--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).


select 
r.npi,
d.drug_name,
coalesce(sum(n.total_claim_count), 0) coalesce
from prescriber r
cross join drug d 	
left join prescription n
	on r.npi = n.npi
	and d.drug_name = n.drug_name
where r.specialty_description = 'Pain Management'	
and r.nppes_provider_city = 'NASHVILLE'
and d.opioid_drug_flag = 'Y'
group by r.npi, d.drug_name




--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.