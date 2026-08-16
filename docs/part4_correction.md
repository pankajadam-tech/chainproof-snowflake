1. Hard runtime blocker: stage validation
File
snowflake/13_part4_raw_validation.sql
Current lines
7–10
Problem

The validation reads:

SELECT *
FROM DIRECTORY(@PART4_SOURCE_STAGE);

But the setup creates the stage without enabling a directory table, and the upload script does not refresh directory metadata. Snowflake’s DIRECTORY(@stage) mechanism requires a directory table to be enabled and refreshed for an internal stage. The current validation can therefore fail after the data has already been loaded.

Exact correction

Replace the directory-table query with a normal stage LIST, which does not require directory-table configuration:

LIST @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/
PATTERN = '.*[.]csv';


SET part4_list_query_id = LAST_QUERY_ID();


SELECT
    "name" AS staged_file_name,
    "size" AS file_size_bytes,
    "md5" AS file_md5,
    "last_modified"
FROM TABLE(RESULT_SCAN($part4_list_query_id))
ORDER BY staged_file_name;

Use the same LIST result to verify:

exactly 12 files;
the exact 12 filenames;
no unexpected files under /v1/;
every file has a nonzero size.

Do not enable a directory table unless the project actually needs one. LIST is sufficient for Part 4.

2. The exact CSV source contracts have not been restored

The current CSVs still use abbreviated schemas, different suppliers, different identifiers, EACH instead of EA, and changed business scenarios. The original Part 4 requirement was not merely “produce totals that happen to match”; it required deterministic source-system files that preserve the approved scenarios.

Master-data files
File and current lines	Required correction
data/raw/supplier_master.csv, lines 1–5	Replace the entire file. Header must be supplier_id,supplier_name,country_code,city_name,supplier_status,erp_supplier_code,logistics_supplier_code. Restore S-101 BatteryWorks, S-102 PowerCell Industries, S-103 VoltEdge Components, and inactive S-199 Legacy Battery Co.
data/raw/erp_part_master.csv, lines 1–2	Replace the entire file. Header must include part_status, planning_part_code, and logistics_part_code. Base UOM must be EA, not EACH.
data/raw/erp_plant_master.csv, lines 1–2	Replace the entire file. Add city, state/region, country, timezone, status, Planning code, and Logistics code.
data/raw/logistics_carrier_master.csv, lines 1–4	Replace the entire file. Use C-301 SwiftAir Cargo, C-302 IndiaRoad Freight, and C-303 OceanLink Logistics, with transport mode and status.

Required master values:

Supplier S-101
BatteryWorks
Shenzhen
ACTIVE
ERP code: BW-ERP-01
Logistics code: BATWRK-LOG


Supplier S-102
PowerCell Industries
Busan
ACTIVE
ERP code: PC-ERP-02
Logistics code: PWRCL-LOG


Supplier S-103
VoltEdge Components
Ho Chi Minh City
ACTIVE
ERP code: VE-ERP-03
Logistics code: VOLTEDGE-LOG


Supplier S-199
Legacy Battery Co
Mumbai
INACTIVE
ERP code: LBC-ERP-99
Logistics code: LEGACY-LOG
Part ID: P-2001
Part name: Laptop Battery 65W
Category: BATTERY
Base UOM: EA
Status: ACTIVE
Planning code: BAT-65W-PLAN
Logistics code: BAT65-LG
Plant ID: PLT-01
Plant name: Pune Plant
City: Pune
State: Maharashtra
Country: IN
Timezone: Asia/Kolkata
Status: ACTIVE
Planning code: PUNE_MFG
Logistics code: PNQ_RECEIVING

Country-code values were not exhaustively fixed in the approved business documentation. Use one consistent documented convention, such as CN, KR, VN, and IN, rather than changing between full names and codes.

Transaction files
File and current lines	Required correction
data/raw/erp_purchase_orders.csv, lines 1–14	Replace the entire file with the seven-column PO-header contract.
data/raw/erp_purchase_order_lines.csv, lines 1–14	Replace the entire file with the exact 13 PO-line scenarios.
data/raw/logistics_shipments.csv, lines 1–16	Replace the entire file; add origin, destination source code, shipment status, and tracking reference.
data/raw/logistics_shipment_lines.csv, lines 1–16	Replace the entire file; include original and revised carrier dates plus line status.
data/raw/logistics_receipts.csv, lines 1–15	Replace the entire file; include Logistics plant code, receiving dock, and receipt status.
data/raw/quality_inspections.csv, lines 1–14	Replace the entire file; include completion date, inspection UOM, disposition, and inspection status.
data/raw/planning_requirements.csv, lines 1–14	Replace the entire file; include planning-record ID, production-plan ID, snapshot timestamp, and requirement status.
data/raw/identity_persona_map.csv, lines 1–6	Replace the five records with the approved identities and scopes.

Exact headers:

# erp_purchase_orders.csv
po_number,erp_supplier_code,po_creation_date,destination_plant_id,currency_code,buyer_id,po_status
# erp_purchase_order_lines.csv
po_number,po_line_number,part_id,destination_plant_id,ordered_quantity,order_uom,original_requested_delivery_date,revised_requested_delivery_date,unit_price,line_status
# logistics_shipments.csv
shipment_id,logistics_supplier_code,carrier_id,origin_location,logistics_destination_plant_code,ship_date,shipment_status,tracking_reference
# logistics_shipment_lines.csv
shipment_id,shipment_line_number,po_number,po_line_number,logistics_part_code,shipped_quantity,shipment_uom,original_carrier_commitment_date,revised_carrier_commitment_date,line_status
# logistics_receipts.csv
receipt_id,shipment_id,shipment_line_number,logistics_plant_code,physical_received_quantity,receipt_uom,receipt_date,receiving_dock,receipt_status
# quality_inspections.csv
inspection_id,receipt_id,inspection_completion_date,inspected_quantity,accepted_quantity,rejected_quantity,damaged_quantity,inspection_uom,disposition,inspection_status
# planning_requirements.csv
planning_record_id,production_plan_id,planning_part_code,planning_plant_code,production_need_date,required_quantity,requirement_uom,usable_quantity_available_by_need_date,snapshot_timestamp,requirement_status
# identity_persona_map.csv
user_id,snowflake_user_name,default_persona,default_plant_scope,can_approve_metrics,assignment_status,effective_start_date,effective_end_date

Fields such as buyer_id, tracking_reference, exact inspection completion time, and PO creation dates were not fully prescribed by the business contract. They can be deterministic synthetic values, but they must remain internally consistent and must not alter the required metric scenarios.

3. Exact scenario values that must not be improvised

The current files changed several scenarios merely to make some aggregate totals work. That is not acceptable because later Parts 5–7 will depend on the individual scenario meanings, not just the total.

Use this as the source-of-truth matrix:

PO	Ordered	Procurement result	Logistics result	Planning result
PO-5001	100 EA	85 / 100 = 85%	90 / 100 = 90%	95 / 100 = 95%
PO-5002	50 EA	50 / 50 = 100%	50 / 50 = 100%	50 / 50 = 100%
PO-5003	80 EA	0 / 80 = 0%	0 / 80 = 0%	80 / 80 = 100%
PO-5004	120 EA	48 / 120 = 40%	100 / 120 = 83.333333%	118 / 120 = 98.333333%
PO-5005	60 EA	capped at 60 / 60 = 100%	70 / 70 = 100%	capped at 60 / 60 = 100%
PO-5006	40 EA	0 / 40 = 0%	0 / 40 = 0%	40 / 40 = 100%
PO-5007	30 EA	0 / 30 = 0%	30 / 30 = 100%	0 / 30 = 0%
PO-5008	75 EA	45 / 75 = 60%	75 / 75 = 100%	70 / 75 = 93.333333%
Required shipment and receipt details
PO-5001
SH-9001:
90 EA, carrier commitment August 8, receipt August 8
Accepted 85, rejected 5, damaged 5


SH-9002:
10 EA, carrier commitment August 10, receipt August 11
Accepted 10
PO-5002
SH-9003:
50 EA, commitment August 9, receipt August 9
Accepted 50
PO-5003
SH-9004:
80 EA, commitment August 10, receipt August 11
Accepted 80


Production need:
August 14
Available usable:
80
PO-5004
SH-9005:
70 EA, commitment August 10
R-8005: 50 received August 9, 48 accepted, 2 rejected/damaged
R-8006: 20 received August 11, 20 accepted


SH-9006:
50 EA, commitment August 12
R-8007: 50 received August 12, 50 accepted


Planning:
120 required, 118 available
PO-5005
Ordered:
60 EA


SH-9007:
70 EA shipped
70 received on August 11
68 accepted
2 rejected/damaged


The order-based and planning metrics are capped at 100%.
The Logistics denominator remains 70 shipped.
PO-5006
Ordered:
40 EA


Original PO date:
August 10


Revised PO date:
August 12


Original carrier commitment:
August 10


Revised carrier commitment:
August 12


Actual receipt:
August 12


Accepted:
40


Version 1.0 uses original dates:
Procurement 0%
Logistics 0%
Planning 100%
PO-5007
Ordered:
30 EA


SH-9009:
30 received on time


R-8010:
No final inspection row


Planning usable quantity:
0
PO-5008
SH-9010:
50 EA
Receipt August 13
Accepted 45
Rejected/damaged 5


SH-9011:
25 EA
Receipt August 14
Accepted 25


PO requested date:
August 13


Only the first 45 accepted units count for Procurement.
Both shipments count for Logistics.
Planning usable quantity is 70.
Required edge cases
PO-5009:
Future original requested date of August 20
No shipment required
Excluded from historical Procurement/Enterprise performance as of August 15


PO-5010:
Canceled PO and PO line
Ordered quantity 0
SH-9014 is VOID with shipped quantity 0
No receipt


PO-5011:
Original PO date missing
Original carrier commitment missing
Revised dates present
25 received and accepted
Must remain a data-quality case


PO-5012:
ordered_quantity = NOT_A_NUMBER
shipped_quantity = NOT_A_NUMBER
No receipt


PO-5013:
10 BOX ordered, shipped, received, and accepted
No BOX-to-EA conversion
Must remain unresolved in RAW

Planning must also contain four explicit data-quality records:

Canceled requirement with required quantity 0
Missing production need date
required_quantity = NOT_A_NUMBER
requirement_uom = BOX without conversion
4. Current aggregate Logistics result is wrong

The current files appear to have been adjusted so that Planning and Procurement totals reach their expected aggregate numerators, but the individual scenarios are different and the Logistics aggregate still fails.

From the current committed shipment and receipt rows, I calculate:

Current Logistics numerator:
340


Current Logistics denominator:
565


Current rate:
340 / 565 = 60.17699115%

The required result is:

415 / 565 = 73.45132743%

The exact required aggregate checks are:

Planning:
513 / 555 = 0.9243243243


Procurement:
288 / 555 = 0.5189189189


Enterprise:
288 / 555 = 0.5189189189


Logistics:
415 / 565 = 0.7345132743

This difference comes from the changed PO-5003, PO-5004, PO-5006, and PO-5008 source scenarios.

5. RAW table DDL must match the complete CSV schemas
File
snowflake/11_part4_raw_tables.sql
Current lines
10–187
Required action

Replace the 12 table definitions so that their business columns match the exact CSV headers above.

The ingestion metadata types now appear correct and should be preserved:

load_batch_id VARCHAR NOT NULL,
source_file_name VARCHAR NOT NULL,
source_file_row_number NUMBER NOT NULL,
source_file_content_key VARCHAR,
source_file_last_modified TIMESTAMP_NTZ,
loaded_at TIMESTAMP_LTZ NOT NULL

Those types match Snowflake’s staged-file metadata types: file modification time is TIMESTAMP_NTZ, while scan start time is TIMESTAMP_LTZ.

All source business fields should remain VARCHAR. Only the six ingestion metadata columns receive Snowflake-native metadata types.

Do not use CREATE OR REPLACE TABLE as the normal rerun mechanism. Use:

CREATE TABLE IF NOT EXISTS ...

followed by controlled:

TRUNCATE TABLE ...

in the load step.

Because the existing draft tables may have an outdated column structure, the first corrected deployment needs either:

explicit DROP TABLE IF EXISTS statements limited to the 12 unapproved Part 4 draft tables, followed by corrected creation; or
manual removal of the unapproved draft tables before the corrected loader is executed.

After the corrected design becomes approved, subsequent reruns should truncate rather than recreate.

6. Load SQL column positions must be rebuilt
File
snowflake/12_part4_raw_load.sql
Current lines
11–130
Required action

Update all 12 COPY INTO statements for the corrected CSV column counts:

File/table	Business columns
Supplier master	7
Part master	7
Plant master	9
Carrier master	4
PO headers	7
PO lines	10
Shipments	8
Shipment lines	10
Receipts	9
Inspections	10
Planning requirements	10
Persona mapping	8

Each COPY INTO should have an explicit target-column list:

COPY INTO CHAINPROOF.RAW.SRC_ERP_PURCHASE_ORDER_LINES (
    po_number,
    po_line_number,
    part_id,
    destination_plant_id,
    ordered_quantity,
    order_uom,
    original_requested_delivery_date,
    revised_requested_delivery_date,
    unit_price,
    line_status,
    load_batch_id,
    source_file_name,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        $10,
        'PART4_SYNTHETIC_V1',
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/erp_purchase_order_lines.csv
)
FILE_FORMAT = (
    FORMAT_NAME = CHAINPROOF.RAW.PART4_CSV_FORMAT
)
ON_ERROR = ABORT_STATEMENT
FORCE = TRUE;

Apply that pattern to all 12 tables. Do not cast, trim, normalize, or repair the business fields during COPY INTO.

7. File-format setup must be deterministic
File
snowflake/10_part4_raw_setup.sql
Current lines
9–22
Problem

CREATE FILE FORMAT IF NOT EXISTS does not repair an existing file format with incorrect settings. A previous partial run could leave the object present but wrongly configured.

Required replacement

Use:

CREATE OR REPLACE FILE FORMAT CHAINPROOF.RAW.PART4_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
    ENCODING = 'UTF8'
    TRIM_SPACE = FALSE;

Keep the internal stage without replacing it:

CREATE STAGE IF NOT EXISTS CHAINPROOF.RAW.PART4_SOURCE_STAGE
    FILE_FORMAT = CHAINPROOF.RAW.PART4_CSV_FORMAT
    COMMENT = 'Internal stage for deterministic Part 4 synthetic source files';

Replacing the stage could unnecessarily remove or invalidate uploaded-file state. The file format itself is safe to recreate before loading.

8. The automated tests are still incomplete
File
tests/part4_raw_data_tests.sql
Current lines
8–279
Required action

Replace the whole test body.

The Snowflake Scripting syntax is now substantially corrected, but the file has only a limited set of assertions and ends with an “all tests passed” result without proving most of the acceptance contract. It does not comprehensively test:

active role, warehouse, database, and schema;
exact staged filenames;
file-format settings;
exact business columns and their positions;
metadata types and nullability;
metadata completeness in all 12 tables;
unique source keys;
all parent/child relationships;
complete inspection arithmetic;
actual scenario calculations;
aggregate ratio-of-sums;
rerun idempotency;
or unexpected RAW objects.

The replacement must contain fail-fast assertions for all of the following:

Current role is GRIZZLY03_LEARNER_RL.
Warehouse is GRIZZLY03_WH.
Database is CHAINPROOF.
Schema is RAW.
File format exists with every exact option.
Stage exists.
Exactly 12 exact CSV filenames exist under /v1/.
Exactly 12 expected RAW tables exist.
Exact column contract for each table.
All business columns are text.
Metadata types and nullability are correct.
Exact row count for each table.
Total row count is 110.
All required metadata is populated.
Every batch ID is PART4_SYNTHETIC_V1.
All source keys are unique.
Every PO line references a PO.
Every shipment line references a shipment and PO line.
Every receipt references a shipment line.
Every inspection references a receipt.
accepted + rejected = inspected.
damaged <= rejected.
inspected <= physically received.
R-8010 has no inspection.
PO-5001 results are 0.95, 0.85, 0.85, and 0.90.
PO-5004 through PO-5007 special results are exact.
PO-5009 through PO-5013 edge records are exact.
Aggregate ratio-of-sums results are exact.
No duplicate accumulation exists after a rerun.
No Part 4 objects were created outside RAW.

Each critical assertion must use a named exception and:

RAISE validation_failed;

The final success message must only run after all assertions complete.

9. The readable validation file needs the same coverage
File
snowflake/13_part4_raw_validation.sql
Current lines
7–111
Required action

Replace or substantially expand the whole validation section.

Every result set should expose:

check_name
expected_value
actual_value
status

The human-readable file should include the same categories as the fail-fast tests but display all results instead of stopping at the first failure.

At minimum, it must display:

stage files;
file-format options;
table and column inventory;
per-table and total row counts;
metadata completeness;
key duplication counts;
orphan counts;
inspection violations;
each scenario result;
aggregate results;
intentional edge-case records;
load-history status;
unexpected objects.
10. The shell script needs stronger preflight checks
File
scripts/load_part4_raw.sh
Current lines
18–56
Required corrections
Use an argument array

Instead of storing several flags in a plain string, use:

SNOW_OPTS=(
  --connection default
  --role GRIZZLY03_LEARNER_RL
  --warehouse GRIZZLY03_WH
  --database CHAINPROOF
  --schema RAW
  --enhanced-exit-codes
)

Then invoke:

snow sql "${SNOW_OPTS[@]}" -f snowflake/10_part4_raw_setup.sql
Validate more than the number of local CSVs

Before any Snowflake mutation, verify locally:

exactly 12 files;
exact filenames;
exact headers;
exact row count per file;
exact column count on every row;
exactly 110 total data rows;
exact required sentinel values such as NOT_A_NUMBER, BOX, and missing dates.

A file count alone is insufficient.

Use enhanced exit codes

Add:

--enhanced-exit-codes

to supported Snowflake CLI calls so SQL failures produce a nonzero script exit status.

Preserve no compression

Keep:

--no-auto-compress

because the validation expects .csv filenames.

Prevent stale stage files

Before upload, remove only the controlled Part 4 stage path:

REMOVE @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/
PATTERN = '.*[.]csv';

Then upload the exact 12 files. This prevents an obsolete thirteenth file from surviving a previous run.

Do not remove anything outside /v1/.

11. Documentation corrections
docs/part4_source_data.md

Correct these current line ranges:

Lines	Problem
8–9	Says all columns are VARCHAR; clarify that all source business columns are VARCHAR, while ingestion metadata uses typed Snowflake columns.
17	Describes replacement behavior differently from the setup SQL.
35–50	Describes changed scenario values rather than the approved scenarios.
72–84	Uses stale batch/timestamp wording.
90–104	Describes table-recreation and rerun behavior inconsistently.

The batch must be documented as:

PART4_SYNTHETIC_V1

The load timestamp must be documented as:

METADATA$START_SCAN_TIME

The document should contain the exact scenario table from this review.

docs/part4_acceptance_criteria.md

Correct and expand:

lines 38–53
lines 61–75

It must explicitly require:

exact complete column contracts;
metadata types and nullability;
all 12 exact staged files;
110 rows;
all scenario results;
all aggregate results;
all relationship checks;
all edge cases;
second-run idempotency.

Runtime boxes must remain unchecked until actual Snowflake evidence exists.

12. Files that should remain unchanged for now

Do not update these until the corrected loader has passed twice:

PROJECT_STATE.md
README.md

PROJECT_STATE.md should continue to say that Part 3 is complete and Part 4 is next. The final Part 4 status should only be recorded after runtime evidence exists.

Do not modify any approved Part 3 document.

13. Local checks before the next commit

Before pushing the correction commit, run only local checks:

git status --short
git diff --check
bash -n scripts/load_part4_raw.sh

The corrected loader should perform its own CSV preflight without connecting to Snowflake. That preflight must report:

12 exact CSV files
110 total data rows
all headers correct
all row widths correct
all required scenarios present
all required edge cases present

Also inspect the committed file scope:

git diff --name-only 565016a1dcf8135bc09abb1995a7d5a3d98e6766..HEAD

There must be no:

.env
config.toml
connections.toml
private key
token
credential file
CORE implementation
GOVERNANCE implementation
SEMANTIC implementation
APP implementation
AUDIT implementation
