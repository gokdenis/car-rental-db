BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE PAYMENT CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE RENTAL CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE RESERVATION CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE MAINTENANCE CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CAR CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CAR_TYPE CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CAR_MODEL CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE BRANCH CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE NATIONAL_ID CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CUSTOMER CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE CUSTOMER
(
    customer_id               NUMBER(10)   NOT NULL,
    birth_date                DATE         NOT NULL,
    first_name                VARCHAR2(50) NOT NULL,
    last_name                 VARCHAR2(50) NOT NULL,
    phone                     VARCHAR2(20),
    email                     VARCHAR2(100),
    address                   VARCHAR2(100),
    driver_license_number     VARCHAR2(20) NOT NULL,
    driver_license_issue_date DATE         NOT NULL,
    CONSTRAINT PK_CUSTOMER PRIMARY KEY (customer_id),
    CONSTRAINT UQ_CUSTOMER_DL UNIQUE (driver_license_number)
);

CREATE TABLE NATIONAL_ID
(
    national_id_id  NUMBER(10)   NOT NULL,
    customer_id     NUMBER(10)   NOT NULL,
    national_id     NUMBER(15)   NOT NULL,
    issuing_country VARCHAR2(50) NOT NULL,
    issue_date      DATE         NOT NULL,
    expiry_date     DATE         NOT NULL,
    CONSTRAINT PK_NATIONAL_ID PRIMARY KEY (national_id_id),
    CONSTRAINT FK_NATIONAL_ID_CUSTOMER FOREIGN KEY (customer_id)
        REFERENCES CUSTOMER (customer_id),
    CONSTRAINT UQ_NATIONAL_ID_CUSTOMER UNIQUE (customer_id),
    CONSTRAINT CHK_NATIONAL_ID_DATES CHECK (issue_date < expiry_date)
);

CREATE TABLE BRANCH
(
    branch_id NUMBER(10)    NOT NULL,
    name      VARCHAR2(100) NOT NULL,
    address   VARCHAR2(100) NOT NULL,
    city      VARCHAR2(50)  NOT NULL,
    phone     VARCHAR2(50),
    email     VARCHAR2(100),
    CONSTRAINT PK_BRANCH PRIMARY KEY (branch_id)
);

CREATE TABLE CAR_MODEL
(
    car_model_id          NUMBER(10)   NOT NULL,
    brand_name            VARCHAR2(50) NOT NULL,
    model_name            VARCHAR2(50) NOT NULL,
    country               VARCHAR2(50),
    production_start_year NUMBER(4),
    production_end_year   NUMBER(4),
    CONSTRAINT PK_CAR_MODEL PRIMARY KEY (car_model_id),
    CONSTRAINT CHK_MODEL_YEARS CHECK (
        production_end_year IS NULL OR production_start_year IS NULL OR production_start_year <= production_end_year
        )
);

CREATE TABLE CAR_TYPE
(
    car_type_id  NUMBER(10)   NOT NULL,
    name         VARCHAR2(30) NOT NULL,
    fuel_type    VARCHAR2(30) NOT NULL,
    transmission VARCHAR2(30) NOT NULL,
    class        VARCHAR2(30) NOT NULL,
    CONSTRAINT PK_CAR_TYPE PRIMARY KEY (car_type_id)
);

CREATE TABLE CAR
(
    car_id       NUMBER(10)   NOT NULL,
    plate_number VARCHAR2(20) NOT NULL,
    year         NUMBER(4)    NOT NULL,
    color        VARCHAR2(30),
    milage       NUMBER(10)   NOT NULL,
    daily_rate   NUMBER(9, 3) NOT NULL,
    status       VARCHAR2(20) NOT NULL,
    car_type_id  NUMBER(10)   NOT NULL,
    car_model_id NUMBER(10)   NOT NULL,
    branch_id    NUMBER(10)   NOT NULL,
    CONSTRAINT PK_CAR PRIMARY KEY (car_id),
    CONSTRAINT UQ_CAR_PLATE UNIQUE (plate_number),
    CONSTRAINT FK_CAR_TYPE FOREIGN KEY (car_type_id) REFERENCES CAR_TYPE (car_type_id),
    CONSTRAINT FK_CAR_MODEL FOREIGN KEY (car_model_id) REFERENCES CAR_MODEL (car_model_id),
    CONSTRAINT FK_CAR_BRANCH FOREIGN KEY (branch_id) REFERENCES BRANCH (branch_id),
    CONSTRAINT CHK_CAR_VALUES CHECK (milage >= 0 AND daily_rate >= 0 AND year BETWEEN 1980 AND 2100),
    CONSTRAINT CHK_CAR_STATUS CHECK (status IN ('AVAILABLE', 'RESERVED', 'RENTED', 'MAINTENANCE', 'INACTIVE'))
);

CREATE TABLE RESERVATION
(
    reservation_id NUMBER(10)                     NOT NULL,
    customer_id    NUMBER(10)                     NOT NULL,
    car_id         NUMBER(10)                     NOT NULL,
    status         VARCHAR2(20)                   NOT NULL,
    start_date     TIMESTAMP                      NOT NULL,
    end_date       TIMESTAMP                      NOT NULL,
    created_at     TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT PK_RESERVATION PRIMARY KEY (reservation_id),
    CONSTRAINT FK_RES_CUST FOREIGN KEY (customer_id) REFERENCES CUSTOMER (customer_id),
    CONSTRAINT FK_RES_CAR FOREIGN KEY (car_id) REFERENCES CAR (car_id),
    CONSTRAINT CHK_RES_DATES CHECK (start_date < end_date),
    CONSTRAINT CHK_RES_STATUS CHECK (status IN ('CREATED', 'CONFIRMED', 'CANCELLED', 'COMPLETED'))
);

CREATE TABLE RENTAL
(
    rental_id        NUMBER(10) NOT NULL,
    reservation_id   NUMBER(10) NOT NULL,
    customer_id      NUMBER(10) NOT NULL,
    car_id           NUMBER(10) NOT NULL,
    pickup_date      TIMESTAMP  NOT NULL,
    return_date      TIMESTAMP,
    start_milage     NUMBER(10) NOT NULL,
    end_milage       NUMBER(10),
    total_amount     NUMBER(9, 3),
    pickup_branch_id NUMBER(10) NOT NULL,
    return_branch_id NUMBER(10) NOT NULL,
    CONSTRAINT PK_RENTAL PRIMARY KEY (rental_id),
    CONSTRAINT FK_RENTAL_RES FOREIGN KEY (reservation_id) REFERENCES RESERVATION (reservation_id),
    CONSTRAINT FK_RENTAL_CUST FOREIGN KEY (customer_id) REFERENCES CUSTOMER (customer_id),
    CONSTRAINT FK_RENTAL_CAR FOREIGN KEY (car_id) REFERENCES CAR (car_id),
    CONSTRAINT FK_RENTAL_PB FOREIGN KEY (pickup_branch_id) REFERENCES BRANCH (branch_id),
    CONSTRAINT FK_RENTAL_RB FOREIGN KEY (return_branch_id) REFERENCES BRANCH (branch_id),
    CONSTRAINT UQ_RENTAL_RES UNIQUE (reservation_id),
    CONSTRAINT CHK_RENTAL_VALUES CHECK (
        start_milage >= 0 AND
        (end_milage IS NULL OR end_milage >= start_milage) AND
        (return_date IS NULL OR return_date >= pickup_date) AND
        (total_amount IS NULL OR total_amount >= 0)
        )
);

CREATE TABLE PAYMENT
(
    payment_id     NUMBER(10)                     NOT NULL,
    rental_id      NUMBER(10)                     NOT NULL,
    payment_date   TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    amount         NUMBER(9, 3)                   NOT NULL,
    payment_method VARCHAR2(30)                   NOT NULL,
    status         VARCHAR2(30)                   NOT NULL,
    CONSTRAINT PK_PAYMENT PRIMARY KEY (payment_id),
    CONSTRAINT FK_PAYMENT_RENTAL FOREIGN KEY (rental_id) REFERENCES RENTAL (rental_id),
    CONSTRAINT CHK_PAYMENT_AMOUNT CHECK (amount > 0),
    CONSTRAINT CHK_PAYMENT_STATUS CHECK (status IN ('PENDING', 'PAID', 'FAILED', 'REFUNDED'))
);

CREATE TABLE MAINTENANCE
(
    maintenance_id        NUMBER(10)   NOT NULL,
    car_id                NUMBER(10)   NOT NULL,
    maintenance_date      DATE         NOT NULL,
    description           VARCHAR2(100),
    cost                  NUMBER(9, 3) NOT NULL,
    milage_at_maintenance NUMBER(10)   NOT NULL,
    CONSTRAINT PK_MAINTENANCE PRIMARY KEY (maintenance_id),
    CONSTRAINT FK_MAINT_CAR FOREIGN KEY (car_id) REFERENCES CAR (car_id),
    CONSTRAINT CHK_MAINT_VALUES CHECK (cost >= 0 AND milage_at_maintenance >= 0)
);
