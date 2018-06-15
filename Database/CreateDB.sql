/*
USE master
GO

IF (SELECT 1 FROM sys.databases where name = 'DQM') IS NOT NULL
DROP DATABASE DQM

CREATE DATABASE DQM
GO
*/
USE [DQM]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('DICTIONARY') IS NOT NULL
DROP TABLE DICTIONARY

IF OBJECT_ID('CONDITION_HIST') IS NOT NULL
DROP TABLE CONDITION_HIST

IF OBJECT_ID('CONDITION') IS NOT NULL
DROP TABLE CONDITION

IF OBJECT_ID('TABLE_FILTER') IS NOT NULL
DROP TABLE TABLE_FILTER

IF OBJECT_ID('RELATION') IS NOT NULL
DROP TABLE [dbo].[RELATION]

IF OBJECT_ID('DQM_CHECK_DEFINITION_HIST') IS NOT NULL
DROP TABLE DQM_CHECK_DEFINITION_HIST

IF OBJECT_ID('DQM_CHECK_DEFINITION') IS NOT NULL
DROP TABLE DQM_CHECK_DEFINITION

IF OBJECT_ID('DQM_FLOW') IS NOT NULL
DROP TABLE DQM_FLOW

IF OBJECT_ID('ETL_FLOW') IS NOT NULL
DROP TABLE ETL_FLOW

CREATE TABLE [dbo].[ETL_FLOW](
	[EtlFlowID] [int] NOT NULL IDENTITY(1,1) primary key,
	[Name] [nvarchar](255) NOT NULL,
	[Description] [nvarchar](255) NOT NULL,
	[DeletedFlag] bit not null default(0),
	[CreationDate] datetime,
	[ModificationDate] datetime
)

GO

CREATE TABLE [dbo].[DQM_FLOW](
	[DqmFlowID] [int] NOT NULL IDENTITY(1,1) primary key,
	[EtlFlowID] [int] NOT NULL references ETL_FLOW,
	[Name] [nvarchar](255) NOT NULL,
	[Description] [nvarchar](255) NOT NULL,
	[DeletedFlag] bit not null default(0),
	[CreationDate] datetime,
	[ModificationDate] datetime
)

GO

CREATE TABLE [dbo].[DQM_CHECK_DEFINITION](
	[DqmFlowID] [int] NOT NULL references DQM_FLOW,
	[ErrorTypeCD] [nvarchar](255) NOT NULL,
	[CheckTypeCD] [nvarchar](255) NOT NULL,
	[SchemaName] [nvarchar](255) NOT NULL,
	[TableName] [nvarchar](255) NOT NULL,
	[ColumnName] [nvarchar](255) NULL,
	[DqmKeyFields] [nvarchar](255) NULL,
	[ValidFrom] date not null,
	[ValidTo] date not null default('2100.12.31'),
	[CreationDate] datetime default(GETDATE()),
	CONSTRAINT PK_DQM_CHECK_DEFINITION PRIMARY KEY (DqmFlowID, ErrorTypeCD, ValidFrom)
) 

GO

CREATE TABLE [dbo].[DQM_CHECK_DEFINITION_HIST](
	[DqmCheckDefinitionHistoryID] [int] NOT NULL primary key,
	[DqmFlowID] [int] NOT NULL references DQM_FLOW,
	[ErrorTypeCD] [nvarchar](255) NOT NULL,
	[CheckTypeCD] [nvarchar](255) NOT NULL,
	[SchemaName] [nvarchar](255) NOT NULL,
	[TableName] [nvarchar](255) NOT NULL,
	[ColumnName] [nvarchar](255) NULL,
	[DqmKeyFields] [nvarchar](255) NULL,
	[ConditionID] [int] NULL,
	[ValidFrom] date not null,
	[ValidTo] date not null default('2100.12.31'),
	[CreationDate] datetime,
	[ModificationDate] datetime
) 

GO

CREATE TABLE [dbo].[RELATION](
	[ID] [int] NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[Label] [nvarchar](50) NULL,
	[ValueSQL] [nvarchar](50) NULL,
	[ValueSAS] [nvarchar](50) NULL
)

GO

INSERT INTO [dbo].[relation](
			[Label]
           ,[ValueSQL]
           ,[ValueSAS])
     VALUES
           ('Equal',				'{exp1} = {exp2}',				'{exp1} eq {exp2}'),
		   ('Not equal',			'{exp1} != {exp2}',				'{exp1} ne {exp2}'),
		   ('Greater than',			'{exp1} > {exp2}',				'{exp1} gt {exp2}'),
		   ('Greater or equal then','{exp1} >= {exp2}',				'{exp1} ge {exp2}'),
		   ('Less then',			'{exp1} < {exp2}',				'{exp1} lt {exp2}'),
		   ('Less or equal then',	'{exp1} <= {exp2}',				'{exp1} le {exp2}'),
		   ('In a list',			'{exp1} in {exp2}',				'{exp1} in {exp2}'),
		   ('Contains',				'{exp1} like ''%{exp2}%''',		'{exp1} ? ''{exp2}''')
GO

CREATE TABLE [dbo].[TABLE_FILTER](
	[TableFilterID] [int] NOT NULL IDENTITY(1,1) primary key,
	[TableName] [nvarchar](255) NOT NULL,
	[Expression1] [nvarchar](255) NOT NULL,
	[RelationID] [int] NOT NULL references Relation,
	[Expression2] [nvarchar](255) NOT NULL,
	[LogicalRelationCD] nvarchar(3),
	[OrderNumber] int,
	[CustomCondition] [nvarchar](max),
	[DeletedFlag] bit not null default(0),
	[ValidFrom] date not null,
	[ValidTo] date not null default('2100.12.31'),
	[CreationDate] datetime,
	[ModificationDate] datetime
) 

GO

CREATE TABLE [dbo].[CONDITION](
	[DqmFlowID] [int] NOT NULL references DQM_FLOW,
	[ErrorTypeCD] [nvarchar](255) NOT NULL,
	[Expression1] [nvarchar](255) NOT NULL,
	[RelationID] [int] NOT NULL references Relation,
	[Expression2] [nvarchar](255) NOT NULL,
	[LogicalRelationCD] nvarchar(3),
	[OrderNumber] int,
	[CustomCondition] [nvarchar](max),
	[ValidFrom] date not null,
	[ValidTo] date not null default('2100.12.31'),
	[CreationDate] datetime,
	[ModificationDate] datetime,
	CONSTRAINT PK_CONDITION PRIMARY KEY (DqmFlowID,ErrorTypeCD)
)

GO

CREATE TABLE [dbo].[CONDITION_HIST](
	[ConditionHistoryID] [int] NOT NULL IDENTITY(1,1) primary key,
	[DqmFlowID] [int] NOT NULL references DQM_FLOW,
	[ErrorTypeCD] [nvarchar](255) NOT NULL,
	[Expression1] [nvarchar](255) NOT NULL,
	[RelationID] [int] NOT NULL references Relation,
	[Expression2] [nvarchar](255) NOT NULL,
	[LogicalRelationCD] nvarchar(3),
	[OrderNumber] int,
	[CustomCondition] [nvarchar](max),
	[ValidFrom] date not null,
	[ValidTo] date not null default('2100.12.31'),
	[CreationDate] datetime,
	[ModificationDate] datetime
)

GO

CREATE TABLE [dbo].[DICTIONARY](
	[ID] [int] NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[Branch] [nvarchar](50) NOT NULL,
	[Code] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](255) NOT NULL,
	[DeletedFlag] bit not null default(0),
	[ValidFrom] date not null,
	[ValidTo] date not null default('2100.12.31'),
	[CreationDate] datetime,
	[ModificationDate] datetime
)

GO

INSERT INTO [DICTIONARY]
			(
				[BRANCH],
				[CODE],
				[DESCRIPTION],
				[ValidFrom],
				CreationDate
			)
	VALUES
			('LOGIC_OPERATOR', 'AND', '','2018.01.01', GETDATE()),
			('LOGIC_OPERATOR', 'OR', '', '2018.01.01',GETDATE()),
			('CHECK_TYPE_CD', 'CUST', '', '2018.01.01',GETDATE()),
			('CHECK_TYPE_CD', 'MISS', '', '2018.01.01',GETDATE()),
			('CHECK_TYPE_CD', 'UNIQ', '', '2018.01.01',GETDATE()),
			('CHECK_TYPE_CD', 'DIFF', '', '2018.01.01',GETDATE()),
			('CHECK_TYPE_CD', 'RTN', '', '2018.01.01',GETDATE()),
			('CHECK_TYPE_CD', 'RT0', '', '2018.01.01',GETDATE()),
			('DATABASE','AdventureworksDW2016CTP3','', '2018.01.01',GETDATE())
GO