-- 


-- ============================================
-- 1. Clients (5 clients)
-- ============================================
INSERT INTO clients (first_name, last_name, middle_name, birth_date, passport_series, passport_number, passport_issued_by, passport_issue_date, phone, email) VALUES
('John', 'Smith', 'Michael', '1985-03-15', 'CA', 'D12345678', 'California DMV', '2005-04-20', '+12025550123', 'john.smith@example.com'),
('Emily', 'Johnson', 'Rose', '1990-07-22', 'NY', 'D87654321', 'New York DMV', '2010-08-15', '+13105551234', 'emily.johnson@example.com'),
('Michael', 'Williams', 'James', '1978-11-30', 'TX', 'D11223344', 'Texas DPS', '1998-12-10', '+17135559876', NULL),
('Sarah', 'Brown', 'Elizabeth', '1995-05-10', 'FL', 'D99887766', 'Florida DHSMV', '2015-06-25', '+14045556789', 'sarah.brown@example.com'),
('David', 'Jones', 'Andrew', '1982-09-18', 'IL', 'D55443322', 'Illinois Secretary of State', '2002-10-30', '+13125554321', 'david.jones@example.com');

-- ============================================
-- 2. Interest Rate History (5 records)
-- ============================================
-- Rates for fixed-term deposits (product_type_id = 1)
INSERT INTO interest_rate_history (product_type_id, rate_percent, effective_from, effective_to) VALUES
(1, 7.00, '2024-01-01', '2024-03-31'),  -- rate_history_id = 1
(1, 7.50, '2024-04-01', '2024-06-30'),  -- rate_history_id = 2
(1, 8.00, '2024-07-01', NULL);          -- rate_history_id = 3 (current)

-- Rates for savings accounts (product_type_id = 2)
INSERT INTO interest_rate_history (product_type_id, rate_percent, effective_from, effective_to) VALUES
(2, 5.00, '2024-01-01', '2024-05-31'),  -- rate_history_id = 4
(2, 5.50, '2024-06-01', NULL);          -- rate_history_id = 5 (current)

-- ============================================
-- 3. Bank Accounts (8 accounts)
-- ============================================
-- status_id: 1 = open, 2 = closed, 3 = blocked
-- All accounts now in USD except client 5 (EUR)

-- Accounts of client 1 (John Smith): deposit and savings
INSERT INTO accounts (client_id, product_type_id, status_id, initial_rate_id, account_number, currency, current_balance, current_rate, opened_date, deposit_term_months) VALUES
(1, 1, 1, 3, '40817810000000000001', 'USD', 510000.00, 8.00, '2024-07-01', 12),        -- Fixed-term deposit
(1, 2, 1, 5, '40817810000000000002', 'USD', 160650.00, 5.50, '2024-06-15', NULL);      -- Savings account

-- Accounts of client 2 (Emily Johnson): savings and deposit
INSERT INTO accounts (client_id, product_type_id, status_id, initial_rate_id, account_number, currency, current_balance, current_rate, opened_date, deposit_term_months) VALUES
(2, 2, 1, 5, '40817810000000000003', 'USD', 251900.00, 5.50, '2024-08-01', NULL),      -- Savings account
(2, 1, 1, 3, '40817810000000000004', 'USD', 765000.00, 8.00, '2024-07-15', 24);        -- Fixed-term deposit

-- Account of client 3 (Michael Williams): savings
INSERT INTO accounts (client_id, product_type_id, status_id, initial_rate_id, account_number, currency, current_balance, current_rate, opened_date, deposit_term_months) VALUES
(3, 2, 1, 4, '40817810000000000005', 'USD', 40590.00, 5.50, '2024-03-10', NULL);       -- Savings account

-- Accounts of client 4 (Sarah Brown): two deposits (one closed)
INSERT INTO accounts (client_id, product_type_id, status_id, initial_rate_id, account_number, currency, current_balance, current_rate, opened_date, deposit_term_months) VALUES
(4, 1, 1, 2, '40817810000000000006', 'USD', 1037850.00, 7.50, '2024-04-20', 12),       -- Fixed-term deposit (active)
(4, 1, 2, 1, '40817810000000000007', 'USD', 0.00, 7.00, '2024-01-15', 6);              -- Fixed-term deposit (CLOSED)

-- Account of client 5 (David Jones): savings in EUR
INSERT INTO accounts (client_id, product_type_id, status_id, initial_rate_id, account_number, currency, current_balance, current_rate, opened_date, deposit_term_months) VALUES
(5, 2, 1, 5, '40817840000000000008', 'EUR', 5022.92, 5.50, '2024-09-01', NULL);        -- Savings EUR

-- ============================================
-- 4. Account Operations (27 operations)
-- ============================================
-- operation_type_id: 1 = deposit, 2 = withdraw, 3 = interest_accrual

-- Operations for account 1 (John Smith's deposit)
INSERT INTO operations (account_id, operation_type_id, operation_date, amount, balance_after, description) VALUES
(1, 1, '2024-07-01 10:00:00', 500000.00, 500000.00, 'Opening fixed-term deposit'),
(1, 3, '2024-10-01 00:00:00', 10000.00, 510000.00, 'Interest accrual for 3 months');

-- Operations for account 2 (John Smith's savings)
INSERT INTO operations (account_id, operation_type_id, operation_date, amount, balance_after, description) VALUES
(2, 1, '2024-06-15 11:00:00', 100000.00, 100000.00, 'Opening savings account'),
(2, 1, '2024-07-10 14:30:00', 50000.00, 150000.00, 'Account top-up'),
(2, 2, '2024-08-20 16:45:00', 20000.00, 130000.00, 'Withdrawal'),
(2, 1, '2024-09-15 09:20:00', 30000.00, 160000.00, 'Account top-up'),
(2, 3, '2024-10-01 00:00:00', 650.00, 160650.00, 'Monthly interest accrual');

-- Operations for account 3 (Emily Johnson's savings)
INSERT INTO operations (account_id, operation_type_id, operation_date, amount, balance_after, description) VALUES
(3, 1, '2024-08-01 10:30:00', 200000.00, 200000.00, 'Opening savings account'),
(3, 1, '2024-08-25 15:00:00', 100000.00, 300000.00, 'Large deposit'),
(3, 3, '2024-09-01 00:00:00', 800.00, 300800.00, 'August interest accrual'),
(3, 2, '2024-09-10 12:00:00', 50000.00, 250800.00, 'Partial withdrawal'),
(3, 3, '2024-10-01 00:00:00', 1100.00, 251900.00, 'September interest accrual');

-- Operations for account 4 (Emily Johnson's deposit)
INSERT INTO operations (account_id, operation_type_id, operation_date, amount, balance_after, description) VALUES
(4, 1, '2024-07-15 13:00:00', 750000.00, 750000.00, 'Opening 2-year fixed-term deposit'),
(4, 3, '2024-10-15 00:00:00', 15000.00, 765000.00, 'Quarterly interest accrual');

-- Operations for account 5 (Michael Williams' savings)
INSERT INTO operations (account_id, operation_type_id, operation_date, amount, balance_after, description) VALUES
(5, 1, '2024-03-10 11:00:00', 50000.00, 50000.00, 'Opening savings account'),
(5, 3, '2024-04-01 00:00:00', 200.00, 50200.00, 'Interest accrual'),
(5, 3, '2024-05-01 00:00:00', 210.00, 50410.00, 'Interest accrual'),
(5, 2, '2024-06-05 14:00:00', 10000.00, 40410.00, 'Withdrawal'),
(5, 3, '2024-07-01 00:00:00', 180.00, 40590.00, 'Interest accrual');

-- Operations for account 6 (Sarah Brown's deposit)
INSERT INTO operations (account_id, operation_type_id, operation_date, amount, balance_after, description) VALUES
(6, 1, '2024-04-20 10:00:00', 1000000.00, 1000000.00, 'Opening large deposit'),
(6, 3, '2024-07-20 00:00:00', 18750.00, 1018750.00, 'Quarterly interest accrual'),
(6, 3, '2024-10-20 00:00:00', 19100.00, 1037850.00, 'Quarterly interest accrual');

-- Operations for account 7 (Sarah Brown's closed deposit)
INSERT INTO operations (account_id, operation_type_id, operation_date, amount, balance_after, description) VALUES
(7, 1, '2024-01-15 10:00:00', 500000.00, 500000.00, 'Opening deposit'),
(7, 3, '2024-04-15 00:00:00', 8750.00, 508750.00, 'Interest accrual'),
(7, 2, '2024-07-15 15:00:00', 508750.00, 0.00, 'Closing deposit with payout');

-- Operations for account 8 (David Jones' EUR savings)
INSERT INTO operations (account_id, operation_type_id, operation_date, amount, balance_after, description) VALUES
(8, 1, '2024-09-01 10:00:00', 5000.00, 5000.00, 'Opening currency savings account'),
(8, 3, '2024-10-01 00:00:00', 22.92, 5022.92, 'Interest accrual in EUR');

-- ============================================
-- 5. 2025 operations to test blocking
-- ============================================

-- Deposit of client 1 (will exceed 1M per month)
INSERT INTO operations(account_id, operation_type_id, operation_date, amount, balance_after, description) VALUES
(1, 1, '2025-10-05 12:40', 600000, 1110000, 'Top-up before blocking'),
(1, 1, '2025-10-14 19:30', 500000, 1610000, 'Large top-up');

-- Savings of client 1 (also exceeds limit)
INSERT INTO operations(account_id, operation_type_id, operation_date, amount, balance_after, description) VALUES
(2, 1, '2025-10-03 09:10', 700000, 860650, 'Large volume top-up');

-- ============================================
-- Final statistics
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Test data successfully loaded!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Clients: 5';
    RAISE NOTICE 'Accounts: 8 (7 open, 1 closed)';
    RAISE NOTICE 'Rate history records: 5';
    RAISE NOTICE 'Operations: 27';
    RAISE NOTICE '========================================';
END $$;