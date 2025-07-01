import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../blocs/collage_bloc.dart';
import '../blocs/collage_event.dart';
import '../blocs/collage_state.dart';
import '../model/images.dart';
import '../utils/collage_type.dart';
import '../utils/permission_type.dart';

class GridCollageWidget extends StatelessWidget {
  // var _imageList = <Images>[];
  final CollageType _collageType;
  final CollageBloc _imageListBloc;
  final BuildContext _context;
  final Color colors;
  final GlobalKey? screenshotKey;

  const GridCollageWidget(
    this._collageType,
    this._imageListBloc,
    this._context, {
    super.key,
    required this.colors,
    required this.screenshotKey,
  });

  @override
  Widget build(BuildContext context) {
    if (_imageListBloc.state is ImageListState) {
      final List<Images> imageList =
          (_imageListBloc.state as ImageListState).images;

      return (imageList.length != 1)
          ? StaggeredGridView.countBuilder(
              shrinkWrap: false,
              itemCount: imageList.length,
              crossAxisCount: getCrossAxisCount(_collageType),
              primary: true,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              itemBuilder: (BuildContext context, int index) =>
                  buildRow(context, index, imageList),
              staggeredTileBuilder: (int index) => StaggeredTile.count(
                getCellCount(
                  index: index,
                  isForCrossAxis: true,
                  type: _collageType,
                ),
                double.parse(
                  getCellCount(
                    index: index,
                    isForCrossAxis: false,
                    type: _collageType,
                  ).toString(),
                ),
              ),
            )
          : buildRow(context, 0, imageList);
    }
    return Container(
      color: Colors.green,
    );
  }

  ///Find cross axis count for arrange items to Grid
  int getCrossAxisCount(CollageType type) {
    if (type == CollageType.hSplit ||
        type == CollageType.vSplit ||
        type == CollageType.threeHorizontal ||
        type == CollageType.threeVertical) {
      return 2;
    } else if (type == CollageType.fourSquare) {
      return 4;
    } else if (type == CollageType.nineSquare) {
      return 9;
    } else if (type == CollageType.leftBig || type == CollageType.rightBig) {
      return 3;
    } else if (type == CollageType.fourLeftBig) {
      return 3;
    } else if (type == CollageType.vMiddleTwo ||
        type == CollageType.centerBig) {
      return 12;
    } else {
      return 1;
    }
  }

  ///Build UI either image is selected or not
  Widget buildRow(BuildContext context, int index, List<Images> imageList) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned.fill(
          bottom: 0.0,
          child: Container(
            child: imageList[index].imageUrl != null
                ? Image.file(
                    imageList[index].imageUrl ?? File(''),
                    fit: BoxFit.fitHeight,
                  )
                : const Padding(
                    padding: EdgeInsets.all(3),
                    child: Material(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Color(0xFFD3D3D3),
                      child: Icon(Icons.add),
                    ),
                  ),
          ),
        ),
        Positioned.fill(
            child: Material(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                color: Colors.transparent,
                child: InkWell(
                    highlightColor: Colors.transparent,
                    onTap: () => showDialogImage(index),
                    onLongPress: () async {
                      RenderRepaintBoundary? boundary =
                          screenshotKey?.currentContext?.findRenderObject()
                              as RenderRepaintBoundary?;
                      final image = await boundary?.toImage(
                        pixelRatio: 5.0,
                      );

                      final imageByte = await image?.toByteData(
                          format: ui.ImageByteFormat.png);
                      if (imageByte != null) {
                        final imageBytes = imageByte.buffer.asUint8List();

                        ui.Image originalImage =
                            await decodeImageFromList(imageBytes);

                        final recorder = ui.PictureRecorder();
                        final canvas = Canvas(recorder);

                        // Terjemahkan titik asal ke tengah gambar
                        canvas.translate(originalImage.width.toDouble() / 2,
                            originalImage.height.toDouble() / 2);

                        // Kembalikan titik asal dan gambar
                        canvas.translate(-originalImage.width.toDouble() / 2,
                            -originalImage.height.toDouble() / 2);
                        canvas.drawImage(originalImage, Offset.zero, Paint());

                        final picture = recorder.endRecording();
                        final correctedImage = await picture.toImage(
                            originalImage.width, originalImage.height);

                        final correctedBytes = await correctedImage.toByteData(
                            format: ui.ImageByteFormat.png);
                        final correctedUint8List =
                            correctedBytes!.buffer.asUint8List();

                        if (context.mounted) {
                          await showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                child: Image(
                                  image: MemoryImage(correctedUint8List),
                                ),
                              );
                            },
                          );
                        }
                      }
                    }))),
      ],
    );
  }

  ///Show bottom sheet
  void showDialogImage(int index) {
    showModalBottomSheet(
        context: _context,
        builder: (BuildContext context) {
          return Container(
            color: const Color(0xFF737373),
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      topRight: Radius.circular(10.0))),
              child: Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    buildDialogOption(
                      index,
                      isForStorage: false,
                      colors: colors,
                      collageType: _collageType,
                    ),
                    buildDialogOption(
                      index,
                      colors: colors,
                      collageType: _collageType,
                    ),
                    (_imageListBloc.state as ImageListState)
                                .images[index]
                                .imageUrl !=
                            null
                        ? buildDialogOption(
                            index,
                            isForRemovePhoto: true,
                            colors: colors,
                            collageType: _collageType,
                          )
                        : Container(),
                  ],
                ),
              ),
            ),
          );
        });
  }

  ///Show dialog
  Widget buildDialogOption(
    int index, {
    bool isForStorage = true,
    bool isForRemovePhoto = false,
    Color colors = Colors.black,
    CollageType collageType = CollageType.one,
  }) {
    return TextButton(
        onPressed: () {
          dismissDialog();
          isForRemovePhoto
              ? _imageListBloc.dispatchRemovePhotoEvent(index)
              : _imageListBloc.add(
                  CheckPermissionEvent(
                    true,
                    isForStorage
                        ? PermissionType.storage
                        : PermissionType.camera,
                    index,
                    colors,
                    collageType,
                  ),
                );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  isForRemovePhoto
                      ? Icons.clear
                      : isForStorage
                          ? Icons.photo_album
                          : Icons.add_a_photo,
                  color: isForRemovePhoto
                      ? Colors.red
                      : isForStorage
                          ? Colors.amber
                          : Colors.blue,
                ),
              ),
              Text(isForRemovePhoto
                  ? "Remove"
                  : isForStorage
                      ? "Gallery"
                      : "Camera")
            ],
          ),
        ));
  }

  ///Dismiss dialog
  void dismissDialog() {
    Navigator.of(_context, rootNavigator: true).pop(true);
  }

  /// @param index:- index of image.
  /// @param isForCrossAxis = if from cross axis count = true
  /// Note:- If row == column then crossAxisCount = row*column // rowCount or columnCount
  /// e.g. row = 3 and column = 3 then crossAxisCount = 3*3(9) or 3
  int getCellCount(
      {required int index,
      required bool isForCrossAxis,
      required CollageType type}) {
    /// total cell count :- 2
    /// Column and Row :- 2*1 = 2 (Cross axis count)

    if (type == CollageType.vSplit) {
      if (isForCrossAxis) {
        /// Cross axis cell count
        return 1;
      } else {
        /// Main axis cell count
        return 2;
      }
    }

    /// total cell count :- 2
    /// Column and Row :- 1*2 = 2 (Cross axis count)

    else if (type == CollageType.hSplit) {
      if (isForCrossAxis) {
        /// Cross axis cell count
        return 2;
      } else {
        /// Main axis cell count
        return 1;
      }
    }

    /// total cell count :- 4
    /// Column and Row :- 2*2 (Cross axis count)

    else if (type == CollageType.fourSquare) {
      /// cross axis and main axis cell count
      return 2;
    }

    /// total cell count :- 9
    /// Column and Row :- 3*3 (Cross axis count)
    else if (type == CollageType.nineSquare) {
      return 3;
    }

    /// total cell count :- 3
    /// Column and Row :- 2 * 2
    /// First index taking 2 cell count in main axis and also in cross axis.
    else if (type == CollageType.threeVertical) {
      if (isForCrossAxis) {
        return 1;
      } else {
        return (index == 0) ? 2 : 1;
      }
    } else if (type == CollageType.threeHorizontal) {
      if (isForCrossAxis) {
        return (index == 0) ? 2 : 1;
      } else {
        return 1;
      }
    }

    /// total cell count :- 6
    /// Column and Row :- 3 * 3
    /// First index taking 2 cell in main axis and also in cross axis.
    /// Cross axis count = 3

    else if (type == CollageType.leftBig) {
      if (isForCrossAxis) {
        return (index == 0) ? 2 : 1;
      } else {
        return (index == 0) ? 2 : 1;
      }
    } else if (type == CollageType.rightBig) {
      if (isForCrossAxis) {
        return (index == 1) ? 2 : 1;
      } else {
        return (index == 1) ? 2 : 1;
      }
    } else if (type == CollageType.fourLeftBig) {
      if (isForCrossAxis) {
        return (index == 0) ? 2 : 1;
      } else {
        return (index == 0) ? 3 : 1;
      }

      /// total tile count (image count)--> 7
      /// Column: Row (2:3)
      /// First column :- 3 tile
      /// Second column :- 4 tile
      /// First column 3 tile taking second column's 4 tile space. So total tile count is 4*3=12(cross axis count).
      /// First column each cross axis tile count = cross axis count/ total tile count(In cross axis)  {12/3 = 4]
      /// Second column cross axis cell count :- 12/4 = 3
      /// Main axis count : Cross axis count / column count {12/2 = 6}
    } else if (type == CollageType.vMiddleTwo) {
      if (isForCrossAxis) {
        return 6;
      } else {
        return (index == 0 || index == 3 || index == 5) ? 4 : 3;
      }
    }

    /// total tile count (image count)--> 7
    /// left, right and center  - 3/3/1
    /// total column:- 3
    /// total row :- 4 (total row is 3 but column 2 taking 2 row space so left + center + right = 1+2+1 {4}).
    /// cross axis count = total column * total row {3*4 = 12}.
    /// First/Third column each cross axis tile count = cross axis count / total tile count(In cross axis) = 12 / 3 = 4
    /// First/Third column each main axis tile count = cross axis count / total tile count(In main axis) = 12 / 4 = 3
    /// Second each cross axis tile count = cross axis count / total tile count(In cross axis) = 12/1 = 12
    /// Second each main axis tile count = cross axis count / total tile count(In main axis) = 12/2 = 6

    else if (type == CollageType.centerBig) {
      if (isForCrossAxis) {
        return (index == 1) ? 6 : 3;
      } else {
        return (index == 1) ? 12 : 4;
      }
    } else {
      return 1;
    }
  }

  ///Show image picker dialog
  void imagePickerDialog(int index) {
    showDialog(
        context: _context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  buildDialogOption(index, isForStorage: false),
                  buildDialogOption(index),
                  (_imageListBloc.state as ImageListState)
                              .images[index]
                              .imageUrl !=
                          null
                      ? buildDialogOption(index, isForRemovePhoto: true)
                      : Container(),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  dismissDialog();
                },
                child: const Text("Cancel"),
              )
            ],
          );
        });
  }
}
