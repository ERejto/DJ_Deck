#include <string>
#include <iostream>
#include <fstream>
using namespace std;

class song {
    //Class keeps track of stream position,
    //file and path? and has some specific 
    //functions to make it easy to run shit
    //
    //lol eventually you'll need to make this
    //support mp3. Problem for later
    
    string song_path = "";
    streampos size;
    ifstream file;
    char * blk;

private:

    void open() {
        file.open(song_path, ios::binary);
        if (!file.is_open()) {
            throw runtime_error("Can't open file");
        }
    }

    void get_size() {
        open();
        file.seekg(0, ios::end);
        size = file.tellg();
        file.close();
    }

public:
    
    song(string path) {
        song_path = path;
        // immediately open file and get size
        get_size();
    }



    void get_data(int len) {
        static_cast<std::streamoff>(len);
        if (len > size) {
            throw runtime_error("Slice requested is too large");
        }
        else {
            blk = new char [len];
            open();
            file.seekg(0, ios::beg);
            file.read(blk,len);
            file.close();

            cout << blk << "\n";
            delete[] blk;
        }
    }

    void print() {
        blk = new char [size];
        open();
        file.seekg(0, ios::beg);
        file.read(blk,size);
        file.close();

        cout << blk << "\n";
        delete[] blk;
    }
};

int main () {
    song song1("./song.bin");
    song1.print();
    song1.get_data(1);
    song1.get_data(2);
    song1.get_data(3);
    song1.get_data(4);
}

