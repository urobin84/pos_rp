import 'package:flutter/material.dart';
import 'package:pos_rp/providers/customer_provider.dart';
import 'package:pos_rp/models/customer_model.dart';
import 'package:pos_rp/services/customer_form_dialog.dart';
import 'package:pos_rp/widgets/sized_alert_dialog.dart';
import 'package:pos_rp/widgets/customer_detail_dialog.dart';
import 'package:pos_rp/widgets/charming_modal.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination and filtering state
  final _scrollController = ScrollController();
  List<Customer> _allFilteredCustomers = [];
  List<Customer> _displayedCustomers = [];
  bool _isPaginating = false;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);

    // Initial data load after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _applyFilters();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final providerCustomers = customerProvider.customers;

    // This is the key fix:
    // If the list from the provider has changed (e.g., after initial loading),
    // we re-apply our local filters and pagination.
    // We use `length` for a quick and efficient comparison.
    if (_allFilteredCustomers.length != providerCustomers.length &&
        _searchQuery.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilters());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final bool? result = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) =>
                        const SizedAlertDialog(child: CustomerFormDialog()),
              );
              // Refresh data if the dialog indicates a change was made.
              if (result == true) _refreshData();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari Pelanggan (Nama/Telepon)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
      ),
      body:
          customerProvider.isLoading
              ? _buildShimmerEffect()
              : RefreshIndicator(
                onRefresh: _refreshData,
                child:
                    _allFilteredCustomers.isEmpty && _searchQuery.isNotEmpty
                        ? const Center(
                          child: Text('Pelanggan tidak ditemukan.'),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              _displayedCustomers.length +
                              (_isPaginating ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i == _displayedCustomers.length) {
                              return _buildPaginationShimmer();
                            }
                            final customer = _displayedCustomers[i];
                            return Dismissible(
                              key: ValueKey(customer.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) {
                                return showDialog<bool>(
                                  context: context,
                                  builder:
                                      (dCtx) => AlertDialog(
                                        title: const Text('Are you sure?'),
                                        content: const Text(
                                          'Do you want to remove this customer?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  dCtx,
                                                ).pop(false),
                                            child: const Text('No'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  dCtx,
                                                ).pop(true),
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      ),
                                );
                              },
                              onDismissed: (direction) async {
                                customerProvider.deleteCustomer(customer.id);
                                await showCharmingModal(
                                  context,
                                  title: 'Deleted!',
                                  message: '${customer.name} has been removed.',
                                );
                                // Re-apply filters to update the UI after deletion
                                _applyFilters();
                              },
                              background: Container(
                                color: Colors.red,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 4,
                                ),
                                child: const Card(
                                  color: Colors.red,
                                  elevation: 0,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 20.0),
                                      child: Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 4,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        width: 5.0,
                                      ),
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.only(
                                      left: 10,
                                      right: 16,
                                      top: 8,
                                      bottom: 8,
                                    ),
                                    onTap: () async {
                                      final result = await showDialog<String>(
                                        context: context,
                                        builder:
                                            (ctx) => SizedAlertDialog(
                                              child: CustomerDetailDialog(
                                                customer: customer,
                                              ),
                                            ),
                                      );

                                      if (!context.mounted) return;

                                      bool needsRefresh =
                                          true; // Assume refresh is needed by default

                                      if (result == 'edit') {
                                        final bool? editResult =
                                            await showDialog<bool>(
                                              context: context,
                                              builder:
                                                  (ctx) => SizedAlertDialog(
                                                    child: CustomerFormDialog(
                                                      customer: customer,
                                                    ),
                                                  ),
                                            );
                                        // If user cancels the edit, we don't need the second refresh.
                                        // The first one will handle it.
                                        needsRefresh = editResult == true;
                                      } else if (result == 'delete') {
                                        final confirmDelete = await showDialog<
                                          bool
                                        >(
                                          context: context,
                                          builder:
                                              (dCtx) => AlertDialog(
                                                title: const Text(
                                                  'Are you sure?',
                                                ),
                                                content: const Text(
                                                  'Do you want to remove this customer?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.of(
                                                          dCtx,
                                                        ).pop(false),
                                                    child: const Text('No'),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.of(
                                                          dCtx,
                                                        ).pop(true),
                                                    child: const Text('Yes'),
                                                  ),
                                                ],
                                              ),
                                        );

                                        if (confirmDelete == true &&
                                            context.mounted) {
                                          customerProvider.deleteCustomer(
                                            customer.id,
                                          );
                                          // Use local filter for instant UI update on delete
                                          _applyFilters();
                                          needsRefresh =
                                              false; // No full refresh needed
                                        }
                                      }

                                      if (needsRefresh) {
                                        _refreshData();
                                      }
                                    },
                                    leading: CircleAvatar(
                                      child: Text(customer.name[0]),
                                    ),
                                    title: Text(customer.name),
                                    subtitle: Text(customer.phone),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await Provider.of<CustomerProvider>(
      context,
      listen: false,
    ).fetchCustomers();
    _applyFilters();
  }

  void _onSearchChanged() {
    if (_searchQuery != _searchController.text) {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _applyFilters();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  void _applyFilters() {
    final allCustomers =
        Provider.of<CustomerProvider>(context, listen: false).customers;

    _allFilteredCustomers =
        allCustomers
            .where(
              (c) =>
                  c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  c.phone.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

    // Reset displayed list and load the first page
    setState(() {
      _displayedCustomers = [];
    });
    _loadNextPage();
  }

  void _loadNextPage() {
    if (_isPaginating ||
        _displayedCustomers.length == _allFilteredCustomers.length) {
      return; // Already loading or no more items
    }

    setState(() {
      _isPaginating = true;
    });

    // Simulate a network delay for loading
    Future.delayed(const Duration(milliseconds: 500), () {
      final currentLength = _displayedCustomers.length;
      final remaining = _allFilteredCustomers.length - currentLength;
      final nextPageSize = remaining > _pageSize ? _pageSize : remaining;

      if (nextPageSize > 0) {
        _displayedCustomers.addAll(
          _allFilteredCustomers.sublist(
            currentLength,
            currentLength + nextPageSize,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _isPaginating = false;
        });
      }
    });
  }

  Widget _buildPaginationShimmer() {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(10, (i) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 5.0,
                  ),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.only(
                  left: 10,
                  right: 16,
                  top: 8,
                  bottom: 8,
                ),
                leading: const CircleAvatar(backgroundColor: Colors.white),
                title: Container(height: 16, width: 150, color: Colors.white),
                subtitle: Container(
                  height: 12,
                  width: 100,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: List.generate(
            10,
            (i) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 5.0,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(
                    left: 10,
                    right: 16,
                    top: 8,
                    bottom: 8,
                  ),
                  leading: const CircleAvatar(backgroundColor: Colors.white),
                  title: Container(height: 16, width: 150, color: Colors.white),
                  subtitle: Container(
                    height: 12,
                    width: 100,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
