class config{
public:
	unsigned int ctrl_reg;
	unsigned int reg0;
	unsigned int reg1;
	unsigned int reg2;
	unsigned int reg3;
	unsigned int reg4;
	unsigned int reg5;
	unsigned int reg6;
	unsigned int reg7;


	config(unsigned int BASE_ADDR, unsigned int CTRL_REG);

	void read_from_fifo();

	void write_to_fifo(int high_32_bits, int low_32_bits);

	void init_regs();

	void ap_start();

	void instr_config(unsigned int bft_addr,const unsigned int *instr_data, unsigned int len);

	void app();


};
