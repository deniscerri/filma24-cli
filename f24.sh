#!/bin/bash

user_agent="Chrome/79"
download_path="/home/$USER"
base_url="https://www.filma24.bz"
newline=$'\n'
file_size=0
url_retries=0


parsevidmoly(){
        fixedURL=$(echo "$referer" | sed 's/embed-//g')
        videoID=$(echo "$fixedURL" | sed 's/https:\/\/vidmoly.to\///g' | sed 's/https:\/\/vidmoly.net\///g' | sed 's/.html//g')

        videoHash=$(curl -s -i -H "Accept: text/html" -H "Content-Type: text/html" -X GET "https://vidmoly.net/dl?op=download_orig&id=$videoID&mode=&hash=" |
 grep -o -E 'name="hash" value=".*"' | grep -o -P 'value="\K[^"]*')

        page_with_mp4=$(curl -s -i -H "Accept: text/html" -H "Content-Type: text/html" -X GET "https://vidmoly.net/dl?op=download_orig&id=$videoID&mode=n&hash=$videoHash")
        mp4=$(echo "$page_with_mp4" | grep -o -E '*https://.*([^"])*.mp4' | head -1)
	
        if [ -z "$mp4" ]
        then
			if [[ $url_retries -gt 10 ]]
			then
				url_retries=0
				return 1
			else
				timeout=$(echo $page_with_mp4 | grep -o -E '*<b class="err">You have to wait[^"<b]*' | tr -dc '0-9')	
				if [ ! -z "$timeout" ]
						then
								echo "Timeout found. Waiting $timeout seconds"
								sleep $timeout
						fi
				((url_retries=url_retries+1))
				parsevidmoly
			fi
		else
        	download $referer $mp4
		fi
}

download () {
	if [ -z "$2" ]
	then
		echo "Couldn't find a suitable stream for the selected movie! :("
		return 1
	fi
	
	echo "Downloading from $1 with video url $2"
	
	if [[ $2 == *"m3u"* ]]
	then 
		ffmpeg -http_persistent 0 -nostdin -hide_banner -v warning -stats -headers "Referer: $1" -i "$2" -c copy -metadata:s:a:0 language=alb "$download_path/$result_title.mkv" || true
	else
		wget -q --show-progress --header="Referer: $(echo $1 | tr -d "\n")" "$2" -O "$download_path/$result_title.mkv" || true
	fi
	if [[ -f "$download_path/$result_title.mkv" ]]
	then
		filesize=$(wc -c "$download_path/$result_title.mkv" | awk '{print $1}' | tr -dc '0-9')
		if [ "$filesize" -lt 50000000 ]
		then
			echo "The Downloading video file was broken."
			return
		else
			exit
		fi
		exit
	else
		return
	fi

}

check_http () {
if [ -z "$1" ]
then
	return
fi
	http=$(echo "$1" | grep -E "^http" | wc -l)
	if [ "$http" -eq 0 ]
	then
		referer="https:$(echo $1 | xargs echo -n)"
	else
		referer=$1
	fi
}

pick_mp4 () {
	size_tmp=$(curl --referer $1 -s -I $2 2> /dev/null | grep -i "content-length:" | tr -d "Content\-Length:\t" | tr -dc '0-9')
	if (( size_tmp > file_size ));
	then	
		file_size=$size_tmp
		chosen_mp4=$2
		chosen_referer=$1			
	fi
}

get_video_link () {
	mp4="$(curl --user-agent "$user_agent" -s "$1" | grep -o -E '.*//.*([^"]*v.mp4")' | grep -o '[^{,"]\+"' | sed 's/"//g' | grep -o -E 'http.*' | head -1)"	
	#Checking if the referer contains a m3u file instead of a mp4 file
	
	if [ -z "$mp4" ]
	then
		mp4=$(curl --connect-timeout 10 --user-agent "$user_agent" -s "$1" | grep -o -E '*https://.*([^"]*.m3u8")' | sed 's/"//g' | head -n 1)
	fi
	
}

parse_embed_referer () {
	nr_of_servers=$(curl --user-agent "$user_agent" -s $1 | grep -o -E '.*<a data-servera=".*' | wc -l | tr -dc '0-9')
	for ((i = 1 ; i <= $nr_of_servers ; i++));
	do
		server="$1?server=$i"
		referer="$(curl --user-agent "$user_agent" -s $server | grep -o -E '*<p><iframe.*' | tr -d '"' | grep -o -P 'src=\K[^ ]*' | xargs echo -n)"
		
		check_http "$referer"
		
		if [ -z "$referer" ]
		then
			continue
		fi
		

		#If user input was an url, result_title was never initiated
		if [ -z "$result_title" ]
		then
			result_title=$(curl --user-agent "$user_agent" -s $server | tr -d "\n" | grep -o -E '<div class="title">[[:space:]]*<h2>([^"]*)</h2>' | grep -o -P '<h2>\K[^"]*' | tr -d '</h2>')	
			fix_title
		fi

		if [[ $referer == *"vidmoly"* ]]
                then
                        parsevidmoly

                        if [[ -f "$episode_output_path" ]]
                        then
                                exit 0
                        else
                                continue
                        fi
                fi

		get_video_link $referer
		if [[ $mp4 == *"m3u"* ]]
		then
			download $referer $mp4	
		fi

		pick_mp4 $referer $mp4
	done
	download $chosen_referer $chosen_mp4
	
}

fix_title(){
	result_title=$(echo $result_title | sed 's/ *$//; s/&nbsp;/ /g; s/&amp;/\&/g; s/&lt;/\</g; s/&gt;/\>/g; s/&quot;/\"/g; s/#&#39;/\'"'"'/g; s/&ldquo;/\"/g; s/&rdquo;/\"/g; s/&#8217;/\'"'"'/g;')
}



search () {
	#Result shows a string that contains both url and title but unformatted
	url_title=$(curl --user-agent "$user_agent" -s "$base_url/search/$1" | tr '\n' ' ' | grep -o -E  '<div class="under-thumb">[[:space:]]*<a href="([^"]*)" title="([^"]*)"\S')
	if [ -z "$url_title" ]
	then
		echo "Media $title was not found! :("
		exit 1
	fi
	echo "$url_title" | while IFS= read -r line ; do
		result_url=$(echo "$line" | grep -o -E 'https.*/')	
		#Extracts text that is inside the title tag.
		#Sed removes the space left out in the end
		result_title=$(echo "$line" | grep -o -P 'title="\K[^"]*')
		fix_title
		if [[ $result_title == *"$1"* ]]
		then	
			parse_embed_referer "$result_url"
			exit
		fi
		index=$index+1
	done


}




if [[ $1 == *"http"* ]]
then
	parse_embed_referer "$1"
else
	search "$1"
fi
