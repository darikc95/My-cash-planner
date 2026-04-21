import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'expense_ui_data.dart';

void showFeatureStub(BuildContext context, String featureName) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('$featureName можно подключить здесь.'),
      ),
    );
}

class WalletIllustration extends StatelessWidget {
  const WalletIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 56,
            top: 34,
            child: Container(
              height: 16,
              width: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFBCA9FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 52,
            top: 40,
            child: Transform.rotate(
              angle: 0.4,
              child: Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7FF),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 36,
            child: CoinBubble(
              color: Color(0xFFFFC85A),
              icon: Icons.attach_money_rounded,
            ),
          ),
          const Positioned(
            right: 46,
            bottom: 28,
            child: CoinBubble(
              color: Color(0xFFD8CCFF),
              icon: Icons.auto_graph_rounded,
            ),
          ),
          Container(
            width: 142,
            height: 118,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B57F2), Color(0xFF5A35D7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x336C45E3),
                  blurRadius: 22,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 18,
                  left: 18,
                  right: 18,
                  child: Transform.rotate(
                    angle: -0.12,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  right: 20,
                  top: 54,
                  child: Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 44),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CoinBubble extends StatelessWidget {
  const CoinBubble({super.key, required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9AA0B4), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF2C3142),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.hintText,
    this.trailing,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onFieldSubmitted,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF9AA0B4), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  obscureText: obscureText,
                  onSubmitted: onFieldSubmitted,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF2C3142),
                        fontWeight: FontWeight.w600,
                      ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hintText,
                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF9AA0B4),
                          fontWeight: FontWeight.w500,
                        ),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7D57F2), Color(0xFF5B35D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Общий баланс',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
              ),
              const Spacer(),
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '120,350 ₸',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 36,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'За этот месяц',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.item});

  final TransactionItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: item.iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF242938),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(item.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Text(
              item.amount,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: item.isNegative
                        ? const Color(0xFFFF5F67)
                        : const Color(0xFF2A2E3A),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class AmountCard extends StatelessWidget {
  const AmountCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Сумма', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 18),
            Text(
              '0 ₸',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 52,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class PickerCard extends StatelessWidget {
  const PickerCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8FC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF394050),
                          ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF7A8092)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DescriptionCard extends StatelessWidget {
  const DescriptionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

class StatsTabs extends StatelessWidget {
  const StatsTabs({super.key});

  @override
  Widget build(BuildContext context) {
    const labels = ['Обзор', 'Категории', 'Тренды'];
    return Row(
      children: labels.map((label) {
        final isSelected = label == 'Обзор';
        return Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected
                      ? const Color(0xFF6C45E3)
                      : const Color(0xFFE7E5F1),
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isSelected
                        ? const Color(0xFF6C45E3)
                        : const Color(0xFF6F7486),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Потрачено всего',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    '120,350 ₸',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 34,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('За этот месяц',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(width: 10),
                      const Icon(Icons.south_west_rounded,
                          color: Color(0xFF1DB954), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '12%',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF1DB954),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 48,
              width: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFF0EAFE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.show_chart_rounded,
                  color: Color(0xFF8D6AF2)),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryChart extends StatelessWidget {
  const CategoryChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            centerSpaceRadius: 48,
            sectionsSpace: 0,
            startDegreeOffset: -90,
            sections: chartItems.map((item) {
              return PieChartSectionData(
                color: item.color,
                value: item.percent.toDouble(),
                showTitle: false,
                radius: 22,
              );
            }).toList(),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '120,350 ₸',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF252A39),
                  ),
            ),
            const SizedBox(height: 4),
            Text('Итого', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}

class ChartLegendTile extends StatelessWidget {
  const ChartLegendTile({super.key, required this.item});

  final ChartItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(item.label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Text('${item.percent}%', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(width: 18),
        SizedBox(
          width: 74,
          child: Text(
            item.amount,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF394050),
                ),
          ),
        ),
      ],
    );
  }
}

class FilterTile extends StatelessWidget {
  const FilterTile({super.key, required this.item});

  final FilterItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Text(item.label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Checkbox(
            value: item.selected,
            onChanged: (_) {},
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            activeColor: const Color(0xFF6C45E3),
          ),
        ],
      ),
    );
  }
}

class DateField extends StatelessWidget {
  const DateField({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF394050),
                      ),
                ),
              ),
              const Icon(Icons.calendar_month_outlined,
                  color: Color(0xFF7A8092)),
            ],
          ),
        ),
      ],
    );
  }
}

class TopActionButton extends StatelessWidget {
  const TopActionButton(
      {super.key, required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF252A39)),
      ),
    );
  }
}

class PrimaryFab extends StatelessWidget {
  const PrimaryFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: const Color(0xFF6C45E3),
      foregroundColor: Colors.white,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }
}

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Главная'),
      (Icons.bar_chart_rounded, 'Статистика'),
      (Icons.grid_view_rounded, 'Категории'),
      (Icons.person_outline_rounded, 'Профиль'),
    ];

    return BottomAppBar(
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      child: SizedBox(
        height: 76,
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++)
              Expanded(
                child: index == 2
                    ? Row(
                        children: [
                          const SizedBox(width: 28),
                          Expanded(
                            child: BottomBarItem(
                              icon: items[index].$1,
                              label: items[index].$2,
                              selected: currentIndex == index,
                              onTap: () => onTap(index),
                            ),
                          ),
                        ],
                      )
                    : index == 1
                        ? Row(
                            children: [
                              Expanded(
                                child: BottomBarItem(
                                  icon: items[index].$1,
                                  label: items[index].$2,
                                  selected: currentIndex == index,
                                  onTap: () => onTap(index),
                                ),
                              ),
                              const SizedBox(width: 28),
                            ],
                          )
                        : BottomBarItem(
                            icon: items[index].$1,
                            label: items[index].$2,
                            selected: currentIndex == index,
                            onTap: () => onTap(index),
                          ),
              ),
          ],
        ),
      ),
    );
  }
}

class BottomBarItem extends StatelessWidget {
  const BottomBarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected ? const Color(0xFF6C45E3) : const Color(0xFF83889A),
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? const Color(0xFF6C45E3)
                      : const Color(0xFF83889A),
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
