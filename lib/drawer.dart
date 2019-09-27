import 'package:flutter/material.dart';
import 'main.dart';

class AppBarWithDrawer extends StatelessWidget implements PreferredSizeWidget {
  final double height;

  const AppBarWithDrawer({Key key, @required this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var appBarTitleText = new Text(appBarTitle);
    return Column(
      children: <Widget>[
        Container(
          color: Colors.teal,
          child: Center(
            child: AppBar(
              title: appBarTitleText,
              elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 6.0,
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => null,
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
