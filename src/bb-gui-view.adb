------------------------------------------------------------
--                 B B . G U I . V I E W                  --
--                                                        --
--                         Body                           --
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

package body BB.GUI.View is

   ------------
   -- Create --
   ------------
   
   procedure Create
     (View   : in out Default_View_Type;
      Parent : in out Gnoga.Gui.Base.Base_Type'Class;
      ID     : in     String  := "")
   is
      use Gnoga.Gui.View.Grid;
      use Gnoga.Gui.Element.Canvas.Context_2D;
   begin
      --  Creation of a grid view of elements
      Gnoga.Gui.View.Grid.Grid_View_Type 
        (View).Create (Parent      => Parent,
                       Layout      => ((COL, COL),
                                       (COL, COL)),
                       Fill_Parent => True,
                       Set_Sizes   => True,
                       ID          => ID);

      --  Creation of animated simulation area
      View.BB_Anim_View.Create (View.Panel (1, 1).all);
      View.BB_Anim_Canvas.Create (Parent => View.BB_Anim_View,
                                  Width  => Canvas_X_Size,
                                  Height => Canvas_Y_Size,
                                  ID     => "Animation");
      View.BB_Animation.Get_Drawing_Context_2D (Canvas  => View.BB_Anim_Canvas);
      
      View.BB_Anim_View.Font (System_Font => Gnoga.Gui.Element.Message_Box);

      View.BB_Anim_Canvas.Border;
      
      
      --  Creation of graph area
      View.BB_Graph_View.Create (View.Panel (1, 2).all);
      View.BB_Graph_Canvas.Create (Parent => View.BB_Graph_View,
                                  Width  => Canvas_X_Size,
                                  Height => Canvas_Y_Size,
                                  ID     => "Position graph");
      View.BB_Pos_Graph.Get_Drawing_Context_2D (Canvas  => View.BB_Graph_Canvas);
      
      View.BB_Graph_View.Font (System_Font => Gnoga.Gui.Element.Message_Box);

      View.BB_Graph_Canvas.Border;
      
      --  Creation of Quit and Pause plot buttons
      View.Quit_Button.Create (View.Panel (2, 1).all, "Quit");
      View.Pause_Button.Create (View.Panel (2, 2).all, " > / || ");
   end Create;

end BB.GUI.View;
