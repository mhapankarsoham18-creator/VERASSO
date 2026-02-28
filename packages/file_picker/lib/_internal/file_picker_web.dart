import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart';

class FilePickerWeb extends FilePicker {
  static final FilePickerWeb platform = FilePickerWeb._();
  late HTMLElement _target;

  final String _kFilePickerInputsDomId = '__file_picker_web-file-input';

  final int _readStreamChunkSize = 1000 * 1000; // 1 MB

  FilePickerWeb._() {
    _target = _ensureInitialized(_kFilePickerInputsDomId);
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool withData = true,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    int compressionQuality = 20,
  }) async {
    if (type != FileType.custom && (allowedExtensions?.isNotEmpty ?? false)) {
      throw Exception(
          'You are setting a type [$type]. Custom extension filters are only allowed with FileType.custom, please change it or remove filters.');
    }

    final Completer<List<PlatformFile>?> filesCompleter =
        Completer<List<PlatformFile>?>();

    String accept = _fileType(type, allowedExtensions);
    HTMLInputElement uploadInput =
        document.createElement('input') as HTMLInputElement;
    uploadInput.type = 'file';
    uploadInput.draggable = true;
    uploadInput.multiple = allowMultiple;
    uploadInput.accept = accept;
    uploadInput.style.display = 'none';

    bool changeEventTriggered = false;

    if (onFileLoading != null) {
      onFileLoading(FilePickerStatus.picking);
    }

    void changeEventListener(e) async {
      if (changeEventTriggered) {
        return;
      }
      changeEventTriggered = true;

      final List<File> files = [];
      final inputFiles = uploadInput.files;
      if (inputFiles != null) {
        for (int i = 0; i < inputFiles.length; i++) {
          files.add(inputFiles.item(i)!);
        }
      }
      final List<PlatformFile> pickedFiles = [];

      void addPickedFile(
        File file,
        Uint8List? bytes,
        String? path,
        Stream<List<int>>? readStream,
      ) {
        pickedFiles.add(PlatformFile(
          name: file.name,
          path: path,
          size: bytes != null ? bytes.length : file.size,
          bytes: bytes,
          readStream: readStream,
        ));

        if (pickedFiles.length >= files.length) {
          if (onFileLoading != null) {
            onFileLoading(FilePickerStatus.done);
          }
          filesCompleter.complete(pickedFiles);
        }
      }

      for (File file in files) {
        if (withReadStream) {
          addPickedFile(file, null, null, _openFileReadStream(file));
          continue;
        }

        if (!withData) {
          final FileReader reader = FileReader();
          reader.onloadend = (Event e) {
            addPickedFile(file, null, reader.result as String?, null);
          }.toJS;
          reader.readAsDataURL(file);
          continue;
        }

        final syncCompleter = Completer<void>();
        final FileReader reader = FileReader();
        reader.onloadend = (Event e) {
          addPickedFile(
              file,
              (reader.result as JSArrayBuffer).toDart.asUint8List(),
              null,
              null);
          syncCompleter.complete();
        }.toJS;
        reader.readAsArrayBuffer(file);
        if (readSequential) {
          await syncCompleter.future;
        }
      }
    }

    void cancelledEventListener(_) {
      window.removeEventListener(
          'focus',
          (Event e) {
            cancelledEventListener(e);
          }.toJS);

      // This listener is called before the input changed event,
      // and the `uploadInput.files` value is still null
      // Wait for results from js to dart
      Future.delayed(Duration(seconds: 1)).then((value) {
        if (!changeEventTriggered) {
          changeEventTriggered = true;
          filesCompleter.complete(null);
        }
      });
    }

    uploadInput.onchange = (Event e) {
      changeEventListener(e);
    }.toJS;
    uploadInput.addEventListener(
        'change',
        (Event e) {
          changeEventListener(e);
        }.toJS);
    uploadInput.addEventListener(
        'cancel',
        (Event e) {
          cancelledEventListener(e);
        }.toJS);

    // Listen focus event for cancelled
    window.addEventListener(
        'focus',
        (Event e) {
          cancelledEventListener(e);
        }.toJS);

    //Add input element to the page body
    _target.innerHTML = ''.toJS;
    _target.appendChild(uploadInput);
    uploadInput.click();

    final List<PlatformFile>? files = await filesCompleter.future;

    return files == null ? null : FilePickerResult(files);
  }

  /// Initializes a DOM container where we can host input elements.
  HTMLElement _ensureInitialized(String id) {
    HTMLElement? target = document.querySelector('#$id') as HTMLElement?;
    if (target == null) {
      final HTMLElement targetElement =
          document.createElement('flt-file-picker-inputs') as HTMLElement;
      targetElement.id = id;

      document.body!.appendChild(targetElement);
      target = targetElement;
    }
    return target;
  }

  Stream<List<int>> _openFileReadStream(File file) async* {
    final reader = FileReader();

    int start = 0;
    while (start < file.size) {
      final end = start + _readStreamChunkSize > file.size
          ? file.size
          : start + _readStreamChunkSize;
      final blob = file.slice(start, end);

      final completer = Completer<void>();
      reader.onload = (Event e) {
        completer.complete();
      }.toJS;
      reader.readAsArrayBuffer(blob);
      await completer.future;

      yield (reader.result as JSArrayBuffer).toDart.asUint8List();
      start += _readStreamChunkSize;
    }
  }

  static void registerWith(Registrar registrar) {
    FilePicker.platform = platform;
  }

  static String _fileType(FileType type, List<String>? allowedExtensions) {
    switch (type) {
      case FileType.any:
        return '';

      case FileType.audio:
        return 'audio/*';

      case FileType.image:
        return 'image/*';

      case FileType.video:
        return 'video/*';

      case FileType.media:
        return 'video/*|image/*';

      case FileType.custom:
        return allowedExtensions!
            .fold('', (prev, next) => '${prev.isEmpty ? '' : '$prev,'} .$next');
    }
  }
}
