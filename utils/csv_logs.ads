--------------------------------------------------------------------------------
--                                                                            --
--                                C S V _ L O G S                             --
--                                                                            --
--                                     Spec                                   --
--                                                                            --
-- This package provides simple logging support for an arbitrary number of    --
--   Float data values. Data may be logged to the standard output, for visual --
--   inspection, or to a specified output file in CSV format, to facilitate   --
--   further analysis of the logged data on a spreadsheet.                    --
--                                                                            --
-- Logging is unprotected, use at most from one task.                         --   
--                                                                            --
-- Author: Jorge Real                                                         --
-- February, 2021                                                             --
--                                                                            --
--  This is free software in the ample sense: you can use it freely,          --
--    provided you preserve this comment at the header of source files and    --
--    you clearly indicate the changes made to the original file, if any.     --
--                                                                            --
--------------------------------------------------------------------------------

package CSV_Logs is
   
   --
   --  A Log session is an interval of time during which data of a particular
   --    experiment may be written to a given file or to the standard output.
   --    The logged data type is an unconstrained array of Floats. In addition, 
   --    arbitrary text lines can also be logged to the output CSV file, such
   --    as column headings.
   --  A log session must be opened with Open_Log_Session and it remains open 
   --    until closed with Close_Log_Session.
   --
   --  For example, the code:
   --  
   --     Open_Log_Session (File_Name => "data.csv");
   --     Log_Text ("Data_1, Data_2, Data_3");
   --     Log ((1 =>  0.0, 2 =>  0.0, 3 =>  0.0));
   --     Log ((1 => -1.0, 2 => -1.0, 3 => -1.0));
   --     Log ((1 =>  2.0, 2 =>  2.0, 3 =>  2.0));
   --     Close_Log_Session;
   --
   --  produces the file "data.csv" with the following contents:
   --
   --  Data_1, Data_2, Data_3
   --   0.00000,  0.00000,  0.00000
   --  -1.00000, -1.00000, -1.00000
   --   2.00000,  2.00000,  2.00000
   --
   --  
   
   procedure Open_Log_Session (File_Name : String := "");
   --  Start a log session. Set File_Name as the output file for the Log.
   --  If File_Name = "", the output file is Standard_Output.
   
   procedure Close_Log_Session;
   --  Close the log session. A new log session can be opened afterwards

   type Float_Array is array (Positive range <>) of Float;
   --  Data that can be logged
   
   procedure Log_Data (Data_Set : Float_Array);
   --  Log the values in Data_Set, separated with commas, to the output file 
   --    set for the current session. No action if there is no log session open.
   
   procedure Log_Text (Text_Line : String);
   --  Log the given Text_Line (verbatim) to the output file set for the curent 
   --    session, if one is open. No action if there is no log session open.

end CSV_Logs;           
