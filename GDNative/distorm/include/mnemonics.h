/*
mnemonics.h

diStorm3 - Powerful disassembler for X86/AMD64
http://ragestorm.net/distorm/
distorm at gmail dot com
Copyright (C) 2003-2021 Gil Dabah
This library is licensed under the BSD license. See the file COPYING.
*/


#ifndef MNEMONICS_H
#define MNEMONICS_H

#ifdef __cplusplus
 extern "C" {
#endif

#ifndef DISTORM_LIGHT

typedef struct WMnemonic {
	unsigned char length;
	unsigned char p[1]; /* p is a null terminated string, which contains 'length' characters. */
} _WMnemonic;

typedef struct WRegister {
	unsigned int length;
	unsigned char p[6]; /* p is a null terminated string. */
} _WRegister;

extern const unsigned char _MNEMONICS[];
extern const _WRegister _REGISTERS[];

#endif /* DISTORM_LIGHT */

#ifdef __cplusplus
} /* End Of Extern */
#endif

#define GET_REGISTER_NAME(r) (unsigned char*)_REGISTERS[(r)].p
#define GET_MNEMONIC_NAME(m) ((_WMnemonic*)&_MNEMONICS[(m)])->p

 typedef enum {
	I_UNDEFINED = 0, I_AAA = 66, I_AAD = 389, I_AAM = 384, I_AAS = 76, I_ADC = 31, I_ADD = 11, I_ADDPD = 3144,
	I_ADDPS = 3137, I_ADDSD = 3158, I_ADDSS = 3151, I_ADDSUBPD = 6428, I_ADDSUBPS = 6438,
	I_AESDEC = 9243, I_AESDECLAST = 9260, I_AESENC = 9201, I_AESENCLAST = 9218,
	I_AESIMC = 9184, I_AESKEYGENASSIST = 9829, I_AND = 41, I_ANDNPD = 3055, I_ANDNPS = 3047,
	I_ANDPD = 3024, I_ANDPS = 3017, I_ARPL = 111, I_BLENDPD = 9406, I_BLENDPS = 9387,
	I_BLENDVPD = 7653, I_BLENDVPS = 7643, I_BOUND = 104, I_BSF = 4380, I_BSR = 4392,
	I_BSWAP = 960, I_BT = 872, I_BTC = 934, I_BTR = 912, I_BTS = 887, I_CALL = 456,
	I_CALL_FAR = 260, I_CBW = 228, I_CDQ = 250, I_CDQE = 239, I_CLAC = 1787, I_CLC = 492,
	I_CLD = 512, I_CLFLUSH = 4363, I_CLGI = 1867, I_CLI = 502, I_CLTS = 541, I_CMC = 487,
	I_CMOVA = 694, I_CMOVAE = 663, I_CMOVB = 656, I_CMOVBE = 686, I_CMOVG = 754,
	I_CMOVGE = 738, I_CMOVL = 731, I_CMOVLE = 746, I_CMOVNO = 648, I_CMOVNP = 723,
	I_CMOVNS = 708, I_CMOVNZ = 678, I_CMOVO = 641, I_CMOVP = 716, I_CMOVS = 701,
	I_CMOVZ = 671, I_CMP = 71, I_CMPEQPD = 4483, I_CMPEQPS = 4404, I_CMPEQSD = 4641,
	I_CMPEQSS = 4562, I_CMPLEPD = 4501, I_CMPLEPS = 4422, I_CMPLESD = 4659, I_CMPLESS = 4580,
	I_CMPLTPD = 4492, I_CMPLTPS = 4413, I_CMPLTSD = 4650, I_CMPLTSS = 4571, I_CMPNEQPD = 4522,
	I_CMPNEQPS = 4443, I_CMPNEQSD = 4680, I_CMPNEQSS = 4601, I_CMPNLEPD = 4542,
	I_CMPNLEPS = 4463, I_CMPNLESD = 4700, I_CMPNLESS = 4621, I_CMPNLTPD = 4532,
	I_CMPNLTPS = 4453, I_CMPNLTSD = 4690, I_CMPNLTSS = 4611, I_CMPORDPD = 4552,
	I_CMPORDPS = 4473, I_CMPORDSD = 4710, I_CMPORDSS = 4631, I_CMPS = 301, I_CMPUNORDPD = 4510,
	I_CMPUNORDPS = 4431, I_CMPUNORDSD = 4668, I_CMPUNORDSS = 4589, I_CMPXCHG = 898,
	I_CMPXCHG16B = 6407, I_CMPXCHG8B = 6396, I_COMISD = 2813, I_COMISS = 2805,
	I_CPUID = 865, I_CQO = 255, I_CRC32 = 9292, I_CVTDQ2PD = 6821, I_CVTDQ2PS = 3341,
	I_CVTPD2DQ = 6831, I_CVTPD2PI = 2715, I_CVTPD2PS = 3267, I_CVTPH2PS = 4195,
	I_CVTPI2PD = 2529, I_CVTPI2PS = 2519, I_CVTPS2DQ = 3351, I_CVTPS2PD = 3257,
	I_CVTPS2PH = 4205, I_CVTPS2PI = 2705, I_CVTSD2SI = 2735, I_CVTSD2SS = 3287,
	I_CVTSI2SD = 2549, I_CVTSI2SS = 2539, I_CVTSS2SD = 3277, I_CVTSS2SI = 2725,
	I_CVTTPD2DQ = 6810, I_CVTTPD2PI = 2648, I_CVTTPS2DQ = 3361, I_CVTTPS2PI = 2637,
	I_CVTTSD2SI = 2670, I_CVTTSS2SI = 2659, I_CWD = 245, I_CWDE = 233, I_DAA = 46,
	I_DAS = 56, I_DEC = 86, I_DIV = 1646, I_DIVPD = 3533, I_DIVPS = 3526, I_DIVSD = 3547,
	I_DIVSS = 3540, I_DPPD = 9649, I_DPPS = 9636, I_EMMS = 4134, I_ENTER = 340,
	I_EXTRACTPS = 9514, I_EXTRQ = 4170, I_F2XM1 = 1192, I_FABS = 1123, I_FADD = 1023,
	I_FADDP = 1549, I_FBLD = 1601, I_FBSTP = 1607, I_FCHS = 1117, I_FCLEX = 7323,
	I_FCMOVB = 1376, I_FCMOVBE = 1392, I_FCMOVE = 1384, I_FCMOVNB = 1445, I_FCMOVNBE = 1463,
	I_FCMOVNE = 1454, I_FCMOVNU = 1473, I_FCMOVU = 1401, I_FCOM = 1035, I_FCOMI = 1512,
	I_FCOMIP = 1623, I_FCOMP = 1041, I_FCOMPP = 1563, I_FCOS = 1311, I_FDECSTP = 1238,
	I_FDIV = 1061, I_FDIVP = 1594, I_FDIVR = 1067, I_FDIVRP = 1586, I_FEDISI = 1488,
	I_FEMMS = 574, I_FENI = 1482, I_FFREE = 1527, I_FIADD = 1317, I_FICOM = 1331,
	I_FICOMP = 1338, I_FIDIV = 1361, I_FIDIVR = 1368, I_FILD = 1418, I_FIMUL = 1324,
	I_FINCSTP = 1247, I_FINIT = 7338, I_FIST = 1432, I_FISTP = 1438, I_FISTTP = 1424,
	I_FISUB = 1346, I_FISUBR = 1353, I_FLD = 1074, I_FLD1 = 1141, I_FLDCW = 1098,
	I_FLDENV = 1090, I_FLDL2E = 1155, I_FLDL2T = 1147, I_FLDLG2 = 1170, I_FLDLN2 = 1178,
	I_FLDPI = 1163, I_FLDZ = 1186, I_FMUL = 1029, I_FMULP = 1556, I_FNCLEX = 7315,
	I_FNINIT = 7330, I_FNOP = 1111, I_FNSAVE = 7345, I_FNSTCW = 7300, I_FNSTENV = 7283,
	I_FNSTSW = 7360, I_FPATAN = 1213, I_FPREM = 1256, I_FPREM1 = 1230, I_FPTAN = 1206,
	I_FRNDINT = 1288, I_FRSTOR = 1519, I_FSAVE = 7353, I_FSCALE = 1297, I_FSETPM = 1496,
	I_FSIN = 1305, I_FSINCOS = 1279, I_FSQRT = 1272, I_FST = 1079, I_FSTCW = 7308,
	I_FSTENV = 7292, I_FSTP = 1084, I_FSTSW = 7368, I_FSUB = 1048, I_FSUBP = 1579,
	I_FSUBR = 1054, I_FSUBRP = 1571, I_FTST = 1129, I_FUCOM = 1534, I_FUCOMI = 1504,
	I_FUCOMIP = 1614, I_FUCOMP = 1541, I_FUCOMPP = 1409, I_FXAM = 1135, I_FXCH = 1105,
	I_FXRSTOR = 9926, I_FXRSTOR64 = 9935, I_FXSAVE = 9898, I_FXSAVE64 = 9906,
	I_FXTRACT = 1221, I_FYL2X = 1199, I_FYL2XP1 = 1263, I_GETSEC = 633, I_HADDPD = 4215,
	I_HADDPS = 4223, I_HLT = 482, I_HSUBPD = 4249, I_HSUBPS = 4257, I_IDIV = 1651,
	I_IMUL = 117, I_IN = 447, I_INC = 81, I_INS = 123, I_INSERTPS = 9581, I_INSERTQ = 4177,
	I_INT = 367, I_INT_3 = 360, I_INT1 = 476, I_INTO = 372, I_INVD = 555, I_INVEPT = 8318,
	I_INVLPG = 1727, I_INVLPGA = 1881, I_INVPCID = 8335, I_INVVPID = 8326, I_IRET = 378,
	I_JA = 166, I_JAE = 147, I_JB = 143, I_JBE = 161, I_JCXZ = 427, I_JECXZ = 433,
	I_JG = 202, I_JGE = 192, I_JL = 188, I_JLE = 197, I_JMP = 462, I_JMP_FAR = 467,
	I_JNO = 138, I_JNP = 183, I_JNS = 174, I_JNZ = 156, I_JO = 134, I_JP = 179,
	I_JRCXZ = 440, I_JS = 170, I_JZ = 152, I_LAHF = 289, I_LAR = 522, I_LDDQU = 7028,
	I_LDMXCSR = 9956, I_LDS = 335, I_LEA = 223, I_LEAVE = 347, I_LES = 330, I_LFENCE = 4299,
	I_LFS = 917, I_LGDT = 1703, I_LGS = 922, I_LIDT = 1709, I_LLDT = 1668, I_LMSW = 1721,
	I_LODS = 313, I_LOOP = 421, I_LOOPNZ = 406, I_LOOPZ = 414, I_LSL = 527, I_LSS = 907,
	I_LTR = 1674, I_LZCNT = 4397, I_MASKMOVDQU = 7153, I_MASKMOVQ = 7143, I_MAXPD = 3593,
	I_MAXPS = 3586, I_MAXSD = 3607, I_MAXSS = 3600, I_MFENCE = 4325, I_MINPD = 3473,
	I_MINPS = 3466, I_MINSD = 3487, I_MINSS = 3480, I_MONITOR = 1771, I_MOV = 218,
	I_MOVAPD = 2493, I_MOVAPS = 2485, I_MOVBE = 9285, I_MOVD = 3954, I_MOVDDUP = 2220,
	I_MOVDQ2Q = 6556, I_MOVDQA = 3980, I_MOVDQU = 3988, I_MOVHLPS = 2185, I_MOVHPD = 2379,
	I_MOVHPS = 2371, I_MOVLHPS = 2362, I_MOVLPD = 2202, I_MOVLPS = 2194, I_MOVMSKPD = 2849,
	I_MOVMSKPS = 2839, I_MOVNTDQ = 6883, I_MOVNTDQA = 7929, I_MOVNTI = 952, I_MOVNTPD = 2590,
	I_MOVNTPS = 2581, I_MOVNTQ = 6875, I_MOVNTSD = 2608, I_MOVNTSS = 2599, I_MOVQ = 3960,
	I_MOVQ2DQ = 6547, I_MOVS = 295, I_MOVSD = 2144, I_MOVSHDUP = 2387, I_MOVSLDUP = 2210,
	I_MOVSS = 2137, I_MOVSX = 939, I_MOVSXD = 10039, I_MOVUPD = 2129, I_MOVUPS = 2121,
	I_MOVZX = 927, I_MPSADBW = 9662, I_MUL = 1641, I_MULPD = 3204, I_MULPS = 3197,
	I_MULSD = 3218, I_MULSS = 3211, I_MWAIT = 1780, I_NEG = 1636, I_NOP = 581,
	I_NOT = 1631, I_OR = 27, I_ORPD = 3087, I_ORPS = 3081, I_OUT = 451, I_OUTS = 128,
	I_PABSB = 7722, I_PABSD = 7752, I_PABSW = 7737, I_PACKSSDW = 3883, I_PACKSSWB = 3715,
	I_PACKUSDW = 7950, I_PACKUSWB = 3793, I_PADDB = 7238, I_PADDD = 7268, I_PADDQ = 6515,
	I_PADDSB = 6964, I_PADDSW = 6981, I_PADDUSB = 6654, I_PADDUSW = 6673, I_PADDW = 7253,
	I_PALIGNR = 9444, I_PAND = 6641, I_PANDN = 6699, I_PAUSE = 10047, I_PAVGB = 6714,
	I_PAVGUSB = 2112, I_PAVGW = 6759, I_PBLENDVB = 7633, I_PBLENDW = 9425, I_PCLMULQDQ = 9681,
	I_PCMPEQB = 4077, I_PCMPEQD = 4115, I_PCMPEQQ = 7910, I_PCMPEQW = 4096, I_PCMPESTRI = 9760,
	I_PCMPESTRM = 9737, I_PCMPGTB = 3736, I_PCMPGTD = 3774, I_PCMPGTQ = 8121,
	I_PCMPGTW = 3755, I_PCMPISTRI = 9806, I_PCMPISTRM = 9783, I_PEXTRB = 9463,
	I_PEXTRD = 9480, I_PEXTRQ = 9488, I_PEXTRW = 6345, I_PF2ID = 1948, I_PF2IW = 1941,
	I_PFACC = 2062, I_PFADD = 2011, I_PFCMPEQ = 2069, I_PFCMPGE = 1972, I_PFCMPGT = 2018,
	I_PFMAX = 2027, I_PFMIN = 1981, I_PFMUL = 2078, I_PFNACC = 1955, I_PFPNACC = 1963,
	I_PFRCP = 1988, I_PFRCPIT1 = 2034, I_PFRCPIT2 = 2085, I_PFRSQIT1 = 2044, I_PFRSQRT = 1995,
	I_PFSUB = 2004, I_PFSUBR = 2054, I_PHADDD = 7409, I_PHADDSW = 7426, I_PHADDW = 7392,
	I_PHMINPOSUW = 8293, I_PHSUBD = 7485, I_PHSUBSW = 7502, I_PHSUBW = 7468, I_PI2FD = 1934,
	I_PI2FW = 1927, I_PINSRB = 9564, I_PINSRD = 9602, I_PINSRQ = 9610, I_PINSRW = 6328,
	I_PMADDUBSW = 7445, I_PMADDWD = 7107, I_PMAXSB = 8208, I_PMAXSD = 8225, I_PMAXSW = 6998,
	I_PMAXUB = 6682, I_PMAXUD = 8259, I_PMAXUW = 8242, I_PMINSB = 8140, I_PMINSD = 8157,
	I_PMINSW = 6936, I_PMINUB = 6624, I_PMINUD = 8191, I_PMINUW = 8174, I_PMOVMSKB = 6565,
	I_PMOVSXBD = 7788, I_PMOVSXBQ = 7809, I_PMOVSXBW = 7767, I_PMOVSXDQ = 7872,
	I_PMOVSXWD = 7830, I_PMOVSXWQ = 7851, I_PMOVZXBD = 8016, I_PMOVZXBQ = 8037,
	I_PMOVZXBW = 7995, I_PMOVZXDQ = 8100, I_PMOVZXWD = 8058, I_PMOVZXWQ = 8079,
	I_PMULDQ = 7893, I_PMULHRSW = 7572, I_PMULHRW = 2095, I_PMULHUW = 6774, I_PMULHW = 6793,
	I_PMULLD = 8276, I_PMULLW = 6530, I_PMULUDQ = 7088, I_POP = 22, I_POPA = 98,
	I_POPCNT = 4372, I_POPF = 277, I_POR = 6953, I_PREFETCH = 1906, I_PREFETCHNTA = 2436,
	I_PREFETCHT0 = 2449, I_PREFETCHT1 = 2461, I_PREFETCHT2 = 2473, I_PREFETCHW = 1916,
	I_PSADBW = 7126, I_PSHUFB = 7375, I_PSHUFD = 4022, I_PSHUFHW = 4030, I_PSHUFLW = 4039,
	I_PSHUFW = 4014, I_PSIGNB = 7521, I_PSIGND = 7555, I_PSIGNW = 7538, I_PSLLD = 7058,
	I_PSLLDQ = 9881, I_PSLLQ = 7073, I_PSLLW = 7043, I_PSRAD = 6744, I_PSRAW = 6729,
	I_PSRLD = 6485, I_PSRLDQ = 9864, I_PSRLQ = 6500, I_PSRLW = 6470, I_PSUBB = 7178,
	I_PSUBD = 7208, I_PSUBQ = 7223, I_PSUBSB = 6902, I_PSUBSW = 6919, I_PSUBUSB = 6586,
	I_PSUBUSW = 6605, I_PSUBW = 7193, I_PSWAPD = 2104, I_PTEST = 7663, I_PUNPCKHBW = 3814,
	I_PUNPCKHDQ = 3860, I_PUNPCKHQDQ = 3929, I_PUNPCKHWD = 3837, I_PUNPCKLBW = 3646,
	I_PUNPCKLDQ = 3692, I_PUNPCKLQDQ = 3904, I_PUNPCKLWD = 3669, I_PUSH = 16,
	I_PUSHA = 91, I_PUSHF = 270, I_PXOR = 7015, I_RCL = 977, I_RCPPS = 2987, I_RCPSS = 2994,
	I_RCR = 982, I_RDFSBASE = 9916, I_RDGSBASE = 9946, I_RDMSR = 600, I_RDPMC = 607,
	I_RDRAND = 10060, I_RDTSC = 593, I_RDTSCP = 1898, I_RET = 325, I_RETF = 354,
	I_ROL = 967, I_ROR = 972, I_ROUNDPD = 9330, I_ROUNDPS = 9311, I_ROUNDSD = 9368,
	I_ROUNDSS = 9349, I_RSM = 882, I_RSQRTPS = 2949, I_RSQRTSS = 2958, I_SAHF = 283,
	I_SAL = 997, I_SALC = 394, I_SAR = 1002, I_SBB = 36, I_SCAS = 319, I_SETA = 807,
	I_SETAE = 780, I_SETB = 774, I_SETBE = 800, I_SETG = 859, I_SETGE = 845, I_SETL = 839,
	I_SETLE = 852, I_SETNO = 767, I_SETNP = 832, I_SETNS = 819, I_SETNZ = 793,
	I_SETO = 761, I_SETP = 826, I_SETS = 813, I_SETZ = 787, I_SFENCE = 4355, I_SGDT = 1691,
	I_SHL = 987, I_SHLD = 876, I_SHR = 992, I_SHRD = 892, I_SHUFPD = 6370, I_SHUFPS = 6362,
	I_SIDT = 1697, I_SKINIT = 1873, I_SLDT = 1657, I_SMSW = 1715, I_SQRTPD = 2889,
	I_SQRTPS = 2881, I_SQRTSD = 2905, I_SQRTSS = 2897, I_STAC = 1793, I_STC = 497,
	I_STD = 517, I_STGI = 1861, I_STI = 507, I_STMXCSR = 9985, I_STOS = 307, I_STR = 1663,
	I_SUB = 51, I_SUBPD = 3413, I_SUBPS = 3406, I_SUBSD = 3427, I_SUBSS = 3420,
	I_SWAPGS = 1890, I_SYSCALL = 532, I_SYSENTER = 614, I_SYSEXIT = 624, I_SYSRET = 547,
	I_TEST = 206, I_TZCNT = 4385, I_UCOMISD = 2776, I_UCOMISS = 2767, I_UD2 = 569,
	I_UNPCKHPD = 2330, I_UNPCKHPS = 2320, I_UNPCKLPD = 2288, I_UNPCKLPS = 2278,
	I_VADDPD = 3173, I_VADDPS = 3165, I_VADDSD = 3189, I_VADDSS = 3181, I_VADDSUBPD = 6448,
	I_VADDSUBPS = 6459, I_VAESDEC = 9251, I_VAESDECLAST = 9272, I_VAESENC = 9209,
	I_VAESENCLAST = 9230, I_VAESIMC = 9192, I_VAESKEYGENASSIST = 9846, I_VANDNPD = 3072,
	I_VANDNPS = 3063, I_VANDPD = 3039, I_VANDPS = 3031, I_VBLENDPD = 9415, I_VBLENDPS = 9396,
	I_VBLENDVPD = 9715, I_VBLENDVPS = 9704, I_VBROADCASTF128 = 7706, I_VBROADCASTSD = 7692,
	I_VBROADCASTSS = 7678, I_VCMPEQPD = 5122, I_VCMPEQPS = 4720, I_VCMPEQSD = 5926,
	I_VCMPEQSS = 5524, I_VCMPEQ_OSPD = 5303, I_VCMPEQ_OSPS = 4901, I_VCMPEQ_OSSD = 6107,
	I_VCMPEQ_OSSS = 5705, I_VCMPEQ_UQPD = 5209, I_VCMPEQ_UQPS = 4807, I_VCMPEQ_UQSD = 6013,
	I_VCMPEQ_UQSS = 5611, I_VCMPEQ_USPD = 5412, I_VCMPEQ_USPS = 5010, I_VCMPEQ_USSD = 6216,
	I_VCMPEQ_USSS = 5814, I_VCMPFALSEPD = 5244, I_VCMPFALSEPS = 4842, I_VCMPFALSESD = 6048,
	I_VCMPFALSESS = 5646, I_VCMPFALSE_OSPD = 5453, I_VCMPFALSE_OSPS = 5051, I_VCMPFALSE_OSSD = 6257,
	I_VCMPFALSE_OSSS = 5855, I_VCMPGEPD = 5271, I_VCMPGEPS = 4869, I_VCMPGESD = 6075,
	I_VCMPGESS = 5673, I_VCMPGE_OQPD = 5483, I_VCMPGE_OQPS = 5081, I_VCMPGE_OQSD = 6287,
	I_VCMPGE_OQSS = 5885, I_VCMPGTPD = 5281, I_VCMPGTPS = 4879, I_VCMPGTSD = 6085,
	I_VCMPGTSS = 5683, I_VCMPGT_OQPD = 5496, I_VCMPGT_OQPS = 5094, I_VCMPGT_OQSD = 6300,
	I_VCMPGT_OQSS = 5898, I_VCMPLEPD = 5142, I_VCMPLEPS = 4740, I_VCMPLESD = 5946,
	I_VCMPLESS = 5544, I_VCMPLE_OQPD = 5329, I_VCMPLE_OQPS = 4927, I_VCMPLE_OQSD = 6133,
	I_VCMPLE_OQSS = 5731, I_VCMPLTPD = 5132, I_VCMPLTPS = 4730, I_VCMPLTSD = 5936,
	I_VCMPLTSS = 5534, I_VCMPLT_OQPD = 5316, I_VCMPLT_OQPS = 4914, I_VCMPLT_OQSD = 6120,
	I_VCMPLT_OQSS = 5718, I_VCMPNEQPD = 5165, I_VCMPNEQPS = 4763, I_VCMPNEQSD = 5969,
	I_VCMPNEQSS = 5567, I_VCMPNEQ_OQPD = 5257, I_VCMPNEQ_OQPS = 4855, I_VCMPNEQ_OQSD = 6061,
	I_VCMPNEQ_OQSS = 5659, I_VCMPNEQ_OSPD = 5469, I_VCMPNEQ_OSPS = 5067, I_VCMPNEQ_OSSD = 6273,
	I_VCMPNEQ_OSSS = 5871, I_VCMPNEQ_USPD = 5357, I_VCMPNEQ_USPS = 4955, I_VCMPNEQ_USSD = 6161,
	I_VCMPNEQ_USSS = 5759, I_VCMPNGEPD = 5222, I_VCMPNGEPS = 4820, I_VCMPNGESD = 6026,
	I_VCMPNGESS = 5624, I_VCMPNGE_UQPD = 5425, I_VCMPNGE_UQPS = 5023, I_VCMPNGE_UQSD = 6229,
	I_VCMPNGE_UQSS = 5827, I_VCMPNGTPD = 5233, I_VCMPNGTPS = 4831, I_VCMPNGTSD = 6037,
	I_VCMPNGTSS = 5635, I_VCMPNGT_UQPD = 5439, I_VCMPNGT_UQPS = 5037, I_VCMPNGT_UQSD = 6243,
	I_VCMPNGT_UQSS = 5841, I_VCMPNLEPD = 5187, I_VCMPNLEPS = 4785, I_VCMPNLESD = 5991,
	I_VCMPNLESS = 5589, I_VCMPNLE_UQPD = 5385, I_VCMPNLE_UQPS = 4983, I_VCMPNLE_UQSD = 6189,
	I_VCMPNLE_UQSS = 5787, I_VCMPNLTPD = 5176, I_VCMPNLTPS = 4774, I_VCMPNLTSD = 5980,
	I_VCMPNLTSS = 5578, I_VCMPNLT_UQPD = 5371, I_VCMPNLT_UQPS = 4969, I_VCMPNLT_UQSD = 6175,
	I_VCMPNLT_UQSS = 5773, I_VCMPORDPD = 5198, I_VCMPORDPS = 4796, I_VCMPORDSD = 6002,
	I_VCMPORDSS = 5600, I_VCMPORD_SPD = 5399, I_VCMPORD_SPS = 4997, I_VCMPORD_SSD = 6203,
	I_VCMPORD_SSS = 5801, I_VCMPTRUEPD = 5291, I_VCMPTRUEPS = 4889, I_VCMPTRUESD = 6095,
	I_VCMPTRUESS = 5693, I_VCMPTRUE_USPD = 5509, I_VCMPTRUE_USPS = 5107, I_VCMPTRUE_USSD = 6313,
	I_VCMPTRUE_USSS = 5911, I_VCMPUNORDPD = 5152, I_VCMPUNORDPS = 4750, I_VCMPUNORDSD = 5956,
	I_VCMPUNORDSS = 5554, I_VCMPUNORD_SPD = 5342, I_VCMPUNORD_SPS = 4940, I_VCMPUNORD_SSD = 6146,
	I_VCMPUNORD_SSS = 5744, I_VCOMISD = 2830, I_VCOMISS = 2821, I_VCVTDQ2PD = 6853,
	I_VCVTDQ2PS = 3372, I_VCVTPD2DQ = 6864, I_VCVTPD2PS = 3308, I_VCVTPS2DQ = 3383,
	I_VCVTPS2PD = 3297, I_VCVTSD2SI = 2756, I_VCVTSD2SS = 3330, I_VCVTSI2SD = 2570,
	I_VCVTSI2SS = 2559, I_VCVTSS2SD = 3319, I_VCVTSS2SI = 2745, I_VCVTTPD2DQ = 6841,
	I_VCVTTPS2DQ = 3394, I_VCVTTSD2SI = 2693, I_VCVTTSS2SI = 2681, I_VDIVPD = 3562,
	I_VDIVPS = 3554, I_VDIVSD = 3578, I_VDIVSS = 3570, I_VDPPD = 9655, I_VDPPS = 9642,
	I_VERR = 1679, I_VERW = 1685, I_VEXTRACTF128 = 9550, I_VEXTRACTPS = 9525,
	I_VFMADD132PD = 8421, I_VFMADD132PS = 8408, I_VFMADD132SD = 8447, I_VFMADD132SS = 8434,
	I_VFMADD213PD = 8701, I_VFMADD213PS = 8688, I_VFMADD213SD = 8727, I_VFMADD213SS = 8714,
	I_VFMADD231PD = 8981, I_VFMADD231PS = 8968, I_VFMADD231SD = 9007, I_VFMADD231SS = 8994,
	I_VFMADDSUB132PD = 8360, I_VFMADDSUB132PS = 8344, I_VFMADDSUB213PD = 8640,
	I_VFMADDSUB213PS = 8624, I_VFMADDSUB231PD = 8920, I_VFMADDSUB231PS = 8904,
	I_VFMSUB132PD = 8473, I_VFMSUB132PS = 8460, I_VFMSUB132SD = 8499, I_VFMSUB132SS = 8486,
	I_VFMSUB213PD = 8753, I_VFMSUB213PS = 8740, I_VFMSUB213SD = 8779, I_VFMSUB213SS = 8766,
	I_VFMSUB231PD = 9033, I_VFMSUB231PS = 9020, I_VFMSUB231SD = 9059, I_VFMSUB231SS = 9046,
	I_VFMSUBADD132PD = 8392, I_VFMSUBADD132PS = 8376, I_VFMSUBADD213PD = 8672,
	I_VFMSUBADD213PS = 8656, I_VFMSUBADD231PD = 8952, I_VFMSUBADD231PS = 8936,
	I_VFNMADD132PD = 8526, I_VFNMADD132PS = 8512, I_VFNMADD132SD = 8554, I_VFNMADD132SS = 8540,
	I_VFNMADD213PD = 8806, I_VFNMADD213PS = 8792, I_VFNMADD213SD = 8834, I_VFNMADD213SS = 8820,
	I_VFNMADD231PD = 9086, I_VFNMADD231PS = 9072, I_VFNMADD231SD = 9114, I_VFNMADD231SS = 9100,
	I_VFNMSUB132PD = 8582, I_VFNMSUB132PS = 8568, I_VFNMSUB132SD = 8610, I_VFNMSUB132SS = 8596,
	I_VFNMSUB213PD = 8862, I_VFNMSUB213PS = 8848, I_VFNMSUB213SD = 8890, I_VFNMSUB213SS = 8876,
	I_VFNMSUB231PD = 9142, I_VFNMSUB231PS = 9128, I_VFNMSUB231SD = 9170, I_VFNMSUB231SS = 9156,
	I_VHADDPD = 4231, I_VHADDPS = 4240, I_VHSUBPD = 4265, I_VHSUBPS = 4274, I_VINSERTF128 = 9537,
	I_VINSERTPS = 9591, I_VLDDQU = 7035, I_VLDMXCSR = 9975, I_VMASKMOVDQU = 7165,
	I_VMASKMOVPD = 7983, I_VMASKMOVPS = 7971, I_VMAXPD = 3622, I_VMAXPS = 3614,
	I_VMAXSD = 3638, I_VMAXSS = 3630, I_VMCALL = 1735, I_VMCLEAR = 10023, I_VMFUNC = 1815,
	I_VMINPD = 3502, I_VMINPS = 3494, I_VMINSD = 3518, I_VMINSS = 3510, I_VMLAUNCH = 1743,
	I_VMLOAD = 1845, I_VMMCALL = 1836, I_VMOVAPD = 2510, I_VMOVAPS = 2501, I_VMOVD = 3966,
	I_VMOVDDUP = 2268, I_VMOVDQA = 3996, I_VMOVDQU = 4005, I_VMOVHLPS = 2229,
	I_VMOVHPD = 2416, I_VMOVHPS = 2407, I_VMOVLHPS = 2397, I_VMOVLPD = 2248, I_VMOVLPS = 2239,
	I_VMOVMSKPD = 2870, I_VMOVMSKPS = 2859, I_VMOVNTDQ = 6892, I_VMOVNTDQA = 7939,
	I_VMOVNTPD = 2627, I_VMOVNTPS = 2617, I_VMOVQ = 3973, I_VMOVSD = 2177, I_VMOVSHDUP = 2425,
	I_VMOVSLDUP = 2257, I_VMOVSS = 2169, I_VMOVUPD = 2160, I_VMOVUPS = 2151, I_VMPSADBW = 9671,
	I_VMPTRLD = 10014, I_VMPTRST = 6419, I_VMREAD = 4162, I_VMRESUME = 1753, I_VMRUN = 1829,
	I_VMSAVE = 1853, I_VMULPD = 3233, I_VMULPS = 3225, I_VMULSD = 3249, I_VMULSS = 3241,
	I_VMWRITE = 4186, I_VMXOFF = 1763, I_VMXON = 10032, I_VORPD = 3100, I_VORPS = 3093,
	I_VPABSB = 7729, I_VPABSD = 7759, I_VPABSW = 7744, I_VPACKSSDW = 3893, I_VPACKSSWB = 3725,
	I_VPACKUSDW = 7960, I_VPACKUSWB = 3803, I_VPADDB = 7245, I_VPADDD = 7275,
	I_VPADDQ = 6522, I_VPADDSB = 6972, I_VPADDSW = 6989, I_VPADDUSW = 6663, I_VPADDW = 7260,
	I_VPALIGNR = 9453, I_VPAND = 6647, I_VPANDN = 6706, I_VPAVGB = 6721, I_VPAVGW = 6766,
	I_VPBLENDVB = 9726, I_VPBLENDW = 9434, I_VPCLMULQDQ = 9692, I_VPCMPEQB = 4086,
	I_VPCMPEQD = 4124, I_VPCMPEQQ = 7919, I_VPCMPEQW = 4105, I_VPCMPESTRI = 9771,
	I_VPCMPESTRM = 9748, I_VPCMPGTB = 3745, I_VPCMPGTD = 3783, I_VPCMPGTQ = 8130,
	I_VPCMPGTW = 3764, I_VPCMPISTRI = 9817, I_VPCMPISTRM = 9794, I_VPERM2F128 = 9299,
	I_VPERMILPD = 7604, I_VPERMILPS = 7593, I_VPEXTRB = 9471, I_VPEXTRD = 9496,
	I_VPEXTRQ = 9505, I_VPEXTRW = 6353, I_VPHADDD = 7417, I_VPHADDSW = 7435, I_VPHADDW = 7400,
	I_VPHMINPOSUW = 8305, I_VPHSUBD = 7493, I_VPHSUBSW = 7511, I_VPHSUBW = 7476,
	I_VPINSRB = 9572, I_VPINSRD = 9618, I_VPINSRQ = 9627, I_VPINSRW = 6336, I_VPMADDUBSW = 7456,
	I_VPMADDWD = 7116, I_VPMAXSB = 8216, I_VPMAXSD = 8233, I_VPMAXSW = 7006, I_VPMAXUB = 6690,
	I_VPMAXUD = 8267, I_VPMAXUW = 8250, I_VPMINSB = 8148, I_VPMINSD = 8165, I_VPMINSW = 6944,
	I_VPMINUB = 6632, I_VPMINUD = 8199, I_VPMINUW = 8182, I_VPMOVMSKB = 6575,
	I_VPMOVSXBD = 7798, I_VPMOVSXBQ = 7819, I_VPMOVSXBW = 7777, I_VPMOVSXDQ = 7882,
	I_VPMOVSXWD = 7840, I_VPMOVSXWQ = 7861, I_VPMOVZXBD = 8026, I_VPMOVZXBQ = 8047,
	I_VPMOVZXBW = 8005, I_VPMOVZXDQ = 8110, I_VPMOVZXWD = 8068, I_VPMOVZXWQ = 8089,
	I_VPMULDQ = 7901, I_VPMULHRSW = 7582, I_VPMULHUW = 6783, I_VPMULHW = 6801,
	I_VPMULLD = 8284, I_VPMULLW = 6538, I_VPMULUDQ = 7097, I_VPOR = 6958, I_VPSADBW = 7134,
	I_VPSHUFB = 7383, I_VPSHUFD = 4048, I_VPSHUFHW = 4057, I_VPSHUFLW = 4067,
	I_VPSIGNB = 7529, I_VPSIGND = 7563, I_VPSIGNW = 7546, I_VPSLLD = 7065, I_VPSLLDQ = 9889,
	I_VPSLLQ = 7080, I_VPSLLW = 7050, I_VPSRAD = 6751, I_VPSRAW = 6736, I_VPSRLD = 6492,
	I_VPSRLDQ = 9872, I_VPSRLQ = 6507, I_VPSRLW = 6477, I_VPSUBB = 7185, I_VPSUBD = 7215,
	I_VPSUBQ = 7230, I_VPSUBSB = 6910, I_VPSUBSW = 6927, I_VPSUBUSB = 6595, I_VPSUBUSW = 6614,
	I_VPSUBW = 7200, I_VPTEST = 7670, I_VPUNPCKHBW = 3825, I_VPUNPCKHDQ = 3871,
	I_VPUNPCKHQDQ = 3941, I_VPUNPCKHWD = 3848, I_VPUNPCKLBW = 3657, I_VPUNPCKLDQ = 3703,
	I_VPUNPCKLQDQ = 3916, I_VPUNPCKLWD = 3680, I_VPXOR = 7021, I_VRCPPS = 3001,
	I_VRCPSS = 3009, I_VROUNDPD = 9339, I_VROUNDPS = 9320, I_VROUNDSD = 9377,
	I_VROUNDSS = 9358, I_VRSQRTPS = 2967, I_VRSQRTSS = 2977, I_VSHUFPD = 6387,
	I_VSHUFPS = 6378, I_VSQRTPD = 2922, I_VSQRTPS = 2913, I_VSQRTSD = 2940, I_VSQRTSS = 2931,
	I_VSTMXCSR = 10004, I_VSUBPD = 3442, I_VSUBPS = 3434, I_VSUBSD = 3458, I_VSUBSS = 3450,
	I_VTESTPD = 7624, I_VTESTPS = 7615, I_VUCOMISD = 2795, I_VUCOMISS = 2785,
	I_VUNPCKHPD = 2351, I_VUNPCKHPS = 2340, I_VUNPCKLPD = 2309, I_VUNPCKLPS = 2298,
	I_VXORPD = 3129, I_VXORPS = 3121, I_VZEROALL = 4152, I_VZEROUPPER = 4140,
	I_WAIT = 10054, I_WBINVD = 561, I_WRFSBASE = 9965, I_WRGSBASE = 9994, I_WRMSR = 586,
	I_XABORT = 1007, I_XADD = 946, I_XBEGIN = 1015, I_XCHG = 212, I_XEND = 1823,
	I_XGETBV = 1799, I_XLAT = 400, I_XOR = 61, I_XORPD = 3114, I_XORPS = 3107,
	I_XRSTOR = 4307, I_XRSTOR64 = 4315, I_XSAVE = 4283, I_XSAVE64 = 4290, I_XSAVEOPT = 4333,
	I_XSAVEOPT64 = 4343, I_XSETBV = 1807, I__3DNOW = 10068
} _InstructionType;

typedef enum {
	R_RAX, R_RCX, R_RDX, R_RBX, R_RSP, R_RBP, R_RSI, R_RDI, R_R8, R_R9, R_R10, R_R11, R_R12, R_R13, R_R14, R_R15,
	R_EAX, R_ECX, R_EDX, R_EBX, R_ESP, R_EBP, R_ESI, R_EDI, R_R8D, R_R9D, R_R10D, R_R11D, R_R12D, R_R13D, R_R14D, R_R15D,
	R_AX, R_CX, R_DX, R_BX, R_SP, R_BP, R_SI, R_DI, R_R8W, R_R9W, R_R10W, R_R11W, R_R12W, R_R13W, R_R14W, R_R15W,
	R_AL, R_CL, R_DL, R_BL, R_AH, R_CH, R_DH, R_BH, R_R8B, R_R9B, R_R10B, R_R11B, R_R12B, R_R13B, R_R14B, R_R15B,
	R_SPL, R_BPL, R_SIL, R_DIL,
	R_ES, R_CS, R_SS, R_DS, R_FS, R_GS,
	R_RIP,
	R_ST0, R_ST1, R_ST2, R_ST3, R_ST4, R_ST5, R_ST6, R_ST7,
	R_MM0, R_MM1, R_MM2, R_MM3, R_MM4, R_MM5, R_MM6, R_MM7,
	R_XMM0, R_XMM1, R_XMM2, R_XMM3, R_XMM4, R_XMM5, R_XMM6, R_XMM7, R_XMM8, R_XMM9, R_XMM10, R_XMM11, R_XMM12, R_XMM13, R_XMM14, R_XMM15,
	R_YMM0, R_YMM1, R_YMM2, R_YMM3, R_YMM4, R_YMM5, R_YMM6, R_YMM7, R_YMM8, R_YMM9, R_YMM10, R_YMM11, R_YMM12, R_YMM13, R_YMM14, R_YMM15,
	R_CR0, R_UNUSED0, R_CR2, R_CR3, R_CR4, R_UNUSED1, R_UNUSED2, R_UNUSED3, R_CR8,
	R_DR0, R_DR1, R_DR2, R_DR3, R_UNUSED4, R_UNUSED5, R_DR6, R_DR7
} _RegisterType;

#endif /* MNEMONICS_H */
