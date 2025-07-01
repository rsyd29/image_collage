import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/collage_bloc.dart';
import 'blocs/collage_event.dart';
import 'blocs/collage_state.dart';
import 'utils/collage_type.dart';
import 'utils/permission_type.dart';
import 'widgets/row_widget.dart';

class ImageCollageScreen extends StatefulWidget {
  const ImageCollageScreen({
    super.key,
    required this.collageType,
    required this.screenshotKey,
    required this.onPressed,
    this.filePath,
    this.color,
    this.titleAppBar,
    this.titleStyleAppBar,
    this.instruction,
    this.instructionStyle,
    this.textButton,
    this.buttonStyle,
    this.isLoading = false,
    this.loadingWidget,
  });

  final CollageType collageType;
  final GlobalKey screenshotKey;
  final String? filePath;
  final Color? color;
  final String? titleAppBar;
  final TextStyle? titleStyleAppBar;
  final String? instruction;
  final TextStyle? instructionStyle;
  final String? textButton;
  final TextStyle? buttonStyle;
  final VoidCallback? onPressed;
  final bool? isLoading;
  final Widget? loadingWidget;

  @override
  State<ImageCollageScreen> createState() => _ImageCollageScreenState();
}

class _ImageCollageScreenState extends State<ImageCollageScreen>
    with WidgetsBindingObserver {
  late CollageBloc imageListBloc;

  _ImageCollageScreenState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    imageListBloc = CollageBloc(
      context: context,
      path: widget.filePath ?? '',
      collageType: widget.collageType,
    );
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
    return BlocProvider<CollageBloc>(
      create: (context) => imageListBloc,
      child: BlocBuilder(
        bloc: imageListBloc,
        builder: (context, state) {
          if (state is PermissionDeniedState) {
            return bodyScreen(
              context: context,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                        "To show images you have to allow storage permission."),
                    TextButton(
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      child: const Text("Allow"),
                      onPressed: () => _handlePermission(),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is LoadImageState) {
            return bodyScreen(
              context: context,
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (state is ImageListState) {
            return bodyScreen(
              context: context,
              isShowFAB: true,
              state: state,
              body: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _gridView(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 8,
                        ),
                        child: Text(
                          widget.instruction ?? 'Instruction',
                          style: widget.instructionStyle,
                        ),
                      ),
                    ],
                  ),
                  if (widget.isLoading ?? false)
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: IgnorePointer(
                        ignoring: true,
                        child: Center(
                          child: widget.loadingWidget,
                        ),
                      ),
                    )
                ],
              ),
            );
          }
          return bodyScreen(
            context: context,
            body: Container(
              color: widget.color,
            ),
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
        widget.color ?? Colors.black,
        widget.collageType,
      ),
    );
  }

  Widget _gridView() {
    return RepaintBoundary(
      key: widget.screenshotKey,
      child: AspectRatio(
        aspectRatio:
            (widget.collageType != CollageType.one) ? 1.0 / 1.0 : 16.0 / 9.0,
        child: Container(
          color: Colors.white,
          child: GridCollageWidget(
            widget.collageType,
            imageListBloc,
            context,
            colors: widget.color ?? Colors.black,
            screenshotKey: widget.screenshotKey,
          ),
        ),
      ),
    );
  }

  Widget bodyScreen({
    required BuildContext context,
    required Widget body,
    bool? isShowFAB,
    Object? state,
  }) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.color,
        title: Title(
          color: widget.color ?? Colors.blue,
          child: Text(
            widget.titleAppBar ?? 'Title',
            style: widget.titleStyleAppBar,
          ),
        ),
      ),
      body: body,
      floatingActionButton: ((isShowFAB ?? false) && state is ImageListState)
          ? SizedBox(
              height: 40,
              width: MediaQuery.of(context).size.width - (24 * 2),
              child: FloatingActionButton(
                elevation: 0,
                backgroundColor: ((state)
                            .images
                            .where((element) => element.imageUrl == null)
                            .toList()
                            .isEmpty) &&
                        (widget.isLoading == false)
                    ? widget.color
                    : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onPressed: ((state)
                            .images
                            .where((element) => element.imageUrl == null)
                            .toList()
                            .isEmpty) &&
                        (widget.isLoading == false)
                    ? widget.onPressed
                    : null,
                child: Text(
                  widget.textButton ?? 'Text Button',
                  style: widget.buttonStyle,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: (isShowFAB ?? false)
          ? FloatingActionButtonLocation.centerFloat
          : null,
    );
  }
}
