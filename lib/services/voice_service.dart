import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final speech = SpeechToText();

  Future<String?> listen() async {
    bool available = await speech.initialize();

    if (!available) return null;

    String result = "";

    await speech.listen(
      onResult: (val) {
        result = val.recognizedWords;
      },
    );

    await Future.delayed(Duration(seconds: 4));
    await speech.stop();

    return result;
  }
}
