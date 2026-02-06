/* =========================================================
   04_trg_mssql.sql
   Environment: Microsoft SQL Server (T-SQL)
   Purpose: Triggers required by the project.
   Contains:
     - trg_payment_no_overpay prevents overpayment
     - trg_rental_car_status keeps CAR.status in sync with real RENTAL state
   Schema: s32736
   Database: 2019SBD

   Project checklist mapping:
     - Two triggers (MSSQL): trg_payment_no_overpay, trg_rental_car_status
     - Demonstrated by: 05_test_mssql.sql
   ========================================================= */

USE [2019SBD];
GO

-- =========================================================
-- Trigger #1
-- Prevent overpayment:
-- On INSERT/UPDATE of PAYMENT, ensure total paid <= RENTAL.total_amount
-- =========================================================

IF OBJECT_ID(N'[s32736].[trg_payment_no_overpay]', N'TR') IS NOT NULL
    DROP TRIGGER [s32736].[trg_payment_no_overpay];
GO

CREATE TRIGGER [s32736].[trg_payment_no_overpay]
    ON [s32736].[PAYMENT]
    AFTER INSERT, UPDATE
    AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
                        JOIN [s32736].[RENTAL] r ON r.rental_id = i.rental_id
               GROUP BY i.rental_id, r.total_amount
               HAVING r.total_amount IS NULL)
        BEGIN
            RAISERROR ('Cannot add payment: rental.total_amount is NULL (close rental first).', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

    IF EXISTS (SELECT 1
               FROM inserted i
                        JOIN [s32736].[RENTAL] r ON r.rental_id = i.rental_id
                        CROSS APPLY (SELECT ISNULL(SUM(p.amount), 0) AS paid_total
                                     FROM [s32736].[PAYMENT] p
                                     WHERE p.rental_id = i.rental_id) x
               WHERE x.paid_total > r.total_amount)
        BEGIN
            RAISERROR ('Overpayment is not allowed: payments exceed total_amount.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;
END;
GO


-- =========================================================
-- Trigger #2
-- Keep CAR.status in sync with real RENTAL state:
--   If a car has ANY open rental (return_date IS NULL) -> status = 'RENTED'
--   Otherwise -> status = 'AVAILABLE'
-- Handles INSERT/UPDATE/DELETE on RENTAL.
-- =========================================================

IF OBJECT_ID(N'[s32736].[trg_rental_car_status]', N'TR') IS NOT NULL
    DROP TRIGGER [s32736].[trg_rental_car_status];
GO

CREATE TRIGGER [s32736].[trg_rental_car_status]
    ON [s32736].[RENTAL]
    AFTER INSERT, UPDATE, DELETE
    AS
BEGIN
    SET NOCOUNT ON;
    ;

    WITH affected AS (SELECT car_id
                      FROM inserted
                      UNION
                      SELECT car_id
                      FROM deleted)
    UPDATE c
    SET c.status = CASE
                       WHEN EXISTS (SELECT 1
                                    FROM [s32736].[RENTAL] r
                                    WHERE r.car_id = c.car_id
                                      AND r.return_date IS NULL) THEN 'RENTED'
                       ELSE 'AVAILABLE'
        END
    FROM [s32736].[CAR] c
             JOIN (SELECT DISTINCT car_id FROM affected) a ON a.car_id = c.car_id;
END;
GO