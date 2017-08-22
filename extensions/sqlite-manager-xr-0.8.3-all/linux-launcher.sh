APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROFILE_DIR=$APP_DIR/profiles/sqlite-composer
mkdir -p $PROFILE_DIR
$APP_DIR/browser-bin --app $APP_DIR/apps/sqlite-manager/application.ini --no-remote --profile $PROFILE_DIR
