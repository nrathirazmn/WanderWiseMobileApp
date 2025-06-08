//Unnecessary page - Delete - Not UX Friendly
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'daily_itinerary_screen.dart';

// class TripDetailsScreen extends StatefulWidget {
//   final String tripId;

//   const TripDetailsScreen({required this.tripId, Key? key}) : super(key: key);

//   @override
//   State<TripDetailsScreen> createState() => _TripDetailsScreenState();
// }

// class _TripDetailsScreenState extends State<TripDetailsScreen> {
//   bool isEditing = false;
//   final TextEditingController _nameController = TextEditingController();
//   DateTime? startDate;
//   DateTime? endDate;

//   Future<void> _pickDate(BuildContext context, bool isStart) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: (isStart ? startDate : endDate) ?? DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isStart) startDate = picked;
//         else endDate = picked;
//       });
//     }
//   }

//   Future<void> _saveChanges(String uid) async {
//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .collection('trips')
//         .doc(widget.tripId)
//         .update({
//       'destination': _nameController.text.trim(),
//       'startDate': startDate,
//       'endDate': endDate,
//     });
//     setState(() => isEditing = false);
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Trip updated!')),
//     );
//   }

//   Future<void> _deleteTrip(String uid) async {
//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .collection('trips')
//         .doc(widget.tripId)
//         .delete();
//     Navigator.pop(context);
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Trip deleted.')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null || widget.tripId.trim().isEmpty) {
//       return const Scaffold(body: Center(child: Text("Invalid trip ID or user not logged in.")));
//     }

//     final tripRef = FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .collection('trips')
//         .doc(widget.tripId);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Trip Details"),
//         actions: [
//           IconButton(
//             icon: Icon(isEditing ? Icons.save : Icons.edit),
//             onPressed: () {
//               if (isEditing) {
//                 _saveChanges(uid);
//               } else {
//                 setState(() => isEditing = true);
//               }
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.delete),
//             onPressed: () => _deleteTrip(uid),
//           ),
//         ],
//       ),
//       body: FutureBuilder<DocumentSnapshot>(
//         future: tripRef.get(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
//           if (!snapshot.data!.exists) return const Center(child: Text("Trip not found."));

//           final data = snapshot.data!.data() as Map<String, dynamic>;
//           _nameController.text = data['destination'] ?? '';
//           startDate ??= (data['startDate'] as Timestamp?)?.toDate();
//           endDate ??= (data['endDate'] as Timestamp?)?.toDate();
//           final guides = List<String>.from(data['embeddedGuides'] ?? []);

//           return Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 isEditing
//                     ? TextField(
//                         controller: _nameController,
//                         decoration: const InputDecoration(labelText: 'Trip Name'),
//                       )
//                     : Text(_nameController.text,
//                         style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     isEditing
//                         ? TextButton(
//                             onPressed: () => _pickDate(context, true),
//                             child: Text(startDate != null
//                                 ? DateFormat.yMMMd().format(startDate!)
//                                 : 'Start Date'),
//                           )
//                         : Text('Start: ${startDate != null ? DateFormat.yMMMd().format(startDate!) : '?'}'),
//                     const SizedBox(width: 16),
//                     isEditing
//                         ? TextButton(
//                             onPressed: () => _pickDate(context, false),
//                             child: Text(endDate != null
//                                 ? DateFormat.yMMMd().format(endDate!)
//                                 : 'End Date'),
//                           )
//                         : Text('End: ${endDate != null ? DateFormat.yMMMd().format(endDate!) : '?'}'),
//                   ],
//                 ),
//                 const Divider(height: 32),
//                 const Text('Embedded Guides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 10),
//                 if (guides.isEmpty)
//                   const Text('No guides added yet.')
//                 else
//                   SizedBox(
//                     height: 150,
//                     child: ListView.separated(
//                       itemCount: guides.length,
//                       separatorBuilder: (_, __) => const SizedBox(height: 10),
//                       itemBuilder: (context, index) {
//                         final url = guides[index];
//                         return ListTile(
//                           leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
//                           title: Text('Guide ${index + 1}'),
//                           trailing: IconButton(
//                             icon: const Icon(Icons.download),
//                             onPressed: () async {
//                               final uri = Uri.parse(url);
//                               if (await canLaunchUrl(uri)) {
//                                 await launchUrl(uri, mode: LaunchMode.externalApplication);
//                               } else {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(content: Text('Could not launch guide.')),
//                                 );
//                               }
//                             },
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 const Spacer(),
//                 if (startDate != null && endDate != null)
//                   Center(
//                     child: ElevatedButton.icon(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => DailyItineraryScreen(
//                               tripId: widget.tripId,
//                               tripTitle: _nameController.text,
//                               startDate: startDate!,
//                               endDate: endDate!,
//                             ),
//                           ),
//                         );
//                       },
//                       icon: const Icon(Icons.calendar_today),
//                       label: const Text("Open Daily Itinerary"),
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
