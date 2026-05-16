import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/home_view_model.dart';
import '../ordonnances/document_view.dart';
import '../stock/stock_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 18),
                    _buildWeekBlock(context),
                    const SizedBox(height: 92),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              imagePath: 'assets/images/card_docs.png',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const DocumentView()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ActionCard(
                              imagePath: 'assets/images/card_stock.png',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const StockView()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppTheme.softBlue,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Code de partage', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            'Partagez ce code avec votre aidant',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _viewModel.shareCode,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        letterSpacing: 1.5,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: () async {
                  final ok = await _viewModel.shareCurrentCode();
                  if (!mounted || ok) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code de partage indisponible pour le moment')),
                  );
                },
                icon: const Icon(Icons.share_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Image.asset('assets/images/logo.png', width: 24, height: 24),
              const SizedBox(width: 8),
              Text(
                'Hello, ${_viewModel.capitalize(_viewModel.firstName)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekBlock(BuildContext context) {
    final fr = DateFormat('d MMM yyyy', 'fr_FR');
    final weekday = DateFormat('EEEE', 'fr_FR');
    final weekStart = _viewModel.weekStart(_viewModel.focusedDay);
    final weekEnd = _viewModel.weekEnd(_viewModel.focusedDay);
    final weekRangeLabel =
        '${DateFormat('d MMM', 'fr_FR').format(weekStart)} - ${DateFormat('d MMM', 'fr_FR').format(weekEnd)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _viewModel.capitalize(weekday.format(_viewModel.selectedDay)),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Text(fr.format(_viewModel.selectedDay), style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _viewModel.goPreviousWeek,
                icon: const Icon(Icons.chevron_left),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  weekRangeLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              IconButton(
                onPressed: _viewModel.goNextWeek,
                icon: const Icon(Icons.chevron_right),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TableCalendar(
              locale: 'fr_FR',
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: _viewModel.focusedDay,
              selectedDayPredicate: (day) => isSameDay(_viewModel.selectedDay, day),
              eventLoader: _viewModel.appointmentsForDay,
              calendarFormat: CalendarFormat.week,
              availableCalendarFormats: const {CalendarFormat.week: 'Semaine'},
              headerVisible: false,
              startingDayOfWeek: StartingDayOfWeek.monday,
              onDaySelected: _viewModel.onDaySelected,
              onPageChanged: _viewModel.onPageChanged,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
              calendarStyle: CalendarStyle(
                markersMaxCount: 1,
                todayDecoration: BoxDecoration(
                  color: AppTheme.softBlue,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.imagePath,
    required this.onTap,
  });

  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 158,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFFE9BDE0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imagePath,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
