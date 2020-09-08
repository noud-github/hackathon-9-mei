source ./shared/init.sh
source ./shared/functions.sh
source ./config/jenkins/functions.sh

####screen -r

echo "Choice: ${CHOICE}"

exit

Go_To_New_Repo_Directory

git clone https://${GITHUB_ACCESS_TOKEN}@github.com/${GITHUBACOUNT}/${FOLDER_NAME}.git
#git clone https://github.com/${GITHUBACOUNT}/${FOLDER_NAME}.git

cd ${FOLDER_NAME}

SET_Release_Branch

echo "release: $YOAST_TAG"

Check_Milestone

git checkout $RELEASEBRANCH

git merge origin/master

#check verions (bailout on unexpected versions)
Check_Package_Versions

#Remove the artifact folder if present
rm -rf  artifact

yarn

#Update version
grunt set-version --new-version=${YOAST_TAG}

Check_For_Changelog_Entry_IN_Readme_file

Check_Release_Date_In_Changelog_Section_Readme

Check_For_Blank_Lines_After_Header_In_Changelog_Section_Readme

git add package.json

git status

git commit -m "Bump version to ${YOAST_TAG}"

# if more files changed than giit add than bail out'
grunt ensure-clean-branch

if [[ "$LIVE" = "true" ]]; then
    echo push to ${RELEASEBRANCH}
    git push origin ${RELEASEBRANCH}
fi

git checkout master
git pull
git merge --no-ff ${RELEASEBRANCH} -m "Merge branch '${RELEASEBRANCH}'"

Install_SVN
Set_SVN_to_Silent

grunt deploy:master

git status

git add readme.txt
git add wp-seo-main.php
git add wp-seo.php
git add svn-assets/.

git status

git commit -m "Bump version to ${YOAST_TAG}"

# if more files changed than git add than bail out'
grunt ensure-clean-branch

git tag -a ${YOAST_TAG} -m "${YOAST_TAG}"

if [[ "$LIVE" = "true" ]]; then
    echo push to master
    git push origin master --tags
else
    echo push to CI-test
    git push origin master:CI-test --force --quiet
fi

#select release text
Select_Changlog_From_Readme

#echo "$RELEASE_TXT"

Do_Github_Release

#cleanup
#rm $BASEDIR/$FOLDER_NAME.zip

#todo: check  WordPress.org plugins trac & changelog
#https://wordpress.org/plugins/wordpress-seo/

#todo: SLACK: #random #yoast_support

#update changelog yoast.com
Update_Yoastdotcom_SEO_Free_Changelog

#todo: update verion wiki pedia

#todo: update stable version in atlassian

#todo: do a tweet as @YoastDev (sname message as slack message?)

#todo: Close github milestone and delete release/${YOAST_TAG} branch

#next! Premium release

Set_Exit_Code

