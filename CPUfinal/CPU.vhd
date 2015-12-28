library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CPU is
port (clk : in std_logic;
		reset : in std_logic;
		RegSel : in std_logic_vector(2 downto 0);--�Ĵ���ѡ���ź�
		IrSel : in std_logic;--Ϊ0ʱs0���ir,Ϊ1ʱs0���reg
		PcSel : in std_logic;--Ϊ1ʱs3, s4���pc,Ϊ0ʱ�������
		AddrBus : out std_logic_vector(15 downto 0);
		DataBus : inout std_logic_vector(15 downto 0);
		nMPREQ, nRD, nWR, nBHE, nBLE : out std_logic;
		oMPREQ, oRD, oWR, oBHE, oBLE : out std_logic;--�ڵ�����ʾ
		z, cy : out std_logic;
		S0, S1, S2, S3, S4, S5 : out std_logic_vector(7 downto 0);
		B : out std_logic_vector(3 downto 0)
);
end CPU;

architecture Behavioral of CPU is

component ED is
	port (  t1 : in  STD_LOGIC;
			  t3 : in  STD_LOGIC;
			  reset : in std_logic;
           ir : in  STD_LOGIC_VECTOR (15 downto 0);
           pc : in  STD_LOGIC_VECTOR (15 downto 0);
			  r_update : in std_logic;
			  r_data : in std_logic_vector(7 downto 0);
			  r_cy : in std_logic;--��д�Ľ�λ
			  pc_out : out std_logic_vector(15 downto 0);--pc����ֵ
           ALUOUT : out  STD_LOGIC_VECTOR (8 downto 0);
			  cy_out : out std_logic;--��λλ
			  z_out : out std_logic;--��λ
			  reg_v : out std_logic_vector(63 downto 0);
			  addr : out std_logic_vector(15 downto 0)--R7//x�ĵ�ַ
	);
end component;

component FI is
    Port ( t0 : in  STD_LOGIC;
			  t3 : in  std_logic;
           rst : in  STD_LOGIC;
			  pc_update : in std_logic;
			  pc_new : in std_logic_vector(15 downto 0);
			  pc_out : out std_logic_vector(15 downto 0)
			  ); 
end component;

component MC is
    Port ( reset : in std_logic; 
			  pc : in  STD_LOGIC_VECTOR (15 downto 0);
			  t0 : in std_logic;
			  t1 : in std_logic;
			  t2 : in std_logic;
			  alu_in : in std_logic_vector(8 downto 0);--ALU������
			  addr_in : in std_logic_vector(15 downto 0);--�ô�ĵ�ַ
			  ir : out std_logic_vector(15 downto 0);--������ָ��
			  data_out : out std_logic_vector(7 downto 0);--������ȡ��������
			  nMREQ: out std_logic;--Ƭѡ
			  nRD: out std_logic;
			  nWR : out std_logic;
			  nBLE: out std_logic;
			  nBHE : out std_logic;--����д������λ������λ
			  DataBus : inout std_logic_vector(15 downto 0);
			  AddBus : out std_logic_vector(15 downto 0);
			  S2 : out std_logic_vector(7 downto 0);
			  S5 : out std_logic_vector(7 downto 0)
	 );
end component;

component WB is
    Port ( t3 : in  STD_LOGIC;
           mem_in : in  STD_LOGIC_VECTOR (8 downto 0);
           pc_in : in  STD_LOGIC_VECTOR (15 downto 0);
           ir : in  STD_LOGIC_VECTOR (15 downto 0);
           pc_update : out  STD_LOGIC;
           pc_new : out  STD_LOGIC_VECTOR (15 downto 0);
           r_update : out  STD_LOGIC;
           r_data : out  STD_LOGIC_VECTOR (7 downto 0);
			  r_cy : out std_logic
	);
end component;

component Memory is
    Port ( t2 : in  STD_LOGIC;
           alu_in : in  STD_LOGIC_VECTOR (8 downto 0);--alu��������
			  ir : in std_logic_vector(15 downto 0);
           mem_in : in  STD_LOGIC_VECTOR (7 downto 0);--�洢��ȡ��������
           mem_out : out  STD_LOGIC_VECTOR (8 downto 0));
end component;

component clock is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           t1 : out  STD_LOGIC;
           t2 : out  STD_LOGIC;
           t3 : out  STD_LOGIC;
           t4 : out  STD_LOGIC);
end component;

signal t : std_logic_vector(3 downto 0);--ʱ��
signal pc_update : std_logic;--pc���µ��ź�
signal reg_update : std_logic;--�Ĵ������µ��ź�
signal pc_new : std_logic_vector(15 downto 0);--pc����ֵ
signal pc :  std_logic_vector(15 downto 0);
signal ir : std_logic_vector(15 downto 0);
--signal reg_addr : std_logic_vector(2 downto 0);--���µļĴ����ĵ�ַ
signal reg_data : std_logic_vector(7 downto 0);--�Ĵ�������ֵ
signal new_cy : std_logic; --��λλ����ֵ���ڻ�д���ڸ���
signal data1: std_logic_vector(8 downto 0);--alu -> rtemp,alu -> mc
signal data2 : std_logic_vector(8 downto 0);--rtemp -> wb
signal data3 : std_logic_vector(7 downto 0);--mc -> rtemp
signal pc_wb : std_logic_vector(15 downto 0);--pc��д��ֵ
signal addr : std_logic_vector(15 downto 0);--R7//x�ĵ�ַ
signal MPREQ, RD, WR, BHE, BLE : std_logic;
signal reg : std_logic_vector(63 downto 0);--�Ĵ�����ֵ
begin

	my_clock: clock port map(clk, reset, t(0), t(1), t(2), t(3));
	my_fi : FI port map(t(0), t(3), reset, pc_update, pc_new, pc);
	my_ed : ED port map(t(1), t(3), reset, ir, pc, reg_update, reg_data, new_cy, pc_new, data1, cy, z, reg, addr);
	my_memory : Memory port map(t(2), data1, ir, data3, data2);
	my_wb : WB port map(t(3), data2, pc_new, ir, pc_update, pc_wb, reg_update, reg_data, new_cy);
	my_mc : MC port map(reset, pc, t(0), t(1), t(2), data1, addr, ir, data3, MPREQ, RD, WR, BLE, BHE, DataBus, AddrBus, S2, S5);
	
	B <= t;
	
	--���洢��
	nMPREQ <= MPREQ;
	nRD <= RD;
	nWR <= WR;
	nBHE <= BHE;
	nBLE <= BLE;
	--��LED��
	oMPREQ <= MPREQ;
	oRD <= RD;
	oWR <= WR;
	oBHE <= BHE;
	oBLE <= BLE;
	
	process(DataBus, PcSel, ir, reg, RegSel, IrSel)
	begin
	--ѡ��7������ܵ���ʾ����
		if(PcSel = '0')then
			S3 <= DataBus(7 downto 0);
			S4 <= DataBus(15 downto 8);
		else
			S3 <= pc_new(7 downto 0);
			S4 <= pc_new(15 downto 8);
		end if;
		
		if(IrSel = '0')then
			S0 <= ir(7 downto 0);
			S1 <= ir(15 downto 8);
		else
			case RegSel  is
				when "000" => S0 <= reg(7 downto 0);  --r0
								  S1 <= (others => '0');
				when "001" => S0 <= reg(15 downto 8); --r1
								  S1 <= (others => '0');
				when "010" => S0 <= reg(23 downto 16);--r2
								  S1 <= (others => '0');
				when "011" => S0 <= reg(31 downto 24);--r3
								  S1 <= (others => '0');
				when "100" => S0 <= reg(39 downto 32);--r4
								  S1 <= (others => '0');
				when "101" => S0 <= reg(47 downto 40);--r5
								  S1 <= (others => '0');	
				when "110" => S0 <= reg(55 downto 48);--r6
								  S1 <= (others => '0');
				when others => S0 <= reg(63 downto 56);--r7
								  S1 <= (others => '0');
			end case;
		end if;
	end process;
	
end Behavioral;
