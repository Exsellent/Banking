-- 

-- Ваш SQL код здесь

-- ============================================
-- Основное задание
-- ============================================

-- Удаление существующих таблиц (для повторного запуска скрипта)
DROP TABLE IF EXISTS operations CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS interest_rate_history CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS account_statuses CASCADE;
DROP TABLE IF EXISTS operation_types CASCADE;
DROP TABLE IF EXISTS product_types CASCADE;

-- ============================================
-- 1. СПРАВОЧНИК: Типы банковских продуктов
-- ============================================
CREATE TABLE product_types (
    product_type_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_deposit BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_product_types_name UNIQUE (name)
);

COMMENT ON TABLE product_types IS 'Справочник типов банковских продуктов (вклады, накопительные счета)';
COMMENT ON COLUMN product_types.product_type_id IS 'Уникальный идентификатор типа продукта';
COMMENT ON COLUMN product_types.name IS 'Название типа продукта';
COMMENT ON COLUMN product_types.is_deposit IS 'TRUE - вклад с фиксированным сроком, FALSE - накопительный счёт';

-- ============================================
-- 2. СПРАВОЧНИК: Статусы счетов
-- ============================================
CREATE TABLE account_statuses (
    status_id SERIAL PRIMARY KEY,
    status_code VARCHAR(20) NOT NULL,
    status_name VARCHAR(50) NOT NULL,
    description TEXT,

    CONSTRAINT uq_account_statuses_code UNIQUE (status_code)
);

COMMENT ON TABLE account_statuses IS 'Справочник статусов банковских счетов';
COMMENT ON COLUMN account_statuses.status_code IS 'Код статуса для программной обработки (open, closed, blocked)';
COMMENT ON COLUMN account_statuses.status_name IS 'Человекочитаемое название статуса';

-- ============================================
-- 3. СПРАВОЧНИК: Типы операций
-- ============================================
CREATE TABLE operation_types (
    operation_type_id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,

    CONSTRAINT uq_operation_types_code UNIQUE (code)
);

COMMENT ON TABLE operation_types IS 'Справочник типов операций по счетам';
COMMENT ON COLUMN operation_types.code IS 'Код типа операции (deposit, withdraw, interest_accrual)';
COMMENT ON COLUMN operation_types.name IS 'Название типа операции';

-- ============================================
-- 4. Клиенты банка
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

COMMENT ON TABLE clients IS 'Клиенты банка - физические лица';
COMMENT ON COLUMN clients.client_id IS 'Уникальный идентификатор клиента';
COMMENT ON COLUMN clients.passport_series IS 'Серия паспорта';
COMMENT ON COLUMN clients.passport_number IS 'Номер паспорта';
COMMENT ON COLUMN clients.registration_date IS 'Дата регистрации в системе банка';

-- ============================================
-- 5. История процентных ставок
-- ============================================
CREATE TABLE interest_rate_history (
    rate_history_id SERIAL PRIMARY KEY,
    product_type_id INTEGER NOT NULL,
    rate_percent NUMERIC(5,2) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_irh_product_type FOREIGN KEY (product_type_id)
        REFERENCES product_types(product_type_id) ON DELETE RESTRICT,
    CONSTRAINT chk_irh_rate_range CHECK (rate_percent >= 0 AND rate_percent <= 100),
    CONSTRAINT chk_irh_dates CHECK (effective_to IS NULL OR effective_to > effective_from)
);

COMMENT ON TABLE interest_rate_history IS 'История изменений процентных ставок по типам продуктов';
COMMENT ON COLUMN interest_rate_history.rate_percent IS 'Процентная ставка годовых';
COMMENT ON COLUMN interest_rate_history.effective_from IS 'Дата начала действия ставки';
COMMENT ON COLUMN interest_rate_history.effective_to IS 'Дата окончания действия ставки (NULL для текущей)';

-- ============================================
-- 6. Банковские счета
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

    CONSTRAINT fk_accounts_client FOREIGN KEY (client_id)
        REFERENCES clients(client_id) ON DELETE RESTRICT,
    CONSTRAINT fk_accounts_product_type FOREIGN KEY (product_type_id)
        REFERENCES product_types(product_type_id) ON DELETE RESTRICT,
    CONSTRAINT fk_accounts_status FOREIGN KEY (status_id)
        REFERENCES account_statuses(status_id) ON DELETE RESTRICT,
    CONSTRAINT fk_accounts_initial_rate FOREIGN KEY (initial_rate_id)
        REFERENCES interest_rate_history(rate_history_id) ON DELETE RESTRICT,
    CONSTRAINT uq_accounts_number UNIQUE (account_number),
    CONSTRAINT chk_accounts_balance CHECK (current_balance >= 0),
    CONSTRAINT chk_accounts_currency CHECK (currency IN ('RUB', 'USD', 'EUR')),
    CONSTRAINT chk_accounts_rate CHECK (current_rate >= 0 AND current_rate <= 100),
    CONSTRAINT chk_accounts_dates CHECK (closed_date IS NULL OR closed_date >= opened_date),
    CONSTRAINT chk_accounts_term CHECK (deposit_term_months IS NULL OR deposit_term_months > 0)
);

COMMENT ON TABLE accounts IS 'Банковские счета клиентов (вклады и накопительные счета)';
COMMENT ON COLUMN accounts.account_id IS 'Уникальный идентификатор счёта';
COMMENT ON COLUMN accounts.account_number IS 'Уникальный номер счёта';
COMMENT ON COLUMN accounts.current_balance IS 'Текущий баланс счёта (денормализация для производительности)';
COMMENT ON COLUMN accounts.current_rate IS 'Текущая процентная ставка по счёту';
COMMENT ON COLUMN accounts.initial_rate_id IS 'Ссылка на ставку, действовавшую при открытии счёта';
COMMENT ON COLUMN accounts.deposit_term_months IS 'Срок вклада в месяцах (NULL для накопительных счетов)';

-- ============================================
-- 7. Операции по счетам
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

    CONSTRAINT fk_operations_account FOREIGN KEY (account_id)
        REFERENCES accounts(account_id) ON DELETE RESTRICT,
    CONSTRAINT fk_operations_type FOREIGN KEY (operation_type_id)
        REFERENCES operation_types(operation_type_id) ON DELETE RESTRICT,
    CONSTRAINT chk_operations_amount CHECK (amount > 0),
    CONSTRAINT chk_operations_balance CHECK (balance_after >= 0)
);

COMMENT ON TABLE operations IS 'Операции по банковским счетам (неизменяемая таблица, только INSERT)';
COMMENT ON COLUMN operations.operation_id IS 'Уникальный идентификатор операции';
COMMENT ON COLUMN operations.operation_date IS 'Дата и время выполнения операции';
COMMENT ON COLUMN operations.amount IS 'Сумма операции';
COMMENT ON COLUMN operations.balance_after IS 'Баланс счёта после выполнения операции (для аудита)';

-- ============================================
-- ИНДЕКСЫ для производительности
-- ============================================

-- Индексы для clients
CREATE INDEX idx_clients_passport ON clients(passport_series, passport_number);
CREATE INDEX idx_clients_phone ON clients(phone);
CREATE INDEX idx_clients_email ON clients(email) WHERE email IS NOT NULL;
CREATE INDEX idx_clients_registration_date ON clients(registration_date);

-- Индексы для interest_rate_history
CREATE INDEX idx_irh_product_type_id ON interest_rate_history(product_type_id);
CREATE INDEX idx_irh_effective_from ON interest_rate_history(effective_from);
CREATE INDEX idx_irh_product_dates ON interest_rate_history(product_type_id, effective_from, effective_to);

-- Индексы для accounts (критически важные для производительности)
CREATE INDEX idx_accounts_client_id ON accounts(client_id);
CREATE INDEX idx_accounts_product_type_id ON accounts(product_type_id);
CREATE INDEX idx_accounts_status_id ON accounts(status_id);
CREATE INDEX idx_accounts_opened_date ON accounts(opened_date);
CREATE INDEX idx_accounts_client_status ON accounts(client_id, status_id);
CREATE INDEX idx_accounts_status_product ON accounts(status_id, product_type_id);

-- Индексы для operations (самая нагруженная таблица)
CREATE INDEX idx_operations_account_id ON operations(account_id);
CREATE INDEX idx_operations_type_id ON operations(operation_type_id);
CREATE INDEX idx_operations_date ON operations(operation_date);
CREATE INDEX idx_operations_account_date ON operations(account_id, operation_date DESC);
CREATE INDEX idx_operations_date_range ON operations(operation_date DESC);
CREATE INDEX idx_operations_account_type ON operations(account_id, operation_type_id);

-- ============================================
-- ТРИГГЕРЫ для автоматического обновления
-- ============================================

-- Триггер для обновления updated_at в accounts
CREATE OR REPLACE FUNCTION update_accounts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_accounts_updated_at
    BEFORE UPDATE ON accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_accounts_updated_at();

COMMENT ON FUNCTION update_accounts_updated_at() IS 'Автоматическое обновление поля updated_at при изменении записи';

-- Триггер для обновления баланса счёта при операции
CREATE OR REPLACE FUNCTION update_account_balance()
RETURNS TRIGGER AS $$
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
    FOR EACH ROW
    EXECUTE FUNCTION update_account_balance();

COMMENT ON FUNCTION update_account_balance() IS 'Автоматическое обновление баланса счёта после операции';

-- ============================================
-- ЗАПОЛНЕНИЕ СПРАВОЧНИКОВ базовыми данными
-- ============================================

-- Типы продуктов
INSERT INTO product_types (name, description, is_deposit) VALUES
    ('Срочный вклад', 'Вклад с фиксированным сроком и процентной ставкой', TRUE),
    ('Накопительный счёт', 'Счёт с возможностью пополнения и снятия средств', FALSE);

-- Статусы счетов
INSERT INTO account_statuses (status_code, status_name, description) VALUES
    ('open', 'Открыт', 'Счёт активен, доступны все операции'),
    ('closed', 'Закрыт', 'Счёт закрыт, операции недоступны'),
    ('blocked', 'Заблокирован', 'Счёт заблокирован, операции ограничены');

-- Типы операций
INSERT INTO operation_types (code, name, description) VALUES
    ('deposit', 'Пополнение', 'Внесение средств на счёт'),
    ('withdraw', 'Снятие', 'Снятие средств со счёта'),
    ('interest_accrual', 'Начисление процентов', 'Начисление процентов по вкладу или накопительному счёту');

-- ============================================
-- Информация о созданной структуре
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'База данных успешно создана!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Таблицы:';
    RAISE NOTICE '  - product_types (справочник типов продуктов)';
    RAISE NOTICE '  - account_statuses (справочник статусов счетов)';
    RAISE NOTICE '  - operation_types (справочник типов операций)';
    RAISE NOTICE '  - clients (клиенты банка)';
    RAISE NOTICE '  - interest_rate_history (история ставок)';
    RAISE NOTICE '  - accounts (банковские счета)';
    RAISE NOTICE '  - operations (операции по счетам)';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Индексы: 20 индексов для оптимизации запросов';
    RAISE NOTICE 'Триггеры: 2 триггера для автоматического обновления';
    RAISE NOTICE 'Справочники: Предварительно заполнены базовыми данными';
    RAISE NOTICE '========================================';
END $$;