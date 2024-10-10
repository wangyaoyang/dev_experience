#!/bin/bash

if [ $1 ]; then
	INPUT_FILE=$1
	OUTPUT_FILE=HSBS_$INPUT_FILE
	
	time ffmpeg -i "$INPUT_FILE" -vf "scale=1920:1080" -c:v libx264 -crf 18 -preset veryfast "$OUTPUT_FILE"
else
	echo "Usage:"
	echo "$0 input_video_file"
fi

