@ECHO OFF

goto:main

:promptyn
    set /P c=%~1
    if /I %c% == y set promptynResult=1
    if /I %c% == n set promptynResult=0
EXIT /B 0

:resetDatas
    call:promptyn "Do you want to reset ssl folder? (y/n)"
    if %promptynResult% == 1 (
        RMDIR /S /Q "datas\ssl"
    )

    call:promptyn "Do you want to reset templates folder? (y/n)"
    if %promptynResult% == 1 (
        RMDIR /S /Q "datas\templates"
        xcopy /E /K /H /I "src\templates" "datas\templates"
        RMDIR /S /Q "datas\templates\config"
    )

    call:promptyn "Do you want to reset database? (y/n)"
    if %promptynResult% == 1 (
        RMDIR /S /Q "datas\database"
    )

    call:promptyn "Do you want to reset config.json? (y/n)"
    if %promptynResult% == 1 (
        copy "src\templates\config\config.json" "config.json"
    )
EXIT /B 0


:buildImage
    docker rmi $1
    docker system prune -af
    docker build -t $1 ./src --no-cache
EXIT /B 0

:main
    call:resetDatas
    call:buildImage
EXIT /B 0