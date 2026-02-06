/* =========================================================
   04_trg_oracle.sql
   Environment: Oracle Database (PL/SQL)
   Purpose: Triggers required by the project.
   Contains:
     - TRG_PAYMENT_NO_OVERPAY (FOR EACH ROW) prevents overpayment
     - TRG_RENTAL_CAR_STATUS keeps CAR.status in sync with RENTAL lifecycle

   Project checklist mapping:
     * Two triggers (Oracle): TRG_PAYMENT_NO_OVERPAY, TRG_RENTAL_CAR_STATUS
     * FOR EACH ROW requirement: satisfied by TRG_PAYMENT_NO_OVERPAY
     * Demonstrated by: 05_test_oracle.sql
   ========================================================= */

-- =========================================================
-- Trigger #1 (FOR EACH ROW)
-- Fires BEFORE INSERT or UPDATE on PAYMENT (specifically on columns amount, rental_id)
-- Enforces business rule: total payments for a rental cannot exceed rental.total_amount
-- If rule violated, raises application error with code and message
-- =========================================================
CREATE OR REPLACE TRIGGER trg_payment_no_overpay
    BEFORE INSERT OR UPDATE OF amount, rental_id
    ON payment
    FOR EACH ROW
DECLARE
    v_total_amount rental.total_amount%TYPE;
    v_paid_total   NUMBER(9, 3);
BEGIN
    SELECT total_amount
    INTO v_total_amount
    FROM rental
    WHERE rental_id = :NEW.rental_id
        FOR UPDATE;

    IF v_total_amount IS NULL THEN
        RAISE_APPLICATION_ERROR(-20101, 'Cannot add payment: rental.total_amount is NULL (close rental first).');
    END IF;

    SELECT NVL(SUM(amount), 0)
    INTO v_paid_total
    FROM payment
    WHERE rental_id = :NEW.rental_id
      AND (:NEW.payment_id IS NULL OR payment_id <> :NEW.payment_id);

    IF (v_paid_total + NVL(:NEW.amount, 0)) > v_total_amount THEN
        RAISE_APPLICATION_ERROR(-20102, 'Overpayment is not allowed: payments would exceed total_amount.');
    END IF;
END;
/

-- =========================================================
-- Trigger #2
-- Fires AFTER INSERT or UPDATE OF return_date on RENTAL
-- Keeps CAR.status consistent with RENTAL lifecycle
-- If return_date is NULL, car is RENTED; else AVAILABLE
-- This is a row-level trigger, handling each changed rental row
-- =========================================================
CREATE OR REPLACE TRIGGER trg_rental_car_status
    AFTER INSERT OR UPDATE OF return_date
    ON rental
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE car
        SET status = CASE WHEN :NEW.return_date IS NULL THEN 'RENTED' ELSE 'AVAILABLE' END
        WHERE car_id = :NEW.car_id;

    ELSIF UPDATING THEN
        UPDATE car
        SET status = CASE WHEN :NEW.return_date IS NULL THEN 'RENTED' ELSE 'AVAILABLE' END
        WHERE car_id = :NEW.car_id;
    END IF;
END;
/
