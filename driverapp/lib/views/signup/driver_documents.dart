import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DriverDocuments extends StatefulWidget {
  @override
  _DriverDocumentsState createState() => _DriverDocumentsState();
}

class _DriverDocumentsState extends State<DriverDocuments> {
  int currentStep = 0;

  bool complete = false;
  File _idfront, _idback, _dlfront, _dlback, _rcfront, _rcback;

  @override
  Widget build(BuildContext context) {
    Future<File> getImage() async {
      return await ImagePicker.pickImage(source: ImageSource.gallery);
    }

    void _settingModalBottomSheet(context) {
      showModalBottomSheet(
          context: context,
          builder: (BuildContext bc) {
            return Container(
              child: new Wrap(
                children: <Widget>[
                  new ListTile(
                      leading: new Icon(Icons.camera_alt),
                      title: new Text('camera'),
                      onTap: () => {}),
                  new ListTile(
                    leading: new Icon(Icons.photo_library),
                    title: new Text('gallery'),
                    onTap: () => {},
                  ),
                ],
              ),
            );
          });
    }

    _pickImage<File>(File filename) async {
      final imageSource = await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text("Select the image source"),
                actions: <Widget>[
                  MaterialButton(
                    child: Text("Camera"),
                    onPressed: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  MaterialButton(
                    child: Text("Gallery"),
                    onPressed: () =>
                        Navigator.pop(context, ImageSource.gallery),
                  )
                ],
              ));

      if (imageSource != null) {
        return await ImagePicker.pickImage(source: imageSource);
      }
      return filename;
    }

    goTo(int step) {
      setState(() => currentStep = step);
    }

    next() {
      currentStep + 1 != 3
          ? goTo(currentStep + 1)
          : setState(() => complete = true);
    }

    cancel() {
      if (currentStep > 0) {
        goTo(currentStep - 1);
      }
    }

    return new Scaffold(
        appBar: AppBar(
          title: Text('Create an account'),
        ),
        body: Stack(
          children: <Widget>[
            Column(children: <Widget>[
              Expanded(
                child: Stepper(
                  currentStep: currentStep,
                  onStepContinue: next,
                  onStepTapped: (step) => goTo(step),
                  onStepCancel: cancel,
                  steps: [
                    Step(
                      isActive: true,
                      state: StepState.editing,
                      title: const Text('Owner Adhaar or voter ID'),
                      subtitle: const Text(
                          'Upload clear photos of your from both sides'),
                      content: Row(
                        children: <Widget>[
                          Container(
                            color: Colors.blue,
                            height: 100,
                            width: 100,
                            child: Stack(
                              children: <Widget>[
                                _idfront == null
                                    ? Container(
                                        color: Colors.brown,
                                      )
                                    : Image.file(
                                        _idfront,
                                        fit: BoxFit.fitWidth,
                                        height: 100,
                                        width: 100,
                                      ),
                                InkWell(
                                    onTap: () async {
                                      File newimage =
                                          await _pickImage(_idfront);
                                      setState(() {
                                        _idfront = newimage;
                                      });
                                    },
                                    child: Center(
                                        child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(Icons.camera_alt),
                                        Text("front photo"),
                                      ],
                                    ))),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Container(
                            color: Colors.blue,
                            height: 100,
                            width: 100,
                            child: Stack(
                              children: <Widget>[
                                _idback == null
                                    ? Container(
                                        color: Colors.brown,
                                      )
                                    : Image.file(
                                        _idback,
                                        fit: BoxFit.fitWidth,
                                        height: 100,
                                        width: 100,
                                      ),
                                InkWell(
                                    onTap: () async {
                                      File newimage = await _pickImage(_idback);
                                      setState(() {
                                        _idback = newimage;
                                      });
                                    },
                                    child: Center(
                                        child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(Icons.camera_alt),
                                        Text("back photo"),
                                      ],
                                    ))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Step(
                      title: const Text('Driving Licence'),
                      subtitle: const Text(
                          'Upload Photo of your driving licence from both sides'),
                      isActive: true,
                      state: StepState.editing,
                      content: Row(
                        children: <Widget>[
                          Container(
                            color: Colors.blue,
                            height: 100,
                            width: 100,
                            child: Stack(
                              children: <Widget>[
                                _dlfront == null
                                    ? Container(
                                        color: Colors.brown,
                                      )
                                    : Image.file(
                                        _dlfront,
                                        fit: BoxFit.fitWidth,
                                        height: 100,
                                        width: 100,
                                      ),
                                InkWell(
                                    onTap: () async {
                                      File newimage =
                                          await _pickImage(_dlfront);
                                      setState(() {
                                        _dlfront = newimage;
                                      });
                                    },
                                    child: Center(child: Text("Front photo"))),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Container(
                            color: Colors.blue,
                            height: 100,
                            width: 100,
                            child: Stack(
                              children: <Widget>[
                                _dlback == null
                                    ? Container(
                                        color: Colors.brown,
                                      )
                                    : Image.file(
                                        _dlback,
                                        fit: BoxFit.fitWidth,
                                        height: 100,
                                        width: 100,
                                      ),
                                InkWell(
                                    onTap: () async {
                                      File newimage =
                                          await _pickImage(_dlfront);
                                      setState(() {
                                        _dlback = newimage;
                                      });
                                    },
                                    child: Center(child: Text("back photo"))),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Step(
                      isActive: true,
                      state: StepState.editing,
                      title: const Text('RC of Vehicle'),
                      subtitle: const Text(
                          'Upload photos of your RC from both sides'),
                      content: Row(
                        children: <Widget>[
                          Container(
                            color: Colors.blue,
                            height: 100,
                            width: 100,
                            child: Stack(
                              children: <Widget>[
                                _rcfront == null
                                    ? Container(
                                        color: Colors.brown,
                                      )
                                    : Image.file(
                                        _rcfront,
                                        fit: BoxFit.fitWidth,
                                        height: 100,
                                        width: 100,
                                      ),
                                InkWell(
                                    onTap: () async {
                                      File newimage =
                                          await _pickImage(_rcfront);
                                      setState(() {
                                        _rcfront = newimage;
                                      });
                                    },
                                    child: Center(child: Text("Front photo"))),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Container(
                            color: Colors.blue,
                            height: 100,
                            width: 100,
                            child: Stack(
                              children: <Widget>[
                                _rcback == null
                                    ? Container(
                                        color: Colors.brown,
                                      )
                                    : Image.file(
                                        _rcback,
                                        fit: BoxFit.fitWidth,
                                        height: 100,
                                        width: 100,
                                      ),
                                InkWell(
                                    onTap: () async {
                                      File newimage =
                                          await _pickImage(_rcfront);
                                      setState(() {
                                        _rcback = newimage;
                                      });
                                    },
                                    child: Center(child: Text("back photo"))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            Positioned(
              bottom: 30,
              right: MediaQuery.of(context).size.width/2 -100,
              child: Container(
                height: 40,
                width: 200,
                child: MaterialButton(
                    color: Colors.green,
                    child: Text("Upload"),
                    onPressed: () {
                      //upload to Firebase basket
                      
                    }),
              ),
            )
          ],
        ));
  }
}
