#include "FileUtils.h"
#include <QFile>
#include <QDir>

#include <fstream>

QByteArray FileUtils::read(const QString &fullFilename)
{
    QFile file(fullFilename);
    if (!file.open(QIODevice::ReadOnly))
        return QByteArray();

    return file.readAll();
}

QByteArray FileUtils::read(const QString &path, const QString &filename)
{
    return this->read(fullFile(path, filename));
}

QString FileUtils::fullFile(const QString &path, const QString &filename)
{
    return QDir(path).filePath(filename);
}

bool FileUtils::exists(const QString &fullFilename)
{
    QFile file(fullFilename);
    return file.exists();
}

bool FileUtils::exists(const QString &path, const QString &filename)
{
  return this->exists(fullFile(path, filename));
}

bool FileUtils::writeToFile(const QString& filename,
                            const QString& string)
{
  std::ofstream myfile;
  myfile.open(filename.toStdString());
  if (myfile.is_open()) {
    myfile << string.toStdString() << std::endl;
    myfile.close();
    return true;
  }
  else {
    return false;
  }
}

bool FileUtils::copyRecursively(QString srcFilePath,
                                QString tgtFilePath)
{

  QFileInfo topDirInfo(srcFilePath);

  // If single file, just plain copy
  if (topDirInfo.isFile()) {
    return(QFile::copy(srcFilePath, tgtFilePath));
  }
  else if (topDirInfo.isDir()) {
    // Make directory
    QDir targetDir(tgtFilePath);
    if (!targetDir.mkdir(QFileInfo(tgtFilePath).fileName())) {
      return false;
    }

    // Get contents
    QDir sourceDir(srcFilePath);
    QStringList fileNames = sourceDir.entryList(QDir::Files |
                                                QDir::Dirs |
                                                QDir::NoDotAndDotDot |
                                                QDir::Hidden |
                                                QDir::System);

    // Recursively copy
    foreach (const QString &fileName, fileNames) {
      // TODO: This doesn't seem very cross-platform.
      const QString newSrcFilePath
          = srcFilePath + QLatin1Char('/') + fileName;
      const QString newTgtFilePath
          = tgtFilePath + QLatin1Char('/') + fileName;
      if (!copyRecursively(newSrcFilePath, newTgtFilePath))
        return false;
    }
  }
  return true;
}

