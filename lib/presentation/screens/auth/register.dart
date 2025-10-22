// import 'package:flutter/material.dart';
// import 'package:linux_test2/services/auth.dart';
// import 'package:linux_test2/shared/constans.dart';
// import 'package:linux_test2/shared/loading.dart';
//
// class Register extends StatefulWidget {
//   final Function toggleView;
//
//   const Register({super.key, required this.toggleView});
//
//   @override
//   State<Register> createState() => _RegisterState();
// }
//
// class _RegisterState extends State<Register> {
//   final AuthService _auth = AuthService();
//   final _formKey = GlobalKey<FormState>();
//   bool loading = false;
//
//   String email = '';
//   String password = '';
//   String error = '';
//
//   @override
//   Widget build(BuildContext context) {
//     return loading ? Loading() : Scaffold(
//       backgroundColor: Colors.brown[100],
//       appBar: AppBar(
//         backgroundColor: Colors.brown[400],
//         elevation: 0.0,
//         title: Text('Sign up in to Brew Crew'),
//         actions: <Widget>[
//           TextButton.icon(
//             icon: Icon(Icons.person),
//             label: Text('Sign In'),
//             onPressed: () {
//               widget.toggleView();
//             },
//           ),
//         ],
//       ),
//       body: Container(
//         padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: <Widget>[
//               SizedBox(height: 20.0),
//               TextFormField(
//                 decoration: textInputDecoration.copyWith(hintText: 'Email'),
//                 validator: (val) => val!.isEmpty ? 'Enter an email' : null,
//                 onChanged: (val) {
//                   setState(() {
//                     email = val;
//                   });
//                 },
//               ),
//               SizedBox(height: 20.0),
//               TextFormField(
//                 decoration: textInputDecoration.copyWith(hintText: 'Password'),
//                 validator: (val) =>
//                     val!.length < 6 ? 'Enter a password 6+ chars long' : null,
//                 obscureText: true,
//                 onChanged: (val) {
//                   setState(() {
//                     password = val;
//                   });
//                 },
//               ),
//               SizedBox(height: 20.0),
//               ElevatedButton(
//                 onPressed: () async {
//                   if (_formKey.currentState!.validate()) {
//                     setState(() {
//                       loading = true;
//                     });
//                     dynamic result = await _auth.registerWithEmailAndPassword(
//                       email,
//                       password,
//                     );
//                     if (result == null) {
//                       setState(() {
//                         error = 'please supply a valid email';
//                         loading = false;
//                       });
//                     }
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.pink[400],
//                 ),
//                 child: Text('Register', style: TextStyle(color: Colors.white)),
//               ),
//               SizedBox(height: 12.0),
//               Text(error, style: TextStyle(color: Colors.red, fontSize: 14.0)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
