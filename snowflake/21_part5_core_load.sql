-- Part 5: Deterministic RAW-to-CORE transformation.
-- No RAW rows are changed. Invalid source values are preserved in *_SOURCE
-- columns, typed values use TRY_TO_* functions, and explicit data-quality
-- issues explain values that cannot participate in governed metrics.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.CORE;

EXECUTE IMMEDIATE $$
DECLARE
    raw_not_ready EXCEPTION (-20501, 'Part 5 requires the complete Part 4 RAW dataset: 12 tables and 110 rows');
    v_tables NUMBER;
    v_rows NUMBER;
BEGIN
    -- Use Snowflake Scripting scalar assignments. This form is intentionally
    -- the same form already exercised by the Part 4 fail-fast tests.
    v_tables := (
        SELECT COUNT(*)
        FROM CHAINPROOF.INFORMATION_SCHEMA.TABLES
        WHERE table_schema = 'RAW'
          AND table_type = 'BASE TABLE'
          AND table_name IN (
            'SRC_SUPPLIER_MASTER','SRC_ERP_PART_MASTER','SRC_ERP_PLANT_MASTER',
            'SRC_LOGISTICS_CARRIER_MASTER','SRC_ERP_PURCHASE_ORDERS',
            'SRC_ERP_PURCHASE_ORDER_LINES','SRC_LOGISTICS_SHIPMENTS',
            'SRC_LOGISTICS_SHIPMENT_LINES','SRC_LOGISTICS_RECEIPTS',
            'SRC_QUALITY_INSPECTIONS','SRC_PLANNING_REQUIREMENTS',
            'SRC_IDENTITY_PERSONA_MAP'
          )
    );
    v_rows := (
        SELECT SUM(row_count)
        FROM (
          SELECT COUNT(*) AS row_count FROM CHAINPROOF.RAW.SRC_SUPPLIER_MASTER
          UNION ALL SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_ERP_PART_MASTER
          UNION ALL SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_ERP_PLANT_MASTER
          UNION ALL SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_LOGISTICS_CARRIER_MASTER
          UNION ALL SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_ERP_PURCHASE_ORDERS
          UNION ALL SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_ERP_PURCHASE_ORDER_LINES
          UNION ALL SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_LOGISTICS_SHIPMENTS
          UNION ALL SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_LOGISTICS_SHIPMENT_LINES
          UNION ALL SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_LOGISTICS_RECEIPTS
          UNION ALL SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_QUALITY_INSPECTIONS
          UNION ALL SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_PLANNING_REQUIREMENTS
          UNION ALL SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_IDENTITY_PERSONA_MAP
        ) raw_counts
    );
    IF (COALESCE(v_tables,0) <> 12 OR COALESCE(v_rows,0) <> 110) THEN
        RAISE raw_not_ready;
    END IF;
END;
$$;


DELETE FROM DATA_QUALITY_ISSUE;
DELETE FROM INSPECTION;
DELETE FROM RECEIPT;
DELETE FROM SHIPMENT_LINE;
DELETE FROM SHIPMENT;
DELETE FROM PURCHASE_ORDER_LINE;
DELETE FROM PURCHASE_ORDER;
DELETE FROM PRODUCTION_REQUIREMENT;
DELETE FROM CARRIER;
DELETE FROM PLANT;
DELETE FROM PART;
DELETE FROM SUPPLIER;

INSERT INTO SUPPLIER (
    supplier_id,supplier_name,country_code,city_name,supplier_status,
    erp_supplier_code,logistics_supplier_code,source_load_batch_id,
    source_file_name,source_file_row_number,source_loaded_at
)
SELECT
    supplier_id,supplier_name,UPPER(country_code),city_name,UPPER(supplier_status),
    erp_supplier_code,logistics_supplier_code,load_batch_id,source_file_name,
    source_file_row_number,loaded_at
FROM CHAINPROOF.RAW.SRC_SUPPLIER_MASTER;

INSERT INTO PART (
    part_id,part_name,part_category,base_uom,part_status,planning_part_code,
    logistics_part_code,source_load_batch_id,source_file_name,
    source_file_row_number,source_loaded_at
)
SELECT
    part_id,part_name,UPPER(part_category),UPPER(base_uom),UPPER(part_status),
    planning_part_code,logistics_part_code,load_batch_id,source_file_name,
    source_file_row_number,loaded_at
FROM CHAINPROOF.RAW.SRC_ERP_PART_MASTER;

INSERT INTO PLANT (
    plant_id,plant_name,city_name,state_region,country_code,time_zone,plant_status,
    planning_plant_code,logistics_plant_code,source_load_batch_id,
    source_file_name,source_file_row_number,source_loaded_at
)
SELECT
    plant_id,plant_name,city_name,state_region,UPPER(country_code),time_zone,UPPER(plant_status),
    planning_plant_code,logistics_plant_code,load_batch_id,source_file_name,
    source_file_row_number,loaded_at
FROM CHAINPROOF.RAW.SRC_ERP_PLANT_MASTER;

INSERT INTO CARRIER (
    carrier_id,carrier_name,transport_mode,carrier_status,source_load_batch_id,
    source_file_name,source_file_row_number,source_loaded_at
)
SELECT
    carrier_id,carrier_name,UPPER(transport_mode),UPPER(carrier_status),load_batch_id,
    source_file_name,source_file_row_number,loaded_at
FROM CHAINPROOF.RAW.SRC_LOGISTICS_CARRIER_MASTER;

INSERT INTO PURCHASE_ORDER (
    po_number,supplier_id,source_erp_supplier_code,po_creation_date,
    destination_plant_id,currency_code,buyer_id,po_status,
    supplier_resolution_status,plant_resolution_status,source_load_batch_id,
    source_file_name,source_file_row_number,source_loaded_at
)
SELECT
    r.po_number,s.supplier_id,r.erp_supplier_code,TRY_TO_DATE(r.po_creation_date),
    p.plant_id,UPPER(r.currency_code),r.buyer_id,UPPER(r.po_status),
    IFF(s.supplier_id IS NULL,'UNRESOLVED','RESOLVED'),
    IFF(p.plant_id IS NULL,'UNRESOLVED','RESOLVED'),
    r.load_batch_id,r.source_file_name,r.source_file_row_number,r.loaded_at
FROM CHAINPROOF.RAW.SRC_ERP_PURCHASE_ORDERS r
LEFT JOIN SUPPLIER s ON s.erp_supplier_code=r.erp_supplier_code
LEFT JOIN PLANT p ON p.plant_id=r.destination_plant_id;

INSERT INTO PURCHASE_ORDER_LINE (
    po_number,po_line_number,part_id,destination_plant_id,
    ordered_quantity_source,ordered_quantity,order_uom_source,base_uom,
    ordered_quantity_base,original_requested_delivery_date,
    revised_requested_delivery_date,unit_price,line_status,
    quantity_parse_status,uom_conversion_status,reference_resolution_status,
    metric_eligibility_status,source_load_batch_id,source_file_name,
    source_file_row_number,source_loaded_at
)
SELECT
    r.po_number,TRY_TO_NUMBER(r.po_line_number),pt.part_id,pl.plant_id,
    r.ordered_quantity,TRY_TO_DECIMAL(r.ordered_quantity,18,3),UPPER(r.order_uom),
    pt.base_uom,
    IFF(UPPER(r.order_uom)=pt.base_uom,TRY_TO_DECIMAL(r.ordered_quantity,18,3),NULL),
    TRY_TO_DATE(r.original_requested_delivery_date),
    TRY_TO_DATE(r.revised_requested_delivery_date),
    TRY_TO_DECIMAL(r.unit_price,18,2),UPPER(r.line_status),
    CASE
      WHEN r.ordered_quantity IS NULL OR r.ordered_quantity='' THEN 'MISSING'
      WHEN TRY_TO_DECIMAL(r.ordered_quantity,18,3) IS NULL THEN 'INVALID'
      ELSE 'VALID'
    END,
    CASE
      WHEN r.order_uom IS NULL OR r.order_uom='' THEN 'MISSING'
      WHEN pt.part_id IS NULL THEN 'UNRESOLVED_REFERENCE'
      WHEN UPPER(r.order_uom)=pt.base_uom THEN 'SAME_AS_BASE'
      ELSE 'UNRESOLVED'
    END,
    IFF(po.po_number IS NOT NULL AND pt.part_id IS NOT NULL AND pl.plant_id IS NOT NULL,'RESOLVED','UNRESOLVED'),
    CASE
      WHEN UPPER(r.line_status)='CANCELED' THEN 'EXCLUDED_CANCELED'
      WHEN TRY_TO_DECIMAL(r.ordered_quantity,18,3) IS NULL THEN 'INVALID_QUANTITY'
      WHEN TRY_TO_DECIMAL(r.ordered_quantity,18,3)<=0 THEN 'ZERO_DENOMINATOR'
      WHEN TRY_TO_DATE(r.original_requested_delivery_date) IS NULL THEN 'MISSING_ORIGINAL_DATE'
      WHEN pt.part_id IS NULL OR pl.plant_id IS NULL OR po.po_number IS NULL THEN 'UNRESOLVED_REFERENCE'
      WHEN r.order_uom IS NULL OR TRIM(r.order_uom)='' THEN 'MISSING_UOM'
      WHEN UPPER(r.order_uom)<>pt.base_uom THEN 'UNRESOLVED_UOM'
      ELSE 'ELIGIBLE'
    END,
    r.load_batch_id,r.source_file_name,r.source_file_row_number,r.loaded_at
FROM CHAINPROOF.RAW.SRC_ERP_PURCHASE_ORDER_LINES r
LEFT JOIN PURCHASE_ORDER po ON po.po_number=r.po_number
LEFT JOIN PART pt ON pt.part_id=r.part_id
LEFT JOIN PLANT pl ON pl.plant_id=r.destination_plant_id;

INSERT INTO SHIPMENT (
    shipment_id,supplier_id,source_logistics_supplier_code,carrier_id,
    origin_location,destination_plant_id,source_logistics_plant_code,ship_date,
    shipment_status,tracking_reference,reference_resolution_status,
    source_load_batch_id,source_file_name,source_file_row_number,source_loaded_at
)
SELECT
    r.shipment_id,s.supplier_id,r.logistics_supplier_code,c.carrier_id,
    r.origin_location,p.plant_id,r.logistics_destination_plant_code,
    TRY_TO_DATE(r.ship_date),UPPER(r.shipment_status),r.tracking_reference,
    IFF(s.supplier_id IS NOT NULL AND c.carrier_id IS NOT NULL AND p.plant_id IS NOT NULL,'RESOLVED','UNRESOLVED'),
    r.load_batch_id,r.source_file_name,r.source_file_row_number,r.loaded_at
FROM CHAINPROOF.RAW.SRC_LOGISTICS_SHIPMENTS r
LEFT JOIN SUPPLIER s ON s.logistics_supplier_code=r.logistics_supplier_code
LEFT JOIN CARRIER c ON c.carrier_id=r.carrier_id
LEFT JOIN PLANT p ON p.logistics_plant_code=r.logistics_destination_plant_code;

INSERT INTO SHIPMENT_LINE (
    shipment_id,shipment_line_number,po_number,po_line_number,part_id,
    source_logistics_part_code,shipped_quantity_source,shipped_quantity,
    shipment_uom_source,base_uom,shipped_quantity_base,
    original_carrier_commitment_date,revised_carrier_commitment_date,line_status,
    quantity_parse_status,uom_conversion_status,reference_resolution_status,
    metric_eligibility_status,source_load_batch_id,source_file_name,
    source_file_row_number,source_loaded_at
)
SELECT
    r.shipment_id,TRY_TO_NUMBER(r.shipment_line_number),r.po_number,
    TRY_TO_NUMBER(r.po_line_number),pt.part_id,r.logistics_part_code,
    r.shipped_quantity,TRY_TO_DECIMAL(r.shipped_quantity,18,3),UPPER(r.shipment_uom),
    pt.base_uom,
    IFF(UPPER(r.shipment_uom)=pt.base_uom,TRY_TO_DECIMAL(r.shipped_quantity,18,3),NULL),
    TRY_TO_DATE(r.original_carrier_commitment_date),
    TRY_TO_DATE(r.revised_carrier_commitment_date),UPPER(r.line_status),
    CASE
      WHEN r.shipped_quantity IS NULL OR r.shipped_quantity='' THEN 'MISSING'
      WHEN TRY_TO_DECIMAL(r.shipped_quantity,18,3) IS NULL THEN 'INVALID'
      ELSE 'VALID'
    END,
    CASE
      WHEN r.shipment_uom IS NULL OR r.shipment_uom='' THEN 'MISSING'
      WHEN pt.part_id IS NULL THEN 'UNRESOLVED_REFERENCE'
      WHEN UPPER(r.shipment_uom)=pt.base_uom THEN 'SAME_AS_BASE'
      ELSE 'UNRESOLVED'
    END,
    IFF(sh.shipment_id IS NOT NULL AND pol.po_number IS NOT NULL AND pt.part_id IS NOT NULL,'RESOLVED','UNRESOLVED'),
    CASE
      WHEN UPPER(r.line_status)='VOID' OR UPPER(sh.shipment_status)='VOID' THEN 'EXCLUDED_VOID'
      WHEN TRY_TO_DECIMAL(r.shipped_quantity,18,3) IS NULL THEN 'INVALID_QUANTITY'
      WHEN TRY_TO_DECIMAL(r.shipped_quantity,18,3)<=0 THEN 'ZERO_DENOMINATOR'
      WHEN TRY_TO_DATE(r.original_carrier_commitment_date) IS NULL THEN 'MISSING_ORIGINAL_DATE'
      WHEN sh.shipment_id IS NULL OR pol.po_number IS NULL OR pt.part_id IS NULL THEN 'UNRESOLVED_REFERENCE'
      WHEN r.shipment_uom IS NULL OR TRIM(r.shipment_uom)='' THEN 'MISSING_UOM'
      WHEN UPPER(r.shipment_uom)<>pt.base_uom THEN 'UNRESOLVED_UOM'
      ELSE 'ELIGIBLE'
    END,
    r.load_batch_id,r.source_file_name,r.source_file_row_number,r.loaded_at
FROM CHAINPROOF.RAW.SRC_LOGISTICS_SHIPMENT_LINES r
LEFT JOIN SHIPMENT sh ON sh.shipment_id=r.shipment_id
LEFT JOIN PURCHASE_ORDER_LINE pol ON pol.po_number=r.po_number AND pol.po_line_number=TRY_TO_NUMBER(r.po_line_number)
LEFT JOIN PART pt ON pt.logistics_part_code=r.logistics_part_code;

INSERT INTO RECEIPT (
    receipt_id,shipment_id,shipment_line_number,plant_id,
    source_logistics_plant_code,physical_received_quantity_source,
    physical_received_quantity,receipt_uom_source,base_uom,
    physical_received_quantity_base,receipt_date,receiving_dock,receipt_status,
    quantity_parse_status,uom_conversion_status,reference_resolution_status,
    source_load_batch_id,source_file_name,source_file_row_number,source_loaded_at
)
SELECT
    r.receipt_id,r.shipment_id,TRY_TO_NUMBER(r.shipment_line_number),p.plant_id,
    r.logistics_plant_code,r.physical_received_quantity,
    TRY_TO_DECIMAL(r.physical_received_quantity,18,3),UPPER(r.receipt_uom),sl.base_uom,
    IFF(UPPER(r.receipt_uom)=sl.base_uom,TRY_TO_DECIMAL(r.physical_received_quantity,18,3),NULL),
    TRY_TO_DATE(r.receipt_date),r.receiving_dock,UPPER(r.receipt_status),
    CASE
      WHEN r.physical_received_quantity IS NULL OR r.physical_received_quantity='' THEN 'MISSING'
      WHEN TRY_TO_DECIMAL(r.physical_received_quantity,18,3) IS NULL THEN 'INVALID'
      ELSE 'VALID'
    END,
    CASE
      WHEN r.receipt_uom IS NULL OR r.receipt_uom='' THEN 'MISSING'
      WHEN sl.shipment_id IS NULL THEN 'UNRESOLVED_REFERENCE'
      WHEN UPPER(r.receipt_uom)=sl.base_uom THEN 'SAME_AS_BASE'
      ELSE 'UNRESOLVED'
    END,
    IFF(sl.shipment_id IS NOT NULL AND p.plant_id IS NOT NULL,'RESOLVED','UNRESOLVED'),
    r.load_batch_id,r.source_file_name,r.source_file_row_number,r.loaded_at
FROM CHAINPROOF.RAW.SRC_LOGISTICS_RECEIPTS r
LEFT JOIN SHIPMENT_LINE sl ON sl.shipment_id=r.shipment_id AND sl.shipment_line_number=TRY_TO_NUMBER(r.shipment_line_number)
LEFT JOIN PLANT p ON p.logistics_plant_code=r.logistics_plant_code;

INSERT INTO INSPECTION (
    inspection_id,receipt_id,inspection_completion_date,
    inspected_quantity_source,inspected_quantity,accepted_quantity_source,
    accepted_quantity,rejected_quantity_source,rejected_quantity,
    damaged_quantity_source,damaged_quantity,inspection_uom_source,base_uom,
    inspected_quantity_base,accepted_quantity_base,rejected_quantity_base,
    damaged_quantity_base,disposition,inspection_status,is_final,
    quantity_parse_status,uom_conversion_status,inspection_arithmetic_status,
    reference_resolution_status,source_load_batch_id,source_file_name,
    source_file_row_number,source_loaded_at
)
SELECT
    r.inspection_id,rc.receipt_id,TRY_TO_DATE(r.inspection_completion_date),
    r.inspected_quantity,TRY_TO_DECIMAL(r.inspected_quantity,18,3),
    r.accepted_quantity,TRY_TO_DECIMAL(r.accepted_quantity,18,3),
    r.rejected_quantity,TRY_TO_DECIMAL(r.rejected_quantity,18,3),
    r.damaged_quantity,TRY_TO_DECIMAL(r.damaged_quantity,18,3),
    UPPER(r.inspection_uom),rc.base_uom,
    IFF(UPPER(r.inspection_uom)=rc.base_uom,TRY_TO_DECIMAL(r.inspected_quantity,18,3),NULL),
    IFF(UPPER(r.inspection_uom)=rc.base_uom,TRY_TO_DECIMAL(r.accepted_quantity,18,3),NULL),
    IFF(UPPER(r.inspection_uom)=rc.base_uom,TRY_TO_DECIMAL(r.rejected_quantity,18,3),NULL),
    IFF(UPPER(r.inspection_uom)=rc.base_uom,TRY_TO_DECIMAL(r.damaged_quantity,18,3),NULL),
    UPPER(r.disposition),UPPER(r.inspection_status),UPPER(r.inspection_status)='FINAL',
    CASE
      WHEN TRY_TO_DECIMAL(r.inspected_quantity,18,3) IS NULL
        OR TRY_TO_DECIMAL(r.accepted_quantity,18,3) IS NULL
        OR TRY_TO_DECIMAL(r.rejected_quantity,18,3) IS NULL
        OR TRY_TO_DECIMAL(r.damaged_quantity,18,3) IS NULL THEN 'INVALID'
      ELSE 'VALID'
    END,
    CASE
      WHEN r.inspection_uom IS NULL OR r.inspection_uom='' THEN 'MISSING'
      WHEN rc.receipt_id IS NULL THEN 'UNRESOLVED_REFERENCE'
      WHEN UPPER(r.inspection_uom)=rc.base_uom THEN 'SAME_AS_BASE'
      ELSE 'UNRESOLVED'
    END,
    CASE
      WHEN TRY_TO_DECIMAL(r.inspected_quantity,18,3) IS NULL
        OR TRY_TO_DECIMAL(r.accepted_quantity,18,3) IS NULL
        OR TRY_TO_DECIMAL(r.rejected_quantity,18,3) IS NULL
        OR TRY_TO_DECIMAL(r.damaged_quantity,18,3) IS NULL THEN 'INVALID_QUANTITY'
      WHEN TRY_TO_DECIMAL(r.accepted_quantity,18,3)+TRY_TO_DECIMAL(r.rejected_quantity,18,3)
           <>TRY_TO_DECIMAL(r.inspected_quantity,18,3) THEN 'ACCEPTED_REJECTED_MISMATCH'
      WHEN TRY_TO_DECIMAL(r.damaged_quantity,18,3)>TRY_TO_DECIMAL(r.rejected_quantity,18,3) THEN 'DAMAGE_EXCEEDS_REJECTED'
      WHEN TRY_TO_DECIMAL(r.inspected_quantity,18,3)>rc.physical_received_quantity THEN 'INSPECTED_EXCEEDS_RECEIVED'
      ELSE 'VALID'
    END,
    IFF(rc.receipt_id IS NULL,'UNRESOLVED','RESOLVED'),
    r.load_batch_id,r.source_file_name,r.source_file_row_number,r.loaded_at
FROM CHAINPROOF.RAW.SRC_QUALITY_INSPECTIONS r
LEFT JOIN RECEIPT rc ON rc.receipt_id=r.receipt_id;

INSERT INTO PRODUCTION_REQUIREMENT (
    planning_record_id,production_plan_id,part_id,source_planning_part_code,
    plant_id,source_planning_plant_code,production_need_date,
    required_quantity_source,required_quantity,requirement_uom_source,base_uom,
    required_quantity_base,usable_quantity_source,
    usable_quantity_available_by_need_date,usable_quantity_base,
    snapshot_timestamp,requirement_status,quantity_parse_status,
    uom_conversion_status,reference_resolution_status,metric_eligibility_status,
    source_load_batch_id,source_file_name,source_file_row_number,source_loaded_at
)
SELECT
    r.planning_record_id,r.production_plan_id,pt.part_id,r.planning_part_code,
    pl.plant_id,r.planning_plant_code,TRY_TO_DATE(r.production_need_date),
    r.required_quantity,TRY_TO_DECIMAL(r.required_quantity,18,3),UPPER(r.requirement_uom),pt.base_uom,
    IFF(UPPER(r.requirement_uom)=pt.base_uom,TRY_TO_DECIMAL(r.required_quantity,18,3),NULL),
    r.usable_quantity_available_by_need_date,
    TRY_TO_DECIMAL(r.usable_quantity_available_by_need_date,18,3),
    IFF(UPPER(r.requirement_uom)=pt.base_uom,TRY_TO_DECIMAL(r.usable_quantity_available_by_need_date,18,3),NULL),
    TRY_TO_TIMESTAMP_NTZ(r.snapshot_timestamp),UPPER(r.requirement_status),
    CASE
      WHEN TRY_TO_DECIMAL(r.required_quantity,18,3) IS NULL
        OR TRY_TO_DECIMAL(r.usable_quantity_available_by_need_date,18,3) IS NULL THEN 'INVALID'
      ELSE 'VALID'
    END,
    CASE
      WHEN r.requirement_uom IS NULL OR r.requirement_uom='' THEN 'MISSING'
      WHEN pt.part_id IS NULL THEN 'UNRESOLVED_REFERENCE'
      WHEN UPPER(r.requirement_uom)=pt.base_uom THEN 'SAME_AS_BASE'
      ELSE 'UNRESOLVED'
    END,
    IFF(pt.part_id IS NOT NULL AND pl.plant_id IS NOT NULL,'RESOLVED','UNRESOLVED'),
    CASE
      WHEN UPPER(r.requirement_status)='CANCELED' THEN 'EXCLUDED_CANCELED'
      WHEN TRY_TO_DECIMAL(r.required_quantity,18,3) IS NULL
        OR TRY_TO_DECIMAL(r.usable_quantity_available_by_need_date,18,3) IS NULL THEN 'INVALID_QUANTITY'
      WHEN TRY_TO_DECIMAL(r.required_quantity,18,3)<=0 THEN 'ZERO_DENOMINATOR'
      WHEN TRY_TO_DATE(r.production_need_date) IS NULL THEN 'MISSING_NEED_DATE'
      WHEN pt.part_id IS NULL OR pl.plant_id IS NULL THEN 'UNRESOLVED_REFERENCE'
      WHEN r.requirement_uom IS NULL OR TRIM(r.requirement_uom)='' THEN 'MISSING_UOM'
      WHEN UPPER(r.requirement_uom)<>pt.base_uom THEN 'UNRESOLVED_UOM'
      ELSE 'ELIGIBLE'
    END,
    r.load_batch_id,r.source_file_name,r.source_file_row_number,r.loaded_at
FROM CHAINPROOF.RAW.SRC_PLANNING_REQUIREMENTS r
LEFT JOIN PART pt ON pt.planning_part_code=r.planning_part_code
LEFT JOIN PLANT pl ON pl.planning_plant_code=r.planning_plant_code;

INSERT INTO DATA_QUALITY_ISSUE (
    issue_id,source_object,source_business_key,canonical_entity,issue_code,
    severity,issue_message,source_value
)
WITH detected_issues AS (
    SELECT
        'SRC_ERP_PURCHASE_ORDER_LINES' source_object,
        po_number||'-'||TO_VARCHAR(po_line_number) source_business_key,
        'PURCHASE_ORDER_LINE' canonical_entity,
        'MISSING_ORIGINAL_PO_DATE' issue_code,
        'ERROR' severity,
        'Original PO requested date is required for version 1.0 supplier performance' issue_message,
        '<missing>' source_value
    FROM PURCHASE_ORDER_LINE
    WHERE original_requested_delivery_date IS NULL
      AND line_status <> 'CANCELED'

    UNION ALL
    SELECT
        'SRC_ERP_PURCHASE_ORDER_LINES',po_number||'-'||TO_VARCHAR(po_line_number),
        'PURCHASE_ORDER_LINE','INVALID_ORDERED_QUANTITY','ERROR',
        'Ordered quantity cannot be converted to NUMBER',ordered_quantity_source
    FROM PURCHASE_ORDER_LINE
    WHERE quantity_parse_status='INVALID'

    UNION ALL
    SELECT
        'SRC_ERP_PURCHASE_ORDER_LINES',po_number||'-'||TO_VARCHAR(po_line_number),
        'PURCHASE_ORDER_LINE','UNRESOLVED_ORDER_UOM','ERROR',
        'No conversion to the canonical part base UOM is available',order_uom_source
    FROM PURCHASE_ORDER_LINE
    WHERE uom_conversion_status='UNRESOLVED'

    UNION ALL
    SELECT
        'SRC_LOGISTICS_SHIPMENT_LINES',shipment_id||'-'||TO_VARCHAR(shipment_line_number),
        'SHIPMENT_LINE','MISSING_ORIGINAL_CARRIER_DATE','ERROR',
        'Original carrier commitment is required for version 1.0 logistics performance','<missing>'
    FROM SHIPMENT_LINE
    WHERE original_carrier_commitment_date IS NULL
      AND line_status <> 'VOID'

    UNION ALL
    SELECT
        'SRC_LOGISTICS_SHIPMENT_LINES',shipment_id||'-'||TO_VARCHAR(shipment_line_number),
        'SHIPMENT_LINE','INVALID_SHIPPED_QUANTITY','ERROR',
        'Shipped quantity cannot be converted to NUMBER',shipped_quantity_source
    FROM SHIPMENT_LINE
    WHERE quantity_parse_status='INVALID'

    UNION ALL
    SELECT
        'SRC_LOGISTICS_SHIPMENT_LINES',shipment_id||'-'||TO_VARCHAR(shipment_line_number),
        'SHIPMENT_LINE','UNRESOLVED_SHIPMENT_UOM','ERROR',
        'No conversion to the canonical part base UOM is available',shipment_uom_source
    FROM SHIPMENT_LINE
    WHERE uom_conversion_status='UNRESOLVED'

    UNION ALL
    SELECT
        'SRC_LOGISTICS_RECEIPTS',receipt_id,'RECEIPT','UNRESOLVED_RECEIPT_UOM','ERROR',
        'No conversion to the canonical part base UOM is available',receipt_uom_source
    FROM RECEIPT
    WHERE uom_conversion_status='UNRESOLVED'

    UNION ALL
    SELECT
        'SRC_QUALITY_INSPECTIONS',inspection_id,'INSPECTION','UNRESOLVED_INSPECTION_UOM','ERROR',
        'No conversion to the canonical part base UOM is available',inspection_uom_source
    FROM INSPECTION
    WHERE uom_conversion_status='UNRESOLVED'

    UNION ALL
    SELECT
        'SRC_PLANNING_REQUIREMENTS',planning_record_id,'PRODUCTION_REQUIREMENT',
        'MISSING_PRODUCTION_NEED_DATE','ERROR',
        'Production need date is required for Planning measurement','<missing>'
    FROM PRODUCTION_REQUIREMENT
    WHERE production_need_date IS NULL
      AND requirement_status <> 'CANCELED'

    UNION ALL
    SELECT
        'SRC_PLANNING_REQUIREMENTS',planning_record_id,'PRODUCTION_REQUIREMENT',
        'INVALID_REQUIRED_QUANTITY','ERROR',
        'Required quantity cannot be converted to NUMBER',required_quantity_source
    FROM PRODUCTION_REQUIREMENT
    WHERE TRY_TO_DECIMAL(required_quantity_source,18,3) IS NULL
      AND COALESCE(required_quantity_source,'') <> ''

    UNION ALL
    SELECT
        'SRC_PLANNING_REQUIREMENTS',planning_record_id,'PRODUCTION_REQUIREMENT',
        'INVALID_USABLE_QUANTITY','ERROR',
        'Usable quantity cannot be converted to NUMBER',usable_quantity_source
    FROM PRODUCTION_REQUIREMENT
    WHERE TRY_TO_DECIMAL(usable_quantity_source,18,3) IS NULL
      AND COALESCE(usable_quantity_source,'') <> ''

    UNION ALL
    SELECT
        'SRC_PLANNING_REQUIREMENTS',planning_record_id,'PRODUCTION_REQUIREMENT',
        'UNRESOLVED_REQUIREMENT_UOM','ERROR',
        'No conversion to the canonical part base UOM is available',requirement_uom_source
    FROM PRODUCTION_REQUIREMENT
    WHERE uom_conversion_status='UNRESOLVED'
)
SELECT
    MD5(canonical_entity||'|'||source_business_key||'|'||issue_code),
    source_object,source_business_key,canonical_entity,issue_code,
    severity,issue_message,source_value
FROM detected_issues;
