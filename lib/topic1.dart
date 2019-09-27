import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'main.dart';

List<Post> cachedPosts;
bool globalForceUpdatePosts = true;


class Post {
  String postId;
  String userId;
  String username;
  String content;

  Post(this.postId, this.userId, this.username, this.content);

}

class PostListTile extends StatelessWidget {
  final String postId;
  final String userId;
  final String username;
  final String content;

  PostListTile(this.postId, this.userId, this.username, this.content);

  @override
  Widget build(BuildContext context) {

    return Container(
      color: Colors.white30,
      child: Container(
        padding: const EdgeInsets.all(5.0),
        margin: const EdgeInsets.fromLTRB(5, 4, 5, 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
          border: new Border.all(color: Colors.black12),
          color: Colors.white,
        ),
        child: Column(
          children: <Widget>[
            Container(
              color: Colors.white30,
              height: 30,
              child: Row(
                children: <Widget>[
                  Icon(Icons.account_circle, size: 25),
                  Expanded(
                    flex: 1,
                    child: Text(' #$postId  $username', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: Icon(Icons.format_quote),
                    iconSize: 15,
                    color: Colors.blue,
                    onPressed: null,
                  )
                ],
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 2,

                  child: Text(this.content)
                )
              ],
            ),
          ],
        )
      ),
    );
  }
}

class TopicPage extends StatefulWidget {
  @override
  _TopicPageState createState() => new _TopicPageState();
}

class CircleIconButton extends StatelessWidget {
  final double size;
  final Function onPressed;
  final IconData icon;

  CircleIconButton({this.size = 30.0, this.icon = Icons.send, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: this.onPressed,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment(0.0, 0.0), // all centered
          children: <Widget>[
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.grey[300]),
            ),
            Icon(
              icon,
              size: size * 0.6, // 60% width for icon
            )
          ],
        )));
  }
}

class _TopicPageState extends State<TopicPage>{

  TextEditingController messageController;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Topic args = ModalRoute.of(context).settings.arguments;
    print('ModalRoute.of(context).settings.arguments: ${args.id}');
    var futureBuilder = new FutureBuilder(
      future: _getPosts(args.id, 1, globalForceUpdatePosts),
      builder: (BuildContext context, AsyncSnapshot snapshot){
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return new Text('Press button to start.');
          case ConnectionState.active:
          case ConnectionState.waiting:
            return new Text('Ожидание данных...');
          case ConnectionState.done:
            if (snapshot.hasError) {
              return new Text('Error: ${snapshot.error}');
            }
            return createListView(context, snapshot);
        }
        return null;
      },
    );

    return new Scaffold(
      appBar: new AppBar(
        title: new Text(args.title),
      ),
      body: futureBuilder
    );
  }


  Widget createListView(BuildContext context, AsyncSnapshot snapshot) {
      List<Post> values = snapshot.data;

      return


        ListView.builder(
          itemCount: values.length,
          itemBuilder: (context, index) {
            return new PostListTile(
              values[index].postId,
              values[index].userId,
              values[index].username,
              values[index].content
            );
          },
        );
  }

  Future<List<Post>> _getPosts(String topicId, int startFrom, bool globalForceUpdatePosts) async {
    var values = new List<Post>();
    int topicPage = 1;
    //String topicUrl = '${authorizeData.mainUrl}/?p=conversations/index.json&userId=${authorizeData.userId}&token=${authorizeData.token}';
    String topicUrl = '${authorizeData.mainUrl}/?p=conversation/index.json/$topicId/p$topicPage&userId=${authorizeData.userId}&token=${authorizeData.token}';

    //topicUrl = '$mainUrl/member/me';
    //&search=%23%D0%BB%D0%B8%D0%BC%D0%B8%D1%82%3A${topicCount.toString()}
    var _url = topicUrl;

    print('get posts');
    print('GET: $_url');


//    'Host': 'forum330.com',
//    'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:69.0) Gecko/20100101 Firefox/69.0',
//    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
//    'Accept-Language': 'ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3',
//    'Accept-Encoding': 'gzip, deflate',
//    'Connection': 'keep-alive',
//    'Upgrade-Insecure-Requests': '1',
//    'Pragma': 'no-cache',
//    'Cache-Control': 'no-cache'

    Map<String, String> httpHeaders = {
      'Referer': 'http://forum330.com/forum/',
      'Cookie': authorizeData.session
    };

    if (!globalForceUpdatePosts && cachedPosts != null) {
      print(' return cached content ');
      return cachedPosts;
    }

    print('Try get posts');
    await http.get(_url, headers: httpHeaders).then((response) {
      print(' ok');
      var tmp = response.body;
      var t = json.decode(tmp);
      var res = t['posts'];
      if (res != null) {
        print('res.length: ${res.length}');
        for (var x = 0; x < res.length; x++) {
          values.add(Post(res[x]['relativePostId'], res[x]['memberId'], res[x]['username'], res[x]['content']));
        }
      }
    }).catchError((error) {
      print('not ok ${error.toString()}');
    });
    cachedPosts = new List<Post>.from(values);
    globalForceUpdatePosts = false;

    return values;
  }

}
