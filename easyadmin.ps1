#Easy admin
 clear
function new_aduser(){
    
    #Создание пользователя АД
    New-ADUser -DisplayName:"$last_name $first_name" `
               -GivenName:"$first_name" `
               -Initials:$null `
               -Name:"$last_name $first_name" `
               -Path:"OU=Сотрудники,OU=but,DC=domen,DC=msk" `
               -AccountPassword $secure_password `
               -SamAccountName:"$login_user" `
               -Server:"but.domen.msk" `
               -Surname:"$last_name" `
               -Type:"user" `
               -UserPrincipalName:"$login_user@domen.msk" `
               -Enable $true `
               -PasswordNeverExpires:$true `
               -ChangePasswordAtLogon:$false

}

function new_mailuser(){

    #Создание почты
    $PfaContent = Invoke-WebRequest -uri https://pfa.testsite.com/login.php -SessionVariable pfa

    $formLogin = $PfaContent.Forms["frmLogin"]
    $formLogin.Fields["fUsername"]=$adminl+"@testsite.com"
    $formLogin.Fields["fPassword"]=$adminp

    $auth1 = Invoke-WebRequest -uri https://pfa.testsite.com/login.php -WebSession $pfa -Method Post -Body $formLogin.Fields


    $PfaMail = Invoke-WebRequest -uri "https://pfa.testsite.com/edit.php?table=mailbox&domain=testsite.com" -WebSession $pfa

    $PfaMailForm = $PfaMail.Forms[0]
    $PfaMailForm.Fields["value[local_part]"]=$login_user
    $PfaMailForm.Fields["value[domain]"]="testsite.com"
    $PfaMailForm.Fields["value[password]"]=$password_user
    $PfaMailForm.Fields["value[password2]"]=$password_user
    $PfaMailForm.Fields["value[name]"]=$login_user
    #$PfaMail.Forms[0].Fields

    $addMail = Invoke-WebRequest -uri https://pfa.testsite.com/edit.php?table=mailbox -WebSession $pfa -Method Post -Body $PfaMailForm.Fields
}

function new_mailuser2(){

    #Создание почты
    $PfaContent = Invoke-WebRequest -uri https://pfa.testsite2.ru/login.php -SessionVariable pfa2

    $formLogin = $PfaContent.Forms["frmLogin"]
    $formLogin.Fields["fUsername"]=$adminl+"@testsite2.ru"
    $formLogin.Fields["fPassword"]=$adminp

    $auth1 = Invoke-WebRequest -uri https://pfa.testsite2.ru/login.php -WebSession $pfa2 -Method Post -Body $formLogin.Fields


    $PfaMail = Invoke-WebRequest -uri "https://pfa.testsite2.ru/edit.php?table=mailbox&domain=testsite2.ru" -WebSession $pfa2

    $PfaMailForm = $PfaMail.Forms[0]
    $PfaMailForm.Fields["value[local_part]"]=$login_user
    $PfaMailForm.Fields["value[domain]"]="testsite2.ru"
    $PfaMailForm.Fields["value[password]"]=$password_user
    $PfaMailForm.Fields["value[password2]"]=$password_user
    $PfaMailForm.Fields["value[name]"]=$login_user
    #$PfaMail.Forms[0].Fields

    $addMail = Invoke-WebRequest -uri https://pfa.testsite2.ru/edit.php?table=mailbox -WebSession $pfa2 -Method Post -Body $PfaMailForm.Fields
}

function new_ldapuser(){
    
    #Создание Ldap user
    $LdapContent = Invoke-WebRequest -uri https://ldap.testsite2.ru/login -SessionVariable ldap

    $formLogin = $LdapContent.Forms[0]
    $formLogin.Fields["user[login]"]=$adminl
    $formLogin.Fields["user[password]"]=$adminp

    $auth2 = Invoke-WebRequest -uri ("https://ldap.testsite2.ru/login") -WebSession $ldap -Method Post -Body $formLogin.Fields

    $adduser = [ordered]@{"user[givenName]" = $first_name; `
                          "user[sn]" = $last_name; `
                          "user[uid]" = $login_user; `
                          "user[cn]" = $login_user; `
                          "user[mail]" = $login_user+"@testsite2.ru"; `
                          "user[description]" = ""; `
                          "user[sshPublicKey]" = ""; `
                          "user[userPassword]" = $password_user;}


    $addUserLdap = Invoke-WebRequest -uri ("https://ldap.testsite2.ru/user/"+$login_user) -Method Post -WebSession $ldap -Body $adduser
}

function new_redmine(){

    $loginredmine = Invoke-WebRequest https://redmine.testsite.com/login -SessionVariable session 

    $loginredmine.Forms[0].Fields["username"]=$adminl
    $loginredmine.Forms[0].Fields["password"]=$adminp

    $authredmine = Invoke-WebRequest -uri ("https://redmine.testsite.com/login") -WebSession $session -Method Post -Body $loginredmine.Forms[0].Fields 

    <#[xml]$xml="<?xml version='1.0' encoding='UTF-8'?>
    <user>
    <login>$login_user</login>
    <firstname>$first_name</firstname>
    <lastname>$last_name</lastname>
    <mail>"+$login_user+"@testsite.com</mail>
    <auth_source_id>1</auth_source_id>
    </user>"#>

    $json = [ordered]@{"user[login]" = $login_user; `
                       "user[firstname]" = $first_name; `
                       "user[lastname]" = $last_name; `
                       "user[mail]" = $login_user+"@testsite2.ru"; `
                       "user[auth_source_id]" = 1; `
                       "send_information" = "1";}

    #Добавляем юзера и xmlим ответ
    [xml]$adduserredmine = Invoke-WebRequest -uri ("https://redmine.testsite.com/users.xml") -WebSession $session -Method Post -Body $json  

    #Парсим Ид юзера, и добавляем в группу All
    $userredmineid = $adduserredmine.user.id
    $xml2="<user_id>$userredmineid</user_id>"

    $addusergroup = Invoke-WebRequest -uri ("https://redmine.testsite.com/groups/246/users.xml") -WebSession $session -Method Post -Body $xml2 -ContentType "application/xml" 

}

function createuser(){

$adminl = 'login'
$adminp = 'pass'

Write-Host "Добро пожаловать в систему Easy admin v0.05"
Write-Host "Убедитесь что вы запустили PowerShell от Администратора"
Write-Host "Введите 1 если хотите создать пользователя"
Write-Host "Введите 2 если хотите выйти, или нажмите Ctrl+C"
$next = Read-Host "Введите цифру"

     if ($next -eq "1") {

         $first_name = Read-Host 'Имя нового пользователя'
         $last_name = Read-Host 'Фамилия нового пользователя'
         $login_user = Read-Host 'Login пользователя (строго на ENG)'
         $password_user = Read-Host 'Pass пользователя (10 знаков в обоих регистрах, минимум 2 цифры)'
         $secure_password = ConvertTo-SecureString $password_user -AsPlainText -Force


         if (Get-AdUser -Filter "SamAccountName -eq '$login_user'") {
         Write-Host "Логин $login_user уже есть, придумайте другой"
         }else{
         Write-Host "Логин $login_user свободен, начинаем создание"   
         new_aduser
         Write-Host "Пользователь создан в AD, начинаем создание PFA"
         Start-Sleep -Seconds 2
         #new_mailuser
         #Write-Host "Пользователь создан в PFA(testsite.com), начинаем создание PFA2(testsite2.ru)"
         #Start-Sleep -Seconds 2
         new_mailuser2
         Write-Host "Пользователь создан в PFA(testsite2.ru), начинаем создание LDAP"
         Start-Sleep -Seconds 2
         new_ldapuser
         Write-Host "Пользователь создан в LDAP, начинаем создание REDMINE"
         Start-Sleep -Seconds 2
         new_redmine
         Write-Host "Пользователь создан в REDMINE, конец, окно зароется через 5 секунд"
         #Write-Host "Пользователь в REDMINE не создан, нужно создать ручками. функция в процессе отладки. конец, окно зароется через 5 секунд"
         Start-Sleep -Seconds 5
         }

     }else{
     break
     }
}

createuser