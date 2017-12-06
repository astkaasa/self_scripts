# get PDAuth
var1=$(curl -H 'Cookie: AProfile=CEwjOAeTvM/HKckYToYwlxHa4hRgihhFBAAAAAAAAAAAAAA=; authreq2=b5c6dcef-feb7-e711-93f6-0a94ef4417ff' -H 'Content-Type: application/x-www-form-urlencoded' -d '__EVENTTARGET=_ctl0&__EVENTARGUMENT=&__VIEWSTATE=%2FwEPDwUKLTE1NTcwMTk0MGRky4%2FL40vbjZE1x93YhzTqGQrIRkc%3D&__VIEWSTATEGENERATOR=6C05F751&__EVENTVALIDATION=%2FwEdAARG446icYIsgxXuoZ92JT7MR1LBKX1P1xh290RQyTesRVwK8%2F1gnn25OldlRNyIedmQRH%2F9Dt8Tjkc82mZrkemniYwnWUNyhDmpWPGTV%2F2SExLPCYg%3D&UserName=200377547&Password=200377547' 'https://account.newspaperdirect.com/epaper/accountingloginse2_nytimes.aspx' | grep -Eo "(http|https)://[a-zA-Z0-9&;./?=_-]*")
var2=$(echo $var1 | sed 's/\&amp;/\&/g')
auth=$(curl -s -D - "${var2}" | grep "PDAuth" | awk -F'PDAuth=|;' '{print $2}')

cd ~/Desktop/nytimes

# first available issue 83022011091900000000001001
today=$(TZ=":America/New_York" date +%Y%m%d)
start_date=$today
end_date=$today
if [[ -n "$1" ]]; then
  start_date=$1
fi
if [[ -n "$2" ]]; then
  end_date=$2
fi

while [[ $start_date -le $end_date ]]; do
  issue="8302${start_date}00000000001001"
  meta=$(curl "http://nytimesnie.newspaperdirect.com/epaper/pageview.aspx?issue=${issue}" | grep 'issue=' | grep 'epaper')
  if [[ $meta =~ "moved" ]]; then
    issue=$(echo $meta | grep -Eo "\d{26}")
    meta=$(curl "http://nytimesnie.newspaperdirect.com/epaper/pageview.aspx?issue=${issue}" | grep 'issue=' | grep 'epaper')
    pages=$(echo $meta | awk  -F't.pages=|;t.bmpages' '{print $2}')
    dir_name="The_New_York_Times($(echo $meta | awk -F't.issue_date="|";t.content_name' '{print $2}' | gdate -f - +'%Y-%m-%d'))"
    mkdir -p $dir_name
    cd $dir_name
    for (( i = 1; i <= $pages; i++ )); do
      url=$(curl "http://nytimesnie.newspaperdirect.com/epaper/PageViewManager.aspx?action=directdownloadpage&issue=${issue}&page=${i}&page2=${i}&cpage=${i}&cpage2=${i}" -H "Cookie: PDAuth=${auth}; _acnt=55304628" | grep trafficmanager | grep -Eo "(http|https)://[a-zA-Z0-9&%;./?=_-]*")
       wget --content-disposition "${url}"
       echo $url >> log
    done
  else
    pages=$(echo $meta | awk  -F't.pages=|;t.bmpages' '{print $2}')
    dir_name="The_New_York_Times($(echo $meta | awk -F't.issue_date="|";t.content_name' '{print $2}' | gdate -f - +'%Y-%m-%d'))"
    mkdir -p $dir_name
    cd $dir_name
    for (( i = 1; i <= $pages; i++ )); do
      url=$(curl "http://nytimesnie.newspaperdirect.com/epaper/PageViewManager.aspx?action=directdownloadpage&issue=${issue}&page=${i}&page2=${i}&cpage=${i}&cpage2=${i}" -H "Cookie: PDAuth=${auth}; _acnt=55304628" | grep trafficmanager | grep -Eo "(http|https)://[a-zA-Z0-9&%;./?=_-]*")
       wget --content-disposition "${url}"
       echo $url >> log
    done
  fi
  i=1; for x in `ls -1 *page[1-9].pdf`; do mv -f $x $(echo $x | awk -v i="$i" -F'page' '{print $1"page0"i".pdf"}'); i=$((++i)); done
  # sudo ln -s "/System/Library/Automator/Combine PDF Pages.action/Contents/Resources/join.py" PDFconcat
  PDFconcat -o "${dir_name}.pdf" *.pdf
  start_date=$(date -j -v +1d -f "%Y%m%d" "$start_date" +%Y%m%d)
  cd ~/Desktop/nytimes
done