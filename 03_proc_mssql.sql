/* =========================================================
   03_proc_mssql.sql
   Purpose:
     - Project-required stored procedures (MS SQL Server).
     - Demonstrates business logic + basic concurrency control + required CURSOR usage.
   Contains:
     - s32736.usp_close_rental (includes CURSOR usage to print payment summary)
     - s32736.usp_add_payment
   Notes / Assumptions (important for grading & maintenance):
     - Both procedures manage their own transaction:
         * BEGIN TRAN ... COMMIT on success
         * ROLLBACK on error (TRY/CATCH + XACT_ABORT)
       => Callers should not expect to control the transaction scope externally.
     - Locking hints (UPDLOCK, HOLDLOCK) are used to prevent concurrent close/payment races
       on the same RENTAL row during calculations and validations.
     - Monetary values use DECIMAL(9,3) and are not rounded explicitly; DECIMAL arithmetic preserves scale.
     - payment_id is generated as MAX(payment_id)+1 (simple approach; may conflict under high concurrency).
   ========================================================= */

USE [2019SBD];
GO

/* ---------------------------------------------------------
   Procedure: s32736.usp_close_rental
   What it does:
     - Closes an open rental by:
         1) Reading rental + car pricing (with locks)
         2) Validating input and rental state
         3) Computing:
              days = DATEDIFF(DAY, pickup_date, return_date) + 1
                    (pickup day counts as full day; same-day return => 1 day)
              driven_km = end_milage - start_milage
              extra_km_fee = 0.10 * (driven_km - 300) if driven_km > 300
                  (threshold applied once per rental based on total km, not per-day)
              total_amount = days * daily_rate + extra_km_fee
         4) Updating RENTAL(return_date, end_milage, total_amount)
         5) Updating CAR(milage=end_milage, status='AVAILABLE')
         6) Printing payment summary using a CURSOR (project requirement)
   Inputs:
     - @rental_id: rental identifier
     - @return_date: actual return date/time
     - @end_milage: odometer at return
   Outputs:
     - None (uses PRINT statements for informational output)
   Concurrency / Locking:
     - RENTAL row is read with UPDLOCK + HOLDLOCK:
         * prevents another session from closing the same rental concurrently
         * ensures validations are consistent until transaction completes
   Transaction behavior:
     - Data updates are committed BEFORE cursor printing:
       printing is informational/debug; data changes are already durable after COMMIT.
   --------------------------------------------------------- */

IF OBJECT_ID(N'[s32736].[usp_close_rental]', N'P') IS NOT NULL
    DROP PROCEDURE [s32736].[usp_close_rental];
GO

CREATE PROCEDURE [s32736].[usp_close_rental] @rental_id INT,
                                             @return_date DATETIME2,
                                             @end_milage INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE
            @car_id INT,
            @start_milage INT,
            @pickup_date DATETIME2,
            @existing_return_date DATETIME2,
            @daily_rate DECIMAL(9, 3),
            @days INT,
            @driven_km INT,
            @extra_km_fee DECIMAL(9, 3),
            @base_amount DECIMAL(9, 3),
            @total_amount DECIMAL(9, 3);


        SELECT @car_id = r.car_id,
               @start_milage = r.start_milage,
               @pickup_date = r.pickup_date,
               @existing_return_date = r.return_date,
               @daily_rate = c.daily_rate
        FROM [s32736].[RENTAL] r WITH (UPDLOCK, HOLDLOCK)
                 JOIN [s32736].[CAR] c ON c.car_id = r.car_id
        WHERE r.rental_id = @rental_id;

        IF @car_id IS NULL
            THROW 50001, 'Rental not found.', 1;

        IF @existing_return_date IS NOT NULL
            THROW 50004, 'Rental already closed.', 1;

        IF @end_milage < @start_milage
            THROW 50002, 'end_milage cannot be less than start_milage.', 1;

        IF @return_date < @pickup_date
            THROW 50003, 'return_date cannot be earlier than pickup_date.', 1;

        SET @days = DATEDIFF(DAY, @pickup_date, @return_date) + 1;
        IF @days < 1 SET @days = 1;

        SET @driven_km = @end_milage - @start_milage;

        SET @extra_km_fee =
                CASE
                    WHEN @driven_km > 300
                        THEN CAST((@driven_km - 300) AS DECIMAL(9, 3)) * CAST(0.10 AS DECIMAL(9, 3))
                    ELSE CAST(0 AS DECIMAL(9, 3))
                    END;

        SET @base_amount = CAST(@days AS DECIMAL(9, 3)) * @daily_rate;
        SET @total_amount = @base_amount + @extra_km_fee;

        UPDATE [s32736].[RENTAL]
        SET return_date  = @return_date,
            end_milage   = @end_milage,
            total_amount = @total_amount
        WHERE rental_id = @rental_id;

        UPDATE [s32736].[CAR]
        SET milage = @end_milage,
            status = 'AVAILABLE'
        WHERE car_id = @car_id;
        COMMIT;

        /* ---- CURSOR: payment summary ---- */
        DECLARE
            @pid INT,
            @pdate DATETIME2,
            @pamount DECIMAL(9, 3),
            @pstatus NVARCHAR(30),
            @paid_total DECIMAL(9, 3) = 0;

        PRINT '--- Payment summary for rental_id=' + CAST(@rental_id AS NVARCHAR(20)) + ' ---';
        PRINT 'Computed total_amount=' + CAST(@total_amount AS NVARCHAR(50)) +
              ', driven_km=' + CAST(@driven_km AS NVARCHAR(20)) +
              ', extra_km_fee=' + CAST(@extra_km_fee AS NVARCHAR(50));

        DECLARE pay_cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT payment_id, payment_date, amount, status
            FROM [s32736].[PAYMENT]
            WHERE rental_id = @rental_id
            ORDER BY payment_date, payment_id;

        OPEN pay_cur;
        FETCH NEXT FROM pay_cur INTO @pid, @pdate, @pamount, @pstatus;

        WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @paid_total = @paid_total + @pamount;
                PRINT 'Payment_id=' + CAST(@pid AS NVARCHAR(20)) +
                      ', date=' + CONVERT(NVARCHAR(30), @pdate, 126) +
                      ', amount=' + CAST(@pamount AS NVARCHAR(50)) +
                      ', status=' + @pstatus;

                FETCH NEXT FROM pay_cur INTO @pid, @pdate, @pamount, @pstatus;
            END

        CLOSE pay_cur;
        DEALLOCATE pay_cur;

        PRINT 'Paid total=' + CAST(@paid_total AS NVARCHAR(50));
        IF @paid_total >= @total_amount
            PRINT 'Result: FULLY PAID';
        ELSE
            PRINT 'Result: DUE=' + CAST((@total_amount - @paid_total) AS NVARCHAR(50));

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 51000, @msg, 1;
    END CATCH
END;
GO

/* ---------------------------------------------------------
   Procedure: s32736.usp_add_payment
   What it does:
     - Inserts a payment row for a given rental_id.
   Validations implemented here:
     - @amount must be > 0
     - rental must exist AND be closed (RENTAL.total_amount must be NOT NULL)
   Important scope note:
     - This procedure does not prevent overpayment (it does not compare paid_total + amount to total_amount).
       If overpayment must be blocked, that rule must be enforced elsewhere.
   Concurrency / Locking:
     - Reads RENTAL row with UPDLOCK + HOLDLOCK to avoid race conditions with close operation.
   ID generation assumption:
     - payment_id generated as MAX(payment_id)+1 (simple; may collide under concurrency).
   Status assumption:
     - Inserts status as constant 'PAID' and assumes it is valid per table constraints/domain.
   Outputs:
     - PRINTs payment totals and remaining due for quick verification.
   --------------------------------------------------------- */

IF OBJECT_ID(N'[s32736].[usp_add_payment]', N'P') IS NOT NULL
    DROP PROCEDURE [s32736].[usp_add_payment];
GO

CREATE PROCEDURE [s32736].[usp_add_payment] @rental_id INT,
                                            @amount DECIMAL(9, 3),
                                            @payment_method NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        IF @amount <= 0
            THROW 52001, 'Payment amount must be > 0.', 1;

        DECLARE @total_amount DECIMAL(9, 3);

        SELECT @total_amount = total_amount
        FROM [s32736].[RENTAL]
        WITH (UPDLOCK, HOLDLOCK)
        WHERE rental_id = @rental_id;

        IF @total_amount IS NULL
            THROW 52002, 'Rental not found or total_amount is NULL. Close rental first.', 1;

        DECLARE @next_payment_id INT =
                (SELECT ISNULL(MAX(payment_id), 0) + 1 FROM [s32736].[PAYMENT]);

        INSERT INTO [s32736].[PAYMENT] (payment_id, rental_id, payment_date, amount, payment_method, status)
        VALUES (@next_payment_id, @rental_id, SYSDATETIME(), @amount, @payment_method, 'PAID');

        DECLARE @paid_total DECIMAL(9, 3) =
            (SELECT ISNULL(SUM(amount), 0) FROM [s32736].[PAYMENT] WHERE rental_id = @rental_id);
        COMMIT;

        PRINT 'Payment inserted. rental_id=' + CAST(@rental_id AS NVARCHAR(20)) +
              ', paid_total=' + CAST(@paid_total AS NVARCHAR(50)) +
              ', total_amount=' + CAST(@total_amount AS NVARCHAR(50));

        IF @paid_total >= @total_amount
            PRINT 'Result: FULLY PAID';
        ELSE
            PRINT 'Result: DUE=' + CAST((@total_amount - @paid_total) AS NVARCHAR(50));

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 52000, @msg, 1;
    END CATCH
END;
GO