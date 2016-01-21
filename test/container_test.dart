library corsac_di.test.container;

import 'dart:io';
import 'package:test/test.dart';
import 'package:corsac_di/corsac_di.dart';
import 'package:dotenv/dotenv.dart';

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
      expect(() => container.get(OneParameter), throwsStateError);
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

    test('it throws DIError if entry can not be resolved', () {
      var c = new DIContainer();
      expect(() {
        c.get('Test');
      }, throwsA(new isInstanceOf<DIError>()));
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

abstract class UserRepository {}

class UserInMemoryRepository implements UserRepository {}
