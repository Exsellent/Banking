-- Обновление структуры счетов для учета нового состояния 'заблокированный'

-- Ваш SQL код здесь

-- ============================================
-- Дополнительное задание
-- ============================================

-- 1. Поле updated_at
ALTER TABLE accounts
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- 2. Триггер обновления updated_at
CREATE OR REPLACE FUNCTION update_accounts_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_accounts_updated_at ON accounts;
CREATE TRIGGER trg_accounts_updated_at
    BEFORE UPDATE ON accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_accounts_timestamp();

-- 3. Таблица аудита
CREATE TABLE IF NOT EXISTS account_status_audit (
    audit_id BIGSERIAL PRIMARY KEY,
    account_id INTEGER NOT NULL,
    old_status_id INTEGER,
    new_status_id INTEGER NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reason TEXT,
    CONSTRAINT fk_audit_account FOREIGN KEY (account_id) REFERENCES accounts(account_id) ON DELETE RESTRICT
);

-- 4. Триггер аудита
CREATE OR REPLACE FUNCTION audit_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status_id IS DISTINCT FROM NEW.status_id THEN
        INSERT INTO account_status_audit(account_id, old_status_id, new_status_id, reason)
        VALUES (NEW.account_id, OLD.status_id, NEW.status_id, 'Изменение статуса');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_status ON accounts;
CREATE TRIGGER trg_audit_status
    AFTER UPDATE OF status_id ON accounts
    FOR EACH ROW
    EXECUTE FUNCTION audit_status_change();

-- 5. Функция блокировки
CREATE OR REPLACE FUNCTION block_account(p_account_id INTEGER, p_reason TEXT DEFAULT 'Превышение лимита')
RETURNS TEXT AS $$
DECLARE
    v_blocked_id INTEGER;
BEGIN
    SELECT status_id INTO v_blocked_id FROM account_statuses WHERE status_code = 'blocked';

    UPDATE accounts
    SET status_id = v_blocked_id
    WHERE account_id = p_account_id AND status_id != v_blocked_id;

    RETURN 'Счёт ' || p_account_id || ' заблокирован';
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    RAISE NOTICE 'Дополнительная структура готова!';
    RAISE NOTICE 'Данные за октябрь 2025 — в data.sql';
END $$;