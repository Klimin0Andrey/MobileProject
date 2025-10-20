import 'package:flutter/material.dart';
import 'package:linux_test2/models/user.dart';
import 'package:linux_test2/screens/home/settings_form.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:linux_test2/services/database.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/screens/home/brew_list.dart';
import 'package:linux_test2/models/brew.dart';

class Home extends StatelessWidget {
  Home({super.key});

  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);

    void _showSettingsPanel() {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 60.0),
            child: SettingsForm(),
          );
        },
      );
    }

    return StreamProvider<List<Brew>?>.value(
      value: user != null ? DatabaseService(uid: user.uid).brews : null,
      initialData: null,
      child: Scaffold(
        backgroundColor: Colors.brown[50],
        appBar: AppBar(
          title: Text('YumYum'),
          backgroundColor: Colors.brown[400],
          elevation: 0.0,
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.logout), // Более подходящая иконка для выхода
              onPressed: () async {
                await _auth.signOut();
              },
              tooltip: 'Выйти', // Всплывающая подсказка
            ),
            TextButton.icon(
              icon: Icon(Icons.settings),
              label: Text('settings'),
              onPressed: () => _showSettingsPanel(),
            ),
          ],
        ),
        body: BrewList(),
      ),
    );
  }
}
