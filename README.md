# E-Commerce Data Warehouse & ELT Pipeline

## 📌 Project Overview
This project demonstrates a complete **End-to-End Data Engineering** solution that transforms unstructured E-Commerce data into a production-ready **Star Schema Data Warehouse**.

Instead of manual Excel cleaning, I implemented an **ELT (Extract, Load, Transform)** architecture using **Oracle SQL**. This approach ensures data integrity, scalability, and auditability.

## 🏗 Architecture
* **Source:** Unstructured Excel Data (OLTP Extract) containing merged orders, customers, and shipping details.
* **Staging Layer:** Raw data ingestion into Oracle Database (`staging_orders`).
* **Core Warehouse:** Star Schema Design with Dimension and Fact tables.
* **Transformation:** SQL-based pipeline to handle data cleaning, normalization, and surrogate key generation.

## 🛠 Tech Stack
* **Database:** Oracle Database (PL/SQL)
* **IDE:** JetBrains DataGrip
* **Modelling:** Dimensional Modelling (Kimball Methodology)

## 📂 Repository Structure
* `sql/` - Contains SQL scripts for table creation (DDL) and data loading (DML).
* `data/` - Source data sample and Data Dictionary.
* `docs/` - Entity Relationship Diagram (ERD) and project requirements.

## 🚀 Key Features Implemented
1.  **Star Schema Design:**
    * **Fact Table:** `fact_sales` (Grain: Order Line)
    * **Dimensions:** `dim_customer`, `dim_product`, `dim_shipment`, `dim_date`
2.  **Junk Dimension:** consolidated low-cardinality flags (e.g., `is_gift`, `device_type`) into `dim_junk` to optimize storage.
3.  **Data Quality Handling:**
    * Handled `NULL` values using `NVL()` logic during joins.
    * Converted string dates to proper `Date` and `Integer` keys.
    * Removed duplicates at the Staging layer.

## 📊 Entity Relationship Diagram (ERD)
*(Please refer to the `docs/` folder for the detailed visual model)*

## 💻 How to Run
1.  Import `unstructured_data.xlsx` into the `staging_orders` table using the import tool.
2.  Run `sql/01_ddl_tables.sql` to create the warehouse structure.
3.  Run `sql/02_elt_pipeline.sql` to clean and populate the tables.

---
*Author: Elmar*