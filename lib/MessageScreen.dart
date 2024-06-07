import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_project1/ChatScreen.dart';
import 'package:my_project1/dashboardscreen.dart';

class MessgaeScreenPage extends StatefulWidget {
  final User? user;

  MessgaeScreenPage({required this.user});

  State<MessgaeScreenPage> createState() => _MessgaeScreenPageScreenState();
}

class _MessgaeScreenPageScreenState extends State<MessgaeScreenPage> {
  String? logged_username;

  String? documnet_id;
  List<String> documentIds = [];
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    var document = await FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.user!.uid)
        .get();

    setState(() {
      logged_username = document["name"];
    });
  }

  Future<bool> MyFriends(String? receiverId) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection("Friends")
        .where("receiver_id", isEqualTo: widget.user!.uid)
        .where("request_id", isEqualTo: receiverId)
        .where("status", isEqualTo: "accepted")
        .get();

    var querySnapshot2 = await FirebaseFirestore.instance
        .collection("Friends")
        .where("receiver_id", isEqualTo: receiverId)
        .where("request_id", isEqualTo: widget.user!.uid)
        .where("status", isEqualTo: "accepted")
        .get();


    return querySnapshot.docs.isNotEmpty || querySnapshot2.docs.isNotEmpty;
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => Dashboard(user: widget.user)),
                  (Route<dynamic> route) => false);
            },
            icon: Icon(Icons.home)),
        // centerTitle: true,
        title: Text('Hi, $logged_username'),
        backgroundColor: Colors.deepPurple[400],
        foregroundColor: Colors.white,
        elevation: 20,
      ),
      backgroundColor: Color.fromARGB(255, 177, 162, 205),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("Users").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: Text('No users found'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> userData =
                  document.data() as Map<String, dynamic>;

              if (document.id == widget.user!.uid) {
                return SizedBox();
              }

              return FutureBuilder<bool>(
                future: MyFriends(userData["uid"]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.data == true) {
                    return Card(
                      margin: EdgeInsets.all(5),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(friendId: userData["uid"] , friendName: userData["name"],)));
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: ClipOval(
                                child: Image.network(userData["profilepic"]),
                              ),
                            ),
                          ),
                          title: Text(userData["name"]),
                          trailing: Icon(Icons.arrow_forward_ios),
                        ),
                      ),
                    );
                  } else {
                    return SizedBox();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
