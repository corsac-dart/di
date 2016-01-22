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
import 'package:corsac_di/corsac_di.dart';

void main() {
  var container = new DIContainer();

  YourService instance = container.get(YourService);
  instance.doThings();
}
```

However sometimes this is just not enough. For instance, when working with
interfaces and multiple implementations of those.

In this case you can provide a configuration object where you can specify
which implementation particular interface should be bound to. Example:

```dart
import 'package:corsac_di/corsac_di.dart';

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
  // Use DI.get() to bind interface to implementation:
  var config = {
    UserRepository: DI.get(UserPostgreSqlRepository),
  };
  var container = new DIContainer.build([config]);

  var user = container.get(UserRepository).findById(5);
}
```

In addition to `DI.get()` there are a few more helpers available.

The `DI.object()` helper provides flexible interface for configuring which
constructor should be used and binding constructor parameters if necessary:

```dart
import 'package:corsac_di/corsac_di.dart';

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
    PostgreConnection: DI.object()
      ..constructor = 'connect'
      ..bindParameter('username', DI.env('POSTGRE_USERNAME'))
      ..bindParameter('password', DI.env('POSTGRE_PASSWORD')),
  };
  var container = new DIContainer.build([config]);
  container.get(PostgreConnection).query('select * from users;');
  // etc...
}
```

It is also possible to use the `DI.object()` helper for binding of entries to
different implementations by passing optional `type` parameter.

In the example above you can also notice usage of the `DI.env()` helper.

The `DI.env()` helper fetches value of an environment variable so that container
can pass it in the constructor parameter when instantiating an entry. It also
supports [dotenv](https://pub.dartlang.org/packages/dotenv) package.

## Dynamic lists

There is a way to define lists of definitions which can be dynamically extended.

Suppose there is an application with multiple modules, and each module
defines it's own database migrations. We would want to collect a list of all
migrations and pass it to the central "migrations manager" responsible for
execution process of all migrations.

```dart
import 'package:corsac_di/corsac_di.dart';

class MigrationManager {
  final List<Migration> migrations;
  MigrationManager(this.migrations);
}
void main() {
  // Just define an entry holding instance of a List
  var baseConfig = {
    'migrations': new List(),
    MigrationManager: DI.object()
      ..bindParameter('migrations', DI.get('migrations')),
  };

  // In each module use the `DI.add()` helper to add to this list.
  // It is also possible to use DI.get() and DI.env() in the list, entries
  // will be auto-resolved upon list retrieval. Of course, other types
  // of values can be used as well.
  var module1Config = {
    'migrations': DI.add([DI.get(Module1Migrations)]),
  };
  var module2Config = {
    'migrations': DI.add([DI.get(Module2Migrations)]),
  };
  var container = new DIContainer.build([
    baseConfig,
    module1Config,
    module2Config
  ]);

  // Here the manager will have inject list of actual migration objects.
  var manager = container.get(MigrationManager);
  // ... run migrations.
}
```

## String Expressions

It is possible to define parametrized string entries which will be resolved
when retrieved from the container. Each parameter in the string expression
must refer to another container entry.

Example usage of `DI.string` helper:

```dart
import 'package:corsac_di/corsac_di.dart';

class MigrationManager {
  final List<Migration> migrations;
  MigrationManager(this.migrations);
}
void main() {
  var config = {
    'env': 'prod',
    'mysql.db': DI.string('{env}_blog'),
  };

  var container = new DIContainer.build(config);
  var dbName = container.get('mysql.db'); // dbname == 'prod_blog'
}
```

## License

BSD-2
