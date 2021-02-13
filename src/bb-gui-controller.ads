------------------------------------------------------------
--           B B . G U I . C O N T R O L L E R            --
--                                                        --
--                         Spec                           --
--                                                        --
--  "Controller" package of Ball on Beam simulator GUI.   --                                                        --
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

with Gnoga.Gui.Window;

package BB.GUI.Controller is

   procedure Create_GUI
     (Main_Window : in out Gnoga.Gui.Window.Window_Type'Class);

end BB.GUI.Controller;
