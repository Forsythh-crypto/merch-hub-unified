# UDD Merch Hub System Flowchart

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           UDD MERCH HUB SYSTEM                                 │
│                        Multi-Department E-commerce Platform                    │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## User Roles & Permissions

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    STUDENT      │    │     ADMIN       │    │  SUPERADMIN     │
│                 │    │                 │    │                 │
│ • Browse Items  │    │ • Manage Dept   │    │ • Manage All    │
│ • Place Orders  │    │ • Approve Items │    │ • Approve All   │
│ • View Orders   │    │ • Manage Orders │    │ • Manage Users  │
│ • Upload Receipt│    │ • View Reports  │    │ • System Admin  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Order Flow Process

### 1. Order Creation Flow
```
┌─────────────────┐
│   User Login    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Browse Products │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Select Product  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Order Confirmation│
│ • Uses registered│
│   email         │
│ • Calculate 35% │
│   reservation   │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Create Order    │
│ Status: PENDING │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Send Email:     │
│ "Order          │
│ Confirmation"   │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Send Notifications│
│ • Superadmin    │
│ • Dept Admin    │
│ • User          │
└─────────────────┘
```

### 2. Payment & Confirmation Flow
```
┌─────────────────┐
│ GCash QR Code  │
│ Payment Screen  │
│ (20% Reservation│
│  Fee)          │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Upload Receipt  │
│ (Can be done    │
│  later in       │
│  My Orders)     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Admin/Super     │
│ Reviews Receipt │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Confirm Payment │
│ Status: CONFIRMED│
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Send Email:     │
│ "Order          │
│ Confirmed"      │
└─────────────────┘
```

### 3. Fulfillment Flow
```
┌─────────────────┐
│ Admin Prepares  │
│ Order           │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Update Status   │
│ to: READY FOR   │
│ PICKUP          │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Send Email:     │
│ "Ready for      │
│ Pickup"         │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ User Picks Up   │
│ Order & Pays    │
│ Remaining 80%   │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Status:         │
│ COMPLETED       │
└─────────────────┘
```

## Department Management

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPARTMENT STRUCTURE                        │
├─────────────────────────────────────────────────────────────────┤
│ SITE (IT)     │ SBA (Business) │ SOC (Criminology) │ SOE (Eng) │
│ SOHS (Health) │ SOH (Humanities)│ SIHM (Hospitality)│ STE (Ed)  │
└─────────────────────────────────────────────────────────────────┘
```

## Admin Workflow

### Department Admin (SITE ADMIN, SBA ADMIN, etc.)
```
┌─────────────────┐
│ Admin Dashboard │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Manage Listings │
│ • View Pending  │
│ • Approve Items │
│ • Update Stock  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Manage Orders   │
│ • View Orders   │
│ • Confirm Payment│
│ • Update Status │
└─────────────────┘
```

### Super Admin
```
┌─────────────────┐
│ Super Admin     │
│ Dashboard       │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Manage All      │
│ • All Listings  │
│ • All Orders    │
│ • All Users     │
│ • All Depts     │
└─────────────────┘
```

## Notification System

```
┌─────────────────┐
│ Order Created   │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Send to:        │
│ • Superadmin    │
│ • Dept Admin    │
│ • User          │
└─────────────────┘
          │
          ▼
┌─────────────────┐
│ Status Change   │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Send to:        │
│ • Superadmin    │
│ • Dept Admin    │
│ • User          │
└─────────────────┘
```

## Email Flow

```
1. ORDER PLACED (PENDING)
   └── "Order Confirmation" Email
       ├── Shows reservation fee (20%)
       ├── Payment instructions
       └── Next steps

2. ADMIN CONFIRMS (CONFIRMED)
   └── "Order Confirmed" Email
       ├── Confirmation message
       ├── Processing status
       └── Pickup instructions

3. READY FOR PICKUP
   └── "Ready for Pickup" Email
       ├── Pickup location
       ├── Remaining balance (80%)
       └── Required documents
```

## Database Structure

```
┌─────────────────┐
│     USERS       │
│ • id, name      │
│ • email, role   │
│ • department_id │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│   LISTINGS      │
│ • id, title     │
│ • price, stock  │
│ • department_id │
│ • status        │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│     ORDERS      │
│ • order_number  │
│ • user_id       │
│ • listing_id    │
│ • status        │
│ • total_amount  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ NOTIFICATIONS   │
│ • type          │
│ • user_id       │
│ • department_id │
│ • is_read       │
└─────────────────┘
```

## Key Features

### 🔐 Authentication & Authorization
- Role-based access control
- Department-specific permissions
- Secure API endpoints

### 📱 User Experience
- Mobile-responsive design
- Real-time notifications
- Intuitive navigation

### 💰 Payment System
- 20% reservation fee via GCash
- 80% remaining on pickup
- Receipt upload system

### 📧 Communication
- Automated email notifications
- In-app notification system
- Status updates

### 📊 Management
- Admin approval workflow
- Order tracking
- Inventory management

## System Benefits

1. **Decentralized Management**: Each department manages their own merchandise
2. **Secure Payments**: Reservation fee system reduces no-shows
3. **Real-time Updates**: Instant notifications for all stakeholders
4. **Scalable Architecture**: Easy to add new departments
5. **User-friendly**: Simple interface for all user types

---

*This flowchart represents the complete UDD Merch Hub system architecture and workflow.*
