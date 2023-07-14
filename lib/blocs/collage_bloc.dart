import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_collage_widget/model/images.dart';
import 'package:image_collage_widget/utils/collage_type.dart';
import 'package:image_collage_widget/utils/permission_type.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/permissions.dart';
import 'collage_event.dart';
import 'collage_state.dart';

class CollageBloc extends Bloc<CollageEvent, CollageState> {
  String path;
  final CollageType collageType;
  final BuildContext context;

  CollageBloc(
      {required this.context, required this.collageType, required this.path})
      : super(InitialState()) {
    on<CheckPermissionEvent>(
      (event, emit) => checkPermission(
        event.isFromPicker,
        event.permissionType,
        event.index,
        event.colors,
        event.collageType,
      ),
    );
    on<AllowPermissionEvent>((event, emit) async {
      if (event.isFromPicker) {
        await openPicker(
          event.permissionType,
          event.index,
          event.colors,
          event.collageType,
        );
      } else {
        emit(LoadImageState());
        loadImages(path, getImageCount());
      }
    });
    on<AskPermissionEvent>(
      (event, emit) => askPermission(
        event.isFromPicker,
        event.permissionType,
        event.index,
        event.colors,
        event.collageType,
      ),
    );

    on<DenyPermissionEvent>(
      (event, emit) {
        showSnackBar();
        if (!event.isFromPicker) {
          emit(PermissionDeniedState());
        }
      },
    );

    on<ImageListEvent>(
      (event, emit) {
        emit(LoadImageState());
        emit(ImageListState(images: event.imageList));
      },
    );
  }

  ///Checking permission
  checkPermission(
    bool isFromPicker,
    PermissionType permissionType,
    int index,
    Color colors,
    CollageType collageType,
  ) async {
    PermissionStatus permissionStatus = PermissionStatus.denied;

    askForPermission(
      permissionStatus,
      isFromPicker,
      permissionType,
      index,
      colors,
      collageType,
    );
  }

  ///Ask permission events
  askForPermission(
    PermissionStatus permissionStatus,
    bool isFromPicker,
    PermissionType permissionType,
    int index,
    Color colors,
    CollageType collageType,
  ) async {
    try {
      if (await Permissions.cameraAndStoragePermissionsGranted()) {
        add(
          AllowPermissionEvent(
            isFromPicker,
            permissionType,
            index,
            colors,
            collageType,
          ),
        );
      } else {
        add(
          AskPermissionEvent(
            isFromPicker,
            permissionType,
            index,
            colors,
            collageType,
          ),
        );
      }
    } catch (e) {
      debugPrint('Camera Exception ::: $e');
    }
  }

  ///Open picker dialog for photo selection
  Future<void> openPicker(
    PermissionType permissionType,
    int index,
    Color colors,
    CollageType collageType,
  ) async {
    PickedFile? image = await ImagePicker.platform.pickImage(
      source: permissionType == PermissionType.storage
          ? ImageSource.gallery
          : ImageSource.camera,
    );

    if (image != null) {
      final imageList = (state as ImageListState).images;

      final croppedFile = await cropImage(
        image.path,
        colors,
        collageType,
      );
      if (croppedFile != null) {
        imageList[index].imageUrl = File(croppedFile.path);
        add(ImageListEvent(imageList));
      }
    }
  }

  ///Crop image screen for crop photo selection
  Future<CroppedFile?> cropImage(
    String sourcePath,
    Color colors,
    CollageType collageType,
  ) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio16x9
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: colors,
          activeControlsWidgetColor: colors,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: (collageType == CollageType.fourSquare)
              ? CropAspectRatioPreset.square
              : CropAspectRatioPreset.ratio16x9,
          lockAspectRatio: true,
          showCropGrid: true,
        ),
      ],
    );

    return croppedFile;
  }

  ///Asking permission (Platform specific)
  askPermission(
    bool isFromPicker,
    PermissionType permissionType,
    int index,
    Color colors,
    CollageType collageType,
  ) async {
    Map<Permission, PermissionStatus> statuses = {};

    /// You can request multiple permissions at once.
    if (Platform.isIOS) {
      statuses = await [
        Permission.photos,
        Permission.storage,
      ].request();
    } else {
      statuses = await [Permission.camera, Permission.storage].request();
    }
    bool isForStorage = permissionType == PermissionType.storage;
    if (isForStorage) {
      if (Platform.isIOS) {
        ///For iOS we need to access photos
        await Permission.photos.request().then(
              (value) => eventAction(
                isForStorage,
                isFromPicker,
                permissionType,
                index,
                statuses,
                colors,
                collageType,
              ),
            );
      } else {
        ///For Android we need to access storage
        await Permission.storage.request().then(
              (value) => eventAction(
                isForStorage,
                isFromPicker,
                permissionType,
                index,
                statuses,
                colors,
                collageType,
              ),
            );
      }
    } else {
      ///If coming from camera then we need to take permission of camera (In both platform)
      await Permission.camera.request().then(
            (value) => eventAction(
              isForStorage,
              isFromPicker,
              permissionType,
              index,
              statuses,
              colors,
              collageType,
            ),
          );
    }
  }

  ///On click of allow or denied event this method will be called...
  eventAction(
    bool isForStorage,
    bool isFromPicker,
    PermissionType permissionType,
    int index,
    Map<Permission, PermissionStatus> status,
    Color colors,
    CollageType collageType,
  ) {
    if (status[isForStorage
            ? Platform.isIOS
                ? Permission.photos
                : Permission.storage
            : Permission.camera] ==
        PermissionStatus.granted) {
      add(
        AllowPermissionEvent(
          isFromPicker,
          permissionType,
          index,
          colors,
          collageType,
        ),
      );
    } else {
      add(
        DenyPermissionEvent(
          isFromPicker,
          permissionType,
          index,
        ),
      );
    }
  }

  ///For remove photo from perticular index
  dispatchRemovePhotoEvent(int index) {
    var imageList = (state as ImageListState).images;
    imageList[index].imageUrl = null;
    add(
      ImageListEvent(
        imageList,
      ),
    );
  }

  /// To load photos from device.
  /// @param path:- path of file from where needs to show image.
  /// Default path :- Camera.
  /// @param maxCount:- Maximum number of photos will return.
  Future loadImages(String path, int? maxCount) async {
    var path = await FilePicker.platform.getDirectoryPath();
    var root = Directory(path ?? '$path/DCIM/Camera');

    await root.exists().then((isExist) async {
      int maxImage = maxCount ?? 6;
      var listImage = blankList();
      if (isExist) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpeg', 'png', 'jpg'],
        );

        List<File> files =
            result!.paths.map((path) => File(path ?? '')).toList();
        debugPrint('file length---> ${files.length}');

        /// [file] by default will return old images.
        /// for getting latest max number of photos [file.sublist(file.length - maxImage, file.length)]

        List<File> filesList = files.length > maxImage
            ? files.sublist(files.length - (maxImage + 1), files.length - 1)
            : files;

        for (int i = 0; i < filesList.length; i++) {
          listImage[i].imageUrl = File(filesList[i].path);
        }
      }

      add(ImageListEvent(listImage));
    });
  }

  ///Show blank images (Thumbnails)
  List<Images> blankList() {
    var imageList = <Images>[];
    for (int i = 0; i < getImageCount(); i++) {
      var images = Images();
      images.id = i + 1;
      imageList.add(images);
    }

    return imageList;
  }

  /// The no. of image return as per collage type.
  getImageCount() {
    if (collageType == CollageType.hSplit ||
        collageType == CollageType.vSplit) {
      return 2;
    } else if (collageType == CollageType.fourSquare ||
        collageType == CollageType.fourLeftBig) {
      return 4;
    } else if (collageType == CollageType.nineSquare) {
      return 9;
    } else if (collageType == CollageType.threeVertical ||
        collageType == CollageType.threeHorizontal) {
      return 3;
    } else if (collageType == CollageType.leftBig ||
        collageType == CollageType.rightBig) {
      return 6;
    } else if (collageType == CollageType.vMiddleTwo ||
        collageType == CollageType.centerBig) {
      return 7;
    } else {
      return 1;
    }
  }

  ///Used to show message
  showSnackBar({String msg = "Permission Denied."}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(milliseconds: 1000),
    ));
  }
}
