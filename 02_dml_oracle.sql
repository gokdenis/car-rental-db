INSERT INTO CUSTOMER (customer_id, birth_date, first_name, last_name, phone, email, address, driver_license_number,
                      driver_license_issue_date)
VALUES (1, DATE '1998-03-12', 'Ahmet', 'Yilmaz', '+90 530 111 1111', 'ahmet.yilmaz@mail.com', 'Istanbul', 'DL-TR-1001',
        DATE '2018-06-10');
INSERT INTO CUSTOMER (customer_id, birth_date, first_name, last_name, phone, email, address, driver_license_number,
                      driver_license_issue_date)
VALUES (2, DATE '1997-09-25', 'Elif', 'Kaya', '+90 530 222 2222', 'elif.kaya@mail.com', 'Ankara', 'DL-TR-1002',
        DATE '2017-05-08');
INSERT INTO CUSTOMER (customer_id, birth_date, first_name, last_name, phone, email, address, driver_license_number,
                      driver_license_issue_date)
VALUES (3, DATE '1995-01-14', 'Mehmet', 'Demir', '+90 530 333 3333', 'mehmet.demir@mail.com', 'Izmir', 'DL-TR-1003',
        DATE '2016-04-18');
INSERT INTO CUSTOMER (customer_id, birth_date, first_name, last_name, phone, email, address, driver_license_number,
                      driver_license_issue_date)
VALUES (4, DATE '2000-11-02', 'Zeynep', 'Sari', '+90 530 444 4444', 'zeynep.sari@mail.com', 'Bursa', 'DL-TR-1004',
        DATE '2019-08-22');
INSERT INTO CUSTOMER (customer_id, birth_date, first_name, last_name, phone, email, address, driver_license_number,
                      driver_license_issue_date)
VALUES (5, DATE '1992-07-30', 'Can', 'Arslan', '+90 530 555 5555', 'can.arslan@mail.com', 'Antalya', 'DL-TR-1005',
        DATE '2014-03-15');

INSERT INTO NATIONAL_ID (national_id_id, customer_id, national_id, issuing_country, issue_date, expiry_date)
VALUES (1, 1, 11111111111, 'Turkey', DATE '2018-01-01', DATE '2028-01-01');
INSERT INTO NATIONAL_ID (national_id_id, customer_id, national_id, issuing_country, issue_date, expiry_date)
VALUES (2, 2, 22222222222, 'Turkey', DATE '2019-02-10', DATE '2029-02-10');
INSERT INTO NATIONAL_ID (national_id_id, customer_id, national_id, issuing_country, issue_date, expiry_date)
VALUES (3, 3, 33333333333, 'Turkey', DATE '2017-03-05', DATE '2027-03-05');
INSERT INTO NATIONAL_ID (national_id_id, customer_id, national_id, issuing_country, issue_date, expiry_date)
VALUES (4, 4, 44444444444, 'Turkey', DATE '2020-04-20', DATE '2030-04-20');
INSERT INTO NATIONAL_ID (national_id_id, customer_id, national_id, issuing_country, issue_date, expiry_date)
VALUES (5, 5, 55555555555, 'Turkey', DATE '2016-05-15', DATE '2026-05-15');

INSERT INTO BRANCH (branch_id, name, address, city, phone, email)
VALUES (1, 'Istanbul Center', 'Sisli', 'Istanbul', '+90 212 000 0001', 'istanbul@carrent.com');
INSERT INTO BRANCH (branch_id, name, address, city, phone, email)
VALUES (2, 'Ankara Center', 'Cankaya', 'Ankara', '+90 312 000 0002', 'ankara@carrent.com');
INSERT INTO BRANCH (branch_id, name, address, city, phone, email)
VALUES (3, 'Izmir Center', 'Konak', 'Izmir', '+90 232 000 0003', 'izmir@carrent.com');
INSERT INTO BRANCH (branch_id, name, address, city, phone, email)
VALUES (4, 'Bursa Center', 'Nilufer', 'Bursa', '+90 224 000 0004', 'bursa@carrent.com');
INSERT INTO BRANCH (branch_id, name, address, city, phone, email)
VALUES (5, 'Antalya Center', 'Muratpasa', 'Antalya', '+90 242 000 0005', 'antalya@carrent.com');

INSERT INTO CAR_TYPE (car_type_id, name, fuel_type, transmission, class)
VALUES (1, 'Sedan', 'Gasoline', 'Automatic', 'Economy');
INSERT INTO CAR_TYPE (car_type_id, name, fuel_type, transmission, class)
VALUES (2, 'SUV', 'Diesel', 'Automatic', 'Standard');
INSERT INTO CAR_TYPE (car_type_id, name, fuel_type, transmission, class)
VALUES (3, 'Hatchback', 'Gasoline', 'Manual', 'Economy');
INSERT INTO CAR_TYPE (car_type_id, name, fuel_type, transmission, class)
VALUES (4, 'Van', 'Diesel', 'Manual', 'Standard');
INSERT INTO CAR_TYPE (car_type_id, name, fuel_type, transmission, class)
VALUES (5, 'Luxury Sedan', 'Hybrid', 'Automatic', 'Luxury');

INSERT INTO CAR_MODEL (car_model_id, brand_name, model_name, country, production_start_year, production_end_year)
VALUES (1, 'Toyota', 'Corolla', 'Japan', 2013, NULL);
INSERT INTO CAR_MODEL (car_model_id, brand_name, model_name, country, production_start_year, production_end_year)
VALUES (2, 'Renault', 'Clio', 'France', 2012, NULL);
INSERT INTO CAR_MODEL (car_model_id, brand_name, model_name, country, production_start_year, production_end_year)
VALUES (3, 'Volkswagen', 'Golf', 'Germany', 2011, NULL);
INSERT INTO CAR_MODEL (car_model_id, brand_name, model_name, country, production_start_year, production_end_year)
VALUES (4, 'Ford', 'Transit', 'USA', 2010, NULL);
INSERT INTO CAR_MODEL (car_model_id, brand_name, model_name, country, production_start_year, production_end_year)
VALUES (5, 'BMW', '5 Series', 'Germany', 2015, NULL);

INSERT INTO CAR (car_id, plate_number, year, color, milage, daily_rate, status, car_type_id, car_model_id, branch_id)
VALUES (1, '34-ABC-001', 2020, 'White', 45000, 55.000, 'AVAILABLE', 1, 1, 1);
INSERT INTO CAR (car_id, plate_number, year, color, milage, daily_rate, status, car_type_id, car_model_id, branch_id)
VALUES (2, '06-DEF-002', 2019, 'Black', 60000, 65.000, 'AVAILABLE', 2, 3, 2);
INSERT INTO CAR (car_id, plate_number, year, color, milage, daily_rate, status, car_type_id, car_model_id, branch_id)
VALUES (3, '35-GHI-003', 2018, 'Blue', 70000, 50.000, 'AVAILABLE', 3, 2, 3);
INSERT INTO CAR (car_id, plate_number, year, color, milage, daily_rate, status, car_type_id, car_model_id, branch_id)
VALUES (4, '16-JKL-004', 2021, 'Gray', 30000, 90.000, 'AVAILABLE', 4, 4, 4);
INSERT INTO CAR (car_id, plate_number, year, color, milage, daily_rate, status, car_type_id, car_model_id, branch_id)
VALUES (5, '07-MNO-005', 2022, 'Silver', 20000, 150.000, 'AVAILABLE', 5, 5, 5);

INSERT INTO RESERVATION (reservation_id, customer_id, car_id, status, start_date, end_date, created_at)
VALUES (1, 1, 1, 'CONFIRMED',
        TO_TIMESTAMP('2025-01-10 09:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2025-01-13 09:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        SYSTIMESTAMP);
INSERT INTO RESERVATION (reservation_id, customer_id, car_id, status, start_date, end_date, created_at)
VALUES (2, 2, 2, 'CONFIRMED',
        TO_TIMESTAMP('2025-01-12 10:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2025-01-14 10:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        SYSTIMESTAMP);
INSERT INTO RESERVATION (reservation_id, customer_id, car_id, status, start_date, end_date, created_at)
VALUES (3, 3, 3, 'CREATED',
        TO_TIMESTAMP('2025-01-15 08:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2025-01-16 08:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        SYSTIMESTAMP);
INSERT INTO RESERVATION (reservation_id, customer_id, car_id, status, start_date, end_date, created_at)
VALUES (4, 4, 4, 'CONFIRMED',
        TO_TIMESTAMP('2025-01-18 12:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2025-01-20 12:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        SYSTIMESTAMP);
INSERT INTO RESERVATION (reservation_id, customer_id, car_id, status, start_date, end_date, created_at)
VALUES (5, 5, 5, 'CONFIRMED',
        TO_TIMESTAMP('2025-01-21 09:30:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2025-01-22 09:30:00', 'YYYY-MM-DD HH24:MI:SS'),
        SYSTIMESTAMP);

INSERT INTO RENTAL (rental_id, reservation_id, customer_id, car_id, pickup_date, return_date, start_milage, end_milage,
                    total_amount, pickup_branch_id, return_branch_id)
VALUES (1, 1, 1, 1,
        TO_TIMESTAMP('2025-01-10 09:10:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2025-01-13 09:05:00', 'YYYY-MM-DD HH24:MI:SS'),
        45000, 45550, 165.000, 1, 1);
INSERT INTO RENTAL (rental_id, reservation_id, customer_id, car_id, pickup_date, return_date, start_milage, end_milage,
                    total_amount, pickup_branch_id, return_branch_id)
VALUES (2, 2, 2, 2,
        TO_TIMESTAMP('2025-01-12 10:05:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2025-01-14 10:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        60000, 60620, 130.000, 2, 2);
INSERT INTO RENTAL (rental_id, reservation_id, customer_id, car_id, pickup_date, return_date, start_milage, end_milage,
                    total_amount, pickup_branch_id, return_branch_id)
VALUES (3, 3, 3, 3,
        TO_TIMESTAMP('2025-01-15 08:10:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2025-01-16 08:10:00', 'YYYY-MM-DD HH24:MI:SS'),
        70000, 70210, 50.000, 3, 3);
INSERT INTO RENTAL (rental_id, reservation_id, customer_id, car_id, pickup_date, return_date, start_milage, end_milage,
                    total_amount, pickup_branch_id, return_branch_id)
VALUES (4, 4, 4, 4,
        TO_TIMESTAMP('2025-01-18 12:05:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2025-01-20 12:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        30000, 30800, 180.000, 4, 4);
INSERT INTO RENTAL (rental_id, reservation_id, customer_id, car_id, pickup_date, return_date, start_milage, end_milage,
                    total_amount, pickup_branch_id, return_branch_id)
VALUES (5, 5, 5, 5,
        TO_TIMESTAMP('2025-01-21 09:35:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2025-01-22 09:30:00', 'YYYY-MM-DD HH24:MI:SS'),
        20000, 20120, 150.000, 5, 5);

INSERT INTO PAYMENT (payment_id, rental_id, payment_date, amount, payment_method, status)
VALUES (1, 1, TO_TIMESTAMP('2025-01-10 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 100.000, 'CARD', 'PAID');
INSERT INTO PAYMENT (payment_id, rental_id, payment_date, amount, payment_method, status)
VALUES (2, 1, TO_TIMESTAMP('2025-01-13 09:10:00', 'YYYY-MM-DD HH24:MI:SS'), 65.000, 'CASH', 'PAID');
INSERT INTO PAYMENT (payment_id, rental_id, payment_date, amount, payment_method, status)
VALUES (3, 2, TO_TIMESTAMP('2025-01-14 10:05:00', 'YYYY-MM-DD HH24:MI:SS'), 130.000, 'CARD', 'PAID');
INSERT INTO PAYMENT (payment_id, rental_id, payment_date, amount, payment_method, status)
VALUES (4, 4, TO_TIMESTAMP('2025-01-20 12:05:00', 'YYYY-MM-DD HH24:MI:SS'), 180.000, 'TRANSFER', 'PAID');
INSERT INTO PAYMENT (payment_id, rental_id, payment_date, amount, payment_method, status)
VALUES (5, 5, TO_TIMESTAMP('2025-01-22 09:40:00', 'YYYY-MM-DD HH24:MI:SS'), 150.000, 'CARD', 'PAID');

INSERT INTO MAINTENANCE (maintenance_id, car_id, maintenance_date, description, cost, milage_at_maintenance)
VALUES (1, 1, DATE '2024-11-10', 'Oil change', 25.000, 44000);
INSERT INTO MAINTENANCE (maintenance_id, car_id, maintenance_date, description, cost, milage_at_maintenance)
VALUES (2, 2, DATE '2024-10-05', 'Brake pads', 80.000, 59000);
INSERT INTO MAINTENANCE (maintenance_id, car_id, maintenance_date, description, cost, milage_at_maintenance)
VALUES (3, 3, DATE '2024-09-12', 'Tire replacement', 120.000, 68000);
INSERT INTO MAINTENANCE (maintenance_id, car_id, maintenance_date, description, cost, milage_at_maintenance)
VALUES (4, 4, DATE '2024-12-01', 'General inspection', 60.000, 29000);
INSERT INTO MAINTENANCE (maintenance_id, car_id, maintenance_date, description, cost, milage_at_maintenance)
VALUES (5, 5, DATE '2024-12-15', 'Battery check', 40.000, 19500);

COMMIT;