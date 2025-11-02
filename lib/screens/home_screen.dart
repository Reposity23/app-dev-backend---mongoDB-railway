import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/toy.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Updated Toy Catalog to match the correct Toy model
  static final List<Toy> _toys = [
    // Toy Guns
    Toy(id: 'TG01', name: 'Laser Ray Gun', category: 'Toy Guns', rfidUid: 'TG01_UID', price: 1499.99, imageUrl: 'assets/images/toy_placeholder.png'),
    Toy(id: 'TG02', name: 'Water Blaster 3000', category: 'Toy Guns', rfidUid: 'TG02_UID', price: 999.99, imageUrl: 'assets/images/toy_placeholder.png'),
    Toy(id: 'TG03', name: 'Foam Dart Pistol', category: 'Toy Guns', rfidUid: 'TG03_UID', price: 749.99, imageUrl: 'assets/images/toy_placeholder.png'),
    // Action Figures
    Toy(id: 'AF01', name: 'Galaxy Commander', category: 'Action Figures', rfidUid: 'AF01_UID', price: 649.99, imageUrl: 'assets/images/toy_placeholder.png'),
    Toy(id: 'AF02', name: 'Jungle Explorer', category: 'Action Figures', rfidUid: 'AF02_UID', price: 599.99, imageUrl: 'assets/images/toy_placeholder.png'),
    Toy(id: 'AF03', name: 'Ninja Warrior', category: 'Action Figures', rfidUid: 'AF03_UID', price: 699.99, imageUrl: 'assets/images/toy_placeholder.png'),
    // Dolls
    Toy(id: 'DL01', name: 'Princess Star', category: 'Dolls', rfidUid: 'DL01_UID', price: 1149.99, imageUrl: 'assets/images/toy_placeholder.png'),
    Toy(id: 'DL02', name: 'Fashionista Doll', category: 'Dolls', rfidUid: 'DL02_UID', price: 1249.99, imageUrl: 'assets/images/toy_placeholder.png'),
    Toy(id: 'DL03', name: 'Baby Joy', category: 'Dolls', rfidUid: 'DL03_UID', price: 949.99, imageUrl: 'assets/images/toy_placeholder.png'),
    // Puzzles
    Toy(id: 'PZ01', name: '1000pc World Map', category: 'Puzzles', rfidUid: 'PZ01_UID', price: 799.99, imageUrl: 'assets/images/toy_placeholder.png'),
    Toy(id: 'PZ02', name: '3D Wooden Dinosaur', category: 'Puzzles', rfidUid: 'PZ02_UID', price: 899.99, imageUrl: 'assets/images/toy_placeholder.png'),
    Toy(id: 'PZ03', name: 'Mystery Box Puzzle', category: 'Puzzles', rfidUid: 'PZ03_UID', price: 1099.99, imageUrl: 'assets/images/toy_placeholder.png'),
  ];

  final List<String> _categories = _toys.map((t) => t.category).toSet().toList();
  late String _selectedCategory;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    _animationController.forward();
  }
  
  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 1));
    _animationController.reset();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getAssignedPerson(String category) {
    switch (category) {
      case 'Toy Guns': return 'John Marwin';
      case 'Action Figures': return 'Jannalyn';
      case 'Dolls': return 'Marl Prince';
      case 'Puzzles': return 'Renz';
      default: return 'Unassigned';
    }
  }

  void _showOrderConfirmation(BuildContext context, Toy toy) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Purchase'),
        content: Text('Do you want to buy the ${toy.name} for ${NumberFormat.currency(symbol: '₱').format(toy.price)}?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            onPressed: () {
              final provider = Provider.of<AppProvider>(context, listen: false);
              provider.createOrder(
                toyId: toy.id,
                toyName: toy.name,
                category: toy.category,
                rfidUid: toy.rfidUid,
                assignedPerson: _getAssignedPerson(toy.category),
                totalAmount: toy.price,
              );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order placed successfully!'), backgroundColor: Colors.green),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredToys = _toys.where((t) => t.category == _selectedCategory).toList();

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: CustomScrollView(
        slivers: [
          _buildPromoBanner(),
          _buildCategoryHeader(),
          _buildCategorySelector(),
          if (_isLoading)
            _buildShimmerList()
          else
            _buildToyList(filteredToys),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).primaryColor, Colors.red.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Toy Fest Challenge',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find your favorite toys and get rewarded!',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Explore Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          'Categories',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1D3557)),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = category == _selectedCategory;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  _animationController.reset();
                  _animationController.forward();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Theme.of(context).primaryColor, width: 1.5),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
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

  Widget _buildToyList(List<Toy> toys) {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final toy = toys[index];
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildToyListItem(toy),
            );
          },
          childCount: toys.length,
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: const ToyListItemShimmer(),
          ),
          childCount: 5,
        ),
      ),
    );
  }

  Widget _buildToyListItem(Toy toy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToyImage(toy),
          _buildToyDetails(toy),
        ],
      ),
    );
  }

  Widget _buildToyImage(Toy toy) {
    return SizedBox(
      width: 140,
      height: 160,
      child: Image.asset(
        toy.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.toys, size: 80, color: Colors.grey);
        },
      ),
    );
  }

  Widget _buildToyDetails(Toy toy) {
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              toy.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1D3557)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Removed Rating widget
            const SizedBox(height: 12),
            Text(
              currencyFormatter.format(toy.price),
              style: TextStyle(fontSize: 22, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () => _showOrderConfirmation(context, toy),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF457B9D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Buy Now', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ToyListItemShimmer extends StatelessWidget {
  const ToyListItemShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            height: 160,
            color: Colors.white,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 20, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 16, color: Colors.white),
                  const SizedBox(height: 12),
                  Container(width: 80, height: 24, color: Colors.white),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(width: 100, height: 36, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
