/* =========================================================
   05_test_oracle.sql
   Environment: Oracle (PL/SQL)
   Purpose:
     Test code that demonstrates how EACH procedure and trigger works
     (with comments), compatible with current schema constraints:
       - RENTAL.reservation_id NOT NULL
       - 1 reservation -> 0..1 rental (reservation_id UNIQUE in RENTAL)

   Objects demonstrated:
     Procedures:
       - CLOSE_RENTAL   (includes CURSOR output via DBMS_OUTPUT)
       - ADD_PAYMENT
     Triggers:
       - TRG_RENTAL_CAR_STATUS
       - TRG_PAYMENT_NO_OVERPAY (FOR EACH ROW)

   Project checklist mapping:
     * Procedures demonstrated: CLOSE_RENTAL, ADD_PAYMENT
     * Triggers demonstrated: TRG_RENTAL_CAR_STATUS, TRG_PAYMENT_NO_OVERPAY (FOR EACH ROW)
     * Cursor requirement: demonstrated by DBMS_OUTPUT printed inside CLOSE_RENTAL
   ========================================================= */

/* ---------------------------------------------------------
   A) Quick data presence proof
      -- Sanity check: show that DML loaded rows into each table (expect at least 5 per table)
   --------------------------------------------------------- */
BEGIN
    FOR x IN (
        SELECT 'CUSTOMER' t, COUNT(*) c
        FROM customer
        UNION ALL
        SELECT 'CAR', COUNT(*)
        FROM car
        UNION ALL
        SELECT 'RESERVATION', COUNT(*)
        FROM reservation
        UNION ALL
        SELECT 'RENTAL', COUNT(*)
        FROM rental
        UNION ALL
        SELECT 'PAYMENT', COUNT(*)
        FROM payment
        )
        LOOP
            DBMS_OUTPUT.PUT_LINE(x.t || ' rows=' || x.c);
        END LOOP;
END;
/

/* ---------------------------------------------------------
   B) Ensure there is an UNUSED reservation (not used in RENTAL yet).
      If none exists, create one.
      (Needed because reservation_id is UNIQUE in RENTAL.)
      -- We need a reservation_id that is not yet used in RENTAL, because reservation_id is UNIQUE in RENTAL.
      -- The LEFT JOIN + x.reservation_id IS NULL finds reservations not yet referenced in RENTAL.
      -- MAX(reservation_id)+1 is a classroom/demo approach and assumes no concurrent inserts (not production-safe).
   --------------------------------------------------------- */
DECLARE
    v_res_id     NUMBER;
    v_car_id     NUMBER;
    v_cust_id    NUMBER;
    v_new_res_id NUMBER;
BEGIN
    BEGIN
        SELECT reservation_id, car_id, customer_id
        INTO v_res_id, v_car_id, v_cust_id
        FROM (SELECT r.reservation_id, r.car_id, r.customer_id
              FROM reservation r
                       LEFT JOIN rental x ON x.reservation_id = r.reservation_id
              WHERE x.reservation_id IS NULL
              ORDER BY r.reservation_id DESC)
        WHERE ROWNUM = 1;

        DBMS_OUTPUT.PUT_LINE('Using UNUSED reservation_id=' || v_res_id);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No unused reservation found -> creating a new RESERVATION for test...');

            SELECT NVL(MAX(reservation_id), 0) + 1 INTO v_new_res_id FROM reservation;
            SELECT car_id INTO v_car_id FROM (SELECT car_id FROM car ORDER BY car_id) WHERE ROWNUM = 1;
            SELECT customer_id
            INTO v_cust_id
            FROM (SELECT customer_id FROM customer ORDER BY customer_id)
            WHERE ROWNUM = 1;

            INSERT INTO reservation
            (reservation_id, customer_id, car_id, status, start_date, end_date, created_at)
            VALUES (v_new_res_id, v_cust_id, v_car_id, 'CREATED',
                    SYSTIMESTAMP + INTERVAL '1' DAY,
                    SYSTIMESTAMP + INTERVAL '3' DAY,
                    SYSTIMESTAMP);

            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Created reservation_id=' || v_new_res_id);
    END;
END;
/

/* ---------------------------------------------------------
   C) TRIGGER TEST #1: TRG_RENTAL_CAR_STATUS (INSERT path)
      Insert a new RENTAL from an UNUSED reservation.
      Expected: car.status becomes 'RENTED'
      -- Inserting into RENTAL should fire TRG_RENTAL_CAR_STATUS trigger.
      -- The expected side effect is that CAR.status is updated to 'RENTED' for the car in this rental.
      -- pickup_branch_id and return_branch_id are set to 1 for deterministic/repeatable test data.
   --------------------------------------------------------- */
DECLARE
    v_res_id        NUMBER;
    v_car_id        NUMBER;
    v_cust_id       NUMBER;
    v_new_rental_id NUMBER;
    v_start_milage  NUMBER;
BEGIN
    BEGIN
        SELECT reservation_id, car_id, customer_id
        INTO v_res_id, v_car_id, v_cust_id
        FROM (SELECT r.reservation_id, r.car_id, r.customer_id
              FROM reservation r
                       LEFT JOIN rental x ON x.reservation_id = r.reservation_id
              WHERE x.reservation_id IS NULL
              ORDER BY r.reservation_id DESC)
        WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('TEST STOP: No unused reservation exists -> cannot create RENTAL.');
            RETURN;
    END;

    SELECT NVL(MAX(rental_id), 0) + 1 INTO v_new_rental_id FROM rental;
    SELECT milage INTO v_start_milage FROM car WHERE car_id = v_car_id;

    INSERT INTO rental
    (rental_id, reservation_id, customer_id, car_id,
     pickup_date, start_milage, pickup_branch_id, return_branch_id)
    VALUES (v_new_rental_id, v_res_id, v_cust_id, v_car_id,
            SYSTIMESTAMP, v_start_milage, 1, 1);

    DBMS_OUTPUT.PUT_LINE('Inserted rental_id=' || v_new_rental_id || ' using reservation_id=' || v_res_id);

    FOR c IN (SELECT status FROM car WHERE car_id = v_car_id)
        LOOP
            DBMS_OUTPUT.PUT_LINE('After INSERT trigger: car.status=' || c.status || ' (expected RENTED)');
        END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('C) Failed: ' || SQLERRM);
        ROLLBACK;
END;
/

/* ---------------------------------------------------------
   D) PROCEDURE TEST #1: CLOSE_RENTAL (includes CURSOR output)
      Close the most recent OPEN rental (return_date IS NULL).
      Expected:
        - total_amount computed
        - return_date/end_milage set
        - car.status becomes 'AVAILABLE'
        - cursor prints payment summary via DBMS_OUTPUT
      -- This selects the most recent rental where return_date IS NULL (an OPEN rental).
      -- CLOSE_RENTAL procedure computes total_amount, sets return_date and end_milage.
      -- Expected side effect: CAR.status becomes 'AVAILABLE'.
      -- The required cursor output is printed by CLOSE_RENTAL to DBMS_OUTPUT (project requirement).
   --------------------------------------------------------- */
DECLARE
    v_rental_id    NUMBER;
    v_start_milage NUMBER;
    v_car_id       NUMBER;
BEGIN
    BEGIN
        SELECT rental_id, start_milage, car_id
        INTO v_rental_id, v_start_milage, v_car_id
        FROM (SELECT rental_id, start_milage, car_id
              FROM rental
              WHERE return_date IS NULL
              ORDER BY rental_id DESC)
        WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No OPEN rental found -> skipping CLOSE_RENTAL test.');
            RETURN;
    END;

    DBMS_OUTPUT.PUT_LINE('Closing rental_id=' || v_rental_id);

    BEGIN
        close_rental(
                v_rental_id,
                SYSTIMESTAMP, -- return now
                v_start_milage + 120 -- end_milage >= start_milage
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('CLOSE_RENTAL failed: ' || SQLERRM);
            RETURN;
    END;

    FOR r IN (
        SELECT r.total_amount,
               r.return_date,
               r.end_milage,
               c.status AS car_status,
               c.milage AS car_milage
        FROM rental r
                 JOIN car c ON c.car_id = r.car_id
        WHERE r.rental_id = v_rental_id
        )
        LOOP
            DBMS_OUTPUT.PUT_LINE('After CLOSE_RENTAL: total_amount=' || r.total_amount ||
                                 ', car_status=' || r.car_status ||
                                 ', car_milage=' || r.car_milage ||
                                 ' (expected AVAILABLE)');
        END LOOP;
END;
/

/* ---------------------------------------------------------
   E) PROCEDURE TEST #2: ADD_PAYMENT (VALID payment)
      Pick a rental that still has DUE balance (paid_total < total_amount)
      and add a small payment.
      Expected: payment inserted + remaining due printed
      -- Selects a rental that still has an outstanding DUE balance (total_amount > paid_total).
      -- Calls ADD_PAYMENT with a small amount, which should be valid (no overpay).
      -- Expected: DBMS_OUTPUT shows payment added and updated totals/due.
   --------------------------------------------------------- */
DECLARE
    v_rental_id  NUMBER;
    v_total      NUMBER(9, 3);
    v_paid_total NUMBER(9, 3);
BEGIN
    BEGIN
        SELECT r.rental_id,
               r.total_amount,
               NVL((SELECT SUM(p.amount) FROM payment p WHERE p.rental_id = r.rental_id), 0)
        INTO v_rental_id, v_total, v_paid_total
        FROM rental r
        WHERE r.total_amount IS NOT NULL
          AND NVL((SELECT SUM(p.amount) FROM payment p WHERE p.rental_id = r.rental_id), 0) < r.total_amount
          AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No rental with DUE balance found -> skipping ADD_PAYMENT valid test.');
            RETURN;
    END;

    DBMS_OUTPUT.PUT_LINE('Adding VALID payment to rental_id=' || v_rental_id ||
                         ' total=' || v_total ||
                         ' paid=' || v_paid_total ||
                         ' due=' || (v_total - v_paid_total));

    BEGIN
        add_payment(v_rental_id, 1.000, 'CARD');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ADD_PAYMENT failed: ' || SQLERRM);
            RETURN;
    END;

    FOR p IN (
        SELECT payment_id, amount, status
        FROM payment
        WHERE rental_id = v_rental_id
        ORDER BY payment_id
        )
        LOOP
            DBMS_OUTPUT.PUT_LINE('Payment row: id=' || p.payment_id ||
                                 ', amount=' || p.amount ||
                                 ', status=' || p.status);
        END LOOP;
END;
/

/* ---------------------------------------------------------
   F) TRIGGER TEST #2: TRG_PAYMENT_NO_OVERPAY (NEGATIVE test)
      Attempt a huge payment on a rental with DUE balance.
      Expected: trigger blocks overpayment.
      -- Negative test for TRG_PAYMENT_NO_OVERPAY trigger.
      -- Attempts to overpay; expect trigger to raise ORA-20103 (or similar) and catch it as success.
   --------------------------------------------------------- */
DECLARE
    v_rental_id NUMBER;
BEGIN
    BEGIN
        SELECT r.rental_id
        INTO v_rental_id
        FROM rental r
        WHERE r.total_amount IS NOT NULL
          AND NVL((SELECT SUM(p.amount) FROM payment p WHERE p.rental_id = r.rental_id), 0) < r.total_amount
          AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No rental with DUE balance found -> skipping OVERPAY test.');
            RETURN;
    END;

    DBMS_OUTPUT.PUT_LINE('Attempting OVERPAY on rental_id=' || v_rental_id);

    BEGIN
        add_payment(v_rental_id, 999999.000, 'CASH');
        DBMS_OUTPUT.PUT_LINE('ERROR: Overpay was NOT blocked (unexpected).');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error (overpayment blocked): ' || SQLERRM);
    END;
END;
/
