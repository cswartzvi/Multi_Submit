#! /bin/bash
#############################################################
# For Submitting multiple PBS scripts
#
# Charles W. Swartz VI
#
#
#############################################################


#IMPORTANT: Must be submitted in the main directory!
#This directory will contain the pseudo-potentials, 
#and all the template input and submit files

#Command Line arguments:
#1-Starting calculation number (NOT Production Number!!)
#2-Ending calculation number (NOT Production Number!!)
#3-(Optional) Job-ID that the first number is dependent upon
#  if no jobs are currently running, queued, or held this is
#  NOT needed

#********************************
# Machine dependent
#********************************
user='cswartz'
Suffix='@sdb'
inout_dir='In-Out_Files'
submit_dir='Submit_Files'
qsub_dir='Qsub_Files'
#********************************


#Hello
echo""
echo "************************************************************************************"
echo " Multi-Submit Script"
echo "************************************************************************************"
echo " "
echo " Required: 1) submit-XXX-TYPE.template* files for qsub submission"
echo "           2) XXX.template* files for input "
echo "           3) TYPE = gs for Ground-State Calculations, TYPE = md for MD Calculations"
echo "           4) XXX = name prefix (PBE, PBE0, ...). Name of input/output files from XXX."
echo " "
echo " Note: All input/output files will be move to directory $inout_dir. Likewise, all "
echo " submit files will also be moved directory $submit_dir"
echo " "
echo " "

#Check to be sure there are at least 2 Arguments
if [ $# -lt '2' ] || [ $1 == '-h' ]; then
   echo "Command Arguments:"
   echo "   1)Starting index number"
   echo "   2)Ending index number"
   echo "   3)First job dependency (Optional)"
   exit 1
fi

#process command line options
count=0
depend='false'
while [ -n "$1" ]
do
   count=$((count + 1))
   case $count in
      1)
         start_loop=$1;;
      2)
         stop_loop=$1;;
      3) 
         depend='true'
         first_depend=$1;;
      *)
         echo "ERROR: Too many command-line arguments"
         exit;;
   esac
   shift
done
   
proceed='n'
while [ ! $proceed = 'Y' ] && [ ! $proceed = 'y' ]; do

   echo "---------------------------------------"
   echo " *template* Files in the current directory: `pwd`"
   ls *template*
   echo "---------------------------------------"

   echo ""
   echo ""
   #Read in Values for the templates and the input names
   echo " Please enter the following filenames..."
   read -e -p "  Submit Template: "  submit_temp
   submit_root="${submit_temp%%.template*}"
   read -e -p "  Input Template: "  input_temp
   inout_root="${input_temp%%.template*}"
   echo ""

   #Read in the Filenames
   echo "---------------------------------------"
   echo ""
   echo " Submit Template     : $submit_temp"
   echo " Submit Root         : $submit_root"
   echo " Input Template      : $input_temp"
   echo " Input/Output Root   : $inout_root"
   echo " Starting Number     : $start_loop"
   echo " Ending Number       : $stop_loop"
   if [ $depend = true ]; then
      echo " First job dependency: $first_depend"
   fi

   #Consistency checks : Ground state
   if (echo $submit_temp | grep -e '-gs.' > /dev/null 2>&1) && (echo $input_temp | grep -e '-gs.' > /dev/null 2>&1) ; then
      #
      echo " "
      echo " Calculation Type:      GS"
      #
      #Check to see if the in-out dir exists
      if [ -d $inout_dir ]; then
         #
         if (ls  $inout_dir | grep -e '-md.'  > /dev/null 2>&1) ; then
            echo " WARNING: Previous MD Calculations Exist (this will overwrite)!!"
         elif (ls $inout_dir | grep -e '-gs.'  > /dev/null 2>&1); then
            echo " Previous Calculation:  GS"
         else
            echo " No Previous 'gs' files found in $inout_dir. Should be first gs Calculation."
         fi
      else
         echo " No Previous 'gs' files ($inout_dir does not exist). Should be first use of multi_submit."
      fi

   #Consistency checks : MD
   elif (echo $submit_temp | grep -e '-md.' > /dev/null 2>&1) && (echo $input_temp | grep -e '-md.' > /dev/null 2>&1) ; then
      #
      echo " "
      echo " Calculation Type:      MD"
      #
      #Check to see if the in-out dir exists
      if [ -d $inout_dir ]; then
         #
         if (ls $inout_dir | grep -e '-md.' > /dev/null 2>&1) ; then
            echo " Previous Calculation:  MD"
            elif (ls $inout_dir | grep -e '-gs.'  > /dev/null 2>&1); then
            echo " Previous Calculation:  GS (Should be first MD Calculation)"
         else
            echo " WARNING: No Standard '-gs.' or '-md.' Files Found in $inout_dir!!"
         fi
      else
         echo " WARNING: No Previous '-gs.' OR '-md.' Calculations exist ($inout_dir does not exist!!"
      fi
   else
      #if the input and submit templates do not match
      echo " "
      echo " WARNING: $submit_temp and $input_temp do not match!"
   fi
   echo " "

   if [ $depend = true ]; then
      qsub_line=`qstat -u $user | grep $first_depend`
      echo " Job dependency Info: $qsub_line"
   fi

   #Check if Values are correct
   echo ""
   read -p " Are these values correct[y/Y]?:" proceed
   echo ""
   if [ ! $proceed = 'Y' ] && [ ! $proceed = 'y' ]; then
      echo " User Values Incorrect, Please reenter!"
      echo ""
   else
      echo " "
   fi
done

#Check to make sure these Files exist
if [ ! -s $submit_temp ]; then
   echo "ERROR: Submit Template not found in current directory."
   echo " Run this scrip in the main directory!"
   echo ""
   exit 1
fi
if [ ! -s $input_temp ]; then
   echo "ERROR: Input Template not found in current directory."
   echo " Run this scrip in the main directory!"
   echo ""
   exit 1
fi


#should the submit scripts be submited to qsub?
read -e -p " Submit jobs with qsub, (Otherwise just create files)? [Y/y] :" qsub

echo " "
echo " Starting Multi-Submit ..." 
echo " "

if [ $qsub = 'Y' ] || [ $qsub = 'y' ]; then
   echo " Submit Scripts will be submitted with qsub."
else
   echo " Submit Scripts will NOT be submitted with qsub"
fi
echo " "


#Correct Directories
if [ ! -d ./$inout_dir ]; then
   echo "  Creating $inout_dir" 
   echo "   All Input and Output Files will be stored here"
   mkdir ./$inout_dir
fi

if [ ! -d ./$submit_dir ]; then
   echo "  Creating $submit_dir"
   echo "   All Submit Scripts will be stored here"
   mkdir ./$submit_dir
fi
if [ ! -d ./$qsub_dir ]; then
   echo "  Creating $qsub_dir"
   echo "   All qsub stdout and stderr files will be stored here"
   mkdir ./$qsub_dir
fi
echo " "

#Roots for submit and Input/Output
submit_root=$submit_dir'/'$submit_root'.sh'
input_root=$inout_dir'/'$inout_root'.in'
output_root=$inout_dir'/'$inout_root'.out'



first=0
for((i = $start_loop; i <= $stop_loop; i++))
do


   #Current input/output and submit files, created below
   submit=$submit_root$i
   input=$input_root$i
   output=$output_root$i

   # '--> Check that the corresponding *first* submit file does not exist
   #       create the new submit file afterwards
   if [ $first -eq '0' ] && [ -s $submit ]; then
      read -e -p "  Warning: The first submit file $submit already exists! Continue? [Y/y] :" proceed
      if [ ! $proceed = 'Y' ] && [ ! $proceed = 'y' ]; then
         echo " "
         echo "  Please Adjust the starting number!"
         exit 2
      else
         echo " "
         echo "  Continuing with the script ..."
         echo " " 
      fi
   fi
   cp $submit_temp $submit

   #Check to make sure this run has not happen already
   # '--> Check that the corresponding *first* input file does not exist
   #       create the new input file afterwards
   if [ $first -eq '0' ] && [ -s $input ]; then
      read -e -p "  Warning: The first input file $input already exists! Continue? [Y/y] :" proceed
      if [ ! $proceed = 'Y' ] && [ ! $proceed = 'y' ]; then
         echo " "
         echo "  Please Adjust the starting number!"
         exit 2
      else
         echo " "
         echo "  Continuing with the script ..."
         echo " " 
      fi
   fi
   cp $input_temp $input

   # '--> Check that the corresponding output file does not exist
   if [ -s $output ]; then
      echo "ERROR: The output file $output already exists! Please adjust Starting Number"
      exit 2
   fi


   #In the submit file change ALL xxNUMxx xxINPUTxx and xxOUTPUTxx
   sed -i -e "s/xxNUMxx/$i/" $submit
   sed -i -e "s#xxINPUTxx#${input}#" $submit
   sed -i -e "s#xxOUTPUTxx#${output}#" $submit

   if [ $qsub = 'y' ] || [ $qsub = 'Y' ]; then
      echo "  --------------------------------------------------"
      echo "  Submitting Job $i"
      echo "  --------------------------------------------------"
      echo "  Batch Script:  $submit"
      echo "  Input File  :  $input"
      echo "  Output File :  $output"
      echo " "


      if [ $first -eq '0' ] ; then
         if [ $depend = true ] ; then

            echo "   Submitting Job: qsub -o $qsub_dir -e $qsub_dir -W depend=afterok:$first_depend$Suffix $submit"
            jobid=`qsub -o $qsub_dir -e $qsub_dir -W depend=afterok:$first_depend$Suffix $submit`
            #jobid="${jobid%%.*}"
            echo "   jobID: $jobid"
            echo " "

         else
            echo "   Submitting Job: qsub -o $qsub_dir -e $qsub_dir $submit"
            jobid=`qsub -o $qsub_dir -e $qsub_dir $submit`
            #jobid="${jobid%%.*}"
            echo "   jobID: $jobid"
            echo " "
         fi

         first=1

      else

         echo "   Submitting Job: qsub -o $qsub_dir -e $qsub_dir -W depend=afterok:$jobid$Suffix $submit"
         jobid=`qsub -o $qsub_dir -e $qsub_dir -W depend=afterok:$jobid$Suffix $submit`
         #jobid="${jobid%%.*}"
         echo "   jobID: $jobid"
         echo " "

      fi
   fi

done

