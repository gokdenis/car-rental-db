USE [2019SBD];

IF NOT EXISTS (SELECT 1
               FROM sys.schemas
               WHERE name = 's32736')
    BEGIN
        EXEC ('CREATE SCHEMA [s32736]');
    END
GO

IF OBJECT_ID('[s32736].[PAYMENT]', 'U') IS NOT NULL DROP TABLE [s32736].[PAYMENT];
IF OBJECT_ID('[s32736].[RENTAL]', 'U') IS NOT NULL DROP TABLE [s32736].[RENTAL];
IF OBJECT_ID('[s32736].[RESERVATION]', 'U') IS NOT NULL DROP TABLE [s32736].[RESERVATION];
IF OBJECT_ID('[s32736].[MAINTENANCE]', 'U') IS NOT NULL DROP TABLE [s32736].[MAINTENANCE];
IF OBJECT_ID('[s32736].[CAR]', 'U') IS NOT NULL DROP TABLE [s32736].[CAR];
IF OBJECT_ID('[s32736].[CAR_TYPE]', 'U') IS NOT NULL DROP TABLE [s32736].[CAR_TYPE];
IF OBJECT_ID('[s32736].[CAR_MODEL]', 'U') IS NOT NULL DROP TABLE [s32736].[CAR_MODEL];
IF OBJECT_ID('[s32736].[BRANCH]', 'U') IS NOT NULL DROP TABLE [s32736].[BRANCH];
IF OBJECT_ID('[s32736].[NATIONAL_ID]', 'U') IS NOT NULL DROP TABLE [s32736].[NATIONAL_ID];
IF OBJECT_ID('[s32736].[CUSTOMER]', 'U') IS NOT NULL DROP TABLE [s32736].[CUSTOMER];
GO

CREATE TABLE [s32736].[CUSTOMER]
(
    customer_id               INT           NOT NULL,
    birth_date                DATE          NOT NULL,
    first_name                NVARCHAR(50)  NOT NULL,
    last_name                 NVARCHAR(50)  NOT NULL,
    phone                     NVARCHAR(20)  NULL,
    email                     NVARCHAR(100) NULL,
    address                   NVARCHAR(100) NULL,
    driver_license_number     NVARCHAR(20)  NOT NULL,
    driver_license_issue_date DATE          NOT NULL,
    CONSTRAINT PK_CUSTOMER PRIMARY KEY (customer_id),
    CONSTRAINT UQ_CUSTOMER_DL UNIQUE (driver_license_number)
);

CREATE TABLE [s32736].[NATIONAL_ID]
(
    national_id_id  INT          NOT NULL,
    customer_id     INT          NOT NULL,
    national_id     BIGINT       NOT NULL,
    issuing_country NVARCHAR(50) NOT NULL,
    issue_date      DATE         NOT NULL,
    expiry_date     DATE         NOT NULL,
    CONSTRAINT PK_NATIONAL_ID PRIMARY KEY (national_id_id),
    CONSTRAINT FK_NATIONAL_ID_CUSTOMER FOREIGN KEY (customer_id)
        REFERENCES [s32736].[CUSTOMER] (customer_id),
    CONSTRAINT UQ_NATIONAL_ID_CUSTOMER UNIQUE (customer_id),
    CONSTRAINT CHK_NATIONAL_ID_DATES CHECK (issue_date < expiry_date)
);

CREATE TABLE [s32736].[BRANCH]
(
    branch_id INT           NOT NULL,
    name      NVARCHAR(100) NOT NULL,
    address   NVARCHAR(100) NOT NULL,
    city      NVARCHAR(50)  NOT NULL,
    phone     NVARCHAR(50)  NULL,
    email     NVARCHAR(100) NULL,
    CONSTRAINT PK_BRANCH PRIMARY KEY (branch_id)
);

CREATE TABLE [s32736].[CAR_MODEL]
(
    car_model_id          INT          NOT NULL,
    brand_name            NVARCHAR(50) NOT NULL,
    model_name            NVARCHAR(50) NOT NULL,
    country               NVARCHAR(50) NULL,
    production_start_year SMALLINT     NULL,
    production_end_year   SMALLINT     NULL,
    CONSTRAINT PK_CAR_MODEL PRIMARY KEY (car_model_id),
    CONSTRAINT CHK_MODEL_YEARS CHECK (
        production_end_year IS NULL OR production_start_year IS NULL OR production_start_year <= production_end_year
        )
);

CREATE TABLE [s32736].[CAR_TYPE]
(
    car_type_id  INT          NOT NULL,
    name         NVARCHAR(30) NOT NULL,
    fuel_type    NVARCHAR(30) NOT NULL,
    transmission NVARCHAR(30) NOT NULL,
    [class]      NVARCHAR(30) NOT NULL,
    CONSTRAINT PK_CAR_TYPE PRIMARY KEY (car_type_id)
);

CREATE TABLE [s32736].[CAR]
(
    car_id       INT           NOT NULL,
    plate_number NVARCHAR(20)  NOT NULL,
    [year]       SMALLINT      NOT NULL,
    color        NVARCHAR(30)  NULL,
    milage       INT           NOT NULL,
    daily_rate   DECIMAL(9, 3) NOT NULL,
    status       NVARCHAR(20)  NOT NULL,
    car_type_id  INT           NOT NULL,
    car_model_id INT           NOT NULL,
    branch_id    INT           NOT NULL,
    CONSTRAINT PK_CAR PRIMARY KEY (car_id),
    CONSTRAINT UQ_CAR_PLATE UNIQUE (plate_number),
    CONSTRAINT FK_CAR_TYPE FOREIGN KEY (car_type_id) REFERENCES [s32736].[CAR_TYPE] (car_type_id),
    CONSTRAINT FK_CAR_MODEL FOREIGN KEY (car_model_id) REFERENCES [s32736].[CAR_MODEL] (car_model_id),
    CONSTRAINT FK_CAR_BRANCH FOREIGN KEY (branch_id) REFERENCES [s32736].[BRANCH] (branch_id),
    CONSTRAINT CHK_CAR_VALUES CHECK (milage >= 0 AND daily_rate >= 0 AND [year] BETWEEN 1980 AND 2100),
    CONSTRAINT CHK_CAR_STATUS CHECK (status IN ('AVAILABLE', 'RESERVED', 'RENTED', 'MAINTENANCE', 'INACTIVE'))
);

CREATE TABLE [s32736].[RESERVATION]
(
    reservation_id INT          NOT NULL,
    customer_id    INT          NOT NULL,
    car_id         INT          NOT NULL,
    status         NVARCHAR(20) NOT NULL,
    start_date     DATETIME2    NOT NULL,
    end_date       DATETIME2    NOT NULL,
    created_at     DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_RESERVATION PRIMARY KEY (reservation_id),
    CONSTRAINT FK_RES_CUST FOREIGN KEY (customer_id) REFERENCES [s32736].[CUSTOMER] (customer_id),
    CONSTRAINT FK_RES_CAR FOREIGN KEY (car_id) REFERENCES [s32736].[CAR] (car_id),
    CONSTRAINT CHK_RES_DATES CHECK (start_date < end_date),
    CONSTRAINT CHK_RES_STATUS CHECK (status IN ('CREATED', 'CONFIRMED', 'CANCELLED', 'COMPLETED'))
);

CREATE TABLE [s32736].[RENTAL]
(
    rental_id        INT           NOT NULL,
    reservation_id   INT           NOT NULL,
    customer_id      INT           NOT NULL,
    car_id           INT           NOT NULL,
    pickup_date      DATETIME2     NOT NULL,
    return_date      DATETIME2     NULL,
    start_milage     INT           NOT NULL,
    end_milage       INT           NULL,
    total_amount     DECIMAL(9, 3) NULL,
    pickup_branch_id INT           NOT NULL,
    return_branch_id INT           NOT NULL,
    CONSTRAINT PK_RENTAL PRIMARY KEY (rental_id),
    CONSTRAINT FK_RENTAL_RES FOREIGN KEY (reservation_id) REFERENCES [s32736].[RESERVATION] (reservation_id),
    CONSTRAINT FK_RENTAL_CUST FOREIGN KEY (customer_id) REFERENCES [s32736].[CUSTOMER] (customer_id),
    CONSTRAINT FK_RENTAL_CAR FOREIGN KEY (car_id) REFERENCES [s32736].[CAR] (car_id),
    CONSTRAINT FK_RENTAL_PB FOREIGN KEY (pickup_branch_id) REFERENCES [s32736].[BRANCH] (branch_id),
    CONSTRAINT FK_RENTAL_RB FOREIGN KEY (return_branch_id) REFERENCES [s32736].[BRANCH] (branch_id),
    CONSTRAINT UQ_RENTAL_RES UNIQUE (reservation_id),
    CONSTRAINT CHK_RENTAL_VALUES CHECK (
        start_milage >= 0 AND
        (end_milage IS NULL OR end_milage >= start_milage) AND
        (return_date IS NULL OR return_date >= pickup_date) AND
        (total_amount IS NULL OR total_amount >= 0)
        )
);

CREATE TABLE [s32736].[PAYMENT]
(
    payment_id     INT           NOT NULL,
    rental_id      INT           NOT NULL,
    payment_date   DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    amount         DECIMAL(9, 3) NOT NULL,
    payment_method NVARCHAR(30)  NOT NULL,
    status         NVARCHAR(30)  NOT NULL,
    CONSTRAINT PK_PAYMENT PRIMARY KEY (payment_id),
    CONSTRAINT FK_PAYMENT_RENTAL FOREIGN KEY (rental_id) REFERENCES [s32736].[RENTAL] (rental_id),
    CONSTRAINT CHK_PAYMENT_AMOUNT CHECK (amount > 0),
    CONSTRAINT CHK_PAYMENT_STATUS CHECK (status IN ('PENDING', 'PAID', 'FAILED', 'REFUNDED'))
);

CREATE TABLE [s32736].[MAINTENANCE]
(
    maintenance_id        INT           NOT NULL,
    car_id                INT           NOT NULL,
    maintenance_date      DATE          NOT NULL,
    description           NVARCHAR(100) NULL,
    cost                  DECIMAL(9, 3) NOT NULL,
    milage_at_maintenance INT           NOT NULL,
    CONSTRAINT PK_MAINTENANCE PRIMARY KEY (maintenance_id),
    CONSTRAINT FK_MAINT_CAR FOREIGN KEY (car_id) REFERENCES [s32736].[CAR] (car_id),
    CONSTRAINT CHK_MAINT_VALUES CHECK (cost >= 0 AND milage_at_maintenance >= 0)
);

CREATE INDEX IX_NATIONAL_ID_CUSTOMER ON [s32736].[NATIONAL_ID] (customer_id);
CREATE INDEX IX_CAR_TYPE_ID ON [s32736].[CAR] (car_type_id);
CREATE INDEX IX_CAR_MODEL_ID ON [s32736].[CAR] (car_model_id);
CREATE INDEX IX_CAR_BRANCH_ID ON [s32736].[CAR] (branch_id);
CREATE INDEX IX_RES_CUST ON [s32736].[RESERVATION] (customer_id);
CREATE INDEX IX_RES_CAR ON [s32736].[RESERVATION] (car_id);
CREATE INDEX IX_RENTAL_RES ON [s32736].[RENTAL] (reservation_id);
CREATE INDEX IX_RENTAL_CUST ON [s32736].[RENTAL] (customer_id);
CREATE INDEX IX_RENTAL_CAR ON [s32736].[RENTAL] (car_id);
CREATE INDEX IX_PAY_RENTAL ON [s32736].[PAYMENT] (rental_id);
CREATE INDEX IX_MAINT_CAR ON [s32736].[MAINTENANCE] (car_id);
GO