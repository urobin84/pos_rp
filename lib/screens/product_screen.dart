import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/providers/product_provider.dart';
import 'package:pos_rp/models/product_model.dart';
import 'package:pos_rp/services/product_form_dialog.dart';
import 'package:pos_rp/widgets/product_detail_dialog.dart';
import 'package:pos_rp/widgets/sized_alert_dialog.dart';
import 'package:pos_rp/widgets/charming_modal.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination and filtering state
  final _scrollController = ScrollController();
  List<Product> _allFilteredProducts = [];
  List<Product> _displayedProducts = [];
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

  Future<void> _refreshData() async {
    // This will call the provider to refetch the product list.
    // After fetching, it will re-apply the local search filters.
    await Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    _applyFilters(); // Re-apply search and pagination after refresh
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final theme = Theme.of(context);
    final priceFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final bool? result = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => const SizedAlertDialog(child: ProductFormDialog()),
              );
              if (result == true) {
                _refreshData();
              }
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
                labelText: 'Cari Produk',
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
          productProvider.isLoading
              ? _buildShimmerEffect()
              : RefreshIndicator(
                onRefresh: _refreshData,
                child:
                    _allFilteredProducts.isEmpty && _searchQuery.isNotEmpty
                        ? const Center(child: Text('Produk tidak ditemukan.'))
                        : ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              _displayedProducts.length +
                              (_isPaginating ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i == _displayedProducts.length) {
                              return _buildPaginationShimmer();
                            }
                            final product = _displayedProducts[i];
                            return Dismissible(
                              key: ValueKey(product.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) {
                                return showDialog<bool>(
                                  context: context,
                                  builder:
                                      (dCtx) => AlertDialog(
                                        title: const Text('Are you sure?'),
                                        content: const Text(
                                          'Do you want to remove this product?',
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
                                productProvider.deleteProduct(product.id);
                                await showCharmingModal(
                                  context,
                                  title: 'Deleted!',
                                  message: '${product.name} has been removed.',
                                );
                                // Re-apply filters to update the UI after deletion
                                _applyFilters();
                              },
                              background: Card(
                                color: Colors.red,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 4,
                                ),
                                child: const Align(
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
                                        color: theme.colorScheme.primary,
                                        width: 5.0,
                                      ),
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      final result = await showDialog<String>(
                                        context: context,
                                        builder:
                                            (ctx) => SizedAlertDialog(
                                              child: ProductDetailDialog(
                                                product: product,
                                              ),
                                            ),
                                      );

                                      // Always refresh data after the detail dialog is closed.
                                      _refreshData();

                                      if (!context.mounted) return;

                                      if (result == 'edit') {
                                        final bool? editResult =
                                            await showDialog<bool>(
                                              context: context,
                                              builder:
                                                  (ctx) => SizedAlertDialog(
                                                    child: ProductFormDialog(
                                                      product: product,
                                                    ),
                                                  ),
                                            );
                                        // Refresh the list only if the edit was successful
                                        if (editResult == true) {
                                          _refreshData();
                                        }
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
                                                  'Do you want to remove this product?',
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
                                          productProvider.deleteProduct(
                                            product.id,
                                          );
                                          // Re-apply filters to update the UI after deletion
                                          _applyFilters();
                                        }
                                      }
                                    },
                                    child: SizedBox(
                                      height: 134,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          SizedBox(
                                            width: 100,
                                            child: Builder(
                                              builder: (context) {
                                                final imageUrl =
                                                    product.imageUrl;
                                                Widget imageWidget;
                                                if (imageUrl.startsWith(
                                                  'http',
                                                )) {
                                                  imageWidget = Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Container(
                                                          color:
                                                              theme
                                                                  .colorScheme
                                                                  .primaryContainer,
                                                          child: Icon(
                                                            Icons.inventory_2,
                                                            color:
                                                                theme
                                                                    .colorScheme
                                                                    .onPrimaryContainer,
                                                          ),
                                                        ),
                                                  );
                                                } else {
                                                  final file = File(imageUrl);
                                                  if (file.existsSync()) {
                                                    imageWidget = Image.file(
                                                      file,
                                                      fit: BoxFit.cover,
                                                    );
                                                  } else {
                                                    imageWidget = Container(
                                                      //
                                                      color:
                                                          theme
                                                              .colorScheme
                                                              .primaryContainer,
                                                      child: Icon(
                                                        Icons.inventory_2,
                                                        color:
                                                            theme
                                                                .colorScheme
                                                                .onPrimaryContainer,
                                                      ),
                                                    );
                                                  }
                                                }
                                                return imageWidget;
                                              },
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                12.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Expanded(
                                                    child: Text(
                                                      product.description,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 3,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${priceFormat.format(product.price)} - Stock: ${product.stock}',
                                                    style: TextStyle(
                                                      color:
                                                          theme
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
    final allProducts =
        Provider.of<ProductProvider>(context, listen: false).products;

    _allFilteredProducts =
        allProducts
            .where(
              (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

    // Reset displayed list and load the first page
    setState(() {
      _displayedProducts = [];
    });
    _loadNextPage();
  }

  void _loadNextPage() {
    if (_isPaginating ||
        _displayedProducts.length == _allFilteredProducts.length) {
      return; // Already loading or no more items
    }

    setState(() {
      _isPaginating = true;
    });

    // Simulate a network delay for loading
    Future.delayed(const Duration(milliseconds: 500), () {
      final currentLength = _displayedProducts.length;
      final remaining = _allFilteredProducts.length - currentLength;
      final nextPageSize = remaining > _pageSize ? _pageSize : remaining;

      if (nextPageSize > 0) {
        _displayedProducts.addAll(
          _allFilteredProducts.sublist(
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

  Widget _buildShimmerEffect() {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: List.generate(
            6,
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
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 100, color: Colors.white),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 150,
                                height: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                height: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 200,
                                height: 12,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationShimmer() {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
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
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 100, color: Colors.white),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 150,
                              height: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              height: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
