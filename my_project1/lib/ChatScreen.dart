import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String myId;
  final String myName;

  ChatScreen({
    required this.friendId,
    required this.friendName,
    required this.myId,
    required this.myName
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  List<Map<String, dynamic>> _messages = [];

  void _sendMessage() async {
    if (_controller.text.isEmpty || _isSending) return;

    String message = _controller.text;
    _controller.clear();

    // Optimistic UI Update: Add message locally
    setState(() {
      _isSending = true;
      _messages.insert(0, {
        'message': message,
        'senderId': widget.myId,
        'timestamp': null, // Placeholder timestamp
      });
      _scrollToBottom();
    });

    try {
      await _firestore.collection('chats').add({
        'senderId': widget.myId,
        'receiverId': widget.friendId,
        'participants': [widget.myId, widget.friendId],
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Handle error (e.g., show a snack bar or retry)
      print("Error sending message: $e");
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
  String formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(Duration(days: 1));

    if (date.isAfter(today)) {
      return 'Today';
    } else if (date.isAfter(yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.friendName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .where('participants', arrayContains: widget.myId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print('Error: ${snapshot.error}');
                  return Center(child: Text('Error loading messages'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print('No data available');
                  return Center(child: Text('No messages available'));
                }

                List<DocumentSnapshot> docs = snapshot.data!.docs;

                _messages = docs
                    .where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return (data['senderId'] == widget.myId && data['receiverId'] == widget.friendId) ||
                             (data['receiverId'] == widget.myId && data['senderId'] == widget.friendId);
                    })
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList();

                print('Retrieved ${docs.length} documents after filtering');

                if (_messages.isEmpty) {
                  return Center(child: Text('No messages to display.'));
                }

                String previousDate = '';
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    var messageData = _messages[index];
                    bool isMe = messageData['senderId'] == widget.myId;

                    // Format the message date
                    String messageDate = messageData['timestamp'] != null
                        ? formatDate(messageData['timestamp'])
                        : '';

                    bool showDate = messageDate != previousDate;
                    previousDate = messageDate;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Center(
                              child: Text(
                                messageDate,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.all(10.0),
                            margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[100] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  messageData['message'],
                                  style: TextStyle(fontSize: 16.0, color: Colors.black),
                                ),
                                SizedBox(height: 5.0),
                                if (messageData['timestamp'] != null)
                                  Text(
                                    DateFormat('h:mm a').format(
                                      (messageData['timestamp'] as Timestamp).toDate()
                                    ),
                                    style: TextStyle(fontSize: 12.0, color: Colors.black54),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Enter your message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? CircularProgressIndicator()
                      : Icon(Icons.send, color: Theme.of(context).primaryColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }  
}
