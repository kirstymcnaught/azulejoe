#include "FileUtilsPrivate.h"

#include <private/qzipreader_p.h>
#include <private/qzipwriter_p.h>

#include <QDebug>

FileUtilsPrivate::FileUtilsPrivate()
{
}

bool FileUtilsPrivate::unzipFile(QString srcFilePath,
                                 QString tgtFilePath)
{
  qDebug() << "Unzipping "<< srcFilePath << " to "<< tgtFilePath;
  srcFilePath = "/Users/kirsty/TEMP/data/things.zip";
  tgtFilePath = "/Users/kirsty/TEMP/data/thingsunzipped";

  QZipReader zip(srcFilePath);
  QZipReader::Status stat = zip.status();

  qDebug() << "zip status = "<<stat;
  qDebug() << "zip count = "<<zip.count();

  qDebug() << zip.extractAll(tgtFilePath);

  return true;
}

bool FileUtilsPrivate::isZipFile(QString filePath)
{
  return QZipReader(filePath).isReadable();
}
