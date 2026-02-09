# Car Rental Database Project (Oracle PL/SQL & SQL Server T-SQL)

A Car Rental Management System database implemented for both Oracle (PL/SQL) and Microsoft SQL Server (T-SQL). Includes schema design (DDL), seed data (DML), stored procedures, triggers, test scripts, and an ER diagram.

## Tech Stack
- Oracle: PL/SQL
- Microsoft SQL Server: T-SQL

## What’s Included
- DDL: tables, constraints, indexes
- DML: seed data
- Stored procedures + triggers (business rules)
- Test scripts
- ER diagram + requirements/assumptions

## Files
- `01_ddl_oracle.sql` / `01_ddl_mssql.sql`
- `02_dml_oracle.sql` / `02_dml_mssql.sql`
- `03_proc_oracle.sql` / `03_proc_mssql.sql`
- `04_trg_oracle.sql` / `04_trg_mssql.sql`
- `05_test_oracle.sql` / `05_test_mssql.sql`
- `database_requirements.txt`
- `diagram.png`

## How to Run

### Oracle
Run in order:
1. `01_ddl_oracle.sql`
2. `02_dml_oracle.sql`
3. `03_proc_oracle.sql`
4. `04_trg_oracle.sql`
5. `05_test_oracle.sql`

### SQL Server
Run in order:
1. `01_ddl_mssql.sql`
2. `02_dml_mssql.sql`
3. `03_proc_mssql.sql`
4. `04_trg_mssql.sql`
5. `05_test_mssql.sql`

> If your MSSQL scripts use a specific database/schema (e.g., `USE [...]` / schema name), adjust them to match your environment.

## ER Diagram
![ERD](diagram.png)
