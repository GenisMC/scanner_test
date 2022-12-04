import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scanner_test/components/document_grid.dart';
import 'package:scanner_test/components/document_list.dart';
import 'package:scanner_test/models/document.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final TextEditingController _searchController;
  // grid or list mode
  bool gridMode = true;

  Future _getDocuments() async {
    final QuerySnapshot snapshot =
        await _firestore.collection('documents').get();
    return snapshot.docs;
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getDocuments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            List<Document> documents = <Document>[];
            // turn snapshot into list of documents
            snapshot.data.forEach((doc) {
              DateTime date = DateTime.parse(
                  Timestamp.fromMillisecondsSinceEpoch(doc.data()['created_at'])
                      .toDate()
                      .toString());
              documents.add(Document(
                id: doc.id,
                title: doc.data()['title'],
                image: doc.data()['url'],
                createdAt: date,
              ));
            });
            return Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    // goto scan page
                    Navigator.pushNamed(context, '/scanner');
                  },
                  backgroundColor: Colors.amber[800],
                  child: const Icon(
                    Icons.document_scanner,
                    size: 30,
                  ),
                ),
                body: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 50, 12, 0),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            const Icon(Icons.search),
                            const SizedBox(width: 10),
                            // search bar TODO: add search functionality
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) {},
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Search',
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                                onTap: () => setState(() {}),
                                child: const Icon(Icons.refresh)),
                            const SizedBox(width: 10),
                            Tooltip(
                              message:
                                  'Switch to ${gridMode ? 'grid' : 'list'} view',
                              child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      gridMode = !gridMode;
                                    });
                                  },
                                  child: Icon(
                                      gridMode ? Icons.grid_view : Icons.list)),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ),
                      Expanded(
                        child: gridMode
                            ? DocumentGrid(
                                documentList: documents,
                                refresh: () {
                                  setState(() {});
                                })
                            : DocumentList(
                                documentList: documents,
                                refresh: () {
                                  setState(() {});
                                }),
                      ),
                    ],
                  ),
                ));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }
}
