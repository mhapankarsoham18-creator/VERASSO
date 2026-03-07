@echo off
echo Cleaning up large files...
del /Q /S android\*.hprof
del /Q /S android\hs_err_pid*.log
del /Q /S android\replay_pid*.log
echo Regenerating Android project...
flutter create . --platforms=android --force
echo Regeneration complete.
