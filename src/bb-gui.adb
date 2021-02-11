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

with BB.GUI.Controller;
with Gnoga.Application.Singleton;
with Gnoga.Gui.Window;

with Ada.Exceptions;

package body BB.GUI is

   ------------------
   -- GUI_Setpoint --
   ------------------

   procedure GUI_Setpoint (Target_Pos : Position) is
   begin
      Current_Target_Pos := Target_Pos;
   end GUI_Setpoint;

   Main_Window : Gnoga.Gui.Window.Window_Type;

   --  Package initialisation
begin

   Gnoga.Application.Title ("Ball on Beam Simulator");
   Gnoga.Application.HTML_On_Close
     ("Connection to <b>Ball on Beam Simulator</b> has been terminated.");
   Gnoga.Application.Open_URL ("http://127.0.0.1:8080");
   Gnoga.Application.Singleton.Initialize (Main_Window, Port => 8080);

   BB.GUI.Controller.Create_GUI (Main_Window);

exception
   when E : others =>
      Gnoga.Log (Ada.Exceptions.Exception_Name (E) & " - " &
                   Ada.Exceptions.Exception_Message (E));
end BB.GUI;
