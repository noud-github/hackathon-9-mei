
BASEDIR=$(pwd)
REPOBASE=$BASEDIR/.repos
RELEASEBRANCH='release/'${YOAST_TAG}


ssh -o StrictHostKeyChecking=no -l pi 10.0.10.10 uname -a

ls -al

source ./shared/functions.sh

Go_To_New_Repo_Directory

ls -al

git clone https://github.com/yoast/${FOLDER_NAME}.git

cd ${FOLDER_NAME}

echo "guess the number: "$(Get_Release_X.XX)

git checkout release/14.9

git merge origin/master

#check verions (bailout on unexpected versions)
Check_Package_Versions

#Remove the artifact folder if present
rm -rf  artifact

yarn

#Update version
grunt set-version --new-version=14.9
