import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/user.dart' as model;
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../resources/firestore_methods.dart';
import '../utils/colors.dart';
import '../utils/utils.dart';
import '../widgets/follow_button.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var userData = {};
  int postsLen = 0;
  int followers = 0;
  int following = 0;
  bool isLoading = false;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      // get post lENGTH
      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      postsLen = postSnap.docs.length;
      userData = userSnap.data()!;
      followers = userSnap.data()!['followers'].length;
      following = userSnap.data()!['following'].length;
      isFollowing = userSnap
          .data()!['followers']
          .contains(FirebaseAuth.instance.currentUser!.uid);
      setState(() {});
    } catch (e) {
      showSnackBar(
        context,
        e.toString(),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final model.User user = Provider.of<UserProvider>(context).getUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: Text(
          user.username,
        ),
        centerTitle: false,
      ),
      body: ListView(
        children: <Widget>[
          // Profile Picture, Stats column, Follow, Unfollow Button, username and bio
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 40.0,
                      backgroundColor: Colors.grey,
                      backgroundImage: NetworkImage(user.photoUrl),
                    ),
                    // stats
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              buildStatColumn(postsLen, "posts"),
                              buildStatColumn(followers, "followers"),
                              buildStatColumn(following, "following"),
                            ],
                          ),
                          // buttons -> edit profile, follow, unfollow
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                user.uid == widget.uid
                                    ? FollowButton(
                                        text: "Edit Profile",
                                        backgroundColor: mobileBackgroundColor,
                                        textColor: primaryColor,
                                        borderColor: Colors.grey,
                                        function: () {},
                                      )
                                    : isFollowing
                                        ? FollowButton(
                                            text: "Unfollow",
                                            backgroundColor: Colors.white,
                                            textColor: Colors.black,
                                            borderColor: Colors.grey,
                                            function: () async {
                                              await FireStoreMethods()
                                                  .followUser(
                                                FirebaseAuth
                                                    .instance.currentUser!.uid,
                                                userData['uid'],
                                              );

                                              setState(() {
                                                isFollowing = false;
                                                followers--;
                                              });
                                            },
                                          )
                                        : FollowButton(
                                            text: "Follow",
                                            backgroundColor: Colors.blue,
                                            textColor: Colors.white,
                                            borderColor: Colors.blue,
                                            function: () async {
                                              await FireStoreMethods()
                                                  .followUser(
                                                FirebaseAuth
                                                    .instance.currentUser!.uid,
                                                userData['uid'],
                                              );

                                              setState(() {
                                                isFollowing = true;
                                                followers++;
                                              });
                                            },
                                          )
                              ]),
                        ],
                      ),
                    )
                  ],
                ),
                // usernmae and description
                Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(
                      user.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(top: 1.0),
                  child: Text(user.bio),
                ),
              ],
            ),
          ),
          const Divider(),
          // displaying user posts
          FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('posts')
                .where('uid', isEqualTo: user.uid)
                .get(),
            builder: (BuildContext coontext, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: (snapshot.data! as dynamic).docs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 1.5,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (BuildContext context, int index) {
                  DocumentSnapshot video =
                      (snapshot.data! as dynamic).docs[index];
                  return Container(
                    child: Image(
                      image: NetworkImage(
                        (video.data()! as dynamic)["postUrl"],
                      ),
                      fit: BoxFit.cover,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

Column buildStatColumn(int num, String label) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        num.toString(),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      Container(
        margin: const EdgeInsets.only(top: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
        ),
      ),
    ],
  );
}
