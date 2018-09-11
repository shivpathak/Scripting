#!/usr/bin/env bash

TODAY=`date +%Y%m%d`

LIST_OF_DOMAINS="www.google.com:443"

FILE="output.txt"

echo -ne "{\"id\": \"130640661\", 
	\"type\": \"page\",\"title\": \"Google SSL Certificates Expiry Status\",
    \"space\": {
        \"key\": \"ISHS\"
    },
    \"body\": {
        \"storage\": { \"value\": "  > $FILE

echo -ne "\"<p> Green 60+ Days Left </p><p> Yellow 30-60 Days Left </p><p> Red Less than 30 Days </p> " >> $FILE

echo -ne "<div class=\\\"table-wrap\\\"><table class=\\\"confluenceTable\\\"><tbody><tr><th class=\\\"confluenceTh\\\">DOMAIN<\/th><th class=\\\"confluenceTh\\\">Issuer<\/th><th class=\\\"confluenceTh\\\">Serial<\/th><th class=\\\"confluenceTh\\\">Expiry<\/th><th class=\\\"confluenceTh\\\">Days Left<\/th><\/tr>" >> $FILE

for i in `echo $LIST_OF_DOMAINS`
  do
    domain=`echo $i|awk -F':' '{print $1}'`
    name=$i
    san=`echo |openssl s_client -servername $domain -connect $name |openssl x509 -noout -text |grep 'DNS:'|sed 's/DNS://g' | sed 's/ //g'`
    sleep 2 
   
   issuer=`echo |openssl s_client -servername $domain -connect $name |openssl x509 -noout -issuer`
    sleep 2 

   serial=`echo |openssl s_client -servername $domain -connect $name |openssl x509 -noout -serial`
   sleep 2

   enddate=`echo |openssl s_client -servername $domain -connect $name |openssl x509 -noout -enddate`
   sleep 2

   I=`echo $issuer|awk -F'=' '{print $(NF)}'`
 
   SR=`echo $serial|awk -F'=' '{print $(NF)}'`
 
   E=`echo $enddate|awk -F'=' '{print $(NF)}'`
 
   EXPIRES=`date -d "$E" "+%Y%m%d"`
 
   DIFF=`echo $(($(($(date -d "$EXPIRES" "+%s") - $(date -d "$TODAY" "+%s"))) / 86400))`
 
   if [[ $san =~ , ]]; then
      export san=`echo $san|sed 's/,/\<br\>\<\/br\>/g'`
      echo $san
   fi
 
   if [[ "$DIFF" -le "60" ]];then
      export COLOR=\\\"yellow\\\"
   elif [[ "$DIFF" -le "30" ]];then
      export COLOR=\\\"red\\\"
   else
      export COLOR=\\\"green\\\"
    fi

   echo -ne "<tr><td class=\\\"confluenceTh\\\">${san}<\/td><td class=\\\"confluenceTh\\\">${I}<\/td><td class=\\\"confluenceTh\\\">${SR}<\/td><td class=\\\"confluenceTh\\\">${E}<\/td><td bgcolor=${COLOR} class=\\\"confluenceTh\\\">${DIFF}<\/td></tr>" >> $FILE

 done

echo -ne "<\/tbody><\/table><\/div>\", " >> $FILE

version=$(curl -x http://ACTUAL_PROXY -H "Authorization: Basic ACTUAL_BASE64_ENC_USER_PASS" -H"Content-Type: application/json" https://ACTUAL_CONFLUENCE_DOMAIN/rest/api/content/130640661 | jq -r ".version.number")
let "version+=1"

echo "\"representation\": \"storage\"
        }
    },
    \"version\": {
        \"number\": $version
    }
}" >> $FILE

sleep 5
echo "Going to upload"
curl -x http://ACTUAL_PROXY -H "Authorization: Basic ACTUAL_BASE64_ENC_USER_PASS" -H"Content-Type: application/json" -X PUT -d @${FILE} https://ACTUAL_CONFLUENCE_DOMAIN/rest/api/content/130640661
