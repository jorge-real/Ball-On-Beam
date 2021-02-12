--------------------------------------------------------------------------------
--                                                                            --
--                        B A L L _ O N _ B E A M _ A D C                     --
--                                                                            --
--                                     Body                                   --
--                                                                            --
--  This package implements an A/D converter interface with the position      --
--  sensor of package Ball_On_Beam_Simulator, instead of the "ideal" results  --
--  produced by function Ball_Position of that package.                       --
--  The ADC converter transforms the result of Ball_Position into a 12-bit    --
--  conversion. The conversion has some random noise added, with gaussian     --
--  distribution to better emulate reality and to motivate the need for using --
--  some form of filtering.                                                   --
--                                                                            --
--  Author: Jorge Real                                                        --
--  Universitat Politecnica de Valencia                                       --
--  December, 2020 - Version 1                                                --
--  February, 2021 - Version 2                                                --
--                                                                            --
--------------------------------------------------------------------------------

with Ada.Real_Time;               use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;

with Ada.Numerics;                       use Ada.Numerics;
with Ada.Numerics.Float_Random;          use Ada.Numerics.Float_Random;
with Ada.Numerics.Elementary_Functions;  use Ada.Numerics.Elementary_Functions;

package body BB.ADC is

   --  The following procedures just call the implementation in package
   --  Ball_On_Beam_Simulator. Ball_On_Beam_ADC only modifies the interface
   --  with the position sensor, emulating an A/D converter
   procedure Set_Beam_Angle (Inclination : Angle) renames
     BB.Set_Beam_Angle;

   procedure Set_Simulation_Mode (Mode : Simulation_Mode) renames
   BB.Set_Simulation_Mode;

   --  Move system to a solar system object
   procedure Move_BB_To (Where : in Solar_System_Object) renames
      BB.Move_BB_To;

   --  ADC implementation

   --  Latency of conversion
   Conversion_Delay : Time_Span := Milliseconds (2);

   --  To simulate gaussian noise in the ADC
   Noise : Generator;
   --  Standard deviation of noise
   Sigma : constant := 4.0;

   --  Protected object for ADC interrupt simulation
   protected ADC is
      pragma Interrupt_Priority;

      procedure Set_User_Handler (UH : ADC_Handler_Access);
      function Conversion_Result return ADC_Register;
      procedure Write_CR (Value : ADC_Register);
   private
      ADC_Interrupt : Timing_Event;
      procedure ADC_Int_Handler (TE : in out Timing_Event);
      Interrupt_Enabled : Boolean := False;
      User_Handler : ADC_Handler_Access;
      User_Handler_Is_Set : Boolean := False;
      Conversion : ADC_Register := 0;
   end ADC;

   protected body ADC is

      function Conversion_Result return ADC_Register is (Conversion);

      procedure Set_User_Handler (UH : ADC_Handler_Access) is
      begin
         User_Handler := UH;
         User_Handler_Is_Set := True;
      end Set_User_Handler;

      procedure Write_CR (Value : ADC_Register) is
         IE  : constant Boolean := ((Value / 4) mod 2) /= 0; --  bit 2
         TRG : constant Boolean := (Value mod 2) /= 0;       --  bit 0
      begin
         if IE then
            Interrupt_Enabled := True;
         else
            Interrupt_Enabled := False;
         end if;

         if TRG then
            --  Set TE for end-of-conversion interrupt
            Set_Handler (Event   => ADC_Interrupt,
                         At_Time => Clock + Conversion_Delay,
                         Handler => ADC_Int_Handler'Access);
            --  Clear EOC bit
            Conversion := Conversion and 16#7FFF#;
         end if;
      end Write_CR;

      procedure ADC_Int_Handler (TE : in out Timing_Event) is

         --  Simulated ball position, with gaussian random noise added
         --  Gaussian random obtained using the Box-Muller method
         Simulated_Position : constant Float := Ball_Position +
           (Sigma * Sqrt (-2.0 * Log (Random (Noise), Ada.Numerics.e)) *
                Cos (2.0 * Pi * Random (Noise)));

         --  Aux is assigned the Simulated_Position scaled to an ADC value. The
         --    Simulated_Position could over/underflow the range of Position,
         --    due to the addition of noise. Hence the convenience of this Aux
         --    variable before we saturate the conversion to fall within the
         --    range (0..4095), first thing we do in the body of this handler.
         Aux : Integer :=
           Integer (( (Simulated_Position - Position'First) * 4096.0) /
                    (Position'Last - Position'First));

      begin
         --  Saturate Aux to a range representable with 12 bits in NBC. Needed
         --  because the addition of noise may over/underflow that range
         Aux := Integer'Max (0,   Aux);
         Aux := Integer'Min (Aux, 4095);

         --  Set the EOC bit in the Data register
         Conversion := ADC_Register (Aux) or 16#8000#;

         --  Execute user handler if interrupts are enabled and a handler is set
         if Interrupt_Enabled and then User_Handler_Is_Set then
            User_Handler.all;
         end if;
      end ADC_Int_Handler;

   end ADC;

   ------------------------
   -- Attach_ADC_Handler --
   ------------------------

   procedure Attach_ADC_Handler (Handler : ADC_Handler_Access) is
   begin
      ADC.Set_User_Handler (Handler);
   end Attach_ADC_Handler;

   --------------
   -- Write_CR --
   --------------

   procedure Write_CR (Value : ADC_Register) is
   begin
      ADC.Write_CR (Value);
   end Write_CR;

   -------------
   -- Read_DR --
   -------------

   function Read_DR return ADC_Register is (ADC.Conversion_Result);

begin

   Reset (Noise);

end BB.ADC;
