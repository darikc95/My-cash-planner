import 'package:flutter/material.dart';

class TransactionItem {
  const TransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.iconBackground,
    required this.isNegative,
  });

  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final Color iconBackground;
  final bool isNegative;
}

class ChartItem {
  const ChartItem(this.label, this.percent, this.amount, this.color);

  final String label;
  final int percent;
  final String amount;
  final Color color;
}

class FilterItem {
  const FilterItem(this.label, this.icon, this.color, this.selected);

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
}

const transactions = <TransactionItem>[
  TransactionItem(
    title: 'Еда',
    subtitle: 'Сегодня, 12:30',
    amount: '5,000 ₸',
    icon: Icons.restaurant_rounded,
    iconBackground: Color(0xFF4BCB72),
    isNegative: true,
  ),
  TransactionItem(
    title: 'Транспорт',
    subtitle: 'Сегодня, 08:15',
    amount: '2,000 ₸',
    icon: Icons.directions_bus_rounded,
    iconBackground: Color(0xFF4A86F7),
    isNegative: true,
  ),
  TransactionItem(
    title: 'Покупки',
    subtitle: 'Вчера, 17:20',
    amount: '12,500 ₸',
    icon: Icons.shopping_bag_rounded,
    iconBackground: Color(0xFFFFBF33),
    isNegative: false,
  ),
  TransactionItem(
    title: 'Развлечения',
    subtitle: 'Вчера, 14:10',
    amount: '3,000 ₸',
    icon: Icons.sports_esports_rounded,
    iconBackground: Color(0xFF8D5CF6),
    isNegative: false,
  ),
  TransactionItem(
    title: 'Жилье',
    subtitle: '12 мая, 09:00',
    amount: '70,000 ₸',
    icon: Icons.home_rounded,
    iconBackground: Color(0xFFFF5E94),
    isNegative: true,
  ),
];

const chartItems = <ChartItem>[
  ChartItem('Еда', 30, '36,100 ₸', Color(0xFF4BCB72)),
  ChartItem('Транспорт', 20, '24,040 ₸', Color(0xFF4A86F7)),
  ChartItem('Покупки', 15, '18,050 ₸', Color(0xFFFFBF33)),
  ChartItem('Развлечения', 10, '12,000 ₸', Color(0xFF8D5CF6)),
  ChartItem('Прочее', 25, '30,160 ₸', Color(0xFFFF6BA3)),
];

const filterItems = <FilterItem>[
  FilterItem('Еда', Icons.restaurant_rounded, Color(0xFF4BCB72), true),
  FilterItem(
      'Транспорт', Icons.directions_bus_rounded, Color(0xFF4A86F7), true),
  FilterItem('Покупки', Icons.shopping_bag_rounded, Color(0xFFFFBF33), true),
  FilterItem(
      'Развлечения', Icons.sports_esports_rounded, Color(0xFF8D5CF6), false),
  FilterItem('Жилье', Icons.home_rounded, Color(0xFFFF5E94), false),
  FilterItem('Прочее', Icons.more_horiz_rounded, Color(0xFFB7BBC8), false),
];
