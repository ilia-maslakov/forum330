import 'package:flutter/material.dart';
import 'package:flutter_image/network.dart';
import 'bbcode.dart' as bbcode;
import 'const.dart';

final TextStyle bold = new TextStyle(fontWeight: FontWeight.bold);
final TextStyle italic = new TextStyle(fontStyle: FontStyle.italic);
final TextStyle code = new TextStyle(fontFamily: 'RobotoMono');
final TextStyle strike = new TextStyle(decoration: TextDecoration.lineThrough);
final TextStyle urlunderline = new TextStyle(decoration: TextDecoration.underline);
final TextStyle quote = new TextStyle(backgroundColor: Colors.white54, fontStyle: FontStyle.italic);
final TextStyle h1 = new TextStyle(height: 1.1, fontSize: 16, fontWeight: FontWeight.w500);


class PostListTile extends StatelessWidget {
  final String postId;
  final String userId;
  final String username;
  final String content;
  List<InlineSpan> richString;
  //List<WidgetSpan> richImages;

  PostListTile(this.postId, this.userId, this.username, this.content){
    if (content.isNotEmpty){
      richString = new List<InlineSpan>();
      List<bbcode.Entity> parsedText = bbcode.Parser.parse(content);
      //print(content);
      parsedText?.forEach((p) {

        TextStyle defStyle = new TextStyle(fontStyle: FontStyle.normal, fontWeight: FontWeight.normal);
        TextStyle curStyle = new TextStyle(fontStyle: FontStyle.normal, fontWeight: FontWeight.normal);
        if (p.value.isNotEmpty) {
          String url = '';
          String user = '';
          List<bbcode.Tags> tags = p.tagList;
          if (p.attr != null) {
            user = ' > ${p.attr['user']}: \n';
          }
          print(p.value);
          bool isImage = false;
          bool isQuote = false;

          tags.forEach((f) {
            print(f.toString());
            if (!isImage) {
              switch (f) {
                case bbcode.Tags.IMG: {
                  isImage = true;
                  break;
                }
                case bbcode.Tags.BOLD: {
                  curStyle = curStyle.merge(bold);
                  break;
                }
                case bbcode.Tags.ITALIC: {
                  curStyle = curStyle.merge(italic);
                  break;
                }
                case bbcode.Tags.HEADLINE: {
                  curStyle = curStyle.merge(h1);
                  break;
                }
                case bbcode.Tags.STRIKE: {
                  curStyle = curStyle.merge(strike);
                  break;
                }
                case bbcode.Tags.CODE: {
                  curStyle = curStyle.merge(code);
                  break;
                }
                case bbcode.Tags.URL: {
                  curStyle = curStyle.merge(urlunderline);
                  break;
                }
                case bbcode.Tags.NORMAL: {
                  curStyle = defStyle.copyWith();
                  break;
                }
                case bbcode.Tags.QUOTE: {
                  isQuote = true;
                  curStyle = curStyle.merge(quote).merge(italic);
                  break;
                }

              }
            }
          });
          if (isImage) {
            WidgetSpan e = new WidgetSpan(
              child: Image(
                image: new  NetworkImageWithRetry(addUrlPrefix(p.value))
              )
            );
            richString.add(e);
          } else {
            if (isQuote) {
              TextSpan e = new TextSpan(
                text: user,
                style: defStyle.merge(bold).merge(italic)
              );
              richString.add(e);
            }
            TextSpan e = new TextSpan(
              text: p.value,
              style: curStyle
            );
            richString.add(e);
          }
        }
      });
      if (richString.length == 0) {
        richString.add(TextSpan(text: ''));
      }
    }
  }

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
                  Icon(Icons.account_circle, size: 25, color: Colors.grey),
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
                  flex: 6,
                  child: Container(
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: richString
                      )
                    )
                  )
                )

              ],
            ),
          ],
        )
      ),
    );
  }
}

String addUrlPrefix(String value) {
  if(value.length > 0 && value[0] == '/') {
    print('New img: $forumUrl$value');
    return '$forumUrl$value';
  }
  print('img: $value');
  return value;
}
