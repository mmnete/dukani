import 'api_provider.dart';
import 'api_service.dart';
import 'dummy_api_service.dart';

enum ApiMode { real, dummy }

class ApiServiceSelector {
  static final ApiServiceSelector _instance = ApiServiceSelector._internal();

  factory ApiServiceSelector() => _instance;

  late ApiProvider _provider;
  ApiMode _mode = ApiMode.real;

  ApiServiceSelector._internal() {
    _provider = ApiService();
  }

  ApiProvider switchTo(ApiMode mode) {
    _mode = mode;
    return mode == ApiMode.real ? ApiService() : DummyApiService();
  }

  ApiProvider get provider => _provider;
}
