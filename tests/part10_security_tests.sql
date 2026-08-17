-- Fail-fast ChainProof Part 10 release hardening tests.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA AUDIT;

EXECUTE IMMEDIATE
$$
DECLARE
    context_failed EXCEPTION (-20601, 'Part 10 Snowflake context mismatch');
    object_failed EXCEPTION (-20602, 'Part 10 AUDIT object contract mismatch');
    limitation_failed EXCEPTION (-20603, 'Part 10 known limitation contract mismatch');
    snapshot_failed EXCEPTION (-20604, 'Part 10 release snapshot contract mismatch');
    control_failed EXCEPTION (-20605, 'Part 10 control result contract mismatch');
    scope_failed EXCEPTION (-20606, 'Part 10 object exists outside AUDIT');
    view_failed EXCEPTION (-20607, 'Part 10 AUDIT view result mismatch');
    v_count NUMBER;
    v_expected_controls NUMBER;
    v_status VARCHAR;
BEGIN
    IF (
        CURRENT_ROLE() <> 'GRIZZLY03_LEARNER_RL'
        OR CURRENT_WAREHOUSE() <> 'GRIZZLY03_WH'
        OR CURRENT_DATABASE() <> 'CHAINPROOF'
        OR CURRENT_SCHEMA() <> 'AUDIT'
    ) THEN
        RAISE context_failed;
    END IF;

    SELECT COUNT(*)
      INTO :v_count
      FROM CHAINPROOF.INFORMATION_SCHEMA.TABLES
     WHERE table_schema = 'AUDIT'
       AND table_type = 'BASE TABLE'
       AND table_name IN (
            'PART10_RELEASE_SNAPSHOT',
            'PART10_CONTROL_RESULT',
            'PART10_KNOWN_LIMITATION'
       );
    IF (v_count <> 3) THEN
        RAISE object_failed;
    END IF;

    SELECT COUNT(*)
      INTO :v_count
      FROM CHAINPROOF.INFORMATION_SCHEMA.VIEWS
     WHERE table_schema = 'AUDIT'
       AND table_name IN (
            'V_PART10_RELEASE_HEALTH',
            'V_PART10_CONTROL_SUMMARY',
            'V_PART10_LIMITATION_REGISTER'
       );
    IF (v_count <> 3) THEN
        RAISE object_failed;
    END IF;

    SELECT COUNT(*)
      INTO :v_count
      FROM CHAINPROOF.AUDIT.PART10_KNOWN_LIMITATION;
    IF (v_count <> 4) THEN
        RAISE limitation_failed;
    END IF;

    SELECT COUNT(*)
      INTO :v_count
      FROM CHAINPROOF.AUDIT.PART10_KNOWN_LIMITATION
     WHERE blocking_status <> 'NON_BLOCKING_DOCUMENTED';
    IF (v_count <> 0) THEN
        RAISE limitation_failed;
    END IF;

    SELECT COUNT(*)
      INTO :v_count
      FROM CHAINPROOF.AUDIT.PART10_RELEASE_SNAPSHOT
     WHERE release_id = 'PART10_HARDENING_V1';
    IF (v_count <> 1) THEN
        RAISE snapshot_failed;
    END IF;

    SELECT status, control_pass_count
      INTO :v_status, :v_expected_controls
      FROM CHAINPROOF.AUDIT.PART10_RELEASE_SNAPSHOT
     WHERE release_id = 'PART10_HARDENING_V1';

    IF (v_status = 'AUTOMATED_PASS' AND v_expected_controls <> 12) THEN
        RAISE snapshot_failed;
    END IF;
    IF (v_status = 'COMMIT_READY_PASS' AND v_expected_controls <> 16) THEN
        RAISE snapshot_failed;
    END IF;
    IF (v_status NOT IN ('AUTOMATED_PASS', 'COMMIT_READY_PASS')) THEN
        RAISE snapshot_failed;
    END IF;

    SELECT COUNT(*)
      INTO :v_count
      FROM CHAINPROOF.AUDIT.PART10_CONTROL_RESULT
     WHERE release_id = 'PART10_HARDENING_V1';
    IF (v_count <> v_expected_controls) THEN
        RAISE control_failed;
    END IF;

    SELECT COUNT(*)
      INTO :v_count
      FROM CHAINPROOF.AUDIT.PART10_CONTROL_RESULT
     WHERE release_id = 'PART10_HARDENING_V1'
       AND status <> 'PASS';
    IF (v_count <> 0) THEN
        RAISE control_failed;
    END IF;

    SELECT COUNT(*)
      INTO :v_count
      FROM (
          SELECT control_id
          FROM CHAINPROOF.AUDIT.PART10_CONTROL_RESULT
          WHERE release_id = 'PART10_HARDENING_V1'
          GROUP BY control_id
          HAVING COUNT(*) > 1
      ) AS duplicate_control_ids;
    IF (v_count <> 0) THEN
        RAISE control_failed;
    END IF;

    SELECT COUNT(*)
      INTO :v_count
      FROM CHAINPROOF.INFORMATION_SCHEMA.TABLES
     WHERE table_schema <> 'AUDIT'
       AND table_name LIKE 'PART10_%';
    IF (v_count <> 0) THEN
        RAISE scope_failed;
    END IF;

    SELECT COUNT(*)
      INTO :v_count
      FROM CHAINPROOF.INFORMATION_SCHEMA.VIEWS
     WHERE table_schema <> 'AUDIT'
       AND table_name LIKE 'V_PART10_%';
    IF (v_count <> 0) THEN
        RAISE scope_failed;
    END IF;

    SELECT COUNT(*)
      INTO :v_count
      FROM CHAINPROOF.AUDIT.V_PART10_RELEASE_HEALTH
     WHERE release_id = 'PART10_HARDENING_V1'
       AND release_health = 'PASS';
    IF (v_count <> 1) THEN
        RAISE view_failed;
    END IF;

    SELECT COUNT(*)
      INTO :v_count
      FROM CHAINPROOF.AUDIT.V_PART10_LIMITATION_REGISTER;
    IF (v_count <> 4) THEN
        RAISE view_failed;
    END IF;

    RETURN 'PASS: Part 10 AUDIT release, controls, limitations, views, and object scope';
END;
$$;
