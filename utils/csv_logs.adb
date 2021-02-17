--------------------------------------------------------------------------------
--                                                                            --
--                                C S V _ L O G S                             --
--                                                                            --
--                                     Body                                   --
--                                                                            --
-- Author: Jorge Real                                                         --
-- February, 2021                                                             --
--                                                                            --
--------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Float_Text_IO;

with Ada.Strings.Unbounded;
with Ada.Directories;

package body CSV_Logs is
   
   A_Session_Is_Open : Boolean := False;
   
   Writing_To_File   : Boolean := False;
   
   Output_File_Name  : Ada.Strings.Unbounded.Unbounded_String;
   
   --  The log file, if it is used
   Log_File    : aliased Ada.Text_IO.File_Type;

   --  The output file access. May access Log_File or Standard_Output
   Output_File : Ada.Text_IO.File_Access;
   
   ------------------------
   --  Open_Log_Session  --
   ------------------------
   
   procedure Open_Log_Session (File_Name : String := "") is 
      use Ada.Strings.Unbounded;
   begin 

      if A_Session_Is_Open then
         return;
      end if;
      
      A_Session_Is_Open := True;

      if File_Name /= "" then
         
         --  A file name was given. Create the file and take note we are writing
         --    to a file, so that we close the file when the session is closed.
         Writing_To_File := True;
         
         Ada.Text_IO.Create (File => Log_File, 
                             Mode => Ada.Text_IO.Out_File,
                             Name => File_Name);
         
         --  The output file is set to access the just created Log_File
         Output_File := Log_File'Access;
         
         --  File name saved for the closing session message
         Output_File_Name := To_Unbounded_String (File_Name);
         
      else 
         
         Writing_To_File := False;
         
         --  The output file is set to access the standard output
         Output_File := Ada.Text_IO.Standard_Output;
         
      end if;

   end Open_Log_Session;

   -------------------------
   --  Close_Log_Session  --
   -------------------------
   
   procedure Close_Log_Session is
      use Ada.Strings.Unbounded;
      use Ada.Directories;
   begin
      
      if A_Session_Is_Open then
         
         A_Session_Is_Open := False;
         
         if Writing_To_File then
            
            Ada.Text_IO.Close (Log_File);
            
            --  File info message for every closed log session
            Ada.Text_IO.Put_Line ("Logged data was saved to """ 
                                  & Current_Directory & "/"
                                  & To_String (Output_File_Name) & """");
         end if;
         
      end if;
      
   end Close_Log_Session;
   
   -----------
   --  Log  --
   -----------
   
   procedure Log_Data (Data_Set : Float_Array) is      
   begin
      
      if not A_Session_Is_Open then
         return;
      end if;
      
      for I in Data_Set'Range loop
         
         Ada.Float_Text_IO.Put 
           (File => Output_File.all,
            Item => Data_Set (I),
            Exp => 0);
         
         --  Put separating comma after each value or new line after last value
         if I /= Data_Set'Last then
            Ada.Text_IO.Put (Output_File.all, ", ");
         else 
            Ada.Text_IO.New_Line (Output_File.all);
         end if;
         
      end loop;
      
   end Log_Data;
      
   ----------------
   --  Log_Text  --
   ----------------
   
   procedure Log_Text (Text_Line : String) is
   begin
      
      if not A_Session_Is_Open then
         return;
      end if;
      
      Ada.Text_IO.Put_Line (Output_File.all, Text_Line);
      
   end Log_Text;
      
end CSV_Logs;
                                                           
