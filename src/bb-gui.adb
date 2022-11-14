------------------------------------------------------------
--                      B B . G U I                       --
--                                                        --
--                         Spec                           --
--                                                        --
--  Graphical User Interface for the Ball on Beam system. --
--                                                        --
--  Author: Jorge Real                                    --
--  Universitat Politecnica de Valencia                   --
--  July, 2020 - Version 1                                --
--  February, 2021 - Version 2                            --
--                                                        --
--  This is free software in the ample sense:             --
--  you can use it freely, provided you preserve          --
--  this comment at the header of source files            --
--  and you clearly indicate the changes made to          --
--  the original file, if any.                            --
------------------------------------------------------------

with BB.GUI.Controller;

with Gnoga.Application.Singleton;

--  To use a native GTk window for the GUI, instead of browser
--  with Gnoga.Application.Gtk_Window;

with Gnoga.Gui.Window;

with UXStrings;

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

   --
   --  --  For native Gtk window (not working on newer Debians at least from 2020):
   --  (You need to uncomment the "with" clause for Gnoga.Application.Gtk_Window)
   --  --  1: use the proper initialize for a Gtk window
   --  --  Gnoga.Application.Gtk_Window.Initialize (Port => 8080, Width => 1150, Height => 550);
   --
   --  --  2: set Verbose to False in the call to Initialize
   --  --  Gnoga.Application.Singleton.Initialize (Main_Window => Main_Window, Verbose => False);

   --  For browser window:
   --  (Comment out the "with" clause for Gnoga.Application.Gtk_Window)
   Gnoga.Application.Open_URL ("http://127.0.0.1:8080");
   Gnoga.Application.Singleton.Initialize (Main_Window, Port => 8080);

   --  For either native or browser:
   BB.GUI.Controller.Create_GUI (Main_Window);

exception
   when E : others =>
      declare
         use UXStrings;

         Msg : UXString := From_ASCII
           ("Exception caught during initialization of package BB.GUI:" &
              Ada.Exceptions.Exception_Name (E) & " - " &
              Ada.Exceptions.Exception_Message (E));
      begin
         Gnoga.Log (Msg, E);
      end;
end BB.GUI;
