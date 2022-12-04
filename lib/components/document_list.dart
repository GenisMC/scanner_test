import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scanner_test/models/document.dart';

class DocumentList extends StatefulWidget {
  const DocumentList(
      {super.key, required this.documentList, required this.refresh});

  final List<Document> documentList;
  final Function refresh;

  @override
  State<DocumentList> createState() => _DocumentListState();
}

class _DocumentListState extends State<DocumentList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: widget.documentList.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return SizedBox(
              key: const ValueKey('header'),
              height: 20,
              child: Padding(
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: Row(children: const [
                  Expanded(
                    child: Text(
                      "Title",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Created",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ]),
              ),
            );
          }
          index -= 1;
          return GestureDetector(
            onLongPress: () {
              showCupertinoDialog(
                  context: context,
                  builder: ((context) {
                    return CupertinoAlertDialog(
                      title: const Text('Delete document?'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: const Text('Delete'),
                          onPressed: () {
                            _firestore
                                .collection('documents')
                                .doc(widget.documentList[index].id)
                                .delete()
                                .then((value) => widget.refresh());
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  }));
            },
            child: SizedBox(
              key: ValueKey(widget.documentList[index].id),
              height: 50,
              child: Card(
                color: index % 2 == 0 ? Colors.grey[100] : Colors.grey[50],
                child: Row(children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        widget.documentList[index].title,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Container(width: 1, color: Colors.grey[400]),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        widget.documentList[index].createdAt.toString(),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          );
        });
  }
}
