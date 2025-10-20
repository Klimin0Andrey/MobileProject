import 'package:linux_test2/services/database.dart';
import 'package:linux_test2/shared/constans.dart';
import 'package:linux_test2/shared/loading.dart';
import 'package:flutter/material.dart';
import 'package:linux_test2/models/user.dart';
import 'package:provider/provider.dart';

class SettingsForm extends StatefulWidget {
  const SettingsForm({super.key});

  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  final List<String> sugars = ['0', '1', '2', '3', '4'];

  // Инициализируем поля начальными значениями
  String _currentName = '';
  String _currentSugars = '0';
  int _currentStrength = 100;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);

    if (user == null) {
      return const Loading();
    }

    return StreamBuilder<UserData>(
      stream: DatabaseService(uid: user.uid).userData,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          UserData? userData = snapshot.data;

          if (_currentName.isEmpty && userData != null) {
            _currentName = userData.name;
            _currentSugars = userData.sugars;
            _currentStrength = userData.strength;
          }

          return Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                Text(
                  'Update your brew settings.',
                  style: TextStyle(fontSize: 18.0),
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  initialValue: _currentName,
                  decoration: textInputDecoration.copyWith(hintText: 'Name'),
                  validator: (val) =>
                      val!.isEmpty ? 'Please enter a name' : null,
                  onChanged: (val) => setState(() => _currentName = val!),
                ),
                SizedBox(height: 10.0),
                // Dropdown для выбора сахара
                DropdownButtonFormField<String>(
                  initialValue: _currentSugars,
                  decoration: textInputDecoration.copyWith(hintText: 'Sugars'),
                  items: sugars.map((sugar) {
                    return DropdownMenuItem<String>(
                      value: sugar,
                      child: Text('$sugar sugars'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _currentSugars = val!),
                ),
                Slider(
                  value: _currentStrength.toDouble(),
                  activeColor: Colors.brown[_currentStrength],
                  inactiveColor: Colors.brown[_currentStrength],
                  min: 100.0,
                  max: 900.0,
                  divisions: 8,
                  onChanged: (val) => setState(() {
                    _currentStrength = val.round();
                  }),
                ),
                SizedBox(height: 10.0),
                // Обновленная кнопка (вместо устаревшего RaisedButton)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[400],
                  ),
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      await DatabaseService(uid: user.uid).updateUserData(
                        _currentSugars,
                        _currentName,
                        _currentStrength,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Update', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        } else {
          return Loading();
        }
      },
    );
  }
}
