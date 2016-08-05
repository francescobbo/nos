#include <fstream>
#include <iostream>

using namespace std;

void usage() {
  cout << "Usage: mkimage SIZE_IN_MB OUTPUT" << endl;
  cout << "\tSIZE_IN_MB must be an integer" << endl;
  cout << "\tOUTPUT file will be erased if existing" << endl;
}

void progress(int step, int total) {
  int length = 60;
  cout << "[";
  int pos = length * (float)step / total;
  for (int i = 0; i < length; ++i) {
    if (i < pos) {
      cout << "=";
    } else if (i == pos) {
      cout << ">";
    } else {
      cout << " ";
    }
  }
  cout << "] " << int((float)step / total * 100.0) << " %\r";
  cout.flush();
}

int main(int argc, char *argv[]) {
  if (argc != 3) {
    usage();
    return -1;
  }

  int size;
  try {
    size = stoi(argv[1]);
  } catch (invalid_argument e) {
    usage();
    return -1;
  }

  // Every MB is made of 2048 sectors on a 512bps disk
  int sectors = size * 2048;
  int spt = 32;
  int hpt = 4;
  int tracks = sectors / spt / hpt;

  std::string filename = argv[2];
  ofstream disk(filename);

  const int blockSize = 4 * 1024 * 1024;
  char *buffer = new char[blockSize];
  memset(buffer, 0, blockSize);

  int blocks = ((long)size * 1024 * 1024) / blockSize;
  for (int i = 0; i < blocks; i++) {
    disk.write(buffer, blockSize);
    progress(i, blocks);
  }

  progress(blocks, blocks);
  cout << endl;

  cout << "Tracks: " << tracks << ". Heads: " << hpt << ". Sectors per track: " << spt << endl;

  disk.close();
  delete[] buffer;
  return 0;
}
