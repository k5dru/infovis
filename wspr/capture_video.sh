outfile=~/Downloads/screencast_$(date "+%Y%m%d%H%M%S").mkv

ffmpeg -f pulse -ac 2 -i default -f x11grab -r 30 -s 1440x900 -i :0.0 -acodec pcm_s16le -vcodec libx264 -preset ultrafast -threads 0 -y $outfile
