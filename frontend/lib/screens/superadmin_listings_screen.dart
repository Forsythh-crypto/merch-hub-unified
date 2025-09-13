import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/admin_service.dart';
import '../config/app_config.dart';
import '../models/user_role.dart';
import 'superadmin_edit_listing_screen.dart';

class SuperAdminListingsScreen extends StatefulWidget {
  final UserSession userSession;

  const SuperAdminListingsScreen({super.key, required this.userSession});

  @override
  State<SuperAdminListingsScreen> createState() =>
      _SuperAdminListingsScreenState();
}

class _SuperAdminListingsScreenState extends State<SuperAdminListingsScreen> {
  List<Listing> _listings = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);

    try {
      final listings = await AdminService.getAllListings();

      // Extract unique categories
      final categorySet = <String>{'All'};
      for (final listing in listings) {
        if (listing.category?.name != null) {
          categorySet.add(listing.category!.name);
        }
      }

      setState(() {
        _listings = listings;
        _categories = categorySet.toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading listings: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Listing> get _filteredListings {
    return _listings.where((listing) {
      final matchesSearch =
          listing.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (listing.description?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);

      final matchesCategory =
          _selectedCategory == 'All' ||
          listing.category?.name == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Section
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              // Category Filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = category == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: const Color(0xFF1E3A8A),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Products Grid
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredListings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No listings found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: _filteredListings.length,
                  itemBuilder: (context, index) {
                    final listing = _filteredListings[index];
                    return _buildListingCard(listing);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildListingCard(Listing listing) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 120,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
             child: listing.images != null && listing.images!.isNotEmpty
                 ? ClipRRect(
                     borderRadius: const BorderRadius.only(
                       topLeft: Radius.circular(16),
                       bottomLeft: Radius.circular(16),
                     ),
                     child: PageView.builder(
                       itemCount: listing.images!.length,
                       itemBuilder: (context, index) {
                         final image = listing.images![index];
                         return Image.network(
                           Uri.encodeFull(AppConfig.fileUrl(image.imagePath)),
                           fit: BoxFit.cover,
                           errorBuilder: (context, error, stackTrace) {
                             return const Icon(
                               Icons.image,
                               size: 50,
                               color: Colors.grey,
                             );
                           },
                         );
                       },
                     ),
                   )
                 : listing.imagePath != null
                     ? ClipRRect(
                         borderRadius: const BorderRadius.only(
                           topLeft: Radius.circular(16),
                           bottomLeft: Radius.circular(16),
                         ),
                         child: Image.network(
                           '${AppConfig.baseUrl}/api/files/${listing.imagePath}',
                           fit: BoxFit.cover,
                           errorBuilder: (context, error, stackTrace) {
                             return const Icon(
                               Icons.image,
                               size: 50,
                               color: Colors.grey,
                             );
                           },
                         ),
                       )
                     : const Icon(Icons.image, size: 50, color: Colors.grey),
           ),

          // Product Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              listing.title,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(listing.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              listing.status.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                       Text(
                         '${listing.department?.name ?? 'N/A'} • ${listing.category?.name ?? 'N/A'}',
                         style: TextStyle(color: Colors.grey[600], fontSize: 14),
                       ),
                       const SizedBox(height: 8),
                       Text(
                         '₱${listing.price.toStringAsFixed(2)}',
                         style: const TextStyle(
                           fontWeight: FontWeight.bold,
                           color: Color(0xFF1E3A8A),
                           fontSize: 16,
                         ),
                       ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SuperAdminEditListingScreen(
                                  listing: listing,
                                  userSession: widget.userSession,
                                  onListingUpdated: () => _loadListings(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit', style: TextStyle(fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteListing(listing),
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Delete', style: TextStyle(fontSize: 14)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
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
  }

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
        _loadListings();
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
}
