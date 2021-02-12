------------------------------------------------------------
--           B B . G U I . C O N T R O L L E R            --
--                                                        --
--                         Spec                           --
--                                                        --
--  "Controller" package of BB.GUI.                       --                                                        --                                                        --
--                                                        --
--  Author: Jorge Real                                    --
--  Universitat Politecnica de Valencia                   --
--  July, 2020 - Version 1                                --
--  February, 2021 - Version 2                            --
--                                                        --
------------------------------------------------------------

with Gnoga.Gui.Window;

package BB.GUI.Controller is

   procedure Create_GUI
     (Main_Window : in out Gnoga.Gui.Window.Window_Type'Class);

end BB.GUI.Controller;
