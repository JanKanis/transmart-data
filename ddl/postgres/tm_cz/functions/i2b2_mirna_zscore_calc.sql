--
-- Name: i2b2_mirna_zscore_calc(character varying, character varying, numeric, character varying, numeric, character varying); Type: FUNCTION; Schema: tm_cz; Owner: -
--
CREATE FUNCTION i2b2_mirna_zscore_calc(trial_id character varying, run_type character varying DEFAULT 'L'::character varying, currentjobid numeric DEFAULT NULL::numeric, data_type character varying DEFAULT 'R'::character varying, log_base numeric DEFAULT 2, source_cd character varying DEFAULT NULL::character varying) RETURNS numeric
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
/*************************************************************************
This Stored Procedure is used in ETL load MIRNA data
Date:12/9/2013
******************************************************************/
Declare
  TrialID character varying(50);
  sourceCD	character varying(50);
  sqlText character varying(2000);
  runType character varying(10);
  dataType character varying(10);
  stgTrial character varying(50);
  idxExists numeric;
  pExists	numeric;
  nbrRecs numeric;
  logBase numeric;
   
  --Audit variables
  newJobFlag numeric(1);
  databaseName VARCHAR(100);
  procedureName VARCHAR(100);
  jobID numeric(18,0);
  stepCt numeric(18,0);
  rtnCd integer;
  rowCt integer;
  
BEGIN

	TrialId := trial_id;
	runType := run_type;
	dataType := data_type;
	logBase := log_base;
	sourceCd := source_cd;
	  
  --Set Audit Parameters
  newJobFlag := 0; -- False (Default)
  jobID := currentJobID;

  databaseName := 'TM_CZ';
  procedureName := 'I2B2_MIRNA_ZSCORE_CALC';

  --Audit JOB Initialization
  --If Job ID does not exist, then this is a single procedure run and we need to create it
  IF(jobID IS NULL or jobID < 1)
  THEN
    newJobFlag := 1; -- True
    select cz_start_audit (procedureName, databaseName) into jobID;
  END IF;
   
  stepCt := 0;
  
	stepCt := stepCt + 1;
	select cz_write_audit(jobId,databaseName,procedureName,'Starting zscore calc for ' || TrialId || ' RunType: ' || runType || ' dataType: ' || dataType,0,stepCt,'Done') into rtnCd;
  
	if runType != 'L' then
		stepCt := stepCt + 1;
		get diagnostics rowCt := ROW_COUNT;
		select cz_write_audit(jobId,databaseName,procedureName,'Invalid runType passed - procedure exiting',rowCt,stepCt,'Done') into rtnCd;
		select cz_error_handler (jobID, procedureName) into rtnCd;  
		select cz_end_audit (jobID, 'FAIL') into rtnCd;
		return 150;
	end if;
  
--	For Load, make sure that the TrialId passed as parameter is the same as the trial in stg_subject_mirna_data
--	If not, raise exception

	if runType = 'L' then
		select distinct trial_name into stgTrial
		from WT_SUBJECT_MIRNA_PROBESET;
		
		if stgTrial != TrialId then
			stepCt := stepCt + 1;
			get diagnostics rowCt := ROW_COUNT;
			select cz_write_audit(jobId,databaseName,procedureName,'TrialId not the same as trial in WT_SUBJECT_MIRNA_PROBESET - procedure exiting',rowCt,stepCt,'Done') into rtnCd;
			select cz_error_handler(jobID, procedureName) into rtnCd;
			select cz_end_audit (jobID, 'FAIL') into rtnCd;
			return 161;
		end if;
	end if;
   
--	truncate tmp tables
	begin
		execute ('truncate table tm_wz.WT_SUBJECT_MIRNA_LOGS');
		execute ('truncate table tm_wz.WT_SUBJECT_MIRNA_CALCS');
		execute ('truncate table tm_wz.WT_SUBJECT_MIRNA_MED');
	exception
	when others then
		perform tm_cz.cz_error_handler (jobID, procedureName, SQLSTATE, SQLERRM);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		return -16;
	end;
	--drop index if exists tm_wz.WT_SUBJECT_MIRNA_LOGS_I1;		
	--drop index if exists tm_wz.WT_SUBJECT_MIRNA_CALCS_I1;
	
	stepCt := stepCt + 1;
	select cz_write_audit(jobId,databaseName,procedureName,'Truncate work tables in TM_WZ',0,stepCt,'Done') into rtnCd;
	
	--	if dataType = L, use intensity_value as log_intensity
	--	if dataType = R, always use intensity_value


	if dataType = 'L' then
		begin
		insert into WT_SUBJECT_MIRNA_LOGS 
			(probeset_id
			,intensity_value
			,assay_id
			,log_intensity
			,patient_id
			)
			select probeset_id
				  ,intensity_value ----UAT 154 changes done on 19/03/2014
				  ,assay_id 
				  ,round((case when intensity_value<=0 then 0
                                  when intensity_value>0 then log(2,intensity_value)
                                  else 0 end),5)
				  ,patient_id
			from WT_SUBJECT_MIRNA_PROBESET
			where trial_name = TrialId;
		exception
		when others then
			perform tm_cz.cz_error_handler (jobID, procedureName, SQLSTATE, SQLERRM);
			perform tm_cz.cz_end_audit (jobID, 'FAIL');
			return -16;
		end;
	else	
		begin
                	insert into WT_SUBJECT_MIRNA_LOGS 
			(probeset_id
			,intensity_value
			,assay_id
			,log_intensity
			,patient_id
			)
			select probeset_id
				  ,intensity_value  ----UAT 154 changes done on 19/03/2014
				  ,assay_id 
				  ,-(intensity_value)  ----UAT 154 changes done on 19/03/2014
				  ,patient_id
			from WT_SUBJECT_MIRNA_PROBESET
			where trial_name = TrialId;
		exception
		when others then
			perform tm_cz.cz_error_handler (jobID, procedureName, SQLSTATE, SQLERRM);
			perform tm_cz.cz_end_audit (jobID, 'FAIL');
			return -16;
		end;
	end if;

	stepCt := stepCt + 1;
	get diagnostics rowCt := ROW_COUNT;
	select cz_write_audit(jobId,databaseName,procedureName,'Loaded data for trial in TM_WZ wt_subject_mirna_logs',rowCt,stepCt,'Done') into rtnCd;

	
    
	--execute ('create index WT_SUBJECT_MIRNA_LOGS_I1 on tm_wz.WT_SUBJECT_MIRNA_LOGS (trial_name, probeset_id)');
	stepCt := stepCt + 1;
	--select cz_write_audit(jobId,databaseName,procedureName,'Create index on TM_WZ WT_SUBJECT_MIRNA_LOGS_I1',0,stepCt,'Done') into rtnCd;
		
--	calculate mean_intensity, median_intensity, and stddev_intensity per experiment, probe

	begin
	insert into WT_SUBJECT_MIRNA_CALCS
	(trial_name
	,probeset_id
	,mean_intensity
	,median_intensity
	,stddev_intensity
	)
	select d.trial_name 
		  ,d.probeset_id
		  ,avg(log_intensity)
		  ,median(log_intensity)
		  ,stddev(log_intensity)
	from WT_SUBJECT_MIRNA_LOGS d 
	group by d.trial_name 
			,d.probeset_id;
	exception
	when others then
		perform tm_cz.cz_error_handler (jobID, procedureName, SQLSTATE, SQLERRM);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		return -16;
	end;
	stepCt := stepCt + 1;
	get diagnostics rowCt := ROW_COUNT;
	select cz_write_audit(jobId,databaseName,procedureName,'Calculate intensities for trial in TM_WZ WT_SUBJECT_MIRNA_CALCS',rowCt,stepCt,'Done') into rtnCd;

	

	--execute ('create index tm_wz.wt_subject_mirna_calcs_i1 on tm_wz.WT_SUBJECT_MIRNA_CALCS (trial_name, probeset_id) nologging tablespace "INDX"');
	--stepCt := stepCt + 1;
	--cz_write_audit(jobId,databaseName,procedureName,'Create index on TM_WZ WT_SUBJECT_MIRNA_CALCS',0,stepCt,'Done');
		
-- calculate zscore

	begin
	insert into WT_SUBJECT_MIRNA_MED 
	(probeset_id
	,intensity_value
	,log_intensity
	,assay_id
	,mean_intensity
	,stddev_intensity
	,median_intensity
	,zscore
	,patient_id
--	,sample_cd
--	,subject_id
	)
	select d.probeset_id
		  ,d.intensity_value 
		  ,d.log_intensity 
		  ,d.assay_id  
		  ,c.mean_intensity 
		  ,c.stddev_intensity 
		  ,c.median_intensity 
		  ,(CASE WHEN stddev_intensity=0 THEN 0 ELSE (d.log_intensity - c.median_intensity ) / c.stddev_intensity END)
		  ,d.patient_id
	--	  ,d.sample_cd
	--	  ,d.subject_id
    from WT_SUBJECT_MIRNA_LOGS d 
		,WT_SUBJECT_MIRNA_CALCS c 
    where d.probeset_id = c.probeset_id;
    	exception
	when others then
		perform tm_cz.cz_error_handler (jobID, procedureName, SQLSTATE, SQLERRM);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		return -16;
	end;
	stepCt := stepCt + 1;
	get diagnostics rowCt := ROW_COUNT;
	select cz_write_audit(jobId,databaseName,procedureName,'Calculate Z-Score for trial in TM_WZ WT_SUBJECT_MIRNA_MED',rowCt,stepCt,'Done') into rtnCd;

	--select count(*) into pExists from de_subject_mirna_data where trial_name=TrialId;
	
	begin
	insert into de_subject_mirna_data
	(trial_source
	,trial_name
	,assay_id
	,probeset_id
	,raw_intensity 
	,log_intensity
	,zscore
	,patient_id
	--,sample_id
	--,subject_id
	)
	select (TrialId || ':' || sourceCD)
		  ,TrialId
	      ,m.assay_id
	      ,m.probeset_id 
		  ,case when dataType = 'R' then m.intensity_value
				when dataType = 'L' 
				then m.intensity_value
				else null
				end as raw_intensity
	    --  ,decode(dataType,'R',m.intensity_value,'L',power(logBase, m.log_intensity),null)
		  ,case when dataType = 'R' then -(m.intensity_value)
				when dataType = 'L' 
				then m.log_intensity
				else null
				end
	      ,(CASE WHEN m.zscore < -2.5 THEN -2.5 WHEN m.zscore >  2.5 THEN  2.5 ELSE round(m.zscore,5) END)
              --,m.zscore
		  ,m.patient_id
	--	  ,m.sample_id
	--	  ,m.subject_id
	from wt_subject_MIRNA_med m;
        exception
	when others then
		perform tm_cz.cz_error_handler (jobID, procedureName, SQLSTATE, SQLERRM);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		return -16;
	end;
	stepCt := stepCt + 1;
	get diagnostics rowCt := ROW_COUNT;
	select cz_write_audit(jobId,databaseName,procedureName,'Insert data for trial in DEAPP DE_SUBJECT_MIRNA_DATA',rowCt,stepCt,'Done') into rtnCd;

	/*
	if pExists > 0 then
		perform tm_cz.I2B2_MIRNA_INC_SUB_ZSCORE(TrialId,dataType);
		stepCt := stepCt + 1;
		perform cz_write_audit(jobId,databaseName,procedureName,'update zscore in de_subject_MIRNA_data ',0,stepCt,'Done');
	end if;
	*/
	---Cleanup OVERALL JOB if this proc is being run standalone
  IF newJobFlag = 1
  THEN
    perform cz_end_audit (jobID, 'SUCCESS');
  END IF;
  return 0;	
END;
$$;

