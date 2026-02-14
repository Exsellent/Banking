
-- ============================================
-- Main Assignment
-- ============================================
-- Drop existing tables (for script re-runs)
DROP TABLE IF EXISTS operations CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS interest_rate_history CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS account_statuses CASCADE;
DROP TABLE IF EXISTS operation_types CASCADE;
DROP TABLE IF EXISTS product_types CASCADE;

-- ============================================
-- 1. REFERENCE: Banking Product Types
-- ============================================
CREATE TABLE product_types (
    product_type_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_deposit BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_types_name UNIQUE (name)
);

COMMENT ON TABLE product_types IS 'Reference of banking product types (deposits, savings accounts)';
COMMENT ON COLUMN product_types.product_type_id IS 'Unique identifier of the product type';
COMMENT ON COLUMN product_types.name IS 'Name of the product type';
COMMENT ON COLUMN product_types.is_deposit IS 'TRUE - fixed-term deposit, FALSE - savings account';

-- ============================================
-- 2. REFERENCE: Account Statuses
-- ============================================
CREATE TABLE account_statuses (
    status_id SERIAL PRIMARY KEY,
    status_code VARCHAR(20) NOT NULL,
    status_name VARCHAR(50) NOT NULL,
    description TEXT,
    CONSTRAINT uq_account_statuses_code UNIQUE (status_code)
);

COMMENT ON TABLE account_statuses IS 'Reference of bank account statuses';
COMMENT ON COLUMN account_statuses.status_code IS 'Status code for programmatic handling (open, closed, blocked)';
COMMENT ON COLUMN account_statuses.status_name IS 'Human-readable status name';

-- ============================================
-- 3. REFERENCE: Operation Types
-- ============================================
CREATE TABLE operation_types (
    operation_type_id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    CONSTRAINT uq_operation_types_code UNIQUE (code)
);

COMMENT ON TABLE operation_types IS 'Reference of account operation types';
COMMENT ON COLUMN operation_types.code IS 'Operation type code (deposit, withdraw, interest_accrual)';
COMMENT ON COLUMN operation_types.name IS 'Operation type name';

-- ============================================
-- 4. Bank Clients
-- ============================================
CREATE TABLE clients (
    client_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    birth_date DATE NOT NULL,
    passport_series VARCHAR(10) NOT NULL,
    passport_number VARCHAR(20) NOT NULL,
    passport_issued_by TEXT,
    passport_issue_date DATE,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    registration_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_clients_passport UNIQUE (passport_series, passport_number),
    CONSTRAINT chk_clients_birth_date CHECK (birth_date <= CURRENT_DATE),
    CONSTRAINT chk_clients_age CHECK (birth_date <= CURRENT_DATE - INTERVAL '18 years')
);

COMMENT ON TABLE clients IS 'Bank clients - individuals';
COMMENT ON COLUMN clients.client_id IS 'Unique client identifier';
COMMENT ON COLUMN clients.passport_series IS 'Passport series';
COMMENT ON COLUMN clients.passport_number IS 'Passport number';
COMMENT ON COLUMN clients.registration_date IS 'Registration date in the bank system';

-- ============================================
-- 5. Interest Rate History
-- ============================================
CREATE TABLE interest_rate_history (
    rate_history_id SERIAL PRIMARY KEY,
    product_type_id INTEGER NOT NULL,
    rate_percent NUMERIC(5,2) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_irh_product_type FOREIGN KEY (product_type_id) REFERENCES product_types(product_type_id) ON DELETE RESTRICT,
    CONSTRAINT chk_irh_rate_range CHECK (rate_percent >= 0 AND rate_percent <= 100),
    CONSTRAINT chk_irh_dates CHECK (effective_to IS NULL OR effective_to > effective_from)
);

COMMENT ON TABLE interest_rate_history IS 'History of interest rate changes by product type';
COMMENT ON COLUMN interest_rate_history.rate_percent IS 'Annual interest rate';
COMMENT ON COLUMN interest_rate_history.effective_from IS 'Rate effective start date';
COMMENT ON COLUMN interest_rate_history.effective_to IS 'Rate effective end date (NULL for current rate)';

-- ============================================
-- 6. Bank Accounts
-- ============================================
CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL,
    product_type_id INTEGER NOT NULL,
    status_id INTEGER NOT NULL,
    initial_rate_id INTEGER,
    account_number VARCHAR(20) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'RUB',
    current_balance NUMERIC(15,2) NOT NULL DEFAULT 0,
    current_rate NUMERIC(5,2) NOT NULL,
    opened_date DATE NOT NULL DEFAULT CURRENT_DATE,
    closed_date DATE,
    deposit_term_months INTEGER,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_accounts_client FOREIGN KEY (client_id) REFERENCES clients(client_id) ON DELETE RESTRICT,
    CONSTRAINT fk_accounts_product_type FOREIGN KEY (product_type_id) REFERENCES product_types(product_type_id) ON DELETE RESTRICT,
    CONSTRAINT fk_accounts_status FOREIGN KEY (status_id) REFERENCES account_statuses(status_id) ON DELETE RESTRICT,
    CONSTRAINT fk_accounts_initial_rate FOREIGN KEY (initial_rate_id) REFERENCES interest_rate_history(rate_history_id) ON DELETE RESTRICT,
    CONSTRAINT uq_accounts_number UNIQUE (account_number),
    CONSTRAINT chk_accounts_balance CHECK (current_balance >= 0),
    CONSTRAINT chk_accounts_currency CHECK (currency IN ('RUB', 'USD', 'EUR')),
    CONSTRAINT chk_accounts_rate CHECK (current_rate >= 0 AND current_rate <= 100),
    CONSTRAINT chk_accounts_dates CHECK (closed_date IS NULL OR closed_date >= opened_date),
    CONSTRAINT chk_accounts_term CHECK (deposit_term_months IS NULL OR deposit_term_months > 0)
);

COMMENT ON TABLE accounts IS 'Client bank accounts (deposits and savings accounts)';
COMMENT ON COLUMN accounts.account_id IS 'Unique account identifier';
COMMENT ON COLUMN accounts.account_number IS 'Unique account number';
COMMENT ON COLUMN accounts.current_balance IS 'Current account balance (denormalized for performance)';
COMMENT ON COLUMN accounts.current_rate IS 'Current interest rate on the account';
COMMENT ON COLUMN accounts.initial_rate_id IS 'Reference to the rate in effect at account opening';
COMMENT ON COLUMN accounts.deposit_term_months IS 'Deposit term in months (NULL for savings accounts)';

-- ============================================
-- 7. Account Operations
-- ============================================
CREATE TABLE operations (
    operation_id BIGSERIAL PRIMARY KEY,
    account_id INTEGER NOT NULL,
    operation_type_id INTEGER NOT NULL,
    operation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount NUMERIC(15,2) NOT NULL,
    balance_after NUMERIC(15,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_operations_account FOREIGN KEY (account_id) REFERENCES accounts(account_id) ON DELETE RESTRICT,
    CONSTRAINT fk_operations_type FOREIGN KEY (operation_type_id) REFERENCES operation_types(operation_type_id) ON DELETE RESTRICT,
    CONSTRAINT chk_operations_amount CHECK (amount > 0),
    CONSTRAINT chk_operations_balance CHECK (balance_after >= 0)
);

COMMENT ON TABLE operations IS 'Account operations (immutable table, INSERT-only)';
COMMENT ON COLUMN operations.operation_id IS 'Unique operation identifier';
COMMENT ON COLUMN operations.operation_date IS 'Operation execution date and time';
COMMENT ON COLUMN operations.amount IS 'Operation amount';
COMMENT ON COLUMN operations.balance_after IS 'Account balance after the operation (for audit)';

-- ============================================
-- INDEXES for performance
-- ============================================
-- Indexes for clients
CREATE INDEX idx_clients_passport ON clients(passport_series, passport_number);
CREATE INDEX idx_clients_phone ON clients(phone);
CREATE INDEX idx_clients_email ON clients(email) WHERE email IS NOT NULL;
CREATE INDEX idx_clients_registration_date ON clients(registration_date);

-- Indexes for interest_rate_history
CREATE INDEX idx_irh_product_type_id ON interest_rate_history(product_type_id);
CREATE INDEX idx_irh_effective_from ON interest_rate_history(effective_from);
CREATE INDEX idx_irh_product_dates ON interest_rate_history(product_type_id, effective_from, effective_to);

-- Indexes for accounts (critical for performance)
CREATE INDEX idx_accounts_client_id ON accounts(client_id);
CREATE INDEX idx_accounts_product_type_id ON accounts(product_type_id);
CREATE INDEX idx_accounts_status_id ON accounts(status_id);
CREATE INDEX idx_accounts_opened_date ON accounts(opened_date);
CREATE INDEX idx_accounts_client_status ON accounts(client_id, status_id);
CREATE INDEX idx_accounts_status_product ON accounts(status_id, product_type_id);

-- Indexes for operations (most heavily used table)
CREATE INDEX idx_operations_account_id ON operations(account_id);
CREATE INDEX idx_operations_type_id ON operations(operation_type_id);
CREATE INDEX idx_operations_date ON operations(operation_date);
CREATE INDEX idx_operations_account_date ON operations(account_id, operation_date DESC);
CREATE INDEX idx_operations_date_range ON operations(operation_date DESC);
CREATE INDEX idx_operations_account_type ON operations(account_id, operation_type_id);

-- ============================================
-- TRIGGERS for automatic updates
-- ============================================
-- Trigger to update updated_at in accounts
CREATE OR REPLACE FUNCTION update_accounts_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_accounts_updated_at
    BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION update_accounts_updated_at();

COMMENT ON FUNCTION update_accounts_updated_at() IS 'Automatically updates the updated_at field on record modification';

-- Trigger to update account balance on operation
CREATE OR REPLACE FUNCTION update_account_balance() RETURNS TRIGGER AS $$
BEGIN
    UPDATE accounts
    SET current_balance = NEW.balance_after,
        updated_at = CURRENT_TIMESTAMP
    WHERE account_id = NEW.account_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_account_balance
    AFTER INSERT ON operations
    FOR EACH ROW EXECUTE FUNCTION update_account_balance();

COMMENT ON FUNCTION update_account_balance() IS 'Automatically updates account balance after an operation';

-- ============================================
-- POPULATE REFERENCES with initial data
-- ============================================
-- Product types
INSERT INTO product_types (name, description, is_deposit) VALUES
('Fixed-term Deposit', 'Deposit with fixed term and interest rate', TRUE),
('Savings Account', 'Account allowing deposits and withdrawals', FALSE);

-- Account statuses
INSERT INTO account_statuses (status_code, status_name, description) VALUES
('open', 'Open', 'Account is active, all operations available'),
('closed', 'Closed', 'Account is closed, operations unavailable'),
('blocked', 'Blocked', 'Account is blocked, operations restricted');

-- Operation types
INSERT INTO operation_types (code, name, description) VALUES
('deposit', 'Deposit', 'Adding funds to the account'),
('withdraw', 'Withdrawal', 'Withdrawing funds from the account'),
('interest_accrual', 'Interest Accrual', 'Accruing interest on deposit or savings account');

-- ============================================
-- Information about the created structure
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Database successfully created!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables:';
    RAISE NOTICE ' - product_types (reference of product types)';
    RAISE NOTICE ' - account_statuses (reference of account statuses)';
    RAISE NOTICE ' - operation_types (reference of operation types)';
    RAISE NOTICE ' - clients (bank clients)';
    RAISE NOTICE ' - interest_rate_history (interest rate history)';
    RAISE NOTICE ' - accounts (bank accounts)';
    RAISE NOTICE ' - operations (account operations)';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Indexes: 20 indexes for query optimization';
    RAISE NOTICE 'Triggers: 2 triggers for automatic updates';
    RAISE NOTICE 'References: Pre-populated with basic data';
    RAISE NOTICE '========================================';

END $$;

