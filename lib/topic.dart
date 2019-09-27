import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'dart:convert';
import 'postile.dart';
import 'package:http/http.dart' as http;

import 'main.dart';

List<Post> cachedPosts;
bool globalForceUpdatePosts = true;


Future<Post> fetchPost() async {
  final response =
  await http.get('https://jsonplaceholder.typicode.com/posts/1');

  if (response.statusCode == 200) {
    // If the call to the server was successful, parse the JSON.
    return null; //Post.fromJson(json.decode(response.body));
  } else {
    // If that call was not successful, throw an error.
    throw Exception('Failed to load post');
  }
}


class Post {
  String postId;
  String userId;
  String username;
  String content;

  Post(this.postId, this.userId, this.username, this.content);

}

final ThemeData iOSTheme = new ThemeData(
  primarySwatch: Colors.red,
  primaryColor: Colors.grey[400],
  primaryColorBrightness: Brightness.dark,
);

final ThemeData androidTheme = new ThemeData(
  primarySwatch: Colors.blue,
  accentColor: Colors.green,
);

final String defaultUserName = 'bob';

class TopicPage extends StatefulWidget {
  TopicPage({Key key}) : super(key: key);

  @override
  State createState() => new TopicWindow(); // _MainPageState();
}

class TopicWindow extends State<TopicPage> with TickerProviderStateMixin {
  final List<Msg> _messages = <Msg>[];
  final TextEditingController _textController = new TextEditingController();
  bool _isWriting = false;

  @override
  Widget build(BuildContext context) {
    Topic args = ModalRoute.of(context).settings.arguments;
    print('ModalRoute.of(context).settings.arguments: ${args.id}');
    var futureBuilder = new FutureBuilder<List<Post>>(
      future: _getPosts(args.id, 1, globalForceUpdatePosts),
      builder: (BuildContext ctx, AsyncSnapshot snapshot){
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
            }
            return _messageList(context, snapshot);
        }
        return null;
      },
    );

    return new Scaffold(
      appBar: new AppBar(
        title: new Text(args.title),
      ),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            new Column(
              children: <Widget>[
                new Flexible(
                  child: futureBuilder
                ),
                new Divider(height: 1.0),
                new Container(
                  child: _buildComposer(),
                  decoration: new BoxDecoration(
                    color: Theme.of(context).cardColor
                  )
                )
              ]
            )
          ]
        )
      )
    );
  }

  Future <List<Post>> _getPosts(String topicId, int startFrom, bool forcedUpdate) async {
 
    globalForceUpdatePosts = forcedUpdate;
    if (!authorizeData.isAuthenticated()) {
      return null;
    }
    if (cachedPosts == null) {
      cachedPosts = new List<Post>();
    }
    int topicPage = 1;
    //String topicUrl = '${authorizeData.mainUrl}/?p=conversations/index.json&userId=${authorizeData.userId}&token=${authorizeData.token}';
    String topicUrl = '${authorizeData.mainUrl}/?p=conversation/index.json/$topicId/p$topicPage&userId=${authorizeData.userId}&token=${authorizeData.token}';

    //topicUrl = '$mainUrl/member/me';
    //&search=%23%D0%BB%D0%B8%D0%BC%D0%B8%D1%82%3A${topicCount.toString()}
    var _url = topicUrl;

    print('get posts');
    print('   token: ${authorizeData.token}');
    print('   session: ${authorizeData.session}');
    print('   userId: ${authorizeData.userId}');
    print('   main url: ${authorizeData.mainUrl}');

    Map<String, String> httpHeaders = {
      'Referer': 'http://forum330.com/forum/',
      'Cookie': authorizeData.session
    };
    if (!globalForceUpdatePosts && cachedPosts != null) {
      print(' return cached content ');
      globalForceUpdatePosts = false;
      return cachedPosts;
    }
    cachedPosts.clear();
    print('Try get posts');
    await http.get(_url, headers: httpHeaders).then((response) {
      var tmp = response.body;
      var t = json.decode(tmp);
      var res = t['posts'];
      if (res != null) {
        print('res.length: ${res.length}');
        for (var x = 0; x < res.length; x++) {
          cachedPosts.add(Post(res[x]['relativePostId'], res[x]['memberId'], res[x]['username'], res[x]['content']));
        }
      }
      //cachedPosts = new List<Post>.from(values);
      print(' ok');
    }).catchError((error) {
      print('not ok ${error.toString()}');
    });
    globalForceUpdatePosts = false;

    return cachedPosts;
  }

  Widget _messageList(BuildContext ctx, AsyncSnapshot snapshot) {

    return new ListView.builder(
      itemCount: cachedPosts.length,
      reverse: false,
      padding: new EdgeInsets.all(6.0),
      itemBuilder: (context, index) {
        return new PostListTile(
          cachedPosts[index].postId,
          cachedPosts[index].userId,
          cachedPosts[index].username,
          cachedPosts[index].content
        );
      }
    );
/*
    return new ListView.builder(
      itemBuilder: (_, int index) => _messages[index],
      itemCount: _messages.length,
      reverse: true,
      padding: new EdgeInsets.all(6.0),
    );

 */
  }

  Widget _buildComposer() {
    return new IconTheme(
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Container(
        margin: const EdgeInsets.symmetric(horizontal: 9.0),
        child: new Row(
          children: <Widget>[
            new Flexible(
              child: new TextField(
                controller: _textController,
                onChanged: (String txt) {
                  /*
                  setState(() {
                    _isWriting = txt.length > 0;
                  });

                   */
                },
                onSubmitted: _submitMsg,
                decoration: new InputDecoration.collapsed(hintText: "Сообщение"),
              ),
            ),
            new Container(
              margin: new EdgeInsets.symmetric(horizontal: 3.0),
              child: Theme.of(context).platform == TargetPlatform.iOS
                ? new CupertinoButton(
                child: new Text("Submit"),
                onPressed: _isWriting ? () => _submitMsg(_textController.text)
                  : null
              )
                : new IconButton(
                icon: new Icon(Icons.send),
                onPressed: _isWriting
                  ? () => _submitMsg(_textController.text)
                  : null,
              )
            ),
          ],
        ),
        decoration: Theme.of(context).platform == TargetPlatform.iOS
          ? new BoxDecoration(
          border:
          new Border(top: new BorderSide(color: Colors.brown))) :
        null
      ),
    );
  }

  void _submitMsg(String txt) {
    _textController.clear();
    setState(() {
      _isWriting = false;
    });
    Msg msg = new Msg(
      txt: txt,
      animationController: new AnimationController(
        vsync: this,
        duration: new Duration(milliseconds: 800)
      ),
    );
    setState(() {
      _messages.insert(0, msg);
    });
    msg.animationController.forward();
  }

  @override
  void dispose() {
    for (Msg msg in _messages) {
      msg.animationController.dispose();
    }
    super.dispose();
  }

}

class Msg extends StatelessWidget {
  Msg({this.txt, this.animationController});
  final String txt;
  final AnimationController animationController;

  @override
  Widget build(BuildContext ctx) {
    return new SizeTransition(
      sizeFactor: new CurvedAnimation(
        parent: animationController, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: new Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: const EdgeInsets.only(right: 18.0),
              child: new CircleAvatar(child: new Text(defaultUserName[0])),
            ),
            new Expanded(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Text(defaultUserName, style: Theme.of(ctx).textTheme.subhead),
                  new Container(
                    margin: const EdgeInsets.only(top: 6.0),
                    child: new Text(txt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}