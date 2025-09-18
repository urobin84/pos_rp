import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/models/product_model.dart';
import 'package:pos_rp/providers/cart_provider.dart';
import 'package:pos_rp/providers/product_provider.dart';
import 'package:pos_rp/widgets/cart_widget.dart';
import 'package:pos_rp/widgets/product_card.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
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

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final isWideScreen = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier'),
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
              ? _buildShimmerEffect(isWideScreen)
              : _allFilteredProducts.isEmpty && _searchQuery.isNotEmpty
              ? const Center(child: Text('Produk tidak ditemukan.'))
              : isWideScreen
              ? _buildWideLayout(context, _displayedProducts)
              : _buildNarrowLayout(context, _displayedProducts),
      floatingActionButton: !isWideScreen ? _buildCartFab(context) : null,
    );
  }

  Widget _buildProductGrid(
    List<Product> products,
    int crossAxisCount, {
    EdgeInsetsGeometry padding = const EdgeInsets.all(10.0),
  }) {
    return GridView.builder(
      controller: _scrollController,
      padding: padding,
      itemCount: products.length + (_isPaginating ? crossAxisCount : 0),
      itemBuilder: (ctx, i) {
        if (i >= products.length) {
          return _buildPaginationShimmerCard();
        }
        return ProductCard(product: products[i]);
      },
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 3 / 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, List<Product> products) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final crossAxisCount = (constraints.maxWidth / 180).floor().clamp(
                2,
                5,
              );
              return _buildProductGrid(products, crossAxisCount);
            },
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            child: const CartWidget(),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, List<Product> products) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final crossAxisCount = (constraints.maxWidth / 180).floor().clamp(2, 3);
        return _buildProductGrid(products, crossAxisCount);
      },
    );
  }

  Widget _buildCartFab(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final priceFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return FloatingActionButton.extended(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder:
              (ctx) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: const CartWidget(),
              ),
        );
      },
      label: Text(priceFormat.format(cart.totalAmount)),
      icon: Badge(
        label: Text('${cart.itemCount}'),
        isLabelVisible: cart.itemCount > 0,
        child: const Icon(Icons.shopping_cart),
      ),
    );
  }

  Widget _buildShimmerEffect(bool isWide) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final crossAxisCount = (constraints.maxWidth / 180).floor().clamp(
          2,
          isWide ? 5 : 3,
        );
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10.0),
            itemCount: 10,
            itemBuilder:
                (ctx, i) => Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(color: Colors.white),
                ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 3 / 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaginationShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(color: Colors.white),
      ),
    );
  }
}
