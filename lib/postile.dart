import 'package:flutter/material.dart';
import 'bbcode.dart' as bbcode;

final TextStyle bold = new TextStyle(fontWeight: FontWeight.bold);
final TextStyle italic = new TextStyle(fontStyle: FontStyle.italic);
final TextStyle strike = new TextStyle(decoration: TextDecoration.lineThrough);
final TextStyle underline = new TextStyle(decoration: TextDecoration.underline);
final TextStyle h1 = new TextStyle(height: 5, fontSize: 10);


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
      print(content);
      parsedText.forEach((p) {
        TextStyle curStyle = new TextStyle(fontStyle: FontStyle.normal, fontWeight: FontWeight.normal);
        if (p.value.isNotEmpty) {
          List<bbcode.Tags> tags = p.tagList;
          print(p.value);
          bool isImage = false;
          tags.forEach((f) {
            print(f.toString());
            if (!isImage) {
              if (f == bbcode.Tags.IMG) {
                isImage = true;
              } else if (f == bbcode.Tags.BOLD) {
                curStyle = curStyle.merge(bold);
              } else if (f == bbcode.Tags.ITALIC) {
                curStyle = curStyle.merge(italic);
              } else if (f == bbcode.Tags.HEADLINE) {
                curStyle = curStyle.merge(h1);
              } else if (f == bbcode.Tags.STRIKE) {
                curStyle = curStyle.merge(strike);
              }
            }
          });
          if (isImage) {
            WidgetSpan e = new WidgetSpan(
              child: Image.network(p.value)
            );
            richString.add(e);
          } else {
            TextSpan e = new TextSpan(
              text: p.value,
              style: curStyle
            );
            richString.add(e);
          }
        }
      });
      if (richString.length == 0) {
        richString.add(TextSpan(text: ""));
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
                  flex: 2,

                  child: RichText(
                    text:
                    TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: richString
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
