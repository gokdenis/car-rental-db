/* =========================================================
   05_test_mssql.sql
   Environment: Microsoft SQL Server (T-SQL)
   Schema: s32736
   Database: 2019SBD

   Purpose:
     Test code demonstrating each procedure + trigger works (with comments),
     compatible with schema constraints discovered:
       - RENTAL.reservation_id NOT NULL
       - reservation_id UNIQUE in RENTAL (1 reservation -> 0..1 rental)

   Objects demonstrated:
     Procedures:
       - s32736.usp_close_rental   (includes CURSOR output via PRINT)
       - s32736.usp_add_payment
     Triggers:
       - s32736.trg_rental_car_status
       - s32736.trg_payment_no_overpay

   Project checklist mapping:
     - Procedures demonstrated: usp_close_rental, usp_add_payment
     - Triggers demonstrated: trg_rental_car_status, trg_payment_no_overpay
     - Cursor requirement: shown by PRINT output inside usp_close_rental
   ========================================================= */

USE [2019SBD];
GO

/* ---------------------------------------------------------
   A) Row counts
   Quick sanity check that DML loaded expected rows (>=5).
   All counts should be non-zero to confirm data presence.
   --------------------------------------------------------- */
SELECT 'CUSTOMER' AS t, COUNT(*) AS c
FROM [s32736].[CUSTOMER]
UNION ALL
SELECT 'CAR', COUNT(*)
FROM [s32736].[CAR]
UNION ALL
SELECT 'RESERVATION', COUNT(*)
FROM [s32736].[RESERVATION]
UNION ALL
SELECT 'RENTAL', COUNT(*)
FROM [s32736].[RENTAL]
UNION ALL
SELECT 'PAYMENT', COUNT(*)
FROM [s32736].[PAYMENT];
GO


/* ---------------------------------------------------------
   B) Ensure UNUSED reservation exists; create one if needed.
      (Must be unused because RENTAL.reservation_id is UNIQUE)

   -- We need an UNUSED reservation because RENTAL.reservation_id is UNIQUE,
      so only one RENTAL per RESERVATION allowed.

   -- The LEFT JOIN with RENTAL and WHERE x.reservation_id IS NULL finds reservations
      that have no associated rental yet (unused).

   -- If none found, create a new RESERVATION with safe future start/end dates
      to ensure test can proceed.

   -- The PRINT line confirms which UNUSED reservation_id is selected.
   --------------------------------------------------------- */
DECLARE @res_id INT, @car_id INT, @cust_id INT;

SELECT TOP 1 @res_id = r.reservation_id,
             @car_id = r.car_id,
             @cust_id = r.customer_id
FROM [s32736].[RESERVATION] r
         LEFT JOIN [s32736].[RENTAL] x ON x.reservation_id = r.reservation_id
WHERE x.reservation_id IS NULL
ORDER BY r.reservation_id;

IF @res_id IS NULL
    BEGIN
        PRINT 'No unused reservation found -> creating a new RESERVATION for test...';

        DECLARE @new_res_id INT;
        SELECT @new_res_id = ISNULL(MAX(reservation_id), 0) + 1 FROM [s32736].[RESERVATION];

        SELECT TOP 1 @car_id = car_id FROM [s32736].[CAR] ORDER BY car_id;
        SELECT TOP 1 @cust_id = customer_id FROM [s32736].[CUSTOMER] ORDER BY customer_id;

        INSERT INTO [s32736].[RESERVATION]
        (reservation_id, customer_id, car_id, status, start_date, end_date, created_at)
        VALUES (@new_res_id, @cust_id, @car_id, 'CREATED',
                DATEADD(day, 1, SYSDATETIME()),
                DATEADD(day, 3, SYSDATETIME()),
                SYSDATETIME());

        SET @res_id = @new_res_id;
    END

PRINT 'UNUSED reservation_id selected=' + CAST(@res_id AS NVARCHAR(20));
GO


/* ---------------------------------------------------------
   C) TRIGGER TEST #1: trg_rental_car_status (INSERT path)
      Insert RENTAL from UNUSED reservation.
      Expected: CAR.status becomes 'RENTED'

   -- Insert a RENTAL record to trigger trg_rental_car_status.

   -- Expected effect: CAR.status changes to 'RENTED' for the rented car.

   -- pickup_branch_id and return_branch_id set to 1 for simple deterministic test data.
   --------------------------------------------------------- */
DECLARE @res_id2 INT, @car_id2 INT, @cust_id2 INT;

SELECT TOP 1 @res_id2 = r.reservation_id,
             @car_id2 = r.car_id,
             @cust_id2 = r.customer_id
FROM [s32736].[RESERVATION] r
         LEFT JOIN [s32736].[RENTAL] x ON x.reservation_id = r.reservation_id
WHERE x.reservation_id IS NULL
ORDER BY r.reservation_id;

IF @res_id2 IS NULL
    THROW 60010, 'TEST STOP: No unused reservation exists.', 1;

DECLARE @new_rental_id INT;
SELECT @new_rental_id = ISNULL(MAX(rental_id), 0) + 1
FROM [s32736].[RENTAL];

DECLARE @start_milage INT;
SELECT @start_milage = milage
FROM [s32736].[CAR]
WHERE car_id = @car_id2;

PRINT 'Inserting RENTAL rental_id=' + CAST(@new_rental_id AS NVARCHAR(20))
    + ' from reservation_id=' + CAST(@res_id2 AS NVARCHAR(20));

INSERT INTO [s32736].[RENTAL]
(rental_id, reservation_id, customer_id, car_id, pickup_date, start_milage, pickup_branch_id, return_branch_id)
VALUES (@new_rental_id, @res_id2, @cust_id2, @car_id2, SYSDATETIME(), @start_milage, 1, 1);

SELECT c.car_id, c.status
FROM [s32736].[CAR] c
WHERE c.car_id = @car_id2;
GO


/* ---------------------------------------------------------
   D) PROCEDURE TEST #1: usp_close_rental (includes CURSOR output)
      Close the newest OPEN rental.
      Expected:
        - return_date/end_milage/total_amount updated
        - CAR.status becomes 'AVAILABLE'
        - procedure prints payment summary (cursor) via PRINT

   -- Select newest open rental (return_date IS NULL) for closing.

   -- Call usp_close_rental which sets return_date, end_milage, total_amount,
      and updates CAR.status to 'AVAILABLE'.

   -- The procedure also prints a payment summary using a cursor,
      fulfilling the cursor requirement.
   --------------------------------------------------------- */
DECLARE @rid INT, @car_id3 INT, @start_milage3 INT;

SELECT TOP 1 @rid = rental_id,
             @car_id3 = car_id,
             @start_milage3 = start_milage
FROM [s32736].[RENTAL]
WHERE return_date IS NULL
ORDER BY rental_id DESC;

IF @rid IS NULL
    BEGIN
        PRINT 'No open rental found -> skipping usp_close_rental test.';
    END
ELSE
    BEGIN
        PRINT 'Closing rental_id=' + CAST(@rid AS NVARCHAR(20));

        DECLARE @ret_date DATETIME2 = SYSDATETIME();
        DECLARE @end_milage INT = @start_milage3 + 120;

        EXEC [s32736].[usp_close_rental]
             @rental_id = @rid,
             @return_date = @ret_date,
             @end_milage = @end_milage;

        SELECT r.rental_id, r.return_date, r.end_milage, r.total_amount
        FROM [s32736].[RENTAL] r
        WHERE r.rental_id = @rid;

        SELECT c.car_id, c.status, c.milage
        FROM [s32736].[CAR] c
        WHERE c.car_id = @car_id3;
    END
GO


/* ---------------------------------------------------------
   E) PROCEDURE TEST #2: usp_add_payment (VALID payment)
      Choose a rental with due balance (paid_total < total_amount),
      pay a very small amount (1.000) to avoid overpayment.

   -- Pick a rental with outstanding balance (due).

   -- Call usp_add_payment with a small amount to avoid overpayment.

   -- Expected: new PAYMENT row inserted with status set by procedure and/or trigger.
   --------------------------------------------------------- */
DECLARE @rid_pay INT;

SELECT TOP 1 @rid_pay = r.rental_id
FROM [s32736].[RENTAL] r
WHERE r.total_amount IS NOT NULL
  AND (SELECT ISNULL(SUM(p.amount), 0)
       FROM [s32736].[PAYMENT] p
       WHERE p.rental_id = r.rental_id) < r.total_amount
ORDER BY r.rental_id DESC;

IF @rid_pay IS NULL
    BEGIN
        PRINT 'No rental with due balance found -> skipping VALID payment test.';
    END
ELSE
    BEGIN
        PRINT 'Adding VALID payment to rental_id=' + CAST(@rid_pay AS NVARCHAR(20));

        EXEC [s32736].[usp_add_payment]
             @rental_id = @rid_pay,
             @amount = 1.000,
             @payment_method = 'CARD';

        SELECT payment_id, amount, status, payment_date
        FROM [s32736].[PAYMENT]
        WHERE rental_id = @rid_pay
        ORDER BY payment_date, payment_id;
    END
GO


/* ---------------------------------------------------------
   F) TRIGGER TEST #2: trg_payment_no_overpay (NEGATIVE test)
      Attempt huge payment. Expected: trigger blocks and error is shown.
      (Robust: chooses a rental that has DUE balance; skips if none.)

   -- Negative test: attempt to add a huge payment amount.

   -- Expected: trigger blocks the insert and error is caught and printed.

   -- Proof query confirms the huge payment was not inserted.
   --------------------------------------------------------- */
DECLARE @rid_over INT;

SELECT TOP 1 @rid_over = r.rental_id
FROM [s32736].[RENTAL] r
WHERE r.total_amount IS NOT NULL
  AND (SELECT ISNULL(SUM(p.amount), 0)
       FROM [s32736].[PAYMENT] p
       WHERE p.rental_id = r.rental_id) < r.total_amount
ORDER BY r.rental_id DESC;

IF @rid_over IS NULL
    BEGIN
        PRINT 'No rental with DUE balance found -> skipping OVERPAY trigger test.';
    END
ELSE
    BEGIN
        PRINT 'Attempting OVERPAY on rental_id=' + CAST(@rid_over AS NVARCHAR(20));

        BEGIN TRY
            EXEC [s32736].[usp_add_payment]
                 @rental_id = @rid_over,
                 @amount = 999999.000,
                 @payment_method = 'CASH';

            PRINT 'ERROR: Overpay was NOT blocked (unexpected).';
        END TRY
        BEGIN CATCH
            PRINT 'Expected error (overpayment blocked): ' + ERROR_MESSAGE();
        END CATCH;

        SELECT payment_id, amount
        FROM [s32736].[PAYMENT]
        WHERE rental_id = @rid_over
        ORDER BY payment_id;
    END
GO
