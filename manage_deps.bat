@echo off
set PUB_CACHE=d:\flutter_pub_cache
echo Using PUB_CACHE=%PUB_CACHE%
if not exist d:\flutter_pub_cache mkdir d:\flutter_pub_cache
echo Cleaning...
call flutter clean
echo Upgrading...
call flutter pub upgrade --major-versions --no-tighten
echo Getting dependencies...
call flutter pub get
echo Done.
