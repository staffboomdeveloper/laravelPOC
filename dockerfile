# Imagen base de Windows Server Core 2019
FROM mcr.microsoft.com/windows/servercore:ltsc2019

# Instalar dependencias de Laravel
RUN ["powershell", "Invoke-WebRequest", "https://aka.ms/vs/16/release/vc_redist.x64.exe", "-OutFile", "vc_redist.x64.exe"]
RUN ["cmd", "/S", "/C", "vc_redist.x64.exe", "/install", "/quiet", "/norestart"]
RUN ["powershell", "Invoke-WebRequest", "https://download.microsoft.com/download/1/E/5/1E5F1C0A-0D5B-426A-A603-1798B951DDAE/WebDeploy_amd64_en-US.msi", "-OutFile", "WebDeploy_amd64_en-US.msi"]
RUN ["msiexec", "/i", "WebDeploy_amd64_en-US.msi", "/quiet", "/norestart"]

# Instalar PHP y extensiones necesarias
RUN ["powershell", "Invoke-WebRequest", "https://windows.php.net/downloads/releases/php-7.4.24-nts-Win32-vs16-x64.zip", "-OutFile", "php.zip"]
RUN ["powershell", "Expand-Archive", "php.zip", "-DestinationPath", "C:/php"]
RUN ["powershell", "Copy-Item", "C:/php/php.ini-development", "C:/php/php.ini"]
RUN ["powershell", "Set-ItemProperty", "-Path", "HKLM:/SYSTEM/CurrentControlSet/Services/W3SVC/Parameters/CGI", "-Name", "C:/php/php-cgi.exe", "-Value", ""]

# Instalar Composer
RUN ["powershell", "Invoke-WebRequest", "https://getcomposer.org/installer", "-OutFile", "composer-setup.php"]
RUN ["php", "composer-setup.php"]
RUN ["mv", "composer.phar", "/usr/local/bin/composer"]

# Crear directorio de la aplicación y copiar archivos necesarios
RUN ["mkdir", "C:/app"]
WORKDIR /app
COPY . .

# Instalar dependencias de la aplicación
RUN ["composer", "install", "--no-dev"]

# Exponer puerto 80
EXPOSE 80

# Configurar IIS para ejecutar la aplicación
RUN ["powershell", "Import-Module", "WebAdministration"]
RUN ["powershell", "New-IISSite", "-Name", "laravel", "-PhysicalPath", "C:/app/public", "-BindingInformation", "*:80:"]

# Ejecutar IIS
ENTRYPOINT ["powershell"]
CMD ["Start-Process", "C:/Windows/System32/inetsrv/w3wp.exe", "-ArgumentList", @("-port", "80", "-apppoolname", "DefaultAppPool"), "-NoNewWindow"]
