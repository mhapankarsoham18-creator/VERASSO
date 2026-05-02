import 'package:supabase_flutter/supabase_flutter.dart';
void main() {
  Supabase.initialize(
    url: 'test',
    anonKey: 'test',
    accessToken: () async => 'test',
  );
}
