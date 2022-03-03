# **Filma24-CLI** - Download Albanian Movies and TV Series through filma24 using the terminal.

## Installing:

`git clone https://github.com/deniscerri/filma24-cli && cd filma24-cli` <br>
`sudo cp f24 /usr/local/bin/f24`

## Usage:

### Download a movie

      f24 -m -f [Movie Title or URL]

### Download series

      f24 -t -f [Series Title or URL]

### Options

      -h show help page
      -m sets media type as movie
      -t sets media type as tv series
      -f give the Media title or URL for the script to scrape.
      -s set a particular season to download. By default it downloads all seasons
      -o set a custom download path. By default it downloads in your Downloads folder

## Disclaimer:

This script was made to make it easier to download movies and tv series through web scraping instead of doing so manually. Every content that is being downloaded is hosted by third parties, as mentioned in the webpage that is used for scraping. <br>
Use it at your own risk. Make sure to look up your country's laws before proceeding. <br>
<br>
Any Copyright Infridgement should be directed towards the scraped website or hosts inside it.
