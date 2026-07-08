import 'package:flutter_test/flutter_test.dart';
import 'package:gym_owner_app/features/members/domain/user_credentials_generator.dart';

void main() {
  group('UserCredentialsGenerator', () {
    test('generateEmail - normal first name and last name', () {
      final email = UserCredentialsGenerator.generateEmail('Karan Palav');
      expect(email, 'karan@palav');
    });

    test('generateEmail - lowercase names and trims whitespace', () {
      final email = UserCredentialsGenerator.generateEmail('  Karan   Palav  ');
      expect(email, 'karan@palav');
    });

    test('generateEmail - single name uses first name as fallback last name', () {
      final email = UserCredentialsGenerator.generateEmail('Karan');
      expect(email, 'karan@karan');
    });

    test('generateEmail - multiple parts in last name are concatenated', () {
      final email = UserCredentialsGenerator.generateEmail('Karan Dev Palav');
      expect(email, 'karan@devpalav');
    });

    test('generatePassword - normal phone number', () {
      final pass = UserCredentialsGenerator.generatePassword('7021511537');
      expect(pass, 'ft1537');
    });

    test('generatePassword - phone number shorter than 4 digits uses all available', () {
      final pass = UserCredentialsGenerator.generatePassword('537');
      expect(pass, 'ft537');
    });

    test('generatePassword - phone number with formatting characters is cleaned', () {
      final pass = UserCredentialsGenerator.generatePassword('+91 (702) 151-1537');
      expect(pass, 'ft1537');
    });
  });
}
