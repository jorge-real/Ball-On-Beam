----------------------------------------------------------------------------
--                                                                            --
--                        B A L L _ O N _ B E A M _ A D C                     --
--                                                                            --
--                                     Spec                                   --
--                                                                            --
--                                                                            --
--  Author: Jorge Real                                                        --
--  Universitat Politecnica de Valencia                                       --
--  December, 2020 - Version 1                                                --
--  February, 2021 - Version 2                                                --
--                                                                            --
--                                                                            --
--  This package implements an A/D converter interface with the position      --
--  sensor of package Ball_On_Beam_Simulator, instead of the "ideal" results  --
--  produced by function Ball_Position of that package.                       --
--  The ADC converter transforms the result of Ball_Position into a 12-bit    --
--  conversion. The conversion has some random noise added, with gaussian     --
--  distribution to better emulate reality and to motivate the need for using --
--  some form of filtering.                                                   --
--                                                                            --
--  This is free software in the ample sense:                                 --
--  you can use it freely, provided you preserve                              --
--  this comment at the header of source files                                --
--  and you clearly indicate the changes made to                              --
--  the original file, if any.                                                --
--                                                                            --
--------------------------------------------------------------------------------

package BB.ADC is

   procedure Set_Beam_Angle (Inclination : Angle);
   --  Set the beam inclination angle, in degrees.

   ----------------------------------------------------------------------------
   --                  Analog to Digital Converter section                   --
   ----------------------------------------------------------------------------
   --                                                                        --
   --  An analog position sensor is connected to this 12-bit ADC. The range  --
   --  of conversion is such that 0 corresponds to Min_Position and 4095 to  --
   --  Max_Position (both declared in BB - spec).                            --
   --                                                                        --
   --  There are two registers in the ADC adapter: Control Register (CR) and --
   --  Data Register (DR). Both are 16-bit wide. CR is read-only, DR is R/W. --
   --                                                                        --
   --  The simulated CR is a 16-bit word with two useful bits:               --
   --    bit 2 (IE): Interrupt Enable bit. When set, the end of an ADC       --
   --      conversion causes a simulated End_Of_Conversion interrupt for     --
   --      which a user program may attach a library-level, parameterless    --
   --      handling procedure.                                               --
   --    bit 0 (TRG): "trigger conversion" bit. When set, it triggers a new  --
   --      A/D conversion. The end of conversion is reflected in bit EOC     --
   --      (in DR), and causes the simulated interrupt when IE is set.       --
   --                                                                        --
   --  The simulated DR uses:                                                --
   --    bits 0..11 (ADC_Count): to store the last 12-bit conversion.        --
   --    bit 15 (EOC): to signal end of conversions. This bit is set upon    --
   --       completion of an A/D conversion. EOC is reset every time the TRG --
   --       bit in the CR is set.                                            --
   --                                                                        --
   ----------------------------------------------------------------------------

   type ADC_Register is mod 2 ** 16
     with Size => 16;
   --  Type of values written to the CR or read from the DR

   procedure Write_CR (Value : ADC_Register);
   --  Write a value to the Control Register

   function Read_DR return ADC_Register;
   --  Read the Data Register

   type ADC_Handler_Access is access procedure;
   --  A user handler is a parameterless procedure

   procedure Attach_ADC_Handler (Handler : ADC_Handler_Access);
   --  Attach a user handler for ADC end-of-conversion interrupts

end BB.ADC;
