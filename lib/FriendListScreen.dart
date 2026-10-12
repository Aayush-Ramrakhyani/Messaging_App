import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ChatScreen.dart';

class FriendListScreen extends StatefulWidget {
  final String myId;
  final String myName;

  FriendListScreen({required this.myId, required this.myName});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  String? logged_username;
  List<String> friendIds = [];
  var querySnapshot;
  var friendsData;
  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    // Fetch the logged-in user's data
    var document = await FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.myId)
        .get();

    setState(() {
      logged_username = document["name"];
    });

    
    friendsData = await FirebaseFirestore.instance
        .collection("Friends")
        .where("request_id", isEqualTo: widget.myId)
        .where("status", isEqualTo: "accepted")
        .get();

    setState(() {
      // Extract friend IDs from the response
      friendIds = friendsData.docs.map((doc) => doc["receiver_id"]).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hi, $logged_username"),
        backgroundColor: Colors.deepPurple[400],
        foregroundColor: Colors.white,
        elevation: 20,
      ),
      backgroundColor: Color.fromARGB(255, 177, 162, 205),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("Users").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: Text('No users found.'));
          }

          List<DocumentSnapshot> users = snapshot.data!.docs;
          List<DocumentSnapshot> friends = [];

          // Filter users to show only friends
          for (var user in users) {
            if (friendIds.contains(user["uid"]) && user["uid"] != widget.myId) {
              friends.add(user);
            }
          }

          if (friends.isEmpty) {
            return Center(child: Text("You have no friends yet."));
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              var user = friends[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user["profilepic"]),
                ),
                title: Text(user["name"]),
                subtitle: Text(user["email"]),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        friendId: user["uid"],
                        friendName: user["name"],
                        myId: widget.myId,
                        myName: widget.myName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
