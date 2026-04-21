import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/expense_ui_widgets.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

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
                children: [
                  Row(
                    children: [
                      TopActionButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Добавить расход',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const AmountCard(),
                  const SizedBox(height: 16),
                  const PickerCard(
                    title: 'Категория',
                    icon: Icons.category_outlined,
                    iconColor: Color(0xFFCE94FF),
                    value: 'Выберите категорию',
                  ),
                  const SizedBox(height: 16),
                  const PickerCard(
                    title: 'Дата',
                    icon: Icons.calendar_month_outlined,
                    iconColor: Color(0xFFB6BAC7),
                    value: '15 мая 2024',
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: DescriptionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Описание (необязательно)',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F8FC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.topLeft,
                              child: Text(
                                'Введите описание...',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => context.pop(),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: const Color(0xFF6C45E3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Сохранить расход'),
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
