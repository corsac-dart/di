library corsac_di.test.container;

import 'dart:io';
import 'package:test/test.dart';
import 'package:corsac_di/corsac_di.dart';

void main() {
  group('Container:', () {
    test("it resolves objects automagically", () {
      var container = new Container.build([{}]);
      var service = container.get(MyService);
      expect(service, new isInstanceOf<MyService>());
      var secondCallService = container.get(MyService);
      expect(secondCallService, same(service));
    });
    test("it resolves objects from definition", () {
      var definitions = {MyService: DI.object(),};

      var container = new Container.build([definitions]);
      var service = container.get(MyService);
      expect(service, new isInstanceOf<MyService>());
      var secondCallService = container.get(MyService);
      expect(secondCallService, same(service));
    });

    test("it resolves objects with custom constructor", () {
      var definitions = {
        MyServiceWithNamedConstructor: DI.object()..constructor = 'getNew',
      };

      var container = new Container.build([definitions]);
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

      var container = new Container.build([definitions]);
      OneParameter service = container.get(OneParameter);
      expect(service, new isInstanceOf<OneParameter>());
      expect(service.prop, equals(1));
      expect(service.foo, equals(Platform.environment['HOME']));
    });

    test("it fails to resolve if positional parameter is not bound", () {
      var definitions = {
        OneParameter: DI.object()..bindParameter('foo', 'example'),
      };

      var container = new Container.build([definitions]);
      expect(() => container.get(OneParameter), throwsStateError);
    });

    test("it resolves references automagically", () {
      var container = new Container.build([{}]);
      DependentService depService = container.get(DependentService);
      expect(depService, new isInstanceOf<DependentService>());
      expect(depService.myService, new isInstanceOf<MyService>());
      expect(container.get(MyService), same(depService.myService));
    });

    test("it resolves references via DI.get()", () {
      var config = {UserRepository: DI.get(UserInMemoryRepository),};
      var container = new Container.build([config]);

      UserRepository repository = container.get(UserRepository);
      expect(repository, new isInstanceOf<UserInMemoryRepository>());
    });

    test("it resolves environment variables", () {
      var definitions = {'HomeDir': DI.env('HOME')};
      var container = new Container.build([definitions]);
      var result = container.get('HomeDir');
      expect(result, isNotNull);
      expect(result, equals(Platform.environment['HOME']));
    });

    test('it resolves lists with overrides', () {
      var definitions = {'migrations': new List()};
      var definitions2 = {
        'migrations': DI.add([DI.env('HOME')])
      };
      var container = new Container.build([definitions, definitions2]);
      var result = container.get('migrations');
      expect(result, new isInstanceOf<List>());
      expect(result, hasLength(1));
      expect(result.first, equals(Platform.environment['HOME']));
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
