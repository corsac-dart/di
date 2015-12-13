library corsac_di.test.container;

import 'dart:io';
import 'package:test/test.dart';
import 'package:corsac_di/di.dart' as di;

void main() {
  group('Container:', () {
    test("it resolves objects automagically", () {
      var container = new di.Container();
      var service = container.get(MyService);
      expect(service, new isInstanceOf<MyService>());
      var secondCallService = container.get(MyService);
      expect(secondCallService, same(service));
    });
    test("it resolves objects", () {
      var definitions = {MyService: di.object(),};

      var container = new di.Container.build(definitions);
      var service = container.get(MyService);
      expect(service, new isInstanceOf<MyService>());
      var secondCallService = container.get(MyService);
      expect(secondCallService, same(service));
    });

    test("it resolves objects with custom constructor", () {
      var definitions = {
        MyServiceWithNamedConstructor: di.object()..constructor = 'getNew',
      };

      var container = new di.Container.build(definitions);
      var service = container.get(MyServiceWithNamedConstructor);
      expect(service, new isInstanceOf<MyServiceWithNamedConstructor>());
      var secondCallService = container.get(MyServiceWithNamedConstructor);
      expect(secondCallService, same(service));
    });

    test("it resolves objects with positional parameters", () {
      var definitions = {
        OneParameter: di.object()
          ..bindParameter('prop', 1)
          ..bindParameter('foo', 'example'),
      };

      var container = new di.Container.build(definitions);
      OneParameter service = container.get(OneParameter);
      expect(service, new isInstanceOf<OneParameter>());
      expect(service.prop, equals(1));
      expect(service.foo, equals('example'));
    });

    test("it fails to resolve if positional parameter is not bound", () {
      var definitions = {
        OneParameter: di.object()..bindParameter('foo', 'example'),
      };

      var container = new di.Container.build(definitions);
      expect(() => container.get(OneParameter), throwsStateError);
    });

    test("it resolves environment variables", () {
      var definitions = {'CurrentDir': di.env('PWD')};
      var container = new di.Container.build(definitions);
      var result = container.get('CurrentDir');
      expect(result, isNotNull);
      expect(result, equals(Platform.environment['PWD']));
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
