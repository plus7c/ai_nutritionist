import 'package:flutter/material.dart';
import 'package:pizza_ordering_app/home/profile.dart';

class MainHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Options'),
      ),
      body: ListView(
        children: <Widget>[
          Text('Hi!'),
          ListTile(
            title: Text('Edit Profile', style: TextStyle(fontSize: 20)),
            trailing: Icon(Icons.edit),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeProfile()),
              );
            },
          ),
          // Add more list items here if needed
        ],
      ),
    );
  }
}

