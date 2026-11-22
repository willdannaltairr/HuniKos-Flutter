/// Error yang sudah diterjemahkan dari respons backend, sehingga layar cukup
/// menampilkan [message] dan memasang [fieldErrors] di bawah field terkait.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;

  /// Kunci: nama field dari backend, nilai: pesan pertama untuk field itu.
  final Map<String, String> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 422;

  /// Error jaringan tidak punya status, jadi tidak bisa dicoba ulang dengan
  /// cara yang sama seperti error validasi.
  bool get isNetwork => statusCode == null;

  @override
  String toString() => message;
}
