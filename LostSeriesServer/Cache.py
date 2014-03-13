from Singleton import Singleton
import Storage


@Singleton
class DataCache:

  __IsCacheValid = False
  __Data = []

  def GetData(self, snapshot = ""):
    if self.__IsCacheValid is False:
      self.__Data = Storage.ReadLostSeriesData(snapshot)
      self.__IsCacheValid = True
    #
    return self.__Data

  def Reset(self):
    self.__IsCacheValid = False;
    self.__Data = []
