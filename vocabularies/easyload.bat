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

:: Change the schema name in the easyload script files

echo Changing the schema name in the easyload script files

set "searchString=@devVocabSchema"
set "replaceString=!VOCAB_SCHEMA!"

:: Define the list of files to process
set "filesToProcess=easyload.py easyload.sql concept_ancestor.sql"

for %%f in (%filesToProcess%) do (
    set "inputFile=%~dp0/%%f"
    set "outputFile=%~dp0/%%~nf_modified%%~xf"
    
    (for /f "delims=" %%a in ('type "!inputFile!"') do (
        set "line=%%a"
        set "modifiedLine=!line:@absolutePath=%~dp0!"
        set "modifiedLine=!modifiedLine:%searchString%=%replaceString%!"
        echo !modifiedLine!
    )) > "!outputFile!"
)

:: Execute easyload.py to generate the gis_fragment.csv files

echo Generating gis_*_fragment.csv files

python %~dp0/easyload_modified.py

:: Append changes to concept, concept_relationship, concept_class, domain, and vocabulary

echo Appending changes to concept, concept_relationship, concept_class, domain, relationship, and vocabulary

psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -f %~dp0/easyload_modified.sql

:: Generate concept_ancestor table

echo Generating concept_ancestor table

psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -f %~dp0/concept_ancestor_modified.sql

:: Cleaning up temporary files

echo Cleaning up temporary files

del "%~dp0/easyload_modified.sql"
del "%~dp0/easyload_modified.py"
del "%~dp0/concept_ancestor_modified.sql"

del "%~dp0/gis_concept_fragment.csv"
del "%~dp0/gis_concept_relationship_fragment.csv"
del "%~dp0/gis_vocabulary_fragment.csv"
del "%~dp0/gis_domain_fragment.csv"
del "%~dp0/gis_concept_class_fragment.csv"
del "%~dp0/gis_relationship_fragment.csv"

echo Done

pause