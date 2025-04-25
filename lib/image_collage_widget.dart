library image_collage_widget;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/collage_bloc.dart';
import 'blocs/collage_event.dart';
import 'blocs/collage_state.dart';
import 'utils/collage_type.dart';
import 'utils/permission_type.dart';
import 'widgets/row_widget.dart';

/// A ImageCollageWidget.
class ImageCollageWidget extends StatefulWidget {
  final String? filePath;
  final CollageType collageType;
  final bool withImage;
  final GlobalKey? screenshotKey;

  const ImageCollageWidget({
    super.key,
    this.filePath,
    this.screenshotKey,
    required this.collageType,
    required this.withImage,
  });

  @override
  State<ImageCollageWidget> createState() => _ImageCollageWidgetState(
        filePath: filePath ?? '',
        collageType: collageType,
      );
}

class _ImageCollageWidgetState extends State<ImageCollageWidget>
    with WidgetsBindingObserver {
  late final String filePath;
  late final CollageType collageType;
  bool _withImage = false;
  late CollageBloc imageListBloc;

  _ImageCollageWidgetState({required this.filePath, required this.collageType});

  @override
  void initState() {
    super.initState();

    _withImage = widget.withImage;

    WidgetsBinding.instance.addObserver(this);
    imageListBloc = CollageBloc(
      context: context,
      path: filePath,
      collageType: collageType,
    );
    imageListBloc.add(ImageListEvent(imageListBloc.blankList()));
    imageListBloc.add(ImageListEvent(imageListBloc.blankList()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    imageListBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => imageListBloc,
      child: BlocBuilder(
        bloc: imageListBloc,
        builder: (context, CollageState state) {
          if (state is PermissionDeniedState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                      "To show images you have to allow storage permission."),
                  TextButton(
                    style: ButtonStyle(
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)))),
                    child: const Text("Allow"),
                    onPressed: () => _handlePermission(),
                  ),
                ],
              ),
            );
          }
          if (state is LoadImageState) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state is ImageListState) {
            return _gridView();
          }
          return Container(
            color: Colors.green,
          );
        },
      ),
    );
  }

  void _handlePermission() {
    imageListBloc.add(
      CheckPermissionEvent(
        true,
        PermissionType.storage,
        0,
        Colors.black,
        widget.collageType,
      ),
    );
  }

  Widget _gridView() {
    return AspectRatio(
      aspectRatio: (collageType != CollageType.one) ? 1.0 / 1.0 : 16.0 / 9.0,
      child: GridCollageWidget(
        collageType,
        imageListBloc,
        context,
        colors: Colors.black,
        screenshotKey: widget.screenshotKey,
      ),
    );
  }
}
