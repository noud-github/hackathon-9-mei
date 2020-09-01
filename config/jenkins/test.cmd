set -e 
BASEDIR=$(pwd)
REPOBASE=$BASEDIR/.repos
RELEASEBRANCH='release/'${YOAST_TAG}

if [[ "$HOTFIX" = "true" ]]; then
    echo "HOTFIX= "$HOTFIX 
    echo "using hotfix/XX.X instead of release/X.XX"
    echo "and no hard error on missing milestone" 
    RELEASEBRANCH='hotfix/'${YOAST_TAG}
fi


ssh -o StrictHostKeyChecking=no -l pi 10.0.10.10 uname -a

ls -al

source ./shared/functions.sh

Go_To_New_Repo_Directory

ls -al

git clone https://github.com/yoast/${FOLDER_NAME}.git

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
grunt set-version --new-version=14.9
