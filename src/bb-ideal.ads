--------------------------------------------------------------------------------
--                                                                            --
--                               B B . I D E A L                              --
--                     Ball on Beam Simulator - Ideal interface               --
--                                                                            --
--                                    Spec                                    --
--                                                                            --
--  Ideal interface to the Ball on Beam system.                               --
--                                                                            --
--  Author: Jorge Real                                                        --
--          Universitat Politecnica de Valencia                               --
--  July, 2020 - Version 1                                                    --
--  February, 2021 - Version 2                                                --
--                                                                            --
--  This is free software in the ample sense: you can use it freely,          --
--    provided you preserve this comment at the header of source files and    --
--    you clearly indicate the changes made to the original file, if any.     --
--                                                                            --
--------------------------------------------------------------------------------
package BB.Ideal is

   procedure Set_Beam_Angle (Inclination : Angle);
   --  Set the beam inclination angle, in degrees.

   function Ball_Position return Position;
   --  Returns the simulated ball position, in mm.

end BB.Ideal;
