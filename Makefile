
CC = icc
CFLAGS = -Wall -m64 -O3 
CXX = icpc
CXXFLAGS = -Wall -m64 -O3 
CUDAHOME = /usr/local/encap/cuda-5.0
CUDACC = $(CUDAHOME)/bin/nvcc
CUDACCFLAGS = -m64 -arch sm_21
CUDALIBS = -Bdynamic -Wl,-rpath,$(CUDAHOME)/lib64 -L$(CUDAHOME)/lib64 -lcudart 
ISPC = ispc
ISPCFLAGS = -O2 --arch=x86-64 

# The performance difference between these two options should be tested at some point
#ISPCFLAGS +=  --target=avx1-i32x8
#ISPCFLAGS +=  --target=avx1-i32x16
# Likewise, these two options for SSE2
#ISPCFLAGS +=  --target=sse2-i32x4
#ISPCFLAGS +=  --target=sse2-i32x8

OBJS_AVX = kernelispc_ispc_avx.o testHarness_avx.o WKFUtils.o #cudaFloat.o
OBJS_SSE2 = kernelispc_ispc_sse2.o testHarness_sse2.o WKFUtils.o #cudaFloat.o
ISPCDEPS_AVX = kernelispc_ispc_avx.h  # automatically generated below
ISPCDEPS_SSE2 = kernelispc_ispc_sse2.h  # automatically generated below

.SUFFIXES: .C .c .cu ..c .i .o .ispc 

%.o: %.cu $(DEPS)
	$(CUDACC) $(CUDACCFLAGS) -c $<

%.o: %.c $(DEPS)
	$(CC) $(CCFLAGS) -c $<

%.o: %.C $(DEPS)
	$(CXX) $(CXXFLAGS) -c $< 

%_ispc_avx.h %_ispc_avx.o: %.ispc
	$(ISPC) $(ISPCFLAGS) --target=avx1-i32x8 $< -o $*_ispc_avx.o -h $*_ispc_avx.h

%_ispc_sse2.h %_ispc_sse2.o: %.ispc
	$(ISPC) $(ISPCFLAGS) --target=sse2-i32x4 $< -o $*_ispc_sse2.o -h $*_ispc_sse2.h

%_avx.o: %.C $(ISPCDEPS_AVX)
	$(CXX) $(CXXFLAGS) -mavx -o $@ -c $<

%_sse2.o: %.C $(ISPCDEPS_SSE2)
	$(CXX) $(CXXFLAGS) -msse2 -o $@ -c $<

default : all
all : testHarnessAVX testHarnessSSE2

testHarnessAVX : $(OBJS_AVX) 
	$(CXX) $(CXXFLAGS) -mavx $(OBJS_AVX) -o $@ 

testHarnessSSE2 : $(OBJS_SSE2) 
	$(CXX) $(CXXFLAGS) -msse2 $(OBJS_SSE2) -o $@ 

runSerial : testHarnessSSE2
	./testHarnessSSE2 serial

runSSE2_INTRIN : testHarnessSSE2
	./testHarnessSSE2 SSE2

runAVX_INTRIN : testHarnessAVX
	./testHarnessAVX AVX

runSSE2_ISPC : testHarnessSSE2
	./testHarnessSSE2 ISPC

runAVX_ISPC : testHarnessAVX
	./testHarnessAVX ISPC

runALL : testHarnessSSE2 testHarnessAVX
	echo "SSE2 using intrinsics\n\n"
	make runSSE2_INTRIN
	echo "SSE2 using ISPC\n\n"
	make runSSE2_ISPC
	echo "AVX using intrinsics\n\n"
	make runAVX_INTRIN
	echo "AVX using ISPC\n\n"
	make runAVX_ISPC

clean:	
	rm -f *.o $(ISPCDEPS_AVX) $(ISPCDEPS_SSE2) testHarnessAVX testHarnessSSE2 ppms/*.ppm ppms/*.jpg *~ 
