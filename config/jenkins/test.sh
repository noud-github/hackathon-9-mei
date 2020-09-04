source ./shared/init.sh
source ./shared/functions.sh
source ./config/jenkins/functions.sh


####screen -r

#ssh -o StrictHostKeyChecking=no -l pi 10.0.10.10 uname -a

Check_Milestone

Go_To_New_Repo_Directory

#git clone https://${GITHUB_ACCESS_TOKEN}@github.com/${GITHUBACOUNT}/${FOLDER_NAME}.git
git clone https://github.com/${GITHUBACOUNT}/${FOLDER_NAME}.git

cd ${FOLDER_NAME}

echo "guess the number: "$(Get_Release_X.XX)

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

Set_SVN_to_Silent

Set_Exit_Code

