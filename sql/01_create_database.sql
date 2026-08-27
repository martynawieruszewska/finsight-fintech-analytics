/*
===============================================================================
FinSight - Database Setup
===============================================================================
Purpose:
    - Creates the PostgreSQL database used by the FinSight project.
    - Run this script while connected to the default `postgres` database.

Important:
    - The DROP DATABASE statement is intentionally commented out.
    - Uncomment it only when you explicitly want to recreate the entire
      FinSight database from scratch.
===============================================================================
*/

-- Optional full reset:
-- WARNING: This permanently removes the entire database and all its objects.
-- DROP DATABASE IF EXISTS finsight;

create database finsight;