-- Part 5: Canonical evidence views.
-- These views expose typed business facts for Part 6. They are not governed
-- metric definitions and do not publish anything to SEMANTIC.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.CORE;

CREATE OR REPLACE VIEW V_PO_LINE_RECEIPT_EVIDENCE AS
WITH receipt_quality AS (
    SELECT
        sl.po_number,
        sl.po_line_number,
        r.receipt_id,
        r.receipt_date,
        r.physical_received_quantity_base,
        IFF(i.is_final AND i.inspection_arithmetic_status='VALID' AND i.uom_conversion_status='SAME_AS_BASE',COALESCE(i.accepted_quantity_base,0),0) accepted_quantity_base,
        IFF(i.is_final AND i.inspection_arithmetic_status='VALID' AND i.uom_conversion_status='SAME_AS_BASE',COALESCE(i.rejected_quantity_base,0),0) rejected_quantity_base,
        IFF(i.is_final AND i.inspection_arithmetic_status='VALID' AND i.uom_conversion_status='SAME_AS_BASE',COALESCE(i.damaged_quantity_base,0),0) damaged_quantity_base,
        IFF(i.inspection_id IS NULL OR NOT COALESCE(i.is_final,FALSE),COALESCE(r.physical_received_quantity_base,0),0) pending_inspection_received_base
    FROM SHIPMENT_LINE sl
    LEFT JOIN RECEIPT r
      ON r.shipment_id=sl.shipment_id AND r.shipment_line_number=sl.shipment_line_number
    LEFT JOIN INSPECTION i ON i.receipt_id=r.receipt_id
), shipment_totals AS (
    SELECT po_number,po_line_number,SUM(COALESCE(shipped_quantity_base,0)) total_shipped_quantity_base
    FROM SHIPMENT_LINE
    GROUP BY po_number,po_line_number
)
SELECT
    pol.po_number,
    pol.po_line_number,
    po.supplier_id,
    pol.part_id,
    pol.destination_plant_id,
    pol.ordered_quantity_base,
    pol.original_requested_delivery_date,
    pol.revised_requested_delivery_date,
    pol.line_status,
    pol.metric_eligibility_status,
    COALESCE(st.total_shipped_quantity_base,0) total_shipped_quantity_base,
    COALESCE(SUM(rq.physical_received_quantity_base),0) total_physical_received_quantity_base,
    COALESCE(SUM(rq.accepted_quantity_base),0) total_accepted_quantity_base,
    COALESCE(SUM(rq.rejected_quantity_base),0) total_rejected_quantity_base,
    COALESCE(SUM(rq.damaged_quantity_base),0) total_damaged_quantity_base,
    COALESCE(SUM(rq.pending_inspection_received_base),0) pending_inspection_received_base,
    COALESCE(SUM(IFF(rq.receipt_date<=pol.original_requested_delivery_date,rq.accepted_quantity_base,0)),0) accepted_by_original_po_date_base,
    COALESCE(SUM(IFF(rq.receipt_date<=pol.revised_requested_delivery_date,rq.accepted_quantity_base,0)),0) accepted_by_revised_po_date_base,
    LEAST(pol.ordered_quantity_base,COALESCE(SUM(IFF(rq.receipt_date<=pol.original_requested_delivery_date,rq.accepted_quantity_base,0)),0)) capped_accepted_by_original_po_date_base
FROM PURCHASE_ORDER_LINE pol
JOIN PURCHASE_ORDER po ON po.po_number=pol.po_number
LEFT JOIN receipt_quality rq ON rq.po_number=pol.po_number AND rq.po_line_number=pol.po_line_number
LEFT JOIN shipment_totals st ON st.po_number=pol.po_number AND st.po_line_number=pol.po_line_number
GROUP BY
    pol.po_number,pol.po_line_number,po.supplier_id,pol.part_id,
    pol.destination_plant_id,pol.ordered_quantity_base,
    pol.original_requested_delivery_date,pol.revised_requested_delivery_date,
    pol.line_status,pol.metric_eligibility_status,st.total_shipped_quantity_base;

CREATE OR REPLACE VIEW V_SHIPMENT_LINE_ARRIVAL_EVIDENCE AS
SELECT
    sl.shipment_id,
    sl.shipment_line_number,
    sl.po_number,
    sl.po_line_number,
    sh.supplier_id,
    sh.carrier_id,
    sh.destination_plant_id,
    sl.part_id,
    sl.shipped_quantity_base,
    sl.original_carrier_commitment_date,
    sl.revised_carrier_commitment_date,
    sl.line_status,
    sl.metric_eligibility_status,
    COALESCE(SUM(r.physical_received_quantity_base),0) total_physical_received_quantity_base,
    COALESCE(SUM(IFF(r.receipt_date<=sl.original_carrier_commitment_date,r.physical_received_quantity_base,0)),0) received_by_original_commitment_base,
    COALESCE(SUM(IFF(r.receipt_date<=sl.revised_carrier_commitment_date,r.physical_received_quantity_base,0)),0) received_by_revised_commitment_base,
    LEAST(sl.shipped_quantity_base,COALESCE(SUM(IFF(r.receipt_date<=sl.original_carrier_commitment_date,r.physical_received_quantity_base,0)),0)) capped_received_by_original_commitment_base
FROM SHIPMENT_LINE sl
JOIN SHIPMENT sh ON sh.shipment_id=sl.shipment_id
LEFT JOIN RECEIPT r ON r.shipment_id=sl.shipment_id AND r.shipment_line_number=sl.shipment_line_number
GROUP BY
    sl.shipment_id,sl.shipment_line_number,sl.po_number,sl.po_line_number,
    sh.supplier_id,sh.carrier_id,sh.destination_plant_id,sl.part_id,
    sl.shipped_quantity_base,sl.original_carrier_commitment_date,
    sl.revised_carrier_commitment_date,sl.line_status,
    sl.metric_eligibility_status;

CREATE OR REPLACE VIEW V_PRODUCTION_REQUIREMENT_EVIDENCE AS
SELECT
    planning_record_id,
    production_plan_id,
    part_id,
    plant_id,
    production_need_date,
    required_quantity_base,
    usable_quantity_base,
    LEAST(required_quantity_base,usable_quantity_base) capped_usable_quantity_base,
    GREATEST(required_quantity_base-COALESCE(usable_quantity_base,0),0) shortage_quantity_base,
    requirement_status,
    metric_eligibility_status,
    snapshot_timestamp
FROM PRODUCTION_REQUIREMENT;
