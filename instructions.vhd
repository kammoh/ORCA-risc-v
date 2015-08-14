library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
library work;

package instructions is
  function ARITH_INSTR (immediate, rs1, rd : integer; func : std_logic_vector(2 downto 0))
    return std_logic_vector;

  function ADDI (dest, srcreg, immediate : integer)
    return std_logic_vector;
  function SB (src, base, offset : integer)
    return std_logic_vector;
  function SH (src, base, offset : integer)
    return std_logic_vector;
  function SW (src, base, offset : integer)
    return std_logic_vector;

  function LB (dest, base, offset : integer)
    return std_logic_vector;
  function LH (dest, base, offset : integer)
    return std_logic_vector;
  function LW (dest, base, offset : integer)
    return std_logic_vector;
  function LBU (dest, base, offset : integer)
    return std_logic_vector;
  function LHU (dest, base, offset : integer)
    return std_logic_vector;


  function BRANCH (src1, src2, offset : integer; func : signed(2 downto 0))
    return std_logic_vector;
  function BEQ (src1, src2, offset : integer)
    return std_logic_vector;
  function BNE (src1, src2, offset : integer)
    return std_logic_vector;
  function JAL(dst, offset : integer)
    return std_logic_vector;

  function LUI (dst, imm : integer)
    return std_logic_vector;

  function NOP(nul : integer)
    return std_logic_vector;
end instructions;
package body instructions is

  function ARITH_INSTR (
    immediate, rs1, rd : integer;
    func               : std_logic_vector(2 downto 0))
    return std_logic_vector is
  begin
    return std_logic_vector(to_signed(immediate, 12)) &
      std_logic_vector(to_unsigned(rs1, 5))& func &
      std_logic_vector(to_unsigned(rd, 5))&"0010011";
  end;

  function ADDI (
    dest, srcreg, immediate : integer)
    return std_logic_vector is
  begin
    return ARITH_INSTR(immediate, srcreg, dest, "000");
  end;

  -- load store
  function SB (src, base, offset : integer)
    return std_logic_vector is
    variable imm : signed(11 downto 0);
  begin
    imm := to_signed(offset, 12);
    return std_logic_vector(imm(11 downto 5) &to_signed(src, 5) &
                            to_signed(base, 5)&"000"&imm(4 downto 0)&"0100011");
  end;
  function SH (src, base, offset : integer)
    return std_logic_vector is
    variable imm : signed(11 downto 0);
  begin
    imm := to_signed(offset, 12);
    return std_logic_vector(imm(11 downto 5) &to_signed(src, 5) &
                            to_signed(base, 5)&"001"&imm(4 downto 0)&"0100011");
  end;
  function SW (src, base, offset : integer)
    return std_logic_vector is
    variable imm : signed(11 downto 0);
  begin
    imm := to_signed(offset, 12);
    return std_logic_vector(imm(11 downto 5) &to_signed(src, 5) &
                            to_signed(base, 5)&"010"&imm(4 downto 0)&"0100011");
  end;
--load
  function LB (dest, base, offset : integer)
    return std_logic_vector is
    variable imm : signed(11 downto 0);
  begin
    return std_logic_vector(to_signed(offset, 12) & to_signed(base, 5)&"000"&to_signed(dest, 5)&"0000011");
  end;
  function LH (dest, base, offset : integer)
    return std_logic_vector is
    variable imm : signed(11 downto 0);
  begin
    return std_logic_vector(to_signed(offset, 12) & to_signed(base, 5)&"001"&to_signed(dest, 5)&"0000011");
  end;
  function LW (dest, base, offset : integer)
    return std_logic_vector is
    variable imm : signed(11 downto 0);
  begin
    return std_logic_vector(to_signed(offset, 12) & to_signed(base, 5)&"010"&to_signed(dest, 5)&"0000011");
  end;
  function LBU (dest, base, offset : integer)
    return std_logic_vector is
    variable imm : signed(11 downto 0);
  begin
    return std_logic_vector(to_signed(offset, 12) & to_signed(base, 5)&"100"&to_signed(dest, 5)&"0000011");
  end;
  function LHU (dest, base, offset : integer)
    return std_logic_vector is
    variable imm : signed(11 downto 0);
  begin
    return std_logic_vector(to_signed(offset, 12) & to_signed(base, 5)&"101"&to_signed(dest, 5)&"0000011");
  end;
  --branch instructions
  function BRANCH (src1, src2, offset : integer;
                   func               : signed(2 downto 0))
    return std_logic_vector is
    variable imm : signed(12 downto 0);
  begin
    imm := to_signed(offset, 13);
    return std_logic_vector(imm(12)&imm(10 downto 5)&to_signed(src2, 5)
                            &to_signed(src1, 5)& func &
                            imm(4 downto 1)& imm(11) & "1100011");
  end;
  function BEQ (src1, src2, offset : integer)
    return std_logic_vector is
  begin
    return BRANCH(src1, src2, offset, "000");
  end;
  function BNE (src1, src2, offset : integer)
    return std_logic_vector is
  begin
    return BRANCH(src1, src2, offset, "001");
  end;

  function JAL(dst, offset : integer)
    return std_logic_vector is
    variable i : signed(20 downto 0);
  begin
    i := to_signed(offset, 21);
    return std_logic_vector(i(20) &i(10 downto 1) & i(11) & i(19 downto 12) &
                            to_signed(dst, 5)&"1101111");
  end;

  function LUI (dst, imm : integer)
    return std_logic_vector is
    variable i : signed(31 downto 0);
  begin
    i := to_signed(imm, 32);
    return std_logic_vector(i(31 downto 12) & to_signed(dst, 5) & "0110111");
  end;
--alias for addi x0 x0 0
  function NOP(nul : integer)
    return std_logic_vector is
  begin
    return ADDI(0, 0, 0);
  end;
end instructions;
