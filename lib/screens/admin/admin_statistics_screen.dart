import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

enum StatsPeriod {
  hourly,
  daily,
  weekly,
  biWeekly,
  monthly,
  quarterly,
}

extension StatsPeriodExtension on StatsPeriod {
  String get displayName {
    switch (this) {
      case StatsPeriod.hourly:
        return 'Hourly';
      case StatsPeriod.daily:
        return 'Daily';
      case StatsPeriod.weekly:
        return 'Weekly';
      case StatsPeriod.biWeekly:
        return 'Bi-Weekly';
      case StatsPeriod.monthly:
        return 'Monthly';
      case StatsPeriod.quarterly:
        return 'Quarterly';
    }
  }
}

class AdminStatisticsScreen extends StatefulWidget {
  final LocalStorageService storageService;

  const AdminStatisticsScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  List<Order> _orders = [];
  StatsPeriod _selectedPeriod = StatsPeriod.daily;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await widget.storageService.getOrders();
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  List<Order> get _deliveredOrders =>
      _orders.where((o) => o.status == OrderStatus.delivered).toList();

  double get _totalRevenue =>
      _deliveredOrders.fold(0.0, (sum, o) => sum + o.total);

  int get _totalOrders => _deliveredOrders.length;

  double get _averageOrderValue =>
      _totalOrders > 0 ? _totalRevenue / _totalOrders : 0;

  int get _totalItemsSold => _deliveredOrders.fold(
      0, (sum, o) => sum + o.items.fold(0, (s, i) => s + i.quantity));

  Map<String, _PeriodStats> get _periodStats {
    final now = DateTime.now();
    final stats = <String, _PeriodStats>{};

    for (final order in _deliveredOrders) {
      final key = _getKeyForPeriod(order.deliveredAt ?? order.createdAt, now);
      if (key != null) {
        if (!stats.containsKey(key)) {
          stats[key] = _PeriodStats(label: key);
        }
        stats[key]!.revenue += order.total;
        stats[key]!.orders++;
        stats[key]!.items +=
            order.items.fold(0, (sum, i) => sum + i.quantity);
      }
    }

    return stats;
  }

  String? _getKeyForPeriod(DateTime date, DateTime now) {
    switch (_selectedPeriod) {
      case StatsPeriod.hourly:
        // Last 24 hours
        if (now.difference(date).inHours <= 24) {
          return '${date.hour}:00';
        }
        return null;
      case StatsPeriod.daily:
        // Last 7 days
        if (now.difference(date).inDays <= 7) {
          return _getDayName(date.weekday);
        }
        return null;
      case StatsPeriod.weekly:
        // Last 4 weeks
        final weekNum = (now.difference(date).inDays / 7).floor();
        if (weekNum < 4) {
          return weekNum == 0 ? 'This Week' : 'Week -$weekNum';
        }
        return null;
      case StatsPeriod.biWeekly:
        // Last 2 bi-weekly periods
        final biWeekNum = (now.difference(date).inDays / 14).floor();
        if (biWeekNum < 2) {
          return biWeekNum == 0 ? 'Current' : 'Previous';
        }
        return null;
      case StatsPeriod.monthly:
        // Last 6 months
        final monthDiff = (now.year - date.year) * 12 + now.month - date.month;
        if (monthDiff < 6) {
          return _getMonthName(date.month);
        }
        return null;
      case StatsPeriod.quarterly:
        // Last 4 quarters
        final quarter = ((date.month - 1) / 3).floor() + 1;
        final currentQuarter = ((now.month - 1) / 3).floor() + 1;
        final yearDiff = now.year - date.year;
        final quarterDiff = yearDiff * 4 + currentQuarter - quarter;
        if (quarterDiff < 4) {
          return 'Q$quarter ${date.year}';
        }
        return null;
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Map<String, int> get _topProducts {
    final productSales = <String, int>{};
    for (final order in _deliveredOrders) {
      for (final item in order.items) {
        productSales[item.product.name] =
            (productSales[item.product.name] ?? 0) + item.quantity;
      }
    }
    final sorted = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }

  Map<String, double> get _categoryRevenue {
    final catRevenue = <String, double>{};
    for (final order in _deliveredOrders) {
      for (final item in order.items) {
        catRevenue[item.product.category] =
            (catRevenue[item.product.category] ?? 0) + item.totalPrice;
      }
    }
    return catRevenue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deliveredOrders.isEmpty
              ? const EmptyState(
                  icon: Icons.bar_chart_outlined,
                  title: 'No sales data yet',
                  subtitle: 'Complete some orders to see statistics',
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Cards
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.attach_money,
                                label: 'Total Revenue',
                                value: '₹${_totalRevenue.toStringAsFixed(0)}',
                                color: AppTheme.successPastel,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.shopping_bag,
                                label: 'Total Orders',
                                value: '$_totalOrders',
                                color: AppTheme.secondaryPastel,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.trending_up,
                                label: 'Avg. Order Value',
                                value: '₹${_averageOrderValue.toStringAsFixed(0)}',
                                color: AppTheme.primaryPastel,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.inventory,
                                label: 'Items Sold',
                                value: '$_totalItemsSold',
                                color: AppTheme.accentPastel,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Period Selector
                        const Text(
                          'Sales Breakdown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: StatsPeriod.values
                                .map((period) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(period.displayName),
                                        selected: _selectedPeriod == period,
                                        onSelected: (_) => setState(
                                            () => _selectedPeriod = period),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Period Stats
                        if (_periodStats.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'No data for selected period',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                          )
                        else
                          ..._buildPeriodChart(),

                        const SizedBox(height: 24),

                        // Top Products
                        const Text(
                          'Top Selling Products',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._topProducts.entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ProductRankCard(
                                rank: _topProducts.keys.toList().indexOf(entry.key) + 1,
                                name: entry.key,
                                quantity: entry.value,
                                maxQuantity: _topProducts.values.first,
                              ),
                            )),

                        const SizedBox(height: 24),

                        // Category Revenue
                        const Text(
                          'Revenue by Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._categoryRevenue.entries.map((entry) {
                          final percentage =
                              (entry.value / _totalRevenue * 100);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _CategoryRevenueCard(
                              category: entry.key,
                              revenue: entry.value,
                              percentage: percentage,
                            ),
                          );
                        }),

                        const SizedBox(height: 24),

                        // Recent Transactions
                        const Text(
                          'Recent Sales',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._deliveredOrders.take(5).map((order) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _RecentSaleCard(order: order),
                            )),
                      ],
                    ),
                  ),
                ),
    );
  }

  List<Widget> _buildPeriodChart() {
    final stats = _periodStats.values.toList();
    final maxRevenue =
        stats.fold(0.0, (max, s) => s.revenue > max ? s.revenue : max);

    return [
      // Bar chart
      Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: stats.map((stat) {
            final heightPercent = maxRevenue > 0 ? stat.revenue / maxRevenue : 0.0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '₹${(stat.revenue / 1000).toStringAsFixed(1)}k',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: heightPercent.clamp(0.05, 1.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.primaryPastel,
                                AppTheme.secondaryPastel,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stat.label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 16),
      // Stats summary table
      AppCard(
        child: Column(
          children: [
            Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Period',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Orders',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Items',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Revenue',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...stats.map((stat) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(stat.label),
                      ),
                      Expanded(
                        child: Text(
                          '${stat.orders}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${stat.items}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '₹${stat.revenue.toStringAsFixed(2)}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    ];
  }
}

class _PeriodStats {
  final String label;
  double revenue = 0;
  int orders = 0;
  int items = 0;

  _PeriodStats({required this.label});
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRankCard extends StatelessWidget {
  final int rank;
  final String name;
  final int quantity;
  final int maxQuantity;

  const _ProductRankCard({
    required this.rank,
    required this.name,
    required this.quantity,
    required this.maxQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final progress = quantity / maxQuantity;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? AppTheme.warningPastel
                  : AppTheme.backgroundLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: rank <= 3 ? (Theme.of(context).brightness == Brightness.dark ? AppTheme.yellowDark : AppTheme.warningPastel) : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.backgroundLight,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryPastel),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$quantity sold',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRevenueCard extends StatelessWidget {
  final String category;
  final double revenue;
  final double percentage;

  const _CategoryRevenueCard({
    required this.category,
    required this.revenue,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.secondaryPastel.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.category_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppTheme.backgroundLight,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.accentPastel),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${revenue.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentSaleCard extends StatelessWidget {
  final Order order;

  const _RecentSaleCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.successPastel.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.greenDark : AppTheme.successPastel,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.userName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${order.totalItems} items • ${_formatDate(order.deliveredAt ?? order.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${order.total.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.greenDark : AppTheme.successPastel,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
