`timescale 1ns / 1ps

module tb_fbcpu();

	`define NULL 0 
	 reg clk = 0;
	 reg rst;
	 
	 parameter ADDRESS_WIDTH = 6;
	 parameter DATA_WIDTH = 10;
	 
	wire [ADDRESS_WIDTH-1:0] addr_toRAM;
	wire [DATA_WIDTH-1:0] data_toRAM, data_fromRAM;
	wire [ADDRESS_WIDTH-1:0] pCounter;
	wire wrEn;

	blram #(ADDRESS_WIDTH, 64) blram(
		  .clk(clk),
		  .rst(rst),
		  .i_we(wrEn),
		  .i_addr(addr_toRAM),
		  .i_ram_data_in(data_toRAM),
		  .o_ram_data_out(data_fromRAM)
		);
		
	FBCPU #(
        ADDRESS_WIDTH,
        DATA_WIDTH
    ) FBCPU_Inst(
        .clk(clk), 
        .rst(rst), 
        .MDRIn(data_toRAM), 
        .RAMWr(wrEn), 
        .MAR(addr_toRAM), 
        .MDROut(data_fromRAM), 
        .PC(pCounter)
    );
	
	always #5 clk = !clk;
	class dosyaSinifi;
		int fileDescriptor;
		int scanFile;
		int lineCount;
		logic fileInitialized;
		logic fileComplated;
		logic [21:0] data;
		logic [7:0] memAddr;
		string dosyaAdi;
		int sayac;
	
		function new();
			fileDescriptor = 0;
			scanFile = 0;
			lineCount = 0;
			fileInitialized = 0;
			fileComplated = 0;
			data = 0;
			memAddr = 0;
			sayac=0;
		endfunction

		function int dosyayiInitializeEt( string girisDosyaAdi);
			fileDescriptor = $fopen(girisDosyaAdi, "r");
			if (fileDescriptor == `NULL) begin
			    fileInitialized = 0;
				$display("Dosya bulunamadý. ");
				$finish;
				return 0;
			end
			else begin
			    fileInitialized = 1;
			    dosyaAdi = girisDosyaAdi;
			    sayac=sayac+1;
			    if (dosyaAdi=="input1.txt" ||dosyaAdi=="input2.txt" ||dosyaAdi=="input3.txt")begin
				    $display("%d. giriþ dosyasý bulundu.\n" , sayac);
				end else if (dosyaAdi=="output1.txt" ||dosyaAdi=="output2.txt" ||dosyaAdi=="output3.txt") begin
				    $display("%d. çýkýþ dosyasý bulundu.\n" , sayac);
				end
				return 1;
			end
        endfunction
        
		function int dosyadanOku( );
			if (fileInitialized == 1 && fileComplated==0) begin
				scanFile = $fscanf(fileDescriptor, "%x %x\n", memAddr, data); 
				lineCount=lineCount+1;
				$display(" %d ) memAddr: %x -> data: %x \n",lineCount, memAddr, data );
				if ($feof(fileDescriptor)) begin
					fileComplated=1;
					fileInitialized=0;
				end
				return 1;
			end else if (fileInitialized == 0 && fileComplated==1) begin
				$display("%d dosyasý okundu. Okunan satýr sayýsý: %d \n", dosyaAdi, lineCount);
				fileComplated=0;
				lineCount = 0;
				return 0;
			end else if (fileInitialized == 0 && fileComplated==0)begin
				$display("Dosya initialized edilemedi." );
				return 0;
			end
        endfunction
	endclass
	
	class testSinifi extends dosyaSinifi;
		int durum1, durum2;
		int testNo;
		
		dosyaSinifi girisDosyasi;
		dosyaSinifi cikisDosyasi;
		
		function new();
		    super.new();
			testNo = 0;
			girisDosyasi =new;
			cikisDosyasi =new;
			
		endfunction
		
		function int testNoAyarla( int girisTestNo );
			testNo = girisTestNo;
		endfunction
		
		function int testInitializeEt(  );
			case(testNo)
				0: begin
					girisDosyasi.dosyayiInitializeEt("input1.txt");
					cikisDosyasi.dosyayiInitializeEt("output1.txt");
				end
				1: begin 
					girisDosyasi.dosyayiInitializeEt("input2.txt");
					cikisDosyasi.dosyayiInitializeEt("output2.txt");
				end
				2: begin
					girisDosyasi.dosyayiInitializeEt("input3.txt");
					cikisDosyasi.dosyayiInitializeEt("output3.txt");
				end
			endcase
		endfunction
		
		function int kontrolEt( reg [7:0] memLocation, reg [21:0] expectedValue );
				durum1 = blram.memory[memLocation];
				durum2 = expectedValue;
				if(durum1 !== durum2)begin
					$display("Simülasyon hatalý.");
				end				
				else begin				
					$display("Simülasyon baþarýlý.");
				end	
		endfunction
			
	endclass
	
	
	initial begin
	    testSinifi test;
        test = new;
		clk = 0;
		rst = 0;
		for (int i = 0; i<3 ;i = i+1) begin
			$display("Su anki Test no:  %d\n",i );
			test.testNoAyarla(i);
			test.testInitializeEt();
			while(test.girisDosyasi.dosyadanOku() == 1) begin
				blram.memory[test.girisDosyasi.memAddr] = test.girisDosyasi.data;
				//@(posedge clk );
			end
			
			rst <= #1 1;
			repeat(10) @(posedge clk );
			rst <= #1 0;
			repeat(10000) @(posedge clk );
			while (test.cikisDosyasi.dosyadanOku() == 1) begin
			    $display("TEST SONUCU:" );
				test.kontrolEt(test.cikisDosyasi.memAddr, test.cikisDosyasi.data);
				
			
			end
			$display("Bitirilen Test  %d\n",i );
			$display("----------------------------------------------" ); //
		end
		$display("Simulasyon Tamamlandý" );
		$finish;
    end
endmodule