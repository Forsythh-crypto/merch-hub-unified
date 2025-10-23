# Merch Hub - Role Flowcharts and Documentation

## Overview
The Merch Hub system implements a three-tier role-based access control system with distinct permissions and capabilities for each user type.

---

## 🔴 SUPER ADMIN ROLE

### Decision-Based Super Admin Flowchart

```
        ┌─────────────────┐
        │   START: Login  │
        │      Page       │
        └─────────┬───────┘
                  │
                  ▼
        ┌─────────────────┐
        │ Enter Credentials│
        └─────────┬───────┘
                  │
                  ▼
            ◆─────────────◆
           ╱               ╲
          ╱ Valid Superadmin ╲
         ╱   Credentials?     ╲
        ◆─────────────────────◆
        │                     │
       NO│                    │YES
        │                     │
        ▼                     ▼
┌─────────────┐    ┌─────────────────┐
│ Show Error  │    │   Superadmin    │
│  Message    │    │   Dashboard     │
└─────┬───────┘    └─────────┬───────┘
      │                      │
      │                      ▼
      │            ┌─────────────────┐
      │            │ Navigation Menu │
      │            │ Selection       │
      │            └─────────┬───────┘
      │                      │
      │                      ▼
      │                ◆─────────────◆
      │               ╱               ╲
      │              ╱ Which Feature? ╲
      │             ╱                 ╲
      │            ◆───────────────────◆
      │            │    │    │    │    │
      │            │    │    │    │    │
      │            ▼    ▼    ▼    ▼    ▼
      │    ┌─────────┐ ┌───┐ ┌───┐ ┌───┐ ┌─────┐
      │    │  User   │ │Dep│ │Pro│ │Sal│ │Sys │
      │    │  Mgmt   │ │Mgt│ │Mgt│ │Rep│ │Cfg │
      │    └────┬────┘ └─┬─┘ └─┬─┘ └─┬─┘ └──┬──┘
      │         │        │     │     │      │
      │         ▼        │     │     │      │
      │   ◆─────────◆    │     │     │      │
      │  ╱           ╲   │     │     │      │
      │ ╱ User Action? ╲  │     │     │      │
      │◆───────────────◆ │     │     │      │
      ││      │      │  │ │     │     │      │
      ││      │      │  │ │     │     │      │
      │▼      ▼      ▼  │ │     │     │      │
      │┌───┐┌───┐┌───┐  │ │     │     │      │
      ││Crt││Edt││Del│  │ │     │     │      │
      │└─┬─┘└─┬─┘└─┬─┘  │ │     │     │      │
      │  │    │    │    │ │     │     │      │
      │  ▼    ▼    ▼    │ │     │     │      │
      │┌─────────────┐  │ │     │     │      │
      ││ Execute     │  │ │     │     │      │
      ││ Operation   │  │ │     │     │      │
      │└─────┬───────┘  │ │     │     │      │
      │      │          │ │     │     │      │
      │      ▼          │ │     │     │      │
      │ ◆─────────◆     │ │     │     │      │
      │╱           ╲    │ │     │     │      │
      ││ Success?   │   │ │     │     │      │
      │◆───────────◆    │ │     │     │      │
      ││           │    │ │     │     │      │
      │NO          YES  │ │     │     │      │
      ││           │    │ │     │     │      │
      │▼           ▼    │ │     │     │      │
      │┌─────┐ ┌─────┐  │ │     │     │      │
      ││Error│ │Success│ │ │     │     │      │
      ││Msg  │ │Message│ │ │     │     │      │
      │└──┬──┘ └──┬──┘  │ │     │     │      │
      │   │       │     │ │     │     │      │
      └───┼───────┼─────┘ │     │     │      │
          │       │       │     │     │      │
          └───────┼───────┼─────┼─────┼──────┘
                  │       │     │     │
                  ▼       │     │     │
            ◆─────────◆   │     │     │
           ╱           ╲  │     │     │
          ╱ Continue?   ╲ │     │     │
         ◆─────────────◆  │     │     │
         │             │  │     │     │
        YES           NO  │     │     │
         │             │  │     │     │
         └─────────────┼──┼─────┼─────┘
                       │  │     │
                       ▼  │     │
                 ┌─────────┐     │
                 │ LOGOUT  │     │
                 └─────────┘     │
                                 │
         ┌───────────────────────┘
         │
         ▼
   ◆─────────◆
  ╱           ╲
 ╱ Department  ╲
╱  Management? ╲
◆─────────────◆
│             │
▼             ▼
[Similar decision tree for Department Management]

   ◆─────────◆
  ╱           ╲
 ╱  Product    ╲
╱  Management? ╲
◆─────────────◆
│             │
▼             ▼
[Similar decision tree for Product Management]

   ◆─────────◆
  ╱           ╲
 ╱   Sales     ╲
╱   Reports?   ╲
◆─────────────◆
│             │
▼             ▼
[Similar decision tree for Sales Reports]
```

### Super Admin Scope & Capabilities

**✅ FULL ACCESS PERMISSIONS:**
- **Global System Control**: Complete access to all system features and data
- **User Management**: Create, edit, delete, and manage roles for all users
- **Department Management**: Create, edit, delete, and manage all departments
- **Product Management**: Full CRUD operations on all products across all departments
- **Order Management**: View and manage all orders from all departments
- **Financial Management**: Access to all sales reports and revenue data
- **System Administration**: Configure system settings, manage notifications
- **Discount Management**: Create and manage discount codes for all departments
- **Analytics & Reporting**: Access to comprehensive system analytics

**🔧 SPECIFIC CAPABILITIES:**
- Grant/revoke admin privileges to users
- Grant/revoke super admin privileges to users
- Manage department assignments for admins
- Override any department-specific restrictions
- Access cross-department analytics and reports
- Configure system-wide settings and policies

### Super Admin Limitations

**❌ RESTRICTIONS:**
- Cannot delete their own super admin account (security measure)
- Cannot modify system-critical configurations without proper validation
- Must follow audit trails for sensitive operations
- Limited by system backup and recovery procedures

---

## 🟡 ADMIN ROLE

### Decision-Based Flowchart: Admin Workflow

```
        ┌─────────────────┐
        │   START: Login  │
        │      Page       │
        └─────────┬───────┘
                  │
                  ▼
        ┌─────────────────┐
        │ Enter Credentials│
        └─────────┬───────┘
                  │
                  ▼
            ◆─────────────◆
           ╱               ╲
          ╱  Valid Admin    ╲
         ╱   Credentials?    ╲
        ◆─────────────────────◆
        │                     │
       NO│                    │YES
        │                     │
        ▼                     ▼
┌─────────────┐    ┌─────────────────┐
│ Show Error  │    │ Check Department│
│  Message    │    │   Assignment    │
└─────┬───────┘    └─────────┬───────┘
      │                      │
      │                      ▼
      │                ◆─────────────◆
      │               ╱               ╲
      │              ╱ Has Department ╲
      │             ╱   Assignment?    ╲
      │            ◆─────────────────────◆
      │            │                     │
      │           NO│                    │YES
      │            │                     │
      │            ▼                     ▼
      │    ┌─────────────┐    ┌─────────────────┐
      │    │ Access      │    │     Admin       │
      │    │ Denied      │    │   Dashboard     │
      │    └─────────────┘    │ (Dept Specific) │
      │                       └─────────┬───────┘
      │                                 │
      │                                 ▼
      │                       ┌─────────────────┐
      │                       │ Navigation Menu │
      │                       │   Selection     │
      │                       └─────────┬───────┘
      │                                 │
      │                                 ▼
      │                           ◆─────────────◆
      │                          ╱               ╲
      │                         ╱ Which Feature? ╲
      │                        ╱                 ╲
      │                       ◆───────────────────◆
      │                       │    │    │    │    │
      │                       │    │    │    │    │
      │                       ▼    ▼    ▼    ▼    ▼
      │               ┌─────────┐ ┌───┐ ┌───┐ ┌───┐ ┌─────┐
      │               │Product  │ │Ord│ │Dis│ │Rep│ │User │
      │               │  Mgmt   │ │Mgt│ │Cod│ │ort│ │Mgmt │
      │               └────┬────┘ └─┬─┘ └─┬─┘ └─┬─┘ └──┬──┘
      │                    │        │     │     │      │
      │                    ▼        │     │     │      │
      │              ◆─────────◆    │     │     │      │
      │             ╱           ╲   │     │     │      │
      │            ╱ Department  ╲  │     │     │      │
      │           ╱   Product?    ╲ │     │     │      │
      │          ◆─────────────────◆│     │     │      │
      │          │                 ││     │     │      │
      │         YES               NO││     │     │      │
      │          │                 ││     │     │      │
      │          ▼                 ▼│     │     │      │
      │    ┌─────────┐    ┌─────────┐│     │     │      │
      │    │ Allow   │    │ Access  ││     │     │      │
      │    │ Access  │    │ Denied  ││     │     │      │
      │    └────┬────┘    └─────────┘│     │     │      │
      │         │                    │     │     │      │
      │         ▼                    │     │     │      │
      │   ◆─────────◆                │     │     │      │
      │  ╱           ╲               │     │     │      │
      │ ╱ Product     ╲              │     │     │      │
      │╱  Action?      ╲             │     │     │      │
      │◆───────────────◆             │     │     │      │
      ││      │      │               │     │     │      │
      ││      │      │               │     │     │      │
      │▼      ▼      ▼               │     │     │      │
      │┌───┐┌───┐┌───┐               │     │     │      │
      ││Crt││Edt││Del│               │     │     │      │
      │└─┬─┘└─┬─┘└─┬─┘               │     │     │      │
      │  │    │    │                 │     │     │      │
      │  ▼    ▼    ▼                 │     │     │      │
      │┌─────────────┐               │     │     │      │
      ││ Execute     │               │     │     │      │
      ││ Operation   │               │     │     │      │
      │└─────┬───────┘               │     │     │      │
      │      │                       │     │     │      │
      │      ▼                       │     │     │      │
      │ ◆─────────◆                  │     │     │      │
      │╱           ╲                 │     │     │      │
      ││ Success?   │                │     │     │      │
      │◆───────────◆                 │     │     │      │
      ││           │                 │     │     │      │
      │NO          YES               │     │     │      │
      ││           │                 │     │     │      │
      │▼           ▼                 │     │     │      │
      │┌─────┐ ┌─────┐               │     │     │      │
      ││Error│ │Success│             │     │     │      │
      ││Msg  │ │Message│             │     │     │      │
      │└──┬──┘ └──┬──┘               │     │     │      │
      │   │       │                  │     │     │      │
      └───┼───────┼──────────────────┼─────┼─────┼──────┘
          │       │                  │     │     │
          └───────┼──────────────────┼─────┼─────┘
                  │                  │     │
                  ▼                  │     │
            ◆─────────◆              │     │
           ╱           ╲             │     │
          ╱ Continue?   ╲            │     │
         ◆─────────────◆             │     │
         │             │             │     │
        YES           NO             │     │
         │             │             │     │
         └─────────────┼─────────────┼─────┘
                       │             │
                       ▼             │
                 ┌─────────┐         │
                 │ LOGOUT  │         │
                 └─────────┘         │
                                     │
         ┌───────────────────────────┘
         │
         ▼
   ◆─────────◆
  ╱           ╲
 ╱   Order     ╲
╱  Management? ╲
◆─────────────◆
│             │
▼             ▼
[Similar decision tree for Order Management - Department Restricted]

   ◆─────────◆
  ╱           ╲
 ╱  Discount   ╲
╱    Codes?    ╲
◆─────────────◆
│             │
▼             ▼
[Similar decision tree for Discount Management - Department Restricted]
```
│  ├─ Edit Products (Own Dept)        ├─ Update Order Status      │
│  ├─ Delete Products (Own Dept)      ├─ Process Payments         │
│  ├─ Manage Stock Levels             ├─ Manage Order Queue       │
│  └─ Manage Size Variants            └─ Generate Order Reports   │
│                                     USER MANAGEMENT             │
│  DISCOUNT MANAGEMENT                ├─ View Department Users    │
│  ├─ Create Dept Discount Codes      ├─ Manage Student Accounts  │
│  ├─ Edit Own Discount Codes         └─ Handle User Inquiries    │
│  ├─ Set Usage Limits                                            │
│  └─ Track Code Usage                REPORTING & ANALYTICS       │
│                                     ├─ Department Sales Reports │
│  NOTIFICATION MANAGEMENT            ├─ Product Performance      │
│  ├─ Send Order Updates              ├─ Customer Analytics       │
│  ├─ Product Notifications           └─ Revenue Tracking         │
│  ├─ Department Announcements                                    │
│  └─ Customer Communications         DEPARTMENT SETTINGS         │
│                                     ├─ Update Department Info   │
│                                     ├─ Manage Department Logo   │
│                                     └─ Configure Preferences    │
└─────────────────────────────────────────────────────────────────┘
```

### Admin Scope & Capabilities

**✅ DEPARTMENT-LEVEL PERMISSIONS:**
- **Product Management**: Full CRUD operations for products within assigned department
- **Order Management**: View and manage orders for department products only
- **User Management**: View and assist users within their department
- **Discount Management**: Create and manage discount codes for their department
- **Reporting**: Access to department-specific sales and analytics reports
- **Notifications**: Send notifications related to department activities

**🔧 SPECIFIC CAPABILITIES:**
- Update order status for department orders
- Create department-specific discount codes
- Generate department sales reports
- Manage department product inventory
- Handle customer inquiries for department products

### Admin Limitations

**❌ RESTRICTIONS:**
- **Department Boundary**: Cannot access or manage other departments' data
- **User Role Management**: Cannot grant/revoke admin or super admin privileges
- **System Settings**: Cannot modify system-wide configurations
- **Cross-Department Access**: Cannot view orders or products from other departments
- **Global Analytics**: Cannot access system-wide reports or analytics
- **Department Creation**: Cannot create or delete departments
- **User Creation**: Cannot create new user accounts (limited to managing existing users)

---

## 🟢 STUDENT/USER ROLE

### Decision-Based Flowchart: Student/User Workflow

```
        ┌─────────────────┐
        │   START: Home   │
        │     Screen      │
        └─────────┬───────┘
                  │
                  ▼
            ◆─────────────◆
           ╱               ╲
          ╱ User Logged In? ╲
         ╱                  ╲
        ◆────────────────────◆
        │                    │
       NO│                   │YES
        │                    │
        ▼                    ▼
┌─────────────┐    ┌─────────────────┐
│ Guest Mode  │    │   User Home     │
│ (Limited)   │    │    Screen       │
└─────┬───────┘    └─────────┬───────┘
      │                      │
      │                      ▼
      │            ┌─────────────────┐
      │            │ Navigation Menu │
      │            │   Selection     │
      │            └─────────┬───────┘
      │                      │
      │                      ▼
      │                ◆─────────────◆
      │               ╱               ╲
      │              ╱ Which Action?  ╲
      │             ╱                 ╲
      │            ◆───────────────────◆
      │            │    │    │    │    │
      │            │    │    │    │    │
      │            ▼    ▼    ▼    ▼    ▼
      │    ┌─────────┐ ┌───┐ ┌───┐ ┌───┐ ┌─────┐
      │    │ Browse  │ │Sho│ │Ord│ │Pro│ │Help │
      │    │Products │ │pCa│ │ers│ │fil│ │Supp │
      │    └────┬────┘ └─┬─┘ └─┬─┘ └─┬─┘ └──┬──┘
      │         │        │     │     │      │
      │         ▼        │     │     │      │
      │   ◆─────────◆    │     │     │      │
      │  ╱           ╲   │     │     │      │
      │ ╱ Select      ╲  │     │     │      │
      │╱  Product?     ╲ │     │     │      │
      │◆───────────────◆ │     │     │      │
      ││               │ │     │     │      │
      ││               │ │     │     │      │
      │▼               ▼ │     │     │      │
      │┌─────────────────┐│     │     │      │
      ││ Product Details ││     │     │      │
      ││     Page        ││     │     │      │
      │└─────────┬───────┘│     │     │      │
      │          │        │     │     │      │
      │          ▼        │     │     │      │
      │    ◆─────────◆    │     │     │      │
      │   ╱           ╲   │     │     │      │
      │  ╱ Add to Cart? ╲ │     │     │      │
      │ ◆─────────────◆   │     │     │      │
      │ │             │   │     │     │      │
      │YES           NO   │     │     │      │
      │ │             │   │     │     │      │
      │ ▼             ▼   │     │     │      │
      │┌───────┐ ┌───────┐│     │     │      │
      ││Add to │ │Continue││     │     │      │
      ││ Cart  │ │Browse ││     │     │      │
      │└───┬───┘ └───────┘│     │     │      │
      │    │              │     │     │      │
      │    ▼              │     │     │      │
      │┌───────────────┐  │     │     │      │
      ││ Update Cart   │  │     │     │      │
      ││   Counter     │  │     │     │      │
      │└───────┬───────┘  │     │     │      │
      │        │          │     │     │      │
      └────────┼──────────┼─────┼─────┼──────┘
               │          │     │     │
               └──────────┼─────┼─────┘
                          │     │
                          ▼     │
                    ◆─────────◆ │
                   ╱           ╲│
                  ╱ View Cart?  ╲
                 ◆─────────────◆│
                 │             ││
                YES           NO│
                 │             ││
                 ▼             ▼│
           ┌─────────┐ ┌─────────┐
           │Shopping │ │Continue │
           │  Cart   │ │Shopping │
           └────┬────┘ └─────────┘
                │
                ▼
          ◆─────────◆
         ╱           ╲
        ╱ Checkout?   ╲
       ◆─────────────◆
       │             │
      YES           NO
       │             │
       ▼             ▼
 ┌─────────┐   ┌─────────┐
 │Checkout │   │Continue │
 │Process  │   │Shopping │
 └────┬────┘   └─────────┘
      │
      ▼
◆─────────────◆
╱             ╲
╱ Login Required ╲
╱  for Checkout? ╲
◆───────────────◆
│               │
YES            NO
│               │
▼               ▼
┌─────────┐ ┌─────────┐
│ Login   │ │ Guest   │
│ Screen  │ │Checkout │
└────┬────┘ └────┬────┘
     │           │
     └─────┬─────┘
           │
           ▼
     ◆─────────◆
    ╱           ╲
   ╱ Payment     ╲
  ╱  Successful? ╲
 ◆─────────────◆
 │             │
YES           NO
 │             │
 ▼             ▼
┌─────────┐ ┌─────────┐
│ Order   │ │ Payment │
│Confirmed│ │ Failed  │
└─────────┘ └─────────┘
```
│  ├─ Filter by Price Range           ├─ Upload Payment Receipts  │
│  ├─ View Product Details            └─ Download Order Receipts  │
│  ├─ Check Stock Availability                                    │
│  └─ View Product Images             SHOPPING CART               │
│                                     ├─ Add Products to Cart     │
│  ACCOUNT MANAGEMENT                 ├─ Update Quantities        │
│  ├─ Update Profile Information      ├─ Remove Items from Cart   │
│  ├─ Change Password                 ├─ Apply Discount Codes     │
│  ├─ Manage Email Preferences        └─ Proceed to Checkout      │
│  └─ View Account Activity                                       │
│                                     NOTIFICATIONS               │
│  RESERVATIONS (if available)        ├─ Order Status Updates     │
│  ├─ Reserve Items                   ├─ Product Availability     │
│  ├─ View Reservations               ├─ Department Announcements │
│  ├─ Cancel Reservations             └─ Promotional Offers       │
│  └─ Convert to Orders                                           │
└─────────────────────────────────────────────────────────────────┘
```

### Student/User Scope & Capabilities

**✅ CUSTOMER-LEVEL PERMISSIONS:**
- **Product Browsing**: View all available products across all departments
- **Order Placement**: Create orders for available products
- **Order Tracking**: Monitor status of their own orders
- **Profile Management**: Update personal information and preferences
- **Shopping Cart**: Manage items before checkout
- **Payment**: Upload payment receipts and proof of payment
- **Notifications**: Receive updates about orders and products

**🔧 SPECIFIC CAPABILITIES:**
- Browse products with search and filter functionality
- Add products to shopping cart and manage quantities
- Place orders with size and quantity selection
- Upload payment receipts for order processing
- Track order status from pending to completion
- Apply discount codes during checkout
- View order history and download receipts
- Receive notifications about order updates

### Student/User Limitations

**❌ RESTRICTIONS:**
- **No Administrative Access**: Cannot access any administrative functions
- **Read-Only Product Data**: Cannot create, edit, or delete products
- **Order Management**: Can only view and manage their own orders
- **User Management**: Cannot view or manage other users' accounts
- **System Access**: No access to system settings or configurations
- **Reporting**: Cannot access sales reports or analytics
- **Discount Creation**: Cannot create or manage discount codes
- **Department Management**: No access to department administration
- **Inventory Management**: Cannot modify stock levels or product availability
- **Order Processing**: Cannot update order status or process payments for others

---

## 🔄 ROLE TRANSITION WORKFLOWS

### Role Elevation Process

```
┌─────────────────┐    Grant Admin    ┌─────────────────┐    Grant SuperAdmin    ┌─────────────────┐
│     STUDENT     │ ───────────────► │      ADMIN      │ ────────────────────► │   SUPERADMIN    │
│                 │                  │                 │                       │                 │
│ • Basic Access  │                  │ • Dept Access   │                       │ • Full Access   │
│ • Own Orders    │                  │ • Dept Products │                       │ • All Depts     │
│ • Browse Only   │                  │ • Dept Orders   │                       │ • All Users     │
└─────────────────┘                  └─────────────────┘                       └─────────────────┘
         ▲                                      ▲                                         ▲
         │                                      │                                         │
         │ Revoke Admin                         │ Revoke SuperAdmin                       │
         └──────────────────────────────────────┘                                         │
         │                                                                                │
         │ Revoke SuperAdmin (Direct to Student)                                         │
         └────────────────────────────────────────────────────────────────────────────────┘
```

### Permission Inheritance

```
SUPERADMIN PERMISSIONS
├─ All Admin Permissions
│  ├─ All Student Permissions
│  │  ├─ Browse Products
│  │  ├─ Place Orders
│  │  ├─ View Own Orders
│  │  └─ Manage Profile
│  ├─ Manage Department Products
│  ├─ Manage Department Orders
│  ├─ Department Analytics
│  └─ Department User Management
├─ Cross-Department Access
├─ User Role Management
├─ System Administration
└─ Global Analytics & Reporting
```

---

## 🛡️ SECURITY & ACCESS CONTROL

### Authentication Flow
1. **Login Validation**: Email/password verification
2. **Role Detection**: System identifies user role from database
3. **Session Creation**: UserSession object created with role-specific permissions
4. **Route Protection**: Middleware validates access to protected routes
5. **UI Rendering**: Interface adapts based on user role and permissions

### Permission Validation
- **Frontend**: UserSession class methods (isSuperAdmin, isAdmin, isStudent)
- **Backend**: User model methods with matching validation logic
- **Middleware**: Role-based route protection and department access control
- **API Endpoints**: Permission checks before data access or modification

### Department Access Control
```php
// Backend Logic
public function canManageDepartment(int $deptId): bool
{
    if ($this->isSuperAdmin()) return true;           // SuperAdmin: All departments
    if ($this->isAdmin() && $this->department_id == $deptId) return true;  // Admin: Own department only
    return false;                                     // Student: No departments
}
```

---

## 📊 ROLE COMPARISON MATRIX

| Feature | Student | Admin | SuperAdmin |
|---------|---------|-------|------------|
| Browse Products | ✅ All | ✅ All | ✅ All |
| Place Orders | ✅ Own | ✅ Own | ✅ Own |
| View Orders | ✅ Own Only | ✅ Department | ✅ All |
| Manage Products | ❌ | ✅ Department | ✅ All |
| User Management | ❌ | ✅ Limited | ✅ Full |
| Department Management | ❌ | ❌ | ✅ Full |
| System Settings | ❌ | ❌ | ✅ Full |
| Analytics/Reports | ❌ | ✅ Department | ✅ All |
| Discount Codes | ❌ | ✅ Department | ✅ All |
| Role Management | ❌ | ❌ | ✅ Full |

---

## 📊 IPO (INPUT-PROCESS-OUTPUT) FLOWCHARTS

### 🔴 SUPER ADMIN IPO FLOWCHART

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    INPUTS                                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│ • Login Credentials (Email/Password)                                           │
│ • User Management Data (Create/Edit/Delete Users)                              │
│ • Department Information (Name, Description, Logo)                             │
│ • Product Data (Name, Price, Description, Images, Stock)                       │
│ • Order Management Commands (Status Updates, Processing)                       │
│ • System Configuration Settings                                                │
│ • Discount Code Parameters (Code, Percentage, Validity)                        │
│ • Report Generation Requests (Date Range, Department Filter)                   │
│ • Role Assignment Data (User ID, Role Type, Department)                        │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                  PROCESSES                                      │
├─────────────────────────────────────────────────────────────────────────────────┤
│ 🔐 AUTHENTICATION & AUTHORIZATION                                              │
│   ├─ Validate login credentials                                                │
│   ├─ Create secure session with superadmin privileges                          │
│   └─ Verify access permissions for each operation                              │
│                                                                                 │
│ 👥 USER MANAGEMENT PROCESSING                                                  │
│   ├─ Create new user accounts with role assignment                             │
│   ├─ Update user information and permissions                                   │
│   ├─ Delete user accounts with data cleanup                                    │
│   └─ Grant/revoke admin and superadmin privileges                              │
│                                                                                 │
│ 🏢 DEPARTMENT MANAGEMENT PROCESSING                                            │
│   ├─ Create new departments with configuration                                 │
│   ├─ Update department information and settings                                │
│   ├─ Delete departments with data migration                                    │
│   └─ Assign admins to departments                                              │
│                                                                                 │
│ 📦 PRODUCT MANAGEMENT PROCESSING                                               │
│   ├─ Create products across all departments                                    │
│   ├─ Update product information and pricing                                    │
│   ├─ Manage inventory levels and stock                                         │
│   └─ Delete products with order history preservation                           │
│                                                                                 │
│ 📋 ORDER MANAGEMENT PROCESSING                                                 │
│   ├─ View and process orders from all departments                              │
│   ├─ Update order status and tracking information                              │
│   ├─ Handle payment verification and processing                                │
│   └─ Generate order reports and analytics                                      │
│                                                                                 │
│ 🎫 DISCOUNT CODE PROCESSING                                                    │
│   ├─ Create discount codes for all departments                                 │
│   ├─ Set usage limits and validity periods                                     │
│   ├─ Track code usage and effectiveness                                        │
│   └─ Deactivate or modify existing codes                                       │
│                                                                                 │
│ 📊 ANALYTICS & REPORTING PROCESSING                                            │
│   ├─ Generate comprehensive sales reports                                      │
│   ├─ Analyze cross-department performance                                      │
│   ├─ Create user activity and engagement reports                               │
│   └─ Process system-wide analytics data                                        │
│                                                                                 │
│ ⚙️ SYSTEM ADMINISTRATION PROCESSING                                            │
│   ├─ Configure system-wide settings                                            │
│   ├─ Manage notification templates and delivery                                │
│   ├─ Handle system maintenance and updates                                     │
│   └─ Monitor system performance and security                                   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   OUTPUTS                                      │
├─────────────────────────────────────────────────────────────────────────────────┤
│ 🖥️ DASHBOARD & UI OUTPUTS                                                     │
│   ├─ Superadmin dashboard with all system metrics                              │
│   ├─ Navigation menu with full access options                                  │
│   ├─ Real-time notifications and alerts                                        │
│   └─ Role-specific interface elements                                          │
│                                                                                 │
│ 📊 REPORTS & ANALYTICS OUTPUTS                                                 │
│   ├─ Comprehensive sales reports (all departments)                             │
│   ├─ User activity and engagement analytics                                    │
│   ├─ Product performance metrics                                               │
│   ├─ Revenue and financial summaries                                           │
│   └─ System usage and performance reports                                      │
│                                                                                 │
│ 📧 NOTIFICATIONS & COMMUNICATIONS                                              │
│   ├─ System-wide announcements                                                 │
│   ├─ User role change notifications                                            │
│   ├─ Department creation/modification alerts                                   │
│   ├─ Critical system alerts and warnings                                       │
│   └─ Automated email confirmations                                             │
│                                                                                 │
│ 💾 DATA MANAGEMENT OUTPUTS                                                     │
│   ├─ Updated user records and permissions                                      │
│   ├─ Modified department configurations                                        │
│   ├─ Product catalog updates                                                   │
│   ├─ Order status modifications                                                │
│   └─ System configuration changes                                              │
│                                                                                 │
│ 🔒 SECURITY & AUDIT OUTPUTS                                                   │
│   ├─ Audit logs for all administrative actions                                 │
│   ├─ Security event notifications                                              │
│   ├─ Access control confirmations                                              │
│   └─ Permission change documentation                                           │
│                                                                                 │
│ ✅ SUCCESS/ERROR MESSAGES                                                      │
│   ├─ Operation completion confirmations                                        │
│   ├─ Error messages with detailed descriptions                                 │
│   ├─ Validation feedback for form submissions                                  │
│   └─ System status updates                                                     │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

### 🟡 ADMIN IPO FLOWCHART

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    INPUTS                                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│ • Login Credentials (Email/Password)                                           │
│ • Department-Specific Product Data (Name, Price, Description, Images)          │
│ • Order Management Data (Status Updates, Processing Commands)                  │
│ • Department User Information (Student Account Details)                        │
│ • Discount Code Creation Data (Code, Percentage, Department Scope)             │
│ • Report Generation Requests (Department-Specific Date Ranges)                 │
│ • Inventory Management Data (Stock Levels, Product Availability)               │
│ • Customer Communication Content (Notifications, Announcements)                │
│ • Department Settings (Logo, Information, Preferences)                         │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                  PROCESSES                                      │
├─────────────────────────────────────────────────────────────────────────────────┤
│ 🔐 AUTHENTICATION & DEPARTMENT VALIDATION                                      │
│   ├─ Validate admin login credentials                                          │
│   ├─ Verify department assignment and permissions                              │
│   ├─ Create session with department-specific access                            │
│   └─ Enforce department boundary restrictions                                  │
│                                                                                 │
│ 📦 DEPARTMENT PRODUCT MANAGEMENT                                               │
│   ├─ Create products within assigned department only                           │
│   ├─ Update department product information and pricing                         │
│   ├─ Manage department inventory and stock levels                              │
│   └─ Delete department products with order validation                          │
│                                                                                 │
│ 📋 DEPARTMENT ORDER PROCESSING                                                 │
│   ├─ View orders for department products only                                  │
│   ├─ Update order status for department orders                                 │
│   ├─ Process payments for department transactions                              │
│   ├─ Handle customer inquiries for department orders                           │
│   └─ Generate department-specific order reports                                │
│                                                                                 │
│ 👥 LIMITED USER MANAGEMENT                                                     │
│   ├─ View student users within department scope                                │
│   ├─ Assist students with account-related issues                               │
│   ├─ Handle customer service for department users                              │
│   └─ Manage student account status (limited scope)                             │
│                                                                                 │
│ 🎫 DEPARTMENT DISCOUNT MANAGEMENT                                              │
│   ├─ Create discount codes for department products only                        │
│   ├─ Set usage limits for department-specific codes                            │
│   ├─ Track department discount code effectiveness                              │
│   └─ Modify or deactivate department discount codes                            │
│                                                                                 │
│ 📊 DEPARTMENT ANALYTICS PROCESSING                                             │
│   ├─ Generate department-specific sales reports                                │
│   ├─ Analyze department product performance                                    │
│   ├─ Process department customer analytics                                     │
│   └─ Create department revenue summaries                                       │
│                                                                                 │
│ 📧 DEPARTMENT COMMUNICATION PROCESSING                                         │
│   ├─ Send department-specific notifications                                    │
│   ├─ Create department announcements                                           │
│   ├─ Handle customer communications for department                             │
│   └─ Process order update notifications                                        │
│                                                                                 │
│ ⚙️ DEPARTMENT SETTINGS MANAGEMENT                                              │
│   ├─ Update department information and preferences                             │
│   ├─ Manage department logo and branding                                       │
│   ├─ Configure department-specific settings                                    │
│   └─ Handle department operational preferences                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   OUTPUTS                                      │
├─────────────────────────────────────────────────────────────────────────────────┤
│ 🖥️ DEPARTMENT DASHBOARD OUTPUTS                                               │
│   ├─ Admin dashboard with department-specific metrics                          │
│   ├─ Department navigation menu with limited access                            │
│   ├─ Department-focused notifications and alerts                               │
│   └─ Role-appropriate interface elements                                       │
│                                                                                 │
│ 📊 DEPARTMENT REPORTS & ANALYTICS                                              │
│   ├─ Department-specific sales reports                                         │
│   ├─ Department product performance metrics                                    │
│   ├─ Department customer analytics                                             │
│   ├─ Department revenue summaries                                              │
│   └─ Department inventory reports                                              │
│                                                                                 │
│ 📧 DEPARTMENT COMMUNICATIONS                                                   │
│   ├─ Department-specific announcements                                         │
│   ├─ Order status update notifications                                         │
│   ├─ Product availability alerts                                               │
│   ├─ Department promotional communications                                     │
│   └─ Customer service responses                                                │
│                                                                                 │
│ 💾 DEPARTMENT DATA UPDATES                                                     │
│   ├─ Updated department product catalog                                        │
│   ├─ Modified department order statuses                                        │
│   ├─ Department inventory level changes                                        │
│   ├─ Department discount code configurations                                   │
│   └─ Department settings modifications                                         │
│                                                                                 │
│ 🔒 DEPARTMENT AUDIT OUTPUTS                                                   │
│   ├─ Department-specific audit logs                                            │
│   ├─ Department access control records                                         │
│   ├─ Department operation confirmations                                        │
│   └─ Department permission validation logs                                     │
│                                                                                 │
│ ⚠️ ACCESS RESTRICTION MESSAGES                                                 │
│   ├─ Cross-department access denial notifications                              │
│   ├─ Permission boundary enforcement messages                                  │
│   ├─ Department-specific error messages                                        │
│   └─ Limited access scope confirmations                                        │
│                                                                                 │
│ ✅ DEPARTMENT SUCCESS/ERROR MESSAGES                                           │
│   ├─ Department operation completion confirmations                             │
│   ├─ Department-specific error descriptions                                    │
│   ├─ Department form validation feedback                                       │
│   └─ Department system status updates                                          │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

### 🟢 STUDENT/USER IPO FLOWCHART (Simplified)

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    INPUTS                                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│ • Login Credentials (Email/Password)                                           │
│ • Product Search (Keywords, Filters)                                           │
│ • Shopping Cart Actions (Add/Remove Items)                                     │
│ • Order Data (Product, Size, Quantity)                                         │
│ • Payment Receipt Upload                                                        │
│ • Profile Information Updates                                                   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                  PROCESSES                                      │
├─────────────────────────────────────────────────────────────────────────────────┤
│ 🔐 LOGIN & AUTHENTICATION                                                      │
│   └─ Validate credentials and create user session                              │
│                                                                                 │
│ 🔍 BROWSE & SEARCH PRODUCTS                                                    │
│   └─ Find and view products from all departments                               │
│                                                                                 │
│ 🛒 MANAGE SHOPPING CART                                                        │
│   └─ Add/remove items and calculate totals                                     │
│                                                                                 │
│ 📋 PLACE ORDERS                                                                │
│   └─ Create order and generate order number                                    │
│                                                                                 │
│ 💳 PROCESS PAYMENTS                                                            │
│   └─ Upload receipt and verify payment                                         │
│                                                                                 │
│ 📦 TRACK ORDERS                                                                │
│   └─ View order status and history                                             │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   OUTPUTS                                      │
├─────────────────────────────────────────────────────────────────────────────────┤
│ 🖥️ USER INTERFACE                                                             │
│   ├─ Home screen with product categories                                       │
│   ├─ Product catalog with search                                               │
│   ├─ Shopping cart and checkout                                                │
│   └─ Order history and tracking                                                │
│                                                                                 │
│ 📦 ORDER INFORMATION                                                           │
│   ├─ Order confirmations                                                       │
│   ├─ Order status updates                                                      │
│   └─ Payment receipts                                                          │
│                                                                                 │
│ 📧 NOTIFICATIONS                                                               │
│   ├─ Order status changes                                                      │
│   ├─ Payment confirmations                                                     │
│   └─ Product availability alerts                                               │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

### 🔄 USER SYSTEM FLOW (Decision-Based)

```
                                    ┌─────────────┐
                                    │    START    │
                                    │   (User)    │
                                    └──────┬──────┘
                                           │
                                           ▼
                                    ┌─────────────┐
                                    │ Open Merch  │
                                    │ Hub App     │
                                    └──────┬──────┘
                                           │
                                           ▼
                                      ◆─────────◆
                                     ╱           ╲
                                    ╱ Registered? ╲
                                   ╱               ╲
                                  ◆─────────────────◆
                                 ╱         │         ╲
                               No          │          Yes
                               │           │           │
                               ▼           │           ▼
                        ┌─────────────┐    │    ┌─────────────┐
                        │ Registration│    │    │    Login    │
                        │   Process   │    │    │   Screen    │
                        └──────┬──────┘    │    └──────┬──────┘
                               │           │           │
                               │           │           ▼
                               │           │      ◆─────────◆
                               │           │     ╱           ╲
                               │           │    ╱ Forgot      ╲
                               │           │   ╱  Password?    ╲
                               │           │  ◆─────────────────◆
                               │           │ ╱         │         ╲
                               │           │No         │          Yes
                               │           ││          │           │
                               └───────────┼┼──────────┘           ▼
                                           ││                ┌─────────────┐
                                           ▼▼                │   Request   │
                                    ┌─────────────┐          │ New Password│
                                    │    Home     │          └──────┬──────┘
                                    │   Screen    │                 │
                                    └──────┬──────┘                 │
                                           │                        │
                                           ▼                        │
                                      ◆─────────◆                   │
                                     ╱           ╲                  │
                                    ╱ Browse or   ╲                 │
                                   ╱   Search?     ╲                │
                                  ◆─────────────────◆               │
                                 ╱         │         ╲              │
                              Browse       │        Search          │
                               │           │           │            │
                               ▼           │           ▼            │
                        ┌─────────────┐    │    ┌─────────────┐     │
                        │   Browse    │    │    │   Search    │     │
                        │  Products   │    │    │  Products   │     │
                        └──────┬──────┘    │    └──────┬──────┘     │
                               │           │           │            │
                               └───────────┼───────────┘            │
                                           │                        │
                                           ▼                        │
                                    ┌─────────────┐                 │
                                    │   Product   │                 │
                                    │   Details   │                 │
                                    └──────┬──────┘                 │
                                           │                        │
                                           ▼                        │
                                      ◆─────────◆                   │
                                     ╱           ╲                  │
                                    ╱ Add to      ╲                 │
                                   ╱   Cart?       ╲                │
                                  ◆─────────────────◆               │
                                 ╱         │         ╲              │
                               No          │          Yes           │
                               │           │           │            │
                               │           │           ▼            │
                               │           │    ┌─────────────┐     │
                               │           │    │ Add to Cart │     │
                               │           │    └──────┬──────┘     │
                               │           │           │            │
                               │           │           ▼            │
                               │           │      ◆─────────◆       │
                               │           │     ╱           ╲      │
                               │           │    ╱ Continue    ╲     │
                               │           │   ╱  Shopping?    ╲    │
                               │           │  ◆─────────────────◆   │
                               │           │ ╱         │         ╲  │
                               │           │Yes        │          No│
                               │           ││          │           ││
                               └───────────┼┼──────────┘           ▼▼
                                           ▲▲                ┌─────────────┐
                                           ││                │  Shopping   │
                                           ││                │    Cart     │
                                           ││                └──────┬──────┘
                                           ││                       │
                                           ││                       ▼
                                           ││                  ◆─────────◆
                                           ││                 ╱           ╲
                                           ││                ╱ Proceed to  ╲
                                           ││               ╱   Checkout?   ╲
                                           ││              ◆─────────────────◆
                                           ││             ╱         │         ╲
                                           ││           No          │          Yes
                                           ││           │           │           │
                                           └└───────────┘           │           ▼
                                                                    │    ┌─────────────┐
                                                                    │    │   Checkout  │
                                                                    │    │   Process   │
                                                                    │    └──────┬──────┘
                                                                    │           │
                                                                    │           ▼
                                                                    │    ┌─────────────┐
                                                                    │    │   Upload    │
                                                                    │    │   Receipt   │
                                                                    │    └──────┬──────┘
                                                                    │           │
                                                                    │           ▼
                                                                    │    ┌─────────────┐
                                                                    │    │    Order    │
                                                                    │    │ Confirmation│
                                                                    │    └──────┬──────┘
                                                                    │           │
                                                                    │           ▼
                                                                    │      ◆─────────◆
                                                                    │     ╱           ╲
                                                                    │    ╱ Track Order ╲
                                                                    │   ╱   or Exit?    ╲
                                                                    │  ◆─────────────────◆
                                                                    │ ╱         │         ╲
                                                                    │Track      │          Exit
                                                                    ││          │           │
                                                                    ▼▼          │           ▼
                                                             ┌─────────────┐    │    ┌─────────────┐
                                                             │    Order    │    │    │     END     │
                                                             │   Tracking  │    │    └─────────────┘
                                                             └──────┬──────┘    │
                                                                    │           │
                                                                    └───────────┘
│   └─ Related product recommendations                                           │
│                                                                                 │
│ 🛒 SHOPPING & ORDER OUTPUTS                                                    │
│   ├─ Updated shopping cart with current items                                  │
│   ├─ Order confirmation with details and tracking                              │
│   ├─ Payment receipts and transaction records                                  │
│   ├─ Order status updates and notifications                                    │
│   ├─ Shipping and delivery information                                         │
│   └─ Order history with downloadable receipts                                  │
│                                                                                 │
│ 📧 NOTIFICATIONS & COMMUNICATIONS                                              │
│   ├─ Order confirmation emails                                                 │
│   ├─ Order status update notifications                                         │
│   ├─ Product availability alerts                                               │
│   ├─ Promotional offers and discount notifications                             │
│   ├─ Account security and verification messages                                │
│   └─ Customer support response communications                                  │
│                                                                                 │
│ 💾 PERSONAL DATA OUTPUTS                                                       │
│   ├─ Updated user profile information                                          │
│   ├─ Saved shopping preferences and favorites                                  │
│   ├─ Order history and transaction records                                     │
│   ├─ Payment method and billing information                                    │
│   ├─ Notification preference settings                                          │
│   └─ Account activity and security logs                                        │
│                                                                                 │
│ ⚠️ USER FEEDBACK & ERROR MESSAGES                                              │
│   ├─ Form validation errors and guidance                                       │
│   ├─ Product availability notifications                                        │
│   ├─ Payment processing status messages                                        │
│   ├─ Account access and authentication feedback                                │
│   ├─ Shopping cart and checkout error messages                                 │
│   └─ System maintenance and service notifications                              │
│                                                                                 │
│ ✅ SUCCESS CONFIRMATIONS                                                       │
│   ├─ Successful login and authentication confirmations                         │
│   ├─ Product added to cart confirmations                                       │
│   ├─ Order placement success messages                                          │
│   ├─ Payment processing confirmations                                          │
│   ├─ Profile update success notifications                                      │
│   └─ Account action completion confirmations                                   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 ADMIN ROLE FLOWCHART

### Admin Authentication & Management Flow
```
┌─────────────────┐
│     START       │
│   Admin Login   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Enter Email &   │
│   Password      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Authenticate    │
│  Credentials    │
└────────┬────────┘
         │
         ▼
    ◆─────────◆
   ╱           ╲
  ╱  Valid      ╲
 ╱ Credentials?  ╲
◆─────────────────◆
╱         │        ╲
No        │        Yes
│         │         │
▼         │         ▼
┌─────────────────┐   ┌─────────────────┐
│ Show Error      │   │ Check Admin     │
│  Message        │   │    Role         │
└─────────────────┘   └────────┬────────┘
                               │
                               ▼
                          ◆─────────◆
                         ╱           ╲
                        ╱   Admin?    ╲
                       ╱               ╲
                      ◆─────────────────◆
                     ╱         │         ╲
                   No          │         Yes
                   │           │          │
                   ▼           │          ▼
            ┌─────────────────┐   ┌─────────────────┐
            │ Access Denied   │   │   Admin         │
            │ Invalid Role    │   │  Dashboard      │
            └─────────────────┘   └────────┬────────┘
                                            │
                                            ▼
                                     ◆─────────◆
                                    ╱           ╲
                                   ╱  Select     ╲
                                  ╱  Management   ╲
                                 ╱    Option       ╲
                                ◆─────────────────◆
                               ╱         │         ╲
                             Products     │        Orders
                             │            │          │
                             ▼            │          ▼
                    ┌─────────────────┐    │  ┌─────────────────┐
                    │  Products       │    │  │   Orders       │
                    │  Management     │    │  │  Management     │
                    └────────┬────────┘    │  └────────┬────────┘
                             │             │           │
                             ▼             │           ▼
                    ┌─────────────────┐    │  ┌─────────────────┐
                    │ Select Product  │    │  │ Update Order   │
                    │    Action       │    │  │    Status      │
                    └────────┬────────┘    │  └────────┬────────┘
                             │             │           │
                             ▼             │           ▼
                    ◆─────────◆            │  ◆─────────◆
                   ╱           ╲           │ ╱           ╲
                  ╱   Choose    ╲          │╱   Update    ╲
                 ╱    Action     ╲         │    Status    ╲
                ◆─────────────────◆        ◆─────────────────◆
               ╱         │         ╲      ╱         │       ╲
             Add        Edit      Delete │           │        │
             │           │          │    │           │        │
             ▼           ▼          ▼    │           ▼        ▼
    ┌─────────────────┐┌─────────────────┐┌─────────────────┐ │ ┌─────────────────┐
    │   Add Product   ││  Edit Product   ││ Delete Product  │ │ │ Order Status    │
    │   (Create)      ││   (Update)      ││   (Delete)      │ │ │   Updated       │
    └────────┬────────┘└────────┬────────┘└────────┬────────┘ │ └─────────────────┘
             │                  │                   │          │
             └──────────────────┼──────────────────┘          │
                                │                             │
                                ▼                             ▼
                         ┌─────────────────┐           ┌─────────────────┐
                         │ Return to       │           │ Return to       │
                         │ Products Menu   │           │ Orders Menu     │
                         └─────────────────┘           └─────────────────┘
                                │                             │
                                └─────────────┬───────────────┘
                                              │
                                              ▼
                                       ┌─────────────────┐
                                       │ Continue        │
                                       │ Management?     │
                                       └────────┬────────┘
                                              │
                                              ▼
                                        ◆─────────◆
                                       ╱           ╲
                                      ╱    Yes      ╲
                                     ╱               ╲
                                    ◆─────────────────◆
                                   ╱         │         ╲
                                 No          │        Yes
                                 │           │          │
                                 ▼           │          │
                          ┌─────────────────┐│          │
                          │    Logout      ││          │
                          │     END        ││          │
                          └─────────────────┘│          │
                                             ▼          ▼
                                      ┌─────────────────┐
                                      │   Admin         │
                                      │  Dashboard      │
                                      │  (Loop Back)    │
                                      └─────────────────┘
```

### Key Admin Capabilities
- **Products Management**: Full CRUD operations (Create, Read, Update, Delete)
- **Orders Management**: Status update functionality only
- **Role Security**: Strict admin-only access enforcement

---

## 🔴 SUPERADMIN ROLE FLOWCHART

### SuperAdmin Authentication & Management Flow
```
┌─────────────────┐
│     START       │
│ SuperAdmin Login│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Enter Email &   │
│   Password      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Authenticate    │
│  Credentials    │
└────────┬────────┘
         │
         ▼
    ◆─────────◆
   ╱           ╲
  ╱  Valid      ╲
 ╱ Credentials?  ╲
◆─────────────────◆
╱         │        ╲
No        │        Yes
│         │         │
▼         │         ▼
┌─────────────────┐   ┌─────────────────┐
│ Show Error      │   │ Check SuperAdmin│
│  Message        │   │     Role        │
└─────────────────┘   └────────┬────────┘
                              │
                              ▼
                         ◆─────────◆
                        ╱           ╲
                       ╱ SuperAdmin? ╲
                      ╱               ╲
                     ◆─────────────────◆
                    ╱         │         ╲
                  No          │         Yes
                  │           │          │
                  ▼           │          ▼
           ┌─────────────────┐   ┌─────────────────┐
           │ Access Denied   │   │   SuperAdmin    │
           │ Invalid Role    │   │   Dashboard     │
           └─────────────────┘   └────────┬────────┘
                                         │
                                         ▼
                                  ◆─────────◆
                                 ╱           ╲
                                ╱  Select     ╲
                               ╱  Management   ╲
                              ╱    Option       ╲
                             ◆─────────────────◆
                            ╱         │         ╲
                          Users       │        System
                          │           │          │
                          ▼           │          ▼
                 ┌─────────────────┐   │  ┌─────────────────┐
                 │   User          │   │  │   System       │
                 │  Management     │   │  │  Management     │
                 └────────┬────────┘   │  └────────┬────────┘
                          │            │           │
                          ▼            │           ▼
                 ┌─────────────────┐   │  ┌─────────────────┐
                 │ Select User     │   │  │ Select System  │
                 │    Action       │   │  │    Action      │
                 └────────┬────────┘   │  └────────┬────────┘
                          │            │           │
                          ▼            │           ▼
                 ◆─────────◆           │  ◆─────────◆
                ╱           ╲          │ ╱           ╲
               ╱   Choose    ╲         │╱   Choose    ╲
              ╱    Action     ╲        │    Action    ╲
             ◆─────────────────◆       ◆─────────────────◆
            ╱         │         ╲     ╱         │       ╲
          Create     Edit     Delete │           │        │
          │           │          │   │           │        │
          ▼           ▼          ▼   │           ▼        ▼
 ┌─────────────────┐┌─────────────────┐┌─────────────────┐ │ ┌─────────────────┐
 │   Create User   ││   Edit User     ││  Delete User   │ │ │  System        │
 │   (Full Access) ││   (Role/Dept)   ││   (Remove)     │ │ │  Settings      │
 └────────┬────────┘└────────┬────────┘└────────┬────────┘ │ └────────┬────────┘
          │                  │                  │           │          │
          └──────────────────┼──────────────────┘           │          ▼
                             │                              │  ◆─────────◆
                             ▼                              │ ╱           ╲
                    ┌─────────────────┐                     │╱   Choose    ╲
                    │ Return to       │                     │    Action    ╲
                    │ Users Menu      │                     ◆─────────────────◆
                    └─────────────────┘                    ╱         │       ╲
                             │                          Global     Dept     Config
                             │                          │          │          │
                             │                          ▼          ▼          ▼
                             │                  ┌─────────────────┐┌─────────────────┐┌─────────────────┐
                             │                  │   Global        ││  Department    ││  System        │
                             │                  │   Settings      ││  Management     ││  Configuration  │
                             │                  └────────┬────────┘└────────┬────────┘└────────┬────────┘
                             │                           │                  │                  │
                             │                           └──────────────────┼──────────────────┘
                             │                                              │
                             │                                              ▼
                             │                                      ┌─────────────────┐
                             │                                      │ Return to       │
                             │                                      │ System Menu     │
                             │                                      └─────────────────┘
                             │                                              │
                             └──────────────────────────────┬───────────────┘
                                                            │
                                                            ▼
                                                     ┌─────────────────┐
                                                     │ Continue        │
                                                     │ Management?     │
                                                     └────────┬────────┘
                                                            │
                                                            ▼
                                                     ◆─────────◆
                                                    ╱           ╲
                                                   ╱    Yes      ╲
                                                  ╱               ╲
                                                 ◆─────────────────◆
                                                ╱         │         ╲
                                              No          │        Yes
                                              │           │          │
                                              ▼           │          │
                                       ┌─────────────────┐│          │
                                       │    Logout      ││          │
                                       │     END        ││          │
                                       └─────────────────┘│          │
                                                          ▼          ▼
                                                   ┌─────────────────┐
                                                   │   SuperAdmin    │
                                                   │   Dashboard     │
                                                   │   (Loop Back)   │
                                                   └─────────────────┘
```

### Key SuperAdmin Capabilities
- **User Management**: Full CRUD operations on all users (Create, Read, Update, Delete)
- **Role Management**: Grant/revoke admin and superadmin privileges
- **Department Management**: Create, edit, delete departments
- **System Management**: Global settings and configuration
- **Global Access**: Complete access to all departments and data
- **Audit & Reporting**: Comprehensive system analytics and reporting

### SuperAdmin-Specific Features
- **Cross-Department Oversight**: Manage all departments simultaneously
- **Role Elevation**: Promote users to admin/superadmin roles
- **System Configuration**: Modify global system settings
- **Backup & Recovery**: Access system backup and recovery functions
- **Security Management**: Configure security policies and access controls

---

## 🎯 CONCLUSION

The Merch Hub system implements a robust three-tier role-based access control system that ensures:

1. **Security**: Clear separation of permissions and access levels
2. **Scalability**: Easy role management and permission updates
3. **Usability**: Intuitive interfaces tailored to each role's needs
4. **Flexibility**: Department-based organization with cross-department oversight
5. **Auditability**: Clear permission boundaries and access logging

Each role is designed to serve specific organizational needs while maintaining system security and data integrity. The IPO flowcharts demonstrate the clear data flow and processing boundaries for each role, ensuring efficient system operation and user experience.