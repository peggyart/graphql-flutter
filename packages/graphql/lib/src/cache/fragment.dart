import 'dart:convert';
import "package:meta/meta.dart";
import "package:collection/collection.dart";

import "package:gql/ast.dart";
import 'package:gql/language.dart';
import "package:gql_exec/gql_exec.dart";
import 'package:normalize/utils.dart';

/// compare two json-like objects for equality
/// parameters must be either null, num, bool, String or a List or Map of these types
/// this is an alternative too DeepCollectionEquality().equals, which is very slow and has
/// O(n^2) complexity:
bool jsonMapEquals(Object? a, Object? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == b) {
    return true;
  }
  if (a is Map) {
    if (b is! Map) {
      return false;
    }
    if (a.length != b.length) return false;
    for (var key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!jsonMapEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List) {
    if (b is! List) {
      return false;
    }
    final length = a.length;
    if (length != b.length) return false;
    for (var i = 0; i < length; i++) {
      if (!jsonMapEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return false;
}

/// A fragment in a [document], optionally defined by [fragmentName]
@immutable
class Fragment {
  /// Document containing at least one [FragmentDefinitionNode]
  final DocumentNode document;

  /// Name of the fragment definition
  ///
  /// Must be specified if [document] contains more than one [FragmentDefinitionNode]
  final String? fragmentName;

  const Fragment({
    required this.document,
    this.fragmentName,
  });

  List<Object?> _getChildren() => [
        document,
        fragmentName,
      ];

  @override
  bool operator ==(Object o) =>
      identical(this, o) ||
      (o is Fragment &&
          jsonMapEquals(
            o._getChildren(),
            _getChildren(),
          ));

  @override
  int get hashCode => const ListEquality<Object?>(
        DeepCollectionEquality(),
      ).hash(
        _getChildren(),
      );

  @override
  String toString() {
    final documentRepr = json.encode(printNode(document));
    return "Fragment(document: DocumentNode($documentRepr), fragmentName: $fragmentName)";
  }

  /// helper for building a [FragmentRequest]
  @experimental
  FragmentRequest asRequest({
    required Map<String, dynamic> idFields,
    Map<String, dynamic> variables = const <String, dynamic>{},
  }) =>
      FragmentRequest(fragment: this, idFields: idFields, variables: variables);
}

/// Cache access request of [fragment] with [variables].
@immutable
class FragmentRequest {
  /// [Fragment] to be read or written
  final Fragment fragment;

  /// Variables of the fragment for this request
  final Map<String, dynamic> variables;

  /// Map which includes all identifying data (usually `{__typename, id }`)
  final Map<String, dynamic> idFields;

  const FragmentRequest({
    required this.fragment,
    required this.idFields,
    this.variables = const <String, dynamic>{},
  });

  List<Object> _getChildren() => [
        fragment,
        variables,
        idFields,
      ];

  @override
  bool operator ==(Object o) =>
      identical(this, o) ||
      (o is FragmentRequest &&
          jsonMapEquals(
            o._getChildren(),
            _getChildren(),
          ));

  @override
  int get hashCode => const ListEquality<Object?>(
        DeepCollectionEquality(),
      ).hash(
        _getChildren(),
      );

  @override
  String toString() =>
      "FragmentRequest(fragment: $fragment, variables: $variables)";
}

extension OperationRequestHelper on Operation {
  /// helper for building a [Request]
  @experimental
  Request asRequest({
    Map<String, dynamic> variables = const <String, dynamic>{},
  }) =>
      Request(operation: this, variables: variables);
}

extension FragmentDataValid on FragmentRequest {
  /// Returns `true` if the structure of [data] is valid according to [request]'s structure.
  ///
  /// Thin wrapper around [validateFragmentDataStructure]
  bool validatesStructureOf(Map<String, dynamic> data) =>
      validateFragmentDataStructure(
        document: fragment.document,
        fragmentName: fragment.fragmentName,
        variables: variables,
        handleException: true,
        data: data,
      );
}

extension OperationDataValid on Request {
  /// Returns `true` if the structure of [data] is valid according to [request]'s structure.

  /// Returns `true` if the structure of [data] is valid according to [request]'s structure.
  ///
  /// Thin wrapper around [validateOperationDataStructure]
  bool validatesStructureOf(Map<String, dynamic> data) =>
      validateOperationDataStructure(
        document: operation.document,
        operationName: operation.operationName,
        variables: variables,
        handleException: true,
        data: data,
      );
}
