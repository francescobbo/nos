#include <fstream>
#include <iostream>
#include <string.h>

using namespace std;

int main(int argc, char *argv[]) {
  if (argc < 3) {
    cout << "Usage: install DISK_IMAGE STAGE1 [file1 [file2 [file3]]]" << endl;
    return -1;
  }

  char code[512];
  ifstream loader(argv[2]);
  loader.read(code, 512);
  loader.close();

  // Open the disk image for writing
  fstream disk(argv[1], ios::in | ios::out | ios::binary);

  // Add the stage1 boot loader
  disk.seekp(0);
  disk.write(code, 512);

  /*
   * Any following file is stored in contiguous sectors, preceded by a single
   * sector containing the number of sectors that the file is made of.
   * The Simplest file system ever.
   */
  int lastSector = 0;
  for (int i = 3; i < argc; i++) {
    ifstream file(argv[i], ios::binary);
    char sizeSector[512] = {0, };

    int sectorLength = 0;
    char buffer[512];
    while (!file.eof()) {
      memset(buffer, 0, 512);
      file.read(buffer, 512);

      disk.seekp((lastSector + sectorLength + 2) * 512, ios::beg);
      disk.write(buffer, 512);
      sectorLength++;
    }

    file.close();

    disk.seekp((lastSector + 1) * 512, ios::beg);
    ((int *)sizeSector)[0] = sectorLength;
    disk.write(sizeSector, 512);

    lastSector += sectorLength + 1;
  }

  disk.close();

  return 0;
}
