/// Tujuan halaman utama setelah login, dipakai router dan layar auth.
String homeForRole(String role) {
  switch (role) {
    case 'owner':
      return '/owner';
    case 'admin':
      return '/admin';
    default:
      return '/tenant';
  }
}
