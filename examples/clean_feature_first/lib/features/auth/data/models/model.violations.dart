// lib/features/auth/data/models/model.violations.dart

import 'package:clean_feature_first/features/auth/domain/entities/user.dart';
import 'package:clean_feature_first/features/auth/data/models/user_model.dart';

// LINT: [1] enforce_layer_independence
// REASON: Data Models should not import from the Presentation layer.
import 'package:clean_feature_first/features/auth/presentation/pages/home_page.dart'; //! <-- LINT WARNING

// LINT: [2] disallow_service_locator
// REASON: Service Locators hide dependencies. Models should be data-only.
import 'package:get_it/get_it.dart'; //! <-- LINT WARNING

// LINT: [3] enforce_naming_pattern
// REASON: Name must match `{{name}}Model` (e.g., UserDTOModel or UserModel).
class UserDTO extends User { //! <-- LINT WARNING
  const UserDTO({required super.id, required super.name});

  User toEntity() => this;
}

// LINT: [4] enforce_model_inherits_entity
// REASON: Models must extend a Domain Entity to ensure architectural alignment.
class OrphanUserModel { //! <-- LINT WARNING
  final String id;
  const OrphanUserModel(this.id);

  // Even if it has the method, it fails if it doesn't extend the Entity class.
  User toEntity() => User(id: id, name: 'Unknown');
}

// LINT: [5] require_to_entity_method
// REASON: Class extends Entity but is missing the `toEntity()` mapping method.
class LazyUserModel extends User { //! <-- LINT WARNING
  const LazyUserModel({required super.id, required super.name});
  // Missing toEntity()
}

// LINT: [6] enforce_semantic_naming
// REASON: Grammar violation. Models must be Noun Phrases.
// 'Parsing' is a Verb (Gerund), implying this class performs an action.
class ParsingUserModel extends User { //! <-- LINT WARNING
  const ParsingUserModel({required super.id, required super.name});
  User toEntity() => this;
}

class LogicHeavyModel extends User {
  const LogicHeavyModel({required super.id, required super.name});

  User toEntity() {
    // LINT: [7] disallow_service_locator
    // REASON: Models should not access global services.
    final loc = GetIt.I.get<String>(); //! <-- LINT WARNING

    return this;
  }

  void saveSelf() {
    // LINT: [8] disallow_dependency_instantiation
    // REASON: Models should not instantiate other architectural components.
    // They are data holders, not logic executors.
    final otherModel = UserModel(id: '1', name: 'a'); // OK (Data creation)

    // Violations usually target Service components (Repos, Sources),
    // but creating ViewModels/Widgets here would also be flagged by layer independence.
    final page = HomePage(); //! <-- LINT WARNING (Layer Independence Violation)
  }
}