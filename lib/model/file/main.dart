import 'package:file_picker/file_picker.dart';
import 'package:progression_live_upgrade/model/general/stream.dart';

class PdfDocumentFile extends StreamElement<FilePickerResult?> {
  FilePickerResult? filePicked;

  PdfDocumentFile();

  Future<PlatformFile?> getFile([Function(PlatformFile? file)? callBack]) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['pdf'],
    );
    PlatformFile? file = result?.files.isNotEmpty == true ? result!.files.first : null;
    add(result);
    if (callBack != null) callBack(file);
    return file;
  }
}