--------------------------------------------------------------------------------
--                                                                            --
--                                    B B                                     --
--                           Ball on Beam Simulator                           --
--                                                                            --
--                                    Spec                                    --
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
--    which is implemented in child package BB.GUI and its child units.       --
--                                                                            --
--  Author: Jorge Real                                                        --
--  Universitat Politecnica de Valencia                                       --
--  July, 2020 - Version 1                                                    --
--  February, 2021 - Version 2                                                --
--                                                                            --
--------------------------------------------------------------------------------

package BB is

   Max_Angle : constant := 15.0;  -- deg
   Min_Angle : constant := - Max_Angle;
   --  Maximum and minimum inclination angle of beam, in degrees.

   subtype Angle is Float range Min_Angle .. Max_Angle;
   --  At zero degrees, the beam is horizontal. Angle grows CCW.
   --  The angle range is symmetrical around 0.0 deg.

   Max_Position : constant Float := 240.0;  -- mm
   Min_Position : constant Float := - Max_Position;
   --  Maximum and minimum position of ball on beam, in mm.

   subtype Position is Float range Min_Position .. Max_Position;
   --  At the beam center, Position = 0.0. Position grows rightwards.
   --  The position range is symmetrical around 0.0 mm.

   type Solar_System_Object is (Mercury, Venus, Earth, Moon, Mars,
                                Jupiter, Saturn, Uranus, Neptune,
                                Pluto, Ceres, Eris, Vesta) with Atomic;
   --  Solar system objects where the ball & beam system may be simulated.
   --  The default location is Earth. On a slow computer, you can try lower
   --    gravity objects to slow down the system dynamics and let you use
   --    larger control loop periods, in control applications.

   procedure Move_BB_To (Where : in Solar_System_Object);
   --  Simulates the system Where specified, applying the gravity of the
   --    given solar system object

   type Simulation_Mode is (Open_Loop, Closed_Loop);
   --  Modes of operation of the simulator. The default mode is Closed_Loop.

   procedure Set_Simulation_Mode (Mode : Simulation_Mode);
   --  The mode affects the way in which the simulator makes simulation steps.
   --  In Open_Loop mode, the simulator actively advances a simulation step once
   --    every 100 ms. This mode is needed only in applications that do not call
   --    Ball_Position or Set_Beam_Angle with sufficient frequency.
   --  In Closed_Loop mode, the simulator is passive. Simulation steps are made
   --    only when a client calls Ball_Position or Set_Beam_Angle. This occurs
   --    naturally in closed-loop applications.

private

   --
   --  Subprograms implementing the ideal BB model upon which all BB interfaces
   --    depend. The ideal model is purely analytical and does not require I/O
   --    synchronisation: input via Ball_Position is always ready and output
   --    via Set_Beam_Angle has immediate effect.
   --
   procedure Set_Beam_Angle (Inclination : Angle);
   --  Set the beam inclination angle, in degrees.

   function Ball_Position return Position;
   --  Returns the simulated ball position, in mm.

   --
   --  Functions made available for GUI updates. They return the most recent
   --    values of ball position, beam angle and selected solar sytem object.
   --    These functions are used from child package BB.GUI.Controller so that
   --    GUI updates do not make simulation steps. A sufficiently fresh value
   --    is enough for the purpose.
   --
   function Last_Pos return Position;

   function Last_Angle return Angle;

   function Current_Planet return Solar_System_Object;

end BB;
