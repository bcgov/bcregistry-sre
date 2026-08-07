-- =============================================================================
-- test/seed-data.sql — Minimal seed data for testing
-- =============================================================================
-- Loaded automatically by Docker Compose init into source-db.
-- Data is inserted in FK-dependency order to avoid violations.
-- =============================================================================

-- Lookup data
INSERT INTO office_types (code, description) VALUES
    ('CEO', 'Chief Executive Officer'),
    ('CFO', 'Chief Financial Officer'),
    ('SECRETARY', 'Corporate Secretary'),
    ('DIRECTOR', 'Director'),
    ('REGISTERED_AGENT', 'Registered Agent');

INSERT INTO corp_types (code, description) VALUES
    ('BC', 'BC Limited Company'),
    ('ULC', 'Unlimited Liability Company'),
    ('C', 'Corporation');

INSERT INTO jurisdictions (name, abbrev) VALUES
    ('British Columbia', 'BC'),
    ('Alberta', 'AB'),
    ('Ontario', 'ON');

-- Businesses (state_filing_id will be set after filings are created)
INSERT INTO businesses (identifier, legal_name, state) VALUES
    ('BC0001000', 'Acme Corp Ltd.', 'ACTIVE'),
    ('BC0001001', 'Globex International Inc.', 'ACTIVE'),
    ('BC0001002', 'Initech Solutions Ltd.', 'HISTORICAL'),
    ('BC0001003', 'Umbrella Holdings Inc.', 'LIQUIDATION'),
    ('BC0001004', 'Sandbox Specific Corp', 'ACTIVE');

-- Filings (self-referencing: filing 3 is an amendment of filing 1)
INSERT INTO filings (business_id, filing_type, status, parent_filing_id) VALUES
    (1, 'INCORPORATION', 'COMPLETED', NULL),      -- filing 1
    (2, 'INCORPORATION', 'COMPLETED', NULL),      -- filing 2
    (1, 'AMALGAMATION', 'FILED', 1),              -- filing 3 (parent = filing 1)
    (3, 'DISSOLUTION', 'COMPLETED', NULL),        -- filing 4
    (4, 'LIQUIDATION', 'FILED', NULL),            -- filing 5
    (5, 'INCORPORATION', 'DRAFT', NULL);          -- filing 6 (sandbox-specific business)

-- Now set state_filing_id on businesses (completes the circular FK)
UPDATE businesses SET state_filing_id = 1 WHERE id = 1;
UPDATE businesses SET state_filing_id = 2 WHERE id = 2;
UPDATE businesses SET state_filing_id = 4 WHERE id = 3;
UPDATE businesses SET state_filing_id = 5 WHERE id = 4;
UPDATE businesses SET state_filing_id = 6 WHERE id = 5;

-- Offices (deep FK chain)
INSERT INTO offices (business_id, office_type, holder_name) VALUES
    (1, 'CEO', 'Alice Johnson'),
    (1, 'CFO', 'Bob Smith'),
    (1, 'SECRETARY', 'Carol White'),
    (2, 'CEO', 'Dave Wilson'),
    (2, 'DIRECTOR', 'Eve Davis'),
    (3, 'CEO', 'Frank Brown'),
    (4, 'REGISTERED_AGENT', 'Grace Lee'),
    (5, 'CEO', 'Henry Taylor');           -- sandbox-specific

-- Party roles (deepest in chain)
INSERT INTO party_roles (business_id, office_id, role_name) VALUES
    (1, 1, 'Primary Contact'),
    (1, 2, 'Financial Officer'),
    (2, 4, 'Primary Contact'),
    (5, 8, 'Primary Contact');            -- sandbox-specific

-- Version records
INSERT INTO businesses_version (business_id, legal_name, state) VALUES
    (1, 'Acme Corp Ltd.', 'ACTIVE'),
    (2, 'Globex International Inc.', 'ACTIVE');

INSERT INTO filings_version (filing_id, business_id, status) VALUES
    (1, 1, 'COMPLETED'),
    (2, 2, 'COMPLETED');

-- Addresses
INSERT INTO addresses (business_id, street, city) VALUES
    (1, '123 Main St', 'Victoria'),
    (1, '456 Oak Ave', 'Vancouver'),
    (2, '789 Pine Rd', 'Toronto');

-- Ensure sequences are set past max values
SELECT setval('businesses_id_seq', (SELECT max(id) FROM businesses));
SELECT setval('filings_id_seq', (SELECT max(id) FROM filings));
SELECT setval('offices_id_seq', (SELECT max(id) FROM offices));
SELECT setval('party_roles_id_seq', (SELECT max(id) FROM party_roles));
SELECT setval('businesses_version_id_seq', (SELECT max(id) FROM businesses_version));
SELECT setval('filings_version_id_seq', (SELECT max(id) FROM filings_version));
SELECT setval('jurisdictions_id_seq', (SELECT max(id) FROM jurisdictions));
