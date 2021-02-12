------------------------------------------------------------
--           B B . G U I . C O N T R O L L E R            --
--                                                        --
--                         Body                           --
--                                                        --
--  "Controller" package of BB.GUI.                       --                                                        --                                                        --
--                                                        --
--  Author: Jorge Real                                    --
--  Universitat Politecnica de Valencia                   --
--  July, 2020 - Version 1                                --
--  February, 2021 - Version 2                            --
--                                                        --
------------------------------------------------------------

with BB.GUI.View;
use BB.GUI.View;

with Gnoga.Gui.Base;
with Gnoga.Gui.Element.Canvas.Context_2D;
with Gnoga.Application.Singleton;
with Gnoga.Types;

with System;
with Ada.Numerics.Elementary_Functions;

with Ada.Real_Time;  use Ada.Real_Time;

package body BB.GUI.Controller is

   View : BB.GUI.View.Default_View_Access :=
     new BB.GUI.View.Default_View_Type;
   
   Simulation_Running : Boolean := True;
   Updater_Terminated : Boolean := False;
   
      --  GUI refresh period
   Updater_Period : constant Duration := 0.1;
   
   --  Declaration of procedure in charge of updating the GUI
   procedure Update_Animation
     (Inclination : Angle;
      Ball_Pos    : Position;
      Target_Pos  : Position);

   --  Quit button On_Click handler
   procedure On_Quit (Object : in out Gnoga.Gui.Base.Base_Type'Class) is
   begin
      --  Inform updater task to terminate
      Simulation_Running := False;
      --  Poll for updater task terminated
      while not Updater_Terminated loop
         delay 0.05;
      end loop;
      Gnoga.Application.Singleton.End_Application;
   end On_Quit;
   
   --  Pause plot button On_Click handler
   Paused : Boolean := False;
   procedure On_Pause (Object : in out Gnoga.Gui.Base.Base_Type'Class) is
   begin
      Paused := not Paused;
      if Paused then
         null; --  release updater task in controller
         --  View.Pause_Button.Property (Name  => ,
                                     --  Value => "Unpause plot");
      else
         null; --  pause updater task
         --  View.Pause_Button.Property (Name  => ,
                                     --  Value => "Pause plot");
      end if;
   end On_Pause;
   
   --  Updater - Task in charge of refreshing the GUI window. 
   --  It uses Last_Angle and Last_Pos, so it doesn't imply calculation of
   --  simulation steps.
   task Updater 
     with Priority => System.Priority'First;
   
   task body Updater is
      Next : Time := Clock;
      Refresh_Period : constant Time_Span := To_Time_Span (Updater_Period);
   begin
      while Simulation_Running loop
         Next := Next + Refresh_Period;
         delay until Next;
         Update_Animation (Last_Angle, Last_Pos, Current_Target_Pos);
      end loop;
      Updater_Terminated := True;
   end Updater;
      
   --  Declarations for Update_Animation

   --  Graphical coordinates of pivot point for all rotations
   --  Integer versions for coordinates
   x0c : constant := Canvas_X_Size / 2;
   y0c : constant := Canvas_Y_Size / 2;
   --  Float versions, for trigonometry
   x0  : constant := Float (x0c);
   y0  : constant := Float (y0c);
   
   --  Rectangles that cover the Animation and Status areas

   Cover_Animated_BB : constant Gnoga.Types.Rectangle_Type := 
     (X => 20, Y =>  20, Width => Canvas_X_Size - 40,
      Height => Canvas_Y_Size - 40);
   Cover_Plot : constant Gnoga.Types.Rectangle_Type := 
     (X => 30, Y =>  20, Width => Canvas_X_Size - 45,
      Height => Canvas_Y_Size - 50);   
   
   --  Background of the animation area (rectangle, beam pier, and labels)
   Anim_Background : Gnoga.Gui.Element.Canvas.Context_2D.Image_Data_Type;
   
   --  Background of the plot area (axis marks, labels, and grid)
   Plot_Background : Gnoga.Gui.Element.Canvas.Context_2D.Image_Data_Type;
   
   --  Scaling factor between 340 pixels of drawn beam (with some leeway for the 
   --  stoppers at both ends) and the beam length
   X_Beam_Scaling : constant Float := 340.0 / (Max_Position - Min_Position);
   
   --  Declaratons for the graph view
   --  Vertical axis: ball position in millimeters
   Y_Min_Pos  : constant Float := Position'First;
   Y_Max_Pos  : constant Float := Position'Last;
   
   --  Horizontal axis: time in seconds
   X_Min_Time : constant :=  0.0;
   X_Max_Time : constant := 12.0;
   
   --  Values over the range of Position that will be included in the Y axis. 
   --  This is so that saturated values can be clearly seen in the graph.
   --  The graph range will be [Min_Position - Over .. Max_Postion + Over]
   Over : constant := 10.0;   
   
   Y_Plot_Scaling : constant := 
     (Float (Canvas_Y_Size) - 50.0) / (Y_Max_Pos - Y_Min_Pos + (2.0 * Over));
   --  Pixel / mm
   
   X_Plot_Scaling : constant := 
     (Float (Canvas_X_Size) - 45.0) / (X_Max_Time - X_Min_Time);
   -- Pixel / s
   
   --  Number of points that will be plotted
   List_Length : constant :=  
     Integer ((X_Max_Time - X_Min_Time) / Updater_Period);
   
   --  Nr of pixels in X between two consecutive updater samples. Keep it Float
   --  and use as an integer later, when plotting, to avoid cummulative error
   Delta_X : constant Float := X_Plot_Scaling * Float (Updater_Period);
   
   type Position_Plot is array (1..List_Length) of Position;
   --  Plot values
   Pos_Plot      : Position_Plot := (others => 0.0);
   Target_Plot   : Position_Plot := (others => 0.0);
   
   --  Counter of valid points in a Position_Plot array. The algorithm for
   --  plotting is different for the first List_Length values to plot, since
   --  there is no need to scroll the plot until the number of values to plot
   --  is larger than List_Length
   N_Plot_Points : Integer := 0;
   
   --  X coordinate of target value when printed in the status area
   Target_Text_X_Offset : Integer;
   
   ------------------------
   --  Update_Animation  --
   ------------------------
   --  Updates the ball and beam animation. 
   --  If plot refresh is not paused, it also updates the plot
   procedure Update_Animation 
     (Inclination : Angle;
      Ball_Pos    : Position;
      Target_Pos  : Position) is
      
      use Ada.Numerics.Elementary_Functions;
      use Ada.Numerics;
      
      --  Auxiliaries for printing the lower status line
      --  Scaled angle to extract two decimals
      Aux_Angle : constant Integer := Integer (Inclination * 100.0);
      --  String that contains the integer part of Angle
      Angle_Int : constant String  := Integer'Image (Aux_Angle  /  100);
      --  String that contains the decimal part of Angle, lead by a space
      Angle_Dec : constant String  := Integer'Image (Aux_Angle mod 100);
      --  String that represents the position in mm
      Pos_Str   : constant String  := Integer'Image (Integer (Ball_Pos));
      --  String that represents the target position in mm
      Tgt_Str   : constant String  := Integer'Image (Integer (Target_Pos));
      
      --  Auxiliaries for drawing
      --  Angle in radians for trigonometrical functions
      Ang : constant Float := (Inclination * Pi) / 180.0;
      
      Sin_A : constant Float := Sin (-Ang);
      Cos_A : constant Float := Cos (-Ang);
      
      --  Coordinates of Ball center at Ball_Pos when Angle = 0.0
      X_Pos_0: constant Float := x0 + Ball_Pos * X_Beam_Scaling;
      Y_Pos_0: constant Float := y0 - 20.0;
      
      --  Coordinates of top of target marker when Angle = 0.0
      X_Tgt_0: constant Float := x0 + Target_Pos * X_Beam_Scaling;
      Y_Tgt_0: constant Float := y0 - 10.0;

      
      --  Rotation transform functions:
      --
      --  x' = x0 - (x - x0)*cos(Ang) - (y - y0)*sin(Ang)
      --  y' = y0 + (x - x0)*sin(Ang) - (y - y0)*cos(Ang)
      --  
      --  where: (x0, y0) = pivot point (declared global constants)
      --         (X, Y) = Coordinates of point to rotate when Angle = 0.0
      --
      --  With sign variations depending on which object is rotated, the
      --  beam, the ball, or the target marker.
      
      function X_Beam (X, Y: Float) return Integer is
        (Integer (x0 - (X - x0) * Cos_A - (Y - y0) * Sin_A));
      function Y_Beam (X, Y: Float) return Integer is
        (Integer (y0 - (X - x0) * Sin_A + (Y - y0) * Cos_A));
      
      function X_Ball (X, Y: Float) return Integer is
        (Integer (x0 + (X - x0) * Cos_A - (Y - y0) * Sin_A));
      function Y_Ball (X, Y: Float) return Integer is
        (Integer (y0 + (X - x0) * Sin_A + (Y - y0) * Cos_A));
      
      --  Same transform for target position marker as for the ball
      function X_Tgt (X, Y: Float) return Integer renames X_Ball;
      function Y_Tgt (X, Y: Float) return Integer renames Y_Ball;
      
      X_Plot_Offset : Integer;
            
   begin
      ----------------------------------
      --  Redraw the animation panel  --
      ----------------------------------

      --  Put background image of animation panel
      View.BB_Animation.Put_Image_Data (Anim_Background, 0, 0);
      
      --  Update status info
      View.BB_Animation.Fill_Color ("Black");
      View.BB_Animation.Fill_Text 
        (Angle_Int & "." & 
           Angle_Dec (Angle_Dec'First + 1 .. Angle_Dec'Last) & 
           " deg", 150 + 38, Canvas_Y_Size - 5);
      View.BB_Animation.Fill_Text 
        (Pos_Str & " mm", 270 + 47, Canvas_Y_Size - 5);
      View.BB_Animation.Fill_Text
        ("        ", (Canvas_X_Size / 2) - 20, 14);
      View.BB_Animation.Fill_Text
        (Current_Planet'Image, (Canvas_X_Size / 2) - 20, 14);
            
      --  Draw beam with angle given by Inclination
      --
      --  Four symmetric points define the beam shape: Outer top (OTop), 
      --    Inner top (ITop), Middle pint (Mid), and Outer bottom (OBot).
      --    For example, OTop opposes -OTop, with respect to symmetry axis 
      --    defined by the orthogonal to the beam that crosses the pivot point.
      --
      --   -ITop                   |Symmetry              OTop
      --     ^                     .axis                   ^
      --  -OTop                    |                   ITop
      --   ^_   -Mid     Negative  .   Positive     Mid  ^_
      --   | | /        positions  |   positions       \ | |
      --   | |/____________________.____________________\| |
      --   |_______________________|_______________________| 
      --   ^ -OBot                 ^                       ^ OBot
      --                     Pivot point (x0, y0)
      
      View.BB_Animation.Fill_Color ("Maroon");
      View.BB_Animation.Begin_Path;
      View.BB_Animation.Move_To (X_Beam (x0 - 180.0, y0), 
                                 Y_Beam (x0 - 180.0, y0));         -- a  -OBot
      View.BB_Animation.Line_To (X_Beam (x0 + 180.0, y0), 
                                 Y_Beam (x0 + 180.0, y0));         -- b   OBot
      View.BB_Animation.Line_To (X_Beam (x0 + 180.0, y0 - 25.0), 
                                 Y_Beam (x0 + 180.0, y0 - 25.0));  -- c   OTop
      View.BB_Animation.Line_To (X_Beam (x0 + 178.0, y0 - 25.0), 
                                 Y_Beam (x0 + 178.0, y0 - 25.0));  -- d   ITop
      View.BB_Animation.Line_To (X_Beam (x0 + 178.0, y0 - 10.0), 
                                 Y_Beam (x0 + 178.0, y0 - 10.0));  -- e    Mid
      View.BB_Animation.Line_To (X_Beam (x0 - 178.0, y0 - 10.0), 
                                 Y_Beam (x0 - 178.0, y0 - 10.0));  -- f   -Mid
      View.BB_Animation.Line_To (X_Beam (x0 - 178.0, y0 - 25.0), 
                                 Y_Beam (x0 - 178.0, y0 - 25.0));  -- g  -ITop
      View.BB_Animation.Line_To (X_Beam (x0 - 180.0, y0 - 25.0), 
                                 Y_Beam (x0 - 180.0, y0 - 25.0));  -- h  -OTop
      View.BB_Animation.Close_Path;
      View.BB_Animation.Fill;
      
      --  Draw a target marker on the beam
      View.BB_Animation.Stroke_Color ("peachpuff");
      View.BB_Animation.Line_Width (3);
      View.BB_Animation.Begin_Path;
      View.BB_Animation.Move_To (X_Tgt (X_Tgt_0, Y_Tgt_0), 
                                 Y_Tgt (X_Tgt_0, Y_Tgt_0));
      
      View.BB_Animation.Line_To (X_Tgt (X_Tgt_0, y0), 
                                 Y_Tgt (X_Tgt_0, y0));
      View.BB_Animation.Stroke;
      
      --  Draw ball on the beam at position given by Ball_Pos
      View.BB_Animation.Fill_Color ("Olive");
      View.BB_Animation.Begin_Path;      
      View.BB_Animation.Arc_Degrees (X_Ball (X_Pos_0, Y_Pos_0),
                                     Y_Ball (X_Pos_0, Y_Pos_0),
                                     10, 0.0, 360.0);
      View.BB_Animation.Close_Path;
      View.BB_Animation.Fill;
      
      --  Reflection effect on ball
      View.BB_Animation.Fill_Color ("White");
      View.BB_Animation.Begin_Path;      
      View.BB_Animation.Arc_Degrees (X_Ball (X_Pos_0, Y_Pos_0) - 3,
                                     Y_Ball (X_Pos_0, Y_Pos_0) - 3,
                                     2, 0.0, 360.0);
      View.BB_Animation.Close_Path;
      View.BB_Animation.Fill;

      
      ------------------------------
      --  Redraw the graph panel  --
      ------------------------------
      --  The graph panel is only refreshed if plotting is not paused
      if not Paused then
         --  Put background image (axes, grid and "Target = " label)
         View.BB_Pos_Graph.Put_Image_Data (Plot_Background, 0, 0);
      
         --  Prepare the plot points in Pos_Plot and Target_Plot
         if N_Plot_Points < List_Length then
            --  No need to scroll
            N_Plot_Points :=  N_Plot_Points + 1;
         else
            --  Need to scroll
            Pos_Plot    (1..N_Plot_Points - 1) := Pos_Plot    (2..N_Plot_Points);
            Target_Plot (1..N_Plot_Points - 1) := Target_Plot (2..N_Plot_Points);
         end if;
         Pos_Plot    (N_Plot_Points) := Ball_Pos;
         Target_Plot (N_Plot_Points) := Current_Target_Pos;
      
         --  Plot Position graph
         --  Status area
         View.BB_Pos_Graph.Fill_Color ("Black");
         View.BB_Pos_Graph.Fill_Text 
           ((if Tgt_Str (Tgt_Str'First) = '-' then Tgt_Str 
            else Tgt_Str (Tgt_Str'First + 1 .. Tgt_Str'Last)) & " mm", 
            200 + Target_Text_X_Offset, Canvas_Y_Size - 5);
      
         X_Plot_Offset := 0;
         View.BB_Pos_Graph.Stroke_Color ("Blue");
         View.BB_Pos_Graph.Begin_Path;
         --  Move to coordinates of first point in list
         View.BB_Pos_Graph.Move_To 
           (30 + X_Plot_Offset, 
            20 + Integer ((Y_Max_Pos + Over) * Y_Plot_Scaling -
              (Pos_Plot (1) * Y_Plot_Scaling)));
         for I in 2..N_Plot_Points loop
            X_Plot_Offset := Integer (Delta_X * Float (I - 1));
            View.BB_Pos_Graph.Line_To 
              (30 + X_Plot_Offset, 
               20 + Integer ((Y_Max_Pos + Over) * Y_Plot_Scaling -
                 (Pos_Plot (I) * Y_Plot_Scaling)));
         end loop;
         View.BB_Pos_Graph.Stroke;
      
         --  Plot Target Position graph
         X_Plot_Offset := 0;
         View.BB_Pos_Graph.Stroke_Color ("Maroon");
         View.BB_Pos_Graph.Begin_Path;
         --  Move to coordinates of first point in list
         View.BB_Pos_Graph.Move_To 
           (30 + X_Plot_Offset, 
            20 + Integer ((Y_Max_Pos + Over) * Y_Plot_Scaling -
              (Target_Plot (1) * Y_Plot_Scaling)));
         for I in 2..N_Plot_Points loop
            X_Plot_Offset := Integer (Delta_X * Float (I - 1));
            View.BB_Pos_Graph.Line_To 
              (30 + X_Plot_Offset, 
               20 + Integer ((Y_Max_Pos + Over) * Y_Plot_Scaling -
                 (Target_Plot (I) * Y_Plot_Scaling)));
         end loop;
         View.BB_Pos_Graph.Stroke;
      end if;

   end Update_Animation;
   
   ----------------------------
   --  Draw_Plot_Background  --
   ----------------------------
   --
   --  Draws all background elements of the plot area and saves the image to
   --    Plot_Background for convenient use from Update_Animation
   --
   procedure Draw_Plot_Background is
      --  Length of mark. Applies to both axes
      Mark_Size  : constant := 5;
      --  Y axis related (Position axis)
      Y_Step     : constant Float   := 50.0; --  Y interval step, in mm
      Y_Interval : constant Float   := Y_Step * Y_Plot_Scaling;
      Y_Start_X  : constant Integer := 30;
      Y_Start_Y  : constant Integer := 20;
      Y_Offset   : Integer := 0;
      Y_Steps    : Float   := 0.0;
      
      --  Start at the top mark of axis Y
      Mark       : Float := Max_Position + Over;
      Val_Label  : Integer;  --  Value to print label from it
      
      --  X axis related (Time axis)
      X_Step     : constant Float   := 1.0;  --  X interval step, in s
      X_Interval : constant Float   := X_Step * X_Plot_Scaling;
      X_Start_X  : constant Integer := 30;
      X_Start_Y  : constant Integer := Y_Start_Y + Canvas_Y_Size - 50;
      X_Offset   : Integer := 0;
      X_Steps    : Float   := 0.0;
      
   begin
      --  Stroke graph rectangle
      View.BB_Pos_Graph.Stroke_Color ("Black");
      View.BB_Pos_Graph.Stroke_Rectangle (Cover_Plot);
      
      --  Draw Y axis
      --  Start at the top mark of axis Y
      loop
         --  Draw mark line
         View.BB_Pos_Graph.Stroke_Color ("Black");
         View.BB_Pos_Graph.Begin_Path;
         View.BB_Pos_Graph.Move_To (Y_Start_X,             Y_Start_Y + Y_Offset);
         View.BB_Pos_Graph.Line_To (Y_Start_X - Mark_Size, Y_Start_Y + Y_Offset);
         View.BB_Pos_Graph.Stroke;
         --  Draw grid line
         View.BB_Pos_Graph.Stroke_Color ("Silver");
         View.BB_Pos_Graph.Begin_Path;
         View.BB_Pos_Graph.Move_To (Y_Start_X,          Y_Start_Y + Y_Offset);
         View.BB_Pos_Graph.Line_To (Canvas_X_Size - 15, Y_Start_Y + Y_Offset);
         View.BB_Pos_Graph.Stroke;
         --  Put label
         Val_Label := Integer (Mark);
         View.BB_Pos_Graph.Fill_Color ("Black");
         View.BB_Pos_Graph.Fill_Text 
           (Val_Label'Image, 
            Y_Start_X - (if Val_Label >= 100 or Val_Label <= -100 then 28
              elsif Val_Label >= 10 or Val_Label <= -10 then 22
              else 16),
            Y_Start_Y + Y_Offset + 3);
         --  Prepare next iteration or exit loop
         Y_Steps := Y_Steps + 1.0;
         Y_Offset := Integer (Y_Steps * Y_Interval);
         Mark := Mark - Y_Step;
         exit when Mark < Position'First - Over;
      end loop;
      
      --  Draw X Axis
      --  Start at the leftmost mark of axis X
      loop
         --  Draw mark line
         View.BB_Pos_Graph.Stroke_Color ("Black");
         View.BB_Pos_Graph.Begin_Path;
         View.BB_Pos_Graph.Move_To (X_Start_X + X_Offset, X_Start_Y);
         View.BB_Pos_Graph.Line_To (X_Start_X + X_Offset, X_Start_Y + Mark_Size);
         View.BB_Pos_Graph.Stroke;
         --  Draw grid line
         View.BB_Pos_Graph.Stroke_Color ("Silver");
         View.BB_Pos_Graph.Begin_Path;
         View.BB_Pos_Graph.Move_To (X_Start_X + X_Offset, X_Start_Y);
         View.BB_Pos_Graph.Line_To (X_Start_X + X_Offset, 20);
         View.BB_Pos_Graph.Stroke;
         --  Prepare next iteration or exit loop         
         X_Steps := X_Steps + 1.0;
         X_Offset := Integer (X_Steps * X_Interval);
         exit when X_Steps > X_Max_Time;
      end loop;
      
      --  Write status text at bottom of graph
      View.BB_Pos_Graph.Fill_Color ("Black");
      View.BB_Pos_Graph.Fill_Text ("Target = ", 200, Canvas_Y_Size - 5);
      Target_Text_X_Offset := 40;
      --  Instead of 40, the assignment should be:
      --     := Integer (View.BB_Pos_Graph.Measure_Text_Width ("Target = "));
      --  but it causes the exception Gnoga.Server.Connection.Connection_Error 
      
      --  Write units next to both axes
      View.BB_Pos_Graph.Fill_Text ("(mm)", 3, Canvas_Y_Size - 10);
      View.BB_Pos_Graph.Fill_Text ("(1 sec/div)", 
                                   Canvas_X_Size - 60, 
                                   Canvas_Y_Size - 10); 
      
      --  Copy background to image Plot_Background. The plot background can then
      --    be redrawn with Put_Image_Data, more efficient than redrawing from
      --    scratch every time the plot is refreshed
      View.BB_Pos_Graph.Get_Image_Data 
        (Image_Data => Plot_Background,
         Left       => 0,
         Top        => 0,
         Width      => Canvas_X_Size,
         Height     => Canvas_Y_Size);
   end Draw_Plot_Background;
   
   ---------------------------------
   --  Draw_Animation_Background  --
   ---------------------------------
   --
   --  Draws all background elements of the animation area and saves the image 
   --    to Anim_Background for convenient use from Update_Animation
   --   
   procedure Draw_Animation_Background is
   begin
      --  Draw background rectangle
      View.BB_Animation.Fill_Color ("Linen");
      View.BB_Animation.Fill_Rectangle (Cover_Animated_BB);
      
      --  Draw beam pier
      View.BB_Animation.Fill_Color ("Silver");
      View.BB_Animation.Stroke_Color ("Grey");
      View.BB_Animation.Begin_Path;
      View.BB_Animation.Move_To (x0c, y0c); --  Top of beam pier (pivot point)
      View.BB_Animation.Line_To (x0c + 40, y0c + 40);
      View.BB_Animation.Line_To (x0c + 40, y0c + 115);
      View.BB_Animation.Line_To (x0c - 40, y0c + 115);
      View.BB_Animation.Line_To (x0c - 40, y0c + 40);
      View.BB_Animation.Close_Path;
      View.BB_Animation.Fill;
      View.BB_Animation.Stroke;
      
      --  Ploace text labels
      View.BB_Animation.Fill_Color ("Black");
      View.BB_Animation.Fill_Text 
        ("Angle = ", 150, Canvas_Y_Size - 5);
      View.BB_Animation.Fill_Text 
        ("Position = ", 270, Canvas_Y_Size - 5);

      --  Copy background to Anim_Background image
      View.BB_Animation.Get_Image_Data 
        (Image_Data => Anim_Background,
         Left       => 0,
         Top        => 0,
         Width      => Canvas_X_Size,
         Height     => Canvas_Y_Size);
   end Draw_Animation_Background;
   
   -----------------
   --  Create_GUI --
   -----------------
   
   procedure Create_GUI
     (Main_Window : in out Gnoga.Gui.Window.Window_Type'Class) is
   begin
      View.Dynamic;
      View.Create (Parent => Main_Window);
      View.Quit_Button.On_Click_Handler (On_Quit'Access);
      View.Pause_Button.On_Click_Handler (On_Pause'Access);
      --  Draw plot and animation background images and save them for future use
      Draw_Plot_Background;
      Draw_Animation_Background;
   end Create_GUI;
   
end BB.GUI.Controller;
