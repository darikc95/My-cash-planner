# Flutter Clean Architecture Template

Стартовый шаблон Flutter-приложения с Clean Architecture, BLoC, Drift (SQLite), GoRouter и fl_chart.

---

## Технический стек

| Слой | Технология |
|------|-----------|
| UI | Flutter + Material 3 |
| State Management | flutter_bloc + equatable |
| Навигация | go_router |
| Локальная БД | Drift (SQLite) |
| HTTP | Dio |
| Графики | fl_chart |
| Авторизация | Локальная (SharedPreferences) |
| Линтер | flutter_lints |

---

## Быстрый старт

```bash
# 1. Установить зависимости
flutter pub get

# 2. Сгенерировать Drift-код (обязательно!)
dart run build_runner build --delete-conflicting-outputs

# 3. Запустить приложение
flutter run
```

> **Важно:** без шага 2 приложение не скомпилируется — `app_database.g.dart` должен быть создан build_runner.

---

## Структура проекта

```
lib/
├── core/
│   ├── constants/      # AppConstants — ключи, маршруты, лимиты
│   ├── router/         # GoRouter с редиректом по AuthBloc
│   ├── theme/          # AppTheme — Material 3, светлая тема
│   ├── utils/          # Validators — валидаторы для форм
│   └── widgets/        # CustomTextField, LoadingButton
│
├── data/
│   ├── datasources/
│   │   ├── app_database.dart           # @DriftDatabase + маппер-расширения
│   │   ├── auth_local_datasource.dart  # Drift + SharedPreferences
│   │   └── item_local_datasource.dart  # Drift CRUD-запросы
│   ├── models/
│   │   ├── user_model.dart   # Drift-таблица Users
│   │   └── item_model.dart   # Drift-таблица Items + TypeConverter
│   └── repositories/
│       ├── auth_repository_impl.dart
│       └── item_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── user.dart    # Чистый Dart-класс, без Flutter
│   │   └── item.dart    # Чистый Dart-класс + enum ItemStatus
│   ├── repositories/
│   │   ├── auth_repository.dart   # abstract class
│   │   └── item_repository.dart   # abstract class
│   └── usecases/
│       ├── base_usecase.dart      # UseCase<Output, Params> + NoParams
│       ├── login_usecase.dart
│       ├── register_usecase.dart
│       ├── check_session_usecase.dart
│       ├── get_all_items_usecase.dart
│       ├── create_item_usecase.dart
│       ├── update_item_usecase.dart
│       ├── delete_item_usecase.dart
│       └── search_items_usecase.dart
│
├── presentation/
│   ├── blocs/
│   │   ├── auth/   # AuthBloc (события + состояния + логика)
│   │   └── item/   # ItemBloc (события + состояния + логика)
│   └── screens/
│       ├── splash_screen.dart     # Проверка сессии → редирект
│       ├── login_screen.dart      # Форма входа + BlocConsumer
│       ├── register_screen.dart   # Форма регистрации
│       ├── home_screen.dart       # Список Items + поиск + фильтр
│       └── analytics_screen.dart  # BarChart (fl_chart)
│
└── main.dart   # BlocObserver, DI вручную, MultiBlocProvider
```

---

## Правила архитектуры

- `domain/` — только Dart, **никаких** Flutter-импортов
- `presentation/` — знает только `domain/`, не знает об источниках данных
- Репозитории — через `abstract class` интерфейсы
- `setState` — только для локального UI-состояния (видимость пароля, фокус)

---

## Как добавить новую сущность (5 шагов)

### 1. Domain — сущность и интерфейс

```dart
// lib/domain/entities/product.dart
class Product extends Equatable { ... }

// lib/domain/repositories/product_repository.dart
abstract class ProductRepository { ... }
```

### 2. Domain — use cases

```dart
// lib/domain/usecases/get_all_products_usecase.dart
class GetAllProductsUseCase implements UseCase<List<Product>, NoParams> { ... }
```

### 3. Data — модель (Drift-таблица)

```dart
// lib/data/models/product_model.dart
class Products extends Table { ... }
```

Добавить `Products` в `@DriftDatabase(tables: [Users, Items, Products])` в `app_database.dart`, затем:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Data — datasource и репозиторий

```dart
// lib/data/datasources/product_local_datasource.dart
class ProductLocalDatasource { ... }

// lib/data/repositories/product_repository_impl.dart
class ProductRepositoryImpl implements ProductRepository { ... }
```

### 5. Presentation — Bloc и экран

```dart
// lib/presentation/blocs/product/product_bloc.dart
class ProductBloc extends Bloc<ProductEvent, ProductState> { ... }

// lib/presentation/screens/products_screen.dart
class ProductsScreen extends StatelessWidget { ... }
```

Добавить маршрут в `app_router.dart` и `BlocProvider` в `main.dart`.

---

## Тесты

```bash
flutter test
```

Тесты находятся в `test/`:
- `test/usecases/login_usecase_test.dart` — LoginUseCase (успех, неверный пароль)
- `test/usecases/register_usecase_test.dart` — RegisterUseCase (успех, дубль email)
- `test/blocs/item_bloc_test.dart` — ItemBloc (загрузка, создание, ошибка)

Mock-объекты создаются через `mocktail`, тесты BLoC — через `bloc_test`.
