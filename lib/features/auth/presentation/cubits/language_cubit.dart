import 'package:flutter_bloc/flutter_bloc.dart';

enum AppLanguage { english, hindi, punjabi }

class LanguageCubit extends Cubit<AppLanguage> {
  LanguageCubit() : super(AppLanguage.english);

  void changeLanguage(AppLanguage lang) => emit(lang);
}