--
-- Type: TABLE; Owner: DEAPP; Name: DE_GENE_INFO
--
 CREATE TABLE "DEAPP"."DE_GENE_INFO"
  (	"GENE_INFO_ID" NUMBER(22,0),
"GENE_SOURCE_ID" NUMBER(5,0) NOT NULL ENABLE,
"ENTREZ_ID" NUMBER(10,0),
"GENE_SYMBOL" VARCHAR2(255 BYTE) NOT NULL ENABLE,
"GENE_NAME" VARCHAR2(255 BYTE),
"CHROM" VARCHAR2(40 BYTE) NOT NULL ENABLE,
"CHROM_START" NUMBER,
"CHROM_STOP" NUMBER,
"STRAND" NUMBER,
 PRIMARY KEY ("GENE_INFO_ID")
 USING INDEX
 TABLESPACE "TRANSMART"  ENABLE,
 UNIQUE ("GENE_SOURCE_ID", "GENE_SYMBOL")
 USING INDEX
 TABLESPACE "TRANSMART"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

--
-- Type: TRIGGER; Owner: DEAPP; Name: TRG_DE_GENE_INFO_ID
--
  CREATE OR REPLACE TRIGGER "DEAPP"."TRG_DE_GENE_INFO_ID"
BEFORE
  INSERT ON DEAPP.DE_GENE_INFO FOR EACH ROW
BEGIN
  IF inserting THEN
    IF :NEW.GENE_INFO_ID IS NULL THEN
        SELECT DEAPP.SEQ_DATA_ID.nextval INTO :NEW.GENE_INFO_ID FROM dual;
    END IF;
  END IF;
END;
/
ALTER TRIGGER "DEAPP"."TRG_DE_GENE_INFO_ID" ENABLE;

--
-- Type: REF_CONSTRAINT; Owner: DEAPP; Name: SYS_C0048085
--
ALTER TABLE "DEAPP"."DE_GENE_INFO" ADD FOREIGN KEY ("GENE_SOURCE_ID")
 REFERENCES "DEAPP"."DE_GENE_SOURCE" ("GENE_SOURCE_ID") ON DELETE CASCADE ENABLE;

