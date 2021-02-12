--------------------------------------------------------------------------------
--                                                                            --
--                                  B B . A D C                               --
--                                                                            --
--                                     Spec                                   --
--                                                                            --
--                                                                            --
--                                                                            --
--  This package implements an A/D converter interface with a ball position   --
--  sensor, instead of the "ideal" results produced by function Ball_Position --
--  of package BB.Ideal.                                                      --
--  Instead of the exact ball position, the ADC converter returns a 12-bit    --
--  A/D conversion that needs be scaled to give a position value in mm. The   --
--  conversion has gaussian random noise added to better emulate reality and  --
--  to motivate the use of some form of filtering.                            --
--                                                                            --
--  Author: Jorge Real                                                        --
--  Universitat Politecnica de Valencia                                       --
--  December, 2020 - Version 1                                                --
--  February, 2021 - Version 2                                                --
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
   --  Max_Position (both declared in Ball_On_Beam_Simulator - spec).        --
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
   --      A/D conversion. The end of conversion is reflected in bit EOC of  --
   --      the ADC, besides causing the simulated interrupt when IE is set.  --
   --                                                                        --
   --  The simulated DR uses:                                                --
   --    bits 0..11 (ADC_Count): to store 12-bit conversions.                --
   --    bit 15 (EOC): to signal end of conversions. This bit is set upon    --
   --       completion of an A/D conversion. EOC is reset every time the TRG --
   --       bit in the CR is set.                                            --
   --                                                                        --
   ----------------------------------------------------------------------------

   --  Type of values written to the CR or read from the DR
   type ADC_Register is mod 2 ** 16
     with Size => 16;

   --  Write a value to the Control Register
   procedure Write_CR (Value : ADC_Register);

   --  Read the Data Register
   function Read_DR return ADC_Register;

   --  A user handler is a parameterless procedure
   type ADC_Handler_Access is access procedure;

   --  Attach a user handler for ADC end-of-conversion interrupts
   procedure Attach_ADC_Handler (Handler : ADC_Handler_Access);

end BB.ADC;
