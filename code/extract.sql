

with atc as 
( 
	SELECT DISTINCT atc AS atc_code 
	FROM continuing_item 
)
select * 
FROM pbs_r 
JOIN pbs_item pi USING (pbs_code)
JOIN atc a USING (atc_code)
LIMIT 100;



with atc as 
( 
	SELECT DISTINCT atc  AS atc_code, generic_name
	FROM continuing_item 
)
select DISTINCT atc_code, drug_name, form_strength
FROM pbs_rr
JOIN pbs_item pi USING (pbs_code)
LEFT JOIN atc a USING (atc_code)
WHERE atc_code LIKE 'N02%'
AND a.generic_name is null;


with atc as 
( 
	SELECT DISTINCT atc  AS atc_code, generic_name
	FROM continuing_item 
)
select DISTINCT atc_code, drug_name, form_strength
FROM pbs_rr
JOIN pbs_item pi USING (pbs_code)
LEFT JOIN atc a USING (atc_code)
WHERE atc_code LIKE 'N05%'
AND a.generic_name is null;


SELECT DISTINCT atc  AS atc_code
FROM continuing_item ;



-- make sure that I have the same pbs codes as mofi; yes! 
with atc as 
( 
	SELECT DISTINCT atc AS atc_code, generic_name, item_code as pbs_code
	FROM continuing_item 
)
select * 
FROM pbs_rr
JOIN pbs_item pi USING (pbs_code)
JOIN pbs_atc pa USING (atc_code)
JOIN atc a USING (pbs_code) 
WHERE a.atc_code != pa.atc_code;

-- What codes do I have that Mofi does not have
with atc as 
( 
	SELECT DISTINCT atc AS atc_code, generic_name, item_code as pbs_code
	FROM continuing_item 
)
select distinct atc_code, atc_meaning
FROM pbs_r
JOIN pbs_item pi USING (pbs_code)
JOIN pbs_atc pa USING (atc_code)
WHERE (pa.atc_code LIKE 'N02A%' OR pa.atc_code LIKE 'N05B%' OR pa.atc_code LIKE 'N05C%' )
AND pa.atc_code not in (select atc_code from atc )
ORDER by atc_code;



SELECT DISTINCT atc AS atc_code FROM continuing_item order by atc_code;



-- What codes do I have that Mofi does not have
with atc as 
( 
	SELECT DISTINCT atc AS atc_code, generic_name, item_code as pbs_code
	FROM continuing_item 
)
select distinct atc_code, atc_meaning
FROM pbs_r
JOIN pbs_item pi USING (pbs_code)
JOIN pbs_atc pa USING (atc_code)
WHERE (pa.atc_code LIKE 'N02A%' OR pa.atc_code LIKE 'N05B%' OR pa.atc_code LIKE 'N05C%' )
AND pa.atc_code not in (select atc_code from atc )
ORDER by atc_code;


select *
FROM pbs_item pi 
WHERE atc_code = 'N02AB02';


--01829G   | PETHIDINE               | Injection 100 mg in 2 mL ampoule | N02AB02  | Y

insert into continuing_item values( 'N02AB02','PETHIDINE','01829G','Injection 100 mg in 2 mL ampoule','injection',1,400,100,'mg','',1,3,1);


--- final detail from 10year
	select pin,
	ptnt_state as state,
	yob,
	sex as gender,
	spply_dt as supply_date,
	pbs_rgltn24_adjst_qty * prscrptn_cnt as quantity,
	i.ddd_mg_factor, i.unit_wt, i.item_form, i.generic_name, i.atc, i.item_code, i.type_code,
	g.type_name
	FROM ", base_table, " pbs
	JOIN patient p USING (pin )
	JOIN continuing_item i ON (pbs.pbs_code = i.item_code )
	JOIN generictype g USING (type_code)
	WHERE (i.atc LIKE 'N02A%' OR i.atc LIKE 'N05B%' OR i.atc LIKE 'N05C%' )

--- final  summary from 10 year
with a as (
select pin, 
ptnt_state as state, 
yob, 
sex as gender, 
spply_dt as supply_date, 
pbs_rgltn24_adjst_qty * prscrptn_cnt as quantity, 
i.ddd_mg_factor, i.unit_wt, i.item_form, i.generic_name, i.atc, i.item_code, i.type_code,
g.type_name
FROM pbs_r pbs 
JOIN patient p USING (pin )
JOIN continuing_item i ON (pbs.pbs_code = i.item_code )
JOIN generictype g USING (type_code)
WHERE (i.atc LIKE 'N02A%' OR i.atc LIKE 'N05B%' OR i.atc LIKE 'N05C%' )
) select type_name, date_part( 'year', supply_date)  as supply_year, sum(quantity)
from a 
where date_part( 'year', supply_date) >'2012'
group by 1,2
order by 2,1
;

--- final fromo mofi
select type_name, date_part( 'year', supply_date)  as supply_year, sum(quantity)
FROM continuing.continuing c
JOIN continuing.item i using (item_code )
JOIN generictype g USING (type_code)
where date_part( 'year', supply_date) >'2012'
AND date_part( 'year', supply_date) <='2014'
group by 1,2
order by 2,1
;

-- check to see if patient is in more than 1 state
with p as (
	select distinct pin, ptnt_state
	from pbs_r
) 
select pin, count(*)
from p
group by 1
HAVING  count(*) >1;



-- extract patient types from pbs

create table temp.people_disease as
select pin, chronic_disease_category, sum(prscrptn_cnt) as scripts, sum( pbs_rgltn24_adjst_qty * prscrptn_cnt) as pills
from pbs p  
JOIN pbs_item USING (pbs_code) 
JOIN pbs_atc using (atc_code) 
JOIN chronic_disease using (chronic_disease_id) 
GROUP by 1, 2 ;


create table temp.people_disease as

select pin, chronic_disease_category, sum(prscrptn_cnt) as scripts, sum( pbs_rgltn24_adjst_qty * prscrptn_cnt) as pills
from pbs_rr p
JOIN pbs_item USING (pbs_code) 
JOIN pbs_atc using (atc_code) 
JOIN chronic_disease using (chronic_disease_id) 
GROUP by 1, 2 ;



drop table temp.pbs;
create table temp.pbs as 
  select pin,
  spply_dt as supply_date,
  pbs_rgltn24_adjst_qty * prscrptn_cnt as quantity,
  pbs_code as item_code 
  FROM  pbs
  JOIN pbs_item i USING (pbs_code) 
  WHERE (i.atc_code LIKE 'N02A%' OR i.atc_code LIKE 'N05B%' OR i.atc_code LIKE 'N05C%' );




pg_dump him5ihc_pbs -t temp.pbs -t temp.people_disease >/tmp/pp.sql; bzip2 /tmp/pp.sql


# find out the most popular state for each pbs person
create table largest_state as 
with states as 
(
  select pin, ptnt_state as state, count(*) as n
  from pbs 
  GROUP BY 1,2
), largest_state as 
(
  select pin, max( n ) as n
  FROM states
  GROUP BY 1 
) 
SELECT pin, max( state )  as state
FROM states 
JOIN largest_state USING (pin, n )
GROUP BY 1;


  
# find out the most popular state for each mbs person
create table largest_state as 
with states as 
(
	select pin, pinstate as state, count(*) as n
	from mbs 
	GROUP BY 1,2
), largest_state as 
(
	select pin, max( n ) as n
	FROM states
	GROUP BY 1 
) 
SELECT pin, max( state )  as state
FROM states 
JOIN largest_state USING (pin, n )
GROUP BY 1;


alter table patient add  pbs_state varchar(3);
create index on largest_state( pin );
update patient p set pbs_state = (select pbs_state from largest_state l where l.pin=p.pin );

alter table patient add  mbs_state character(1);
create index on largest_state( pin );
update patient p set mbs_state = (select state from largest_state l where l.pin=p.pin );


select mbs_state, pbs_state, state, count(*)
from patient p
group by 1,2, 3
order by 1,2;

alter table patient add  state varchar(3);
update patient set state= pbs_state where pbs_state != 'UNK' and pbs_state is not null;;
create index on patient( state );
update patient set state= 'NSW' where mbs_state = '1' and state is null;
update patient set state= 'VIC' where mbs_state = '2' and state is null;
update patient set state= 'SA' where mbs_state = '3' and state is null;
update patient set state= 'QLD' where mbs_state = '4' and state is null;
update patient set state= 'WA' where mbs_state = '5' and state is null;


