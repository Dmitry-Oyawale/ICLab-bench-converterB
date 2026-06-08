module aes_inv_cipher_top(clk, rst, kld, ld, done, key, text_in, text_out );
input		clk, rst;
input		kld, ld;
output		done;
input	[127:0]	key;
input	[127:0]	text_in;
output	[127:0]	text_out;

////////////////////////////////////////////////////////////////////
//
// Local Wires
//

wire	[31:0]	wk0, wk1, wk2, wk3;
reg	[31:0]	w0, w1, w2, w3;
reg	[127:0]	text_in_r;
reg	[127:0]	text_out;
reg	[7:0]	sa00, sa01, sa02, sa03;
reg	[7:0]	sa10, sa11, sa12, sa13;
reg	[7:0]	sa20, sa21, sa22, sa23;
reg	[7:0]	sa30, sa31, sa32, sa33;
wire	[7:0]	sa00_next, sa01_next, sa02_next, sa03_next;
wire	[7:0]	sa10_next, sa11_next, sa12_next, sa13_next;
wire	[7:0]	sa20_next, sa21_next, sa22_next, sa23_next;
wire	[7:0]	sa30_next, sa31_next, sa32_next, sa33_next;
wire	[7:0]	sa00_sub, sa01_sub, sa02_sub, sa03_sub;
wire	[7:0]	sa10_sub, sa11_sub, sa12_sub, sa13_sub;
wire	[7:0]	sa20_sub, sa21_sub, sa22_sub, sa23_sub;
wire	[7:0]	sa30_sub, sa31_sub, sa32_sub, sa33_sub;
wire	[7:0]	sa00_sr, sa01_sr, sa02_sr, sa03_sr;
wire	[7:0]	sa10_sr, sa11_sr, sa12_sr, sa13_sr;
wire	[7:0]	sa20_sr, sa21_sr, sa22_sr, sa23_sr;
wire	[7:0]	sa30_sr, sa31_sr, sa32_sr, sa33_sr;
wire	[7:0]	sa00_ark, sa01_ark, sa02_ark, sa03_ark;
wire	[7:0]	sa10_ark, sa11_ark, sa12_ark, sa13_ark;
wire	[7:0]	sa20_ark, sa21_ark, sa22_ark, sa23_ark;
wire	[7:0]	sa30_ark, sa31_ark, sa32_ark, sa33_ark;
reg		ld_r, go, done;
reg	[3:0]	dcnt;

////////////////////////////////////////////////////////////////////
//
// Misc Logic
//解密过程的轮控制：
//复位时计数器清零；完成时计数器清零；加载新数据时计数器置1；
//go信号有效时每周期递增
//计数到11且不在加载状态时置位完成信号

always @(posedge clk)
	if(!rst)	dcnt <=  4'h0;
	else
	if(done)	dcnt <=  4'h0;
	else
	if(ld)		dcnt <=  4'h1;
	else
	if(go)		dcnt <=  dcnt + 4'h1;

always @(posedge clk)	done <=  (dcnt==4'hb) & !ld;

always @(posedge clk)
	if(!rst)	go <=  1'b0;
	else
	if(ld)		go <=  1'b1;
	else
	if(done)	go <=  1'b0;

always @(posedge clk)	if(ld)	text_in_r <=  text_in;

always @(posedge clk)	ld_r <=  ld;

////////////////////////////////////////////////////////////////////
//
// Initial Permutation
//

always @(posedge clk)	sa33 <=  ld_r ? text_in_r[007:000] ^ w3[07:00] : sa33_next;
always @(posedge clk)	sa23 <=  ld_r ? text_in_r[015:008] ^ w3[15:08] : sa23_next;
always @(posedge clk)	sa13 <=  ld_r ? text_in_r[023:016] ^ w3[23:16] : sa13_next;
always @(posedge clk)	sa03 <=  ld_r ? text_in_r[031:024] ^ w3[31:24] : sa03_next;
always @(posedge clk)	sa32 <=  ld_r ? text_in_r[039:032] ^ w2[07:00] : sa32_next;
always @(posedge clk)	sa22 <=  ld_r ? text_in_r[047:040] ^ w2[15:08] : sa22_next;
always @(posedge clk)	sa12 <=  ld_r ? text_in_r[055:048] ^ w2[23:16] : sa12_next;
always @(posedge clk)	sa02 <=  ld_r ? text_in_r[063:056] ^ w2[31:24] : sa02_next;
always @(posedge clk)	sa31 <=  ld_r ? text_in_r[071:064] ^ w1[07:00] : sa31_next;
always @(posedge clk)	sa21 <=  ld_r ? text_in_r[079:072] ^ w1[15:08] : sa21_next;
always @(posedge clk)	sa11 <=  ld_r ? text_in_r[087:080] ^ w1[23:16] : sa11_next;
always @(posedge clk)	sa01 <=  ld_r ? text_in_r[095:088] ^ w1[31:24] : sa01_next;
always @(posedge clk)	sa30 <=  ld_r ? text_in_r[103:096] ^ w0[07:00] : sa30_next;
always @(posedge clk)	sa20 <=  ld_r ? text_in_r[111:104] ^ w0[15:08] : sa20_next;
always @(posedge clk)	sa10 <=  ld_r ? text_in_r[119:112] ^ w0[23:16] : sa10_next;
always @(posedge clk)	sa00 <=  ld_r ? text_in_r[127:120] ^ w0[31:24] : sa00_next;

////////////////////////////////////////////////////////////////////
//
// Round Permutations
//
//逆向轮变换实现
//1.逆向行位移变换
assign sa00_sr = sa00;//0行不移位
assign sa01_sr = sa01;
assign sa02_sr = sa02;
assign sa03_sr = sa03;
assign sa10_sr = sa13;//1行右移3字节
assign sa11_sr = sa10;
assign sa12_sr = sa11;
assign sa13_sr = sa12;
assign sa20_sr = sa22;//2行右移2字节
assign sa21_sr = sa23;
assign sa22_sr = sa20;
assign sa23_sr = sa21;
assign sa30_sr = sa31;//3行右移1字节
assign sa31_sr = sa32;
assign sa32_sr = sa33;
assign sa33_sr = sa30;

//2.轮密钥加
assign sa00_ark = sa00_sub ^ w0[31:24];
assign sa01_ark = sa01_sub ^ w1[31:24];
assign sa02_ark = sa02_sub ^ w2[31:24];
assign sa03_ark = sa03_sub ^ w3[31:24];
assign sa10_ark = sa10_sub ^ w0[23:16];
assign sa11_ark = sa11_sub ^ w1[23:16];
assign sa12_ark = sa12_sub ^ w2[23:16];
assign sa13_ark = sa13_sub ^ w3[23:16];
assign sa20_ark = sa20_sub ^ w0[15:08];
assign sa21_ark = sa21_sub ^ w1[15:08];
assign sa22_ark = sa22_sub ^ w2[15:08];
assign sa23_ark = sa23_sub ^ w3[15:08];
assign sa30_ark = sa30_sub ^ w0[07:00];
assign sa31_ark = sa31_sub ^ w1[07:00];
assign sa32_ark = sa32_sub ^ w2[07:00];
assign sa33_ark = sa33_sub ^ w3[07:00];

//3.逆向列混合
wire [31:0] inv_mix_col_out0, inv_mix_col_out1, inv_mix_col_out2, inv_mix_col_out3;

assign inv_mix_col_out0 = inv_mix_col(sa00_ark,sa10_ark,sa20_ark,sa30_ark);
assign inv_mix_col_out1 = inv_mix_col(sa01_ark,sa11_ark,sa21_ark,sa31_ark);
assign inv_mix_col_out2 = inv_mix_col(sa02_ark,sa12_ark,sa22_ark,sa32_ark);
assign inv_mix_col_out3 = inv_mix_col(sa03_ark,sa13_ark,sa23_ark,sa33_ark);

assign {sa00_next, sa10_next, sa20_next, sa30_next} = inv_mix_col_out0 ;
assign {sa01_next, sa11_next, sa21_next, sa31_next} = inv_mix_col_out1 ;
assign {sa02_next, sa12_next, sa22_next, sa32_next} = inv_mix_col_out2 ;
assign {sa03_next, sa13_next, sa23_next, sa33_next} = inv_mix_col_out3 ;

////////////////////////////////////////////////////////////////////
//
// Final Text Output
//

always @(posedge clk) text_out[127:120] <=  sa00_ark;
always @(posedge clk) text_out[095:088] <=  sa01_ark;
always @(posedge clk) text_out[063:056] <=  sa02_ark;
always @(posedge clk) text_out[031:024] <=  sa03_ark;
always @(posedge clk) text_out[119:112] <=  sa10_ark;
always @(posedge clk) text_out[087:080] <=  sa11_ark;
always @(posedge clk) text_out[055:048] <=  sa12_ark;
always @(posedge clk) text_out[023:016] <=  sa13_ark;
always @(posedge clk) text_out[111:104] <=  sa20_ark;
always @(posedge clk) text_out[079:072] <=  sa21_ark;
always @(posedge clk) text_out[047:040] <=  sa22_ark;
always @(posedge clk) text_out[015:008] <=  sa23_ark;
always @(posedge clk) text_out[103:096] <=  sa30_ark;
always @(posedge clk) text_out[071:064] <=  sa31_ark;
always @(posedge clk) text_out[039:032] <=  sa32_ark;
always @(posedge clk) text_out[007:000] <=  sa33_ark;

////////////////////////////////////////////////////////////////////
//
// Generic Functions
//列混合运算

function [31:0] inv_mix_col;
input	[7:0]	s0,s1,s2,s3;
begin
inv_mix_col[31:24]=pmul_e(s0)^pmul_b(s1)^pmul_d(s2)^pmul_9(s3);
inv_mix_col[23:16]=pmul_9(s0)^pmul_e(s1)^pmul_b(s2)^pmul_d(s3);
inv_mix_col[15:08]=pmul_d(s0)^pmul_9(s1)^pmul_e(s2)^pmul_b(s3);
inv_mix_col[07:00]=pmul_b(s0)^pmul_d(s1)^pmul_9(s2)^pmul_e(s3);
end
endfunction

// Some synthesis tools don't like xtime being called recursevly ...
//GF(2^8)乘法运算

//×14
function [7:0] pmul_e;
input [7:0] b;
reg [7:0] two,four,eight;
begin
two=xtime(b);//×2
four=xtime(two);//×4
eight=xtime(four);//×8
pmul_e=eight^four^two;//8+4+2=14
end
endfunction

function [7:0] pmul_9;
input [7:0] b;
reg [7:0] two,four,eight;
begin
two=xtime(b);four=xtime(two);eight=xtime(four);pmul_9=eight^b;
end
endfunction

function [7:0] pmul_d;
input [7:0] b;
reg [7:0] two,four,eight;
begin
two=xtime(b);four=xtime(two);eight=xtime(four);pmul_d=eight^four^b;
end
endfunction

function [7:0] pmul_b;
input [7:0] b;
reg [7:0] two,four,eight;
begin
two=xtime(b);four=xtime(two);eight=xtime(four);pmul_b=eight^two^b;
end
endfunction

function [7:0] xtime;
input [7:0] b;xtime={b[6:0],1'b0}^(8'h1b&{8{b[7]}});
endfunction

////////////////////////////////////////////////////////////////////
//
// Key Buffer
//
//密钥缓存相关寄存器和计数器
reg	[127:0]	kb[10:0];//11个轮密钥的缓存
reg	[3:0]	kcnt;//密钥缓存计数器
reg		kdone;//密钥加载完成标志
reg		kb_ld;//密钥缓存加载使能

//密钥缓存计数器控制，kcnt逆序存储轮密钥
always @(posedge clk)
	if(!rst)	kcnt <=  4'ha;
	else
	if(kld)		kcnt <=  4'ha;
	else
	if(kb_ld)	kcnt <=  kcnt - 4'h1;

//密钥加载控制
always @(posedge clk)
	if(!rst)	kb_ld <=  1'b0;
	else
	if(kld)		kb_ld <=  1'b1;
	else
	if(kcnt==4'h0)	kb_ld <=  1'b0;

always @(posedge clk)	kdone <=  (kcnt==4'h0) & !kld;

//密钥缓存写入和读取
always @(posedge clk)	if(kb_ld) kb[kcnt] <=  {wk3, wk2, wk1, wk0};//存储轮密钥
always @(posedge clk)	{w3, w2, w1, w0} <=  kb[dcnt];//读取轮密钥

////////////////////////////////////////////////////////////////////
//
// Modules
//

aes_key_expand_128 u0(
	.clk(		clk	),
	.kld(		kld	),
	.key(		key	),
	.wo_0(		wk0	),
	.wo_1(		wk1	),
	.wo_2(		wk2	),
	.wo_3(		wk3	));

aes_inv_sbox us00(	.a(	sa00_sr	),	.b(	sa00_sub	));
aes_inv_sbox us01(	.a(	sa01_sr	),	.b(	sa01_sub	));
aes_inv_sbox us02(	.a(	sa02_sr	),	.b(	sa02_sub	));
aes_inv_sbox us03(	.a(	sa03_sr	),	.b(	sa03_sub	));
aes_inv_sbox us10(	.a(	sa10_sr	),	.b(	sa10_sub	));
aes_inv_sbox us11(	.a(	sa11_sr	),	.b(	sa11_sub	));
aes_inv_sbox us12(	.a(	sa12_sr	),	.b(	sa12_sub	));
aes_inv_sbox us13(	.a(	sa13_sr	),	.b(	sa13_sub	));
aes_inv_sbox us20(	.a(	sa20_sr	),	.b(	sa20_sub	));
aes_inv_sbox us21(	.a(	sa21_sr	),	.b(	sa21_sub	));
aes_inv_sbox us22(	.a(	sa22_sr	),	.b(	sa22_sub	));
aes_inv_sbox us23(	.a(	sa23_sr	),	.b(	sa23_sub	));
aes_inv_sbox us30(	.a(	sa30_sr	),	.b(	sa30_sub	));
aes_inv_sbox us31(	.a(	sa31_sr	),	.b(	sa31_sub	));
aes_inv_sbox us32(	.a(	sa32_sr	),	.b(	sa32_sub	));
aes_inv_sbox us33(	.a(	sa33_sr	),	.b(	sa33_sub	));

endmodule

/////////////////////////////////////////////////////////////////////
////                                                             ////
////  AES Inverse SBOX (ROM)                                     ////
////                                                             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/cores/aes_core/  ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2002 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: aes_inv_sbox.v,v 1.1.1.1 2002-11-09 11:22:55 rudi Exp $
//
//  $Date: 2002-11-09 11:22:55 $
//  $Revision: 1.1.1.1 $
//  $Author: rudi $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//
//
//
//
//

// `include "timescale.v"

module aes_inv_sbox(a,b);
input	[7:0]	a;
output	[7:0]	b;
reg	[7:0]	b;

always @(a)
	case(a)		// synopsys full_case parallel_case
	   8'h00: b=8'h52;
	   8'h01: b=8'h09;
	   8'h02: b=8'h6a;
	   8'h03: b=8'hd5;
	   8'h04: b=8'h30;
	   8'h05: b=8'h36;
	   8'h06: b=8'ha5;
	   8'h07: b=8'h38;
	   8'h08: b=8'hbf;
	   8'h09: b=8'h40;
	   8'h0a: b=8'ha3;
	   8'h0b: b=8'h9e;
	   8'h0c: b=8'h81;
	   8'h0d: b=8'hf3;
	   8'h0e: b=8'hd7;
	   8'h0f: b=8'hfb;
	   8'h10: b=8'h7c;
	   8'h11: b=8'he3;
	   8'h12: b=8'h39;
	   8'h13: b=8'h82;
	   8'h14: b=8'h9b;
	   8'h15: b=8'h2f;
	   8'h16: b=8'hff;
	   8'h17: b=8'h87;
	   8'h18: b=8'h34;
	   8'h19: b=8'h8e;
	   8'h1a: b=8'h43;
	   8'h1b: b=8'h44;
	   8'h1c: b=8'hc4;
	   8'h1d: b=8'hde;
	   8'h1e: b=8'he9;
	   8'h1f: b=8'hcb;
	   8'h20: b=8'h54;
	   8'h21: b=8'h7b;
	   8'h22: b=8'h94;
	   8'h23: b=8'h32;
	   8'h24: b=8'ha6;
	   8'h25: b=8'hc2;
	   8'h26: b=8'h23;
	   8'h27: b=8'h3d;
	   8'h28: b=8'hee;
	   8'h29: b=8'h4c;
	   8'h2a: b=8'h95;
	   8'h2b: b=8'h0b;
	   8'h2c: b=8'h42;
	   8'h2d: b=8'hfa;
	   8'h2e: b=8'hc3;
	   8'h2f: b=8'h4e;
	   8'h30: b=8'h08;
	   8'h31: b=8'h2e;
	   8'h32: b=8'ha1;
	   8'h33: b=8'h66;
	   8'h34: b=8'h28;
	   8'h35: b=8'hd9;
	   8'h36: b=8'h24;
	   8'h37: b=8'hb2;
	   8'h38: b=8'h76;
	   8'h39: b=8'h5b;
	   8'h3a: b=8'ha2;
	   8'h3b: b=8'h49;
	   8'h3c: b=8'h6d;
	   8'h3d: b=8'h8b;
	   8'h3e: b=8'hd1;
	   8'h3f: b=8'h25;
	   8'h40: b=8'h72;
	   8'h41: b=8'hf8;
	   8'h42: b=8'hf6;
	   8'h43: b=8'h64;
	   8'h44: b=8'h86;
	   8'h45: b=8'h68;
	   8'h46: b=8'h98;
	   8'h47: b=8'h16;
	   8'h48: b=8'hd4;
	   8'h49: b=8'ha4;
	   8'h4a: b=8'h5c;
	   8'h4b: b=8'hcc;
	   8'h4c: b=8'h5d;
	   8'h4d: b=8'h65;
	   8'h4e: b=8'hb6;
	   8'h4f: b=8'h92;
	   8'h50: b=8'h6c;
	   8'h51: b=8'h70;
	   8'h52: b=8'h48;
	   8'h53: b=8'h50;
	   8'h54: b=8'hfd;
	   8'h55: b=8'hed;
	   8'h56: b=8'hb9;
	   8'h57: b=8'hda;
	   8'h58: b=8'h5e;
	   8'h59: b=8'h15;
	   8'h5a: b=8'h46;
	   8'h5b: b=8'h57;
	   8'h5c: b=8'ha7;
	   8'h5d: b=8'h8d;
	   8'h5e: b=8'h9d;
	   8'h5f: b=8'h84;
	   8'h60: b=8'h90;
	   8'h61: b=8'hd8;
	   8'h62: b=8'hab;
	   8'h63: b=8'h00;
	   8'h64: b=8'h8c;
	   8'h65: b=8'hbc;
	   8'h66: b=8'hd3;
	   8'h67: b=8'h0a;
	   8'h68: b=8'hf7;
	   8'h69: b=8'he4;
	   8'h6a: b=8'h58;
	   8'h6b: b=8'h05;
	   8'h6c: b=8'hb8;
	   8'h6d: b=8'hb3;
	   8'h6e: b=8'h45;
	   8'h6f: b=8'h06;
	   8'h70: b=8'hd0;
	   8'h71: b=8'h2c;
	   8'h72: b=8'h1e;
	   8'h73: b=8'h8f;
	   8'h74: b=8'hca;
	   8'h75: b=8'h3f;
	   8'h76: b=8'h0f;
	   8'h77: b=8'h02;
	   8'h78: b=8'hc1;
	   8'h79: b=8'haf;
	   8'h7a: b=8'hbd;
	   8'h7b: b=8'h03;
	   8'h7c: b=8'h01;
	   8'h7d: b=8'h13;
	   8'h7e: b=8'h8a;
	   8'h7f: b=8'h6b;
	   8'h80: b=8'h3a;
	   8'h81: b=8'h91;
	   8'h82: b=8'h11;
	   8'h83: b=8'h41;
	   8'h84: b=8'h4f;
	   8'h85: b=8'h67;
	   8'h86: b=8'hdc;
	   8'h87: b=8'hea;
	   8'h88: b=8'h97;
	   8'h89: b=8'hf2;
	   8'h8a: b=8'hcf;
	   8'h8b: b=8'hce;
	   8'h8c: b=8'hf0;
	   8'h8d: b=8'hb4;
	   8'h8e: b=8'he6;
	   8'h8f: b=8'h73;
	   8'h90: b=8'h96;
	   8'h91: b=8'hac;
	   8'h92: b=8'h74;
	   8'h93: b=8'h22;
	   8'h94: b=8'he7;
	   8'h95: b=8'had;
	   8'h96: b=8'h35;
	   8'h97: b=8'h85;
	   8'h98: b=8'he2;
	   8'h99: b=8'hf9;
	   8'h9a: b=8'h37;
	   8'h9b: b=8'he8;
	   8'h9c: b=8'h1c;
	   8'h9d: b=8'h75;
	   8'h9e: b=8'hdf;
	   8'h9f: b=8'h6e;
	   8'ha0: b=8'h47;
	   8'ha1: b=8'hf1;
	   8'ha2: b=8'h1a;
	   8'ha3: b=8'h71;
	   8'ha4: b=8'h1d;
	   8'ha5: b=8'h29;
	   8'ha6: b=8'hc5;
	   8'ha7: b=8'h89;
	   8'ha8: b=8'h6f;
	   8'ha9: b=8'hb7;
	   8'haa: b=8'h62;
	   8'hab: b=8'h0e;
	   8'hac: b=8'haa;
	   8'had: b=8'h18;
	   8'hae: b=8'hbe;
	   8'haf: b=8'h1b;
	   8'hb0: b=8'hfc;
	   8'hb1: b=8'h56;
	   8'hb2: b=8'h3e;
	   8'hb3: b=8'h4b;
	   8'hb4: b=8'hc6;
	   8'hb5: b=8'hd2;
	   8'hb6: b=8'h79;
	   8'hb7: b=8'h20;
	   8'hb8: b=8'h9a;
	   8'hb9: b=8'hdb;
	   8'hba: b=8'hc0;
	   8'hbb: b=8'hfe;
	   8'hbc: b=8'h78;
	   8'hbd: b=8'hcd;
	   8'hbe: b=8'h5a;
	   8'hbf: b=8'hf4;
	   8'hc0: b=8'h1f;
	   8'hc1: b=8'hdd;
	   8'hc2: b=8'ha8;
	   8'hc3: b=8'h33;
	   8'hc4: b=8'h88;
	   8'hc5: b=8'h07;
	   8'hc6: b=8'hc7;
	   8'hc7: b=8'h31;
	   8'hc8: b=8'hb1;
	   8'hc9: b=8'h12;
	   8'hca: b=8'h10;
	   8'hcb: b=8'h59;
	   8'hcc: b=8'h27;
	   8'hcd: b=8'h80;
	   8'hce: b=8'hec;
	   8'hcf: b=8'h5f;
	   8'hd0: b=8'h60;
	   8'hd1: b=8'h51;
	   8'hd2: b=8'h7f;
	   8'hd3: b=8'ha9;
	   8'hd4: b=8'h19;
	   8'hd5: b=8'hb5;
	   8'hd6: b=8'h4a;
	   8'hd7: b=8'h0d;
	   8'hd8: b=8'h2d;
	   8'hd9: b=8'he5;
	   8'hda: b=8'h7a;
	   8'hdb: b=8'h9f;
	   8'hdc: b=8'h93;
	   8'hdd: b=8'hc9;
	   8'hde: b=8'h9c;
	   8'hdf: b=8'hef;
	   8'he0: b=8'ha0;
	   8'he1: b=8'he0;
	   8'he2: b=8'h3b;
	   8'he3: b=8'h4d;
	   8'he4: b=8'hae;
	   8'he5: b=8'h2a;
	   8'he6: b=8'hf5;
	   8'he7: b=8'hb0;
	   8'he8: b=8'hc8;
	   8'he9: b=8'heb;
	   8'hea: b=8'hbb;
	   8'heb: b=8'h3c;
	   8'hec: b=8'h83;
	   8'hed: b=8'h53;
	   8'hee: b=8'h99;
	   8'hef: b=8'h61;
	   8'hf0: b=8'h17;
	   8'hf1: b=8'h2b;
	   8'hf2: b=8'h04;
	   8'hf3: b=8'h7e;
	   8'hf4: b=8'hba;
	   8'hf5: b=8'h77;
	   8'hf6: b=8'hd6;
	   8'hf7: b=8'h26;
	   8'hf8: b=8'he1;
	   8'hf9: b=8'h69;
	   8'hfa: b=8'h14;
	   8'hfb: b=8'h63;
	   8'hfc: b=8'h55;
	   8'hfd: b=8'h21;
	   8'hfe: b=8'h0c;
	   8'hff: b=8'h7d;
	endcase
endmodule

/////////////////////////////////////////////////////////////////////
////                                                             ////
////  AES Key Expand Block (for 128 bit keys)                    ////
////                                                             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/cores/aes_core/  ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2002 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: aes_key_expand_128.v,v 1.1.1.1 2002-11-09 11:22:38 rudi Exp $
//
//  $Date: 2002-11-09 11:22:38 $
//  $Revision: 1.1.1.1 $
//  $Author: rudi $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//
//
//
//
//

// `include "timescale.v"

module aes_key_expand_128(clk, kld, key, wo_0, wo_1, wo_2, wo_3);
input		clk;
input		kld;
input	[127:0]	key;
output	[31:0]	wo_0, wo_1, wo_2, wo_3;
reg	[31:0]	w[3:0];
wire	[31:0]	tmp_w;
wire	[31:0]	subword;
wire	[31:0]	rcon;

assign wo_0 = w[0];
assign wo_1 = w[1];
assign wo_2 = w[2];
assign wo_3 = w[3];
always @(posedge clk)	w[0] <=  kld ? key[127:096] : w[0]^subword^rcon;
always @(posedge clk)	w[1] <=  kld ? key[095:064] : w[0]^w[1]^subword^rcon;
always @(posedge clk)	w[2] <=  kld ? key[063:032] : w[0]^w[2]^w[1]^subword^rcon;
always @(posedge clk)	w[3] <=  kld ? key[031:000] : w[0]^w[3]^w[2]^w[1]^subword^rcon;
assign tmp_w = w[3];
aes_sbox u0(	.a(tmp_w[23:16]), .b(subword[31:24]));
aes_sbox u1(	.a(tmp_w[15:08]), .b(subword[23:16]));
aes_sbox u2(	.a(tmp_w[07:00]), .b(subword[15:08]));
aes_sbox u3(	.a(tmp_w[31:24]), .b(subword[07:00]));
aes_rcon r0(	.clk(clk), .kld(kld), .out(rcon));
endmodule

/////////////////////////////////////////////////////////////////////
////                                                             ////
////  AES RCON Block                                             ////
////                                                             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/cores/aes_core/  ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2002 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: aes_rcon.v,v 1.1.1.1 2002-11-09 11:22:38 rudi Exp $
//
//  $Date: 2002-11-09 11:22:38 $
//  $Revision: 1.1.1.1 $
//  $Author: rudi $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//
//
//
//
//

// `include "timescale.v"

module aes_rcon(clk, kld, out);
input		clk;
input		kld;
output	[31:0]	out;
reg	[31:0]	out;
reg	[3:0]	rcnt;
wire	[3:0]	rcnt_next;

always @(posedge clk)
	if(kld)		out <=  32'h01_00_00_00;
	else		out <=  frcon(rcnt_next);

assign rcnt_next = rcnt + 4'h1;
always @(posedge clk)
	if(kld)		rcnt <=  4'h0;
	else		rcnt <=  rcnt_next;

function [31:0]	frcon;
input	[3:0]	i;
case(i)	// synopsys parallel_case
   4'h0: frcon=32'h01_00_00_00;
   4'h1: frcon=32'h02_00_00_00;
   4'h2: frcon=32'h04_00_00_00;
   4'h3: frcon=32'h08_00_00_00;
   4'h4: frcon=32'h10_00_00_00;
   4'h5: frcon=32'h20_00_00_00;
   4'h6: frcon=32'h40_00_00_00;
   4'h7: frcon=32'h80_00_00_00;
   4'h8: frcon=32'h1b_00_00_00;
   4'h9: frcon=32'h36_00_00_00;
   default: frcon=32'h00_00_00_00;
endcase
endfunction

endmodule


module aes_sbox(a,b);
input	[7:0]	a;
output	[7:0]	b;
reg	[7:0]	b;

always @(a)
	case(a)		// synopsys full_case parallel_case
	   8'h00: b=8'h63;
	   8'h01: b=8'h7c;
	   8'h02: b=8'h77;
	   8'h03: b=8'h7b;
	   8'h04: b=8'hf2;
	   8'h05: b=8'h6b;
	   8'h06: b=8'h6f;
	   8'h07: b=8'hc5;
	   8'h08: b=8'h30;
	   8'h09: b=8'h01;
	   8'h0a: b=8'h67;
	   8'h0b: b=8'h2b;
	   8'h0c: b=8'hfe;
	   8'h0d: b=8'hd7;
	   8'h0e: b=8'hab;
	   8'h0f: b=8'h76;
	   8'h10: b=8'hca;
	   8'h11: b=8'h82;
	   8'h12: b=8'hc9;
	   8'h13: b=8'h7d;
	   8'h14: b=8'hfa;
	   8'h15: b=8'h59;
	   8'h16: b=8'h47;
	   8'h17: b=8'hf0;
	   8'h18: b=8'had;
	   8'h19: b=8'hd4;
	   8'h1a: b=8'ha2;
	   8'h1b: b=8'haf;
	   8'h1c: b=8'h9c;
	   8'h1d: b=8'ha4;
	   8'h1e: b=8'h72;
	   8'h1f: b=8'hc0;
	   8'h20: b=8'hb7;
	   8'h21: b=8'hfd;
	   8'h22: b=8'h93;
	   8'h23: b=8'h26;
	   8'h24: b=8'h36;
	   8'h25: b=8'h3f;
	   8'h26: b=8'hf7;
	   8'h27: b=8'hcc;
	   8'h28: b=8'h34;
	   8'h29: b=8'ha5;
	   8'h2a: b=8'he5;
	   8'h2b: b=8'hf1;
	   8'h2c: b=8'h71;
	   8'h2d: b=8'hd8;
	   8'h2e: b=8'h31;
	   8'h2f: b=8'h15;
	   8'h30: b=8'h04;
	   8'h31: b=8'hc7;
	   8'h32: b=8'h23;
	   8'h33: b=8'hc3;
	   8'h34: b=8'h18;
	   8'h35: b=8'h96;
	   8'h36: b=8'h05;
	   8'h37: b=8'h9a;
	   8'h38: b=8'h07;
	   8'h39: b=8'h12;
	   8'h3a: b=8'h80;
	   8'h3b: b=8'he2;
	   8'h3c: b=8'heb;
	   8'h3d: b=8'h27;
	   8'h3e: b=8'hb2;
	   8'h3f: b=8'h75;
	   8'h40: b=8'h09;
	   8'h41: b=8'h83;
	   8'h42: b=8'h2c;
	   8'h43: b=8'h1a;
	   8'h44: b=8'h1b;
	   8'h45: b=8'h6e;
	   8'h46: b=8'h5a;
	   8'h47: b=8'ha0;
	   8'h48: b=8'h52;
	   8'h49: b=8'h3b;
	   8'h4a: b=8'hd6;
	   8'h4b: b=8'hb3;
	   8'h4c: b=8'h29;
	   8'h4d: b=8'he3;
	   8'h4e: b=8'h2f;
	   8'h4f: b=8'h84;
	   8'h50: b=8'h53;
	   8'h51: b=8'hd1;
	   8'h52: b=8'h00;
	   8'h53: b=8'hed;
	   8'h54: b=8'h20;
	   8'h55: b=8'hfc;
	   8'h56: b=8'hb1;
	   8'h57: b=8'h5b;
	   8'h58: b=8'h6a;
	   8'h59: b=8'hcb;
	   8'h5a: b=8'hbe;
	   8'h5b: b=8'h39;
	   8'h5c: b=8'h4a;
	   8'h5d: b=8'h4c;
	   8'h5e: b=8'h58;
	   8'h5f: b=8'hcf;
	   8'h60: b=8'hd0;
	   8'h61: b=8'hef;
	   8'h62: b=8'haa;
	   8'h63: b=8'hfb;
	   8'h64: b=8'h43;
	   8'h65: b=8'h4d;
	   8'h66: b=8'h33;
	   8'h67: b=8'h85;
	   8'h68: b=8'h45;
	   8'h69: b=8'hf9;
	   8'h6a: b=8'h02;
	   8'h6b: b=8'h7f;
	   8'h6c: b=8'h50;
	   8'h6d: b=8'h3c;
	   8'h6e: b=8'h9f;
	   8'h6f: b=8'ha8;
	   8'h70: b=8'h51;
	   8'h71: b=8'ha3;
	   8'h72: b=8'h40;
	   8'h73: b=8'h8f;
	   8'h74: b=8'h92;
	   8'h75: b=8'h9d;
	   8'h76: b=8'h38;
	   8'h77: b=8'hf5;
	   8'h78: b=8'hbc;
	   8'h79: b=8'hb6;
	   8'h7a: b=8'hda;
	   8'h7b: b=8'h21;
	   8'h7c: b=8'h10;
	   8'h7d: b=8'hff;
	   8'h7e: b=8'hf3;
	   8'h7f: b=8'hd2;
	   8'h80: b=8'hcd;
	   8'h81: b=8'h0c;
	   8'h82: b=8'h13;
	   8'h83: b=8'hec;
	   8'h84: b=8'h5f;
	   8'h85: b=8'h97;
	   8'h86: b=8'h44;
	   8'h87: b=8'h17;
	   8'h88: b=8'hc4;
	   8'h89: b=8'ha7;
	   8'h8a: b=8'h7e;
	   8'h8b: b=8'h3d;
	   8'h8c: b=8'h64;
	   8'h8d: b=8'h5d;
	   8'h8e: b=8'h19;
	   8'h8f: b=8'h73;
	   8'h90: b=8'h60;
	   8'h91: b=8'h81;
	   8'h92: b=8'h4f;
	   8'h93: b=8'hdc;
	   8'h94: b=8'h22;
	   8'h95: b=8'h2a;
	   8'h96: b=8'h90;
	   8'h97: b=8'h88;
	   8'h98: b=8'h46;
	   8'h99: b=8'hee;
	   8'h9a: b=8'hb8;
	   8'h9b: b=8'h14;
	   8'h9c: b=8'hde;
	   8'h9d: b=8'h5e;
	   8'h9e: b=8'h0b;
	   8'h9f: b=8'hdb;
	   8'ha0: b=8'he0;
	   8'ha1: b=8'h32;
	   8'ha2: b=8'h3a;
	   8'ha3: b=8'h0a;
	   8'ha4: b=8'h49;
	   8'ha5: b=8'h06;
	   8'ha6: b=8'h24;
	   8'ha7: b=8'h5c;
	   8'ha8: b=8'hc2;
	   8'ha9: b=8'hd3;
	   8'haa: b=8'hac;
	   8'hab: b=8'h62;
	   8'hac: b=8'h91;
	   8'had: b=8'h95;
	   8'hae: b=8'he4;
	   8'haf: b=8'h79;
	   8'hb0: b=8'he7;
	   8'hb1: b=8'hc8;
	   8'hb2: b=8'h37;
	   8'hb3: b=8'h6d;
	   8'hb4: b=8'h8d;
	   8'hb5: b=8'hd5;
	   8'hb6: b=8'h4e;
	   8'hb7: b=8'ha9;
	   8'hb8: b=8'h6c;
	   8'hb9: b=8'h56;
	   8'hba: b=8'hf4;
	   8'hbb: b=8'hea;
	   8'hbc: b=8'h65;
	   8'hbd: b=8'h7a;
	   8'hbe: b=8'hae;
	   8'hbf: b=8'h08;
	   8'hc0: b=8'hba;
	   8'hc1: b=8'h78;
	   8'hc2: b=8'h25;
	   8'hc3: b=8'h2e;
	   8'hc4: b=8'h1c;
	   8'hc5: b=8'ha6;
	   8'hc6: b=8'hb4;
	   8'hc7: b=8'hc6;
	   8'hc8: b=8'he8;
	   8'hc9: b=8'hdd;
	   8'hca: b=8'h74;
	   8'hcb: b=8'h1f;
	   8'hcc: b=8'h4b;
	   8'hcd: b=8'hbd;
	   8'hce: b=8'h8b;
	   8'hcf: b=8'h8a;
	   8'hd0: b=8'h70;
	   8'hd1: b=8'h3e;
	   8'hd2: b=8'hb5;
	   8'hd3: b=8'h66;
	   8'hd4: b=8'h48;
	   8'hd5: b=8'h03;
	   8'hd6: b=8'hf6;
	   8'hd7: b=8'h0e;
	   8'hd8: b=8'h61;
	   8'hd9: b=8'h35;
	   8'hda: b=8'h57;
	   8'hdb: b=8'hb9;
	   8'hdc: b=8'h86;
	   8'hdd: b=8'hc1;
	   8'hde: b=8'h1d;
	   8'hdf: b=8'h9e;
	   8'he0: b=8'he1;
	   8'he1: b=8'hf8;
	   8'he2: b=8'h98;
	   8'he3: b=8'h11;
	   8'he4: b=8'h69;
	   8'he5: b=8'hd9;
	   8'he6: b=8'h8e;
	   8'he7: b=8'h94;
	   8'he8: b=8'h9b;
	   8'he9: b=8'h1e;
	   8'hea: b=8'h87;
	   8'heb: b=8'he9;
	   8'hec: b=8'hce;
	   8'hed: b=8'h55;
	   8'hee: b=8'h28;
	   8'hef: b=8'hdf;
	   8'hf0: b=8'h8c;
	   8'hf1: b=8'ha1;
	   8'hf2: b=8'h89;
	   8'hf3: b=8'h0d;
	   8'hf4: b=8'hbf;
	   8'hf5: b=8'he6;
	   8'hf6: b=8'h42;
	   8'hf7: b=8'h68;
	   8'hf8: b=8'h41;
	   8'hf9: b=8'h99;
	   8'hfa: b=8'h2d;
	   8'hfb: b=8'h0f;
	   8'hfc: b=8'hb0;
	   8'hfd: b=8'h54;
	   8'hfe: b=8'hbb;
	   8'hff: b=8'h16;
	endcase

endmodule