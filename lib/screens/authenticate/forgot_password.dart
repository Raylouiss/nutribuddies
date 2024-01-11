import 'package:flutter/material.dart';
import 'package:nutribuddies/services/auth.dart';
import 'package:nutribuddies/constant/text_input_decoration.dart';
import 'package:nutribuddies/widgets/loading.dart';
import 'package:nutribuddies/constant/colors.dart';

import '../../widgets/wrapper.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final AuthService _auth = AuthService();
  final _formkey = GlobalKey<FormState>();
  bool loading = false;

  String email = '';

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Loading()
        : Scaffold(
            backgroundColor: background,
            body: Column(
              children: [
                Image.asset('assets/Login/Group1(1).png'),
                ClipRect(
                  child: Transform.translate(
                    offset: const Offset(0, -0),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(40, 0, 40, 52),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Forgot Password?",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                color: black,
                                fontSize: 32,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Text(
                            "Please enter the email address you'd like your password reset information sent to.",
                            textAlign: TextAlign.justify,
                            softWrap: true,
                            style: TextStyle(
                              color: black,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              letterSpacing: 0.25,
                            ),
                          ),
                          Form(
                            key: _formkey,
                            child: Column(children: [
                              const SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                decoration: textInputDecoration.copyWith(
                                    hintText: 'Email'),
                                validator: (val) =>
                                    val!.isEmpty ? 'Enter an email' : null,
                                onChanged: (val) {
                                  setState(() => email = val);
                                },
                              ),
                              const SizedBox(
                                height: 50,
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  if (_formkey.currentState!.validate()) {
                                    setState(() => loading = true);
                                    dynamic result =
                                        await _auth.resetPassword(email);
                                    if (result == null) {
                                      setState(() => loading = false);
                                    } else {
                                      // ignore: use_build_context_synchronously
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const CheckEmail()),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                  ),
                                  minimumSize: const Size(double.infinity, 48),
                                  backgroundColor: primary,
                                  foregroundColor: onPrimary,
                                ),
                                child: const Text(
                                  'Send',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const Wrapper(
                                                result: false,
                                              )),
                                    );
                                  },
                                  child: const Text(
                                    'Back to Login',
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}

class CheckEmail extends StatefulWidget {
  const CheckEmail({super.key});

  @override
  State<CheckEmail> createState() => _CheckEmailState();
}

class _CheckEmailState extends State<CheckEmail> {
  bool isSignIn = true;

  void notSignedIn() {
    setState(() => isSignIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          Image.asset('assets/Login/Group1(1).png'),
          ClipRect(
            child: Transform.translate(
              offset: const Offset(0, -0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 52),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Check Your Email",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: black,
                          fontSize: 32,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Text(
                      "We just emailed you with the instructions to reset your password.",
                      textAlign: TextAlign.justify,
                      softWrap: true,
                      style: TextStyle(
                        color: black,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        letterSpacing: 0.25,
                      ),
                    ),
                    const SizedBox(
                      height: 50,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Wrapper(
                                    result: false,
                                  )),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100.0),
                        ),
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: primary,
                        foregroundColor: onPrimary,
                      ),
                      child: const Text(
                        'Done',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}