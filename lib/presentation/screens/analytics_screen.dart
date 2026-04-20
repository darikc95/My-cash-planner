// Слой: presentation | Назначение: экран аналитики с BarChart (fl_chart)

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// Для подключения реальных данных:
// 1. Добавьте AnalyticsBloc с нужными use cases
// 2. Оберните в BlocBuilder<AnalyticsBloc, AnalyticsState>
// 3. Передавайте данные из state в BarChartGroupData
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  // Тестовые данные — заменить на данные из Bloc
  static const List<(String, double)> _testData = [
    ('Пн', 4),
    ('Вт', 7),
    ('Ср', 3),
    ('Чт', 9),
    ('Пт', 5),
    ('Сб', 2),
    ('Вс', 6),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Активность по дням',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Количество выполненных элементов',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: 12,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          rod.toY.toInt().toString(),
                          TextStyle(color: colorScheme.onPrimary),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= _testData.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _testData[index].$1,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(
                    drawVerticalLine: false,
                  ),
                  barGroups: List.generate(
                    _testData.length,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: _testData[i].$2,
                          color: colorScheme.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
