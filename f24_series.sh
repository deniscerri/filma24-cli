#!/bin/bash

user_agent="Chrome/97"
download_path="/home/$USER"
base_url="https://www.filma24.bz"
newline=$'\n'
file_size=0
url_retries=0

parsevidmoly(){
        fixedURL=$(echo "$referer" | sed 's/embed-//g')
        videoID=$(echo "$fixedURL" | sed 's/https:\/\/vidmoly.net\///g' | sed 's/https:\/\/vidmoly.net\///g' | sed 's/.html//g')

        videoHash=$(curl -s -i -H "Accept: text/html" -H "Content-Type: text/html" -X GET "https://vidmoly.net/dl?op=download_orig&id=$videoID&mode=&hash=" |
 grep -o -E 'name="hash" value=".*"' | grep -o -P 'value="\K[^"]*')

        page_with_mp4=$(curl -s -i -H "Accept: text/html" -H "Content-Type: text/html" -X GET "https://vidmoly.net/dl?op=download_orig&id=$videoID&mode=n&hash=$videoHash")
        mp4=$(echo "$page_with_mp4" | grep -o -E '*https://.*([^"])*.mp4' | head -1)
	
        if [ -z "$mp4" ]
        then
			if [[ $url_retries -gt 5 ]]
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
		echo "Couldn't find a suitable stream for the selected episode! :("
		return
	fi
	echo "Downloading from $1 with video url $2"
	if [[ $2 == *"m3u"* ]]
	then
	       	
		ffmpeg -http_persistent 0 -nostdin -hide_banner -v warning -stats -headers "Referer: $1" -i $2 -c copy "$episode_output_path" || true
		return
	else
		wget -q --show-progress --header="Referer: $(echo $1 | tr -d '\n')" "$2" -O "$episode_output_path" || true
	fi
}

check_http () {
	if [ -z $1 ]
	then
		return
	fi
	http=$(echo "$1" | grep "^http" | wc -c)
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
		mp4="$(curl --user-agent "$user_agent" -s "$1" | grep -o -E '*https://.*([^"]*.m3u8")' | sed 's/"//g' | head -n 1)"
	fi
	
}

parse_embed_referer () {

	nr_of_servers=$(curl --user-agent "$user_agent" -s $1 | grep -o -E '.*<a data-servera=".*' | wc -l | tr -dc '0-9')
	for ((i = 1 ; i <= $nr_of_servers ; i++))
	do
		
		server="$1?server=$i"	
		referer="$(curl --user-agent "$user_agent" -s $server | grep -o -E '*<p><iframe.*' | tr -d '"' | grep -o -P 'src=\K[^ ]*' | xargs echo -n)"
		
		if [ -z "$referer" ]
		then
			continue
		fi
			
		check_http $referer

		season_nr=$(echo "$episode_label" | grep -o -P 'Sezoni \K[^ ]*')
		episode_nr=$(echo "$episode_label" | grep -o -P 'Episodi \K[^"]*' | tr -d " (I FUNDIT)")

		episode_output_path="$download_path/$result_title/$series_title - S${season_nr}E${episode_nr}.mkv"

		if [ -f "/$episode_output_path" ]
		then
			echo "It Already Exists."
			return
		fi
		
		
		
		if [[ $referer == *"vidmoly"* ]]
		then
			
			if [[ -f "$episode_output_path" ]]
			then
				filesize=$(wc -c "$episode_output_path" | awk '{print $1}' | tr -dc '0-9')
				if [ "$filesize" -lt 50000000 ]
				then
					echo "The Downloading video file was broken."
					continue
				else
					return 0
				fi
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
	
        if [[ -f "$episode_output_path" ]]
	then
		return 0
	else
		download $chosen_referer $chosen_mp4
	fi
}

parse_seasons () {
	episode_list=$(curl --user-agent "$user_agent" -s "$1" | tr -d '\n' | grep -o -E '<div class="under-thumb seriale">[[:space:]]*<a href="([^"]*)"><h4>([^"]*)</h4\S' | tac)
	if [ -z "$episode_list" ]
	then
		echo "Series $query not found! :("
		exit 1
	fi
	#If user input was an url, result_title was never initiated
	if [ -z "$result_title" ]
	then
		result_title=$(curl --user-agent "$user_agent" -s "$1" | tr -d "\n" | grep -o -E '<div class="category-head">[[:space:]].*<h3>([^"]*)</h3>' | grep -o -P '<h3>\K[^"]*' | tr -d '</h3>')
		fix_title
		series_title=$result_title
	fi

	echo "Creating Series Folder"
	mkdir "$download_path/$result_title" || echo "Series Folder already exists. Continuing..."


	season=$2
	if [ -z "$season" ]
	then
		season=0
	fi

	if [ $season -gt 0 ]
	then
		episode_list=$(echo "$episode_list" | grep -o -E ".*Sezoni $season.*")
	fi

	
	echo "$episode_list" | while IFS= read -r line ; do
		episode_label=$(echo "$line" | grep -o -P 'h4>\K[^<]*')
		episode_url=$(echo "$line" | grep -o -E 'https.*/"' | tr -d "\"")

		echo "Downloading $episode_label"
		parse_embed_referer "$episode_url"
	done


}

fix_title(){
        result_title=$(echo $result_title | sed 's/ *$//; s/&nbsp;/ /g; s/&amp;/\&/g; s/&lt;/\</g; s/&gt;/\>/g; s/&quot;		/\"/g; s/#&#39;/\'"'"'/g; s/&ldquo;/\"/g; s/&rdquo;/\"/g; s/&#8217;/\'"'"'/g;')
}


search () {
	url_title=$(curl --user-agent "$user_agent" -s "$base_url/search/$1" | tr -d '\n' | grep -o -E  '<div class="under-thumb">[[:space:]]*<a href="([^"]*)" title="([^"]*)"\S')
	if [ -z "$url_title" ]
	then
		echo "Media $title was not found! :("
		exit 1
	fi

	echo "$url_title" | while IFS= read -r line ; do

		
	result_url=$(echo "$line" | grep -o -E 'https.*/')
	if [[ $result_url != *serial* ]]
	then
		continue
	fi

	#Extracts text that is inside the title tag.
	#Sed removes the space left out in the end
	result_title=$(echo "$line" | grep -o -P 'title="\K[^"]*')
	fix_title	
	if [[ $result_title == *"$input_text"* ]]
	then	
		parse_seasons "$result_url" "$season"
		exit 0
	fi
	index=$index+1
	done


}



query=$1
season=$2
if [[ $query == *"http"* ]]
then
	parse_seasons "$query" "$season"
else
	series_title=$query
	search "$query"
fi
