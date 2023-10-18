:: Connect to database via config file
@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Specify the path to the configuration file
set "CONFIG_FILE=%~dp0config.txt"

:: Check if the configuration file exists
if not exist !CONFIG_FILE! (
    echo Configuration file "!CONFIG_FILE!" not found. Please create a file in the same directory as the bat file called config.txt with variables:
	echo PGPASSWORD
	echo DB_USER
	echo DB_NAME
	echo DB_HOST
	echo DB_PORT
	echo VOCAB_SCHEMA
	pause
	exit
) else (
    :: Read the configuration file and set the variables
    for /f "usebackq tokens=1,* delims==" %%a in (!CONFIG_FILE!) do (
        set "%%a=%%b"
    )
)

:: Change the schema name in the ref script files

echo Changing the schema name in the refreshDev script file

set "searchString=@devVocabSchema"
set "replaceString=!VOCAB_SCHEMA!"

:: Define the list of files to process
set "filesToProcess=refreshDev.sql"

for %%f in (%filesToProcess%) do (
    set "inputFile=%~dp0/%%f"
    set "outputFile=%~dp0/%%~nf_modified%%~xf"
    
    (for /f "delims=" %%a in ('type "!inputFile!"') do (
        set "line=%%a"
        set "modifiedLine=!line:%searchString%=%replaceString%!"
        echo !modifiedLine!
    )) > "!outputFile!"
)


:: Delete all 2 Billionaire concepts

echo Deleting all changes (i.e. concept_id > 2000000000) to concept, concept_relationship, concept_class, domain, relationship, and vocabulary

psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -f %~dp0/refreshDev_modified.sql

del %~dp0/refreshDev_modified.sql
