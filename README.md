# SQL Server Backup & Maintenance Project

This project demonstrates key SQL Server tasks in a single, well-organized script (`SQL_Server_Training_Project.sql`).  
It is designed as a hands-on learning resource to practice database administration (DBA) fundamentals and disaster recovery best practices.

---

## 📌 Contents

The SQL script includes:

### ✅ 1 – Running Totals
- Two variations for calculating running totals using `SUM() OVER(...)`:
  - Option A: Based on `CustomerTransactions`
  - Option B: Based on `Orders` and `OrderLines`

### ✅ 2 & 3 – Create Databases with Recovery Models
- 🟩 Full Recovery Model: `FULL_RECOVERY_DB`
- 🟨 Simple Recovery Model: `SIMPLE_RECOVERY_DB`

### 🔁 Recovery Models – Key Differences

In SQL Server, **Recovery Models** determine how transaction logs are managed and how you can recover your data.

#### 🟩 FULL Recovery Model
- 🔄 **All transactions are fully logged**
- 🔐 Supports **point-in-time recovery**
- 📦 Requires **regular log backups**
- 🧠 Ideal for: Production environments where data loss is unacceptable

#### 🟨 SIMPLE Recovery Model
- 🔁 **Minimal logging** – logs are automatically truncated
- ❌ Does **not support point-in-time recovery**
- 📦 Does **not require log backups**
- 🧪 Ideal for: Development, testing, or non-critical systems

#### 🔍 Summary

| Feature                      | FULL                        | SIMPLE                      |
|-----------------------------|-----------------------------|-----------------------------|
| Logging                     | Full                        | Minimal                     |
| Log Backups Required        | ✅ Yes                      | ❌ No                        |
| Point-in-Time Restore       | ✅ Yes                      | ❌ No                        |
| Automatic Log Truncation    | ❌ No                       | ✅ Yes                      |
| Use Case                    | Production / Critical Data  | Dev/Test / Non-critical     |

> 📌 **Bottom line:**  
> Use **FULL** when you need full control and recovery options.  
> Use **SIMPLE** when performance and ease of maintenance are more important than full recovery capability.

### ✅ 4 – Backup Plan
- Full database backup
- Transaction log backup with timestamped filenames

### ✅ 5 – Point-in-Time Recovery Script
- Full script for restoring database to a specific time using `STOPAT`
- Includes safety notes, assumptions, and best practices

### ✅ 6 – Weekly Maintenance Plan
- Integrity check with `DBCC CHECKDB`
- Statistics update with `sp_updatestats`
- Index rebuild with cursor-based loop for all applicable indexes

---

## 💡 Why These Steps Matter

- **Running totals**: Useful for reporting and data analysis without subqueries.
- **Recovery models**: Define how SQL Server handles logging and backups.
- **Backups**: Essential for data protection and disaster recovery.
- **Point-in-time restore**: Enables undoing accidental data changes or corruption.
- **Maintenance**: Keeps the database healthy, improves performance, and prevents corruption.

---

## 📁 File

- [`SQL_Server_Training_Project.sql`](SQL_Server_Training_Project.sql) – The full script with all questions and solutions.

---

## 🛠 Requirements

- Microsoft SQL Server Developer Edition
- SQL Server Management Studio (SSMS)
- WideWorldImporters sample database

---

## ✅ Author

Created by: [Guy Van-Creveld]  
Date: July 2025

---
