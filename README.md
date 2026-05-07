# UDD Essentials

Welcome to the UDD Essentials repository.  
This project is a full-stack university merchandise hub designed to streamline the ordering process for students and administrators of university departments.

---

## About the Project

UDD Essentials is a comprehensive merchandise management ecosystem composed of two main components:

• Backend API (Laravel)  
• Mobile Application (Flutter)  

Each system works together to support:

• Students  
• Admins  
• Super Admins  

It handles:

• Product and inventory management  
• Order processing and tracking  
• User authentication and role management  
• Departmental monitoring  

---

## System Structure

The project is organized into two main repositories:

• backend → RESTful API (Laravel Framework)  
• frontend → Multi-platform Application (Flutter)  

---

# Backend API

The Backend API serves as the central hub for data management and business logic.

## Features

• Secure RESTful API endpoints  
• Role-based access control (RBAC)  
• Product and category management  
• Order and transaction logging  
• Department and user management  
• Automated notifications system  

## Tech Stack

• Laravel 12.x  
• PHP 8.2+  
• MySQL Database  
• Laravel Sanctum (Authentication) 


---

# Mobile Application

The Mobile App is the interface for students to browse and order, and for admins to manage their departments.

## Features

• Student merchandise browsing and ordering  
• Real-time order status tracking  
• Admin dashboard for product management  
• QR code generation for order verification  
• Payment receipt upload and verification  
• Department-specific analytics  
• Responsive and modern UI/UX  

## User Roles

• Students → Browse, order, and track merchandise  
• Admins → Manage products and process department orders  
• Super Admins → System monitoring and department management  

## Tech Stack

• Flutter (Dart)  
• Provider (State Management)  
• HTTP (API Integration)  
• Shared Preferences (Local Storage)  

---

# How to Run

## Backend API

cd backend  
composer install  
php artisan migrate --seed  
php artisan serve  

---

## Mobile Application

cd frontend  
flutter pub get  
flutter run  

---

# Project Goal

The goal of UDD Essentials is to make university merchandise ordering:

• Streamlined  
• Organized  
• Transparent  
• Easy to manage  
• Highly accessible  

---

# License

This project is for educational and capstone purposes only.

---

# Developers

UDD Essentials Development Team

• Siapno, Arvin Denver A.  
• Cayabyab, Angelo Gabriel E.  
• Soriano, Christan Jake C.  
• Palma, Jann Patrick G.
