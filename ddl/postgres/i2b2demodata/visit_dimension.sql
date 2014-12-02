--
-- Name: visit_dimension; Type: TABLE; Schema: i2b2demodata; Owner: -
--
CREATE TABLE visit_dimension (
    encounter_num integer NOT NULL,
    patient_num integer NOT NULL,
    active_status_cd character varying(50),
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    inout_cd character varying(50),
    location_cd character varying(50),
    location_path character varying(900),
    length_of_stay integer,
    visit_blob text,
    update_date timestamp without time zone,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    upload_id integer
);

--
-- Name: visit_dimension_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: -
--
ALTER TABLE ONLY visit_dimension
    ADD CONSTRAINT visit_dimension_pk PRIMARY KEY (encounter_num, patient_num);

--
-- Name: vd_uploadid_idx; Type: INDEX; Schema: i2b2demodata; Owner: -
--
CREATE INDEX vd_uploadid_idx ON visit_dimension USING btree (upload_id);

--
-- Name: visitdim_en_pn_lp_io_sd_idx; Type: INDEX; Schema: i2b2demodata; Owner: -
--
CREATE INDEX visitdim_en_pn_lp_io_sd_idx ON visit_dimension USING btree (encounter_num, patient_num, location_path, inout_cd, start_date, end_date, length_of_stay);

--
-- Name: visitdim_std_edd_idx; Type: INDEX; Schema: i2b2demodata; Owner: -
--
CREATE INDEX visitdim_std_edd_idx ON visit_dimension USING btree (start_date, end_date);

