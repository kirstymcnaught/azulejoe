#include "FileDownloader.h"

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
 m_DownloadedData = pReply->readAll();
 //emit a signal
 pReply->deleteLater();
 emit downloaded();
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
