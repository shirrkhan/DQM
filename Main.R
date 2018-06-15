library("glue")
library(DBI)
library(qdap)

source("prepare.R")
source("custom_check.R")
source("miss_check.R")

environemt <- 'SQL'
database <- 'AdventureworksDW2016CTP3'
date <- "2018-03-30"
dqm_flow_nm <- 'TEST_DQM2'
check_list <- c("ErrorTypeCD", "SchemaName", "TableName", "ColumnName", "DqmKeyFields")

if (environemt == 'SQL') con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server}; server={LOCAL-SERVER\\LOCALDB}")

date_prepare(date)
param_prepare(dqm_flow_nm, date, environemt)

act_table <- ''
prev_table <- ''
for (i in 1:nrow(Param_Table)) {
  act_table <- Param_Table[i,"TableName"]
  
  if (act_table != prev_table) {
      print ("új tábla lekérése")

      filter <- Table_Filter[Table_Filter$TableName == Param_Table[i,"TableName"]]
      filter[order(filter$OrderNumber)]
      
      filter_string <- glue(filter$RELATION, ' ', filter$LogicalRelationCD, exp1 = filter$EXPRESSION1, exp2 = filter$EXPRESSION2)
      query_string <- glue('SELECT *
                            FROM {database}.{Param_Table[i,"SchemaName"]}.{Param_Table[i,"TableName"]} T1
                            WHERE {filter_string}'
                            )
      print(query_string)
      
      sql <- glue_sql(query_string
               ,.con= con)
      query <- DBI::dbSendQuery(con, sql)
      work_table <<- DBI::dbFetch(query)
      DBI::dbClearResult(query)
    }
  

  if(Param_Table[i,"CheckTypeCD"] == "MISS") print("Missing")
  #else if (Param_Table[i,"CHECK_TYPE_CD"] == "CUST") custom(table, Param_Table[i,check_list])
  
  prev_table <- act_table
}

