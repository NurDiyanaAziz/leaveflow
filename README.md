# 📅 LeaveFlow: Digital Leave Management System

LeaveFlow is a mobile application designed to modernize and streamline the HR process of managing employee leave requests. It replaces traditional paper forms and messy email chains with a clean, real-time platform for both employees and managers.

> **Mission:** To help employees and managers streamline leave requests digitally so they can track status instantly and eliminate paperwork delays.

---

## 🏗️ Tech Stack

This project uses a modern full-stack architecture:

| Component | Technology | Role |
|----------|------------|------|
| **Frontend (Mobile App)** | **Flutter** | Cross-platform UI for employees and managers |
| **Backend (API)** | **Node.js / Express** | REST API, business logic, validation, DB interaction |
| **Messaging / Notifications** | **Firebase Cloud Messaging (FCM)** | Real-time push notifications for leave status |
| **Database** | **MySQL** | Relational DB (Schema: `leaveflowdb`) |
| **Version Control** | **Git / GitHub** | Team collaboration & code tracking |

> _Architecture Diagram Placeholder_

---

## 🗄️ Database Schema Highlights

The system uses four main MySQL tables inside **`leaveflowdb`**, designed to support features like decimal leave balances and half-day requests.

### **1. `users`**
- Stores employee & manager details  
- Includes `role`, `email`, `password`  
- Supports reporting structure with `manager_id` (self-referencing FK)

### **2. `leave_types`**
- Reference leave categories (Annual, Medical, Emergency, etc.)

### **3. `leave_balances`**
- Tracks remaining leave for each employee  
- `remaining_days` stored as `DECIMAL(4,2)` to support half-day leave

### **4. `leave_requests`**
- Every leave submission stored here  
- Includes:  
  - `start_date`, `end_date`  
  - `days_requested` (DECIMAL)  
  - `status` (Pending, Approved, Rejected, Cancelled)  
  - `created_at`, `last_updated_at`  
  - `approver_id`  

---

## 👥 Team Roles & Responsibilities

| Team Member | Core Responsibility | Key Deliverables |
|-------------|---------------------|------------------|
| **Person A** | Main Screens & Authentication | Login, Signup, Dashboard UI + Authentication API |
| **Person B** | Employee Module Owner | Leave request form, history, related APIs |
| **Person C** | Manager Module Owner | Approval dashboard, approval logic, APIs |
| **Person D** | Testing & Integration | Token handling, module integration, full system testing |

---

## ⚙️ Setup & Installation

### 1. 🗃️ Database Setup

1. Ensure MySQL is installed & running.
2. Execute schema file:
    ```sh
    mysql -u root -p < leaveflow_db_setup.sql
    ```
3. Load seed data (sample users, balances, requests):
    ```sh
    mysql -u root -p < leaveflow_seed_data.sql
    ```

---

### 2. 🛠️ Backend Setup (Node.js / Express)

1. Navigate to backend folder:
    ```sh
    cd backend/node
    ```
2. Install dependencies:
    ```sh
    npm install
    ```
3. Configure environment variables (`.env`):
    - MySQL credentials
    - JWT secret
    - Firebase Admin SDK for FCM notifications
4. Start API server:
    ```sh
    npm start
    ```

---

### 3. 📱 Frontend Setup (Flutter)

1. Ensure Flutter SDK is installed.
2. Navigate to frontend directory:
    ```sh
    cd frontend/flutter
    ```
3. Install dependencies:
    ```sh
    flutter pub get
    ```
4. Run the app:
    ```sh
    flutter run
    ```

---

## 🎉 Final Notes

This README contains:
- Project overview  
- Full tech stack  
- Database summary  
- Team task assignment  
- Complete setup steps for backend & frontend  

You can extend the README with:
✔ API documentation  
✔ Screenshots  
✔ ERD diagram  
✔ CI/CD info  
✔ Release notes  

Let me know if you want me to generate:  
📌 **API Documentation (REST endpoints)**  
📌 **ERD Diagram (image)**  
📌 **More detailed system architecture**  
📌 **User flow diagrams**  
📌 **Project timeline / Gantt chart**

Just tell me! 😊
