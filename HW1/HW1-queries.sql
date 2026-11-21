-- HW1
-- Student names: Herdís Heiða, Júlía, Sindri Snær




-- A. What is the size of the largest flowerbed?
--    Note: The query should return only the size.
-- Explanation:
/*
Finnum stærðir frá beds-töflunni og finnum stærstu stærðina með því að nota MAX() fallið.
*/
SELECT MAX(B.size)
FROM beds B;


-- B. There are 8 different plants that are missing the family information.
--    Write a query that returns the number of plants that
--    belong to the family “Thespesia”.
-- Explanation:
/*
Tengjum plöntu- og fjölskyldu-töfluna saman, og með WHERE-skipun náum við aðeins í gögn frá 'Thespesia' fjölskyldunni.
Síðan notuðum við COUNT(*) til að telja hvert tilvik
*/
SELECT COUNT(*)
FROM plants P
   JOIN families F ON P.familyid = F.id
WHERE F.name = 'Thespesia';


-- C. In total, there are 792 families in the database. 
--    Write a query that returns the number of families whose name starts with “A”.
-- Explanation:
/*
Náum í gögn úr fjölskyldu-töflunni, notum WHERE-skipun og "%" merki til að finna nöfn sem byrja á A.
Notum síðan COUNT(*) fallið til að telja hvert tilvik.
*/
SELECT COUNT(*)
FROM families F
WHERE F.name LIKE 'A%';


-- D. Of the people in the database, 11 have not planted anything.
--    Write a query that returns the number of people who
--    have the position “Senior Planter” and have not planted anything.
-- Explanation:
/*
Náum í gögn frá staff- og plantedin-töflunni með LEFT JOIN, til að fá líka upplýsingar um starfsmenn sem hafa ekki plantað neinu.
Notum síðan WHERE-skipun til að finna Senior Planters sem hafa ekki plantað neinu. Og teljum tilvikin með Count(*) fallinu.
*/
SELECT COUNT(*)
FROM staff S
   LEFT JOIN plantedin PI ON S.id = PI.staffid
WHERE S.position = 'Senior Planter'
   AND PI.staffid IS NULL;


-- E. Write a query to return the number of people in the database
--    who have planted plants from more than 50 different families.
-- Explanation:
/*
Söfnun gögn úr staff-, plantedin- og plants-töflunum. Notum GROUP BY til að flokka eftir starfsfólki.
Notum HAVING til að velja starfsfólk sem hefur plantað meira en 50 mismunandi plöntufjölskyldum.
Setjum það allt í SUB-QUERY og notum COUNT() til að telja atvikin úr SUB-QUERY-inu.
*/
SELECT COUNT(*)
FROM (
   SELECT S.id
   FROM staff S
       JOIN plantedin PI ON S.id = PI.staffid
       JOIN plants P ON PI.plantid = P.id
   GROUP BY S.id
   HAVING COUNT(DISTINCT P.familyid) > 50
);


-- F. Write a query that returns the number of people in the database
--    who have the same name as some other person.
-- Explanation:
/*
Gerðum SUB-QUERY sem finnur nöfn starfsmanna sem heitir sama nafni.
Notum síðan WHERE-IN-skipun sem finnur alla með þau nöfn.
Að lokum notum við COUNT(*) fallið sem telur öll þau tilvik.
*/
SELECT COUNT(*)
FROM staff S
WHERE S.name IN (
   SELECT name
   FROM staff
   GROUP BY name
   HAVING COUNT(*) > 1
);


-- G. The total area of the family “Thespesia” is 66.62
--    (the unit is square meters; on my machine, the exact number is 66.62000000000003).
--    Write a query that returns the total area of the family “Vicia”.
--    Note: The result only needs to be accurate to two digits after the decimal point.
-- Explanation:
/*
Notuðm WHERE-skipun til að fá aðeins upplýsingar um 'Vicia' fjölskylduna.
Í SELECT skipuninni, reiknuðum við hversu marga fermetra ákveðin planta hefur í ákveðnu blómabeði.
Notuðum SUM() á útkomuna til að finna heildarflatarmálið.
*/
SELECT SUM(1.0 * B.size * PI.percentage / 100) AS total_area
FROM families F
   JOIN plants P ON F.id = P.familyid
   JOIN plantedin PI ON P.id = PI.plantid
   JOIN beds B ON PI.bedid = B.id
WHERE F.name = 'Vicia';


-- H. Write a query that returns the names of all gardens that have some plant
--    of type “epiphyte” that was planted by a person with the position “Teamleader”.
-- Explanation:
/*
Tengdum allar töflur sem við þurftum.
Notuðum síðan WHERE-skipun til að fá garða með 'epiphyte' plöntu type,
sem var plöntuð af 'Teamleader' starfsmanni
*/
SELECT DISTINCT G.name
FROM gardens G
   JOIN beds B ON G.id = B.gardenid
   JOIN plantedin PI ON B.id = PI.bedid
   JOIN plants P ON PI.plantid = P.id
   JOIN families F ON P.familyid = F.id
   JOIN types T ON F.typeid = T.id
   JOIN staff S ON PI.staffid = S.id
WHERE T.name = 'epiphyte'
   AND S.position = 'Teamleader';



-- I. Write a query that returns, for each flowerbed with overfilled capacity,
--    the description of the flowerbed, the name of the garden it resides in,
--    and the percentage of capacity to which it is planted. The results should
--    be ordered by the percentage of capacity, with the highest percentage first.
--    Note: The last column should always contain a number higher than 100.
-- Explanation:
/*
Notum GROUP-BY til að hópa saman 'flowerbeds',
notum síðan HAVING til að fá aðeins 'flowerbeds' með 'overfilled capacity'
NOTUM ORDER BY... DESC til að sýna stærstu prósentu útkomuna fyrst
*/
SELECT B.description, G.name, SUM(PI.percentage) AS percentage_capacity
FROM beds B
   JOIN gardens G ON B.gardenid = G.id
   JOIN plantedin PI ON B.id = PI.bedid
GROUP BY B.id, B.description, G.name
HAVING SUM(PI.percentage) > 100
ORDER BY percentage_capacity DESC;


-- J. Write a query that returns the ID and the name of the gardens(s) with the 
--    most flowerbeds, along with the number of flowerbeds.
--    Note: Although this query will return only one row for this database instance, 
--    your query should nevertheless handle potential ties.
-- Explanation:
/* 
Bjuggum til sub-query með WITH-xxx-AS-skipun til að fá upplýsingar um fjölda blómabeða fyrir hvern garð.
Síðan í main-query var WHERE-skipunin notuð sem fann stærsta blómabeðið með MAX() falli
*/

-- sub query
WITH bed_counts AS (
    SELECT B.gardenid, COUNT(B.id) as bed_count
    FROM beds B
    GROUP BY B.gardenid
)
-- main query
SELECT G.id, G.name, BC.bed_count AS max_bed_count
FROM gardens G
    JOIN bed_counts BC ON G.id = BC.gardenid
WHERE BC.bed_count = (
    SELECT MAX(bed_count)
    FROM bed_counts
);




-- CASE 1: önnur lausn á J) -- frá Júlíu
SELECT G.id, G.name, COUNT(*) AS number_of_beds
FROM gardens G
   JOIN beds B ON G.id = B.gardenid
GROUP BY G.id, G.name
HAVING COUNT(*) = (
   SELECT MAX(bed_count)
   FROM (
       SELECT gardenid, COUNT(*) AS bed_count
       FROM beds
       GROUP BY gardenid
   ) AS BedCounts
);
