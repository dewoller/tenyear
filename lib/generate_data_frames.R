# get the actual data from the cache, put it in the parent enironment

cache_directory_name = 'data/cache/'
cache_file_prefix = 'mycache_'
dataset = '_rr'
library('DataCache')

clear_cache = function( dataset ='_rr') { 

  rmcache = paste0( 'rm ', cache_directory_name, '/', cache_file_prefix, dataset, '*')
#  dput(rmcache)
  system( rmcache )
}

test_generate_data_frames = function() {


  debug( data.cache )
  undebug( data.cache )
  debug( get_data_from_cache )
  debug( generate_data_frames )
  undebug( get_data_from_cache )
  undebug( generate_data_frames )
  generate_data_frames('')
  generate_data_frames('_r')

  get_data_from_cache('_rr')
  get_data_from_cache('_r')
  get_data_from_cache('')

  clear_cache('_rr')
  clear_cache('_r')

  clear_cache('full')
  

}


get_data_from_cache = function( limit = 1000 ) {
  data_id = paste0(cache_file_prefix, limit )

  tic( 'get data from cache or generate' )
  rv=data.cache( generate_data_frames, 
             frequency=yearly, 
             cache.name=data_id,
             cache.dir=cache_directory_name,
             envir=parent.frame(1), 
             wait=FALSE,
             limit )
  toc()
  rv
}

# generate all the data
dataset='' 
generate_data_frames = function( limit ) 
{

  tic( "Getting drug data from database")
  get_drug( )  %>%
    mutate(drug_type=ifelse(is_benzo(type_code), 'benzodiazepine', 'opioid'),
           type_name = ifelse( !is_benzo( type_code), type_name, 
                              stringr::str_extract( generic_name, '[^ ]*')),
           ) %>% 
    { . } -> df_drug

  toc()
  tic( "Getting main data from database")
  get_10year( limit )  %>%
    inner_join( df_drug, by='item_code') %>%
    mutate( n_dose = quantity * unit_wt / ddd_mg_factor , 
           quarter = quarter(supply_date, with_year = TRUE), 
           supply_year = as.character(year(supply_date)) 
          ) %>% 
    { . } -> df_10year
  toc()

  age_groups = structure(1:4, .Label = c("0-19", 
                                        "20-44", 
                                        "45-64", 
                                        "65+"), 
                        class = "factor")

  tic( "Getting Population")
  df_population = get_population_df()
  toc()

  tic( "Getting patients")
  get_patient() %>% 
    {.} -> df_patient
  toc()

  tic( "Getting diseases")
  get_disease() %>% 
      {.} -> df_disease
  toc()

  tic( "Getting opioid usage")
    df_10year%>%
      group_by(pin, drug_type) %>%
      summarise( 
        n_quarter = n_distinct( quarter ),
        usage_category= cut( n_quarter, 
                            c(-1, 1,7,13, 999999), 
                            labels = qw("one-off short-term long-term regular"),
                            ordered_result=TRUE
                            ) 
                ) %>%
      ungroup() %>% 
      {.} -> df_patient_usage_temp
#
    full_join( 
              filter( df_patient_usage_temp, drug_type=="opioid" ) ,
              filter( df_patient_usage_temp, drug_type=="benzodiazepine" ) ,
              by='pin') %>%
      select( pin, starts_with('n_'), starts_with('usage') ) %>% 
      set_names( qc( pin, 
                    opioid_n_quarter, 
                  benzo_n_quarter, 
                  opioid_usage_category,  
                  benzo_usage_category) ) %>% 
      mutate( 
        opioid_n_quarter = ifelse( is.na( opioid_n_quarter ), 0, opioid_n_quarter ),
        benzo_n_quarter = ifelse( is.na( benzo_n_quarter ), 0, benzo_n_quarter ), 
        both_n_quarter= opioid_n_quarter + benzo_n_quarter,  
        both_category= cut( pmin( opioid_n_quarter , benzo_n_quarter ), 
                          c(-1, 1,7,13, 999999), 
                          labels = qw("one-off short-term long-term regular"),
                          ordered_result=TRUE
                          ) ) %>%
    { . } -> df_patient_usage
  rm( df_patient_usage_temp )
    toc()


     list( 
         "df_10year"=df_10year,
         "df_patient_usage" = df_patient_usage, 
         "df_population" = df_population,
         "df_patient" = df_patient,
         "df_disease" = df_disease,
         #"base_map" =  get_australia_base_map(1:8), 
         "age_groups" = age_groups
         )
}


