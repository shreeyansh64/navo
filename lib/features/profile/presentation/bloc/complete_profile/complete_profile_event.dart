part of 'complete_profile_bloc.dart';

sealed class CompleteProfileEvent {}

class CompleteProfileSubmitted extends CompleteProfileEvent {
  final String fullName;
  final String section;
  final String year;
  final String branch;
  final String studentNumber;
  final File image;

  CompleteProfileSubmitted({
    required this.fullName,
    required this.section,
    required this.year,
    required this.branch,
    required this.studentNumber,
    required this.image,
  });
}
