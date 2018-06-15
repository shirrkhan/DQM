-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
USE DQM
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

IF OBJECT_ID('INSERT_ELT_FLOW') IS NOT NULL
DROP PROCEDURE INSERT_ELT_FLOW
GO

CREATE PROCEDURE INSERT_ELT_FLOW 
	@ETL_FLOW_NM nvarchar(255),
	@ETL_DESC nvarchar(255)
AS
BEGIN
	SET NOCOUNT ON;

	MERGE ETL_FLOW as target
	USING (SELECT @ETL_FLOW_NM, @ETL_DESC) as source (EtlFlowName, EtlDescription)
	ON	target.Name = source.ETLFlowName
	WHEN MATCHED THEN
		UPDATE
			SET target.Description = source.EtlDescription,
				target.ModificationDate = GETDATE()	
	WHEN NOT MATCHED THEN
		INSERT (
			Name,
			Description,
			CreationDate)
		VALUES(
			EtlFlowName,
			EtlDescription,
			GETDATE()
		);
END
GO

IF OBJECT_ID('INSERT_DQM_FLOW') IS NOT NULL
DROP PROCEDURE INSERT_DQM_FLOW
GO

CREATE PROCEDURE INSERT_DQM_FLOW 
	@ETL_FLOW_NM nvarchar(255),
	@DQM_FLOW_NM nvarchar(255),
	@DQM_DESC nvarchar(255)
AS
BEGIN
	SET NOCOUNT ON;

	MERGE DQM_FLOW as target
	USING (
			SELECT EtlflowID,@ETL_FLOW_NM, @DQM_FLOW_NM, @DQM_DESC
			FROM ETL_FLOW
			WHERE Name = @ETL_FLOW_NM AND deletedFlag = 0
		   ) as source (EtlflowID, EtlFlowName, DqmFlowName, DqmDescription)
	ON	target.Name = source.DqmFlowName
	WHEN MATCHED THEN
		UPDATE
			SET target.Description = source.DqmDescription,
				target.ModificationDate = GETDATE()	
	WHEN NOT MATCHED THEN
		INSERT (
			EtlFlowID,
			Name,
			Description,
			CreationDate)
		VALUES(
			EtlFlowID,
			DqmFlowName,
			DqmDescription,
			GETDATE()
		);
END
GO

/*
INSERT_DQM_CHECK_DEFINITION
	Paraméter:
	 - módosuló sorok (tábla)

	Ha DqmFlowID + ErrorTypeCD alapján nincs, akkor új sor
	Egyébként
		Ha bármelyik másik mezõ változott, kivéve ValidFrom és ValidTo, akkor
			1. azon sorok leválogatása, ahol régi.ValidFrom < új.ValidFrom < régi ValidTo vagy régi.ValidFrom < új.ValidTo < régi ValidTo
				- ID
				- Mûvelet = Ha régi.ValidFrom = min(régi.ValidFrom), akkor SplitMin
							Egyébként ha régi.ValidTo = Max(régi.ValidTo), akkor SplitMax
							Egyébként Törlés

			2. UPDATE: elsõ pontban kapott rekordok közül azon sorok esetén, ahol régi.ValidFrom = min(régi.ValidFrom) ==> ValidTo = min(új.ValidFrom) - 1 nap
			3. UPDATE: elsõ pontban kapott rekordok közül azon sorok esetén, ahol régi.ValidTo = Max(régi.ValidTo) ==> ValidTo = min(új.ValidFrom) - 1 nap
			4. INSERT: inputként kapott sorok 
			


		Egyébként nincs teendõ
		
*/

/*
IF OBJECT_ID('INSERT_DQM_CHECK_DEFINITION') IS NOT NULL
DROP PROCEDURE INSERT_DQM_CHECK_DEFINITION
GO

CREATE PROCEDURE INSERT_DQM_CHECK_DEFINITION 
	@DQM_check XML
AS
BEGIN

	declare @DQM_CHECK_DEFINITION table(
		[DqmFlowName] [nvarchar](255) NOT NULL,
		[ErrorTypeCD] [nvarchar](255) NOT NULL,
		[CheckTypeCD] [nvarchar](255) NOT NULL,
		[SchemaName] [nvarchar](255) NOT NULL,
		[TableName] [nvarchar](255) NOT NULL,
		[ColumnName] [nvarchar](255) NULL,
		[DqmKeyFields] [nvarchar](255) NULL,
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
		x.Rec.query('./ValidFrom').value('.', 'date') AS 'ValidFrom',
		x.Rec.query('./ValidTo').value('.', 'date') AS 'ValidTo'
	FROM @DQM_check.nodes ('/DQM_CHECKS/DQM_CHECK') as x(Rec)

	INSERT INTO @Max_ValidTo(
		DqmFlowName,
		ErrorTypeCD,
		ValidTo
	)
	SELECT
		DCD.DqmFlowName,
		DCD.ErrorTypeCD,
		MAX(DCD.Validto)
	FROM @DQM_CHECK_DEFINITION DCD
	GROUP BY DCD.DqmFlowName, DCD.ErrorTypeCD

	INSERT INTO @TMP_DQM_CHECK_CONDITION(
		[DqmFlowName],
		[ErrorTypeCD],
		[Expression1],
		[RelationID],
		[Expression2],
		[LogicalRelationCD],
		[OrderNumber],
		[CustomCondition],
		[ValidFrom],
		[ValidTo]
	)
	SELECT
		x.Rec.query('./DqmFlowName').value('.', 'nvarchar(255)') AS 'DqmFlowName',
		x.Rec.query('./ErrorTypeCD').value('.', 'nvarchar(255)') AS 'ErrorTypeCD',
		x.Rec.query('./Expression1').value('.', 'nvarchar(255)') AS 'Expression1',
		x.Rec.query('./RelationID').value('.', 'nvarchar(255)') AS 'RelationID',
		x.Rec.query('./Expression2').value('.', 'nvarchar(255)') AS 'Expression2',
		x.Rec.query('./LogicalRelationCD').value('.', 'nvarchar(3)') AS 'LogicalRelationCD',
		x.Rec.query('./OrderNumber').value('.', 'int') AS 'OrderNumber',
		x.Rec.query('./CustomCondition').value('.', 'nvarchar(255)') AS 'CustomCondition',
		x.Rec.query('./ValidFrom').value('.', 'date') AS 'ValidFrom',
		x.Rec.query('./ValidTo').value('.', 'date') AS 'ValidTo'
	FROM @DQM_check.nodes ('/DQM_CHECKS/CONDITION') as x(Rec)

	/* CONDITION feldolgozása */
	IF OBJECT_ID('_TMP_CONDITION_CURRENT') IS NOT NULL
	DROP TABLE _TMP_CONDITION_CURRENT

	SELECT
		DF.[Name] as DqmFlowName,
		DCD.ErrorTypeCD,
		C.[Expression1],
		C.[RelationID],
		C.[Expression2],
		C.[CustomCondition],
		C.[ValidFrom],
		C.[ValidTo]
	INTO _TMP_CONDITION_CURRENT
	FROM CONDITION C
	JOIN DQM_CHECK_DEFINITION DCD
		ON DCD.DqmFlowID = C.DqmFlowID AND
			DCD.ErrorTypeCD = C.ErrorTypeCD
	JOIN DQM_FLOW DF
		ON DCD.DqmFlowID = DF.DqmFlowID
	WHERE DF.DeletedFlag = 0

	IF OBJECT_ID('_TMP_CONDITION_UNION') IS NOT NULL
	DROP TABLE _TMP_CONDITION_UNION

	SELECT
		a.*
	INTO _TMP_CONDITION_UNION 
	FROM(
		SELECT
			[DqmFlowName],
			[ErrorTypeCD],
			[Expression1],
			[RelationID],
			[Expression2],
			[LogicalRelationCD],
			[OrderNumber],
			[CustomCondition],
			[ValidFrom],
			[ValidTo]
		FROM @TMP_DQM_CHECK_CONDITION
		 
		UNION ALL 

		SELECT 
			[DqmFlowName],
			[ErrorTypeCD],
			[Expression1],
			[RelationID],
			[Expression2],
			[LogicalRelationCD],
			[OrderNumber],
			[CustomCondition],
			[ValidFrom],
			[ValidTo]
		FROM _TMP_CONDITION_CURRENT
	) a

	IF OBJECT_ID('_TMP_CONDITION') IS NOT NULL
	DROP TABLE _TMP_CONDITION

	SELECT
		ROW_NUMBER() over(order by a.validfrom) as order_number,
		a.*
	INTO _TMP_CONDITION
	FROM (
	SELECT
		u.DqmFlowName,
		u.ErrorTypeCD,
		u.[Expression1],
		u.[RelationID],
		u.[Expression2],
		u.[LogicalRelationCD],
		u.[OrderNumber],
		u.[CustomCondition],
		Min(Case when u.ValidFrom >= r.ValidFrom then u.ValidFrom
			else r.ValidFrom
		end) ValidFrom
	FROM _TMP_CONDITION_CURRENT r
	FULL OUTER JOIN _TMP_CONDITION_UNION u
		on  r.DqmFlowName = u.DqmFlowName AND
			r.ErrorTypeCD = u.ErrorTypeCD AND
			r.Expression1 = u.Expression1 AND
			r.RelationID = u.RelationID AND
			r.Expression2 = u.Expression2 AND
			r.LogicalRelationCD = u.LogicalRelationCD AND
			r.OrderNumber = u.OrderNumber AND
			r.CustomCondition = u.CustomCondition AND
			(
				r.validfrom <= u.ValidFrom AND u.ValidFrom <= r.ValidTo
				OR
				r.validfrom <= u.ValidTo AND u.ValidTo <= r.ValidTo
			)
	GROUP BY u.DqmFlowName,
			 u.ErrorTypeCD,
			 u.[Expression1],
			 u.[RelationID],
			 u.[Expression2],
			 u.[LogicalRelationCD],
			 u.[OrderNumber],
			 u.[CustomCondition]
	) a

	/* DQM_CHECK feldolgozása */
	IF OBJECT_ID('_TMP_DQM_CHECK_CURRENT') IS NOT NULL
	DROP TABLE _TMP_DQM_CHECK_CURRENT

	SELECT 
		DF.[Name] as DqmFlowName,
		DCD.[ErrorTypeCD],
		DCD.[CheckTypeCD],
		DCD.[SchemaName],
		DCD.[TableName],
		DCD.[ColumnName],
		DCD.[DqmKeyFields],
		DCD.[ValidFrom],
		DCD.[ValidTo]
	INTO _TMP_DQM_CHECK_CURRENT
	FROM DQM_CHECK_DEFINITION DCD
	JOIN DQM_FLOW DF
		ON DCD.DqmFlowID = DF.DqmFlowID
	WHERE DF.DeletedFlag = 0
		
	IF OBJECT_ID('_TMP_DQM_CHECK_UNION') IS NOT NULL
	DROP TABLE _TMP_DQM_CHECK_UNION

	SELECT
		a.*
	INTO _TMP_DQM_CHECK_UNION 
	FROM(
		SELECT
			[DqmFlowName],
			[ErrorTypeCD],
			[CheckTypeCD],
			[SchemaName],
			[TableName],
			[ColumnName],
			[DqmKeyFields],
			[ValidFrom],
			[ValidTo]
		FROM @DQM_CHECK_DEFINITION
		 
		UNION ALL 

		SELECT 
			[DqmFlowName],
			[ErrorTypeCD],
			[CheckTypeCD],
			[SchemaName],
			[TableName],
			[ColumnName],
			[DqmKeyFields],
			[ValidFrom],
			[ValidTo]
		FROM _TMP_DQM_CHECK_CURRENT
	) a

	IF OBJECT_ID('_TMP_DQM_CHECK') IS NOT NULL
	DROP TABLE _TMP_DQM_CHECK

	SELECT
		ROW_NUMBER() over(order by a.validfrom) as order_number,
		a.*
	INTO _TMP_DQM_CHECK
	FROM (
	SELECT
		u.DqmFlowName,
		u.ErrorTypeCD,
		Min(Case when u.ValidFrom >= r.ValidFrom then u.ValidFrom
			else r.ValidFrom
		end) ValidFrom
	FROM _TMP_DQM_CHECK_CURRENT r
	FULL OUTER JOIN _TMP_DQM_CHECK_UNION u
		on  r.DqmFlowName = u.DqmFlowName AND
			r.ErrorTypeCD = u.ErrorTypeCD AND
			(
				r.validfrom <= u.ValidFrom AND u.ValidFrom <= r.ValidTo
				OR
				r.validfrom <= u.ValidTo AND u.ValidTo <= r.ValidTo
			)
	GROUP BY u.DqmFlowName,
			 u.ErrorTypeCD
	) a

	IF OBJECT_ID('_TMP_DQM_CHECK_NEW') IS NOT NULL
	DROP TABLE _TMP_DQM_CHECK_NEW

	SELECT
		a.[DqmFlowName],
		a.[ErrorTypeCD],
		c.[CheckTypeCD],
		c.[SchemaName],
		c.[TableName],
		c.[ColumnName],
		c.[DqmKeyFields],
		a.ValidFrom,
		coalesce(dateadd(d,-1,b.ValidFrom), MV.ValidTo) as Validto
	INTO _TMP_DQM_CHECK_NEW
	FROM _TMP_DQM_CHECK a
	LEFT JOIN _TMP_DQM_CHECK b
		on a.order_number = b.order_number-1
	LEFT JOIN _TMP_DQM_CHECK_UNION c
		on a.DqmFlowName = c.DqmFlowName AND
		   a.ErrorTypeCD = c.ErrorTypeCD
	LEFT JOIN @Max_ValidTo MV
		ON a.DqmFlowName = MV.DqmFlowName AND
		   a.ErrorTypeCD = MV.ErrorTypeCD


END

GO*/

IF OBJECT_ID('INSERT_DQM_CHECK_DEFINITION') IS NOT NULL
DROP PROCEDURE INSERT_DQM_CHECK_DEFINITION
GO

CREATE PROCEDURE INSERT_DQM_CHECK_DEFINITION 
	@DQM_check XML
AS
BEGIN
	declare @DQM_CHECK_DEFINITION table(
		[DqmFlowName] [nvarchar](255) NOT NULL,
		[ErrorTypeCD] [nvarchar](255) NOT NULL,
		[CheckTypeCD] [nvarchar](255) NOT NULL,
		[SchemaName] [nvarchar](255) NOT NULL,
		[TableName] [nvarchar](255) NOT NULL,
		[ColumnName] [nvarchar](255) NULL,
		[DqmKeyFields] [nvarchar](255) NULL,
		[DeletedFlag] bit,
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

	INSERT INTO [DBO].DQM_CHECK_DEFINITION_HIST(
			[DqmFlowID]
           ,[ErrorTypeCD]
           ,[CheckTypeCD]
           ,[SchemaName]
           ,[TableName]
           ,[ColumnName]
           ,[DqmKeyFields]
           ,[ValidFrom]
           ,[ValidTo]
		   ,[CreationDate]
		   ,[ModificationDate]
		   )
	SELECT
		 r.[DQMFLOWID]
		,r.[ERRORTYPECD]
		,r.[CHECKTYPECD]
		,r.[SCHEMANAME]
		,r.[TABLENAME]
		,r.[COLUMNNAME]
		,r.[DQMKEYFIELDS]
		,r.[VALIDFROM]
		,r.[VALIDTO]
		,r.CreationDate
		,GETDATE()
	FROM DQM_CHECK_DEFINITION r
	join DQM_FLOW DF
		on	r.DQMFLOWID = DF.DqmFlowID
	WHERE Exists(SELECT 1 FROM @DQM_CHECK_DEFINITION u WHERE DF.Name = u.DqmFlowName AND r.ERRORTYPECD = u.ErrorTypeCD)

	DELETE FROM DQM_CHECK_DEFINITION
	FROM DQM_CHECK_DEFINITION r
	join DQM_FLOW DF
		on	r.DQMFLOWID = DF.DqmFlowID
	WHERE Exists(SELECT 1 FROM @DQM_CHECK_DEFINITION u WHERE DF.Name = u.DqmFlowName AND r.ERRORTYPECD = u.ErrorTypeCD)

	INSERT INTO [DBO].DQM_CHECK_DEFINITION(
			[DqmFlowID]
           ,[ErrorTypeCD]
           ,[CheckTypeCD]
           ,[SchemaName]
           ,[TableName]
           ,[ColumnName]
           ,[DqmKeyFields]
           ,[ValidFrom]
           ,[ValidTo]
		   )
	SELECT
		 [DqmFlowID]
        ,[ErrorTypeCD]
        ,[CheckTypeCD]
        ,[SchemaName]
        ,[TableName]
        ,[ColumnName]
        ,[DqmKeyFields]
        ,[ValidFrom]
        ,[ValidTo]
	FROM @DQM_CHECK_DEFINITION DCD
	join DQM_FLOW DF
		on	DCD.DqmFlowName = DF.Name

END
GO