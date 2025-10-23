# Laravel Backend API Documentation

This API implements role-based access control matching the frontend UserRole enum and UserSession class.

## User Roles

```php
// Backend constants
User::ROLE_STUDENT = 'student'
User::ROLE_ADMIN = 'admin' 
User::ROLE_SUPERADMIN = 'superadmin'
```

```dart
// Frontend enum (for reference)
enum UserRole {
  superAdmin,  // maps to 'superadmin'
  admin,       // maps to 'admin' 
  student,     // maps to 'student'
}
```

## Authentication Endpoints

### POST /api/register
Register a new user
```json
{
  "name": "John Doe",
  "email": "john@example.com", 
  "password": "password123",
  "password_confirmation": "password123",
  "role": "student|admin|superadmin",
  "department_id": 1
}
```

**Response:**
```json
{
  "user": {
    "userId": "1",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "student",
    "departmentId": 1,
    "departmentName": "Computer Science"
  },
  "token": "sanctum_token_here"
}
```

### POST /api/login
Login user
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:** Same as register

### POST /api/logout
Logout user (requires auth token)

## User Session Endpoints

### GET /api/user
Get current user session data (requires auth)

**Response:**
```json
{
  "user": {
    "userId": "1", 
    "name": "John Doe",
    "email": "john@example.com",
    "role": "student",
    "departmentId": 1,
    "departmentName": "Computer Science"
  }
}
```

### GET /api/user/permissions
Get user permissions and capabilities (requires auth)

**Response:**
```json
{
  "user": { /* user session data */ },
  "permissions": {
    "isSuperAdmin": false,
    "isAdmin": false, 
    "isStudent": true,
    "canManageUsers": false,
    "canManageDepartments": false,
    "canApproveListings": false,
    "canCreateListings": true,
    "managedDepartmentId": null,
    "managedDepartmentName": null
  }
}
```

## Student Routes (role: student)

### GET /api/listings
Get approved listings for students

### POST /api/listings  
Create new listing (students can create listings)

## Admin Routes (role: admin, superadmin)

### GET /api/admin/listings
Get all listings for admin review (admin sees only their department, superadmin sees all)

### DELETE /api/admin/listings/{listing}
Delete a listing (admin can only delete from their department)

## Super Admin Only Routes (role: superadmin)

### PUT /api/admin/listings/{listing}/approve
Approve a listing (Super Admin only - can approve from any department)

### User Management
- `GET /api/admin/users` - Get all users
- `POST /api/admin/users` - Create new user
- `PUT /api/admin/users/{user}` - Update user  
- `DELETE /api/admin/users/{user}` - Delete user

### Department Management
- `GET /api/admin/departments` - Get all departments with counts
- `POST /api/admin/departments` - Create department
- `PUT /api/admin/departments/{department}` - Update department
- `DELETE /api/admin/departments/{department}` - Delete department

## Department-Specific Routes (requires department access)

### GET /api/departments/{department_id}/listings
Get listings from specific department (admin can only access their own department)

### GET /api/departments/{department_id}/users  
Get users from specific department (admin can only access their own department)

## Public Routes

### GET /api/departments
Get list of all departments (public)

### GET /api/categories
Get list of all categories (requires auth but no specific role)

## Role-Based Authorization

The API uses custom middleware:

1. **RoleMiddleware** (`role:student,admin`) - Checks if user has required role(s)
2. **DepartmentAccessMiddleware** (`department.access`) - Checks if user can access specific department

## Permission Logic

### canManageDepartment(deptId) Logic:
- **SuperAdmin**: Can manage ALL departments  
- **Admin**: Can only manage their assigned department
- **Student**: Cannot manage any department

This matches the frontend UserSession.canManageDepartment() method exactly.

## Error Responses

- `401` - Unauthorized (no token or invalid token)
- `403` - Forbidden (insufficient permissions) 
- `422` - Validation errors
- `404` - Resource not found

## Headers Required

All authenticated routes require:
```
Authorization: Bearer {sanctum_token}
Content-Type: application/json
Accept: application/json
```
