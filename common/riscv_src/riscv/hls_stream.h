#ifndef __HLS_STREAM_H_
#define __HLS_STREAM_H_

# include "ap_int.h"
#include <stdint.h>
#define STREAMOUT_BASE 0x10000000

//template <class type>
namespace hls{
  template <class type>
  class stream
  {
      public:
	uint32_t ADDR;
        unsigned int WORD_NUM;
	stream(uint32_t addr, unsigned int bits){ ADDR = addr; WORD_NUM=bits>>5; }
	stream(void){ ADDR = STREAMOUT_BASE; };

        type read(){
          type out_tmp;
          for(int i=0; i<WORD_NUM; i++){
            out_tmp((i<<5)+31, i<<5) = *((volatile uint32_t*)ADDR);
          }
	  return out_tmp;
        }

        void write(type dout){
          for(int i=0; i<WORD_NUM;i++){ 
	    *((volatile uint32_t*)ADDR) = (unsigned int) dout((i<<5)+31, (i<<5));
          }
        }
 
  };

template<typename __STREAM_T__, int SIZE=4096>
class stream_local
{
  protected:
	//std::string _name;
	__STREAM_T__ _data[SIZE];
	unsigned int _head = 0;
	unsigned int _tail = 0;
  public:
    /// Constructors
    // Keep consistent with the synthesis model's constructors
    stream_local() {

    }

    //stream_local(const std::string name) {
    // default constructor,
    // capacity set to predefined maximum
    //    _name = name;
    //}

  public:
    /// Destructor
    /// Check status of the queue
    virtual ~stream_local() {
       ;
    }



    __STREAM_T__ read() {
        __STREAM_T__ elem;
        if(_tail==SIZE-1){
			elem = _data[_tail];
			_tail = 0;
			//std::cout<< _name << ": fifo empty!" << std::endl;
		} else if(_tail==_head){
			elem = _data[_tail];
			//std::cout<< _name << ": empty!" << std::endl;
		} else {
			//std::cout<< _name << " tail = " << _tail << std::endl;
			elem = _data[_tail];
			_tail++;
		}
        return elem;
    }

    /// Blocking write
    void write(const __STREAM_T__& tail) { 
		if(_head==SIZE-1){
			_data[_head]=tail;
			_head = 0;
			//std::cout<< _name << " full!" << std::endl;
		} else {
			_data[_head]=tail;
			//std::cout<< _name << " head = " << _head << std::endl;
			_head++;

		}

    }

    void write(unsigned int tail) {
		if(_head==SIZE-1){
			_data[_head].data=tail;
			_head = 0;
			//std::cout<< _name << " full!" << std::endl;
		} else {
			_data[_head].data=tail;
			//std::cout<< _name << " head = " << _head << std::endl;
			_head++;
		}

    }

};//end of stream_local



}// end of hls

#endif
