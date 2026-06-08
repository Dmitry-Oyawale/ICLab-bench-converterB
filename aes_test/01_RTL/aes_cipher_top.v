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


module aes_cipher_top(clk, rst, ld, done, key, text_in, text_out);
input		clk, rst;
input		ld;
output		done;
input	[127:0]	key;
input	[127:0]	text_in;
output	[127:0]	text_out;

////////////////////////////////////////////////////////////////////
//
// Local Wires
//

wire	[31:0]	w0, w1, w2, w3;
reg	[127:0]	text_in_r;
reg	[127:0]	text_out;

//状态矩阵的组织
reg	[7:0]	sa00, sa01, sa02, sa03;//第0行
reg	[7:0]	sa10, sa11, sa12, sa13;//第1行
reg	[7:0]	sa20, sa21, sa22, sa23;//第2行
reg	[7:0]	sa30, sa31, sa32, sa33;//第3行

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
wire	[7:0]	sa00_mc, sa01_mc, sa02_mc, sa03_mc;
wire	[7:0]	sa10_mc, sa11_mc, sa12_mc, sa13_mc;
wire	[7:0]	sa20_mc, sa21_mc, sa22_mc, sa23_mc;
wire	[7:0]	sa30_mc, sa31_mc, sa32_mc, sa33_mc;
reg		done, ld_r;
reg	[3:0]	dcnt;

////////////////////////////////////////////////////////////////////
//
// Misc Logic
//轮计数控制

always @(posedge clk)
	if(!rst)	dcnt <=  4'h0;
	else
	if(ld)		dcnt <=  4'hb;//加载新数据时设为11（10轮加密+1轮初始轮密钥加）
	else
	if(|dcnt)	dcnt <=  dcnt - 4'h1;//每个时钟周期递减，直到完成所有轮
//“|”是归约运算符，对所有位进行或运算
//当dcnt不为0时即还有位是1时进行减1，为0时保持为0，防止计数器从0减到负数

always @(posedge clk) done <=  !(|dcnt[3:1]) & dcnt[0] & !ld;
always @(posedge clk) if(ld) text_in_r <=  text_in;//输入数据缓存到text_in_r寄存器，当初始轮密钥加时使用
always @(posedge clk) ld_r <=  ld;

////////////////////////////////////////////////////////////////////
//
// Initial Permutation (AddRoundKey)
//
//初始轮密钥加操作
//
always @(posedge clk)	sa33 <=  ld_r ? text_in_r[007:000] ^ w3[07:00] : sa33_next;
//当ld_r=1时：输入数据的最低字节与轮密钥w3的最低字节异或；当ld_r=0时：使用轮变换的结果sa33_next
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
//加密轮变换流程
//2.shiftrows变换
assign sa00_sr = sa00_sub;//第0行，不移位
assign sa01_sr = sa01_sub;
assign sa02_sr = sa02_sub;
assign sa03_sr = sa03_sub;
assign sa10_sr = sa11_sub;//第1行，循环左移1字节
assign sa11_sr = sa12_sub;
assign sa12_sr = sa13_sub;
assign sa13_sr = sa10_sub;
assign sa20_sr = sa22_sub;//第2行，循环左移2字节
assign sa21_sr = sa23_sub;
assign sa22_sr = sa20_sub;
assign sa23_sr = sa21_sub;
assign sa30_sr = sa33_sub;//第3行，循环左移3字节
assign sa31_sr = sa30_sub;
assign sa32_sr = sa31_sub;
assign sa33_sr = sa32_sub;

//加密轮变换流程
//3.MixColumns变换
wire [31:0] mix_col_out0, mix_col_out1, mix_col_out2, mix_col_out3;

assign mix_col_out0 = mix_col(sa00_sr,sa10_sr,sa20_sr,sa30_sr);
assign mix_col_out1 = mix_col(sa01_sr,sa11_sr,sa21_sr,sa31_sr);
assign mix_col_out2 = mix_col(sa02_sr,sa12_sr,sa22_sr,sa32_sr);
assign mix_col_out3 = mix_col(sa03_sr,sa13_sr,sa23_sr,sa33_sr);

assign {sa00_mc, sa10_mc, sa20_mc, sa30_mc} = mix_col_out0;
assign {sa01_mc, sa11_mc, sa21_mc, sa31_mc} = mix_col_out1;
assign {sa02_mc, sa12_mc, sa22_mc, sa32_mc} = mix_col_out2;
assign {sa03_mc, sa13_mc, sa23_mc, sa33_mc} = mix_col_out3;

//加密轮变换流程
//4.轮密钥加
assign sa00_next = sa00_mc ^ w0[31:24];
assign sa01_next = sa01_mc ^ w1[31:24];
assign sa02_next = sa02_mc ^ w2[31:24];
assign sa03_next = sa03_mc ^ w3[31:24];
assign sa10_next = sa10_mc ^ w0[23:16];
assign sa11_next = sa11_mc ^ w1[23:16];
assign sa12_next = sa12_mc ^ w2[23:16];
assign sa13_next = sa13_mc ^ w3[23:16];
assign sa20_next = sa20_mc ^ w0[15:08];
assign sa21_next = sa21_mc ^ w1[15:08];
assign sa22_next = sa22_mc ^ w2[15:08];
assign sa23_next = sa23_mc ^ w3[15:08];
assign sa30_next = sa30_mc ^ w0[07:00];
assign sa31_next = sa31_mc ^ w1[07:00];
assign sa32_next = sa32_mc ^ w2[07:00];
assign sa33_next = sa33_mc ^ w3[07:00];

////////////////////////////////////////////////////////////////////
//
// Final text output
//
//输出处理，最后一轮后的状态与最终轮密钥异或
always @(posedge clk) text_out[127:120] <=  sa00_sr ^ w0[31:24];
always @(posedge clk) text_out[095:088] <=  sa01_sr ^ w1[31:24];
always @(posedge clk) text_out[063:056] <=  sa02_sr ^ w2[31:24];
always @(posedge clk) text_out[031:024] <=  sa03_sr ^ w3[31:24];
always @(posedge clk) text_out[119:112] <=  sa10_sr ^ w0[23:16];
always @(posedge clk) text_out[087:080] <=  sa11_sr ^ w1[23:16];
always @(posedge clk) text_out[055:048] <=  sa12_sr ^ w2[23:16];
always @(posedge clk) text_out[023:016] <=  sa13_sr ^ w3[23:16];
always @(posedge clk) text_out[111:104] <=  sa20_sr ^ w0[15:08];
always @(posedge clk) text_out[079:072] <=  sa21_sr ^ w1[15:08];
always @(posedge clk) text_out[047:040] <=  sa22_sr ^ w2[15:08];
always @(posedge clk) text_out[015:008] <=  sa23_sr ^ w3[15:08];
always @(posedge clk) text_out[103:096] <=  sa30_sr ^ w0[07:00];
always @(posedge clk) text_out[071:064] <=  sa31_sr ^ w1[07:00];
always @(posedge clk) text_out[039:032] <=  sa32_sr ^ w2[07:00];
always @(posedge clk) text_out[007:000] <=  sa33_sr ^ w3[07:00];

////////////////////////////////////////////////////////////////////
//
// Generic Functions
//

function [31:0] mix_col;//实现GF(2^8)上的矩阵乘法
input	[7:0]	s0,s1,s2,s3;
reg	[7:0]	s0_o,s1_o,s2_o,s3_o;
begin
mix_col[31:24]=xtime(s0)^xtime(s1)^s1^s2^s3;
mix_col[23:16]=s0^xtime(s1)^xtime(s2)^s2^s3;
mix_col[15:08]=s0^s1^xtime(s2)^xtime(s3)^s3;
mix_col[07:00]=xtime(s0)^s0^s1^s2^xtime(s3);
end
endfunction

function [7:0] xtime;//实现GF(2^8)上的×2运算
input [7:0] b; xtime={b[6:0],1'b0}^(8'h1b&{8{b[7]}});
endfunction

////////////////////////////////////////////////////////////////////
//
// Modules
//

aes_key_expand_128 u0(
	.clk(		clk	),
	.kld(		ld	),
	.key(		key	),
	.wo_0(		w0	),
	.wo_1(		w1	),
	.wo_2(		w2	),
	.wo_3(		w3	));

//加密轮变换流程
//1.subbyte变换
aes_sbox us00(	.a(	sa00	), .b(	sa00_sub	));
aes_sbox us01(	.a(	sa01	), .b(	sa01_sub	));
aes_sbox us02(	.a(	sa02	), .b(	sa02_sub	));
aes_sbox us03(	.a(	sa03	), .b(	sa03_sub	));
aes_sbox us10(	.a(	sa10	), .b(	sa10_sub	));
aes_sbox us11(	.a(	sa11	), .b(	sa11_sub	));
aes_sbox us12(	.a(	sa12	), .b(	sa12_sub	));
aes_sbox us13(	.a(	sa13	), .b(	sa13_sub	));
aes_sbox us20(	.a(	sa20	), .b(	sa20_sub	));
aes_sbox us21(	.a(	sa21	), .b(	sa21_sub	));
aes_sbox us22(	.a(	sa22	), .b(	sa22_sub	));
aes_sbox us23(	.a(	sa23	), .b(	sa23_sub	));
aes_sbox us30(	.a(	sa30	), .b(	sa30_sub	));
aes_sbox us31(	.a(	sa31	), .b(	sa31_sub	));
aes_sbox us32(	.a(	sa32	), .b(	sa32_sub	));
aes_sbox us33(	.a(	sa33	), .b(	sa33_sub	));

endmodule