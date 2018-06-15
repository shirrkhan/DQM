custom <- function(table, check){
  lib <- check["LIBRARY_NM"]
  table <- check["TABLE_DB_NM"]
  field <- check["COLUMN_NM"]
  
  condition <- check["ERR_CHECK_CONDITION_TXT"]
  
  sql <- glue_sql("
           SELECT
                  {lib} as SOURCE_LIBRARY,
                  {table} as SOURCE_TABLE,
                  {field} as SOURCE_FIELD
           FROM {lib}.{table}
           WHERE {condition}
           ",.con=con)
  
  print(sql)
  #query <- DBI::dbGetQuery(con, sql)
}