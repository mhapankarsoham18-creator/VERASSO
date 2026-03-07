@echo off
echo. > release_log.txt
echo Git Status: >> release_log.txt
git status >> release_log.txt 2>&1
echo --- >> release_log.txt
echo Aborting merge if any... >> release_log.txt
git merge --abort >> release_log.txt 2>&1
echo Pulling changes... >> release_log.txt
git pull --no-rebase >> release_log.txt 2>&1
echo Resolving .flutter-plugins-dependencies conflict... >> release_log.txt
git checkout --theirs .flutter-plugins-dependencies >> release_log.txt 2>&1
echo Adding files... >> release_log.txt
git add . >> release_log.txt 2>&1
echo Committing Prototype v001... >> release_log.txt
git commit -m "prototype v001" >> release_log.txt 2>&1
echo Pushing... >> release_log.txt
git push >> release_log.txt 2>&1
echo Done. >> release_log.txt
