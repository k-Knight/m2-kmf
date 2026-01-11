# Magicka 2 Mods

To install the mods, run the installer and give it the path to the Magicka 2 root directory *(that is where `data` and `engine` folders are located)*.

So far only Windows is supported.


### >>> <a href="https://github.com/k-Knight/m2-kmf/raw/master/installer.exe">DOWNLOAD</a> <<<

<br><br>
## I get virus warnings!
Those are false positives; here is why that happens:

- The loader script is here for ***legacy reasons*** and will be deleted in the ***near future***.

- The loader script is obfuscated so people cannot get tier 2 access without completing challenges.

- The only thing the loader script does is check the Steam user ID locally (it does not send or record anything) to see if the user has tier 2 access or whether to activate extended functionality; nothing binary gets decoded.

- I have written the installer myself because I wanted to, and it has to scan part of your system to find the Magicka 2 installation directory (scanning is very minimal, since I try to do it in a smart way; results are not sent anywhere), and after installation it deletes zone identifier streams so users will not have warnings when trying to launch the executables.

- The only logging that is being done is done locally, so you can send me crash logs if you want to (I do not send them automatically) and for debugging purposes (it is not done when you do not have the debugger running that I do not distribute with mods).

- I do not do DLL injection; the attacher is there to basically attach to the debugger. I modify game files to make the games load needed DLLs themselves.

- I have hotkey functions, so I have to listen to inputs, but you can check that no logging occurs.

- Since I support gamepad hotkeys, I have to listen to it too, but I cannot do it as a child process of Magicka 2; as such, I have to use Windows Scheduler or tricks to launch an unrelated process to Magicka 2.

- Detours are only used for debugging and crash logging.

## Notes

- Usually windows system detects utility files as viruses, this is a false positive, probably best course of action is to add `Magicka 2/engine` folder to antivirus exclusions.

<br><br><br><br><br>
in you are interested here is <a href="https://github.com/k-Knight/m2-kmf/commits">changelog</a>, kinda ...
