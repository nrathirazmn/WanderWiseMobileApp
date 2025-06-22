import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_post_screen.dart';
import 'post_details_screen.dart';
import 'user_guide_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _username;
  String? _photoUrl;
  String? _age;
  String? _nationality;
  String? _contact;
  String? _social;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();

    if (data != null && mounted) {
      setState(() {
        _username = data['name'];
        _age = data['age']?.toString();
        _nationality = data['nationality'];
        _contact = data['contact'];
        _social = data['social'];
        _photoUrl = data.containsKey('photoUrl') ? data['photoUrl'] : null;
      });
    }
  }

  void _showDestinationPopup(BuildContext context) {
    final controller = TextEditingController();
    final List<String> customOptions = [];
    final List<String> defaultOptions = [
      "Malaysia", "India", "China", "Japan", "South Korea",
      "Thailand", "Vietnam", "Indonesia", "Philippines", "Singapore",
      "United States", "Canada", "Mexico", "Brazil", "Argentina",
      "United Kingdom", "France", "Germany", "Italy", "Spain",
      "Australia", "New Zealand", "Russia", "South Africa", "Egypt",
      "Turkey", "Saudi Arabia", "United Arab Emirates", "Pakistan", "Bangladesh"
    ];
    String? chosen;
    bool useCustom = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('🎯 Not Sure on Your Next Destination?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (chosen == null) ...[
                    Text("Here’s a surprise suggestion for you!"),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        final pick = (defaultOptions.toList()..shuffle()).first;
                        setState(() => chosen = pick);
                      },
                      child: Text("Decide for Me"),
                    ),
                    TextButton(
                      onPressed: () => setState(() => useCustom = true),
                      child: Text("Choose from My List"),
                    ),
                  ],
                  if (useCustom && chosen == null) ...[
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(hintText: 'Add a destination'),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          setState(() {
                            customOptions.add(value.trim());
                            controller.clear();
                          });
                        }
                      },
                    ),
                    Wrap(
                      spacing: 6,
                      children: customOptions
                          .map((e) => Chip(
                                label: Text(e),
                                onDeleted: () => setState(() => customOptions.remove(e)),
                              ))
                          .toList(),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: customOptions.length < 2
                          ? null
                          : () {
                              final pick = (customOptions.toList()..shuffle()).first;
                              setState(() => chosen = pick);
                            },
                      child: Text("Spin from My List"),
                    ),
                  ],
                  if (chosen != null) ...[
                    SizedBox(height: 12),
                    Text('🎉 You should visit:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(chosen!, style: TextStyle(fontSize: 18, color: const Color.fromARGB(255, 86, 35, 1))),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/main', arguments: 2); // Navigate to Itinerary tab
                      },
                      child: Text('Start Planning Now'),
                    ),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuideSection(String title, List<DocumentSnapshot> posts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserGuidesScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final data = posts[index].data() as Map<String, dynamic>;
              return _buildPostCard(data, posts[index].id);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> data, String postId) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final hasLiked = data['likes']?.contains(uid) ?? false;
    final hasSaved = data['saves']?.contains(uid) ?? false;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailsScreen(postId: postId),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[200],
          image: data['imageUrl'] != null && data['imageUrl'].toString().startsWith('http')
              ? DecorationImage(
                  image: NetworkImage(data['imageUrl']), fit: BoxFit.cover)
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(data['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('By ${data['author'] ?? data['authorName'] ?? 'Unknown'}', style: const TextStyle(color: Colors.white)),
                    Row(
                      // children: [
                      //   IconButton(
                      //     icon: Icon(
                      //       hasLiked ? Icons.favorite : Icons.favorite_border,
                      //       color: Colors.white,
                      //       size: 20,
                      //     ),
                      //     onPressed: () => _toggleAction(postId, 'likes', hasLiked),
                      //   ),
                      //   IconButton(
                      //     icon: Icon(
                      //       hasSaved ? Icons.bookmark : Icons.bookmark_border,
                      //       color: Colors.white,
                      //       size: 20,
                      //     ),
                      //     onPressed: () => _toggleAction(postId, 'saves', hasSaved),
                      //   ),
                      // ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAction(String postId, String field, bool currentlyHas) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final postRef = FirebaseFirestore.instance.collection('forum_posts').doc(postId);
    await postRef.update({
      field: currentlyHas
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid])
    });
  }

  Widget _buildAIChatBanner() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/chat', arguments: {
          'isAI': true,
          'peerName': 'AI Travel Assistant',
        }),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 86, 35, 1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color.fromARGB(255, 252, 252, 252)),
          ),
          child: Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Travel Assistant', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Ask anything about your trip!', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

//Upgrading UI - 06/06/2025 - 12:43am
  // Widget _buildUserCard() {
  //   return Column(
  //     children: [
  //       Container(
  //         margin: const EdgeInsets.all(16),
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: Colors.brown[100],
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: Row(
  //           children: [
  //             CircleAvatar(
  //               backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
  //               radius: 35,
  //             ),
  //             const SizedBox(width: 16),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(_username ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //                   Text("Age: $_age y/o"),
  //                   Text("Nationality: $_nationality"),
  //                   Text("Contact: $_contact"),
  //                   Text("Socials: $_social"),
  //                 ],
  //               ),
  //             )
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildDestinationSpinBanner() {
  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: GestureDetector(
  //       onTap: () => _showDestinationPopup(context),
  //       child: Container(
  //         padding: EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: const Color.fromARGB(255, 86, 35, 1),
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(color: Colors.white),
  //         ),
  //         child: Row(
  //           children: [
  //             Icon(Icons.casino, color: Colors.white),
  //             SizedBox(width: 12),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text('Not Sure on Your Next Destination?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
  //                   Text('Let WanderWise choose it for you or choose from your own list!', style: TextStyle(color: Colors.white70, fontSize: 12)),
  //                 ],
  //               ),
  //             ),
  //             Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( 
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/WWlogo.png', height: 32),
            const SizedBox(width: 10),
            const Text(
              'WanderWise',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          // StreamBuilder<QuerySnapshot>(
          //   stream: FirebaseFirestore.instance
          //       .collection('chats')
          //       .where('participants', arrayContains: FirebaseAuth.instance.currentUser?.uid)
          //       .snapshots(),
          //   builder: (context, snapshot) {
          //     bool hasUnread = false;

          //     if (snapshot.hasData) {
          //       for (var doc in snapshot.data!.docs) {
          //         final data = doc.data() as Map<String, dynamic>;
          //         final lastSender = data['lastMessageSender'];
          //         final readBy = List<String>.from(data['readBy'] ?? []);
          //         final currentUid = FirebaseAuth.instance.currentUser?.uid;

          //         if (lastSender != currentUid && !readBy.contains(currentUid)) {
          //           hasUnread = true;
          //           break;
          //         }
          //       }
          //     }

          //     return Stack(
          //       children: [
                  IconButton(
                    icon: const Icon(Icons.message, color: Colors.black),
                    onPressed: () {
                      Navigator.pushNamed(context, '/messages');
                    },
                  ),
      //             if (hasUnread)
      //               Positioned(
      //                 right: 10,
      //                 top: 10,
      //                 child: Container(
      //                   width: 9,
      //                   height: 9,
      //                   decoration: BoxDecoration(
      //                     color: Colors.red,
      //                     shape: BoxShape.circle,
      //                   ),
      //                 ),
      //               ),
      //           ],
      //         );
      //       },
      //     ),
         ],
       ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.push(context, MaterialPageRoute(builder: (_) => CreatePostScreen()));
      //   },
      //   child: const Icon(Icons.add),
      // ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('forum_posts').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final posts = snapshot.data!.docs;
          final guides = posts.where((d) =>
            (d.data() as Map<String, dynamic>)['isDraft'] == false &&
            ['guide', 'explore'].contains((d.data() as Map<String, dynamic>)['category'])
          ).toList();

      Widget _buildHeroBanner() {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.orange.shade200, Colors.pink.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("🌴 Ready for your next adventure?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 8),
              Text("Let WanderWise guide your journey.",
                style: TextStyle(color: Colors.grey[800])),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showDestinationPopup(context),
                icon: Icon(Icons.explore, color: Colors.white,),
                label: Text("Inspire Me", style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade700),
              )
            ],
          ),
        );
      }

        Widget _buildDailyQuote() {
          final quotes = [
            "“Life is short and the world is wide.” 🌎",
            "“Adventure is out there!” 🧭",
            "“Pack light, travel far.” ✈️",
            "“The journey is the reward.” 🚶"
          ];
          final quote = quotes[DateTime.now().day % quotes.length];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              quote,
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          );
        }

        Widget _buildQuickActions(BuildContext context) {
  final actions = [
    {
      'icon': Icons.menu_book_rounded,
      'title': 'User Guides',
      'subtitle': 'Explore guides & experiences',
      'color': Colors.blue.shade100,
      'onTap': () => Navigator.pushNamed(context, '/user-guide-page'),
    },
    {
      'icon': Icons.favorite,
      'title': 'Travel Buddy',
      'subtitle': 'Find & match with others',
      'color': Colors.yellow.shade100,
      'onTap': () => Navigator.pushNamed(context, '/travel-buddy'),
    },
    {
      'icon': Icons.add_box_rounded,
      'title': 'Create Guide',
      'subtitle': 'Share your own journey',
      'color': Colors.purple.shade100,
      'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreatePostScreen()),
          ),
    },
    {
      'icon': Icons.bar_chart,
      'title': 'Expenses Report',
      'subtitle': 'View your spending insights',
      'color': Colors.orange.shade100,
      'onTap': () => Navigator.pushNamed(context, '/expenses-report'),
    },
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          children: actions.map((item) {
            return GestureDetector(
              onTap: item['onTap'] as VoidCallback,
              child: Container(
                decoration: BoxDecoration(
                  color: item['color'] as Color,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item['icon'] as IconData, size: 28, color: Colors.brown[700]),
                    const SizedBox(height: 12),
                    Text(
                      item['title'] as String,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['subtitle'] as String,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

          return ListView(
            children: [
              _buildHeroBanner(),
              _buildAIChatBanner(),
              // _buildUserCard(),
              // _buildDestinationSpinBanner(),
              _buildDailyQuote(),
              // _buildGuideSection("📒 User Guide and Experience", guides),
              _buildQuickActions(context),

            ],
          );
        },
      ),
    );
  }
}