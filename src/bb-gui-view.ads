------------------------------------------------------------
--                 B B . G U I . V I E W                  --
--                                                        --
--                         Spec                           --
--                                                        --
--  "View" package of Ball on Beam simulator GUI.         --
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

with Gnoga.Gui.Base;
with Gnoga.Gui.Element.Common;
with Gnoga.Gui.Element.Canvas.Context_2D;
with Gnoga.Gui.View.Grid;

package BB.GUI.View is
   
   --  Size of canvas to display animation and graph
   Canvas_X_Size : constant := 500;
   Canvas_Y_Size : constant := 400;
   
   type Default_View_Type is new Gnoga.Gui.View.Grid.Grid_View_Type with
      record
         BB_Anim_View    : Gnoga.Gui.View.View_Type;
         BB_Anim_Canvas  : Gnoga.Gui.Element.Canvas.Canvas_Type;
         BB_Animation    : Gnoga.Gui.Element.Canvas.Context_2D.Context_2D_Type;
         
         BB_Graph_View   : Gnoga.Gui.View.View_Type;
         BB_Graph_Canvas : Gnoga.Gui.Element.Canvas.Canvas_Type;
         BB_Pos_Graph    : Gnoga.Gui.Element.Canvas.Context_2D.Context_2D_Type;
                  
         Quit_Button     : Gnoga.Gui.Element.Common.Button_Type;
         Pause_Button    : Gnoga.Gui.Element.Common.Button_Type;
      end record;

   type Default_View_Access is access all Default_View_Type;
   type Pointer_to_Default_View_Class is access all Default_View_Type'Class;

   
   procedure Create
     (View   : in out Default_View_Type;
      Parent : in out Gnoga.Gui.Base.Base_Type'Class;
      ID     : in     String  := "");     
   
end BB.GUI.View;
