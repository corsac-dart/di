# Corsac DI container [![Build Status](https://img.shields.io/travis-ci/corsac-dart/di.svg?branch=master&style=flat-square)](https://travis-ci.org/corsac-dart/di) [![Coverage Status](https://img.shields.io/coveralls/corsac-dart/di.svg?branch=master&style=flat-square)](https://coveralls.io/github/corsac-dart/di?branch=master) [![License](https://img.shields.io/badge/license-BSD--2-blue.svg?style=flat-square)](https://raw.githubusercontent.com/corsac-dart/di/master/LICENSE)

Dependency Injection container for Dart server-side applications.

## 1. Installation

Update your `pubspec.yaml` with:

```yaml
dependencies:
  corsac_di:
    git: https://github.com/corsac-dart/di.git
```

Pub package will be added as soon as API is "stable enough".

## 2. Usage

### 2.1 Auto-wiring

`DIContainer` supports auto-wiring, which means it will attempt to resolve
entries based on type information:

```dart
import 'package:corsac_di/corsac_di.dart';

class FooService {
  final BarService bar;
  FooService(this.bar);
}

class BarService {
  void baz() {
    print('foo bar baz');
  }
}

void main() {
  var container = new DIContainer();

  FooService service = container.get(FooService);
  service.bar.baz(); // prints 'foo bar baz'
}
```

With zero configuration needed this covers a good portion of common use cases.

### 2.2 Configuration

For a more complex and modular applications we usually need more flexibility
and `DIContainer` provides a way to configure itself.

Configurations for `DIContainer` are standard Dart's `Map` objects. Keys
in a configuration map refer to container entries and values can either be
actual values to associate with particular key or a special definition
object which carries information necessary to get the actual value.

#### 2.2.1 Static values

Simplest configuration object with static values can look like this:

```dart
Map config = {
  'mysql.hostname': 'localhost',
  'mysql.port': 3306
};

var container = new DIContainer.build([config]);
print(container.get('mysql.hostname')); // prints 'localhost'
```

#### 2.2.2 Environment variables

It is very common for projects to use environment variables to store sensitive
configuration data. One can use `DI.env()` helper to associate container entry
with the value of environment variable:

```dart
// say, MYSQL_PASSWORD=123456
Map config = {
  'mysql.password': DI.env('MYSQL_PASSWORD'),
};

var container = new DIContainer.build([config]);
print(container.get('mysql.password')); // prints '123456'
```

This helper also supports [dotenv](https://pub.dartlang.org/packages/dotenv)
package.

#### 2.2.3 Objects

We already saw example of getting an object in the "auto-wiring" section.
However following example will result in an error:

```dart
class MySQL {
  final String host;
  final String user;
  final String password;
  MySQL(this.host, this.user, this.password);
}

var container = new DIContainer();
container.get(MySQL); // will throw DIError
```

There is no way for container to know actual values of `host`, `user` and
`password` parameters. But we can tell container where to find these values:

```dart
Map config = {
  MySQL: DI.object()
    ..bindParameter('host', 'localhost') // binds static value to `host` parameter
    ..bindParameter('user', DI.env('MYSQL_USER')) // binds value of env variable
    ..bindParameter('password', DI.env('MYSQL_PASSWORD')) // another env variable
};

var container = new DIContainer.build([config]);
var mysql = container.get(MySQL); // returns instance of `MySQL` class
mysql.query(); // do work
```

It is also possible to customize which constructor should be called to get new
instance:

```dart
Map config = {
  MySQL: DI.object()
    ..constructor = 'connect'
    // ...bind necessary parameters
};
```

#### 2.2.4 Binding interface to implementation

Here is a typical situation:

```dart
abstract class LogHandler {}
class EmailLogHandler implements LogHandler {} // sends email notifications
class NullLogHandler implements LogHandler {} // silently ignores everything
```

One might want to use `NullLogHandler` when running tests to avoid unnecessary
emails being sent in test environment. This can be resolved using `DI.get()`
helper:

```dart
var config = {
  LogHandler: DI.get(NullLogHandler),
};
var container = new DIContainer.build([config]);
container.get(LogHandler); // returns instance of `NullLogHandler`
```

#### 2.2.5 String expressions

There is a way to define parametrized string which value is resolved based
on container configuration. Parameters in a string must be enclosed in curly braces
and refer to another container entry:

```dart
var config = {
  'env': 'prod',
  'mysql.database': DI.string('{env}_blog'),
};

var container = new DIContainer.build([config]);
print(container.get('mysql.database')); // prints 'prod_blog'
```

#### 2.2.6 Dynamic lists

Any `Iterable` entry in the `DIContainer` is treated specially. If it only
contains static values then it will be returned as is:

```dart
var config = {
  'fruits': ['apple', 'pear', 'orange']
};
var container = new DIContainer.build([config]);
print(container.get('fruits')); // prints ['apple', 'pear', 'orange']
```

However if values contain any of resolvers returned by `DI.get()`, `DI.object()`,
`DI.env()` or `DI.string()`, then such values are automatically resolved:

```dart
var config = {
  'env': 'prod',
  'entries': [
    DI.env('MYSQL_PASSWORD'), // say MYSQL_PASSWORD=123456
    DI.string('{env}_blog'),
    DI.get(MySQL),
  ]
};
var container = new DIContainer.build([config]);
print(container.get('entries'));
// prints ['123456', 'prod_blog', 'Instance of <MySQL>']
```

In addition, there is `DI.add()` helper which allows to dynamically add items
to such lists. This allows for building applications with complex structure
which can be split into a set of modules. Each module in turn can provide
it's own configurations and add items to such lists.

```dart
// Base configuration
var baseConfig = {
  'migrations': new List(), // list containing all database migrations
};
// MySQL module configuration
var mysqlConfig = {
  'migrations': DI.add([
    DI.get(MySQLMigration) // adds MySQLMigration to the list
  ]),
};
// Mongo module configuration
var mongoConfig = {
  'migrations': DI.add([
    DI.get(MongoMigration) // adds MongoMigration to the list
  ]),
};

// `DIContainer.build()` accepts a list of configuration objects
var container = new DIContainer.build([
  baseConfig,
  mysqlConfig,
  mongoConfig
]);

print(container.get('migrations'));
// prints [Instance of <MySQLMigration>, Instance of <MongoMigration>]
```

## Inspirations

Public API of this library is inspired by PHP-DI library.

## License

BSD-2
