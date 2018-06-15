--USE [DQM]
--GO

--/****** OBJECT:  TABLE [DBO].[DQM_CHECK_DEFINITION]    SCRIPT DATE: 2018. 04. 11. 11:21:35 ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

--IF OBJECT_ID('REGI') IS NOT NULL
--DROP TABLE REGI

--CREATE TABLE [DBO].[REGI](
--	[DQMFLOWID] [NVARCHAR](255) NOT NULL,
--	[ERRORTYPECD] [NVARCHAR](255) NOT NULL,
--	[CHECKTYPECD] [NVARCHAR](255) NOT NULL,
--	[SCHEMANAME] [NVARCHAR](255) NOT NULL,
--	[TABLENAME] [NVARCHAR](255) NOT NULL,
--	[COLUMNNAME] [NVARCHAR](255) NULL,
--	[DQMKEYFIELDS] [NVARCHAR](255) NULL,
--	[VALIDFROM] [DATE] NOT NULL,
--	[VALIDTO] [DATE] NOT NULL,
--CONSTRAINT [PK_REGI] PRIMARY KEY CLUSTERED 
--(
--	[DQMFLOWID] ASC,
--	[ERRORTYPECD] ASC,
--	[VALIDFROM] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
--) ON [PRIMARY]
--GO

--IF OBJECT_ID('UJ') IS NOT NULL
--DROP TABLE UJ

--CREATE TABLE [DBO].UJ(
--	[DQMFLOWNAME] [NVARCHAR](255) NOT NULL,
--	[ERRORTYPECD] [NVARCHAR](255) NOT NULL,
--	[CHECKTYPECD] [NVARCHAR](255) NOT NULL,
--	[SCHEMANAME] [NVARCHAR](255) NOT NULL,
--	[TABLENAME] [NVARCHAR](255) NOT NULL,
--	[COLUMNNAME] [NVARCHAR](255) NULL,
--	[DQMKEYFIELDS] [NVARCHAR](255) NULL,
--	DELETEDFLAG bit,
--	[VALIDFROM] [DATE] NOT NULL,
--	[VALIDTO] [DATE] NOT NULL,
--CONSTRAINT [PK_UJ] PRIMARY KEY CLUSTERED 
--(
--	[DQMFLOWNAME] ASC,
--	[ERRORTYPECD] ASC,
--	[VALIDFROM] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
--) ON [PRIMARY]
--GO

--USE [DQM]
--GO

--INSERT INTO [DBO].[REGI]
--           ([DQMFLOWID]
--           ,[ERRORTYPECD]
--           ,[CHECKTYPECD]
--           ,[SCHEMANAME]
--           ,[TABLENAME]
--           ,[COLUMNNAME]
--           ,[DQMKEYFIELDS]
--           ,[VALIDFROM]
--           ,[VALIDTO])
--     VALUES
--           (1 ,'CHECK1','MISS','DBO','DIMDEPARTMENTGROUP','WEIGHTUNITMEASURECODE','PRODUCTKEY','2010.01.01','2012.12.31'),
--		   (2 ,'CHECK1','MISS','DBO','DIMDEPARTMENTGROUP','WEIGHTUNITMEASURECODE','PRODUCTKEY','2010.01.01','2012.12.31'),
--		   (2 ,'CHECK1','MISS','DBO','DIMDEPARTMENTGROUP','SIZEUNITMEASURECODE','PRODUCTKEY','2013.01.01','2014.12.31'),
--		   (2 ,'CHECK1','MISS','DBO','DIMDEPARTMENTGROUP','SPANISHPRODUCTNAME','PRODUCTKEY','2015.01.01','2100.12.31')
--GO

--INSERT INTO [DBO].[UJ]
--           ([DQMFLOWNAME]
--           ,[ERRORTYPECD]
--           ,[CHECKTYPECD]
--           ,[SCHEMANAME]
--           ,[TABLENAME]
--           ,[COLUMNNAME]
--           ,[DQMKEYFIELDS]
--		   ,DELETEDFLAG
--           ,[VALIDFROM]
--           ,[VALIDTO])
--     VALUES
--		    ('TEST_DQM1','CHECK1','UNIQ','DBO','DIMDEPARTMENTGROUP','WEIGHTUNITMEASURECODE','PRODUCTKEY',0,'2010.01.01','2100.12.31'),
--			('TEST_DQM2','CHECK1','MISS','DBO','DIMDEPARTMENTGROUP','WEIGHTUNITMEASURECODE','PRODUCTKEY',1,'2010.01.01','2012.12.31'),
--			('TEST_DQM2','CHECK1','MISS','DBO','DIMDEPARTMENTGROUP','SIZEUNITMEASURECODE','PRODUCTKEY',0,'2013.01.01','2015.12.31'),
--			('TEST_DQM2','CHECK1','MISS','DBO','DIMDEPARTMENTGROUP','SPANISHPRODUCTNAME','PRODUCTKEY',0,'2016.01.01','2100.12.31')


--GO

declare @DQM_check XML

SET @DQM_check = (
SELECT 
	 [DqmFlowName]
	,[ErrorTypeCD]
	,[CheckTypeCD]
	,[SchemaName]
	,[TableName]
	,[ColumnName]
	,[DqmKeyFields]
	,DeletedFlag
	,[ValidFrom]
	,[ValidTo]  
FROM uj 
FOR XML RAW('DQM_CHECK'),ROOT('DQM_CHECKS'), ELEMENTS 
)

	declare @DQM_CHECK_DEFINITION table(
		[DqmFlowName] [nvarchar](255) NOT NULL,
		[ErrorTypeCD] [nvarchar](255) NOT NULL,
		[CheckTypeCD] [nvarchar](255) NOT NULL,
		[SchemaName] [nvarchar](255) NOT NULL,
		[TableName] [nvarchar](255) NOT NULL,
		[ColumnName] [nvarchar](255) NULL,
		[DqmKeyFields] [nvarchar](255) NULL,
		DeletedFlag bit,
		[ValidFrom] date not null,
		[ValidTo] date not null
	) 
	
	declare @TMP_DQM_CHECK_CONDITION table(
		[DqmFlowName] [nvarchar](255) NOT NULL,
		[ErrorTypeCD] [nvarchar](255) NOT NULL,
		[Expression1] [nvarchar](255) NOT NULL,
		[RelationID] [int] NOT NULL,
		[Expression2] [nvarchar](255) NOT NULL,
		[LogicalRelationCD] nvarchar(3),
		[OrderNumber] int,
		[CustomCondition] [nvarchar](max),
		[ValidFrom] date not null,
		[ValidTo] date
	)
	
	declare @Max_ValidTo table(
		[DqmFlowName] nvarchar(255),
		[ErrorTypeCD] nvarchar(255),
		ValidTo date
	)

	INSERT INTO @DQM_CHECK_DEFINITION(
		[DqmFlowName],
		[ErrorTypeCD],
		[CheckTypeCD],
		[SchemaName],
		[TableName],
		[ColumnName],
		[DqmKeyFields],
		DeletedFlag,
		[ValidFrom],
		[ValidTo]
	)
	SELECT 
		x.Rec.query('./DqmFlowName').value('.', 'nvarchar(255)') AS 'DqmFlowName',
		x.Rec.query('./ErrorTypeCD').value('.', 'nvarchar(255)') AS 'ErrorTypeCD',
		x.Rec.query('./CheckTypeCD').value('.', 'nvarchar(255)') AS 'CheckTypeCD',
		x.Rec.query('./SchemaName').value('.', 'nvarchar(255)') AS 'SchemaName',
		x.Rec.query('./TableName').value('.', 'nvarchar(255)') AS 'TableName',
		x.Rec.query('./ColumnName').value('.', 'nvarchar(255)') AS 'ColumnName',
		x.Rec.query('./DqmKeyFields').value('.', 'nvarchar(255)') AS 'DqmKeyFields',
		x.Rec.query('./DeletedFlag').value('.', 'bit') AS 'DeletedFlag',
		x.Rec.query('./ValidFrom').value('.', 'date') AS 'ValidFrom',
		x.Rec.query('./ValidTo').value('.', 'date') AS 'ValidTo'
	FROM @DQM_check.nodes ('/DQM_CHECKS/DQM_CHECK') as x(Rec)

	--select * from @DQM_CHECK_DEFINITION

	--IF OBJECT_ID('_TMP_DEFINITION_TO_DELETE') IS NOT NULL
	--DROP TABLE _TMP_DEFINITION_TO_DELETE

	--SELECT
	--	DF.Name,
	--	r.*
	--INTO _TMP_DEFINITION_TO_DELETE
	--FROM regi r
	--join DQM_FLOW DF
	--	on	r.DQMFLOWID = DF.DqmFlowID
	--WHERE Exists(SELECT 1 FROM @DQM_CHECK_DEFINITION u WHERE DF.Name = u.DqmFlowName AND r.ERRORTYPECD = u.ErrorTypeCD)

	DELETE FROM REGI
	FROM regi r
	join DQM_FLOW DF
		on	r.DQMFLOWID = DF.DqmFlowID
	WHERE Exists(SELECT 1 FROM @DQM_CHECK_DEFINITION u WHERE DF.Name = u.DqmFlowName AND r.ERRORTYPECD = u.ErrorTypeCD)

	INSERT INTO [DBO].[REGI](
			[DQMFLOWID]
           ,[ERRORTYPECD]
           ,[CHECKTYPECD]
           ,[SCHEMANAME]
           ,[TABLENAME]
           ,[COLUMNNAME]
           ,[DQMKEYFIELDS]
           ,[VALIDFROM]
           ,[VALIDTO]
		   )
	SELECT
		 [DQMFLOWID]
		,[ERRORTYPECD]
		,[CHECKTYPECD]
		,[SCHEMANAME]
		,[TABLENAME]
		,[COLUMNNAME]
		,[DQMKEYFIELDS]
		,[VALIDFROM]
		,[VALIDTO]
	FROM @DQM_CHECK_DEFINITION DCD
	join DQM_FLOW DF
		on	DCD.DqmFlowName = DF.Name