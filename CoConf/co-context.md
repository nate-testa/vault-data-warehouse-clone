# Vault Insurance Data Warehouse - Copilot Context

## 📚 Overview

This repository contains all source code and documentation for the **Vault Insurance Data Warehouse architecture**. It includes stored procedures, ETL logic, Airflow DAGs, and other supporting components for data management within the Vault platform.

## 🎯 Copilot Usage Instructions

This file defines the contextual documents that GitHub Copilot Agent should always refer to when assisting with code generation, maintenance, or task implementation.

### Always load context from:

- 📘 **Project Documentation**: `co-dw_docu.md`
- ⚙️ **Stored Procedure Patterns**: `co-proc-common-patterns.md`
- 📝 **Assigned Requirements**: `co-req.md`

These documents provide architectural documentation, reusable coding patterns, and current implementation tasks, respectively.

## 🌐 Language Standards

- All code, function names, comments, and documentation **must be written in English**.

## 🛠️ Task Types You May Be Asked to Implement

Tasks described in `co-req.md` can include:

- Adding new fields to existing stored procedures.
- Creating new stored procedures following existing patterns.
- Improving or refactoring existing SQL logic.
- Updating or adding procedures to **Airflow DAGs**.
- Performing general maintenance based on business requirements.

## 📌 Important Notes

- Follow existing naming conventions and architecture patterns found in `co-proc-common-patterns.md`.
- Always prioritize readability, maintainability, and performance.
- Avoid hardcoding unless strictly required.
- Do not execute commands or connect to any database, just do then changes on the code.
- Only modify other lines of code if absolutely necessary.
- Do not create changes on DDL, DML, Functions, Reports, ADF, Hubspot, Python Scripts unless strictly requiered.

---

GitHub Copilot Agent should treat this file as the entry point for contextual understanding of the project.
