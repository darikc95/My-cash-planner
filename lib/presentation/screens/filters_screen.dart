import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/expense_ui_data.dart';
import '../widgets/expense_ui_widgets.dart';

class FiltersScreen extends StatelessWidget {
  const FiltersScreen({super.key});

  void _handleReset(BuildContext context) {
    showFeatureStub(context, 'Сброс фильтров');
  }

  void _handleApply(BuildContext context) {
    showFeatureStub(context, 'Применение фильтров');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TopActionButton(
                        icon: Icons.close_rounded,
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      Text(
                        'Фильтры',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _handleReset(context),
                        child: const Text('Сброс'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Категория',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: 'Все категории',
                      decoration:
                          const InputDecoration(border: InputBorder.none),
                      items: const [
                        DropdownMenuItem(
                          value: 'Все категории',
                          child: Text('Все категории'),
                        ),
                      ],
                      onChanged: null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        ...filterItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FilterTile(item: item),
                          );
                        }),
                        const SizedBox(height: 20),
                        Text(
                          'Период',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 14),
                        const DateField(label: 'С', value: '01 мая 2024'),
                        const SizedBox(height: 12),
                        const DateField(label: 'По', value: '15 мая 2024'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => _handleApply(context),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: const Color(0xFF6C45E3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Применить фильтры'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
