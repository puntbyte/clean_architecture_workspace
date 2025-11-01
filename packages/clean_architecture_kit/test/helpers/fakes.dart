import 'dart:async';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';

class FakeToken extends Fake implements Token {
  @override
  final int offset;

  @override
  final int length;

  FakeToken({this.offset = 0, this.length = 0});

  @override
  TokenType get type => TokenType.IDENTIFIER;
}

class FakeCustomLintResolver implements CustomLintResolver {
  @override
  final String path;
  final String _content;

  FakeCustomLintResolver({required this.path, required String content}) : _content = content;

  @override
  late final source = StringSource(_content, path);

  @override
  late final lineInfo = LineInfo.fromContent(_content);

  @override
  Future<ResolvedUnitResult> getResolvedUnitResult() =>
      throw UnimplementedError('getResolvedUnitResult is not implemented for this test fake.');
}
