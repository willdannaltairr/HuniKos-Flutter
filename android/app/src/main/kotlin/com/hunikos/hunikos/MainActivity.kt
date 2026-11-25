package com.hunikos.hunikos

import io.flutter.embedding.android.FlutterFragmentActivity

// Harus FlutterFragmentActivity, bukan FlutterActivity, agar SDK Midtrans
// bisa menampilkan halaman pembayarannya di atas aplikasi.
class MainActivity : FlutterFragmentActivity()
