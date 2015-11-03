#include "FileDownloader.h"
#include "FileUtilsPrivate.h"
#include <QFile>

FileDownloader::FileDownloader() :
 QObject()
{
 connect(
  &m_WebCtrl, SIGNAL (finished(QNetworkReply*)),
  this, SLOT (fileDownloaded(QNetworkReply*))
  );
}

FileDownloader::~FileDownloader() { }

void FileDownloader::fileDownloaded(QNetworkReply* pReply) {
// m_DownloadedData = pReply->readAll();
 //emit a signal
 emit downloaded();

 // Save to disk
 QString filename = "/Users/kirsty/TEMP/data/downloadthing";
 QFile file(filename);
 if (!file.open(QIODevice::WriteOnly)) {
   fprintf(stderr, "Could not open %s for writing: %s\n",
           qPrintable(filename),
           qPrintable(file.errorString()));
   qDebug() << "Error";
 }

 file.write(pReply->readAll());
 file.close();

 // Unzip (if appropriate)
 FileUtilsPrivate fileUtils;
 if (fileUtils.isZipFile(filename)) {
   qDebug() << "Unzipping file " << filename;
   fileUtils.unzipFile(filename, filename + "unzipped");
 }

 qDebug() << fileUtils.isZipFile("/Users/kirsty/TEMP/data/downloadthing");

 qDebug() << fileUtils.isZipFile("/Users/kirsty/TEMP/data/downloadthing");

 qDebug() << fileUtils.isZipFile("/Users/kirsty/TEMP/data/thing.txt");

 pReply->deleteLater();

}

QByteArray FileDownloader::downloadedData() const {
  return m_DownloadedData;
}

void FileDownloader::startDownload(QUrl url)
{
  QNetworkRequest request(url);
  m_WebCtrl.get(request);
}

QByteArray FileDownloader::getDownloadedData()
{
  return m_DownloadedData;
}
