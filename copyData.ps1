#v0.2.0-beta
#$ErrorActionPreference = "SilentlyContinue";
#& cmd /c ver | Out-Null

[Console]::outputEncoding = [System.Text.Encoding]::GetEncoding("windows-1251");
#$OutputEncoding = [System.Text.Encoding]::GetEncoding("windows-1251");

$PSDefaultParameterValues['Out-File:Encoding'] = "windows-1251";
#$PSDefaultParameterValues['-Out-File:Encoding'] = "windows-1251";

#Переменная-флаг
$isRight = $false;

#Буква диска, откуда будет копироваться информация
$from = "";
#Буква диска, куда будет копироваться информация
$to = "";

#Требуется ли сохранить папки AppData
#$isAppDataRequired = "";
#Требуется ли сохранить временные файлы
#$isTempFilesRequired = "";

#Функция, проверяющая существует ли диск по переданной букве
function checkDiskExistence {
    param (
        $diskLetter
    )

    if (Test-Path ${diskLetter}) { return($true) }

    return($false);
};

#Функция возвращающая метку диска по переданной букве
function getDiskLabel {
    param (
        $diskLetter
    )

    $label = ([System.IO.DriveInfo]::GetDrives() | ? Name -eq "${diskLetter}").VolumeLabel;

    return("${label} (${diskLetter})");
};

#Функция для сбора информации о дисках: откуда и куда будет копироваться информация
function askFromTo {
    param (
        $question, $from
    )

    $flag = $false;
    $diskLetter = "";

    while ($flag -ne $true) {
        Write-Host $question;

        $diskLetter = Read-Host;

        if ($diskLetter -match "^[a-zA-Z]{1}$") {
            $diskLetter = $diskLetter.ToUpper() + ":\";
        } else {
            Write-Host "Введено неверное значение, попробуйте еще раз." `n;

            continue;
        }

        if ($diskLetter -eq $from) {
            Write-Host "Для копирования данных укажите диск, не являющийся источником!" `n;

            continue;
        }

        $flag = checkDiskExistence($diskLetter);

        if ($flag -ne $true) {
            Write-Host "Диска по указанной букве не найдено, проверьте данные и повторите попытку!" `n;
        }
    }

    return($diskLetter);
};

#функция для сбора дополнительной информации по переданному вопросу
function askAdditionalInfo {
    param(
        $question
    )

    $flag = $false;
    $answer = "";

    while ($flag -ne $true) {
        Write-Host $question;

        $answer = Read-Host;

        $answer = $answer.ToUpper();

        if ($answer -eq "Y" -or $answer -eq "N") {
            $flag = $true;
        } else {
            Write-Host "Введено неверное значение, попробуйте еще раз." `n;
        }
    }

    return($answer);
};

function getSerialNumber {
    return (Get-CIMInstance win32_bios)[0].SerialNumber;
    #return((wmic bios get serialnumber)[2].trim());
};

function Get-Now {
    return Get-Date -UFormat "%Y-%m-%d %T";
};

#Диалог с пользователем. Собираем необходимую информацию перед началом выполнения скрипта.
while ($isRight -ne $true) {
    #Считываем с клавиатуры и проверяем на корректность букву диска, с которого необходимо скопировать данные
    $from = askFromTo("Укажите букву диска, с которого необходимо скопировать данные:");

    #Считываем с клавиатуры и проверяем на корректность букву диска, на который необходимо скопировать данные
    $to = askFromTo "Укажите букву диска, на который будут скопированы данные:" $from;

    #Спрашиваем у пользователя необходимо ли сохранить папки AppData и проверяем ввод на корректность
    #$isAppDataRequired = askAdditionalInfo("Сохранить папки AppData? Y - да, N - нет:");

    #Спрашиваем у пользователя необходимо ли сохранить temp-файлы и проверяем ввод на корректность
    #$isTempFilesRequired = askAdditionalInfo("Желаете ли сохранить временные (*.temp) файлы пользователей при копировании? Y - да, N - нет:");

    #Выводим пользователю все введенные ранее данные и спрашиваем все ли корректно
    while ($isRight -ne $true) {
        Write-Host `n;
        Write-Host "Вы ввели следующие данные:";
        Write-Host "Диск, с которого необходимо скопировать данные: $(getDiskLabel($from))";
        Write-Host "Диск, куда нужно скопировать данные: $(getDiskLabel($to))";
        #Write-Host "Сохранить папки AppData? - ${isAppDataRequired}";
        #Write-Host "Сохранить временные (*.temp) файлы? - ${isTempFilesRequired}" `n;
        Write-Host "Если все верно - Y, для внесения изменений - N:";

        $isRight = Read-Host;

        $isRight = $isRight.ToUpper();

        if ($isRight -eq "Y") {
            $isRight = $true;
        } elseif ($isRight -eq "N") {
            $isRight = $false;

            break;
        } else {
            Write-Host "Введено неверное значение, попробуйте еще раз." `n;
        }
    }
}

#$destinationFolderPath = "$to$(getSerialNumber)";
$destinationFolderName = (Get-Now) -replace ':', ''; #Имя папки назначения: текущая дата со временем, между цифрами времени удален символ :
$destinationFolderPath = "$to$destinationFolderName";
$pathToLogFile = "$destinationFolderPath\logs.txt";

function writeLog {
    param (
        $text, $pathToLogFile
    )

    Write-Host "[$(Get-Now)]: $text";

    "[$(Get-Now)]: $text" >> $pathToLogFile;
};

function makeLogFile {
    param (
        $pathToLogFile
    )

    try {
        New-Item -Path "$pathToLogFile" -ItemType File;

        writeLog -text "init log file" -pathToLogFile $pathToLogFile;
    } catch {
        Write-Host "Не удалось создать файл логов.";
    }
};

function makeDestinationFolder {
    param (
        $to, $destinationFolderPath, $pathToLogFile
    )

    try {
        New-Item -Path "$destinationFolderPath" -ItemType Directory;

        makeLogFile($pathToLogFile);

        writeLog -text "Создана папка назначения $destinationFolderPath" -pathToLogFile $pathToLogFile;
    } catch {
        Write-Host "Не удалось создать папку назначения!";

        pause;

        exit 1;
    }
};

makeDestinationFolder -to $to -destinationFolderPath $destinationFolderPath -pathToLogFile $pathToLogFile;

function copyObject {
    param (
        $copiedObjectName, $pathToLogFile, $excludeDir, $excludeFiles, $from, $to
    )

    writeLog -text "Начато копирование ${copiedObjectName}" -pathToLogFile $pathToLogFile;

    try {
        robocopy "${from}" "$to" /XD $excludeDir /XF $excludeFiles /s /mir /R:2 /W:10 /unilog+:$pathToLogFile /tee /XJD;

        writeLog -text "Копирование ${copiedObjectName} успешно завершено" -pathToLogFile $pathToLogFile; 
    } catch {
        writeLog -text "Что-то пошло не так при копировании ${copiedObjectName}. Проверьте результат." -pathToLogFile $pathToLogFile;
    }
};

try {
    #Записываем имя компьютера в лог
    #writeLog -text "Имя компьютера: $(gc env:computername)" -pathToLogFile $pathToLogFile

    #Копируем стартовое меню (список программ)
    copyObject -copiedObjectName "СТАРТОВОЕ МЕНЮ" -pathToLogFile $pathToLogFile -excludeDir "" -excludeFiles @("desktop.ini", "Immersive Control Panel.lnk") -from "${from}ProgramData\Microsoft\Windows\Start Menu\Programs" -to "$destinationFolderPath\StartMenu";

    #Перечень исключаемых из копирования папок
    $excludeDir = @(
        "AppData",
        "Application Data",
        "Contacts",
        "Cookies",
        "IntelGraphicsProfiles",
        "Local Settings",
        "LtcJobs",
        "NetHood",
        "PrintHood",
        "Recent",
        "SendTo",
        "Searches",
        "главное меню",
        #"Мои документы", #Пришлось исключить, так как у некоторых пользователей есть личный папки с таким названием
        "Мои видеозаписи",
        "мои рисунки",
        "Моя музыка",
        "Music",
        "MicrosoftEdgeBackups",
        "Saved Games",
        "Links",
        "Шаблоны",
        "All Users",
        "*Default*",
        "Default User",
        "Все пользователи",
        "*LocAdmin*",
        "*ksnproxy*",
        "*aaklyuev2*",
        "*_wa*",
        "*_adm*",
        "*$*",
        "*cache*",
        "*Cache*",
        "*Temp*",
        "*temp*",
        "OneDrive",
        "rzn-present"
    );

    #Перечень исключаемых из копирования файлов
    $excludeFiles = @(
        "ntuser*",
        "Ntuser*",
        "NTUSER*",
        "*.tmp",
        "*.temp",
        "~*",
        "*.bak",
        "*.ini",
        "*cache*",
        "*Cache*"
    );

    #Копируем папки пользователей
    copyObject -copiedObjectName "ПАПКА USERS" -pathToLogFile $pathToLogFile -excludeDir $excludeDir -excludeFiles $excludeFiles -from "${from}Users" -to "$destinationFolderPath\Users";
} catch {
    Write-Host "В процессе выполнения скрипта произошла ошибка, попробуйте запустить скрипт заново или выполните копирование вручную.";
}

pause;

###
#
# v0.2.0
# - исправлено зацикливание скрипта при копировании битых / недоступных файлов (установлено ограничение в 2 попытки)
# - подправлен перечень исключаемых папок в excludeDir
#
###

###
#
# v0.3.0
# - исправлена проблема в папке с именем "Мои документы".
# Суть в том, что в папке профиля каждого пользователя есть стандартная скрытая папка-ярлык (символическая ссылка) "Мои документы",
# которая ссылается на стандартную папку "Documents" (Документы).
# Раньше папка-ярлык "Мои документы" была исключена из копирования, но так как пользователи иногда сами создают свои папки "Мои документы", исключать это название из копирования нельзя.
# После удаления "Мои документы" из исключений, скрипт стал копировать папку Documents 2 раза, то есть происходит дублирование информации, трата дискового пространства и времени.
# Происходит это, так как папка-ярлык "Мои документы" ссылается на Documents, что приводит к задвоенному копированию.
# Для выхода из этой ситуации чтобы избежать задвоенного копирования, но при этом не добавлять название "Мои документы" в исключения,
# так как у пользователей могут быть личные папки с такими названиями к robocopy добавлен параметр /XJD
#
###

#TODO:
#
# - общий прогресс бар для robocopy, чтобы знать, сколько примерно будет занимать копирование по времени (?)
# - добавить в исключения стандартные вложенные папки, если они не содержат нестандартных файлов (?)
#
#TODO: сделать функцию для копирования всех папок пользователя в корне диска-источника кром стандартных (Users, Program Files, etc...)
#
#
#TODO: *также сделать скрипт для копирования уже на новый диск/ОС данных из папки serialNumber\ в C:\temp\serialNumber\
#
#
