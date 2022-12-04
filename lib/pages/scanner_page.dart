import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:document_scanner/document_scanner.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  File? _scannedImage;
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();
  Future<PermissionStatus>? cameraPermissionFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late final TextEditingController _titleController;

  @override
  void initState() {
    _titleController = TextEditingController();
    cameraPermissionFuture = Permission.camera.request();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();
  }

  Widget documentScanner() {
    return FutureBuilder<PermissionStatus>(
      future: cameraPermissionFuture,
      builder:
          (BuildContext context, AsyncSnapshot<PermissionStatus> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          if (snapshot.data!.isGranted) {
            return DocumentScanner(
              // documentAnimation: false,
              noGrayScale: true,
              onDocumentScanned: (ScannedImage scannedImage) {
                setState(() {
                  _scannedImage = scannedImage.getScannedDocumentAsFile();
                  // imageLocation = image;
                });
              },
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Please grant camera permission to use this feature",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]!, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      openAppSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                    ),
                    child: const Text("Grant access"),
                  )
                ],
              ),
            );
          }
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Future getImage() async {
    try {
      // call the image picker
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      // if user picks an image set the new state
      if (image != null) {
        setState(() {
          // pick the image name as the title
          _titleController.text = image.name;
          _scannedImage = File(image.path);
        });
      }
    } on PlatformException catch (e) {
      showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text("Allow access to gallery"),
              content: Text(e.message!),
              actions: [
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                CupertinoDialogAction(
                  child: const Text("Allow"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                  },
                ),
              ],
            );
          });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future uploadDocument() async {
    // show loading indicator
    showDialog(
        context: context,
        builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      // upload image to firebase storage
      final String fileName = _titleController.text;
      final Reference ref = _storage.ref().child(fileName);
      final UploadTask uploadTask = ref.putFile(_scannedImage!);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      // upload image url to firestore
      await _firestore.collection("documents").add({
        "title": fileName,
        "url": downloadUrl,
        "created_at": DateTime.now().millisecondsSinceEpoch,
      }).then((_) => {
            // Return to initial screen
            Navigator.of(context).popUntil((route) => route.isFirst),
          });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
          padding: const EdgeInsets.only(top: 45, bottom: 10),
          child: Center(
            child: Column(
              children: [
                Expanded(
                  child: _scannedImage == null
                      ? Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _isScanning
                              ? documentScanner()
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.document_scanner_sharp,
                                      size: 100,
                                      color: Colors.grey,
                                    ),
                                    Text(
                                      'Scan a document or pick one from gallery',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: MediaQuery.of(context).size.height * 0.5,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.file(
                                _scannedImage!,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 20.0, right: 20.0),
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: "Enter document name",
                                ),
                                controller: _titleController,
                              ),
                            )
                          ],
                        ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: _scannedImage != null ? 200 : 150,
                  child: Column(
                    children: [
                      FloatingActionButton.extended(
                        heroTag: 'scan',
                        onPressed: () {
                          setState(() {
                            _scannedImage = null;
                            _isScanning = !_isScanning;
                          });
                        },
                        label: Text(_isScanning
                            ? 'Cancel scanning'
                            : 'Scan new document'),
                        icon: _isScanning
                            ? const Icon(Icons.cancel_rounded)
                            : const Icon(Icons.camera_alt),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.grey[800],
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton.extended(
                        heroTag: 'gallery',
                        onPressed: () async {
                          await getImage();
                        },
                        label: const Text('Pick from gallery'),
                        icon: const Icon(Icons.image),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.grey[800],
                      ),
                      const SizedBox(height: 10),
                      _scannedImage != null && _titleController.text.isNotEmpty
                          ? FloatingActionButton.extended(
                              heroTag: 'save',
                              onPressed: () {
                                uploadDocument();
                              },
                              label: const Text('Confirm document'),
                              icon: const Icon(Icons.check),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.green[800],
                            )
                          : Container(),
                    ],
                  ),
                )
              ],
            ),
          )),
    );

    // return Scaffold(
    //     body: FutureBuilder<PermissionStatus>(
    //   future: cameraPermissionFuture,
    //   builder:
    //       (BuildContext context, AsyncSnapshot<PermissionStatus> snapshot) {
    //     if (snapshot.connectionState == ConnectionState.done &&
    //         snapshot.hasData) {
    //       if (snapshot.data!.isGranted) {
    //         return Stack(
    //           children: <Widget>[
    //             Column(
    //               children: <Widget>[
    //                 Expanded(
    //                   child: _scannedImage != null
    //                       ? Padding(
    //                           padding: const EdgeInsets.all(24.0),
    //                           child: ClipRRect(
    //                               borderRadius: BorderRadius.circular(40),
    //                               child: Image.file(
    //                                 _scannedImage!,
    //                                 fit: BoxFit.contain,
    //                               )),
    //                         )
    //                       : Column(
    //                           children: [
    //                             Expanded(
    //                                 child: Container(
    //                               decoration: BoxDecoration(
    //                                 border: Border.all(
    //                                   color: Colors.black,
    //                                   width: 2,
    //                                 ),
    //                               ),
    //                               child: documentScanner(),
    //                             )),
    //                             Padding(
    //                               padding: const EdgeInsets.only(bottom: 8.0),
    //                               child: SizedBox(
    //                                 height: 100,
    //                                 child: Center(
    //                                   child: FloatingActionButton.extended(
    //                                     onPressed: () async {
    //                                       await getImage();
    //                                     },
    //                                     label: const Text('Pick from gallery'),
    //                                     icon: const Icon(Icons.image),
    //                                     backgroundColor: Colors.grey[700],
    //                                   ),
    //                                 ),
    //                               ),
    //                             ),
    //                           ],
    //                         ),
    //                 ),
    //               ],
    //             ),
    //             _scannedImage != null
    //                 ? Positioned(
    //                     bottom: 40,
    //                     left: 0,
    //                     right: 0,
    //                     child: Column(
    //                       children: [
    //                         ElevatedButton.icon(
    //                             style: ElevatedButton.styleFrom(
    //                               backgroundColor: Colors.grey[700],
    //                             ),
    //                             label: const Text("Take another picture"),
    //                             icon: const Icon(Icons.camera_alt),
    //                             onPressed: () {
    //                               setState(() {
    //                                 _scannedImage = null;
    //                               });
    //                             }),
    //                         ElevatedButton.icon(
    //                             style: ElevatedButton.styleFrom(
    //                               backgroundColor: Colors.grey[700],
    //                             ),
    //                             label: const Text("Get picture from gallery"),
    //                             icon: const Icon(Icons.image),
    //                             onPressed: () async {
    //                               await getImage();
    //                             }),
    //                       ],
    //                     ),
    //                   )
    //                 : Container(),
    //           ],
    //         );
    //       } else {
    //         return Center(
    //           child: Column(
    //             mainAxisAlignment: MainAxisAlignment.center,
    //             children: [
    //               const Text(
    //                   "Please grant camera permission to use this feature"),
    //               ElevatedButton(
    //                   onPressed: () {
    //                     setState(() {
    //                       cameraPermissionFuture = Permission.camera.request();
    //                     });
    //                   },
    //                   child: const Text("Grant access"))
    //             ],
    //           ),
    //         );
    //       }
    //     } else {
    //       return const Center(
    //         child: CircularProgressIndicator(),
    //       );
    //     }
    //   },
    // ));
  }
}
