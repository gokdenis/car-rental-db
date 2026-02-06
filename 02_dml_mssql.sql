USE [2019SBD];

INSERT INTO [s32736].[CUSTOMER] (customer_id, birth_date, first_name, last_name, phone, email, address,
                                 driver_license_number, driver_license_issue_date)
VALUES (1, '1998-03-12', 'Ahmet', 'Yilmaz', '+90 530 111 1111', 'ahmet.yilmaz@mail.com', 'Istanbul', 'DL-TR-1001',
        '2018-06-10'),
       (2, '1997-09-25', 'Elif', 'Kaya', '+90 530 222 2222', 'elif.kaya@mail.com', 'Ankara', 'DL-TR-1002',
        '2017-05-08'),
       (3, '1995-01-14', 'Mehmet', 'Demir', '+90 530 333 3333', 'mehmet.demir@mail.com', 'Izmir', 'DL-TR-1003',
        '2016-04-18'),
       (4, '2000-11-02', 'Zeynep', 'Sari', '+90 530 444 4444', 'zeynep.sari@mail.com', 'Bursa', 'DL-TR-1004',
        '2019-08-22'),
       (5, '1992-07-30', 'Can', 'Arslan', '+90 530 555 5555', 'can.arslan@mail.com', 'Antalya', 'DL-TR-1005',
        '2014-03-15');

INSERT INTO [s32736].[NATIONAL_ID] (national_id_id, customer_id, national_id, issuing_country, issue_date, expiry_date)
VALUES (1, 1, 11111111111, 'Turkey', '2018-01-01', '2028-01-01'),
       (2, 2, 22222222222, 'Turkey', '2019-02-10', '2029-02-10'),
       (3, 3, 33333333333, 'Turkey', '2017-03-05', '2027-03-05'),
       (4, 4, 44444444444, 'Turkey', '2020-04-20', '2030-04-20'),
       (5, 5, 55555555555, 'Turkey', '2016-05-15', '2026-05-15');

INSERT INTO [s32736].[BRANCH] (branch_id, name, address, city, phone, email)
VALUES (1, 'Istanbul Center', 'Sisli', 'Istanbul', '+90 212 000 0001', 'istanbul@carrent.com'),
       (2, 'Ankara Center', 'Cankaya', 'Ankara', '+90 312 000 0002', 'ankara@carrent.com'),
       (3, 'Izmir Center', 'Konak', 'Izmir', '+90 232 000 0003', 'izmir@carrent.com'),
       (4, 'Bursa Center', 'Nilufer', 'Bursa', '+90 224 000 0004', 'bursa@carrent.com'),
       (5, 'Antalya Center', 'Muratpasa', 'Antalya', '+90 242 000 0005', 'antalya@carrent.com');

INSERT INTO [s32736].[CAR_TYPE] (car_type_id, name, fuel_type, transmission, [class])
VALUES (1, 'Sedan', 'Gasoline', 'Automatic', 'Economy'),
       (2, 'SUV', 'Diesel', 'Automatic', 'Standard'),
       (3, 'Hatchback', 'Gasoline', 'Manual', 'Economy'),
       (4, 'Van', 'Diesel', 'Manual', 'Standard'),
       (5, 'Luxury Sedan', 'Hybrid', 'Automatic', 'Luxury');

INSERT INTO [s32736].[CAR_MODEL] (car_model_id, brand_name, model_name, country, production_start_year,
                                  production_end_year)
VALUES (1, 'Toyota', 'Corolla', 'Japan', 2013, NULL),
       (2, 'Renault', 'Clio', 'France', 2012, NULL),
       (3, 'Volkswagen', 'Golf', 'Germany', 2011, NULL),
       (4, 'Ford', 'Transit', 'USA', 2010, NULL),
       (5, 'BMW', '5 Series', 'Germany', 2015, NULL);

INSERT INTO [s32736].[CAR] (car_id, plate_number, [year], color, milage, daily_rate, status, car_type_id, car_model_id,
                            branch_id)
VALUES (1, '34-ABC-001', 2020, 'White', 45000, 55.000, 'AVAILABLE', 1, 1, 1),
       (2, '06-DEF-002', 2019, 'Black', 60000, 65.000, 'AVAILABLE', 2, 3, 2),
       (3, '35-GHI-003', 2018, 'Blue', 70000, 50.000, 'AVAILABLE', 3, 2, 3),
       (4, '16-JKL-004', 2021, 'Gray', 30000, 90.000, 'AVAILABLE', 4, 4, 4),
       (5, '07-MNO-005', 2022, 'Silver', 20000, 150.000, 'AVAILABLE', 5, 5, 5);

INSERT INTO [s32736].[RESERVATION] (reservation_id, customer_id, car_id, status, start_date, end_date, created_at)
VALUES (1, 1, 1, 'CONFIRMED', '2025-01-10T09:00:00', '2025-01-13T09:00:00', SYSDATETIME()),
       (2, 2, 2, 'CONFIRMED', '2025-01-12T10:00:00', '2025-01-14T10:00:00', SYSDATETIME()),
       (3, 3, 3, 'CREATED', '2025-01-15T08:00:00', '2025-01-16T08:00:00', SYSDATETIME()),
       (4, 4, 4, 'CONFIRMED', '2025-01-18T12:00:00', '2025-01-20T12:00:00', SYSDATETIME()),
       (5, 5, 5, 'CONFIRMED', '2025-01-21T09:30:00', '2025-01-22T09:30:00', SYSDATETIME());

INSERT INTO [s32736].[RENTAL] (rental_id, reservation_id, customer_id, car_id, pickup_date, return_date, start_milage,
                               end_milage, total_amount, pickup_branch_id, return_branch_id)
VALUES (1, 1, 1, 1, '2025-01-10T09:10:00', '2025-01-13T09:05:00', 45000, 45550, 165.000, 1, 1),
       (2, 2, 2, 2, '2025-01-12T10:05:00', '2025-01-14T10:00:00', 60000, 60620, 130.000, 2, 2),
       (3, 3, 3, 3, '2025-01-15T08:10:00', '2025-01-16T08:10:00', 70000, 70210, 50.000, 3, 3),
       (4, 4, 4, 4, '2025-01-18T12:05:00', '2025-01-20T12:00:00', 30000, 30800, 180.000, 4, 4),
       (5, 5, 5, 5, '2025-01-21T09:35:00', '2025-01-22T09:30:00', 20000, 20120, 150.000, 5, 5);

INSERT INTO [s32736].[PAYMENT] (payment_id, rental_id, payment_date, amount, payment_method, status)
VALUES (1, 1, '2025-01-10T10:00:00', 100.000, 'CARD', 'PAID'),
       (2, 1, '2025-01-13T09:10:00', 65.000, 'CASH', 'PAID'),
       (3, 2, '2025-01-14T10:05:00', 130.000, 'CARD', 'PAID'),
       (4, 4, '2025-01-20T12:05:00', 180.000, 'TRANSFER', 'PAID'),
       (5, 5, '2025-01-22T09:40:00', 150.000, 'CARD', 'PAID');

INSERT INTO [s32736].[MAINTENANCE] (maintenance_id, car_id, maintenance_date, description, cost, milage_at_maintenance)
VALUES (1, 1, '2024-11-10', 'Oil change', 25.000, 44000),
       (2, 2, '2024-10-05', 'Brake pads', 80.000, 59000),
       (3, 3, '2024-09-12', 'Tire replacement', 120.000, 68000),
       (4, 4, '2024-12-01', 'General inspection', 60.000, 29000),
       (5, 5, '2024-12-15', 'Battery check', 40.000, 19500);