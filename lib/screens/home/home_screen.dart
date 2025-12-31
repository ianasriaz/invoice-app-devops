import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gsheet/constants/app_colors.dart';
import 'package:gsheet/screens/account_screen.dart';
import 'package:gsheet/screens/create_invoice_screen.dart';
import 'package:gsheet/screens/drawer.dart';
import 'package:gsheet/screens/invoices_list_screen.dart';
import 'package:gsheet/screens/manage_clients_screen.dart';
import 'package:gsheet/screens/manage_services_screen.dart';

class HomeScreen extends StatefulWidget {
  final String signURL;

  const HomeScreen({Key? key, required this.signURL}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Color _brandColor = AppColors.primary;

  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _brandColor = Theme.of(context).colorScheme.primary;
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 800));
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // Responsive breakpoints
  bool _isMobile(double width) => width < 600;
  bool _isDesktop(double width) => width >= 900;

  int _getCrossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 2;
  }

  double _getChildAspectRatio(double width) {
    if (width >= 1200) return 1.3;
    if (width >= 900) return 1.2;
    if (width >= 600) return 1.15;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final isDesktop = _isDesktop(width);
    final isMobile = _isMobile(width);
    final horizontalPadding = isDesktop ? 40.0 : (isMobile ? 20.0 : 32.0);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FD),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Enhanced ambient background with multiple blur circles
          Positioned(
            top: -150,
            left: -100,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(
                    height: 400,
                    width: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _brandColor.withOpacity(0.15),
                          _brandColor.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                height: 350,
                width: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: _brandColor,
              backgroundColor: Colors.white,
              strokeWidth: 3,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(context, horizontalPadding, isMobile),
                  ),

                  // Data Stream
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('invoices')
                        .where('userId', isEqualTo: userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int totalInvoices = 0;
                      int paidCount = 0;
                      double totalRevenue = 0;
                      int pendingCount = 0;

                      if (snapshot.hasData) {
                        totalInvoices = snapshot.data!.docs.length;
                        for (var doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'] as String?;
                          final total = double.tryParse(
                                  data['total']?.toString() ?? '0') ??
                              0.0;

                          if (status == 'paid') {
                            paidCount++;
                            totalRevenue += total;
                          } else if (status == 'sent' || status == 'draft') {
                            pendingCount++;
                          }
                        }
                      }

                      return SliverPadding(
                        padding:
                            EdgeInsets.symmetric(horizontal: horizontalPadding),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            SizedBox(height: isMobile ? 16 : 20),

                            // Revenue Card
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _EnhancedRevenueCard(
                                revenue: totalRevenue,
                                brandColor: _brandColor,
                                isMobile: isMobile,
                              ),
                            ),

                            SizedBox(height: isMobile ? 28 : 40),

                            // Overview Stats
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _sectionTitle('Overview', isMobile),
                            ),
                            SizedBox(height: isMobile ? 12 : 16),
                            _buildStatsRow(
                              totalInvoices,
                              pendingCount,
                              paidCount,
                              isMobile,
                            ),

                            SizedBox(height: isMobile ? 28 : 40),

                            // Quick Actions Title
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _sectionTitle('Quick Actions', isMobile),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),

                  // Quick Actions Grid
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      isMobile ? 12 : 16,
                      horizontalPadding,
                      100,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getCrossAxisCount(width),
                        childAspectRatio: _getChildAspectRatio(width),
                        crossAxisSpacing: isMobile ? 16 : 20,
                        mainAxisSpacing: isMobile ? 16 : 20,
                      ),
                      delegate: SliverChildListDelegate([
                        _EnhancedActionCard(
                          title: 'New Invoice',
                          icon: Icons.add_circle_outline_rounded,
                          accentColor: _brandColor,
                          delay: 200,
                          isMobile: isMobile,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateInvoiceScreen(),
                            ),
                          ),
                        ),
                        _EnhancedActionCard(
                          title: 'Invoices',
                          icon: Icons.description_outlined,
                          accentColor: const Color(0xFF2196F3),
                          delay: 300,
                          isMobile: isMobile,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InvoicesListScreen(),
                            ),
                          ),
                        ),
                        _EnhancedActionCard(
                          title: 'Clients',
                          icon: Icons.people_outline_rounded,
                          accentColor: const Color(0xFFFF9800),
                          delay: 400,
                          isMobile: isMobile,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageClientsScreen(),
                            ),
                          ),
                        ),
                        _EnhancedActionCard(
                          title: 'Services',
                          icon: Icons.category_outlined,
                          accentColor: const Color(0xFF9C27B0),
                          delay: 500,
                          isMobile: isMobile,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageServicesScreen(),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _EnhancedFAB(
        brandColor: _brandColor,
        isMobile: isMobile,
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateInvoiceScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double padding, bool isMobile) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        padding,
        isMobile ? 16 : 24,
        padding,
        isMobile ? 16 : 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Greetings
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: isMobile ? 26 : 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey[900],
                      letterSpacing: -0.8,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Icons
          Row(
            children: [
              _GlassButton(
                icon: Icons.person_rounded,
                isMobile: isMobile,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  );
                },
              ),
              SizedBox(width: isMobile ? 8 : 12),
              _GlassButton(
                icon: Icons.menu_rounded,
                isMobile: isMobile,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, bool isMobile) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: isMobile ? 11 : 12,
        fontWeight: FontWeight.w900,
        color: Colors.grey[700],
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildStatsRow(int total, int pending, int paid, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = isMobile ? 12.0 : 16.0;

        return Row(
          children: [
            Expanded(
              child: _EnhancedStatCard(
                label: 'Invoices',
                value: total.toString(),
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF607D8B),
                delay: 100,
                isMobile: isMobile,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _EnhancedStatCard(
                label: 'Pending',
                value: pending.toString(),
                icon: Icons.hourglass_empty_rounded,
                color: const Color(0xFFFF9800),
                delay: 200,
                isMobile: isMobile,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _EnhancedStatCard(
                label: 'Paid',
                value: paid.toString(),
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF4CAF50),
                delay: 300,
                isMobile: isMobile,
              ),
            ),
          ],
        );
      },
    );
  }
}

// Enhanced Revenue Card
class _EnhancedRevenueCard extends StatelessWidget {
  final double revenue;
  final Color brandColor;
  final bool isMobile;

  const _EnhancedRevenueCard({
    required this.revenue,
    required this.brandColor,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brandColor, brandColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: brandColor.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: brandColor.withOpacity(0.2),
            blurRadius: 48,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Total Revenue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 20 : 24),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Rs ${revenue.toStringAsFixed(0)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 36 : 48,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Lifetime',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'All time earnings',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Enhanced Action Card
class _EnhancedActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final int delay;
  final bool isMobile;
  final VoidCallback onTap;

  const _EnhancedActionCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.delay,
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<_EnhancedActionCard> createState() => _EnhancedActionCardState();
}

class _EnhancedActionCardState extends State<_EnhancedActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 700 + widget.delay),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) => Transform.scale(
        scale: val * (_isPressed ? 0.95 : 1.0),
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(widget.isMobile ? 20 : 24),
            border: Border.all(
              color: widget.accentColor.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(widget.isMobile ? 14 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.accentColor.withOpacity(0.15),
                      widget.accentColor.withOpacity(0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.accentColor,
                  size: widget.isMobile ? 28 : 32,
                ),
              ),
              SizedBox(height: widget.isMobile ? 12 : 16),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: widget.isMobile ? 14 : 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced Stat Card
class _EnhancedStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;
  final bool isMobile;

  const _EnhancedStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 700 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) => Transform.scale(
        scale: val,
        child: Opacity(opacity: val, child: child),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 20 : 24,
          horizontal: isMobile ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          border: Border.all(color: color.withOpacity(0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: isMobile ? 20 : 24,
              ),
            ),
            SizedBox(height: isMobile ? 10 : 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey[900],
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced Glass Button
class _GlassButton extends StatefulWidget {
  final IconData icon;
  final bool isMobile;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.isMobile ? 42.0 : 48.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(widget.isMobile ? 12 : 14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.grey[800],
            size: widget.isMobile ? 20 : 22,
          ),
        ),
      ),
    );
  }
}

// Enhanced FAB
class _EnhancedFAB extends StatelessWidget {
  final Color brandColor;
  final bool isMobile;
  final VoidCallback onPressed;

  const _EnhancedFAB({
    required this.brandColor,
    required this.isMobile,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: brandColor,
      elevation: 8,
      highlightElevation: 12,
      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      label: Text(
        "Create Invoice",
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: isMobile ? 14 : 15,
          letterSpacing: 0.3,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
