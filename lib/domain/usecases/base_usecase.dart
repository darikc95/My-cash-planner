// Слой: domain | Назначение: базовый абстрактный класс use case

import 'package:equatable/equatable.dart';

abstract class UseCase<Output, Params> {
  Future<Output> call(Params params);
}

// Используется для use case без входных параметров
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
