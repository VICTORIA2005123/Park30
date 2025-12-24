import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../secrets.dart'; // User must populate this

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  Future<bool> sendOTP(String recipientEmail, String otp) async {
    final smtpServer = gmail(Secrets.gmailEmail, Secrets.gmailAppPassword);

    final message = Message()
      ..from = Address(Secrets.gmailEmail, 'Park30 Support')
      ..recipients.add(recipientEmail)
      ..subject = 'Your Park30 Verification Code'
      ..text = 'Your verification code is: $otp\n\nThis code expires in 10 minutes.'
      ..html = '''
        <h1>Verification Code</h1>
        <p>Your code is: <strong>$otp</strong></p>
        <p>This code expires in 10 minutes.</p>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      return true;
    } on MailerException catch (e) {
      print('Message not sent. \n' + e.toString());
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      print('Unknown error: $e');
      return false;
    }
  }
}
