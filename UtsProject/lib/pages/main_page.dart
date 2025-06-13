import 'package:calendar_appbar/calendar_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:utsproject/pages/home_page.dart';
import 'package:utsproject/pages/category_page.dart';
import 'package:utsproject/pages/transaction_page.dart';
import 'package:utsproject/pages/profile_page.dart';
import 'package:utsproject/services/category_services.dart';
import 'package:utsproject/services/transaction_service.dart';
import 'package:intl/intl.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  final GlobalKey<CategoryPageState> _categoryPageKey = GlobalKey<CategoryPageState>();
  late List<Widget> _children;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  int currentIndex = 0;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateChildren();

    // Setup animation for FAB
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );

    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _updateChildren() {
    _children = [
      HomePage(selectedDate: selectedDate),
      CategoryPage(key: _categoryPageKey),
    ];
  }

  void onTapTapped(int index) {
    if (index != currentIndex) {
      HapticFeedback.lightImpact();
      setState(() {
        currentIndex = index;
      });

      // Animate FAB when switching tabs
      _fabAnimationController.reset();
      _fabAnimationController.forward();
    }
  }

  // Navigate to profile page
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pastikan Provider tersedia di sini
    final categoryService = Provider.of<CategoryService>(context);
    final transactionService = Provider.of<TransactionService>(context);

    return Scaffold(
      extendBody: true, // Important for bottom nav bar transparency
      appBar: currentIndex == 0
          ? _buildHomeAppBar()
          : AppBar(
        title: Text(
          'Categories',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Profile button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            onPressed: _navigateToProfile,
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh categories using the public method
              _categoryPageKey.currentState?.refreshCategories();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Categories refreshed!',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.deepPurple,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality if needed
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Search functionality coming soon!',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.deepPurple,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            if (currentIndex == 0) {
              // Debug log
              debugPrint('Opening transaction page with date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}');

              // Tambah transaksi - now using the dedicated transaction page with selected date
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionPage(initialDate: selectedDate),
                ),
              ).then((_) {
                // Force refresh when returning from transaction page
                setState(() {
                  // Buat instance baru dari HomePage dengan tanggal yang sama
                  _children[0] = HomePage(selectedDate: selectedDate);
                });

                // Debug print all transactions after adding
                transactionService.debugPrintAllTransactions();
              });
            } else if (currentIndex == 1) {
              _categoryPageKey.currentState?.openDialog();
            }
          },
          backgroundColor: Colors.deepPurple,
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: _children,
          ),
          // Only show profile button on home page
          if (currentIndex == 0)
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _navigateToProfile,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: Colors.white,
          elevation: 0,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => onTapTapped(0),
                    splashColor: Colors.deepPurple.withOpacity(0.1),
                    highlightColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_rounded,
                          color: currentIndex == 0 ? Colors.deepPurple : Colors.grey.shade500,
                          size: 26,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Home",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: currentIndex == 0 ? FontWeight.w600 : FontWeight.w500,
                            color: currentIndex == 0 ? Colors.deepPurple : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 80), // Space for FAB
                Expanded(
                  child: InkWell(
                    onTap: () => onTapTapped(1),
                    splashColor: Colors.deepPurple.withOpacity(0.1),
                    highlightColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_rounded,
                          color: currentIndex == 1 ? Colors.deepPurple : Colors.grey.shade500,
                          size: 26,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Categories",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: currentIndex == 1 ? FontWeight.w600 : FontWeight.w500,
                            color: currentIndex == 1 ? Colors.deepPurple : Colors.grey.shade500,
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
    );
  }

  // Build the CalendarAppBar for the home tab
  PreferredSizeWidget _buildHomeAppBar() {
    return CalendarAppBar(
      onDateChanged: (value) {
        // Debug log
        debugPrint('Calendar date selected: ${DateFormat('yyyy-MM-dd').format(value)}');

        setState(() {
          selectedDate = value;
          // Buat instance baru dari HomePage dengan tanggal yang baru
          _children[0] = HomePage(selectedDate: selectedDate);
        });
      },
      firstDate: DateTime.now().subtract(const Duration(days: 140)),
      lastDate: DateTime.now(),
      selectedDate: selectedDate,
      accent: Colors.deepPurple,
      locale: 'id',
      backButton: false,
      events: const [],
    );
  }
}