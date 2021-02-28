import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_shop/Widgets/customTextField.dart';
import 'package:e_shop/DialogBox/errorDialog.dart';
import 'package:e_shop/DialogBox/loadingDialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../Config/config.dart';
import '../DialogBox/errorDialog.dart';
import '../DialogBox/errorDialog.dart';
import '../DialogBox/loadingDialog.dart';
import '../Store/storehome.dart';
import 'package:e_shop/Config/config.dart';

import '../Store/storehome.dart';
import '../Widgets/customTextField.dart';



class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}



class _RegisterState extends State<Register>
{

  final TextEditingController _nameTextEditingController = TextEditingController();
  final TextEditingController _emailTextEditingController = TextEditingController();
  final TextEditingController _passwordTextEditingController = TextEditingController();
  final TextEditingController _cpasswordTextEditingController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String userImageUrl = "";
  File _imageFile;
  final picker = ImagePicker();

  _imgFromCamera() async {
    File image = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 50
    );

    setState(() {
      _imageFile = image;
    });
  }

  _imgFromGallery() async {
    File image = await  ImagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 50
    );

    setState(() {
      _imageFile = image;
    });
  }

  void _showPicker(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              child: new Wrap(
                children: <Widget>[
                  new ListTile(
                      leading: new Icon(Icons.photo_library),
                      title: new Text('Photo Library'),
                      onTap: () {
                        _imgFromGallery();
                        Navigator.of(context).pop();
                      }),
                  new ListTile(
                    leading: new Icon(Icons.photo_camera),
                    title: new Text('Camera'),
                    onTap: () {
                      _imgFromCamera();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        }
    );
  }



  @override
  Widget build(BuildContext context) {
    double _screenWidth = MediaQuery.of(context).size.width, _screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
          SizedBox(height: 32.0,),
           Center(
             child: GestureDetector(
               onTap: (){
                 _showPicker(context);
               },
               child: CircleAvatar(
                 radius: 55,
                 backgroundColor: Color(0xffFDCF09),
                 child: _imageFile != null
                 ? ClipRect(
                   child: Image.file(_imageFile,
                   width: 100,
                   height: 100,
                   fit: BoxFit.fitHeight,
                   ),
                 )
                     : Container(
                     decoration: BoxDecoration(
                       color: Colors.grey[200],
                         borderRadius: BorderRadius.circular(50)),
                   width: 100,
                   height: 100,
                     child: Icon(
                       Icons.camera_alt,
                       color: Colors.grey[800],
                     ),
                 ),
                 ),
               ),
             ),
            SizedBox(height: 8.0,),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: _nameTextEditingController,
                    data: Icons.person,
                    hintText: "Name",
                    isObsecure: false,
                  ),
                  CustomTextField(
                    controller: _emailTextEditingController,
                    data: Icons.email,
                    hintText: "Email",
                    isObsecure: false,
                  ),
                  CustomTextField(
                    controller: _passwordTextEditingController,
                    data: Icons.security,
                    hintText: "Password",
                    isObsecure: true,
                  ),
                  CustomTextField(
                    controller: _cpasswordTextEditingController,
                    data: Icons.security,
                    hintText: "Confirm Password",
                    isObsecure: true,
                  ),
                ],
              )
            ),
            RaisedButton(
                onPressed: () {uploadAndSaveImage(); },
                color: Colors.pink,
                child: Text("Sign up", style: TextStyle(color: Colors.white),
                 ),
                ),
                SizedBox(
                  height: 30.0,
                  ),
                 Container(
                   height:  4.0,
                   width: _screenWidth = 0.8,
                   color: Colors.pink,
                 ),
            SizedBox(
              height: 15.0,
            ),
           ],
         ),
      ),
    );
  }


  Future _selectAndPickImage() async
  {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _imageFile = image;
    });
  }



  Future<void> uploadAndSaveImage() async
  {
    if(_imageFile == null) {
      showDialog(
          context: context,
          builder: (c) {
            return ErrorAlertDialog(message: "Please select an image file",);
          }
      );
    }
        else{
          _passwordTextEditingController.text == _cpasswordTextEditingController.text
              ? _emailTextEditingController.text.isNotEmpty &&
              _passwordTextEditingController.text.isNotEmpty &&
              _cpasswordTextEditingController.text.isNotEmpty &&
              _nameTextEditingController.text.isNotEmpty

              ? uploadToStorage()

              : displayDialog("Please fill up the registration complete form..")
              : displayDialog("Password is not matching.");
    }
      }

    displayDialog(String msg){
      showDialog(
        context: context,
        builder: (c){
        return ErrorAlertDialog(message:  msg,);
  }
  );

  }

  uploadToStorage() async {
  showDialog(
      context: context,
      builder: (c){
        return LoadingAlertDialog(message: "Registering.., Please wait....",);
      }
  );

  // ignore: non_constant_identifier_names
  String ImageFileName = DateTime.now().microsecondsSinceEpoch.toString();

  StorageReference storageReference = FirebaseStorage.instance.ref().child(ImageFileName);

  StorageUploadTask storageUploadTask = storageReference.putFile(_imageFile);

  StorageTaskSnapshot taskSnapshot = await storageUploadTask.onComplete;

  await taskSnapshot.ref.getDownloadURL().then((urlImage){
    userImageUrl = urlImage;

    _registerUser();
  });
  }

  FirebaseAuth _auth = FirebaseAuth.instance;
  void _registerUser() async{

    FirebaseUser firebaseUser;

    await _auth.createUserWithEmailAndPassword
      (email: _emailTextEditingController.text.trim(),
        password: _passwordTextEditingController.text.trim(),
    ).then((auth){
      firebaseUser = auth.user;
    }).catchError((error){
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (c){
          return ErrorAlertDialog(message: error.message.toString(),);
        }
    );
    });
    if(firebaseUser != null){
      saveUserInfoToFireStore(firebaseUser).then((value) {
        Navigator.pop(context);
        Route route = MaterialPageRoute(builder: (c) => StoreHome());
        Navigator.pushReplacement(context, route);
      });
    }
  }

  Future saveUserInfoToFireStore(FirebaseUser fUser) async{
    Firestore.instance.collection("users").document(fUser.uid).setData({
      "uid": fUser.uid,
      "email": fUser.email,
      "name" : _nameTextEditingController.text.trim(),
      "url" :userImageUrl,
      EcommerceApp.userCartList: ["garbageValue"],
    });

    await EcommerceApp.sharedPreferences.setString("uid", fUser.uid);
    await EcommerceApp.sharedPreferences.setString(EcommerceApp.userEmail, fUser.email);
    await EcommerceApp.sharedPreferences.setString(EcommerceApp.userName, _nameTextEditingController.text);
    await EcommerceApp.sharedPreferences.setString(EcommerceApp.userAvatarUrl, userImageUrl);
    await EcommerceApp.sharedPreferences.setStringList(EcommerceApp.userCartList, ["garbageValue"]);

  }
}

