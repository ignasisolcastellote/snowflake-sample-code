USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE FOOBAR_DB;

-- drop schemas RAW and STAGE if they exist
DROP SCHEMA IF EXISTS FOOBAR_DB.RAW;
DROP SCHEMA IF EXISTS FOOBAR_DB.STG;
