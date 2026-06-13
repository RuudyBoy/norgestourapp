import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'groups_page.dart';
import 'playoffs_page.dart';

class ResultsPage extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const ResultsPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.nightSurface1 : AppColors.sand1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Kampoppsett",
          style: AppText.uiTitle.copyWith(
            color: isDark ? AppColors.nightInk : AppColors.ink,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.nightInk : AppColors.ink,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.nightInk : AppColors.ink,
          unselectedLabelColor: isDark ? AppColors.nightInk3 : AppColors.ink3,
          indicatorColor: AppColors.coral,
          indicatorWeight: 3,
          labelStyle: AppText.uiCta,
          unselectedLabelStyle: AppText.uiCta,
          tabs: const [
            Tab(text: "Puljespill"),
            Tab(text: "Sluttspill"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          GroupsPage(tournamentId: widget.tournamentId),
          PlayoffsPage(tournamentId: widget.tournamentId),
        ],
      ),
    );
  }
}
