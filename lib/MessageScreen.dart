import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:my_project1/FriendListScreen.dart';
import 'ChatScreen.dart';
import 'dashboardscreen.dart';

class MessgaeScreenPage extends StatefulWidget {
  final User? user;

  MessgaeScreenPage({required this.user});

  @override
  State<MessgaeScreenPage> createState() => _MessgaeScreenPageScreenState();
}

class _MessgaeScreenPageScreenState extends State<MessgaeScreenPage> {
  String? loggedUsername;
  String? loggedId;

  @override
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
      loggedUsername = document["name"];
      loggedId = document["uid"];
    });
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
        title: Text('Hi, $loggedUsername'),
        backgroundColor: Colors.deepPurple[400],
        foregroundColor: Colors.white,
        elevation: 20,
      ),
      backgroundColor: Color.fromARGB(255, 177, 162, 205),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: widget.user!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No chats found'));
          }

          List<DocumentSnapshot> chats = snapshot.data!.docs;
          Map<String, Map<String, dynamic>> latestChats = {};

          // Group and find the latest chat for each user
          for (var chat in chats) {
            var data = chat.data() as Map<String, dynamic>;
            String friendId = data['senderId'] == widget.user!.uid
                ? data['receiverId']
                : data['senderId'];

            if (!latestChats.containsKey(friendId) ||
                (data['timestamp'] as Timestamp)
                    .toDate()
                    .isAfter((latestChats[friendId]!['timestamp'] as Timestamp)
                        .toDate())) {
              latestChats[friendId] = data;
            }
          }

          List<Map<String, dynamic>> sortedChats =
              latestChats.values.toList();
          sortedChats.sort((a, b) => (b['timestamp'] as Timestamp)
              .compareTo(a['timestamp'] as Timestamp));

          return ListView.builder(
            itemCount: sortedChats.length,
            itemBuilder: (context, index) {
              var chat = sortedChats[index];
              String friendId = chat['senderId'] == widget.user!.uid
                  ? chat['receiverId']
                  : chat['senderId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(friendId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!userSnapshot.hasData || userSnapshot.data == null) {
                    return SizedBox();
                  }

                  var userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  String latestMessage = chat['message'];
                  Timestamp timestamp = chat['timestamp'];
                  String time = DateFormat('h:mm a')
                      .format(timestamp.toDate());

                  return Card(
                    margin: EdgeInsets.all(5),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              friendId: friendId,
                              friendName: userData["name"],
                              myId: widget.user!.uid,
                              myName: loggedUsername!,
                            ),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(userData["profilepic"]),
                      ),
                      title: Text(userData["name"]),
                      subtitle: Text(
                        latestMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(time),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
            floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FriendListScreen(
                myId: widget.user!.uid,
                myName: loggedUsername!,
              ),
            ),
          );
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.deepPurple[400],
      ),

    );
  }
}
