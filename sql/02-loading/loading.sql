USE ROLE SYSADMIN;
USE WAREHOUSE SNOWPROCORE;
USE DATABASE SNOWPROCORE;
USE SCHEMA PUBLIC;

-- ****************************** 1.- File Format ******************************
CREATE OR REPLACE FILE FORMAT SNOWPROCORE.PUBLIC.FILE_FORMAT_JSON_GENERIC
 TYPE = 'JSON'
 ENABLE_OCTAL = FALSE
 ALLOW_DUPLICATE  = TRUE
 STRIP_OUTER_ARRAY = TRUE
 STRIP_NULL_VALUES = TRUE
 IGNORE_UTF8_ERRORS = FALSE;

-- ****************************** 2.- Internal Stage ******************************
CREATE OR REPLACE STAGE SNOWPROCORE.PUBLIC.STAGE_INTERNAL_ACCOUNTS
    DIRECTORY = ( ENABLE =  TRUE );

SELECT * FROM @SNOWPROCORE.PUBLIC.STAGE_INTERNAL_ACCOUNTS (FILE_FORMAT => SNOWPROCORE.PUBLIC.FILE_FORMAT_JSON_GENERIC) SAMPLE(100 ROWS);

CREATE OR REPLACE TRANSIENT TABLE SNOWPROCORE.PUBLIC.ACCOUNTS_INTERNAL_RAW (
    PAYLOAD VARIANT,
    LOAD_DATE TIMESTAMP_LTZ(9) DEFAULT CURRENT_TIMESTAMP()
);

COPY INTO SNOWPROCORE.PUBLIC.ACCOUNTS_INTERNAL_RAW (PAYLOAD)
FROM (
    SELECT $1 AS PAYLOAD
    FROM @SNOWPROCORE.PUBLIC.STAGE_INTERNAL_ACCOUNTS (FILE_FORMAT => SNOWPROCORE.PUBLIC.FILE_FORMAT_JSON_GENERIC)
)
FILE_FORMAT = SNOWPROCORE.PUBLIC.FILE_FORMAT_JSON_GENERIC
PATTERN = '.*.json'
ON_ERROR = 'skip_file'
--PURGE = TRUE
;

SELECT * FROM SNOWPROCORE.PUBLIC.ACCOUNTS_INTERNAL_RAW;

LIST @SNOWPROCORE.PUBLIC.STAGE_INTERNAL_ACCOUNTS;
SELECT COUNT(*) FROM SNOWPROCORE.PUBLIC.ACCOUNTS_INTERNAL_RAW;
-- RUN THE COPY INTO AGAIN

-- LOADING LOCAL FILE USING CLIENT
PUT file://///Users/eplata/Developer/personal/snowflake-sample-code/sql/02-loading/SNOWBANK_PUBLIC_ACCOUNTS_2.json @SNOWPROCORE.PUBLIC.STAGE_INTERNAL_ACCOUNTS;

REMOVE @SNOWPROCORE.PUBLIC.STAGE_INTERNAL_ACCOUNTS/SNOWBANK_PUBLIC_ACCOUNTS_2.json.gz;

-- ****************************** 3.- Creating External Stages ******************************
CREATE OR REPLACE STAGE SNOWPROCORE.PUBLIC.STAGE_EXTERNAL_ACCOUNTS
  URL='s3://snowflake-s3-sfc-demo-ep/accounts/'
  FILE_FORMAT = SNOWPROCORE.PUBLIC.FILE_FORMAT_JSON_GENERIC;

CREATE OR REPLACE STAGE SNOWPROCORE.PUBLIC.STAGE_EXTERNAL_DEPOSITORS
  URL='s3://snowflake-s3-sfc-demo-ep/depositors/'
  FILE_FORMAT = SNOWPROCORE.PUBLIC.FILE_FORMAT_JSON_GENERIC;

-- ****************************** 4.- Exploring data from the S3 ******************************
-- ACCOUNT DATA
LS @SNOWPROCORE.PUBLIC.STAGE_EXTERNAL_ACCOUNTS;

SELECT * FROM @SNOWPROCORE.PUBLIC.STAGE_EXTERNAL_ACCOUNTS/SNOWBANK_PUBLIC_ACCOUNTS_1.json LIMIT 10;

SELECT $1:ACCESSIBLE_BALANCE::VARCHAR AS ACCESSIBLE_BALANCE,
       $1:ACCOUNT_BALANCE::VARCHAR AS ACCOUNT_BALANCE,
       $1:ACCOUNT_STATUS_CODE::VARCHAR AS ACCOUNT_STATUS_CODE,
       $1:ACCOUNT_UID::VARCHAR AS ACCOUNT_UID,
       $1:CDIC_HOLD_STATUS_CODE::VARCHAR AS CDIC_HOLD_STATUS_CODE,
       $1:CURRENCY_CODE::VARCHAR AS CURRENCY_CODE,
       $1:CURRENT_CDIC_HOLD_AMOUNT::VARCHAR AS CURRENT_CDIC_HOLD_AMOUNT,
       $1:DEPOSITOR_ID::VARCHAR AS DEPOSITOR_ID,
       $1:INSURANCE_DETERMINATION_CATEGORY_TYPE_CODE::VARCHAR AS INSURANCE_DETERMINATION_CATEGORY_TYPE_CODE,
       $1:PRODUCT_CODE::VARCHAR AS PRODUCT_CODE,
       $1:REGISTERED_ACCOUNT_FLAG::VARCHAR AS REGISTERED_ACCOUNT_FLAG,
       $1:REGISTERED_PLAN_TYPE_CODE::VARCHAR AS REGISTERED_PLAN_TYPE_CODE,
       metadata$filename, metadata$file_row_number
FROM @SNOWPROCORE.PUBLIC.STAGE_EXTERNAL_ACCOUNTS SAMPLE(100 ROWS);

-- DEPOSITOR DATA
SELECT * FROM @SNOWPROCORE.PUBLIC.STAGE_EXTERNAL_DEPOSITORS;

SELECT $1:ADDRESS::VARCHAR AS ADDRESS,
       $1:BIRTH_DATE::VARCHAR AS BIRTH_DATE,
       $1:CITY::VARCHAR AS CITY,
       $1:COUNTRY::VARCHAR AS COUNTRY,
       $1:DEPOSITOR_BRANCH::VARCHAR AS DEPOSITOR_BRANCH,
       $1:DEPOSITOR_ID::VARCHAR AS DEPOSITOR_ID,
       $1:DEPOSITOR_TYPE_CODE::VARCHAR AS DEPOSITOR_TYPE_CODE,
       $1:DEPOSITOR_UID::VARCHAR AS DEPOSITOR_UID,
       $1:EMAIL::VARCHAR AS EMAIL,
       $1:FIRST_NAME::VARCHAR AS FIRST_NAME,
       $1:LAST_NAME::VARCHAR AS LAST_NAME,
       $1:PHONE::VARCHAR AS PHONE,
       $1:POSTAL_CODE::VARCHAR AS POSTAL_CODE,
       $1:STATE::VARCHAR AS STATE
FROM @SNOWPROCORE.PUBLIC.STAGE_EXTERNAL_DEPOSITORS SAMPLE (100 ROWS);

-- ****************************** 4.- Creating Table ******************************
-- COPY INTO APPROACH: ACCOUNTS DATASET
CREATE OR REPLACE TABLE SNOWPROCORE.PUBLIC.ACCOUNTS_RAW (
    ACCESSIBLE_BALANCE                         VARCHAR,
    ACCOUNT_BALANCE                            VARCHAR,
    ACCOUNT_STATUS_CODE                        VARCHAR,
    ACCOUNT_UID                                VARCHAR,
    CDIC_HOLD_STATUS_CODE                      VARCHAR,
    CURRENCY_CODE                              VARCHAR,
    CURRENT_CDIC_HOLD_AMOUNT                   VARCHAR,
    DEPOSITOR_ID                               VARCHAR,
    INSURANCE_DETERMINATION_CATEGORY_TYPE_CODE VARCHAR,
    PRODUCT_CODE                               VARCHAR,
    REGISTERED_ACCOUNT_FLAG                    VARCHAR,
    REGISTERED_PLAN_TYPE_CODE                  VARCHAR,
    FILE_NAME                                  VARCHAR,
    FILE_ROW_NUMBER                            VARCHAR
);

SELECT * FROM SNOWPROCORE.PUBLIC.ACCOUNTS_RAW;

COPY INTO SNOWPROCORE.PUBLIC.ACCOUNTS_RAW (ACCESSIBLE_BALANCE,ACCOUNT_BALANCE,ACCOUNT_STATUS_CODE,
                        ACCOUNT_UID,CDIC_HOLD_STATUS_CODE,CURRENCY_CODE,
                        CURRENT_CDIC_HOLD_AMOUNT,DEPOSITOR_ID,
                        INSURANCE_DETERMINATION_CATEGORY_TYPE_CODE,PRODUCT_CODE,
                        REGISTERED_ACCOUNT_FLAG,REGISTERED_PLAN_TYPE_CODE,
                        FILE_NAME,FILE_ROW_NUMBER)
FROM (
    SELECT $1:ACCESSIBLE_BALANCE::VARCHAR AS ACCESSIBLE_BALANCE,
       $1:ACCOUNT_BALANCE::VARCHAR AS ACCOUNT_BALANCE,
       $1:ACCOUNT_STATUS_CODE::VARCHAR AS ACCOUNT_STATUS_CODE,
       $1:ACCOUNT_UID::VARCHAR AS ACCOUNT_UID,
       $1:CDIC_HOLD_STATUS_CODE::VARCHAR AS CDIC_HOLD_STATUS_CODE,
       $1:CURRENCY_CODE::VARCHAR AS CURRENCY_CODE,
       $1:CURRENT_CDIC_HOLD_AMOUNT::VARCHAR AS CURRENT_CDIC_HOLD_AMOUNT,
       $1:DEPOSITOR_ID::VARCHAR AS DEPOSITOR_ID,
       $1:INSURANCE_DETERMINATION_CATEGORY_TYPE_CODE::VARCHAR AS INSURANCE_DETERMINATION_CATEGORY_TYPE_CODE,
       $1:PRODUCT_CODE::VARCHAR AS PRODUCT_CODE,
       $1:REGISTERED_ACCOUNT_FLAG::VARCHAR AS REGISTERED_ACCOUNT_FLAG,
       $1:REGISTERED_PLAN_TYPE_CODE::VARCHAR AS REGISTERED_PLAN_TYPE_CODE,
       metadata$filename::VARCHAR AS FILE_NAME,
       metadata$file_row_number::VARCHAR AS FILE_ROW_NUMBER
    FROM @SNOWPROCORE.PUBLIC.STAGE_INTERNAL_ACCOUNTS (FILE_FORMAT => SNOWPROCORE.PUBLIC.FILE_FORMAT_JSON_GENERIC)
    --FROM @SNOWPROCORE.PUBLIC.STAGE_EXTERNAL_ACCOUNTS
)
FILE_FORMAT = SNOWPROCORE.PUBLIC.FILE_FORMAT_JSON_GENERIC
PATTERN = '.*.json'
ON_ERROR = 'skip_file'
PURGE = TRUE;

SELECT TOP 10 * FROM SNOWPROCORE.PUBLIC.ACCOUNTS_RAW;

-- CTAS APPROACH instead of COPY INTO
DROP TABLE IF EXISTS SNOWPROCORE.PUBLIC.ACCOUNTS_RAW;

CREATE OR REPLACE TABLE SNOWPROCORE.PUBLIC.ACCOUNTS_RAW AS
SELECT $1:ACCESSIBLE_BALANCE::VARCHAR AS ACCESSIBLE_BALANCE,
       $1:ACCOUNT_BALANCE::VARCHAR AS ACCOUNT_BALANCE,
       $1:ACCOUNT_STATUS_CODE::VARCHAR AS ACCOUNT_STATUS_CODE,
       $1:ACCOUNT_UID::VARCHAR AS ACCOUNT_UID,
       $1:CDIC_HOLD_STATUS_CODE::VARCHAR AS CDIC_HOLD_STATUS_CODE,
       $1:CURRENCY_CODE::VARCHAR AS CURRENCY_CODE,
       $1:CURRENT_CDIC_HOLD_AMOUNT::VARCHAR AS CURRENT_CDIC_HOLD_AMOUNT,
       $1:DEPOSITOR_ID::VARCHAR AS DEPOSITOR_ID,
       $1:INSURANCE_DETERMINATION_CATEGORY_TYPE_CODE::VARCHAR AS INSURANCE_DETERMINATION_CATEGORY_TYPE_CODE,
       $1:PRODUCT_CODE::VARCHAR AS PRODUCT_CODE,
       $1:REGISTERED_ACCOUNT_FLAG::VARCHAR AS REGISTERED_ACCOUNT_FLAG,
       $1:REGISTERED_PLAN_TYPE_CODE::VARCHAR AS REGISTERED_PLAN_TYPE_CODE,
       metadata$filename::VARCHAR AS FILE_NAME,
       metadata$file_row_number::VARCHAR AS FILE_ROW_NUMBER
FROM @SNOWPROCORE.PUBLIC.STAGE_EXTERNAL_ACCOUNTS (FILE_FORMAT => SNOWPROCORE.PUBLIC.FILE_FORMAT_JSON_GENERIC);

SELECT TOP 10 * FROM SNOWPROCORE.PUBLIC.ACCOUNTS_RAW;

-- Adaptive Caching