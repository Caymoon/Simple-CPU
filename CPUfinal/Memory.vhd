library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_arith.ALL;

entity Memory is
    Port ( t2 : in  STD_LOGIC;
           alu_in : in  STD_LOGIC_VECTOR (8 downto 0);--alu��������
			  ir : in std_logic_vector(15 downto 0);
           mem_in : in  STD_LOGIC_VECTOR (7 downto 0);--�洢��ȡ��������
           mem_out : out  STD_LOGIC_VECTOR (8 downto 0));
end Memory;

architecture Behavioral of Memory is

begin
	process(t2, alu_in, mem_in, ir)
	variable data : std_logic_vector(8 downto 0);
	begin
		if(t2 = '1')then
			case ir(15 downto 11) is
				when "00110" => data := alu_in;--add
				when "00100" => data := alu_in;--sub
				when "01010" => data := alu_in;--mov
				when "01000" => data := alu_in;--mvi
				when "01110" => data := alu_in(8)&mem_in;--LDA
				when "00000" => data(8) := alu_in(8);--jmp,����cy
				when "00010" => data(8) := alu_in(8);--jz,����cy
				when others  => null;--sta������t1��ʱ�������Ѿ��ŵ�����������
			end case;
		end if;
		mem_out <= data;
	end process;
	
end Behavioral;

