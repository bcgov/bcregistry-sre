-- =============================================================================
-- test/seed-source.sql — Test schema with circular FKs, enums, deep chains
-- =============================================================================
-- Loaded automatically by Docker Compose init into source-db.
-- Designed to exercise: circular FKs, self-referencing FKs, transitive
-- FK resolution (FK_DEPTH=-1), custom types, and seeding modes.
-- =============================================================================

-- Custom types
CREATE TYPE business_state AS ENUM ('ACTIVE', 'HISTORICAL', 'LIQUIDATION', 'DISSOLVED');
CREATE TYPE filing_status AS ENUM ('DRAFT', 'FILED', 'COMPLETED', 'CANCELLED');
CREATE TYPE office_type_code AS ENUM ('CEO', 'CFO', 'SECRETARY', 'DIRECTOR', 'REGISTERED_AGENT');

-- =============================================================================
-- Core tables with circular FKs: businesses ↔ filings
-- =============================================================================

-- businesses references filings via state_filing_id (deferred FK)
CREATE TABLE businesses (
    id              SERIAL PRIMARY KEY,
    identifier      VARCHAR(10) NOT NULL UNIQUE,
    legal_name      VARCHAR(250) NOT NULL,
    state           business_state NOT NULL DEFAULT 'ACTIVE',
    state_filing_id INTEGER,  -- FK to filings added later (circular)
    created_at      TIMESTAMP DEFAULT now()
);

CREATE TABLE filings (
    id              SERIAL PRIMARY KEY,
    business_id     INTEGER NOT NULL,
    filing_type     VARCHAR(50) NOT NULL,
    status          filing_status NOT NULL DEFAULT 'DRAFT',
    parent_filing_id INTEGER,  -- self-referencing FK
    transaction_id  INTEGER,
    created_at      TIMESTAMP DEFAULT now(),

    -- Forward FK: filings → businesses
    CONSTRAINT fk_filings_business
        FOREIGN KEY (business_id) REFERENCES businesses(id),

    -- Self-referencing FK: filings → filings
    CONSTRAINT fk_filings_parent
        FOREIGN KEY (parent_filing_id) REFERENCES filings(id)
);

-- Back-reference FK: businesses → filings (circular with fk_filings_business)
ALTER TABLE businesses
    ADD CONSTRAINT fk_businesses_state_filing
    FOREIGN KEY (state_filing_id) REFERENCES filings(id);

-- =============================================================================
-- Deep FK chain: businesses → offices → office_holders → party_roles
-- =============================================================================

CREATE TABLE office_types (
    code office_type_code PRIMARY KEY,
    description VARCHAR(200) NOT NULL
);

CREATE TABLE offices (
    id          SERIAL PRIMARY KEY,
    business_id INTEGER NOT NULL,
    office_type office_type_code NOT NULL,
    holder_name VARCHAR(200),

    CONSTRAINT fk_offices_business
        FOREIGN KEY (business_id) REFERENCES businesses(id),
    CONSTRAINT fk_offices_type
        FOREIGN KEY (office_type) REFERENCES office_types(code)
);

CREATE TABLE party_roles (
    id          SERIAL PRIMARY KEY,
    business_id INTEGER NOT NULL,
    office_id   INTEGER NOT NULL,
    role_name   VARCHAR(100) NOT NULL,

    CONSTRAINT fk_party_roles_business
        FOREIGN KEY (business_id) REFERENCES businesses(id),
    CONSTRAINT fk_party_roles_office
        FOREIGN KEY (office_id) REFERENCES offices(id)
);

-- =============================================================================
-- Version tables (common pattern in the real schema)
-- =============================================================================

CREATE TABLE businesses_version (
    id              SERIAL PRIMARY KEY,
    business_id     INTEGER NOT NULL,
    legal_name      VARCHAR(250) NOT NULL,
    state           business_state NOT NULL,

    CONSTRAINT fk_biz_ver_business
        FOREIGN KEY (business_id) REFERENCES businesses(id)
);

CREATE TABLE filings_version (
    id              SERIAL PRIMARY KEY,
    filing_id       INTEGER NOT NULL,
    business_id     INTEGER NOT NULL,
    status          filing_status NOT NULL,

    CONSTRAINT fk_filing_ver_filing
        FOREIGN KEY (filing_id) REFERENCES filings(id),
    CONSTRAINT fk_filing_ver_business
        FOREIGN KEY (business_id) REFERENCES businesses(id)
);

-- =============================================================================
-- Shared lookup tables (used by seed_target_backup tests)
-- =============================================================================

CREATE TABLE corp_types (
    code VARCHAR(10) PRIMARY KEY,
    description VARCHAR(200) NOT NULL
);

CREATE TABLE jurisdictions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    abbrev VARCHAR(10) NOT NULL UNIQUE
);

-- =============================================================================
-- Table with no PK (tests seed_target_backup fallback to DO NOTHING)
-- =============================================================================

CREATE TABLE addresses (
    id SERIAL,
    business_id INTEGER NOT NULL,
    street VARCHAR(200) NOT NULL,
    city VARCHAR(100) NOT NULL,

    CONSTRAINT fk_addresses_business
        FOREIGN KEY (business_id) REFERENCES businesses(id)
);

-- =============================================================================
-- Grant permissions to loader user
-- =============================================================================
GRANT ALL ON ALL TABLES IN SCHEMA public TO loader;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO loader;
