USE [DQM]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('DQM_Param_table') IS NOT NULL
DROP FUNCTION [dbo].[DQM_Param_table]
GO

CREATE FUNCTION DQM_Param_table
(   
    @DQM_FLOW_NM nvarchar(50),
	@date_param date
)
RETURNS TABLE 
AS
RETURN 
SELECT
	DF.[Name]as DQM_FLOW_NAME,
	DCP.[CheckTypeCD],
	DCP.ErrorTypeCD,
	DCP.SchemaName,
	DCP.TableName,
	DCP.ColumnName,
	DCP.DqmKeyFields
FROM DQM_CHECK_DEFINITION DCP
JOIN DQM_FLOW DF
	ON DCP.DqmFlowID = DF.DqmFlowID
WHERE DCP.ValidFrom <= @date_param AND @date_param <= DCP.ValidTo
	  AND DF.[NAME] = @DQM_FLOW_NM
	  AND DF.[DeletedFlag] = 0

GO

IF OBJECT_ID('Table_Filters') IS NOT NULL
DROP FUNCTION [dbo].[Table_Filters]
GO

CREATE FUNCTION Table_Filters
(   
	@date_param date,
	@system		nvarchar(20)
)
RETURNS TABLE 
AS
RETURN 
SELECT
	TF.TableName,
	TF.EXPRESSION1,
	TF.EXPRESSION2,
	CASE @system
		WHEN 'SAS' THEN R.ValueSAS
		WHEN 'SQL' THEN R.ValueSQL
	END as RELATION,
	TF.CustomCondition,
	isnull(TF.LogicalRelationCD,'') as LogicalRelationCD,
	TF.OrderNumber
FROM TABLE_FILTER TF
LEFT JOIN RELATION R
	ON TF.RelationID = R.ID
WHERE @date_param >= TF.[ValidFrom] AND @date_param < TF.[ValidTo]

GO

IF OBJECT_ID('DQM_Conditions') IS NOT NULL
DROP FUNCTION [dbo].[DQM_Conditions]
GO

CREATE FUNCTION DQM_Conditions
(   
	@DQM_FLOW_NM nvarchar(50),
	@date_param date,
	@system		nvarchar(20)
)
RETURNS TABLE 
AS
RETURN 
SELECT
	DCP.DqmFlowID,
	DCP.ErrorTypeCD,
	C.EXPRESSION1,
	C.EXPRESSION2,
	CASE @system
		WHEN 'SAS' THEN R.ValueSAS
		WHEN 'SQL' THEN R.ValueSQL
	END as RELATION,
	C.CustomCondition
FROM DQM_CHECK_DEFINITION DCP
JOIN DQM_FLOW DF
	ON DCP.DqmFlowID = DF.DqmFlowID
LEFT JOIN CONDITION C
	ON DCP.DqmFlowID = C.DqmFlowID AND
	   DCP.ErrorTypeCD = C.ErrorTypeCD
LEFT JOIN RELATION R
	ON C.RelationID = R.ID
WHERE DCP.ValidFrom <= @date_param AND @date_param <= DCP.ValidTo AND DF.[NAME] = @DQM_FLOW_NM
	  AND DF.[DeletedFlag] = 0
	  AND @date_param >= C.[ValidFrom] AND @date_param < C.[ValidTo]

GO