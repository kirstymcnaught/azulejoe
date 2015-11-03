#ifndef FILEUTILSPRIVATE_H
#define FILEUTILSPRIVATE_H

#include <QString>


// File utils using things from qt-private.
// This means they may not be supported in future, so they
// are kept separate for easier replacement.
class FileUtilsPrivate
{
public:
  FileUtilsPrivate();

  bool unzipFile(QString srcFilePath,
                 QString tgtFilePath);

  bool isZipFile(QString filePath);

};

#endif // FILEUTILSPRIVATE_H
