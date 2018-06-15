miss <- function(table, check){
  
  row_filter <- is.as(table[,check$COLUMN_NM])
  column_selector <- c(check$DQM_KEY_FIELDS_TXT,check$COLUMN_NM)
  
  miss_check <- table[row_filter, column_selector]
  
  miss_check <- cbind(miss_check, check$ERRTYPE_CD, check$SCHEMA_NM, check$TABLE_NM)
  
  miss_check[1,]
  
  # sql <- glue_sql("
  #                 SELECT
  #                 {schema} as SOURCE_LIBRARY,
  #                 {table} as SOURCE_TABLE,
  #                 {field} as SOURCE_FIELD
  #                 FROM {lib}.{table}
  #                 WHERE {field} IS NULL
  #                 "
  #                 ,schema = check$SCHEMA_NM
  #                 ,table = check$TABLE_NM
  #                 ,field = check$COLUMN_NM
  #                 ,.con=con)
  # 
  # print(sql)
  # #query <- DBI::dbGetQuery(con, sql)
}