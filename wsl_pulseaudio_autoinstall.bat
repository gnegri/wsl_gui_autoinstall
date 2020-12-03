@ECHO OFF

set WSLENV=%WSLENV%:WINTMP:WINAPP
set WINTMP=%TMP%
set LINUXTMP='$(wslpath -u \"$WINTMP\")'
set WINAPP=%AppData%
set LINUXAPP='$(wslpath -u \"$WINAPP\")'

ECHO --- Running Linux installation.  You will be prompted for your Ubuntu user's password:
REM One big long command to be absolutely sure we're not prompted for a password repeatedly

echo yes ^| add-apt-repository ppa:aseering/wsl-pulseaudio > "%TMP%\script.sh"
echo apt-get update >> "%TMP%\script.sh"
echo apt-get -y install pulseaudio unzip >> "%TMP%\script.sh"
echo sed -i 's/; default-server =.*/default-server = 127.0.0.1/' /etc/pulse/client.conf >> "%TMP%\script.sh"
echo sed -i "s$<listen>.*</listen>$<listen>tcp:host=localhost,port=0</listen>$" /etc/dbus-1/session.conf >> "%TMP%\script.sh"
C:\Windows\System32\bash.exe -c "chmod +x '%LINUXTMP%/script.sh' ; tr -d $'\r' < '%LINUXTMP%/script.sh' | tee '%LINUXTMP%/script_clean.sh'; sudo '%LINUXTMP%/script_clean.sh'"

ECHO --- Downloading PulseAudio
C:\Windows\System32\bash.exe -xc "wget -cO '%LINUXTMP%/pulseaudio.zip' 'http://bosmans.ch/pulseaudio/pulseaudio-1.1.zip'"

ECHO --- Extracting PulseAudio
md "%TMP%\pulseaudio"
C:\Windows\System32\bash.exe -xc "unzip -o '%LINUXTMP%/pulseaudio.zip' -d '%LINUXTMP%/pulseaudio'"

ECHO --- Installing PulseAudio
xcopy /e "%TMP%\pulseaudio" "%AppData%\PulseAudio"

REM Recomended/required settings
echo load-module module-native-protocol-tcp auth-ip-acl=172.16.0.0/12 auth-anonymous=1 >> "%AppData%\PulseAudio\etc\pulse\default.pa"
echo load-module module-esound-protocol-tcp auth-ip-acl=172.16.0.0/12 auth-anonymous=1 >> "%AppData%\PulseAudio\etc\pulse\default.pa"
C:\Windows\System32\bash.exe -xc "sed -i 's/\(load\-module\ module\-waveout\ .*\)/\1 record=0/' '%LINUXAPP%/PulseAudio/etc/pulse/default.pa'"
C:\Windows\System32\bash.exe -xc "sed -i 's/; exit-idle-time =.*/exit-idle-time = -1/' '%LINUXAPP%/PulseAudio/etc/pulse/daemon.conf'"

ECHO --- Setting PulseAudio to run at startup
echo set ws=wscript.createobject("wscript.shell") > "%userprofile%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\start_pulseaudio.vbe"
echo ws.run "%AppData%\PulseAudio\bin\pulseaudio.exe --exit-idle-time=-1",0 >> "%userprofile%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\start_pulseaudio.vbe"
C:\Windows\System32\bash.exe -xc "echo 'export PULSE_SERVER=tcp:$(grep -oP 'nameserver \K.*' /etc/resolv.conf);' >> ~/.bashrc"

"%userprofile%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\start_pulseaudio.vbe"
ECHO When prompted, allow 'pulseaudio' access to your networks. It needs access.

ECHO All Done
PAUSE
