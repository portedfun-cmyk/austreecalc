/// Represents an input validation issue.
///
/// Errors block calculation; warnings are advisory only.
class ValidationIssue {
  final String message;
  final bool isError;

  const ValidationIssue({
    required this.message,
    required this.isError,
  });
}
