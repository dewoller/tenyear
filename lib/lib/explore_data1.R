query  <-  paste0( "
                  --- final 
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
                             ) select type_name, date_part( 'year', supply_date)  as supply_year, sum(quantity) as total_quantity, count(*) as no_scripts
                  from a 
                  where date_part( 'year', supply_date) >'2012'
                  group by 1,2
                  order by 2,1
                  " )
                  my_db_get_query( query, dbname='him5ihc_pbs' ) %>%
                    as.tibble() %>% 
                    { . } -> a

  query  <-  paste0( "
                    --- final fromo mofi
                    select type_name, date_part( 'year', supply_date)  as supply_year, sum(quantity) as total_quantity, count(*) as no_scripts
                    FROM continuing.continuing c
                    JOIN continuing.item i using (item_code )
                    JOIN generictype g USING (type_code)
                    where date_part( 'year', supply_date) >'2012'
                    AND date_part( 'year', supply_date) <='2014'
                    group by 1,2
                    order by 2,1
                " )


  my_db_get_query( query, dbname='mofi' ) %>%
    as.tibble() %>% 
    { . } -> b



  inner_join( b, a, by=qc( type_name, supply_year ), suffix=c( ".continuing", ".10year" )) %>% xc() 




