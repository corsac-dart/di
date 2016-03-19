library corsac_di.test.container;

import 'dart:io';
import 'package:test/test.dart';
import 'package:corsac_di/corsac_di.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:mirrors';

void main() {
  group('Container:', () {
    test('it can be created without configuration', () {
      var container = new DIContainer();
      expect(container, new isInstanceOf<DIContainer>());
    });

    test("it resolves objects automagically", () {
      var container = new DIContainer.build([{}]);
      var service = container.get(MyService);
      expect(service, new isInstanceOf<MyService>());
      var secondCallService = container.get(MyService);
      expect(secondCallService, same(service));
    });

    test("it resolves objects from definition", () {
      var definitions = {MyService: DI.object(),};

      var container = new DIContainer.build([definitions]);
      var service = container.get(MyService);
      expect(service, new isInstanceOf<MyService>());
      var secondCallService = container.get(MyService);
      expect(secondCallService, same(service));
    });

    test('it indicates if entry is defined or can be auto-wired', () {
      var definitions = {'static.entry': 'value'};

      var container = new DIContainer.build([definitions]);
      expect(container.has('static.entry'), isTrue);
      expect(container.has(MyService), isTrue);
      expect(container.has('not.defined'), isFalse);
    });

    test("it resolves objects with custom constructor", () {
      var definitions = {
        MyServiceWithNamedConstructor: DI.object()..constructor = 'getNew',
      };

      var container = new DIContainer.build([definitions]);
      var service = container.get(MyServiceWithNamedConstructor);
      expect(service, new isInstanceOf<MyServiceWithNamedConstructor>());
      var secondCallService = container.get(MyServiceWithNamedConstructor);
      expect(secondCallService, same(service));
    });

    test("it resolves objects with positional parameters", () {
      var definitions = {
        OneParameter: DI.object()
          ..bindParameter('prop', 1)
          ..bindParameter('foo', DI.env('HOME')),
      };

      var container = new DIContainer.build([definitions]);
      OneParameter service = container.get(OneParameter);
      expect(service, new isInstanceOf<OneParameter>());
      expect(service.prop, equals(1));
      expect(service.foo, equals(Platform.environment['HOME']));
    });

    test("it fails to resolve if positional parameter is not bound", () {
      var definitions = {
        OneParameter: DI.object()..bindParameter('foo', 'example'),
      };

      var container = new DIContainer.build([definitions]);
      expect(() => container.get(OneParameter),
          throwsA(new isInstanceOf<DIError>()));
    });

    test("it resolves references automagically", () {
      var container = new DIContainer.build([{}]);
      DependentService depService = container.get(DependentService);
      expect(depService, new isInstanceOf<DependentService>());
      expect(depService.myService, new isInstanceOf<MyService>());
      expect(container.get(MyService), same(depService.myService));
    });

    test("it resolves references via DI.get()", () {
      var config = {UserRepository: DI.get(UserInMemoryRepository),};
      var container = new DIContainer.build([config]);

      UserRepository repository = container.get(UserRepository);
      expect(repository, new isInstanceOf<UserInMemoryRepository>());
    });

    test('it throws DIError if entry can not be resolved', () {
      var c = new DIContainer();
      expect(() {
        c.get('Test');
      }, throwsA(new isInstanceOf<DIError>()));
    });

    test('it throws DIError on attempt to override resolved entry', () {
      var definitions = {'Entry': 'Value',};
      var container = new DIContainer.build([definitions]);
      container.get('Entry');
      expect(() {
        container.set('Entry', 'NewValue');
      }, throwsA(new isInstanceOf<DIError>()));
    });
  });

  group('Environment Variables:', () {
    test("it resolves environment variables", () {
      var definitions = {
        'HomeDir': DI.env('HOME'),
        OneParameter: DI.object()
          ..bindParameter('prop', 1)
          ..bindParameter('foo', DI.env('HOME'))
      };
      var container = new DIContainer.build([definitions]);
      var homeDir = container.get('HomeDir');
      expect(homeDir, isNotNull);
      expect(homeDir, equals(Platform.environment['HOME']));
      OneParameter service = container.get(OneParameter);
      expect(service.foo, equals(Platform.environment['HOME']));
    });

    test("it resolves to dotenv vars if not found in the Platform env", () {
      env['MY_PASSWORD'] = 'secret';
      var definitions = {'Password': DI.env('MY_PASSWORD'),};
      var container = new DIContainer.build([definitions]);
      var homeDir = container.get('Password');
      expect(homeDir, equals('secret'));
    });

    test('it throws DIError if variable is not set', () {
      var def = {'env.var': DI.env('NOT_EXISTS')};
      var container = new DIContainer.build([def]);
      expect(
          () => container.get('env.var'), throwsA(new isInstanceOf<DIError>()));
    });
  });

  group('Factories:', () {
    test('it resolves entries using factory', () {
      var def = {
        UserRepository: DI.factory((DIContainer container) {
          return new UserInMemoryRepository();
        })
      };
      var container = new DIContainer.build([def]);
      var service = container.get(UserRepository);
      expect(service, new isInstanceOf<UserInMemoryRepository>());
      var secondAccessService = container.get(UserRepository);
      expect(secondAccessService, same(service));
    });
  });

  group('Objects:', () {
    test(
        'it makes sure ObjectResolver can not be used when for binding parameters',
        () {
      expect(
          () => DI.object()..bindParameter('prop', DI.object(UserRepository)),
          throwsA(new isInstanceOf<DIError>()));
    });

    test('it detects circular dependencies', () {
      var container = new DIContainer();

      try {
        container.get(TeamFactory);
        fail('Must throw DIError exception.');
      } catch (e) {
        expect(e, new isInstanceOf<DIError>());
        expect(e.message, 'Circular dependency detected for TeamFactory.');
      }
    });
  });

  group('Dynamic Lists:', () {
    test('it resolves lists with overrides', () {
      var definitions = {'migrations': new List()};
      var definitions2 = {
        'migrations': DI.add([DI.env('HOME')])
      };
      var container = new DIContainer.build([definitions, definitions2]);
      var result = container.get('migrations');
      expect(result, new isInstanceOf<List>());
      expect(result, hasLength(1));
      expect(result.first, equals(Platform.environment['HOME']));
    });

    test('it auto-creates lists if not explicitly defined', () {
      var definitions = {
        'migrations': DI.add([DI.env('HOME')])
      };
      var container = new DIContainer.build([definitions]);
      var result = container.get('migrations');
      expect(result, new isInstanceOf<List>());
      expect(result, hasLength(1));
      expect(result.first, equals(Platform.environment['HOME']));
    });

    test('it supports arbitrary values in the list', () {
      var definitions = {'migrations': new List()};
      var definitions2 = {
        'migrations': DI.add([DI.env('HOME'), 'random.value'])
      };
      var container = new DIContainer.build([definitions, definitions2]);
      var result = container.get('migrations');
      expect(result, new isInstanceOf<List>());
      expect(result, hasLength(2));
      expect(result.first, equals(Platform.environment['HOME']));
      expect(result.last, equals('random.value'));
    });
  });

  group('Static Values:', () {
    test('it supports static values', () {
      var definitions = {
        'MyInt': 352,
        OneParameter: DI.object()..bindParameter('prop', 736),
      };
      var container = new DIContainer.build([definitions]);
      OneParameter service = container.get(OneParameter);
      expect(container.get('MyInt'), equals(352));
      expect(service.prop, equals(736));
    });
  });

  group('String Expressions:', () {
    test('it extracts parameters from expression', () {
      var resolver = new StringExpressionResolver('{env}_{app}_dbname');
      expect(resolver.parameters, equals(['env', 'app']));
      expect(resolver.expression, equals('{env}_{app}_dbname'));
    });

    test('it resolves expression', () {
      var container = new DIContainer.build([
        {'env': 'dev', 'app': 'api', 'db': DI.string('{env}_{app}_dbname')}
      ]);

      expect(container.get('db'), equals('dev_api_dbname'));
    });
  });

  group('Middleware:', () {
    test('it asks middlewares to resolve entries', () {
      var container = new DIContainer();
      container.addMiddleware(new TestMiddleware());
      var entry = container.get('test');
      expect(entry, equals('dynamically resolved'));
    });
  });

  group('Generic container entries:', () {
    test('it can resolve generic entries declared with diType helper', () {
      var conf = {
        const diType<Repository<User>>():
            DI.get(const diType<MySQLRepository<User>>()),
      };
      var container = new DIContainer.build([conf]);
      execute((Repository<User> repo) {
        expect(repo, new isInstanceOf<MySQLRepository<User>>());
      }, container);
    });
  });
}

dynamic execute(Function body, DIContainer container) {
  ClosureMirror mirror = reflect(body);
  var positionalArguments = [];
  for (var param in mirror.function.parameters) {
    if (!param.isNamed) {
      positionalArguments.add(container.get(param.type.reflectedType));
    }
  }
  return mirror.apply(positionalArguments).reflectee;
}

class TestMiddleware implements DIMiddleware {
  @override
  resolve(id, DIMiddlewarePipeline next) {
    return 'dynamically resolved';
  }
}

class MyService {}

class MyServiceWithNamedConstructor {
  MyServiceWithNamedConstructor.getNew();
}

class OneParameter {
  final int prop;
  final String foo;
  OneParameter(this.prop, [this.foo]);
}

class DependentService {
  final MyService myService;
  DependentService(this.myService);
}

class User {}

class Repository<T> {}

class MySQLRepository<T> implements Repository<T> {}

abstract class UserRepository {}

class UserInMemoryRepository implements UserRepository {}

class TeamFactory {
  final TeamRepository repo;

  TeamFactory(this.repo);
}

class TeamRepository {
  final TeamFactory teamFactory;

  TeamRepository(this.teamFactory);
}
