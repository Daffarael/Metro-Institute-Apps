import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/datasources/remote/leaderboard_remote_datasource.dart';
import '../widgets/metro_leaderboard_view.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _ds = sl<LeaderboardRemoteDataSource>();

  bool _isLoading = true;
  List<dynamic> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await _ds.getLeaderboard(period: 'all-time');
      if (!mounted) return;
      setState(() {
        _entries = (data['entries'] as List<dynamic>?) ?? [];
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08261B), // Deep Emerald Dark Metro
      body: MetroLeaderboardView(
        entries: _entries,
        isLoading: _isLoading,
        onRefresh: _loadLeaderboard,
        onBack: Navigator.of(context).canPop() ? () => Navigator.of(context).pop() : null,
      ),
    );
  }
}
