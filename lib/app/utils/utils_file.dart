import 'dart:io';

import 'package:msk_utils/utils/utils_platform.dart';
import 'dart:io' as io;

import 'package:path_provider/path_provider.dart';
import 'package:share_extend/share_extend.dart';

class UtilsFile {
  static saveFileString(String s,
      {String fileName,
      String extensionFile,
      String dirComplementar,
      String contentExport}) async {
    String diretorio;
    String separator = "/";
    if (UtilsPlatform.isWindows()) {
      separator = "\\";
    }
    if (UtilsPlatform.isDesktop()) {
      diretorio = '${io.Directory.current.path}${separator}Files';
    } else {
      diretorio = (await getExternalStorageDirectory()).absolute.path;
    }
    if (dirComplementar != null) {
      diretorio += '$separator$dirComplementar';
    }
    io.File file =
        io.File('$diretorio$separator${DateTime.now().millisecondsSinceEpoch}');
    io.Directory dir = io.Directory('$diretorio');
    if ((await dir.exists()) == false) {
      dir = await dir.create(recursive: true);
    }
    if (fileName == null) {
      fileName =
          '${DateTime.now().millisecondsSinceEpoch}${extensionFile != null ? extensionFile : ''}';
    }
    file = io.File('${dir.path}$separator$fileName');
    if ((await file.exists()) == false) {
      file = await file.create(recursive: true);
    }
    await file.writeAsString(s);
    await openFileOrDirectory(file.path, dir.path,
        contentExport: contentExport);
  }

  static openFileOrDirectory(String filePath, String directoryPath,
      {String contentExport}) async {
    if (UtilsPlatform.isWindows()) {
      await UtilsPlatform.openProcess('explorer.exe', args: ['$directoryPath']);
    } else if (Platform.isMacOS) {
      await UtilsPlatform.openProcess('open', args: ['$directoryPath']);
    } else if (UtilsPlatform.isMobile()) {
      ShareExtend.share(filePath, "file",
          sharePanelTitle: 'Selecione por onde deseja enviar seu arquivo',
          subject: contentExport ?? 'Segue em anexo seu relatório');
    }
  }
}
