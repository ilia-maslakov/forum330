import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class LoginForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginFormState();
  }
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  String pass;
  String user;


  TextEditingController loginController;
  TextEditingController passwordController;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future _loadDefaults() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try{
      pass = prefs.getString('password');
      user = prefs.getString('login');

    } catch (e){
      pass = '';
      user = '';
    }

    setState(() {
      loginController = new TextEditingController();
      passwordController = new TextEditingController();

      loginController.text = user;
      passwordController.text = pass;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future _saveAuth(String login, String password) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', password);
    await prefs.setString('login', login);
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      padding: EdgeInsets.all(40),
      child: new Form(
        child: new Column(
          children: <Widget>[
            new Text('Имя пользователя / e-mail'),
            new TextFormField(
              controller: loginController,
              validator: (value) {
                if (value.isEmpty) {
                  return 'Поле не должно быть пустым';
                } else {
                  user = value;
                }
                return null;
              },
            ),
            new SizedBox(height: 20),
            new Text('Пароль'),
            new TextFormField(
              controller: passwordController,
              obscureText: true,
              validator: (value) {
                if (value.isEmpty) {
                  return 'Поле не должно быть пустым';
                } else {
                  pass = value;
                }
                return null;
              },
            ),
            new SizedBox(height: 20),
            new RaisedButton(
              onPressed: () async {
                if (_formKey.currentState.validate()) {
                  Scaffold.of(context)
                    .showSnackBar(new SnackBar(content: Text('Авторизация...'), backgroundColor: Colors.blue));
                  _saveAuth(user, pass);
                  authorizeData.password = pass;
                  authorizeData.login = user;

                  var authResult = await authorizeData.sendLoginRequest();
                  if (authResult) {
                    //globalForceUpdate = true;
                    Navigator.pop(context, authorizeData);
                  } else {
                    Scaffold.of(context)
                      .showSnackBar(new SnackBar(content: Text('Ошибка авторизации!'), backgroundColor: Colors.amberAccent));
                  }
                }
              },
              child: Text('Войти'),
              color: Colors.blue,
              textColor: Colors.white,
            )
          ],
        ),
        key: _formKey)
    );
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text('Вход'),
      ),
      body: LoginForm()
    );
  }
}