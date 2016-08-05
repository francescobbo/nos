#include <fstream>
#include <iostream>

using namespace std;

int main(int argc, char *argv[]) {
  if (argc != 3) {
    cout << "Usage: install DISK_IMAGE BOOT_LOADER" << endl;
    return -1;
  }

  char code[512];
  ifstream loader(argv[2]);
  loader.read(code, 512);
  loader.close();

  fstream file(argv[1], ios::in | ios::out | ios::binary);
  file.seekp(0);
  file.write(code, 512);
  file.close();

  return 0;
}
