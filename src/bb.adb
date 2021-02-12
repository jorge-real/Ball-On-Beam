--------------------------------------------------------------------------------
--                                                                            --
--                                    B B                                     --
--                           Ball on Beam Simulator                           --
--                                                                            --
--                                    Body                                    --
--                                                                            --
--  This is the root package of a library implementing a ball on beam system  --
--    simulator. It gives general definitions concerning this system, namely  --
--    the types for representing the system variables (ball position and      --
--    beam angle); and it implements general operations on the system, such   --
--    as moving the system to a given solar system object or setting the      --
--    simulator operating mode.                                               --
--                                                                            --
--  The interfaces to obtain the ball position and set the beam angle from a  --
--    client program are implemented by child packages of BB, which need to   --
--    with'ed, together with package BB. These packages present different     --
--    abstractions for the purpose, such as an ADC device to obtain the ball  --
--    position. The same goes for the gnoga-based graphical user interface,   --
--    which is implemented in child package BB.GUI and childs of it.          --
--                                                                            --
--  Author: Jorge Real                                                        --
--  Universitat Politecnica de Valencia                                       --
--  July, 2020 - Version 1                                                    --
--  February, 2021 - Version 2                                                --
--                                                                            --
--------------------------------------------------------------------------------

with System;
with Ada.Real_Time;                     use Ada.Real_Time;
with Ada.Real_Time.Timing_Events;       use Ada.Real_Time.Timing_Events;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body BB is

   --  Location related entities
   Current_Location : Solar_System_Object := Earth
     with Atomic;

   type Gravities is array (Solar_System_Object) of Float;

   Gravity_Of : constant Gravities :=
     (Mercury =>  3.7,    Venus   =>  8.87,  Earth   =>  9.80665,
      Mars    =>  3.711,  Jupiter => 24.79,  Saturn  => 10.4,
      Uranus  =>  8.69,   Neptune => 11.15,  Pluto   =>  0.62,
      Moon    =>  1.6249, Ceres   =>  0.27,  Eris    =>  0.82,
      Vesta   =>  0.22);

   g  : Float := Gravity_Of (Current_Location)
     with Atomic;

   procedure Move_BB_To (Where : in Solar_System_Object) is
   begin
      Current_Location := Where;
      g := Gravity_Of (Current_Location);
   end Move_BB_To;

   function Current_Planet return Solar_System_Object is (Current_Location);
   --  The BB.GUI obtains the current SSO name using this function

   pi : constant := Ada.Numerics.Pi;

   --  The default simulation mode is passive
   Auto_Mode_On : Boolean := False;

   --  Duration of a simulation step in auto mode
   Auto_Period : Duration := 0.1;
   pragma Atomic (Auto_Period);



   -------------------
   --  Sim  (spec)  --
   -------------------

   --  Protected object to simulate the ball & beam system.
   --    The simulator can be used from concurrent tasks, but task dispatching
   --    policy and locking policy are not enforced from this simulator.
   --  There are only two significant events: calling Set_Angle and calling
   --    Get_Pos. Either call recalculates the current position based on the
   --    position, speed and acceleration of the ball at the previous event,
   --    and the time elapsed since then. In addition, Set_Angle sets the Angle
   --    to the given value, which determines the ball acceleration until the
   --    next call to Set_Angle.

   protected Sim
     with Priority => System.Priority'Last
   is
      procedure Set_Angle (To : Angle);
      procedure Get_Pos (Where : out Position);
      --  These two procedures imply a state update in the simulator, i.e. the
      --    calculation of a simulation step.

      function Last_Pos return Position;
      function Last_Angle return Angle;
      --  These two functions simply return the most recently simulated position
      --    and angle, without forcing the recalculation of a simulation step.
      --  They are intended for GUI updates, for which a relatively recent value
      --    is good enough. They do not update the simulation state, so they are
      --    faster and less interferring. GUI updates are performed from a task
      --    in child package BB.GUI.Controller.

      procedure Set_Refresh_Mode (Mode : Simulation_Mode);
      --  Set the auto-refresh mode, passive for Closed_Loop or 100 ms periodic
      --    for Open_Loop mode. Auto-refresh is operated by a recurring TE

   private

      procedure Update_State (Last_Interval : in Time_Span);

      Pos : Position := 0.0;  --  Simulated ball position, in mm
      Vel : Float   := 0.0;   --  Ball velocity, in mm/s
      Acc : Float   := 0.0;   --  Ball acceleration, in mm/s^2
      Ang : Angle   := 0.0;   --  Beam angle, in degrees

      Last_Event : Time := Clock; --  Start time of simulation interval

      Refresh_TE      : Timing_Event;
      Time_To_Refresh : Time;
      procedure Auto_Refresh (TE : in out Timing_Event);
      --  TE and support for Auto-refresh (Open_Loop) mode

   end Sim;

   ------------------
   --  Sim (body)  --
   ------------------

   Refresh_Period : constant Time_Span := Milliseconds (100);
   --  Auto-refresh period in Open_Loop mode

   protected body Sim is

      procedure Update_State (Last_Interval : in Time_Span) is

         --  Duration of last simulation interval, in seconds, as a Float
         T : constant Float := Float (To_Duration (Last_Interval));

         --  An estimated position could fall out of range, so we use this
         --    Float for the calculated position, and then trim it to fall
         --    within the bounds of type Position, imposed by the beam size.
         Unbounded_Pos : Float;

      begin

         --  Update simulator state. Called whenever there is a simulator event.
         --  The current ball position depends on the beam angle during the last
         --    interval (which determines the acceleration), and the ball
         --    velocity and position at the start of the simulation interval.
         --    Since changing the beam angle causes a simulator event, the beam
         --    angle remains constant during a simulator step.

         --  Ball acceleration as a function of beam angle.
         --  Since angle grows CCW and position decreases leftwards, a positive
         --  angle causes a negative acceleration -- hence "-Ang" here.
         Acc := (5.0 * g * Sin ((Float (-Ang) * pi) / 180.0)) / 7.0; -- m/s**2

         --  Ball velocity acquired during last interval.
         Vel := Vel + Acc * T; -- m/s

         --  Calculated a ball position that is not constrained to the range
         --  of type Position. If it was constrained, there would be a
         --  Constraint_Error if T was large enough to let the ball continue
         --  falling beyond either end of the beam.
         --  The constant 1_000.0 scales meters to mm, since ball position is
         --  given in mm.
         Unbounded_Pos := Pos + (1_000.0 * Vel * T) +
           ((1_000.0 * Acc * T**2) / 2.0);

         --  Adjust to position limits. Assume ball stoppers at both beam ends.
         --  Assume also no bouncing when the ball hits a stopper.
         if Unbounded_Pos > Position'Last then     -- Ball hits right end
            Unbounded_Pos := Position'Last;
            Vel := 0.0;    --  Rectify velocity: the ball hit the right stopper
         elsif Unbounded_Pos < Position'First then  -- Ball hits left end
            Unbounded_Pos := Position'First;
            Vel := 0.0;    --  Rectify velocity: the ball hit the left stopper
         end if;

         Pos := Position (Unbounded_Pos);  --  Safe conversion after adjustment

      end Update_State;

      procedure Set_Angle (To : Angle) is
         Now : constant Time := Clock;
      begin
         Update_State (Now - Last_Event);
         Last_Event := Now;
         --  Set the beam inclination to the given angle
         Ang := To;
      end Set_Angle;

      procedure Get_Pos (Where : out Position) is
         Now : constant Time := Clock;
      begin
         Update_State (Now - Last_Event);
         Last_Event := Now;
         --  Return updated position
         Where := Pos;
      end Get_Pos;

      function Last_Pos return Position is (Pos);

      function Last_Angle return Angle is (Ang);

      procedure Set_Refresh_Mode (Mode : Simulation_Mode) is
         Cancelled : Boolean;
      begin
         case Mode is
            when Open_Loop =>
               Time_To_Refresh := Clock;
               Set_Handler (Event   => Refresh_TE,
                            At_Time => Time_To_Refresh,
                            Handler => Auto_Refresh'Access);
            when Closed_Loop =>
               Cancel_Handler (Refresh_TE, Cancelled);
         end case;
      end Set_Refresh_Mode;

      procedure Auto_Refresh (TE : in out Timing_Event) is
      begin

         --  Update simulator state to make it simulate one more step so that
         --  the GUI can show progress in open-loop uses
         Update_State (Time_To_Refresh - Last_Event);
         Last_Event := Time_To_Refresh;

         Time_To_Refresh := Time_To_Refresh + Refresh_Period;
         Set_Handler (Event   => Refresh_TE,
                      At_Time => Time_To_Refresh,
                      Handler => Auto_Refresh'Access);

      end Auto_Refresh;

   end Sim;

   --------------------
   -- Set_Beam_Angle --
   --------------------

   procedure Set_Beam_Angle (Inclination : Angle) is
   begin
      Sim.Set_Angle (Inclination);
   end Set_Beam_Angle;

   -------------------
   -- Ball_Position --
   -------------------

   function Ball_Position return Position is
      Result : Position;
   begin
      Sim.Get_Pos (Result);
      return Result;
   end Ball_Position;

   -------------------------
   -- Set_Simulation_Mode --
   -------------------------

   procedure Set_Simulation_Mode (Mode : Simulation_Mode) is
   begin
      Sim.Set_Refresh_Mode (Mode);
   end Set_Simulation_Mode;

   --  Private subprograms

   --------------
   -- Last_Pos --
   --------------

   function Last_Pos return Position is (Sim.Last_Pos);

   ----------------
   -- Last_Angle --
   ----------------

   function Last_Angle return Angle is (Sim.Last_Angle);

end BB;
