PROFILE_DIR=~/.sqlite-composer/profile
mkdir -p $PROFILE_DIR
./browser-bin --app apps/sqlite-manager/application.ini --no-remote --profile $PROFILE_DIR
