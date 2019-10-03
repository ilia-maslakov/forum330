import 'main.dart';
import 'const.dart';


import 'package:http/http.dart' as http;

class SendMessage {
  String topicId;
  String content;

  String token;
  String session;
  String userId;

  final String messageUrl = '/?p=conversation/reply.ajax/';
  final String mainUrl = '$forumUrl/forum';
  final String referUrl = '$forumUrl/forum';

  SendMessage(this.content, this.topicId){
    token = authorizeData.token;
    session = authorizeData.session;
    userId = authorizeData.userId;
  }

  Future<int> sendPostMessage() async {
    String _url = '$mainUrl$messageUrl$topicId';
    int res;


    print('PART II Send POST with content');
    print('POST $_url');
    print(' form-data - conversationId: ${this.topicId}');
    print(' form-data - content: ${this.content}');
    print(' form-data - token: ${this.token}');
    print(' Cookie: [${this.session}]');

    var request = new http.MultipartRequest( "POST", Uri.parse( _url ) );
    request.fields['conversationId'] = this.topicId;
    request.fields['userId'] = this.userId;
    request.fields['content'] = this.content;
    request.fields['token'] = this.token;
    request.headers['Cookie'] = this.session;

    request.followRedirects = true;
    request.persistentConnection = true;

    await request.send().then((response) {
      print('status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Message sended - OK');
        res = response.statusCode;
      }
    }).catchError( (error) {
      print('Message not sended - BAD');
      res = -1;
    });
    return res;
  }

}

