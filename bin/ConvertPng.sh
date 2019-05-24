 #!/bin/bash
#set -v
#set -x

filename=$(basename "$1")
extension="${filename##*.}"
filename="${filename%.*}"



#calcul du framerate
echo "Traitement de $filename" $extension
fileinfo = `ffmpeg -i "$1" -vcodec copy -acodec copy -f null /dev/null 2>&1`

frames= `$fileinfo  | grep 'frame=' | cut -f 2 -d ' '`

if [[ $frames  == "" ]]; then

	frames=`$fileinfo  | grep 'frame=' | cut -f 3 -d ' '`
	fi
if [[ $frames == "" ]] ; then frames=25; fi

echo "Nombre de frames: " $frames
#duration=`ffmpeg -i "$1"  2>&1 | grep Duration | awk '{print $2}' | tr -d ,`
duration=`$fileinfo | grep Duration`
echo $duration
echo "duree: " $duration
secondes=`echo $duration |cut -d ':' -f 3|tr -d '.'`
minutes=`echo $duration |cut -d ':' -f 2`
heures=`echo $duration |cut -d ':' -f 1`
centiemes=`expr $heures \* 360000 + $minutes \* 6000 + $secondes`
framerate=`expr 100 \* $frames / $centiemes`
echo "framerate: " $framerate

if [[ $2 == "" ]]; then
	read -p " Dossier : (defaut)"
	dossier=${dossier:-defaut}
	d=$dossier
	else
	d="$2"
fi
if [[ ! -d $d ]]; then
	mkdir $dossier
fi


i=`ls "$d" | grep movie | cut -d'e' -f 2 | cut -d' ' -f 2 `
i=`echo $i | sed 's/.*\(..\)$/\1/'`
i=`expr $i + 1`
read -p " Offset : (0)"
offset=${offset:-0} 
read -p " Durée : ($duration)"
duree=${duree:-$duration}  

 
cd $d

mkdir movie0$i && ffmpeg -y -i "$1" -s 320x180 -ss $offset -t $duree -an -r 24 -vcodec png movie0$i/%d.png && cp movie0$i/1.png movie0$i/0.png

