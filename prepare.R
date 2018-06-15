date_prepare <- function(date){
#  yymmdd <- format(as.Date(date), "%y%m%d")
  
  date_ds <<- rbind(
                      c("&yymm.", format(as.Date(date), "%y%m")), 
                      c("&yymmdd.", format(as.Date(date), "%y%m%d"))
                    )

}

param_prepare <- function(dqm_flow,run_date,server_type){
  #Paraméter tábla lekérdezése
  sql <- glue_sql("
                    SELECT
                    *
                    FROM DQM.dbo.DQM_Param_table({conditions*})
                  "
                  ,conditions = c(dqm_flow,run_date)
                  ,.con = con)
  
  query <- DBI::dbSendQuery(con, sql)
  Param_table <- DBI::dbFetch(query)
  DBI::dbClearResult(query)

  # Paraméter tábla TABLE_NM oszlopában a dátum paraméter feloldása, sorba rendezés
  Param_table$TableName <- mgsub(date_ds[,1],date_ds[,2],Param_table[,"TableName"], fixed = TRUE)
  Param_table[order(Param_table$SchemaName, Param_table$TableName)]
  
  Param_Table <<- Param_table

  sql <- glue_sql("
                    SELECT
                      *
                    FROM DQM.dbo.Table_Filters({conditions*})
                  "
                  ,conditions = c(run_date,server_type)
                  ,.con = con)

  query <- DBI::dbSendQuery(con, sql)
  Table_Filter <<- DBI::dbFetch(query)
  DBI::dbClearResult(query)

  sql <- glue_sql("
                    SELECT
                      *
                    FROM DQM.dbo.DQM_Conditions({conditions*})
                  "
                  ,conditions = c(dqm_flow,run_date,server_type)
                  ,.con = con)
  
  query <- DBI::dbSendQuery(con, sql)
  DQM_Condition <<- DBI::dbFetch(query)
  DBI::dbClearResult(query)
}