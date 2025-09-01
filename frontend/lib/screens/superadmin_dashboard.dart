import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';
import '../models/listing.dart';
import '../services/admin_service.dart';
import '../services/auth_services.dart';
import '../config/app_config.dart';
import 'admin_orders_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  final UserSession userSession;

  const SuperAdminDashboard({super.key, required this.userSession});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  Map<String, dynamic>? _dashboardStats;
  List<UserSession> _users = [];
  List<Listing> _listings = [];
  bool _isLoading = false;
  int _selectedIndex = 0;

  // Department logo mapping
  String? _getDepartmentLogo(String departmentName) {
    switch (departmentName.toLowerCase()) {
      case 'school of information technology education':
        return 'assets/logos/site.png';
      case 'school of business and accountancy':
        return 'assets/logos/sba.png';
      case 'school of criminology':
        return 'assets/logos/soc.png';
      case 'school of engineering':
        return 'assets/logos/soe.png';
      case 'school of teacher education':
        return 'assets/logos/ste.png';
      case 'school of humanities':
        return 'assets/logos/soh.png';
      case 'school of health sciences':
        return 'assets/logos/sohs.png';
      case 'school of international hospitality management':
        return 'assets/logos/sihm.png';
      case 'official udd merch':
        return null; // Will use fallback icon due to file size issues
      default:
        return 'assets/logos/site.png'; // Default fallback
    }
  }

  // Filter variables
  String? _selectedDepartmentFilter;
  String? _selectedRoleFilter;
  String _searchQuery = '';
  List<String> _availableDepartments = [];
  final List<String> _availableRoles = [
    'All',
    'Student',
    'Admin',
    'SuperAdmin',
  ];

  // Department management variables
  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      print('🔄 Loading superadmin data...');

      // Load dashboard stats
      final stats = await AdminService.getDashboardStats();
      print('📊 Stats loaded: $stats');

      // Load users
      final users = await AdminService.getAllUsers();
      print('👥 Users loaded: ${users.length}');

      // Load listings
      final listings = await AdminService.getAllListings();
      print('📦 Listings loaded: ${listings.length}');

      // Load departments
      final departmentsData = await AdminService.getAllDepartments();
      print('🏢 Departments loaded: ${departmentsData.length}');

      if (mounted) {
        setState(() {
          _dashboardStats = stats;
          _users = users;
          _listings = listings;
          _departments = departmentsData;
          _isLoading = false;

          // Extract available departments for filtering
          _availableDepartments = ['All'];
          final departments = users
              .map((user) => user.departmentName)
              .where((dept) => dept != null && dept!.isNotEmpty)
              .map((dept) => dept!)
              .toSet();
          _availableDepartments.addAll(departments.toList());
        });
      }

      print('✅ Superadmin data loaded successfully');
    } catch (e) {
      print('❌ Error loading superadmin data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: Text(
          _getCurrentTitle(),
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildCurrentBody(),
    );
  }

  // Dashboard Tab
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  _buildStatCard(
                    'Total Users',
                    _dashboardStats?['users']?['total']?.toString() ?? '0',
                    Icons.people,
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    'Departments',
                    _dashboardStats?['departments']?.toString() ?? '0',
                    Icons.school,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    'Total Listings',
                    _dashboardStats?['listings']?['total']?.toString() ?? '0',
                    Icons.inventory,
                    Colors.purple,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    'Stock Value',
                    '₱${_formatStockValue(_dashboardStats?['totalStockValue'])}',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Users Tab
  Widget _buildUsersTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Column(
                    children: [
                      // Department Filter
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedDepartmentFilter ?? 'All',
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        items: _availableDepartments.map((dept) {
                          return DropdownMenuItem(
                            value: dept,
                            child: Text(
                              dept,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartmentFilter = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Role Filter
                      DropdownButtonFormField<String>(
                        value: _selectedRoleFilter ?? 'All',
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _availableRoles.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRoleFilter = value;
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      // Clear Filters Button
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedDepartmentFilter = null;
                            _selectedRoleFilter = null;
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Showing ${_filteredUsers.length} of ${_users.length} users',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredUsers.isEmpty)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.people, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _users.isEmpty
                          ? 'No users found'
                          : 'No users match the selected filters',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    if (_users.isNotEmpty && _filteredUsers.isEmpty)
                      const SizedBox(height: 8),
                    if (_users.isNotEmpty && _filteredUsers.isEmpty)
                      Text(
                        'Try adjusting your filters',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    crossAxisSpacing: 0,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  child: Text(
                                    user.name[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (user.departmentName != null &&
                                user.departmentName!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user.departmentName!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(user.role),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getRoleString(user.role).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (user.role == UserRole.student)
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    onSelected: (value) =>
                                        _handleUserAction(user, value),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'grant_admin',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.admin_panel_settings,
                                              color: Colors.blue,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Grant Admin'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'grant_superadmin',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.admin_panel_settings,
                                              color: Colors.purple,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Grant SuperAdmin'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else if (user.role == UserRole.admin)
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    onSelected: (value) =>
                                        _handleUserAction(user, value),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'grant_superadmin',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.admin_panel_settings,
                                              color: Colors.purple,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Grant SuperAdmin'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'revoke_admin',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.remove_moderator,
                                              color: Colors.orange,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Revoke Admin'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else if (user.role == UserRole.superAdmin)
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    onSelected: (value) =>
                                        _handleUserAction(user, value),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'revoke_superadmin',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.remove_moderator,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Revoke SuperAdmin'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Departments Tab
  Widget _buildDepartmentsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Departments',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddDepartmentDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Department'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_departments.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.school, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No departments found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Click "Add Department" to create one',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _departments.length,
                  itemBuilder: (context, index) {
                    final department = _departments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1E3A8A),
                        child: ClipOval(
                          child: _getDepartmentLogo(department['name']) != null
                              ? Image.asset(
                                  _getDepartmentLogo(department['name'])!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                      'Error loading logo for ${department['name']}: $error',
                                    );
                                    return Text(
                                      department['name'][0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                )
                              : Text(
                                  department['name'][0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                      title: Text(department['name']),
                      subtitle: Text(
                        department['description'] ?? 'No description',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showEditDepartmentDialog(department),
                            tooltip: 'Edit Department',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _showDeleteDepartmentDialog(department),
                            tooltip: 'Delete Department',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Products Tab
  Widget _buildProductsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Products',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddProductDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_listings.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory, size: 84, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No products found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Click "Add Product" to create one',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.42,
                ),
                itemCount: _listings.length,
                itemBuilder: (context, index) {
                  final listing = _listings[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: listing.imagePath != null
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                    child: Image.network(
                                      Uri.encodeFull(
                                        '${AppConfig.fileUrl(listing.imagePath)}?t=${listing.updatedAt.millisecondsSinceEpoch}',
                                      ),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.image,
                                              size: 50,
                                              color: Colors.grey,
                                            );
                                          },
                                    ),
                                  )
                                : const Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₱${_formatPrice(listing.price)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A8A),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(listing.status),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        listing.status == 'pending'
                                            ? 'PENDING'
                                            : listing.status.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () =>
                                              _showDeleteConfirmationDialog(
                                                listing,
                                              ),
                                          child: Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: Colors.red[600],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () =>
                                              _showEditProductDialog(listing),
                                          child: Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // Analytics Tab
  Widget _buildAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.analytics, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Analytics Dashboard',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This feature will be implemented soon.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Settings Tab
  Widget _buildSettingsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // App Configuration Section
            _buildSettingsSection(
              'App Configuration',
              Icons.settings_applications,
              [
                _buildSettingTile(
                  'Base URL',
                  'http://192.168.100.11:8000',
                  Icons.link,
                  onTap: () => _showEditSettingDialog(
                    'Base URL',
                    'http://192.168.100.11:8000',
                    (value) {
                      // Update base URL logic would go here
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Base URL updated to: $value'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
                _buildSettingTile(
                  'App Version',
                  '1.0.0',
                  Icons.info,
                  isEditable: false,
                ),
                _buildSettingTile(
                  'Environment',
                  'Production',
                  Icons.cloud,
                  isEditable: false,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // User Management Settings
            _buildSettingsSection('User Management', Icons.people, [
              _buildSettingTile(
                'Default User Role',
                'Student',
                Icons.person_add,
                onTap: () => _showRoleSelectionDialog(),
              ),
              _buildSettingTile(
                'Auto-approve Registrations',
                'Disabled',
                Icons.auto_awesome,
                onTap: () =>
                    _showToggleDialog('Auto-approve Registrations', false),
              ),
              _buildSettingTile(
                'Email Verification Required',
                'Enabled',
                Icons.email,
                onTap: () =>
                    _showToggleDialog('Email Verification Required', true),
              ),
              _buildSettingTile(
                'Max Login Attempts',
                '5',
                Icons.security,
                onTap: () => _showEditSettingDialog('Max Login Attempts', '5', (
                  value,
                ) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Max login attempts updated to: $value'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }),
              ),
            ]),

            const SizedBox(height: 24),

            // System Preferences
            _buildSettingsSection('System Preferences', Icons.tune, [
              _buildSettingTile(
                'Maintenance Mode',
                'Disabled',
                Icons.build,
                onTap: () => _showToggleDialog('Maintenance Mode', false),
              ),
              _buildSettingTile(
                'Debug Mode',
                'Disabled',
                Icons.bug_report,
                onTap: () => _showToggleDialog('Debug Mode', false),
              ),
              _buildSettingTile(
                'Data Backup Frequency',
                'Daily',
                Icons.backup,
                onTap: () => _showBackupFrequencyDialog(),
              ),
              _buildSettingTile(
                'Session Timeout',
                '30 minutes',
                Icons.timer,
                onTap: () => _showSessionTimeoutDialog(),
              ),
            ]),

            const SizedBox(height: 24),

            // Data Management
            _buildSettingsSection('Data Management', Icons.storage, [
              _buildSettingTile(
                'Database Size',
                '2.5 MB',
                Icons.storage,
                isEditable: false,
              ),
              _buildSettingTile(
                'Backup Database',
                'Last backup: 2 hours ago',
                Icons.save_alt,
                onTap: () => _showBackupDialog(),
              ),
              _buildSettingTile(
                'Clear Cache',
                'Cache size: 15 MB',
                Icons.clear_all,
                onTap: () => _showClearCacheDialog(),
              ),
              _buildSettingTile(
                'Export Data',
                'Export all data to CSV',
                Icons.file_download,
                onTap: () => _showExportDialog(),
              ),
            ]),

            const SizedBox(height: 24),

            // Security Settings
            _buildSettingsSection('Security', Icons.security, [
              _buildSettingTile(
                'Password Policy',
                'Minimum 8 characters',
                Icons.lock,
                onTap: () => _showPasswordPolicyDialog(),
              ),
              _buildSettingTile(
                'Two-Factor Authentication',
                'Optional',
                Icons.phone_android,
                onTap: () => _showTwoFactorDialog(),
              ),
              _buildSettingTile(
                'API Rate Limiting',
                '100 requests/hour',
                Icons.speed,
                onTap: () => _showRateLimitDialog(),
              ),
              _buildSettingTile(
                'Audit Log',
                'View system logs',
                Icons.history,
                onTap: () => _showAuditLogDialog(),
              ),
            ]),

            const SizedBox(height: 24),

            // Maintenance Actions
            _buildSettingsSection('Maintenance', Icons.build_circle, [
              _buildSettingTile(
                'System Health Check',
                'Run diagnostics',
                Icons.health_and_safety,
                onTap: () => _runSystemHealthCheck(),
              ),
              _buildSettingTile(
                'Optimize Database',
                'Improve performance',
                Icons.speed,
                onTap: () => _optimizeDatabase(),
              ),
              _buildSettingTile(
                'Reset System',
                'Reset to default settings',
                Icons.restore,
                onTap: () => _showResetSystemDialog(),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // Helper method to build settings sections
  Widget _buildSettingsSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF1E3A8A), size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  // Helper method to build setting tiles
  Widget _buildSettingTile(
    String title,
    String value,
    IconData icon, {
    bool isEditable = true,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(value),
      trailing: isEditable
          ? const Icon(Icons.chevron_right, color: Colors.grey)
          : null,
      onTap: isEditable ? onTap : null,
    );
  }

  // Dialog methods for settings
  void _showEditSettingDialog(
    String title,
    String currentValue,
    Function(String) onSave,
  ) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onSave(controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showToggleDialog(String title, bool currentValue) {
    bool value = currentValue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configure $title'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enable $title?'),
              const SizedBox(height: 16),
              Switch(
                value: value,
                onChanged: (newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title ${value ? 'enabled' : 'disabled'}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRoleSelectionDialog() {
    String selectedRole = 'Student';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default User Role'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Student'),
                value: 'Student',
                groupValue: selectedRole,
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Admin'),
                value: 'Admin',
                groupValue: selectedRole,
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Default role set to: $selectedRole'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBackupFrequencyDialog() {
    String selectedFrequency = 'Daily';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Frequency'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Daily'),
                value: 'Daily',
                groupValue: selectedFrequency,
                onChanged: (value) {
                  setState(() {
                    selectedFrequency = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Weekly'),
                value: 'Weekly',
                groupValue: selectedFrequency,
                onChanged: (value) {
                  setState(() {
                    selectedFrequency = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Monthly'),
                value: 'Monthly',
                groupValue: selectedFrequency,
                onChanged: (value) {
                  setState(() {
                    selectedFrequency = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Backup frequency set to: $selectedFrequency'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSessionTimeoutDialog() {
    String selectedTimeout = '30 minutes';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Timeout'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('15 minutes'),
                value: '15 minutes',
                groupValue: selectedTimeout,
                onChanged: (value) {
                  setState(() {
                    selectedTimeout = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('30 minutes'),
                value: '30 minutes',
                groupValue: selectedTimeout,
                onChanged: (value) {
                  setState(() {
                    selectedTimeout = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('1 hour'),
                value: '1 hour',
                groupValue: selectedTimeout,
                onChanged: (value) {
                  setState(() {
                    selectedTimeout = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Never'),
                value: 'Never',
                groupValue: selectedTimeout,
                onChanged: (value) {
                  setState(() {
                    selectedTimeout = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Session timeout set to: $selectedTimeout'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Database'),
        content: const Text(
          'This will create a backup of all system data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performBackup();
            },
            child: const Text('Backup'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCache();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Export all system data to CSV format?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportData();
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showPasswordPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password Policy'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Policy:'),
            SizedBox(height: 8),
            Text('• Minimum 8 characters'),
            Text('• At least 1 uppercase letter'),
            Text('• At least 1 lowercase letter'),
            Text('• At least 1 number'),
            Text('• At least 1 special character'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorDialog() {
    String selectedOption = 'Optional';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Two-Factor Authentication'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Disabled'),
                value: 'Disabled',
                groupValue: selectedOption,
                onChanged: (value) {
                  setState(() {
                    selectedOption = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Optional'),
                value: 'Optional',
                groupValue: selectedOption,
                onChanged: (value) {
                  setState(() {
                    selectedOption = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Required for Admins'),
                value: 'Required for Admins',
                groupValue: selectedOption,
                onChanged: (value) {
                  setState(() {
                    selectedOption = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Required for All'),
                value: 'Required for All',
                groupValue: selectedOption,
                onChanged: (value) {
                  setState(() {
                    selectedOption = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('2FA set to: $selectedOption'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRateLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Rate Limiting'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Limits:'),
            SizedBox(height: 8),
            Text('• General users: 100 requests/hour'),
            Text('• Admin users: 500 requests/hour'),
            Text('• SuperAdmin users: 1000 requests/hour'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAuditLogDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audit Log'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Audit log feature will be implemented soon.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetSystemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset System'),
        content: const Text(
          'This will reset all system settings to default values. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSystem();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _performBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup completed successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data exported successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _runSystemHealthCheck() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'System health check completed. All systems operational.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _optimizeDatabase() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Database optimization completed'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetSystem() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('System reset completed'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Helper Methods
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0.00';
    if (price is String) {
      try {
        return double.parse(price).toStringAsFixed(2);
      } catch (e) {
        return '0.00';
      }
    } else if (price is int || price is double) {
      return price.toDouble().toStringAsFixed(2);
    }
    return '0.00';
  }

  String _formatStockValue(dynamic value) {
    if (value == null) return '0.00';
    if (value is String) {
      try {
        return double.parse(value).toStringAsFixed(2);
      } catch (e) {
        return '0.00';
      }
    } else if (value is int || value is double) {
      return value.toDouble().toStringAsFixed(2);
    }
    return '0.00';
  }

  String _getRoleString(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'superadmin';
      case UserRole.admin:
        return 'admin';
      case UserRole.student:
        return 'student';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Colors.purple;
      case UserRole.admin:
        return Colors.blue;
      case UserRole.student:
        return Colors.green;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Department Selection Dialog
  Future<int?> _showDepartmentSelectionDialog() async {
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Department'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose which department this user will be an admin of:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ...(_departments
                  .map(
                    (dept) => ListTile(
                      title: Text(dept['name']),
                      onTap: () => Navigator.pop(context, dept['id']),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                  )
                  .toList()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // User Management Actions
  Future<void> _handleUserAction(UserSession user, String action) async {
    try {
      bool success = false;
      String message = '';

      switch (action) {
        case 'grant_admin':
          // Show department selection dialog for grant admin
          final selectedDepartmentId = await _showDepartmentSelectionDialog();
          if (selectedDepartmentId != null) {
            success = await AdminService.grantAdminPrivileges(
              int.parse(user.userId),
              selectedDepartmentId,
            );
            message = success
                ? 'Admin privileges granted to ${user.name}. The user should log out and log back in to see the updated department.'
                : 'Failed to grant admin privileges';
          }
          break;
        case 'grant_superadmin':
          success = await AdminService.grantSuperAdminPrivileges(
            int.parse(user.userId),
          );
          message = success
              ? 'SuperAdmin privileges granted to ${user.name}'
              : 'Failed to grant SuperAdmin privileges';
          break;
        case 'revoke_admin':
          success = await AdminService.revokeAdminPrivileges(
            int.parse(user.userId),
          );
          message = success
              ? 'Admin privileges revoked from ${user.name}. The user should log out and log back in to see the updated role.'
              : 'Failed to revoke admin privileges';
          break;
        case 'revoke_superadmin':
          success = await AdminService.revokeSuperAdminPrivileges(
            int.parse(user.userId),
          );
          message = success
              ? 'SuperAdmin privileges revoked from ${user.name}'
              : 'Failed to revoke SuperAdmin privileges';
          break;
      }

      if (success) {
        // Refresh data to show updated user roles
        _loadData();
      }
    } catch (e) {
      print('Error in user action: $e');
    }
  }

  // Filter users based on selected filters
  List<UserSession> get _filteredUsers {
    return _users.where((user) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = user.name.toLowerCase();
        final email = user.email.toLowerCase();

        if (!name.contains(query) && !email.contains(query)) {
          return false;
        }
      }

      // Department filter
      if (_selectedDepartmentFilter != null &&
          _selectedDepartmentFilter != 'All') {
        if (user.departmentName != _selectedDepartmentFilter) {
          return false;
        }
      }

      // Role filter
      if (_selectedRoleFilter != null && _selectedRoleFilter != 'All') {
        String userRole = _getRoleString(user.role);
        if (_selectedRoleFilter == 'Student' && userRole != 'student')
          return false;
        if (_selectedRoleFilter == 'Admin' && userRole != 'admin') return false;
        if (_selectedRoleFilter == 'SuperAdmin' && userRole != 'superadmin')
          return false;
      }

      return true;
    }).toList();
  }

  // Department Management Dialogs
  void _showAddDepartmentDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    File? selectedLogo;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Department'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Department Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Logo upload section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Department Logo (Optional)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (selectedLogo != null)
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(selectedLogo!, fit: BoxFit.cover),
                          ),
                        )
                      else
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 512,
                                maxHeight: 512,
                              );
                              if (image != null) {
                                setState(() {
                                  selectedLogo = File(image.path);
                                });
                              }
                            },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.camera,
                                maxWidth: 512,
                                maxHeight: 512,
                              );
                              if (image != null) {
                                setState(() {
                                  selectedLogo = File(image.path);
                                });
                              }
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                descriptionController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  return;
                }

                nameController.dispose();
                descriptionController.dispose();
                Navigator.pop(context);

                try {
                  final success = await AdminService.createDepartment(
                    nameController.text.trim(),
                    descriptionController.text.trim(),
                    logoPath: selectedLogo?.path,
                  );

                  if (success) {
                    // Refresh data to show the new department
                    _loadData();
                  }
                } catch (e) {
                  print('Error creating department: $e');
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDepartmentDialog(Map<String, dynamic> department) {
    final nameController = TextEditingController(text: department['name']);
    final descriptionController = TextEditingController(
      text: department['description'] ?? '',
    );
    File? selectedLogo;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Department'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Department Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Logo upload section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Department Logo (Optional)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (selectedLogo != null)
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(selectedLogo!, fit: BoxFit.cover),
                          ),
                        )
                      else
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 512,
                                maxHeight: 512,
                              );
                              if (image != null) {
                                setState(() {
                                  selectedLogo = File(image.path);
                                });
                              }
                            },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.camera,
                                maxWidth: 512,
                                maxHeight: 512,
                              );
                              if (image != null) {
                                setState(() {
                                  selectedLogo = File(image.path);
                                });
                              }
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                descriptionController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  return;
                }

                nameController.dispose();
                descriptionController.dispose();
                Navigator.pop(context);

                try {
                  final success = await AdminService.updateDepartment(
                    department['id'],
                    nameController.text.trim(),
                    descriptionController.text.trim(),
                    logoPath: selectedLogo?.path,
                  );

                  if (success) {
                    // Refresh data to show the updated department
                    _loadData();
                  }
                } catch (e) {
                  print('Error updating department: $e');
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDepartmentDialog(Map<String, dynamic> department) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text(
          'Are you sure you want to delete "${department['name']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final success = await AdminService.deleteDepartment(
                  department['id'],
                );

                if (success) {
                  // Refresh data to reflect the deletion
                  _loadData();
                }
              } catch (e) {
                print('Error deleting department: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Product Management Dialogs
  Future<void> _showAddProductDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    String selectedStatus = 'pending';
    int? selectedCategoryId;
    int? selectedDepartmentId;
    String? selectedSize;
    List<Map<String, dynamic>> categories = [];
    List<Map<String, dynamic>> departments = [];
    File? selectedImage;
    bool isLoading = true;

    // Per-size stock controllers for clothing
    final Map<String, TextEditingController> _sizeQtyControllers = {
      'XS': TextEditingController(),
      'S': TextEditingController(),
      'M': TextEditingController(),
      'L': TextEditingController(),
      'XL': TextEditingController(),
      'XXL': TextEditingController(),
    };
    final List<String> _clothingSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
    bool isClothingSelected = false;

    // Load data first
    Future<void> loadData() async {
      try {
        // Use existing departments data from dashboard
        departments = _departments;

        // For categories, we'll use a simple approach for now
        // You can add a getAllCategories method to AdminService later
        categories = [
          {'id': 1, 'name': 'Clothing'},
          {'id': 2, 'name': 'Accessories'},
          {'id': 3, 'name': 'Stationery'},
          {'id': 4, 'name': 'Electronics'},
        ];

        isLoading = false;
      } catch (e) {
        print('Error loading data: $e');
        isLoading = false;
      }
    }

    // Preload data synchronously before opening the dialog
    departments = _departments;
    final cats = await AdminService.getAllCategories();
    if (cats.isNotEmpty) {
      categories = cats;
    } else {
      categories = [
        {'id': 1, 'name': 'Clothing'},
        {'id': 2, 'name': 'Accessories'},
        {'id': 3, 'name': 'Stationery'},
        {'id': 4, 'name': 'Electronics'},
      ];
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Product Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price (₱)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category['id'],
                      child: Text(category['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategoryId = value;
                      // Determine if clothing is selected to show/hide size fields
                      final cat = categories.firstWhere(
                        (c) => c['id'] == selectedCategoryId,
                        orElse: () => {'name': ''},
                      );
                      isClothingSelected = (cat['name'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains('cloth');
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Department Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedDepartmentId,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
                      items: departments.map((dept) {
                        return DropdownMenuItem<int>(
                          value: dept['id'],
                          child: Text(dept['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDepartmentId = value;
                        });
                      },
                    ),
                    // Special indicator for Official UDD Merch
                    if (selectedDepartmentId != null)
                      Builder(
                        builder: (context) {
                          final selectedDept = departments.firstWhere(
                            (dept) => dept['id'] == selectedDepartmentId,
                            orElse: () => {},
                          );
                          if (selectedDept['name'] == 'Official UDD Merch') {
                            return Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1E3A8A,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xFF1E3A8A,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: const Color(0xFF1E3A8A),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Official UDD Merch - Only superadmins can create listings for this department',
                                      style: TextStyle(
                                        color: const Color(0xFF1E3A8A),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Conditional Size/Stock Inputs
                if (isClothingSelected) ...[
                  const Text(
                    'Stock per Size:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._clothingSizes
                      .map(
                        (size) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TextField(
                            controller: _sizeQtyControllers[size],
                            decoration: InputDecoration(
                              labelText: '$size Stock',
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      )
                      .toList(),
                ] else ...[
                  // Single Stock Quantity for non-clothing
                  TextFormField(
                    controller: stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter stock quantity';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid quantity';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                  ],
                  onChanged: (value) {
                    selectedStatus = value!;
                  },
                ),

                const SizedBox(height: 16),
                // Image upload section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Product Image (Optional)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (selectedImage != null)
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 512,
                                maxHeight: 512,
                              );
                              if (image != null) {
                                setState(() {
                                  selectedImage = File(image.path);
                                });
                              }
                            },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.camera,
                                maxWidth: 512,
                                maxHeight: 512,
                              );
                              if (image != null) {
                                setState(() {
                                  selectedImage = File(image.path);
                                });
                              }
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product title is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a category'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (selectedDepartmentId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a department'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  // Handle per-size stock for clothing
                  if (isClothingSelected) {
                    final entries = _sizeQtyControllers.entries
                        .map(
                          (e) => MapEntry(
                            e.key,
                            int.tryParse(e.value.text.trim()),
                          ),
                        )
                        .where((e) => (e.value ?? 0) > 0)
                        .toList();

                    if (entries.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter stock for at least one size',
                          ),
                        ),
                      );
                      return;
                    }

                    // Create single listing with size variants
                    final sizeVariants = <Map<String, dynamic>>[];
                    for (final entry in entries) {
                      sizeVariants.add({
                        'size': entry.key,
                        'stock_quantity': entry.value,
                      });
                    }

                    final success =
                        await AdminService.createListingWithVariants(
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                          price:
                              double.tryParse(priceController.text.trim()) ??
                              0.0,
                          status: selectedStatus,
                          imagePath: selectedImage?.path,
                          categoryId: selectedCategoryId,
                          departmentId: selectedDepartmentId,
                          sizeVariants: sizeVariants,
                        );

                    if (success && mounted) {
                      Navigator.pop(context);
                      print(
                        '🔄 Product created successfully, refreshing data...',
                      );
                      setState(() {
                        _selectedIndex = 4; // Switch to Products tab
                        _isLoading = true; // Show loading indicator
                      });
                      await _loadData(); // Wait for data to load
                      print(
                        '✅ Data refresh completed. Listings count: ${_listings.length}',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Successfully created listing with multiple sizes',
                            ),
                          ),
                        );
                      }
                    }
                  } else {
                    // Regular single listing creation
                    final success = await AdminService.createListing(
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      price:
                          double.tryParse(priceController.text.trim()) ?? 0.0,
                      stockQuantity:
                          int.tryParse(stockController.text.trim()) ?? 0,
                      status: selectedStatus,
                      imagePath: selectedImage?.path,
                      categoryId: selectedCategoryId,
                      departmentId: selectedDepartmentId,
                      size: selectedSize?.trim(),
                    );

                    if (success && mounted) {
                      Navigator.pop(context);
                      print(
                        '🔄 Product created successfully, refreshing data...',
                      );
                      setState(() {
                        _selectedIndex = 4; // Switch to Products tab
                        _isLoading = true; // Show loading indicator
                      });
                      await _loadData(); // Wait for data to load
                      print(
                        '✅ Data refresh completed. Listings count: ${_listings.length}',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product created successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  }
                } catch (e) {
                  print('Error creating product: $e');
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(Listing listing) {
    final titleController = TextEditingController(text: listing.title);
    final descriptionController = TextEditingController(
      text: listing.description,
    );
    final priceController = TextEditingController(
      text: listing.price.toString(),
    );
    final stockController = TextEditingController(
      text: listing.stockQuantity.toString(),
    );
    String selectedStatus = listing.status;

    // Check if this is a clothing item with size variants
    final hasSizeVariants =
        listing.sizeVariants != null && listing.sizeVariants!.isNotEmpty;
    final isClothing =
        listing.category?.name.toLowerCase().contains('clothing') ?? false;

    // Per-size stock controllers for clothing
    final Map<String, TextEditingController> sizeQtyControllers = {
      'XS': TextEditingController(),
      'S': TextEditingController(),
      'M': TextEditingController(),
      'L': TextEditingController(),
      'XL': TextEditingController(),
      'XXL': TextEditingController(),
    };

    // Initialize size controllers with existing data
    if (hasSizeVariants && listing.sizeVariants != null) {
      // If listing has size variants, use those values
      for (final variant in listing.sizeVariants!) {
        if (sizeQtyControllers.containsKey(variant.size)) {
          sizeQtyControllers[variant.size]!.text = variant.stockQuantity
              .toString();
        }
      }
    } else if (isClothing) {
      // If it's clothing but no size variants, distribute the total stock across sizes
      final totalStock = listing.stockQuantity;
      final defaultStock = totalStock > 0
          ? (totalStock / 6).round()
          : 0; // Distribute across 6 sizes

      for (final controller in sizeQtyControllers.values) {
        controller.text = defaultStock.toString();
      }

      // Put remaining stock in the first size (M)
      if (totalStock > 0) {
        final remaining = totalStock - (defaultStock * 6);
        if (remaining > 0) {
          sizeQtyControllers['M']!.text = (defaultStock + remaining).toString();
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Product Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price (₱)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (!isClothing && !hasSizeVariants)
                      Expanded(
                        child: TextField(
                          controller: stockController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Quantity',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                  ],
                ),
                if (isClothing || hasSizeVariants) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Stock per Size:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: sizeQtyControllers.entries.map((entry) {
                      return SizedBox(
                        width: 100,
                        child: TextField(
                          controller: entry.value,
                          decoration: InputDecoration(
                            labelText: entry.key,
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                  ],
                  onChanged: (value) {
                    selectedStatus = value!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product title is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  print('🔄 Starting update for listing ID: ${listing.id}');
                  print('📝 Title: ${titleController.text.trim()}');
                  print('📝 Description: ${descriptionController.text.trim()}');
                  print('📝 Price: ${priceController.text.trim()}');
                  print('📝 Status: $selectedStatus');
                  print('👕 Has size variants: $hasSizeVariants');

                  // Update basic info
                  final success = await AdminService.updateListing(
                    listing.id,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    price:
                        double.tryParse(priceController.text.trim()) ??
                        listing.price,
                    status: selectedStatus,
                  );

                  if (success) {
                    print('✅ Basic info update successful');

                    // Update size variants if it's clothing
                    if (isClothing || hasSizeVariants) {
                      print('👕 Updating size variants...');
                      final sizeVariants = <Map<String, dynamic>>[];
                      for (final entry in sizeQtyControllers.entries) {
                        final stock = int.tryParse(entry.value.text.trim());
                        if (stock != null && stock >= 0) {
                          sizeVariants.add({
                            'size': entry.key,
                            'stock_quantity': stock,
                          });
                        }
                      }

                      print('📦 Size variants to update: $sizeVariants');

                      if (sizeVariants.isNotEmpty) {
                        final sizeSuccess =
                            await AdminService.updateListingSizeVariants(
                              listing.id,
                              sizeVariants,
                            );
                        print('👕 Size variants update result: $sizeSuccess');
                      }
                    } else {
                      // Update single stock quantity for non-clothing
                      final newStock = int.tryParse(stockController.text);
                      if (newStock != null) {
                        await AdminService.updateStock(listing.id, newStock);
                      }
                    }

                    // Auto-refresh data
                    _loadData();

                    // Close dialog first, then show success message
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Product updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    // Show error without closing dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to update product'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  print('Error updating product: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update product'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // Approve listing method
  Future<void> _approveListing(Listing listing) async {
    try {
      print('🔄 Approving listing: ${listing.title} (ID: ${listing.id})');

      final success = await AdminService.approveListing(listing.id);

      if (success) {
        print('✅ Listing approved successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Listing "${listing.title}" approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the data to show updated status
        _loadData();
      } else {
        print('❌ Failed to approve listing');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve listing'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error approving listing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving listing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete listing confirmation dialog
  void _showDeleteConfirmationDialog(Listing listing) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Product'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${listing.title}"?\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteListing(listing);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Delete listing method
  Future<void> _deleteListing(Listing listing) async {
    try {
      print('🗑️ Deleting listing: ${listing.title} (ID: ${listing.id})');

      final success = await AdminService.deleteListing(listing.id);

      if (success) {
        print('✅ Listing deleted successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "${listing.title}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the data to show updated list
        _loadData();
      } else {
        print('❌ Failed to delete listing');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting listing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Drawer Navigation Methods
  String _getCurrentTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Orders';
      case 2:
        return 'Users';
      case 3:
        return 'Departments';
      case 4:
        return 'Products';
      case 5:
        return 'Analytics';
      case 6:
        return 'Settings';
      default:
        return 'UDD SuperAdmin Dashboard';
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 30,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.userSession.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'SuperAdmin',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() {
                _selectedIndex = 0;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Orders'),
            selected: _selectedIndex == 1,
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Users'),
            selected: _selectedIndex == 2,
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Departments'),
            selected: _selectedIndex == 3,
            onTap: () {
              setState(() {
                _selectedIndex = 3;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Products'),
            selected: _selectedIndex == 4,
            onTap: () {
              setState(() {
                _selectedIndex = 4;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            selected: _selectedIndex == 5,
            onTap: () {
              setState(() {
                _selectedIndex = 5;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            selected: _selectedIndex == 6,
            onTap: () {
              setState(() {
                _selectedIndex = 6;
              });
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return AdminOrdersScreen(userSession: widget.userSession);
      case 2:
        return _buildUsersTab();
      case 3:
        return _buildDepartmentsTab();
      case 4:
        return _buildProductsTab();
      case 5:
        return _buildAnalyticsTab();
      case 6:
        return _buildSettingsTab();
      default:
        return _buildDashboardTab();
    }
  }
}
