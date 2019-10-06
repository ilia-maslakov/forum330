import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:http/http.dart' as http;
import 'package:indexed_list_view/indexed_list_view.dart';

import 'main.dart';
import 'postile.dart';
import 'postmsg.dart';
import 'const.dart';

List<Post> cachedPosts;
bool globalForceUpdatePosts = true;

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

  final TextEditingController msgTextController = new TextEditingController();
  String topicId = '';
  IndexedScrollController _controller;
  Topic args;
  int currentPage;
  int maxPages;


  _printLatestValue() {
    print("text field: ${msgTextController.text}");
  }

  void initState() {
    _controller = new IndexedScrollController();
    msgTextController.addListener(_printLatestValue);
    maxPages = 1;
    currentPage = -1;
    print('Topic page InitState()');
    super.initState();
  }



  @override
  Widget build(BuildContext context) {

    args = ModalRoute.of(context).settings.arguments;
    topicId = args.id;

    maxPages = args.countPosts ~/ 100 + 1;
    print('max pages: $maxPages');
    if (maxPages < 1) {
      maxPages = 1;
    }
    if (currentPage < 0) {
      currentPage = args.lastRead ~/ 100 + 1;
    }

    print('ModalRoute.of(context).settings.arguments: ${args.id}');
    var futureBuilder = new FutureBuilder<List<Post>>(
      future: _getPosts(args.id),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return new Text('Press button to start.');
          case ConnectionState.active:
          case ConnectionState.waiting:
            {
              return new Center(child: CircularProgressIndicator());
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

    int unread = args.countPosts - args.lastRead;

    return new Scaffold(
      appBar: new AppBar(
        title: Padding(
          padding: const EdgeInsets.only(bottom: 0.0),
          child: ListTile(
            isThreeLine: false,
            title: Text(args.title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: Text('Сообщений: ${args.countPosts} новых: $unread', style: TextStyle(color: Colors.white))
          ),
        )
      ),
      body: new Column(children: <Widget>[
        new Flexible(child: futureBuilder),
        new Divider(height: 1.0),
        new Container(child: _buildComposer(), decoration: new BoxDecoration(color: Theme.of(context).cardColor))
      ]),
      floatingActionButton: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 0, 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FloatingActionButton(
                  heroTag: 'rewind',
                  backgroundColor: Colors.blue,
                  mini: true,
                  child: Icon(
                    Icons.fast_rewind,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    currentPage = 1;
                    setState(() {
                      print('currentPage: $currentPage');
                      globalForceUpdatePosts = true;
                      //_getPosts(true);
                      print('Pressed rewind');
                    });
                  },
                ),
                FloatingActionButton(
                  backgroundColor: Colors.blue,
                  heroTag: 'forward',
                  mini: true,
                  child: Icon(
                    Icons.fast_forward,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    currentPage = maxPages;
                    setState(() {
                      print('currentPage: $currentPage');
                      globalForceUpdatePosts = true;
                      //_getPosts(true);
                      print('Pressed forward');
                      _controller.animateToIndexAndOffset(index: cachedPosts.length - 1, offset: -250);
                    }
                    );
                  },
                ),
              ],
            ),
            FloatingActionButton(
              heroTag: 'end',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                _controller.animateToIndexAndOffset(index: cachedPosts.length - 1, offset: -250);
              },
              child: Icon(Icons.keyboard_arrow_down, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Post>> _getPosts(String topicId) async {
    if (!authorizeData.isAuthenticated()) {
      return null;
    }
    if (cachedPosts == null) {
      cachedPosts = new List<Post>();
    }

    String topicUrl = '${authorizeData.mainUrl}/?p=conversation/index.json/$topicId/p$currentPage&userId=${authorizeData.userId}&token=${authorizeData.token}';

    //topicUrl = '$mainUrl/member/me';
    //&search=%23%D0%BB%D0%B8%D0%BC%D0%B8%D1%82%3A${topicCount.toString()}
    var _url = topicUrl;

    print('get posts');
    print('   p = $currentPage');
    print('   token: ${authorizeData.token}');
    print('   session: ${authorizeData.session}');
    print('   userId: ${authorizeData.userId}');
    print('   url: $topicUrl');

    Map<String, String> httpHeaders = {'Referer': '$forumUrl/forum/', 'Cookie': authorizeData.session};
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

  Function messageItemBuilder() {
    return (BuildContext context, int index) {
      if (index < (cachedPosts?.length ?? 99) && index >= 0) {
        return PostListTile(
          cachedPosts[index].postId,
          cachedPosts[index].userId,
          cachedPosts[index].username,
          cachedPosts[index].content
        );
      } else {
        return null;
      }
    };
  }

  Widget _messageList(BuildContext context, AsyncSnapshot snapshot) {
    IndexedListView _tilelist = new IndexedListView.builder(

      //itemCount: cachedPosts.length,
      maxItemCount: cachedPosts.length,
      controller: _controller,
      reverse: false,
      padding: new EdgeInsets.all(6.0),
      itemBuilder: messageItemBuilder()
    );

    return _tilelist;
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
                controller: msgTextController,
                minLines: 1,
                maxLines: 8,
                onSubmitted: _submitMsg,
                decoration: new InputDecoration.collapsed(hintText: "Сообщение"),
              ),
            ),
            new Container(
              margin: new EdgeInsets.symmetric(horizontal: 3),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: () => _submitMsg(msgTextController.text),
              )
            ),
          ],
        ),
      ),
    );
  }
  void _submitMsg(String txt) async {
    msgTextController.clear();
    var pmsg = new SendMessage(txt, topicId);
    int res = await pmsg.sendPostMessage();
    if (res == 200) {
      globalForceUpdatePosts = true;
      setState(() {
        print('Try send $txt');
      });
    }
  }

  @override
  void dispose() {
    msgTextController.dispose();
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
      sizeFactor: new CurvedAnimation(parent: animationController, curve: Curves.easeOut),
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
