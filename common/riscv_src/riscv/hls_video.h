#ifndef ___HLS__VIDEO_MEM__
#define ___HLS__VIDEO_MEM__

//#define __DEBUG__

#ifdef AESL_SYN
#undef __DEBUG__
#endif

namespace hls {

/* Template class of Window */
template<int ROWS, int COLS, typename T>
class Window {
public:
	T val[ROWS][COLS];

    Window() {
    };

    void shift_pixels_left() {
        unsigned int i, j;
        for(i = 0; i < ROWS; i++) {
            for(j = 0; j < COLS-1; j++) {
                val[i][j] = val[i][j+1];
            }
        }
    }

    void insert_pixel(T value, int row, int col) {
        val[row][col] = value;
    }

	T getval(int row, int col) {
        return val[row][col];
    }
};


/* Template class of LineBuffer */
template<int ROWS, int COLS, typename T>
class LineBuffer {
public:
	T val[ROWS][COLS];

    LineBuffer() {
    };

    void shift_pixels_up(int col) {
        unsigned int i, j;
        for(i = 0; i < ROWS-1; i++) {
            val[i][col] = val[i+1][col];
        }
    }

    void insert_bottom_row(T value, int col){
        val[ROWS-1][col] = value;
    }

	T getval(int row, int col) {
        return val[row][col];
    }
};





} // namespace hls

#endif
