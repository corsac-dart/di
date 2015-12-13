# Dart DI container

[![Build Status](https://img.shields.io/travis-ci/corsac-dart/di.svg?branch=master&style=flat-square)](https://travis-ci.org/corsac-dart/di)
[![Coverage Status](https://img.shields.io/coveralls/corsac-dart/di.svg?branch=master&style=flat-square)](https://coveralls.io/github/corsac-dart/di?branch=master)
[![License](https://img.shields.io/badge/license-BSD--2-blue.svg?style=flat-square)](https://raw.githubusercontent.com/corsac-dart/di/master/LICENSE)


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
