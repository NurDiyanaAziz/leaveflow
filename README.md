📅 LeaveFlow: Digital Leave Management System

Project Overview

LeaveFlow is a mobile application designed to modernize and streamline the traditional HR process of managing employee leave requests. The goal is to eliminate paper-based forms and email chains by providing a real-time platform for both employees and managers.

Mission: To help employees and managers streamline leave requests digitally so they can track status instantly and eliminate paperwork delays.

Tech Stack

This project utilizes a robust, modern full-stack architecture:

Component

Technology

Role

Frontend (Mobile App)

Flutter

Cross-platform UI development for Employee and Manager screens.

Backend (API)

Node.js / Express

RESTful API server handling business logic, validation, and database interaction.

Messaging/Notifications

Firebase Cloud Messaging (FCM)

Added for real-time live notifications for status changes (e.g., manager approval).

Database

MySQL

Relational database (DB name: leaveflowdb) ensuring data integrity for balances and transactions.

Version Control

Git / GitHub

Code management and team collaboration.

Database Schema Highlights

The application relies on four key tables in the leaveflowdb, which are structured to support all required features, including decimal values for half-day requests:

users: Stores user authentication details (email, password, role) and establishes the reporting chain using a self-referencing manager_id foreign key.

leave_types: Stores reference data (e.g., Annual, Medical, Unpaid).

leave_balances: Tracks remaining days for each employee (remaining_days is DECIMAL(4, 2) for half-day support).

leave_requests: Stores every leave submission, including days_requested (DECIMAL), status (Pending, Approved, Rejected, Cancelled), and audit fields (created_at, last_updated_at).

Team Roles & Feature Ownership

The project is structured with full-stack ownership across key feature domains:

Team Member

Core Responsibility

Key Deliverables (FE & BE)

Person A

Main Screens & Authentication

FE: Login, Signup, Dashboard UI. BE: Authentication APIs and initial dashboard data endpoints.

Person B

Employee Module Owner

FE/BE: Full implementation of Leave Request Forms, History View, and the corresponding APIs (CRUD for requests).

Person C

Manager Module Owner

FE/BE: Full implementation of Manager Approval Dashboard, History, and the Approval/Rejection logic APIs.

Person D

Testing & Integration

Ensures token management, integration stability between all modules (A, B, C), and performs final system testing.

Setup & Installation

1. Database Setup

Ensure MySQL is installed and running locally.

Execute the schema script to create the database and tables:

mysql -u root -p < leaveflow_db_setup.sql



Run the seed data script to populate initial users, balances, and requests:

mysql -u root -p < leaveflow_seed_data.sql



2. Backend (Node.js/Express)

Navigate to the backend directory: cd backend/node

Install dependencies: npm install

Configure environment variables (.env file) for DB connection and JWT secret. (Note: You will also need to configure your Firebase Admin SDK keys here for sending notifications.)

Start the server: npm start (or similar command defined in your package.json).

3. Frontend (Flutter)

Ensure Flutter is installed and configured.

Navigate to the frontend directory: cd frontend/flutter

Run dependency check: flutter pub get

Run the application on an emulator or device: flutter run
