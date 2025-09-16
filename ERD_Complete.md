# Merch Hub Unified - Complete Entity Relationship Diagram (ERD)

## Tables and Attributes

### 1. departments
- **id** (PK, AUTO_INCREMENT)
- **name** (VARCHAR, UNIQUE)
- **description** (TEXT, NULLABLE) - added later
- **logo** (VARCHAR, NULLABLE) - added later
- **created_at** (TIMESTAMP)
- **updated_at** (TIMESTAMP)

### 2. users
- **id** (PK, AUTO_INCREMENT)
- **name** (VARCHAR)
- **email** (VARCHAR, UNIQUE)
- **email_verified_at** (TIMESTAMP, NULLABLE)
- **password** (VARCHAR)
- **role** (ENUM: 'student', 'admin', 'superadmin', DEFAULT: 'student')
- **department_id** (FK, NULLABLE)
- **remember_token** (VARCHAR, NULLABLE)
- **created_at** (TIMESTAMP)
- **updated_at** (TIMESTAMP)

### 3. categories
- **id** (PK, AUTO_INCREMENT)
- **name** (VARCHAR, UNIQUE)
- **created_at** (TIMESTAMP)
- **updated_at** (TIMESTAMP)

### 4. products
- **id** (PK, AUTO_INCREMENT)
- **name** (VARCHAR)
- **description** (TEXT, NULLABLE)
- **price** (DECIMAL 8,2)
- **stock** (INTEGER)
- **department_id** (FK)
- **created_at** (TIMESTAMP)
- **updated_at** (TIMESTAMP)

### 5. listings
- **id** (PK, AUTO_INCREMENT)
- **title** (VARCHAR)
- **description** (TEXT, NULLABLE)
- **image_path** (VARCHAR, NULLABLE)
- **department_id** (FK)
- **category_id** (FK)
- **user_id** (FK) - uploader
- **price** (DECIMAL 8,2)
- **size** (VARCHAR, NULLABLE)
- **status** (VARCHAR, NULLABLE) - added later
- **stock** (INTEGER, NULLABLE) - added later
- **images** (JSON, NULLABLE) - added later
- **created_at** (TIMESTAMP)
- **updated_at** (TIMESTAMP)

### 6. listing_size_variants
- **id** (PK, AUTO_INCREMENT)
- **listing_id** (FK)
- **size** (VARCHAR)
- **stock_quantity** (INTEGER, DEFAULT: 0)
- **created_at** (TIMESTAMP)
- **updated_at** (TIMESTAMP)
- **UNIQUE(listing_id, size)**

### 7. listing_images
- **id** (PK, AUTO_INCREMENT)
- **listing_id** (FK)
- **image_path** (VARCHAR)
- **sort_order** (INTEGER, DEFAULT: 0)
- **created_at** (TIMESTAMP)
- **updated_at** (TIMESTAMP)

### 8. discount_codes
- **id** (PK, AUTO_INCREMENT)
- **code** (VARCHAR, UNIQUE)
- **type** (ENUM: 'percentage', 'fixed')
- **value** (DECIMAL 8,2)
- **description** (TEXT, NULLABLE)
- **created_by** (FK to users)
- **department_id** (FK, NULLABLE)
- **is_udd_official** (BOOLEAN, DEFAULT: false)
- **usage_limit** (INTEGER, NULLABLE)
- **usage_count** (INTEGER, DEFAULT: 0)
- **minimum_order_amount** (DECIMAL 8,2, NULLABLE)
- **valid_from** (DATETIME, NULLABLE)
- **valid_until** (DATETIME, NULLABLE)
- **is_active** (BOOLEAN, DEFAULT: true)
- **created_at** (TIMESTAMP)
- **updated_at** (TIMESTAMP)

### 9. orders
- **id** (PK, AUTO_INCREMENT)
- **order_number** (VARCHAR, UNIQUE)
- **user_id** (FK, NULLABLE) - made nullable later
- **email** (VARCHAR, NULLABLE) - added later
- **listing_id** (FK)
- **department_id** (FK)
- **quantity** (INTEGER)
- **size** (VARCHAR 10, NULLABLE) - added later
- **total_amount** (DECIMAL 10,2)
- **reservation_fee_amount** (DECIMAL 10,2, NULLABLE) - added later
- **reservation_fee_paid** (BOOLEAN, DEFAULT: false) - added later
- **payment_receipt_path** (VARCHAR, NULLABLE) - added later
- **discount_code_id** (FK, NULLABLE) - added later
- **discount_amount** (DECIMAL 10,2, DEFAULT: 0) - added later
- **original_amount** (DECIMAL 10,2, NULLABLE) - added later
- **status** (ENUM: 'pending', 'confirmed', 'ready_for_pickup', 'completed', 'cancelled', DEFAULT: 'pending')
- **pickup_date** (DATETIME, NULLABLE)
- **notes** (TEXT, NULLABLE)
- **payment_method** (VARCHAR, DEFAULT: 'cash_on_pickup')
- **email_sent** (BOOLEAN, DEFAULT: false)
- **created_at** (TIMESTAMP)
- **updated_at** (TIMESTAMP)

### 10. reservations
- **id** (PK, AUTO_INCREMENT)
- **user_id** (FK)
- **listing_id** (FK)
- **reserved_at** (TIMESTAMP, DEFAULT: CURRENT_TIMESTAMP)
- **status** (ENUM: 'pending', 'approved', 'cancelled', DEFAULT: 'pending')
- **created_at** (TIMESTAMP)
- **updated_at** (TIMESTAMP)

### 11. notifications
- **id** (PK, AUTO_INCREMENT)
- **type** (VARCHAR) - 'order_created', 'order_status_changed', 'reservation_created'
- **title** (VARCHAR)
- **message** (TEXT)
- **data** (JSON, NULLABLE)
- **user_id** (BIGINT UNSIGNED, NULLABLE)
- **user_role** (VARCHAR, NULLABLE) - 'superadmin', 'admin', 'student'
- **department_id** (BIGINT UNSIGNED, NULLABLE)
- **is_read** (BOOLEAN, DEFAULT: false)
- **read_at** (TIMESTAMP, NULLABLE)
- **created_at** (TIMESTAMP)
- **updated_at** (TIMESTAMP)

### 12. personal_access_tokens
- **id** (PK, AUTO_INCREMENT)
- **tokenable_type** (VARCHAR)
- **tokenable_id** (BIGINT UNSIGNED)
- **name** (VARCHAR)
- **token** (VARCHAR, UNIQUE)
- **abilities** (TEXT, NULLABLE)
- **last_used_at** (TIMESTAMP, NULLABLE)
- **expires_at** (TIMESTAMP, NULLABLE)
- **created_at** (TIMESTAMP)
- **updated_at** (TIMESTAMP)

### 13. password_reset_tokens
- **email** (PK, VARCHAR)
- **token** (VARCHAR)
- **created_at** (TIMESTAMP, NULLABLE)

### 14. sessions
- **id** (PK, VARCHAR)
- **user_id** (FK, NULLABLE)
- **ip_address** (VARCHAR 45, NULLABLE)
- **user_agent** (TEXT, NULLABLE)
- **payload** (LONGTEXT)
- **last_activity** (INTEGER)

### 15. cache
- **key** (PK, VARCHAR)
- **value** (MEDIUMTEXT)
- **expiration** (INTEGER)

### 16. cache_locks
- **key** (PK, VARCHAR)
- **owner** (VARCHAR)
- **expiration** (INTEGER)

### 17. jobs
- **id** (PK, AUTO_INCREMENT)
- **queue** (VARCHAR)
- **payload** (LONGTEXT)
- **attempts** (TINYINT UNSIGNED)
- **reserved_at** (INTEGER UNSIGNED, NULLABLE)
- **available_at** (INTEGER UNSIGNED)
- **created_at** (INTEGER UNSIGNED)

### 18. job_batches
- **id** (PK, VARCHAR)
- **name** (VARCHAR)
- **total_jobs** (INTEGER)
- **pending_jobs** (INTEGER)
- **failed_jobs** (INTEGER)
- **failed_job_ids** (LONGTEXT)
- **options** (MEDIUMTEXT, NULLABLE)
- **cancelled_at** (INTEGER, NULLABLE)
- **created_at** (INTEGER)
- **finished_at** (INTEGER, NULLABLE)

### 19. failed_jobs
- **id** (PK, AUTO_INCREMENT)
- **uuid** (VARCHAR, UNIQUE)
- **connection** (TEXT)
- **queue** (TEXT)
- **payload** (LONGTEXT)
- **exception** (LONGTEXT)
- **failed_at** (TIMESTAMP, DEFAULT: CURRENT_TIMESTAMP)

## Relationships and Verbs

### One-to-Many Relationships

1. **departments** `HAS MANY` **users**
   - departments.id → users.department_id
   - Verb: "Department has many users"
   - Constraint: ON DELETE SET NULL

2. **departments** `HAS MANY` **products**
   - departments.id → products.department_id
   - Verb: "Department has many products"
   - Constraint: ON DELETE CASCADE

3. **departments** `HAS MANY` **listings**
   - departments.id → listings.department_id
   - Verb: "Department has many listings"
   - Constraint: ON DELETE CASCADE

4. **departments** `HAS MANY` **orders**
   - departments.id → orders.department_id
   - Verb: "Department has many orders"
   - Constraint: ON DELETE CASCADE

5. **departments** `HAS MANY` **discount_codes**
   - departments.id → discount_codes.department_id
   - Verb: "Department has many discount codes"
   - Constraint: ON DELETE CASCADE

6. **categories** `HAS MANY` **listings**
   - categories.id → listings.category_id
   - Verb: "Category has many listings"
   - Constraint: ON DELETE CASCADE

7. **users** `HAS MANY` **listings** (as uploader)
   - users.id → listings.user_id
   - Verb: "User uploads many listings"
   - Constraint: ON DELETE CASCADE

8. **users** `HAS MANY` **orders**
   - users.id → orders.user_id
   - Verb: "User places many orders"
   - Constraint: ON DELETE CASCADE

9. **users** `HAS MANY` **reservations**
   - users.id → reservations.user_id
   - Verb: "User makes many reservations"
   - Constraint: ON DELETE CASCADE

10. **users** `HAS MANY` **discount_codes** (as creator)
    - users.id → discount_codes.created_by
    - Verb: "User creates many discount codes"
    - Constraint: ON DELETE CASCADE

11. **listings** `HAS MANY` **orders**
    - listings.id → orders.listing_id
    - Verb: "Listing has many orders"
    - Constraint: ON DELETE CASCADE

12. **listings** `HAS MANY` **reservations**
    - listings.id → reservations.listing_id
    - Verb: "Listing has many reservations"
    - Constraint: ON DELETE CASCADE

13. **listings** `HAS MANY` **listing_size_variants**
    - listings.id → listing_size_variants.listing_id
    - Verb: "Listing has many size variants"
    - Constraint: ON DELETE CASCADE

14. **listings** `HAS MANY` **listing_images**
    - listings.id → listing_images.listing_id
    - Verb: "Listing has many images"
    - Constraint: ON DELETE CASCADE

15. **discount_codes** `HAS MANY` **orders**
    - discount_codes.id → orders.discount_code_id
    - Verb: "Discount code is used in many orders"
    - Constraint: ON DELETE SET NULL

16. **users** `HAS MANY` **sessions**
    - users.id → sessions.user_id
    - Verb: "User has many sessions"
    - Constraint: ON DELETE CASCADE

### Polymorphic Relationships

1. **personal_access_tokens** `BELONGS TO` **tokenable** (polymorphic)
   - tokenable_type + tokenable_id → users.id (typically)
   - Verb: "Token belongs to tokenable entity"

## Business Rules and Constraints

### Unique Constraints
- departments.name (UNIQUE)
- users.email (UNIQUE)
- categories.name (UNIQUE)
- discount_codes.code (UNIQUE)
- orders.order_number (UNIQUE)
- listing_size_variants(listing_id, size) (UNIQUE COMPOSITE)
- personal_access_tokens.token (UNIQUE)
- password_reset_tokens.email (PRIMARY KEY)

### Indexes for Performance
- users.role (INDEX)
- users.department_id (INDEX)
- discount_codes(code, is_active) (INDEX)
- discount_codes(department_id, is_active) (INDEX)
- discount_codes.created_by (INDEX)
- discount_codes(valid_from, valid_until) (INDEX)
- notifications(user_id, is_read) (INDEX)
- notifications(user_role, is_read) (INDEX)
- notifications(department_id, is_read) (INDEX)
- notifications.type (INDEX)
- sessions.user_id (INDEX)
- sessions.last_activity (INDEX)

### Enum Constraints
- users.role: 'student', 'admin', 'superadmin'
- discount_codes.type: 'percentage', 'fixed'
- orders.status: 'pending', 'confirmed', 'ready_for_pickup', 'completed', 'cancelled'
- reservations.status: 'pending', 'approved', 'cancelled'

### Default Values
- users.role: 'student'
- discount_codes.is_udd_official: false
- discount_codes.usage_count: 0
- discount_codes.is_active: true
- orders.status: 'pending'
- orders.payment_method: 'cash_on_pickup'
- orders.email_sent: false
- orders.discount_amount: 0
- orders.reservation_fee_paid: false
- reservations.status: 'pending'
- notifications.is_read: false
- listing_size_variants.stock_quantity: 0
- listing_images.sort_order: 0

## Key Features Supported by ERD

1. **Multi-Department System**: Each department can have its own products, listings, and users
2. **Role-Based Access Control**: Students, Admins, and Superadmins with different permissions
3. **Product Catalog**: Categories and listings with multiple images and size variants
4. **Order Management**: Complete order lifecycle with status tracking
5. **Discount System**: Flexible discount codes with usage limits and department restrictions
6. **Reservation System**: Users can reserve items before ordering
7. **Notification System**: Real-time notifications for different user roles
8. **Payment Tracking**: Reservation fees and payment receipts
9. **Inventory Management**: Stock tracking for size variants
10. **Authentication**: Personal access tokens and session management

This ERD represents a comprehensive e-commerce system for university merchandise with multi-department support, role-based access control, and advanced features like discount codes and reservations.