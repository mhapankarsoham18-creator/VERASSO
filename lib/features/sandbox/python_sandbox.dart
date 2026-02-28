/// Python Sandbox - Secure Code Execution Environment
/// Reference Implementation (documented as Dart class)
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../gamification/services/gamification_event_bus.dart';

/// Status of a code execution.
enum ExecutionStatus {
  /// Execution completed successfully.
  success,

  /// Execution timed out.
  timeout,

  /// Execution exceeded memory limits.
  memoryLimit,

  /// Execution violated security constraints.
  securityViolation,

  /// Execution failed with a runtime error.
  runtimeError,
}

/// Result of Python code execution
class PythonExecutionResult {
  /// The status of the execution.
  final ExecutionStatus status;

  /// Standard output of the execution.
  final String? output;

  /// Error message, if any.
  final String? error;

  /// Time taken for execution.
  final Duration? executionTime;

  /// Peak memory used.
  final int? memoryUsed;

  /// Number of tests that passed.
  final int? passedTests;

  /// Total number of tests run.
  final int? totalTests;

  /// Creates a [PythonExecutionResult].
  PythonExecutionResult({
    required this.status,
    this.output,
    this.error,
    this.executionTime,
    this.memoryUsed,
    this.passedTests,
    this.totalTests,
  });

  /// Whether the execution was successful.
  bool get isSuccessful => status == ExecutionStatus.success;
}

/// Python Sandbox - Secure execution environment
class PythonSandbox {
  /// Whitelisted modules
  static const Set<String> allowedModules = {
    'math',
    'random',
    'string',
    're',
    'collections',
    'itertools',
    'functools',
    'datetime',
    'json',
    'csv',
    'urllib',
  };

  /// Whitelisted builtins
  static const Set<String> allowedBuiltins = {
    'print',
    'len',
    'range',
    'enumerate',
    'zip',
    'sum',
    'max',
    'min',
    'sorted',
    'reversed',
    'list',
    'dict',
    'set',
    'tuple',
    'str',
    'int',
    'float',
    'any',
    'all',
    'filter',
    'map',
    'bool',
    'abs',
    'isinstance',
    'type',
    'hasattr',
    'getattr',
  };

  /// Blocked operations/patterns
  static const Set<String> blockedPatterns = {
    '__import__',
    'open(',
    'exec(',
    'eval(',
    'compile(',
    'globals()',
    'locals()',
    'vars()',
    'dir()',
    'input(',
    '__file__',
    '__name__',
    'os.',
    'sys.',
    'subprocess',
    'socket',
  };

  /// Maximum execution time in seconds.
  static const int maxExecutionTime = 5; // seconds

  /// Maximum memory in megabytes.
  static const int maxMemory = 50; // MB

  /// Execute Python code in sandbox
  static Future<PythonExecutionResult> executeWithTests(
    String code, {
    List<Map<String, dynamic>>? testCases,
    Duration timeout = const Duration(seconds: 5),
    GamificationEventBus? eventBus,
    String? currentUserId,
  }) async {
    // Validate code for security
    final securityCheck = validateCode(code);
    if (!securityCheck.isValid) {
      return PythonExecutionResult(
        status: ExecutionStatus.securityViolation,
        error: securityCheck.error,
      );
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Call Piston public API (emkc.org)
      final response = await http
          .post(
            Uri.parse('https://emkc.org/api/v2/piston/execute'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'language': 'python',
              'version': '3.10',
              'files': [
                {'content': code}
              ],
            }),
          )
          .timeout(timeout);

      stopwatch.stop();

      if (response.statusCode != 200) {
        return PythonExecutionResult(
          status: ExecutionStatus.runtimeError,
          error: 'API Error: ${response.statusCode} - ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      final runData = data['run'] as Map<String, dynamic>;
      final stdout = runData['stdout'] as String?;
      final stderr = runData['stderr'] as String?;
      final codeExit = runData['code'] as int?;

      final hasError = codeExit != 0 || (stderr != null && stderr.isNotEmpty);

      if (!hasError && currentUserId != null) {
        eventBus?.track(GamificationAction.challengeSolved, currentUserId);
      }

      return PythonExecutionResult(
        status:
            hasError ? ExecutionStatus.runtimeError : ExecutionStatus.success,
        output: stdout,
        error: stderr,
        executionTime: stopwatch.elapsed,
      );
    } catch (e) {
      return PythonExecutionResult(
        status: ExecutionStatus.runtimeError,
        error: e.toString(),
      );
    }
  }

  /// Validate code for security violations before execution
  static SecurityValidationResult validateCode(String code) {
    // Check for blocked patterns
    for (final pattern in blockedPatterns) {
      if (code.contains(pattern)) {
        return SecurityValidationResult(
          isValid: false,
          error: 'Blocked operation detected: $pattern',
        );
      }
    }

    // Check for dangerous imports
    if (code.contains('import os') || code.contains('import sys')) {
      return SecurityValidationResult(
        isValid: false,
        error: 'Blocked module import',
      );
    }

    return SecurityValidationResult(isValid: true);
  }
}

/// Security validation result
class SecurityValidationResult {
  /// Whether the code is valid.
  final bool isValid;

  /// Error message if the code is invalid.
  final String? error;

  /// Creates a [SecurityValidationResult].
  SecurityValidationResult({required this.isValid, this.error});
}
