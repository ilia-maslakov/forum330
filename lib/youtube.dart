import 'dart:convert';
import 'package:http/http.dart' as http;

import 'apikey.dart';

const regexp1 = r"^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$";
const regexp2 = r"^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{11}).*$";
const regexp3 = r"^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{11}).*$";

class YouTube {
  String extractYouTubeIdFromUrl(String url) {
    if (!url.contains("http")) {
      url = "http://$url";
    }
    if (url == null || url.length == 0) {
      return '';
    }

    for (var exp in [RegExp(regexp1), RegExp(regexp2), RegExp(regexp3)]) {
      Match match = exp.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return '';
  }

  Future<Map<String, String>> getDescription(String videoId) async {

    String snippetUrl = 'https://www.googleapis.com/youtube/v3/videos?id=$videoId&key=$youtubeApiKey&part=snippet';
    print('Try get snippet');
    Map<String, String> res;
    await http.get(snippetUrl).then((response) {
      var tmp = response.body;
      var t = json.decode(tmp);
      var title = t['items']['0']['title'];
      var thumbnail = t['items']['0']['thumbnails']['high']['url'];
      res = {'title': title, 'img': thumbnail};
      print(' ok');
    }).catchError((error) {
      res = null;
      print('not ok ${error.toString()}');
    });

    return res;
  }


}