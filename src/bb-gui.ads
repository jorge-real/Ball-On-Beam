------------------------------------------------------------
--                      B B . G U I                       --
--                                                        --
--                         Spec                           --
--                                                        --
--  Graphical User Interface for the Ball on Beam system. --
--                                                        --
--  Author: Jorge Real                                    --
--  Universitat Politecnica de Valencia                   --
--  July, 2020 - Version 1                                                    --
--  February, 2021 - Version 2                                                --
--                                                        --
--  This is free software in the ample sense:             --
--  you can use it freely, provided you preserve          --
--  this comment at the header of source files            --
--  and you clearly indicate the changes made to          --
--  the original file, if any.                            --
------------------------------------------------------------

package BB.GUI is

   procedure GUI_Setpoint (Target_Pos : Position);
   --  Tell the current setpoint to the GUI (in control applications).
   --  The target position is plotted in the graph area of the animation, and
   --    indicated by a marker drawn on the beam itselg. If this procedure is
   --    never called, the plotted setpoint value is always 0.0 and the target
   --    marker appears at the center of the beam.

private

   Current_Target_Pos : Position := 0.0 with Atomic;
   --  Current target position of ball in control applications written by client
   --  application, read from task BB.GUI.Controller.Update_Animation.

end BB.GUI;
