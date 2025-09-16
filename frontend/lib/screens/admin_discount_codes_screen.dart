import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/user_role.dart';


class AdminDiscountCodesScreen extends StatefulWidget {
  const AdminDiscountCodesScreen({super.key});

  @override
  State<AdminDiscountCodesScreen> createState() => _AdminDiscountCodesScreenState();
}

class _AdminDiscountCodesScreenState extends State<AdminDiscountCodesScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _discountCodes = [];
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;
  String? _error;
  UserSession? _userSession;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    try {
      final session = await UserSession.fromStorage();
      setState(() {
        _userSession = session;
      });
      await _loadData();
    } catch (e) {
      setState(() {
        _error = 'Failed to load user session: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load discount codes
      final discountCodes = await _adminService.getDiscountCodes();
      
      // Load departments for superadmins
      List<Map<String, dynamic>> departments = [];
      if (_userSession?.isSuperAdmin == true) {
        departments = await _adminService.getDepartments();
      }

      setState(() {
        _discountCodes = discountCodes;
        _departments = departments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateDiscountCodeDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CreateDiscountCodeDialog(
        departments: _departments,
        userSession: _userSession!,
      ),
    );

    if (result != null) {
      try {
        await _adminService.createDiscountCode(result);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Discount code created successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create discount code: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteDiscountCode(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Discount Code'),
        content: const Text('Are you sure you want to delete this discount code?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteDiscountCode(id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Discount code deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete discount code: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_userSession == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discount Codes',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: _buildMainContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDiscountCodeDialog,
        backgroundColor: const Color(0xFF1E3A8A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_discountCodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No discount codes found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first discount code using the + button',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discount Codes (${_discountCodes.length})',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _discountCodes.length,
              itemBuilder: (context, index) {
                final discountCode = _discountCodes[index];
                return _buildDiscountCodeCard(discountCode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCodeCard(Map<String, dynamic> discountCode) {
    final isActive = discountCode['is_active'] == true;
    final usageCount = discountCode['used_count'] ?? 0;
    final maxUsage = discountCode['max_usage'];
    final discountType = discountCode['type'];
    final discountValue = discountCode['value'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            discountCode['code'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        discountType == 'percentage'
                            ? '${discountValue}% off'
                            : '₱${discountValue} off',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (discountCode['description'] != null)
                        Text(
                          discountCode['description'],
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteDiscountCode(discountCode['id']),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usage: $usageCount${maxUsage != null ? '/$maxUsage' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (discountCode['valid_from'] != null)
                        Text(
                          'Valid from: ${discountCode['valid_from']}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      if (discountCode['valid_until'] != null)
                        Text(
                          'Valid until: ${discountCode['valid_until']}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (discountCode['department'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      discountCode['department']['name'] ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreateDiscountCodeDialog extends StatefulWidget {
  final List<Map<String, dynamic>> departments;
  final UserSession userSession;

  const CreateDiscountCodeDialog({
    super.key,
    required this.departments,
    required this.userSession,
  });

  @override
  State<CreateDiscountCodeDialog> createState() => _CreateDiscountCodeDialogState();
}

class _CreateDiscountCodeDialogState extends State<CreateDiscountCodeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _maxUsageController = TextEditingController();
  
  String _discountType = 'percentage';
  int? _selectedDepartmentId;
  DateTime? _validFrom;
  DateTime? _validUntil;
  bool _isUddOfficial = false;

  @override
  void initState() {
    super.initState();
    // For admins, pre-select their department
    if (widget.userSession.isAdmin && !widget.userSession.isSuperAdmin) {
      _selectedDepartmentId = widget.userSession.departmentId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Create Discount Code',
        style: TextStyle(fontFamily: 'Montserrat'),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Discount Code',
                    hintText: 'e.g., SAVE20',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a discount code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Brief description of the discount',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _discountType,
                        decoration: const InputDecoration(
                          labelText: 'Discount Type',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'percentage',
                            child: Text('Percentage'),
                          ),
                          DropdownMenuItem(
                            value: 'fixed',
                            child: Text('Fixed Amount'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _discountType = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _discountValueController,
                        decoration: InputDecoration(
                          labelText: _discountType == 'percentage' ? 'Percentage' : 'Amount',
                          suffixText: _discountType == 'percentage' ? '%' : '₱',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final numValue = double.tryParse(value);
                          if (numValue == null || numValue <= 0) {
                            return 'Invalid value';
                          }
                          if (_discountType == 'percentage' && numValue > 100) {
                            return 'Max 100%';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.userSession.isSuperAdmin) ...[
                  DropdownButtonFormField<int?>(
                    value: _selectedDepartmentId,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Departments'),
                      ),
                      ...widget.departments.map((dept) => DropdownMenuItem<int?>(
                        value: dept['id'],
                        child: Text(dept['name']),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartmentId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('UDD Official Merch'),
                    subtitle: const Text('Allow for official university merchandise'),
                    value: _isUddOfficial,
                    onChanged: (value) {
                      setState(() {
                        _isUddOfficial = value ?? false;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxUsageController,
                  decoration: const InputDecoration(
                    labelText: 'Max Usage (Optional)',
                    hintText: 'Leave empty for unlimited',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final numValue = int.tryParse(value);
                      if (numValue == null || numValue <= 0) {
                        return 'Invalid number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Valid From'),
                        subtitle: Text(
                          _validFrom?.toString().split(' ')[0] ?? 'Not set',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _validFrom ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              _validFrom = date;
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('Valid Until'),
                        subtitle: Text(
                          _validUntil?.toString().split(' ')[0] ?? 'Not set',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _validUntil ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: _validFrom ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              _validUntil = date;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final data = {
                'code': _codeController.text.trim().toUpperCase(),
                'description': _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                'type': _discountType,
                'value': double.parse(_discountValueController.text),
                'department_id': _selectedDepartmentId,
                'is_udd_official': _isUddOfficial,
                'usage_limit': _maxUsageController.text.isEmpty
                    ? null
                    : int.parse(_maxUsageController.text),
                'valid_from': _validFrom?.toIso8601String().split('T')[0],
                'valid_until': _validUntil?.toIso8601String().split('T')[0],
              };
              Navigator.pop(context, data);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _maxUsageController.dispose();
    super.dispose();
  }
}