# Corsac Dart Dependency Injection container

[![Build Status](https://img.shields.io/travis-ci/corsac-dart/di.svg?branch=master&style=flat-square)](https://travis-ci.org/corsac-dart/di)
[![Coverage Status](https://img.shields.io/coveralls/corsac-dart/di.svg?branch=master&style=flat-square)](https://coveralls.io/github/corsac-dart/di?branch=master)
[![License](https://img.shields.io/badge/license-BSD--2-blue.svg?style=flat-square)](https://raw.githubusercontent.com/corsac-dart/di/master/LICENSE)


Dependency Injection container inspired by PHP-DI.

## Current status

This library is a work-in-progress. APIs can (and most likely will) change
without notice.

## Installation

There is no Pub package yet so you have to use git dependency for now:

```yaml
dependencies:
  corsac_di:
    git: https://github.com/corsac-dart/di.git
```


## Usage:

Container tries to auto-resolve services when possible (using reflection). So
using this container can be as simple as instantiating it and asking for your
service. Example:

```dart
import 'package:corsac_di/corsac_di.dart' as di;

void main() {
  var container = new di.Container();

  YourService instance = container.get(YourService);
  instance.doThings();
}
```

However sometimes this is just not enough. For instance, when working with
interfaces and multiple implementations of those.

In this case you can provide a configuration object where you can specify
which implementation particular interface should be bound to. Example:

```dart
import 'package:corsac_di/corsac_di.dart' as di;

// Example repository interface
abstract class UserRepository {
  User findById(int id);
}

// First implementation
class UserInMemoryRepository {
  // implementation goes here.
}

// Second implementation
class UserPostgreSqlRepository {
  // implementation goes here.
}

void main() {
  // Use di.get() to bind interface to implementation:
  var config = {
    UserRepository: di.get(UserPostgreSqlRepository),
  };
  var container = new di.Container.build(config);

  var user = container.get(UserRepository).findById(5);
}
```

In addition to `di.get()` there are a few more helpers available.

The `di.object()` helper provides flexible interface for configuring which
constructor should be used and binding constructor parameters if necessary:

```dart
import 'package:corsac_di/corsac_di.dart' as di;

class PostgreConnection {
  final String username;
  final String password;
  // ...the rest of connection settings
  factory PostgreConnection.connect(this.username, this.password) {
    // connection, etc...
  }
}

void main() {
  var config = {
    PostgreConnection: di.object()
      ..constructor = 'connect'
      ..bindParameter('username', di.env('POSTGRE_USERNAME'))
      ..bindParameter('password', di.env('POSTGRE_PASSWORD')),
  };
  var container = new di.Container.build(config);
  container.get(PostgreConnection).query('select * from users;');
  // etc...
}
```

In the example above you can also notice usage of the `di.env()` helper.

The `di.env()` helper fetches value of an environment variable so that container
can pass it in the constructor parameter when instantiating an entry.

## License

BSD-2
