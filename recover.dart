import 'dart:io';
import 'dart:convert';
void main() {
  final logFile = File('C:\\Users\\ceily\\.gemini\\antigravity\\brain\\a1c66185-687c-492a-a7a6-8daf0c357cd3\\artifacts\\log.txt');
  final outFile = File('recovered.dart');
  final bytes = logFile.readAsBytesSync();
  final content = utf8.decode(bytes, allowMalformed: true);
  final lines = content.split('\n');
  final Map<int, String> recovered = {};
  final reg = RegExp(r'^(\d+):\s(.*)$');
  for (var line in lines) {
    line = line.trimRight();
    final match = reg.firstMatch(line);
    if (match != null) {
      recovered[int.parse(match.group(1)!)] = match.group(2)!;
    }
  }
  final sortedKeys = recovered.keys.toList()..sort();
  final out = outFile.openWrite();
  for (var key in sortedKeys) {
    out.writeln(recovered[key]);
  }
  out.close();
}
