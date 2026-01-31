import 'dart:io';

void main() async {
  final file = File('errors_phase3_fix.txt');
  if (await file.exists()) {
    print(await file.readAsString());
  }
}
