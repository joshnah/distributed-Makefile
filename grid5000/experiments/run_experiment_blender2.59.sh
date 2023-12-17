# Run the matrix multiplication experiment on Grid5000 proving that spark is deployed correctly
# Final result is stored in execution_time_result.txt
result_file="blender_result.txt"
execution_file="executionTime.txt"
folder=$(pwd)/$(dirname "${BASH_SOURCE[0]}")   
echo "folder: $folder"
BLENDER_FOLDER=$folder/../../makefiles/blender_2.59
NB_ATTEMPTS=3

# if NB_ATTEMPTS is provided
if [ ! -z "$1" ]; then
  NB_ATTEMPTS=$1
fi


# install dependencies
taktuk -l root -f ~/oar_node_file broadcast exec [ "apt-get install -y blender imagemagick ffmpeg" ]


rm -f $BLENDER_FOLDER/*.png $BLENDER_FOLDER/*.jpg $BLENDER_FOLDER/*.tga $BLENDER_FOLDER/*.avi > /dev/null

echo "nb_frames" > $result_file
# loop through value of nb_executors 2 4 8 16 32  
for nb_frames in {10..60..10}; do
  echo "Running for nb_frames: $nb_frames"
  total_execution_time=0
  total_scheduling_time=0

  $BLENDER_FOLDER/generate_blender_make.pl $BLENDER_FOLDER/cube_anim.blend $BLENDER_FOLDER/cubesphere.blend $BLENDER_FOLDER/dolphin.blend $nb_frames $nb_frames $nb_frames  > $BLENDER_FOLDER/Makefile
  for i in $(seq "$NB_ATTEMPTS"); do 
    echo "Attempt $i"

    $folder/../submit-job.sh $BLENDER_FOLDER/Makefile 2> /dev/null

    if [ $? -ne 0 ]; then
      echo "Error while submitting job"
      exit 1
    fi
    
    # make clean
    echo "Cleaning up"
    rm -f $BLENDER_FOLDER/*.png $BLENDER_FOLDER/*.jpg $BLENDER_FOLDER/*.tga $BLENDER_FOLDER/*.avi > /dev/null

    # First line is scheduling time, second line is execution time
    SCHEDULING_TIME=$(head -n 1 $execution_file)
    EXECUTION_TIME=$(tail -n 1 $execution_file)

    total_execution_time=$(($total_execution_time + $EXECUTION_TIME))
    total_scheduling_time=$(($total_scheduling_time + $SCHEDULING_TIME))

    echo finished attempt $i
  done


  average_execution_time=$(echo "scale=2; $total_execution_time / $NB_ATTEMPTS" | bc)
  average_scheduling_time=$(echo "scale=2; $total_scheduling_time / $NB_ATTEMPTS" | bc)

  echo "number of frames: $nb_frames,average scheduling time: $average_scheduling_time, average execution time: $average_execution_time"
  echo "$nb_frames;$average_scheduling_time; $average_execution_time; " >> $result_file

done

echo "Execution results are stored in $result_file"
