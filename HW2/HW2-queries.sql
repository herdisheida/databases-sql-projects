-- HW2
-- Student names: Herdís Heiða, Júlía Gunnlaugsdóttir, Sindri Snær


-- A. There are 8 plants that belong to the family “Ruellia”.
--    How many plants (in total) belong to families with names that have
--    two instances of the letter “r” (either upper or lower case)?
-- Explanation: 
/*
Telur fjölda plantna í öllum fjölskyldunum sem eru með tvö “r” í nafninu. við breytum nöfnunum í “lowercase” og kíkjum þannig á það. 
*/
SELECT COUNT(p.id) AS total_plants
FROM plants p
   JOIN families f ON p.familyid = f.id
WHERE LOWER(F.name) LIKE '%r%r%'
   AND NOT LOWER(F.name) LIKE '%r%r%r%';



-- B. The most overfilled flowerbed is planted to 105% capacity.
--    What are the ID(s) of the flowerbed(s) with the most overfilled capacity?
-- Explanation:
/*
Fundum öll “over-filled” blómabeðin í sub, svo fundum við blómabeðið sem var með mest fyllt samkvæmt prósentu. 
*/
-- sub query
WITH overfilled_flowerbed AS (
   SELECT B.id, SUM(PI.percentage) AS percentage_capacity
   FROM beds B
       JOIN plantedin PI ON B.id = PI.bedid
   GROUP BY B.id
   )
-- main query
SELECT id
FROM overfilled_flowerbed
WHERE percentage_capacity = (
   SELECT MAX(percentage_capacity) FROM overfilled_flowerbed
);



-- C. There are 10 flowerbeds that are planted to more than 100% capacity.
--    How many flowerbeds are planted to less than 100% capacity.
-- Explanation:
with bedperc as (
	select I.bedID as ID, sum(I.percentage) as perc
	from plantedin I
	group by I.bedID
)
select count(*)
from beds B
where B.ID not in (
	select BP.ID
	from bedperc BP
	where BP.perc >= 100
);



-- D. Write a query using a set operator that returns the number of plants that
--    (a) are planted in “Faelledparken” or (b) are of type “shrub”.
-- Explanation:
/*
 í fyrsta query-inu fundum við allar plöntur sem eru plantaðar í “Faelledparke” og í seinna fundum við allar plöntur sem eru “Shrub”. Notum svo Union til að það telji plöntuna ef það er partur af öðru hvoru query
*/
SELECT COUNT(*)
FROM (
   SELECT P.id -- get plants in 'Faelledparken'
   FROM plants P
       JOIN plantedin PI ON P.id = PI.plantid
       JOIN beds B ON PI.bedid = B.id
       JOIN gardens G ON B.gardenid = G.id
   WHERE G.name = 'Faelledparken'

   UNION -- set operator

   SELECT P.id -- get plants that are 'shrub'
   FROM plants P
       JOIN families F ON P.familyid = F.id
       JOIN types T ON T.id = F.typeid
   WHERE T.name = 'shrub'
);



-- E. Write a query without a set operator that returns the number of plants that
--    (a) are planted in “Faelledparken” and (b) are of type “shrub”.
-- Explanation:
/*
Við notuðum WHERE til að fá aðeins plöntur í garðinum “Faelledparken” og af týpunni “shrub”. Notuðum síðan COUNT() til að telja þau tilvik
*/
SELECT COUNT(*)
FROM plants P
   JOIN families F ON F.id = P.familyid
   JOIN types T ON T.id = F.typeid
   JOIN plantedin PI ON P.id = PI.plantid
   JOIN beds B ON B.id = PI.bedid
   JOIN gardens G ON G.id = B.gardenid
WHERE G.name = 'Faelledparken'
   AND T.name = 'shrub';



-- F. Write a query that returns the ID and name of all staff that
--    (a) have position “Planter” and (b) have planted a larger area than any
--    staff member with position “Senior Planter”. Order the result by the name.
-- Explanation:

with staffarea as (
	select S.ID, S.name, S.position, sum(1.0 * B.size * I.percentage / 100) as sqm
	from staff S
		join plantedin I on S.ID = I.staffID
        join beds B on B.ID = I.bedID
	group by S.ID
)
select SA.ID, SA.name
from staffarea SA
where SA.position = 'Planter'
	and not exists (
		select *
		from staffarea SA2
		where SA2.position = 'Senior Planter'
			and SA2.sqm >= SA.sqm
	)
order by SA.name;



-- G. Write a query to return the names of the families, with at least
--    5 different plants, that are planted in the most flowerbeds on average,
--    across all their plants?
-- Note: In a different instance, the output of this query could contain more
--    than one family name, but in this database instance the answer is one family name.
--    As an additional hint, the average number of flowerbeds for each plant of
--    that family is 6.20000….
-- Explanation:
/*
plant_bed_counts taflan, telur fjölda blómabeða sem hver planta er í.
family_avg taflan, reiknar meðalfjölda blómabeða fyrir hverja fjölskyldu. (en aðeins þau sem hafa amk 5 mismunandi plöntur)
Main-query-ið, tengir þessar tímabundu töflur saman. Sub-query-ið inn í main-query-inu passar að sýna aðeins aðeins fjölskyldu(r) með mesta meðalfjöldan.
*/
with plantsbeds as (
	select I.plantID, count(I.bedID) as numbeds
	from plantedin I
	group by I.plantID
), famnumbeds as (
	select F.name, avg(numbeds) as avgnumbeds
	from families F
		join plants P on P.familyID = F.ID
		join plantsbeds PB on PB.plantID = P.ID
	group by F.ID
	having count(*) >= 5
) 
select FB.name --, FB.avgnumbeds
from famnumbeds FB
where FB.avgnumbeds = (select max(avgnumbeds) from famnumbeds);







-- H. Write a query that returns the number of staff who have planted something
--    (at least one plant in at least one flowerbed) in all gardens.
-- Note: This is a division query; points will only be awarded if division is attempted.
-- Explanation:
/*
Við joinum töflunar saman til þess að fá allar upplýsingar saman sem við þurfum, við grupum svo staff til þess að greina plöntu söguna hjá starfsfólkinu, við filterum svo starfsfólkið sem hafa bara gróður sett í alla garða með því að nota “Having” Svo til þess að fá enda niðurstöðu af öllu starfsfólkinu
*/
select count(*)
from (
	select I.staffID, count(distinct B.gardenID)
	from plantedin I 
		join beds B on I.bedID = B.ID
	group by I.staffID
	having count(distinct B.gardenID) = (
		select count(*)
		from gardens
	)
) X;





-- I. There are 105 families that are planted in at least one flowerbed in
--    all the parks from the database. How many flowerbeds have at least one plant
--    of all types from the database.
-- Note: This is a division query; points will only be awarded if division is attempted.
-- Explanation:
/*
með því að flokka blómabeð, telja plöntutegundir í hverju og bera saman sú tölu við heildarfjölda plöntutegunda í kerfinu til að tryggja að hvert blómabeð hafi allar tegundirnar.
*/
select count(*)
from (
	select I.bedID,  count(*), count(distinct F.ID), count(distinct F.typeID) -- use these for debugging
	from families F 
		join plants P on F.ID = P.familyID
		join plantedin I on P.ID = I.plantID
	group by I.bedID
	having count(distinct F.typeID) = (
		select count(*)
		from types T
	) 
) X;







-- J. Write a query that returns the ID and name of staff, and the total area that
--    they have planted. The list should be restricted to staff who have the
--    position “Planter” and who have planted some plant of type “flower” in the
--    garden “Kongens Have”. The total area returned, however, should not have those
--    restrictions and should represent all the area planted by these staff.
--    The list should be ordered with the largest area first.
-- Explanation:
/*
total_areas taflan reiknar út heildar svæði sem hver starfsmaður hefur plantað í.
Main-query-ið notar WHERE-skipun til að fá aðeins tiltekna útkomu. Síðan var ORDER-BY DESC notað til að sýna tota_area útkomurnar í stærðarröð.
*/
with alldata as (
	select S.ID, S.name, T.name as type, G.name as garden, S.position, 1.0 * B.size * I.percentage / 100 as sqm
	from staff S
		join plantedin I on S.ID = I.staffID
		join beds B on B.ID = I.bedID
		join gardens G on G.ID = B.gardenID
		join plants P on P.ID = I.plantID
		join families F on F.ID = P.familyID
		join types T on T.ID = F.typeID
)
select A.ID, A.name, sum(A.sqm)
from alldata A
group by A.ID, A.name
having A.ID in (
	select A2.ID
	from alldata A2
	where A2.type = 'flower'
		and A2.garden = 'Kongens Have'
		and A2.position = 'Planter'
)
order by sum(A.sqm) desc;