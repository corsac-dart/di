/// Library implementing Dependency Injection container.
library corsac_di;

import 'dart:mirrors';

import 'package:dotenv/dotenv.dart' as dotenv show env;
import 'dart:collection';

part 'src/container.dart';
part 'src/errors.dart';
part 'src/middleware.dart';
part 'src/resolvers.dart';

/// Constant providing easy access to helper functions in [DIHelpers].
const DIHelpers DI = const DIHelpers();

/// Convenience helpers for building service configuration.
///
/// Example usage:
///
///     var config = {
///       UserRepository: DI.get(UserMysqlRepository),
///       UserMysqlRepository: DI.object()
///         ..bindParameter('host', DI.env('MYSQL_HOST'))
///         ..bindParameter('port', DI.env('MYSQL_PORT')),
///     };
///
/// Refer to documentation for particular method for more details.
class DIHelpers {
  const DIHelpers();

  /// Returns configuration resolver for entries which should be instantiated
  /// by the [DIContainer].
  ///
  /// Returned resolver allows to configure which constructor to use for
  /// instantiating the entry and also bind constructor parameters to
  /// desirable values.
  ///
  /// Use [type] to override class of the entry. If type is omitted then it is
  /// assumed that entry is an instance of [Type] which will be used by the
  /// container to create the instance. Examples:
  ///
  ///     var config = {
  ///       // In this case container.get(UserRepository) will return instance
  ///       // of UserRepository
  ///       UserRepository: DI.object(),
  ///       // In this case container.get(UserRepository) will return instance
  ///       // of UserMockRepository.
  ///       UserRepository: DI.object(UserMockRepository),
  ///       // DIContainer will try to instantiate this entry with
  ///       // new UserMockRepository.withFixtures(fixtures);
  ///       UserMockRepository: DI.object()
  ///         ..constructor = 'withFixtures'
  ///         ..bindParameter('fixtures', DI.get('fixtures'))
  ///     };
  ObjectResolver object([Type type]) {
    return new ObjectResolver()..type = type;
  }

  /// Creates factory resolver for the container entry.
  ///
  /// This allows more control over creating the entry.
  ///
  ///     var config = {
  ///       UserRepository: DI.factory((Container c) {
  ///         var repository = new UserMockRepository();
  ///         repository.add(new UserMock(1));
  ///         repository.add(new UserMock(2));
  ///         return repository;
  ///       }),
  ///     };
  FactoryResolver factory(EntryFactory func) => new FactoryResolver(func);

  /// Binds an entry to an environment variable.
  ///
  /// One can use this helper to define container entries as well as bind
  /// constructor parameters.
  ///
  ///     var config = {
  ///       // In this case container.get('MysqlHost') will return value
  ///       // of the MYSQL_HOST environment variable
  ///       'MysqlHost': DI.env('MYSQL_HOST'),
  ///       // When instantiating UserMysqlRepository container will pass
  ///       // value of MYSQL_HOST environment variable in the 'host'
  ///       // parameter of the constructor
  ///       UserMysqlRepository: DI.object()
  ///         ..bindParameter('host', DI.env('MYSQL_HOST')),
  ///     };
  EnvironmentVariableResolver env(String variableName) {
    return new EnvironmentVariableResolver(variableName);
  }

  /// References other entry in the container.
  ///
  /// This is useful when working with interfaces (abstract classes) to easily
  /// swap implementations based on the environment.
  ///
  /// For instance, one can define a mock implementation to use in tests.
  /// Let's say we have TwitterApiClient which is an interface and a couple
  /// implemementations: TwitterMockClient and TwitterHttpClient.
  ///
  /// For testing container configuration can look like this:
  ///
  ///     var config = {
  ///       TwitterApiClient: DI.get(TwitterMockClient),
  ///     };
  ///
  /// This way when you request `TwitterApiClient` from container you will
  /// actually get instance of `TwitterMockClient`.
  ReferenceResolver get(dynamic id) => new ReferenceResolver(id);

  /// Helper for extending dynamic lists.
  ListExtensionHelper add(Iterable items) => new ListExtensionHelper(items);

  StringExpressionResolver string(String expression) =>
      new StringExpressionResolver(expression);
}
