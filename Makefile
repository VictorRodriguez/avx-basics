static_flags = -static
src_dir = src/
build_dir = build/
exp_dir = src/experiments/
imgs_dir = docker_images/templates


MKDIR  := mkdir -p
CC_HSW := gcc -O3 -march=haswell
CC_SKX := gcc -O3 -march=skylake-avx512
CC_ICX := gcc -O3 -march=icelake-server
CC_KN := gcc -O3 -march=skylake-avx512 -mavx5124vnniw
CC_static := $(CC) $(static_flags)
CC_HSW_static := $(CC_HSW) $(static_flags)
CC_AMX := /install-dir/bin/gcc



all:
	$(MKDIR) $(build_dir)
	$(CC) $(src_dir)basic_add_asm.c -o $(build_dir)basic_add_asm
	$(CC) $(src_dir)basic_sub_asm.c -o $(build_dir)basic_sub_asm
	$(CC) $(src_dir)basic_mul_asm.c -o $(build_dir)basic_mul_asm
	$(CC) $(src_dir)basic_div_asm.c -o $(build_dir)basic_div_asm
	$(CC_HSW) $(src_dir)basic_add_avx2.c -o $(build_dir)basic_add_avx2
	$(CC_HSW) $(src_dir)basic_maddubs_epi.c -o $(build_dir)basic_maddubs_epi
	$(CC_HSW) $(src_dir)stress_add_avx2.c -o $(build_dir)stress_add_avx2

static_check:
	cppcheck --enable=all --inconclusive --suppress=unusedFunction src/*

avx512:
	$(MKDIR) $(build_dir)
	$(CC_SKX) $(src_dir)basic_add_avx512.c -o $(build_dir)basic_add_avx512
	$(CC_SKX) $(src_dir)basic_add_d_avx512.c -o $(build_dir)basic_add_d_avx512
	$(CC_SKX) $(src_dir)basic_add_i_avx512.c -o $(build_dir)basic_add_i_avx512
	$(CC_SKX) $(src_dir)stress_add_avx512.c -o $(build_dir)stress_add_avx512
	$(CC_SKX) $(src_dir)stress_add_d_avx512.c -o $(build_dir)stress_add_d_avx512
	$(CC_SKX) $(src_dir)stress_add_i_avx512.c -o $(build_dir)stress_add_i_avx512

vnni:
	$(MKDIR) $(build_dir)
	$(CC_HSW) $(src_dir)basic_vpmaddwd.c -o $(build_dir)basic_vpmaddwd
	$(CC_ICX) $(src_dir)basic_dpbusd_vnni.c -o $(build_dir)simple_dpbusd_vnni
	$(CC_ICX) $(src_dir)stress_dpbusd_vnni.c -o $(build_dir)stress_dpbusd_vnni
	cp $(build_dir)simple_dpbusd_vnni $(imgs_dir)

vnni_container: vnni
	cd $(imgs_dir) && docker build -t vnni_test .

ud_test:
	$(MKDIR) $(build_dir)
	$(CC_SKX)   $(ud2_dir)add_avx512_ud2.c -o $(build_dir)add_avx512_ud2
	$(CC_SKX_T) $(ud2_dir)add_avx512_t_ud2.c -o $(build_dir)add_avx512_t_ud2
	$(CC_SKX_T) $(ud2_dir)add_avx_mthread.c -o $(build_dir)add_avx_mthread

experiments:
	$(MKDIR) $(build_dir)
	$(CC_KN)  $(exp_dir)4dpwssd_epi32.c -o $(build_dir)4dpwssd_epi32
	$(CC_HSW) $(exp_dir)test_matrix_mul.c -o $(build_dir)test_matrix_mul
	$(CC_HSW) $(exp_dir)matrix_mul.c -o $(build_dir)matrix_mul

static:
	$(MKDIR) $(build_dir)
	$(CC_static) $(src_dir)basic_add_asm.c -o $(build_dir)basic_add_asm
	$(CC_static) $(src_dir)basic_sub_asm.c -o $(build_dir)basic_sub_asm
	$(CC_static) $(src_dir)basic_mul_asm.c -o $(build_dir)basic_mul_asm
	$(CC_static) $(src_dir)basic_div_asm.c -o $(build_dir)basic_div_asm
	$(CC_HSW_static) $(src_dir)basic_add_avx2.c -o $(build_dir)basic_add_avx2
	$(CC_HSW_static) $(src_dir)stress_add_avx2.c -o $(build_dir)stress_add_avx2

bfloat16:
	clang $(src_dir)basic_bfloat.c -o $(build_dir)basic_bfloat -march=cooperlake
	clang $(src_dir)basic_bfloat_mm512.c -o $(build_dir)basic_bfloat_mm512 -march=cooperlake

crypto: ifma gfni vaes clmul

crypto_container: clean crypto
	cp $(build_dir)/* $(imgs_dir)
	cd $(imgs_dir) && docker build -t crypto_test -f Dockerfile.crypto .

ifma:
	$(CC_ICX) $(src_dir)basic_vpmadd52huq_i_avx512.c -o $(build_dir)basic_vpmadd52huq_i_avx512
	$(CC_ICX) $(src_dir)basic_vpmadd52luq_i_avx512.c -o $(build_dir)basic_vpmadd52luq_i_avx512

gfni:
	$(CC_ICX) $(src_dir)basic_gf2p8affineinv_epi64_epi8.c -o $(build_dir)basic_gf2p8affineinv_epi64_epi8
	$(CC_ICX) $(src_dir)basic_gf2p8affine_epi64_epi8.c -o $(build_dir)basic_gf2p8affine_epi64_epi8
	$(CC_ICX) $(src_dir)basic_gf2p8mul_epi8.c -o $(build_dir)basic_gf2p8mul_epi8

vaes:
	$(CC_ICX) $(src_dir)basic_mm256_aesdec_epi128.c -o $(build_dir)basic_mm256_aesdec_epi128
	$(CC_ICX) $(src_dir)basic_mm256_aesdeclast_epi128.c -o $(build_dir)basic_mm256_aesdeclast_epi128
	$(CC_ICX) $(src_dir)basic_mm256_aesenc_epi128.c -o $(build_dir)basic__mm256_aesenc_epi128
	$(CC_ICX) $(src_dir)basic_mm256_aesenclast_epi128.c -o $(build_dir)basic_mm256_aesenclast_epi128

clmul:
	$(CC_ICX) $(src_dir)basic_mm256_clmulepi64_epi128.c -o $(build_dir)basic_mm256_clmulepi64_epi128
	$(CC_ICX) $(src_dir)basic_mm_clmulepi64_si128.c -o $(build_dir)basic_mm_clmulepi64_si128

amx:
	@echo "Install latest version of master gcc or gcc 11"
	$(CC_AMX) $(src_dir)mamx_basic.c -O2 -mamx-tile -o $(build_dir)mamx_basic
	$(CC_AMX) $(src_dir)amxtile-2.c -O2 -mamx-tile -o $(build_dir)amxtile-2
	$(CC_AMX) $(src_dir)amxbf16-dpbf16ps-2.c -O2 -mamx-tile -mamx-bf16 -o $(build_dir)bf16_dpbf16p
	$(CC_AMX) $(src_dir)amxint8-dpbsud-2.c -O2 -mamx-tile -mamx-int8 -o $(build_dir)amxint8-dpbsud
	$(CC_AMX) $(src_dir)amxint8-dpbssd-2.c -O2 -mamx-tile -mamx-int8 -o $(build_dir)amxint8-dpbssd
	$(CC_AMX) $(src_dir)amxint8-dpbusd-2.c -O2 -mamx-tile -mamx-int8 -o $(build_dir)amxint8-dpbusd
	$(CC_AMX) $(src_dir)amxint8-dpbusd-2.c -O2 -mamx-tile -mamx-int8 -o $(build_dir)amxint8-dpbuud
	$(CC_AMX) $(src_dir)amxint8-dpbssd-fixed-time-2.c -O2 -mamx-tile -mamx-int8 -o $(build_dir)amxint8-dpbssd-fixed-time
	$(CC_AMX) $(src_dir)amxint8-dpbssd-fixed-loops-2.c -O2 -mamx-tile -mamx-int8 -o $(build_dir)amxint8-dpbssd-fixed-loops-2

check:
	./$(build_dir)basic_add_asm
	./$(build_dir)basic_sub_asm
	./$(build_dir)basic_mul_asm
	./$(build_dir)basic_div_asm
	./$(build_dir)basic_add_avx2

release:
	mkdir -p avx-bench-basic
	cp run-all.sh avx-bench-basic
	cp -rf build/ avx-bench-basic/
	tar -czvf avx-bench-basic.tar.gz avx-bench-basic/

clean-release:
	rm -rf avx-bench-basic*

clean:
	@rm -rf build/*
