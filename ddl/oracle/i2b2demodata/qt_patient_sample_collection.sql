-- NOTE: not in i2b2 schema for i2b2demo data - version 1.7 - 02Dec2014 - Terry Weymouth

--
-- Type: TABLE; Owner: I2B2DEMODATA; Name: QT_PATIENT_SAMPLE_COLLECTION
--
 CREATE TABLE "I2B2DEMODATA"."QT_PATIENT_SAMPLE_COLLECTION" 
  (	"SAMPLE_ID" NUMBER(10,0) NOT NULL ENABLE, 
"PATIENT_ID" NUMBER(10,0) NOT NULL ENABLE, 
"RESULT_INSTANCE_ID" NUMBER(10,0) NOT NULL ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;
 