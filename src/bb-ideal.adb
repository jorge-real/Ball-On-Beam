--------------------------------------------------------------------------------
--                                                                            --
--                               B B . I D E A L                              --
--                     Ball on Beam Simulator - Ideal interface               --
--                                                                            --
--                                    Body                                    --
--                                                                            --
--  Ideal interface to the Ball on Beam system.                               --
--                                                                            --
--  Author: Jorge Real                                                        --
--          Universitat Politecnica de Valencia                               --
--  July, 2020 - Version 1                                                    --
--  February, 2021 - Version 2                                                --
--                                                                            --
--------------------------------------------------------------------------------

package body BB.Ideal is

   --------------------
   -- Set_Beam_Angle --
   --------------------

   procedure Set_Beam_Angle (Inclination : Angle) renames
     BB.Set_Beam_Angle;

   -------------------
   -- Ball_Position --
   -------------------

   function Ball_Position return Position renames
     BB.Ball_Position;

end BB.Ideal;
