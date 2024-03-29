## **Filma24-CLI** - Download Albanian Movies and TV Series through filma24 using the terminal.

## Check out [anisq](https://github.com/deniscerri/anisq) for a similar implementation

### Table of Contents

- [Dependencies](#Dependencies)
- [Install](#Installation)
  - [Linux](#Linux)
  - [Android](#Android)
  - [Windows](#Windows)
- [Usage](#Usage)
- [Disclaimer](#Disclaimer)

### Dependencies that need to be installed: <a name="Dependencies"></a>

- ffmpeg
- curl
- vlc
- yt-dlp

## Installation: <a name="Installation"></a>

### Generic Linux <a name="Linux"></a>

`git clone https://github.com/deniscerri/filma24-cli` <br>
`cd filma24-cli && chmod +x f24`<br>
`sudo cp f24 /usr/local/bin/f24`

### Android <a name="Android"></a>

- Download [Termux](https://f-droid.org/en/packages/com.termux/) <br>
- Give storage permissions with the command: `termux-setup-storage` <br>
- `git clone https://github.com/deniscerri/filma24-cli` <br>
- `cd filma24-cli && chmod +x f24` <br>
- `cp f24 $PREFIX/bin/f24`
- (DISCLAIMER. VLC on Android doesn't support Referrers so there is no way to play on Android for now)

### Windows <a name="Windows"></a>

Either install WSL (Windows Subsystem for Linux) or Git Bash.

- If you choose WSL, you can use the same commands as generic linux. (If you are running WSL1, you can't open VLC so you can only download with it. You need to upgrade to WSL2 or use Git Bash)
- On Git Bash you need to keep to copy f24 to /usr/bin/ directory instead and you need to run it as an administrator to achieve that.

## Usage: <a name="Usage"></a>

### Download a movie

      f24 -m [Movie Title or URL]

- ### Download a movie in interactive mode
      f24 -im [Movie Title]
- ### Watch a movie
      f24 -wm [Movie Title]
- ### Watch a movie, but make a choice first
      f24 -wim [Movie Title]

---

### Download series

      f24 -t [Series Title or URL]

- ### Download series in interactive mode
      f24 -it [Series Title]
- ### Watch first episode of the first season
      f24 -wt [Series Title]
- ### Watch first episode of a custom season
      f24 -wt [Series Title] -s [Season Nr]
- ### Watch a custom episode of a custom season
      f24 -wt [Series Title] -s [Season Nr] -e [Episode Nr]

---

### Custom Output Directory

      f24 [options] [query] -o [directory path]

---

### Using a List

You can use a txt file filled with names or url's and use that as input. The script will go over all of them.

- If you add a custom season, the script will download the same season number for all elements on the list. Same thing will happen for a custom episode.

---

### Options

      -h help this page
      -m sets media type as movie
      -t sets media type as tv series
      -w watch instead of downloading
      -s set a particular season to download. By default it downloads all seasons
      -e set a particular episode to download. By default it downloads all episodes
      -o set a custom download path. By default it downloads in your current working directory
      -i use interactive mode when searching, instead of the script picking it itself
      -u update the script

## Disclaimer: <a name="Disclaimer"></a>

This script was made to make it easier to download movies and tv series through web scraping instead of doing so manually. Every content that is being downloaded is hosted by third parties, as mentioned in the webpage that is used for scraping. <br>
Use it at your own risk. Make sure to look up your country's laws before proceeding. <br>
<br>
Any Copyright Infridgement should be directed towards the scraped website or hosts inside it.
