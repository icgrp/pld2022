
template<typename T>
void load_kh(T& comp, const Word kh_mem[KH_WORDS], Address idx) {
  //printf("kh_mem %d\n", (unsigned int)idx/KH_PER_WORD);
  Word kh_word = kh_mem[idx/KH_PER_WORD];
  IdxType off = idx % KH_PER_WORD;
  if (off == 0)
    comp(15,0) = kh_word(15, 0);
  else if (off == 1)
    comp(15,0) = kh_word(31,16);
  else if (off == 2)
    comp(15,0) = kh_word(47,32);
  else
    comp(15,0) = kh_word(63,48);
}
