<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LeaveFlow Project Documentation</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <style>
        body {
            font-family: 'Inter', sans-serif;
            background-color: #f1f5f9; /* Slate 100 */
        }
        .container {
            max-width: 900px;
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
        }
        .code-block {
            background-color: #1e293b; /* Slate 800 */
            color: #f8fafc; /* Slate 50 */
            padding: 1rem;
            border-radius: 0.5rem;
            overflow-x: auto;
            font-family: monospace;
            font-size: 0.875rem;
        }
        .setup-section h3 {
            border-left: 4px solid #3b82f6; /* Blue 500 */
            padding-left: 0.75rem;
            margin-bottom: 1rem;
        }
        /* Custom image styling for the placeholder */
        .image-placeholder {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 200px;
            background-color: #e0f2fe; /* Light Blue */
            border: 2px dashed #93c5fd; /* Mid Blue */
            border-radius: 0.75rem;
            color: #1e40af; /* Dark Blue */
            font-weight: 600;
            margin-top: 1rem;
            margin-bottom: 1.5rem;
        }
    </style>
</head>
<body>

    <div class="container mx-auto mt-8 mb-12 p-8 md:p-12 bg-white rounded-xl">
        
        <!-- Header -->
        <header class="pb-6 mb-8 border-b-2 border-blue-500">
            <h1 class="text-5xl font-extrabold text-gray-900 flex items-center">
                <i class="fa-solid fa-calendar-days text-blue-500 mr-4"></i>
                LeaveFlow: Digital Leave Management System
            </h1>
        </header>

        <!-- Project Overview -->
        <section class="mb-8">
            <h2 class="text-3xl font-bold text-gray-800 mb-4">Project Overview</h2>
            <p class="text-gray-600 mb-4">LeaveFlow is a mobile application designed to modernize and streamline the traditional HR process of managing employee leave requests. The goal is to eliminate paper-based forms and email chains by providing a real-time platform for both employees and managers.</p>
            <blockquote class="p-4 my-4 bg-yellow-50 border-l-4 border-yellow-500 text-yellow-800 rounded-lg italic">
                <strong class="font-semibold">Mission:</strong> To help employees and managers streamline leave requests digitally so they can track status instantly and eliminate paperwork delays.
            </blockquote>
        </section>

        <!-- Tech Stack -->
        <section class="mb-8">
            <h2 class="text-3xl font-bold text-gray-800 mb-4">Tech Stack</h2>
            <p class="text-gray-600 mb-4">This project utilizes a robust, modern full-stack architecture:</p>

            <div class="overflow-x-auto mb-4 rounded-lg border border-gray-200">
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Component</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Technology</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">Frontend (Mobile App)</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-blue-600 font-semibold">Flutter</td>
                            <td class="px-6 py-4 text-sm text-gray-500">Cross-platform UI development for Employee and Manager screens.</td>
                        </tr>
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">Backend (API)</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-blue-600 font-semibold">Node.js / Express</td>
                            <td class="px-6 py-4 text-sm text-gray-500">RESTful API server handling business logic, validation, and database interaction.</td>
                        </tr>
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">Messaging/Notifications</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-red-600 font-semibold">Firebase Cloud Messaging (FCM)</td>
                            <td class="px-6 py-4 text-sm text-gray-500">Added for real-time live notifications for status changes (e.g., manager approval).</td>
                        </tr>
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">Database</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-blue-600 font-semibold">MySQL</td>
                            <td class="px-6 py-4 text-sm text-gray-500">Relational database (DB name: `leaveflowdb`) ensuring data integrity for balances and transactions.</td>
                        </tr>
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">Version Control</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-blue-600 font-semibold">Git / GitHub</td>
                            <td class="px-6 py-4 text-sm text-gray-500">Code management and team collaboration.</td>
                        </tr>
                    </tbody>
                </table>
            </div>
            
            <div class="image-placeholder">
                 <p class="text-xl">Full Stack Application Architecture Diagram Placeholder</p>
                 <!-- [Image of Full Stack Application Architecture Diagram] -->
            </div>
        </section>

        <!-- Database Schema Highlights -->
        <section class="mb-8">
            <h2 class="text-3xl font-bold text-gray-800 mb-4">Database Schema Highlights</h2>
            <p class="text-gray-600 mb-3">The application relies on four key tables in the `leaveflowdb`, which are structured to support all required features, including decimal values for half-day requests:</p>
            <ul class="list-disc list-inside space-y-3 text-gray-600 pl-4">
                <li>**`users`**: Stores user authentication details (`email`, `password`, `role`) and establishes the reporting chain using a **self-referencing `manager_id` foreign key**.</li>
                <li>**`leave_types`**: Stores reference data (e.g., Annual, Medical, Unpaid).</li>
                <li>**`leave_balances`**: Tracks remaining days for each employee (`remaining_days` is `DECIMAL(4, 2)` for half-day support).</li>
                <li>**`leave_requests`**: Stores every leave submission, including `days_requested` (DECIMAL), `status` (Pending, Approved, Rejected, Cancelled), and audit fields (`created_at`, `last_updated_at`).</li>
            </ul>
        </section>

        <!-- Team Roles -->
        <section class="mb-8">
            <h2 class="text-3xl font-bold text-gray-800 mb-4">Team Roles & Feature Ownership</h2>
            <p class="text-gray-600 mb-3">The project is structured with full-stack ownership across key feature domains:</p>
            
            <div class="overflow-x-auto rounded-lg border border-gray-200">
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Team Member</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Core Responsibility</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Key Deliverables (FE & BE)</th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">Person A</td>
                            <td class="px-6 py-4 text-sm text-gray-500">Main Screens & Authentication</td>
                            <td class="px-6 py-4 text-sm text-gray-500">FE: Login, Signup, Dashboard UI. BE: Authentication APIs and initial dashboard data endpoints.</td>
                        </tr>
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">Person B</td>
                            <td class="px-6 py-4 text-sm text-gray-500">Employee Module Owner</td>
                            <td class="px-6 py-4 text-sm text-gray-500">FE/BE: Full implementation of Leave Request Forms, History View, and the corresponding APIs (CRUD for requests).</td>
                        </tr>
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">Person C</td>
                            <td class="px-6 py-4 text-sm text-gray-500">Manager Module Owner</td>
                            <td class="px-6 py-4 text-sm text-gray-500">FE/BE: Full implementation of Manager Approval Dashboard, History, and the Approval/Rejection logic APIs.</td>
                        </tr>
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">Person D</td>
                            <td class="px-6 py-4 text-sm text-gray-500">Testing & Integration</td>
                            <td class="px-6 py-4 text-sm text-gray-500">Ensures token management, integration stability between all modules (A, B, C), and performs final system testing.</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </section>

        <!-- Setup & Installation -->
        <section class="setup-section">
            <h2 class="text-3xl font-bold text-gray-800 mb-6">Setup & Installation</h2>

            <!-- Database Setup -->
            <div class="mb-6">
                <h3 class="text-xl font-semibold text-gray-700">1. Database Setup</h3>
                <ol class="list-decimal list-outside space-y-4 text-gray-600 pl-5">
                    <li>Ensure MySQL is installed and running locally.</li>
                    <li>Execute the schema script to create the database and tables:
                        <pre class="code-block mt-1"><code>mysql -u root -p &lt; leaveflow_db_setup.sql</code></pre>
                    </li>
                    <li>Run the seed data script to populate initial users, balances, and requests:
                        <pre class="code-block mt-1"><code>mysql -u root -p &lt; leaveflow_seed_data.sql</code></pre>
                    </li>
                </ol>
            </div>

            <!-- Backend Setup -->
            <div class="mb-6">
                <h3 class="text-xl font-semibold text-gray-700">2. Backend (Node.js/Express)</h3>
                <ol class="list-decimal list-outside space-y-4 text-gray-600 pl-5">
                    <li>Navigate to the backend directory: 
                        <pre class="code-block mt-1"><code>cd backend/node</code></pre>
                    </li>
                    <li>Install dependencies: 
                        <pre class="code-block mt-1"><code>npm install</code></pre>
                    </li>
                    <li>Configure environment variables (`.env` file) for DB connection and JWT secret. **(Note: You will also need to configure your Firebase Admin SDK keys here for sending notifications.)**</li>
                    <li>Start the server: 
                        <pre class="code-block mt-1"><code>npm start</code></pre>
                    </li>
                </ol>
            </div>

            <!-- Frontend Setup -->
            <div>
                <h3 class="text-xl font-semibold text-gray-700">3. Frontend (Flutter)</h3>
                <ol class="list-decimal list-outside space-y-4 text-gray-600 pl-5">
                    <li>Ensure Flutter is installed and configured.</li>
                    <li>Navigate to the frontend directory: 
                        <pre class="code-block mt-1"><code>cd frontend/flutter</code></pre>
                    </li>
                    <li>Run dependency check: 
                        <pre class="code-block mt-1"><code>flutter pub get</code></pre>
                    </li>
                    <li>Run the application on an emulator or device: 
                        <pre class="code-block mt-1"><code>flutter run</code></pre>
                    </li>
                </ol>
            </div>
        </section>

    </div>
</body>
</html>
