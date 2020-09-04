LIVE="false"
PRE="false"
HOTFIX="false"
BASEDIR=$(pwd)
REPOBASE=$BASEDIR/.repos
RELEASEBRANCH='release/'${YOAST_TAG}
#GITHUBACOUNT='noud-github'
GITHUBACOUNT='yoast'
WP_FILES="/home/staging-yoast/staging.yoast.com/web"
SSH_HOST="staging"
SITE_URL="staging.yoast.com"
TASK_RESULT="SUCCESS"
EXIT_MESSAGE=""

[[ "$1" = "live" ]] && LIVE="true"
[[ "$1" = "pre" ]] && PRE="true"
[[ "$1" = "hotfix" ]] && HOTFIX="true"
[[ "$2" = "live" ]] && LIVE="true"
[[ "$2" = "pre" ]] && PRE="true"
[[ "$2" = "hotfix" ]] && HOTFIX="true"

if [[ "$HOTFIX" = "true" ]]; then
    echo "HOTFIX= "$HOTFIX 
    echo "using hotfix/XX.X instead of release/X.XX"
    echo "and no hard error on missing milestone" 
    RELEASEBRANCH='hotfix/'${YOAST_TAG}
fi

if [[ "$LIVE" = "true" ]]; then
    echo "live!!!"
    PRE="false"
    WP_FILES="/home/yoast/shared/yoast.com/www/web"
    SSH_HOST="yoast"
    SITE_URL="yoast.com"
else 
    if [[ "$PRE" = "true" ]]; then
        echo "PRE!!!"
    else
        echo "TEST!!!"
        set -x
    fi
fi

git config user.email "yoastbot-ci@yoast.com"
git config user.name "YoastBot CI"
