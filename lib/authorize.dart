import 'package:http/http.dart' as http;

String _extractCookie(String rawCookie){
  String _session = '';
  String _l = '';
  print(rawCookie);
  if (rawCookie != null) {
    int index = rawCookie.indexOf(',');
    if (index > 0) {
      List<String> cookieList = rawCookie.split(',');
      cookieList.forEach((cVal) {
        _l = cVal;
      });
    } else {
      _l = rawCookie;
    }

    index = _l.indexOf(';');
    _session = (index == -1) ? _l : _l.substring(0, index);

  }
  return _session;
}

class Authorize {
  String password;
  String login;
  String token;
  String session;
  String userId;

  final String loginUrl = '/user/login/';
  final String mainUrl = 'http://forum330.com/forum';

  final String tokenExtractRegexp = 'var ET=\\{.*?\"token\":\"(.*?)\".*?\\}';
  final String userIdExtractRegexp = 'var ET=\\{.*?\"userId\":(.*?),.*?\\}';


  Authorize(this.login, this.password);

  Future <bool> sendLoginRequest() async {
    String _url = '$mainUrl$loginUrl';

    // try get Token
    await _getInitToken(_url);

    // try get userId & token
    await _sendAuthPost(_url);

    // try get userId & Token
    await _getFinalAuth(_url);

    return isAuthenticated();
  }

  Future _getInitToken(String _url) async{
    String _token = '';
    String _session = '';
    await http.get(_url).then((response) {

      print('PART I:');
      print('GET $_url');
      var _body = response.body;
      // prepare regexp to extract Token
      RegExp expToken = new RegExp(tokenExtractRegexp);

      var t = expToken.allMatches(_body);
      _token = t.first.group(1).toString();
      print('  token: $_token');

      //get cookie
      var rawCookie = response.headers['set-cookie'].toString();

      _session = _extractCookie(rawCookie);
      print('  Cookie(set-cookie): $_session');
    }).catchError((error) {
      _token = '';
      _session = '';
    });

    this.token = _token;
    this.session = _session;
  }

  Future _sendAuthPost(String _url) async {
    String _session;

    print('PART II Send POST with login/pass');
    print('POST $_url');
    print(' form-data - username: ${this.login}');
    print(' form-data - password: ******');
    print(' form-data - token: ${this.token}');
    print(' Cookie: [${this.session}]');

    var request = new http.MultipartRequest( "POST", Uri.parse( _url ) );
    request.fields['username'] = this.login;
    request.fields['password'] = this.password;
    request.fields['return'] = '';
    request.fields['token'] = this.token;
    request.headers['Cookie'] = this.session;

    request.followRedirects = true;
    request.persistentConnection = true;

    await request.send().then((response) {
      print('status: ${response.statusCode}');
      if (response.statusCode == 302) {
        var rawCookie = response.headers['set-cookie'].toString( );
        _session = _extractCookie(rawCookie);
        print('  RAW headers: ${response.headers}');
        print('  Cookie(set-cookie): $_session');
      } else {
        _session = '';
      }
    }).catchError( (error) {
      _session = '';
    });
    this.session = _session;
  }

  Future _getFinalAuth(String _url) async{
    String _token = '';
    String _userid = '';

    Map<String, String> httpHeaders = {
      'Accept': 'text/html,application/xhtml+xml,application/xml',
      'Referer': 'http://forum330.com/forum/',
      'Charset': 'utf-8',
      'Cookie': this.session
    };

    await http.get('$mainUrl', headers: httpHeaders).then((response) {
      print('PART III:');
      print('GET $mainUrl/');
      print('  Cookie: ${this.session}');

      // prepare regexp to extract userId & Token
      RegExp expUserId = new RegExp(userIdExtractRegexp);
      RegExp expToken = new RegExp(tokenExtractRegexp);

      var _body = response.body;

      var t = expUserId.allMatches(_body);

      _userid = t.first.group(1).toString();
      print('  userId: $_userid');

      t = expToken.allMatches(_body);
      _token = t.first.group(1).toString();
      print('  token: $_token');

    }).catchError((error) {
      _token = '';
      _userid = '';
    });

    this.token = _token;
    this.userId = _userid;
  }

  bool isAuthenticated() {
    if (this == null || this?.token == null) {
      print(' isAuthenticated false');
      return false;
    } else {
      print('== isAuthenticated token:${this.token} session:${this.session} userId:${this.userId} login:${this.login} password:${this.password}');
      var t = this.token?.isNotEmpty ?? false;
      var s = this.session?.isNotEmpty ?? false;
      var u = this.userId?.isNotEmpty ?? false;
      var l = this.login?.isNotEmpty ?? false;
      var p = this.password?.isNotEmpty ?? false;

      return (t && s && u && l && p);
    }
  }
}

