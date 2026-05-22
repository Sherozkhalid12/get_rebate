import 'package:flutter/material.dart';
import 'package:getrebate/app/modules/auth/views/auth_view.dart';

/// Post–social-login profile completion using the same fields as manual signup.
class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({super.key});

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  @override
  Widget build(BuildContext context) {
    return const AuthView(completeProfile: true);
  }
}
