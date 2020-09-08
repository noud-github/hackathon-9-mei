Go_To_New_Repo_Directory(){
    [[ -d "$REPOBASE" ]] && rm -rf "$REPOBASE"
    mkdir -p "$REPOBASE"
    cd "$REPOBASE"
}

SET_Release_Branch ()
{
	if [["OVERRIDE_YOAST_TAG" = ""]]; then
		# pick the lowest release branch
		if [[ "$HOTFIX" = "true" ]]; then
			YOAST_TAG=$(git branch -a | grep 'hotfix/[1-9]' | cut -d / -f 4 | sort -V | head -n 1 )
			RELEASEBRANCH='hotfix/'${YOAST_TAG}
		else
			YOAST_TAG=$(git branch -a | grep 'release/[1-9]' | cut -d / -f 4 | sort -V | head -n 1 )
			RELEASEBRANCH='release/'${YOAST_TAG}
		fi
	else
		YOAST_TAG="$OVERRIDE_YOAST_TAG"
		if [[ "$HOTFIX" = "true" ]]; then
				RELEASEBRANCH='hotfix/'${YOAST_TAG}
			else
				RELEASEBRANCH='release/'${YOAST_TAG}
			fi
		fi	
}

GET_Monorepro_Highest_Release() {
    local CURDIR=$(pwd)
    local YOAST_REPOSITORYNAME="$1"
    if [ "$YOAST_REPOSITORYNAME" == "@yoast/grunt-plugin-tasks" ]; then
        YOAST_REPOSITORYNAME="plugin-grunt-tasks"
    fi
    local MYTAG=""
    cd $REPOBASE
    [ ! -d $REPOBASE/javascript.git ] && git clone --bare https://github.com/Yoast/javascript.git
    cd javascript.git
    if [[ $(git tag --list ${YOAST_REPOSITORYNAME}*) ]]; then
        local POS=1
        if [[ ${YOAST_REPOSITORYNAME} == "@"* ]]; then
            POS=2
        fi   
        MYTAG=$(/usr/bin/python3 -c "import re, operator, subprocess; print(sorted({str(line.decode('utf-8').rstrip().split('@')[${POS}]): int(sum([(1000**k)*v for k,v in dict(enumerate(reversed([int(d) for d in re.findall(r'[\d]+', line.decode('utf-8'))]))).items()])) for line in subprocess.Popen(['git', 'tag', '--list', '${YOAST_REPOSITORYNAME}*'], stdout=subprocess.PIPE).stdout.readlines() if re.match('^\d+\.\d+\.\d+$' , str(line.decode('utf-8').rstrip().split('@')[${POS}])) is not None}.items(), key=operator.itemgetter(1))[-1][0])")
    
    else
        cd $REPOBASE
        # not mono repro!!!
        [ ! -d $REPOBASE/$YOAST_REPOSITORYNAME.git ] && git clone --bare https://github.com/Yoast/$YOAST_REPOSITORYNAME.git
        cd $YOAST_REPOSITORYNAME.git
        MYTAG=$(/usr/bin/python3 -c "import re, operator, subprocess; print(sorted({str(line.decode('utf-8').rstrip()): int(sum([(1000**k)*v for k,v in dict(enumerate(reversed([int(d) for d in re.findall(r'[\d]+', line.decode('utf-8'))]))).items()])) for line in subprocess.Popen(['git', 'tag'], stdout=subprocess.PIPE).stdout.readlines() if re.match('^\d+\.\d+\.\d+$' , str(line.decode('utf-8').rstrip())) is not None}.items(), key=operator.itemgetter(1))[-1][0])")
    fi
    cd $CURDIR
    [[ "$MYTAG" != "" ]] && echo "$MYTAG"
}

Check_Package_Versions () {
    local PressEnter=false
	local message=""
    local lines=$(grep '"@*yoast[^"]' package.json) 
    while read  line ; do
        echo "Processing $line"
        local REPRO=$(echo $line| cut -d'"' -f 2)
        local VERSION=$(echo $line| cut -d'"' -f 4 | cut -d'^' -f 2)
        local RELESEDVERSION=$(GET_Monorepro_Highest_Release $REPRO )
        if [[ "$RELESEDVERSION" = "$VERSION" ]]; then
            echo "ok"
        else
            message="$message\n $REPRO is set to wrong version $VERSION in package.json expected version: $RELESEDVERSION" 
			#echo "message: $message"
			echo $REPRO "is set to wrong version" $VERSION "in package.json expected version:" $RELESEDVERSION 
            if [[ "$LIVE" = "true" ]]; then
                if [[ "$REPRO" = "@yoast/grunt-plugin-tasks" ]]; then
                    echo "ignoring this for repo: $REPRO" 
                else
                    # slack message to #channel?
                    exit 1
                fi
            fi
            if [[ "$PRE" = "true" ]]; then
                if [[ "$REPRO" = "@yoast/grunt-plugin-tasks" ]]; then
                    echo "ignoring this for repo: $REPRO"
                else
                    # slack message to #channel?
                    PressEnter=true
                    #exit 1
                fi
            fi
        fi
    done <<<  "$(echo -e "$lines")"
    if [[ "$PressEnter" = "true" ]]; then
        read -p "Press enter to continue"
		TASK_RESULT="FAILURE"
		EXIT_MESSAGE="$EXIT_MESSAGE\n$message"
    fi
}


Check_Milestone () {
    local OPENISSUES=$(curl -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" -s https://api.github.com/repos/yoast/${FOLDER_NAME}/milestones | python3 -c "import sys, json; data=json.load(sys.stdin); print(next(x['open_issues'] for x in data if x['title']=='${YOAST_TAG}'))")
    if [[ "$OPENISSUES" != "" ]]; then
        if [[ "$OPENISSUES" != "0" ]]; then
            echo "There are $OPENISSUES open issues in the milestone!!!"
            if [[ "$LIVE" = "true" ]]; then
                #todo: slack message to #channel?
                exit 1                
            fi
            if [[ "$PRE" = "true" ]]; then
                TASK_RESULT="FAILURE"
                EXIT_MESSAGE="$EXIT_MESSAGE\nThere are $OPENISSUES open issues in the milestone!!!"
            fi 
        fi
    else
         echo "There is no milestone!!!"
        if [[ "$LIVE" = "true" ]]; then
            #todo: slack message to #channel?
            if [[ "$HOTFIX" = "true" ]]; then
                    echo "this is a hotfix"
                else
                    exit 1
            fi     
        fi
        if [[ "$PRE" = "true" ]]; then
            TASK_RESULT="FAILURE"
            EXIT_MESSAGE="$EXIT_MESSAGE\nThere is no $YOAST_TAG milestone!!!"
        fi 
    fi
    echo "done milestone check for ${FOLDER_NAME} ${YOAST_TAG}"
}

Do_Github_Release () {
    echo "Creating GITHUB release"
    local API_JSON='{"tag_name": "'${YOAST_TAG}'","target_commitish": "master","name": "'${YOAST_TAG}'","body": "'"${RELEASE_TXT}"'","draft": false,"prerelease": false}'
    local API_URL="https://api.github.com/repos/noud-github/hackathon-9-mei/releases"
    if [[ "$LIVE" = "true" ]]; then
        echo add release to github
        API_URL="https://api.github.com/repos/${GITHUBACOUNT}/${FOLDER_NAME}/releases"
    else
        echo add release to test
    fi
    #echo "$API_JSON"
    #add a release
    if [[ "$LIVE" = "true" || "$PRE" = "true" ]]; then
        result=$(curl -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" --data "$API_JSON" "$API_URL")

        upload_url=`echo "${result}" | grep '"upload_url":' | cut -d : -f 2- | cut -d '{' -f 1 | cut -d '"' -f 2`?name=${FOLDER_NAME}.zip

        #echo "${upload_url}"
        if [[ "$upload_url" = "?name=${FOLDER_NAME}.zip" ]]; then
        echo upload_url text not found!!!
        echo "${result}"
        exit 1
        fi

        #Upload zip as asset to release
        if [[ "$LIVE" = "true" || "$FOLDER_NAME" = "wordpress-seo" ]]; then
            curl -H "Authorization: token $GITHUB_ACCESS_TOKEN" -H "Content-Type: $(file -b --mime-type artifact.zip)" --data-binary @artifact.zip "${upload_url}"
        else
            echo "$upload_url"
        fi    
    fi
}

Do_We_Need_Commit() {
[[ $(git status | grep "nothing to commit, working tree clean") = "nothing to commit, working tree clean" ]] && echo false || echo true
}

Upload_Zip_To_Yoast(){

if [[ `ssh $SSH_HOST  [ -f "'$WP_FILES'/app/uploads/"$(date +"%Y")"/"$(date +"%m")"/wordpress-seo-premium-$YOAST_TAG.zip" ] && echo "exist"` = "exist" ]]; then
    echo "already uploaded"
    if [[ "$LIVE" = "true" ]]; then
        exit 1
    fi
else
    # add file to media
    scp  $BASEDIR/$FOLDER_NAME-$YOAST_TAG.zip  $SSH_HOST:~/dump
    ssh $SSH_HOST  'cd '$WP_FILES' && wp media import ~/dump/wordpress-seo-premium-'$YOAST_TAG'.zip --porcelain | xargs -I {} wp post update {} --post_author=388975'
    ssh $SSH_HOST 'rm ~/dump/'$FOLDER_NAME-$YOAST_TAG.zip
    if [[ `ssh $SSH_HOST  [ -f "'$WP_FILES'/app/uploads/"$(date +"%Y")"/"$(date +"%m")"/wordpress-seo-premium-$YOAST_TAG.zip" ] && echo "exist"` = "exist" ]]; then
        echo upload succes!!
    else 
        exit 1
    fi
fi
}

Calc_md5 (){
    md5_url=`echo -n $YOAST_DOWNLOAD_URL | md5sum |  cut -d ' ' -f 1`
}


Update_Product_Post(){
    local postid="$1"
    local url="$SITE_URL/$2/wp-admin"

    #build url
    local YOAST_DOWNLOAD_URL="https://$SITE_URL/app/uploads/"$(date +"%Y")"/"$(date +"%m")"/wordpress-seo-premium-$YOAST_TAG.zip"
    #echo $YOAST_DOWNLOAD_URL
    Calc_md5
    #echo $md5_url
    local previous_hash=$(ssh $SSH_HOST  'cd '$WP_FILES' && wp --url='$url' post meta get '$postid' _downloadable_files --format=json | cut -d : -f 1 | cut -d '"'\"'"' -f 2')

    #echo $previous_hash
    if [ "$previous_hash" = "$md5_url" ]; then
        previous_hash=""
    fi
    #echo "$previous_hash < $md5_url"
    local my_JSON_value="'{\"$md5_url\":{\"id\":\"$md5_url\",\"name\":\"zip\",\"file\":\""$(echo $YOAST_DOWNLOAD_URL| sed -e 's,/,\\/,g')"\",\"previous_hash\":\"$previous_hash\"}}'"
    #echo $my_JSON_value
    
    ssh $SSH_HOST  'cd '$WP_FILES' && wp --url='$url' post update '$postid' --meta_input='"'"'{"version":"'$YOAST_TAG'"}'"'"' \
    && echo '$my_JSON_value' | wp --url='$url' post meta update '$postid' _downloadable_files --format=json \
    && wp --url='$url' my-yoast webhook trigger-ids product.updated ['$postid']'

}

# Check_If_More_Files_Changed_Than_Expected(){
#     if [[ $(git status  --porcelain) ]]; then
#         echo more files changed than expected
#         git status
#         if [[ "$LIVE" = "true" ]]; then
#             #todo: slack message to #channel?
#             exit 1
#         fi
#         if [[ "$PRE" = "true" ]]; then
#             read -p "Press enter to continue"
#         fi
#     fi
# }


markdown2html(){
    # remove trailing spaces
    RELEASE_MD=$(echo "$RELEASE_MD" | sed -e 's/[[:space:]]*$//g')
    local MY_RESULT=$(curl -X POST -H "Content-Type: application/x-www-form-urlencoded; charset=utf-8" --data-urlencode "Submit=Format" --data-urlencode "changelog=$RELEASE_MD"  https://yoast.com/internal-tools/format-changelog.php)
    local line=`echo "$MY_RESULT" | grep -n '<h2>Result:</h2>'   | sed -n 1,2p | cut -d : -f 1`
    RELEASE_HTML=$(echo "$MY_RESULT" | sed -n $line,'$'p )
    local lines=`echo "$RELEASE_HTML" | grep -n  'textarea' | sed -n 1,2p | cut -d : -f 1`
    local range=`echo "${lines}" | head -n 1`","$(( `echo "${lines}" | tail -n 1` ))"p"
    RELEASE_HTML=$(echo "$RELEASE_HTML" | sed -n "${range}" | sed -e 's/[[:space:]]*<textarea name="result" cols="100" rows="30">//'  -e 's/<\/textarea>.*//'  -e 's/<p>//g' -e 's/<\/p>/\'$'\n/g' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n<\/li>/<\/li>/g' -e 's/\n<li>/\'$'\n \t<li>/g' -e 's/\n\n*<ul>/\'$'\n<ul>/g' -e 's/<\/ul>\n\n*/<\/ul>\'$'\n/g' -e 's/[[:space:]][[:space:]]*<\/li>\n/\<\/li>\'$'\n/g'  -e 's/<\/ul><\/li>/<\/ul>\'$'\n<\/li>/g'   -e 's/<\/small>\n\([a-zA-Z0-9]\)/<\/small>\'$'\n\\\n\\1/g'  -e 's/\&quot\;/"/g')
}

Update_Yoastdotcom_Changelog_Post(){

    scp -o stricthostkeychecking=no $BASEDIR/new_changelog.html $SSH_HOST:~/dump/$ChanglogPostid.new_changelog.html
    ssh -o stricthostkeychecking=no $SSH_HOST  'cd '$WP_FILES' && wp post update '$ChanglogPostid' ~/dump/'$ChanglogPostid'.new_changelog.html'
    ssh -o stricthostkeychecking=no $SSH_HOST  'rm ~/dump/'$ChanglogPostid'.new_changelog.html'  

}

Set_Exit_Code(){
	if [[ "$TASK_RESULT" = ""FAILURE"" ]]; then
		echo -e "Summery why it did not pass tests:$EXIT_MESSAGE"
		exit 1
	else
		if [[ "$EXIT_MESSAGE" != "" ]] then
			echo -e "Warning: $EXIT_MESSAGE"
		fi
	fi

}