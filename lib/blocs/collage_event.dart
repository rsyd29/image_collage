import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:image_collage_widget/model/images.dart';
import 'package:image_collage_widget/utils/collage_type.dart';
import 'package:image_collage_widget/utils/permission_type.dart';

abstract class CollageEvent extends Equatable {
  const CollageEvent([List props = const []]) : super();

  @override
  List<Object> get props => [];
}

///Checking permission event
class CheckPermissionEvent extends CollageEvent {
  final PermissionType permissionType;
  final bool isFromPicker;
  final int index;
  final Color colors;
  final CollageType collageType;

  const CheckPermissionEvent(
    this.isFromPicker,
    this.permissionType,
    this.index,
    this.colors,
    this.collageType,
  );

  @override
  String toString() => 'CheckPermissionEvent';

  @override
  List<Object> get props => [permissionType, isFromPicker, index];
}

///Asking permission event
class AskPermissionEvent extends CollageEvent {
  final PermissionType permissionType;
  final bool isFromPicker;
  final int index;
  final Color colors;
  final CollageType collageType;

  const AskPermissionEvent(
    this.isFromPicker,
    this.permissionType,
    this.index,
    this.colors,
    this.collageType,
  );

  @override
  String toString() => 'AskPermissionEvent';

  @override
  List<Object> get props => [permissionType, isFromPicker, index];
}

///Allow permission event
class AllowPermissionEvent extends CollageEvent {
  final PermissionType permissionType;
  final bool isFromPicker;
  final int index;
  final Color colors;
  final CollageType collageType;

  const AllowPermissionEvent(
    this.isFromPicker,
    this.permissionType,
    this.index,
    this.colors,
    this.collageType,
  );

  @override
  String toString() => 'AllowPermissionEvent';

  @override
  List<Object> get props => [permissionType, isFromPicker, index];
}

///Denied permission event
class DenyPermissionEvent extends CollageEvent {
  final PermissionType permissionType;
  final bool isFromPicker;
  final int index;

  const DenyPermissionEvent(this.isFromPicker, this.permissionType, this.index);

  @override
  String toString() => 'DenyPermissionEvent';

  @override
  List<Object> get props => [permissionType, isFromPicker, index];
}

///ImageList permission event
class ImageListEvent extends CollageEvent {
  final List<Images> imageList;

  const ImageListEvent(this.imageList);

  @override
  String toString() => 'ImageListEvent';

  @override
  List<Object> get props => [imageList];
}
