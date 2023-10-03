:: Connect to database via config file
@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Execute easyload.py to generate the gis_fragment.csv files

echo Generating gis_*_fragment.csv files

python %~dp0/easyload.py

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
	pause
	exit
) else (
    :: Read the configuration file and set the variables
    for /f "usebackq tokens=1,* delims==" %%a in (!CONFIG_FILE!) do (
        set "%%a=%%b"
    )
)

:: Append changes to concept, concept_relationship, concept_class, domain, and vocabulary

echo Appending changes to concept, concept_relationship, concept_class, domain, and vocabulary

psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -f %~dp0/easyload.sql

:: Generate concept_ancestor table

echo Generating concept_ancestor table

psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -f %~dp0/concept_ancestor.sql

echo Done

pause