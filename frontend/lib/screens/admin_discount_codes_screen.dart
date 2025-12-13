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
      if (mounted) {
        setState(() {
          _userSession = session;
        });
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load user session: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // Load discount codes
      final discountCodes = await _adminService.getDiscountCodes();
      
      // Load departments for superadmins
      List<Map<String, dynamic>> departments = [];
      if (_userSession?.isSuperAdmin == true) {
        departments = await _adminService.getDepartments();
      }

      if (mounted) {
        setState(() {
          _discountCodes = discountCodes;
          _departments = departments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
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
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Discount code created successfully'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to create discount code: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
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
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Discount code deleted successfully'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to delete discount code: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
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
                          Expanded(
                            child: Text(
                              discountCode['code'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                              ),
                              overflow: TextOverflow.ellipsis,
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
                        () {
                          // Handle different data types for discount value
                          double? actualValue;
                          
                          if (discountValue is String) {
                            actualValue = double.tryParse(discountValue);
                          } else if (discountValue is num) {
                            actualValue = discountValue.toDouble();
                          }
                          
                          // Show the actual value even if it's 0, but handle null
                          if (actualValue == null) {
                            return 'Invalid discount value';
                          }
                          
                          return '${actualValue.toStringAsFixed(actualValue == actualValue.toInt() ? 0 : 1)}% off';
                        }(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (discountCode['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          discountCode['description'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteDiscountCode(discountCode['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 400;
                
                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (discountCode['valid_from'] != null) ...[
                        Text(
                          'Valid from: ${_formatDate(discountCode['valid_from'])}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (discountCode['valid_until'] != null) ...[
                        Text(
                          'Valid until: ${_formatDate(discountCode['valid_until'])}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (discountCode['department'] != null) ...[
                        const SizedBox(height: 8),
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
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      if (discountCode['valid_from'] != null) ...[
                        Expanded(
                          child: Text(
                            'Valid from: ${_formatDate(discountCode['valid_from'])}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      if (discountCode['valid_until'] != null) ...[
                        Expanded(
                          child: Text(
                            'Valid until: ${_formatDate(discountCode['valid_until'])}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
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
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  );
                }
              },
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
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;
    
    return AlertDialog(
      title: const Text(
        'Create Discount Code',
        style: TextStyle(fontFamily: 'Montserrat'),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
      content: SizedBox(
        width: dialogWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 400) {
                      return Row(
                        children: [

                          Expanded(
                            child: TextFormField(
                              controller: _discountValueController,
                              decoration: InputDecoration(
                                labelText: 'Percentage',
                            suffixText: '%',
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
                                if (numValue > 100) {
                                  return 'Max 100%';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          TextFormField(
                            controller: _discountValueController,
                            decoration: InputDecoration(
                              labelText: 'Percentage',
                              suffixText: '%',
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
                              if (numValue > 100) {
                                  return 'Max 100%';
                                }
                              return null;
                            },
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (widget.userSession.isSuperAdmin) ...[
                  DropdownButtonFormField<int?>(
                    value: _selectedDepartmentId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'All Departments',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      ...widget.departments.map((dept) => DropdownMenuItem<int?>(
                        value: dept['id'],
                        child: Text(
                          dept['name'],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartmentId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        'UDD Official Merch',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Allow for official university merchandise',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _isUddOfficial,
                      onChanged: (value) {
                        setState(() {
                          _isUddOfficial = value ?? false;
                        });
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 400) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildDateTile(
                              'Valid From',
                              _validFrom,
                              () => _selectValidFromDate(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDateTile(
                              'Valid Until',
                              _validUntil,
                              () => _selectValidUntilDate(),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildDateTile(
                            'Valid From',
                            _validFrom,
                            () => _selectValidFromDate(),
                          ),
                          const SizedBox(height: 8),
                          _buildDateTile(
                            'Valid Until',
                            _validUntil,
                            () => _selectValidUntilDate(),
                          ),
                        ],
                      );
                    }
                  },
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

  Widget _buildDateTile(String title, DateTime? date, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          date?.toString().split(' ')[0] ?? 'Not set',
          style: TextStyle(
            fontSize: 12,
            color: date != null ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.calendar_today,
          size: 20,
          color: Colors.grey.shade600,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Future<void> _selectValidFromDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _validFrom ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _validFrom = date;
        // Reset valid until if it's before the new valid from date
        if (_validUntil != null && _validUntil!.isBefore(date)) {
          _validUntil = null;
        }
      });
    }
  }

  Future<void> _selectValidUntilDate() async {
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