import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'bbcode.dart' as bbcode;
import 'drawer.dart';
import 'authorize.dart';
import 'login.dart';
import 'topic.dart';

String appBarTitle = 'Форум 330';

List<Topic> cachedTopics;

class Topic {
  String id;
  String title;
  String lastUser;

  Topic(this.id, this.title, this.lastUser);
}

bool globalForceUpdate = true;

Authorize authorizeData = new Authorize('', '');

final ThemeData iOSTheme = new ThemeData(
  primarySwatch: Colors.red,
  primaryColor: Colors.grey[400],
  primaryColorBrightness: Brightness.dark,
);

final ThemeData androidTheme = new ThemeData(
  primarySwatch: Colors.blue,
  accentColor: Colors.green,
);

void checkBBCode(){
  var test="e[b]ss[/b]r[url=http://werterwt.rwe/3243423][b]fdhfdhgfdhgfdhd[/b][/url][quote=:@wewrew][h]eyter[i]werterw[b]erwterwter[/b]ewtew[/i][/h]werterwtewrtrew[/quote]    [quote=1234321-2134213:@wewrew]1111111111111111[/quote] [quote]22222222222222222[/quote]";
  var res = bbcode.Parser.parse(test);
  res.forEach((f){
    print(f.value);
  });
}

void main() => runApp(
  new MaterialApp(
    debugShowCheckedModeBanner: false,
    debugShowMaterialGrid: false,
    theme: defaultTargetPlatform == TargetPlatform.iOS
      ? iOSTheme
      : androidTheme,
    routes: {
      '/': (BuildContext context) => Forum(),
      '/login': (BuildContext context) => LoginPage(),
      '/topic': (BuildContext context) => TopicPage()
    },
    initialRoute: '/'
  )
);

class Forum extends StatefulWidget {
  @override
  State createState() => new ForumWindow(); // _MainPageState();
}

class ForumWindow extends State<Forum> with TickerProviderStateMixin {

  @override
  Widget build(BuildContext ctx) {
    var futureBuilder = new FutureBuilder(
      future: _getTopics(globalForceUpdate),
      builder: (BuildContext context, AsyncSnapshot snapshot){

        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return new Text('Press button to start.');
          case ConnectionState.active:
          case ConnectionState.waiting:
          {
            return new Center(
              child: CircularProgressIndicator()
            );
          }
          case ConnectionState.done:
            if (snapshot.hasError) {
              return new Text('Error: ${snapshot.error}');
            } else {

              return createListView(context, snapshot);
            }
        }

        return null;
      },
    );




    setState(() {
      appBarTitle = 'Форум 330';
    });

    return new Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.supervised_user_circle, size: 90, color: Colors.black26),
                  Text('Пользователь')
                ],
              ),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              title: Text('Настройки'),
              onTap: () {
                //_getTopics();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Войти'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login').then((onValue) {
                  print('Return from login');
                  print(authorizeData.session);
                  Authorize s = onValue;
                  print(s.session);
                });
              },
            ),
          ],
        )),
      appBar: AppBarWithDrawer(height: 56),
      body: futureBuilder,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          globalForceUpdate = true;
          setState(() {
            checkBBCode();
            _getTopics(true);
            print('Pressed UPDATE button');
          });
        },
        child: Icon(Icons.refresh),
      ),
    );
  }

  Widget createListView(BuildContext context, AsyncSnapshot snapshot) {
    List<Topic> values = snapshot.data;
    return new ListView.builder(
      itemCount: values.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: FlutterLogo(size: 34.0),
          title: Text(values[index].title),
          subtitle: Text(values[index].lastUser),
          trailing: Icon(Icons.more_vert),
          onTap: () {
            print(' open: ${values[index].id}');
            globalForceUpdatePosts = true;
            Navigator.pushNamed(context, '/topic', arguments: values[index]);
          },
        );
      }
    );
  }

  Future<List<Topic>> _getTopics(bool forced) async {
    var values = new List<Topic>();
    //&search=%23%D0%BB%D0%B8%D0%BC%D0%B8%D1%82%3A${topicCount.toString()}
    if (!authorizeData.isAuthenticated()) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      try{
        authorizeData.login = prefs.getString('login');
        authorizeData.password = prefs.getString('password');
      } catch (e){
        authorizeData.password = '';
        authorizeData.login = '';
      }
      var auResult = await authorizeData.sendLoginRequest();
      if (!auResult) {
        //Navigator.pushNamed(context, '/login');
      }
    }

    String topicUrl = '${authorizeData.mainUrl}/?p=conversations/index.json&userId=${authorizeData.userId}&token=${authorizeData.token}';
    var _url = topicUrl;

    print('get topics');
    print('GET: $_url');

    Map<String, String> httpHeaders = {
      'Host': 'forum330.com',
      'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:69.0) Gecko/20100101 Firefox/69.0',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Referer': 'http://forum330.com/forum/',
      'Cookie': authorizeData.session,
      'Upgrade-Insecure-Requests': '1',
      'Pragma': 'no-cache',
      'Cache-Control': 'no-cache'
    };

    if (!globalForceUpdate && cachedTopics != null) {
      print(' return cached content ');
      return cachedTopics;
    }

    print('Try get content');

    await http.get(_url, headers: httpHeaders).then((response) {
      print(' ok');
      var tmp = response.body;
      var t = json.decode(tmp);
      var res = t['results'];
      if (res != null) {
        print('Count topcs: ${res.length}');
        for (var x = 0; x < res.length; x++) {
          values.add(Topic(res[x]['conversationId'], res[x]['title'], res[x]['lastPostMember']));
        }
      }
    }).catchError((error) {
      print('not ok  ${error.toString()}');
    });

    cachedTopics = new List<Topic>.from(values);
    globalForceUpdate = false;
    return cachedTopics;
  }

  @override
  void dispose() {
    super.dispose();
  }

}
