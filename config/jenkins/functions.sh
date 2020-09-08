Install_SVN(){
    if [[ "$LIVE" = "true" && "$GITHUBACOUNT" = "Yoast" ]]; then
        echo install svn
		hash -d svn
        apt-get update
        apt-get -y install subversion 
    else
        echo use installed svn mockup
    fi
}

Check_For_Changelog_Entry_IN_Readme_file(){
    echo check $README_FILE
    sed -n -e '/== Changelog ==/,// p' $README_FILE
    if [[ $(sed -n -e '/== Changelog ==/,// p' $README_FILE | sed -n -e '/= '${YOAST_TAG}' =/,/^$/ p' | grep ${YOAST_TAG}) ]]; then
        echo Changelog entry found
    else
        echo did not find Changlog entry
        if [[ "$LIVE" = "true" ]]; then
            #todo: slack message to #channel?
            exit 1
        fi
        if [[ "$PRE" = "true" ]]; then
            TASK_RESULT="FAILURE"
			EXIT_MESSAGE="$EXIT_MESSAGE\ndid not find Changlog entry"
        fi
        echo "NOT ok!!!"
    fi
}

Check_Release_Date_In_Changelog_Section_Readme(){
    echo check release date in readme
    FOUNDRELEASEDATE=$(sed -n -e '/== Changelog ==/,// p' $README_FILE | sed -n -e '/= '${YOAST_TAG}' =/,/^$/ p' | grep 'Release Date:')
    echo $FOUNDRELEASEDATE
    case $(date '+%-d') in
        1?) ORDINAL=th ;;
        *1) ORDINAL=st ;;
        *2) ORDINAL=nd ;;
        *3) ORDINAL=rd ;;
        *)  ORDINAL=th ;;
    esac
    CALCULATEDRELEASEDATE=$(echo 'Release Date:' $(date '+%B %-d'${ORDINAL}', %Y'))
    echo $CALCULATEDRELEASEDATE
    if [ "$FOUNDRELEASEDATE" = "$CALCULATEDRELEASEDATE" ]; then
            echo "ok"    
    else
            echo  "Not OK date found is not today"
            if [[ "$LIVE" = "true" ]]; then
                #todo: slack message to #channel?
                exit 1
            fi
			TASK_RESULT="FAILURE"
			EXIT_MESSAGE="$EXIT_MESSAGE\ndate found in release log is not today"
    fi
}

Check_For_Blank_Lines_After_Header_In_Changelog_Section_Readme(){
    #find missing blank line after header ending:
    if [[ $(sed -n -e '/== Changelog ==/,// p' $README_FILE  |  sed 's/[[:space:]]*$//g' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g' |  grep '\\n[a-zA-Z0-9]*:\\\n\* ') ]]; then
    echo "found missing NEWLINE after header in ${README_FILE}"
    if [[ "$LIVE" = "true" ]]; then
            #todo: slack message to #channel?
            exit 1
        fi
        if [[ "$PRE" = "true" ]]; then
            TASK_RESULT="FAILURE"
			EXIT_MESSAGE="$EXIT_MESSAGE\nfound missing NEWLINE after header in ${README_FILE}"
        fi
    fi
}

Set_SVN_to_Silent(){
    # set svn username in wp_deploy config.
    # ./node_modules/@yoast/grunt-plugin-tasks/config/wp_deploy.js
    # skip_confirmation: true,
    # svn_user: 'Yoast',
    # force_interactive: false,
    # not very pritty but it does the job:
    sed -i'' -e 's/deploy_trunk: true,/deploy_trunk: true,skip_confirmation: true,svn_user: "Yoast",/g' $REPOBASE/$FOLDER_NAME/node_modules/@yoast/grunt-plugin-tasks/config/wp_deploy.js
    #read -p "Press enter to continue"
}


Select_Changlog_From_Readme(){
    lines=`sed -n -e '/^== Changelog ==/,// p' $README_FILE | grep -n '^= [0-9]' | sed -n 1,2p | cut -d : -f 1`
    range=`echo "${lines}" | head -n 1`","$(( `echo "${lines}" | tail -n 1` -1 ))"p"

    RELEASE_TXT=$(sed -n -e '/^== Changelog ==/,// p' $README_FILE | sed -n "${range}" |  sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g' -e 's/\t/  /g' | sed -e 's/"/\\"/g')

    if [[ "$RELEASE_TXT" = "" ]]; then
    echo release text not found!!!
    if [[ "$LIVE" = "true" ]]; then
            #todo: slack message to #channel?
            exit 1
        fi
        if [[ "$PRE" = "true" ]]; then
            TASK_RESULT="FAILURE"
			EXIT_MESSAGE="$EXIT_MESSAGE\nrelease text not found!!!"
        fi
    fi
	# test for ^= YOAST_TAG = entry in Changelog 
	foundtag=$(echo "$RELEASE_TXT" |  grep -e '^= '$YOAST_TAG' =')
	if [[ "$foundtag" = "" ]]; then
    	echo "missing = $YOAST_TAG = line in release log this will break release post on Wordpress.com!!"
    if [[ "$LIVE" = "true" ]]; then
            #todo: slack message to #channel?
            exit 1
        fi
        if [[ "$PRE" = "true" ]]; then
            TASK_RESULT="FAILURE"
			EXIT_MESSAGE="$EXIT_MESSAGE\nmissing = $YOAST_TAG = line in release log this will break release post on Wordpress.com!!"
        fi
    fi
}

Update_Yoastdotcom_SEO_Free_Changelog () {
    lines=`sed -n -e '/^== Changelog ==/,// p' $README_FILE | grep -n '^= [0-9]' | sed -n 1,2p | cut -d : -f 1`
    range=`echo "${lines}" | head -n 1`","$(( `echo "${lines}" | tail -n 1` -1 ))"p"

    RELEASE_MD=$(sed -n -e '/^== Changelog ==/,// p' $README_FILE | sed -n "${range}" | sed -e 's/^= \([0-9][0-9\.]*\) =/## \1/g') 

    if [[ "$RELEASE_MD" = "" ]]; then
    echo release text not found!!!
    exit 1
    fi

    markdown2html 

    RELEASE_HTML=$(echo "$RELEASE_HTML" | sed -e 's/<h2>\(.*\)<\/h2./<h2 class="\1">\1<\/h2>/g' )      


    #echo "$RELEASE_HTML" 

    ssh -o stricthostkeychecking=no $SSH_HOST  'cd '$WP_FILES' && wp post get '$ChanglogPostid' --field=content' > $BASEDIR/changelog.html

    #find line of previus release header
    line=$(sed -n -e '1,/^</ p' $BASEDIR/changelog.html | grep -n '^<h2.*</h2>' | cut -d : -f 1)
    #HEAD
    sed -n "1, $(( `echo "$line"` -1)) "p  $BASEDIR/changelog.html > $BASEDIR/new_changelog.html
    #NEW
    echo "$RELEASE_HTML" >> $BASEDIR/new_changelog.html
    #TAIL
    sed -n "$(echo "$line"),$ p" $BASEDIR/changelog.html >> $BASEDIR/new_changelog.html

    Update_Yoastdotcom_Changelog_Post

    rm $BASEDIR/new_changelog.html $BASEDIR/changelog.html
}