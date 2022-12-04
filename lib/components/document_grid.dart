import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scanner_test/models/document.dart';

class DocumentGrid extends StatefulWidget {
  const DocumentGrid(
      {super.key, required this.documentList, required this.refresh});

  final List<Document> documentList;
  final Function refresh;

  @override
  State<DocumentGrid> createState() => _DocumentGridState();
}

class _DocumentGridState extends State<DocumentGrid> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: widget.documentList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        if (index == 2) {
          // Return separator with date
        }
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
          child: Card(
            key: ValueKey(widget.documentList[index].id),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  widget.documentList[index].image,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  width: double.infinity,
                  alignment: Alignment.center,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  child: Text(
                    widget.documentList[index].title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
