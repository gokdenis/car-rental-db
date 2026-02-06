/* =========================================================
   03_proc_oracle.sql
   Purpose:
     - Project-required 2 stored procedures.
     - CLOSE_RENTAL includes explicit CURSOR usage (project requirement).
     - Procedures implement: rental closing (cost calc + car availability) and payment insertion.
   Notes / Assumptions:
     - Both procedures COMMIT on success and ROLLBACK on error.
       This is an important side-effect for callers.
     - Monetary rounding uses 3 decimals consistently (NUMBER(9,3) and ROUND(...,3)).
   Objects created:
     - Procedure CLOSE_RENTAL
     - Procedure ADD_PAYMENT
   ========================================================= */


/* ---------------------------------------------------------
   Procedure: CLOSE_RENTAL
   What it does:
     - Closes an open rental:
         1) validates return info
         2) calculates rental cost:
              * days = TRUNC(return_date - pickup_date) + 1  (pickup day counts as a full day)
              * base = days * daily_rate
              * extra km fee = 0.10 per km above 300 km (threshold applied to total driven km, not per-day)
         3) updates RENTAL with return_date, end_milage, total_amount
         4) updates CAR status to 'AVAILABLE' and sets milage to returned odometer
         5) prints payment list + totals via DBMS_OUTPUT for verification/debug
   Inputs:
     - p_rental_id: ID of the rental to close
     - p_return_date: actual return date/time
     - p_end_milage: odometer reading at return
   Outputs:
     - None (informational output via DBMS_OUTPUT only)
   Side effects:
     - Updates rows in RENTAL and CAR
     - Reads PAYMENT rows and prints summary (no payment row is modified here)
     - COMMIT on success; ROLLBACK on error
   Locking / concurrency:
     - SELECT ... FOR UPDATE locks the RENTAL row to prevent concurrent close/update on same rental
       while calculations and updates are performed.
   --------------------------------------------------------- */

CREATE OR REPLACE PROCEDURE close_rental(
    p_rental_id IN NUMBER,
    p_return_date IN TIMESTAMP,
    p_end_milage IN NUMBER
) IS
    v_car_id          NUMBER;
    v_start_milage    NUMBER;
    v_pickup_date     TIMESTAMP;
    v_existing_return TIMESTAMP;
    v_daily_rate      NUMBER(9, 3);
    v_days            NUMBER;
    v_driven_km       NUMBER;
    v_extra_km_fee    NUMBER(9, 3);
    v_base_amount     NUMBER(9, 3);
    v_total_amount    NUMBER(9, 3);
    v_paid_total      NUMBER(9, 3) := 0;
    CURSOR c_payments IS
        SELECT payment_id, payment_date, amount, status
        FROM payment
        WHERE rental_id = p_rental_id
        ORDER BY payment_date, payment_id;
    v_pid             payment.payment_id%TYPE;
    v_pdate           payment.payment_date%TYPE;
    v_amt             payment.amount%TYPE;
    v_stat            payment.status%TYPE;
BEGIN
    SELECT r.car_id,
           r.start_milage,
           r.pickup_date,
           r.return_date,
           c.daily_rate
    INTO v_car_id,
        v_start_milage,
        v_pickup_date,
        v_existing_return,
        v_daily_rate
    FROM rental r
             JOIN car c ON c.car_id = r.car_id
    WHERE r.rental_id = p_rental_id
        FOR UPDATE;

    IF v_existing_return IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20004, 'Rental already closed');
    END IF;

    IF p_end_milage < v_start_milage THEN
        RAISE_APPLICATION_ERROR(-20001, 'end_milage cannot be less than start_milage');
    END IF;

    IF p_return_date < v_pickup_date THEN
        RAISE_APPLICATION_ERROR(-20002, 'return_date cannot be earlier than pickup_date');
    END IF;

    v_days := TRUNC(CAST(p_return_date AS DATE) - CAST(v_pickup_date AS DATE)) + 1;
    v_days := GREATEST(1, v_days);

    v_driven_km := p_end_milage - v_start_milage;

    IF v_driven_km > 300 THEN
        v_extra_km_fee := ROUND((v_driven_km - 300) * 0.10, 3);
    ELSE
        v_extra_km_fee := 0;
    END IF;

    v_base_amount := ROUND(v_days * v_daily_rate, 3);
    v_total_amount := ROUND(v_base_amount + v_extra_km_fee, 3);

    UPDATE rental
    SET return_date  = p_return_date,
        end_milage   = p_end_milage,
        total_amount = v_total_amount
    WHERE rental_id = p_rental_id;

    UPDATE car
    SET milage = p_end_milage,
        status = 'AVAILABLE'
    WHERE car_id = v_car_id;

    -- CURSOR output section:
    DBMS_OUTPUT.PUT_LINE('--- Payment summary for rental_id=' || p_rental_id || ' ---');
    DBMS_OUTPUT.PUT_LINE('Computed total_amount=' || v_total_amount ||
                         ', driven_km=' || v_driven_km ||
                         ', extra_km_fee=' || v_extra_km_fee);

    OPEN c_payments;
    LOOP
        FETCH c_payments INTO v_pid, v_pdate, v_amt, v_stat;
        EXIT WHEN c_payments%NOTFOUND;

        v_paid_total := v_paid_total + v_amt;

        DBMS_OUTPUT.PUT_LINE('Payment_id=' || v_pid ||
                             ', date=' || TO_CHAR(v_pdate, 'YYYY-MM-DD HH24:MI:SS') ||
                             ', amount=' || v_amt ||
                             ', status=' || v_stat);
    END LOOP;
    CLOSE c_payments;

    DBMS_OUTPUT.PUT_LINE('Paid total=' || v_paid_total);
    IF v_paid_total >= v_total_amount THEN
        DBMS_OUTPUT.PUT_LINE('Result: FULLY PAID');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Result: DUE=' || (v_total_amount - v_paid_total));
    END IF;

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        IF c_payments%ISOPEN THEN CLOSE c_payments; END IF;
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'Rental not found');
    WHEN OTHERS THEN
        IF c_payments%ISOPEN THEN CLOSE c_payments; END IF;
        ROLLBACK;
        RAISE;
END;
/

/* ---------------------------------------------------------
   Procedure: ADD_PAYMENT
   What it does:
     - Adds a payment to a CLOSED rental.
     - Validates:
         * amount > 0
         * rental exists
         * rental is closed (rental.total_amount is NOT NULL)
         * no overpayment (sum(existing payments) + new amount <= total_amount)
     - Inserts new PAYMENT row and prints updated totals via DBMS_OUTPUT.
   Inputs:
     - p_rental_id: rental ID
     - p_amount: payment amount (> 0)
     - p_payment_method: method description
   Outputs:
     - Informational output via DBMS_OUTPUT only.
   Side effects:
     - Inserts into PAYMENT
     - COMMIT on success; ROLLBACK on error
   Locking / concurrency:
     - SELECT total_amount ... FOR UPDATE locks the RENTAL row so paid_total check and insert are consistent.
   Important implementation notes:
     - payment_id is generated as MAX(payment_id)+1.
     - payment.status is chosen by:
         1) taking MIN(status) from existing rows if any exist,
         2) else attempting to extract a default from a CHECK constraint,
         3) else fallback to 'COMPLETED'.
   --------------------------------------------------------- */

CREATE OR REPLACE PROCEDURE add_payment(
    p_rental_id IN NUMBER,
    p_amount IN NUMBER,
    p_payment_method IN VARCHAR2
) IS
    v_total_amount   rental.total_amount%TYPE;
    v_paid_total     NUMBER(9, 3);
    v_due            NUMBER(9, 3);
    v_new_payment_id NUMBER;
    v_payment_status payment.status%TYPE;
    v_chk_condition  VARCHAR2(4000);
BEGIN
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20101, 'Payment amount must be > 0');
    END IF;

    SELECT total_amount
    INTO v_total_amount
    FROM rental
    WHERE rental_id = p_rental_id
        FOR UPDATE;

    IF v_total_amount IS NULL THEN
        RAISE_APPLICATION_ERROR(-20102, 'Rental is not closed yet (total_amount is NULL). Close rental first.');
    END IF;

    SELECT NVL(SUM(amount), 0)
    INTO v_paid_total
    FROM payment
    WHERE rental_id = p_rental_id;

    IF v_paid_total + p_amount > v_total_amount THEN
        RAISE_APPLICATION_ERROR(-20103, 'Overpayment is not allowed: payments exceed total_amount.');
    END IF;

    SELECT NVL(MAX(payment_id), 0) + 1
    INTO v_new_payment_id
    FROM payment;

    SELECT MIN(status)
    INTO v_payment_status
    FROM payment
    WHERE status IS NOT NULL;

    IF v_payment_status IS NULL THEN
        BEGIN
            SELECT search_condition
            INTO v_chk_condition
            FROM user_constraints
            WHERE constraint_type = 'C'
              AND table_name = 'PAYMENT'
              AND UPPER(constraint_name) LIKE 'CHK%STATUS%'
              AND ROWNUM = 1;

            v_payment_status := REGEXP_SUBSTR(v_chk_condition, '''([^'']+)''', 1, 1, NULL, 1);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
    END IF;

    IF v_payment_status IS NULL THEN
        v_payment_status := 'COMPLETED';
    END IF;

    INSERT INTO payment (payment_id, rental_id, payment_date, amount, payment_method, status)
    VALUES (v_new_payment_id, p_rental_id, SYSTIMESTAMP, p_amount, p_payment_method, v_payment_status);

    v_paid_total := v_paid_total + p_amount;
    v_due := v_total_amount - v_paid_total;

    DBMS_OUTPUT.PUT_LINE('Payment added. payment_id=' || v_new_payment_id ||
                         ', rental_id=' || p_rental_id ||
                         ', amount=' || p_amount ||
                         ', method=' || p_payment_method ||
                         ', status=' || v_payment_status);

    DBMS_OUTPUT.PUT_LINE('Total_amount=' || v_total_amount ||
                         ', Paid_total=' || v_paid_total ||
                         ', Due=' || v_due);

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20104, 'Rental not found.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/