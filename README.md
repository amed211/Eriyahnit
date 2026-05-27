# Eriyahnit
Eriyahnit is a fileless initial access and persistence kit. It registers itself on the system as a scheduled task, and when executed, all operations occur in memory. Even if detected by antivirus solutions, it cannot be quarantined without manual intervention

Eriyahnit is used to establish persistence on a device, bypass security mechanisms, and obtain full system control. However, Eriyahnit has one major limitation: for the program to execute successfully, it must either bypass User Account Control (UAC) or run on a system where UAC is disabled. Of course, this only applies to the initial access stage once a device has been compromised by Eriyahnit, UAC no longer provides meaningful protection.

Eriyahnit’s greatest advantage is that even if it is detected, it cannot be quarantined, because technically there is no malicious file to isolate. All operations are executed through PowerShell and occur in memory.

If your device has been infected with Eriyahnit, there is no need to panic. Eriyahnit was released strictly for educational and awareness purposes, and potential misuse has been taken into consideration. Using the AntiEriyahnit utility distributed alongside it, you can easily remove Eriyahnit from your device without requiring any technical knowledge
