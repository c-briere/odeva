-- TP 2 ED

-- QUESTION 1

-- RAFRAICHISSEMENT

-- PRODUIT - 24H
-- TEMPS - JAMAIS
-- CLIENT - 24H
-- VENTE - 24H



-- Vue matérialisée - PRODUIT

CREATE MATERIALIZED VIEW DIM_PRODUIT 
USING INDEX 
-- REFRESH ONCE PER DAY
REFRESH START WITH GREATEST(SYSDATE,TO_DATE('2015.10.17.23.09.47','YYYY.MM.DD.HH24.MI.SS')) NEXT SYSDATE + 1 COMPLETE 
WITH PRIMARY KEY 
DISABLE QUERY REWRITE AS 
SELECT  NUM AS ID_PRODUIT
,       RTRIM (REGEXP_SUBSTR (DESIGNATION, '[^.]*.', 1, 1), '.')    AS NOM
,       RTRIM (REGEXP_SUBSTR (DESIGNATION, '[^.]*.', 1, 2), '.')    AS CATEGORIE
,       LTRIM (REGEXP_SUBSTR (DESIGNATION, '.[^.]*', 1, 3), '.')    AS SOUS_CATEGORIE
FROM    produit;





-- Vue matérialisée - TEMPS


CREATE MATERIALIZED VIEW DIM_TEMPS 
USING INDEX 
REFRESH ON DEMAND COMPLETE 
DISABLE QUERY REWRITE AS 
SELECT
-- DAY LEVEL
time_id AS day_id,
INITCAP(TO_CHAR(time_id,'DD fmMonth YYYY')) AS day_desc,
INITCAP(TO_CHAR(time_id, 'fmDAY')) AS day_name,
TO_NUMBER(TO_CHAR(time_id - 1, 'D')) AS day_of_week,
TO_NUMBER(TO_CHAR(time_id, 'DD')) AS day_of_month,
TO_NUMBER(TO_CHAR(time_id, 'DDD')) AS day_of_year,

-- MONTH LEVEL
TO_CHAR(time_id, 'YYYY"-M"MM') AS month_id,
TO_CHAR(time_id, 'fmMonth YYYY') AS month_desc,
DECODE(MOD(TO_NUMBER(TO_CHAR(time_id, 'MM')), 4), 0, 4, MOD(TO_NUMBER(TO_CHAR(time_id, 'MM')), 4)) AS month_of_quarter,
TO_NUMBER(TO_CHAR(time_id, 'MM')) AS month_of_year,
TO_CHAR(time_id, 'fmMonth') AS month_name,
LAST_DAY(time_id) AS end_of_month,
TO_CHAR(LAST_DAY(time_id),'DD') AS days_in_month,

-- QUARTER LEVEL
TO_CHAR(time_id, 'YYYY"-Q"Q') AS quarter_id,
TO_NUMBER(TO_CHAR(time_id, 'Q')) AS quarter_of_year,
TRUNC(ADD_MONTHS(time_id,3), 'Q') - 1 AS end_of_quarter,
(TRUNC(ADD_MONTHS(time_id,3), 'Q') - 1) - (TRUNC(time_id, 'Q') - 1) AS days_in_quarter,

-- YEAR LEVEL
TO_NUMBER(TO_CHAR(time_id, 'YYYY')) AS year_id,
(TRUNC(ADD_MONTHS(time_id,12), 'YYYY') - 1) - (TRUNC(time_id, 'YYYY') - 1) AS days_in_year,
TRUNC(ADD_MONTHS(time_id,12), 'YYYY') - 1 AS end_of_year,

-- THIS IS THE SAME FOR ALL WEEKS
7 AS days_in_week,

-- CALENDAR WEEK LEVEL
TO_CHAR(time_id, 'IYYY') || '-W' || TO_CHAR(time_id, 'IW') AS cal_week_id,
TO_NUMBER(TO_CHAR(time_id, 'IW')) AS cal_week_of_year,
TRUNC(time_id + 7, 'IW') - 1 AS end_of_cal_week

FROM (SELECT to_date('01/01/1900','MM/DD/YYYY') + rownum - 1 AS time_id
FROM all_objects
-- start 01/01/1900
-- until 12/31/2099
WHERE rownum <= 73049)
ORDER BY time_id;





-- Vue matérialisée - CLIENT

CREATE MATERIALIZED VIEW DIM_CLIENT 
USING INDEX 
REFRESH START WITH GREATEST(SYSDATE,TO_DATE('2015.10.18.20.41.15','YYYY.MM.DD.HH24.MI.SS')) NEXT SYSDATE + 1 COMPLETE 
WITH PRIMARY KEY 
DISABLE QUERY REWRITE AS 
SELECT  NUM
,       Nom
,       Prenom
,       RTRIM  (REGEXP_SUBSTR (ADRESSE, '[^,]+,', 1, 1), ',')    AS RUE
,       RTRIM  (REGEXP_SUBSTR (ADRESSE, '[^,]+,', 1, 2), ',')    AS CP
,       RTRIM  (REGEXP_SUBSTR (ADRESSE, '[^,]+,', 1, 3), ',')    AS VILLE
,       SUBSTR (RTRIM (REGEXP_SUBSTR (ADRESSE, '[^,]+,', 1, 2), ',') ,1,2)    AS DEPARTEMENT
,       LTRIM  (REGEXP_SUBSTR (ADRESSE, ',[^,]+', 1, 3), ',')    AS PAYS
,       (CASE 
          WHEN extract(year from numtoyminterval(months_between(trunc(sysdate),date_nais),'month'))<30 THEN '<30 ans'
          WHEN extract(year from numtoyminterval(months_between(trunc(sysdate),date_nais),'month'))<46 THEN '30-45 ans'
          WHEN extract(year from numtoyminterval(months_between(trunc(sysdate),date_nais),'month'))<61 THEN '46-60 ans'
          ELSE '>60ans'
        END)
        age
,       sexe
FROM CLIENT;

-- Vue matérialisée - VENTE

CREATE MATERIALIZED VIEW FAIT_VENTE 
USING INDEX 
REFRESH START WITH GREATEST(SYSDATE,TO_DATE('2015.10.18.21.03.36','YYYY.MM.DD.HH24.MI.SS')) NEXT SYSDATE + 1 COMPLETE 
DISABLE QUERY REWRITE AS 
SELECT  CLIENT ID_CLIENT
,       DATE_ETABLI ID_TEMPS
,       FACTURE ID_FACTURE
,       LIGNE_FACTURE.PRODUIT ID_PRODUIT
,       QTE QUANTITE
,       prix_date.prix PRIX
,       (CASE REMISE WHEN 0 THEN QTE*PRIX_DATE.PRIX ELSE QTE*PRIX_DATE.PRIX*REMISE END)
        MONTANT_HT
FROM FACTURE
JOIN LIGNE_FACTURE ON LIGNE_FACTURE.FACTURE=FACTURE.NUM
JOIN PRIX_DATE ON LIGNE_FACTURE.ID_PRIX=PRIX_DATE.NUM;


-- QUESTION 2

--CLIENT
ALTER MATERIALIZED VIEW DIM_CLIENT
ADD (
  CONSTRAINT pk_DIM_CLIENT PRIMARY KEY (NUM)
);

--PRODUIT
ALTER MATERIALIZED VIEW DIM_PRODUIT
ADD (
  CONSTRAINT pk_DIM_PRODUIT PRIMARY KEY (ID_PRODUIT)
);

--TEMPS
ALTER MATERIALIZED VIEW  DIM_TEMPS
ADD (
  CONSTRAINT pk_DIM_TEMPS PRIMARY KEY (DAY_ID)
); 

--