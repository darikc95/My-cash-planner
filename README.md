# Мои финансы

Мобильное приложение для учёта личных финансов, написанное на Flutter. Позволяет отслеживать расходы и доходы, просматривать статистику, контролировать бюджет и следить за курсами валют в реальном времени.

---

## Возможности

- **Учёт операций** — добавление, редактирование и удаление расходов и доходов с выбором категории, суммы, даты и заметки
- **Категории** — настройка категорий расходов и доходов: свои иконки, цвета, переименование и деактивация
- **Статистика** — графики по расходам/доходам за выбранный период, разбивка по категориям, динамика по месяцам
- **Бюджет** — установка месячного лимита расходов и уведомление при превышении
- **Курсы валют** — котировки в реальном времени через Yahoo Finance API (EUR/KZT, USD/KZT, RUB/KZT и другие)
- **Фильтрация** — поиск операций по дате, категории и тексту
- **Профиль** — имя пользователя, аватар, смена пароля, тёмная/светлая тема
- **Уведомления** — ежедневное напоминание о внесении расходов, уведомление о превышении бюджета
- **Мультиаккаунт** — регистрация и вход по email и паролю

---

## Архитектура

Проект построен по принципам **Clean Architecture** с чётким разделением слоёв:

```
lib/
├── application/        # Фасад приложения (PlannerFacade)
├── core/               # Константы, утилиты, тема, уведомления
├── data/               # Источники данных (Hive, API)
│   ├── datasources/    # HiveStorageService, LocalAuthService, YahooFinanceApiService
│   ├── models/         # DTO (FinanceQuote)
│   └── repositories/   # Реализации репозиториев
├── domain/             # Бизнес-логика
│   ├── entities/       # Сущности (User, Expense)
│   ├── repositories/   # Интерфейсы репозиториев
│   └── usecases/       # Use case'ы (Login, Register, Logout, GetCurrentUser)
└── presentation/       # UI
    ├── blocs/          # AuthBloc
    ├── screens/        # Экраны приложения
    └── widgets/        # Переиспользуемые виджеты
```

**Паттерны:**
- **BLoC** (flutter_bloc) — управление состоянием авторизации
- **GoRouter** — декларативная маршрутизация с реактивными редиректами
- **Hive** — локальное хранилище данных
- **PlannerFacade** — единая точка доступа для слоя представления ко всем данным

---

## Стек технологий

| Технология | Назначение |
|---|---|
| Flutter >= 3.3.0 | UI фреймворк |
| flutter_bloc 8 | Управление состоянием |
| go_router 14 | Навигация |
| Hive 2 | Локальная база данных |
| Dio 5 | HTTP-клиент для API |
| fl_chart | Графики |
| flutter_local_notifications | Push-уведомления |
| mocktail / bloc_test | Тестирование |

---

## Структура данных

### Expense (расход/доход)

| Поле | Тип | Описание |
|---|---|---|
| id | String | Уникальный идентификатор |
| userId | String | Привязка к пользователю |
| title | String | Название |
| amount | double | Сумма |
| category | String | Категория |
| date | DateTime | Дата операции |
| note | String? | Заметка |
| isIncome | bool | true — доход, false — расход |

### User

| Поле | Тип | Описание |
|---|---|---|
| id | String | Уникальный идентификатор |
| email | String | Email пользователя |
| name | String | Имя |
| passwordHash | String | Хэш пароля |

---

## Экраны

| Маршрут | Экран |
|---|---|
| `/` | Вход (логин) |
| `/register` | Регистрация |
| `/home` | Главный экран (операции, курсы валют, бюджет) |
| `/statistics` | Статистика и графики |
| `/categories` | Управление категориями |
| `/profile` | Профиль пользователя |
| `/add-expense` | Добавление операции |
| `/edit-expense` | Редактирование операции |
| `/filters` | Фильтры списка операций |

---

### Запуск приложения

```bash
flutter run
```

---

## Сборка APK

```bash
flutter build apk --release --no-tree-shake-icons
```

> Флаг `--no-tree-shake-icons` необходим, так как иконки категорий хранятся динамически в Hive и загружаются во время выполнения — стандартная оптимизация Flutter не может определить, какие иконки используются.

Готовый APK: `build/app/outputs/flutter-apk/app-release.apk`

---

## Скриншоты
<img width="563" height="1155" alt="image" src="https://github.com/user-attachments/assets/e3347fc6-df81-4347-b54b-3341d9f48b5a" />
<img width="563" height="1155" alt="image" src="https://github.com/user-attachments/assets/7d1b1890-b7b1-4e78-901c-f6c6deccb625" />
<img width="819" height="1055" alt="image" src="https://github.com/user-attachments/assets/a1c6903a-f6aa-46f6-81b0-dd5378efc9bb" />
<img width="562" height="1155" alt="image" src="https://github.com/user-attachments/assets/21abe22a-2139-4c27-94f7-5060f2d49abe" />
<img width="563" height="1155" alt="image" src="https://github.com/user-attachments/assets/2ccb7c1b-af87-47a4-b597-eed0fdba479e" />

