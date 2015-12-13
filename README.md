# Dart DI container

Dependency Injection container inspired by PHP-DI.

Usage:

```dart
import 'package:corsac_di/di.dart' as di;

var container = new di.Container();

YourService instance = container.get(YourService);
instance.doThings();
```

Providing service definitions and binding parameters:

```dart
import 'package:corsac_di/di.dart' as di;

// Example services
abstract class YourServiceInterface {}
class YourHttpService implements YourServiceInterface {
  final OtherService otherService;
  final int number;
  YourHttpService.fromParameters(this.otherService, this.number);
}

var services = {
  YourServiceInterface: di.get(YourHttpService),
  YourHttpService: di.object()
    ..constructor = 'fromParameters'
    ..bindParameter('otherService', di.get(OtherService))
    ..bindParameter('number', di.env('ENV_NUMBER')),

};
var container = new di.Container.build(services);

container.get(YourService).doThings();
```
