# PDFCrack-GUI
Provides desktop based Linux users with a friendly GUI to break password protected PDF files

General Information
===================

PDF Crack GUI is an open-source GUI overlay for the popular and highly regarded 'pdfcrack' (http://sourceforge.net/projects/pdfcrack/) by Henning Noren.

SHA-1 hashes : 
76d31f51a205e93adacf08564f3180e106304494 : pdfcrack (backend tool)
7c538124c850bda016471f7feb0c8492466696f0 : pdfcrack-gui (GUI tool)

It comes precompiled as a Linux 64-bit binary, only. Both were compiled on Linux Mint 19.3.

This project in no way aims to replace pdfcrack. The gui is 100% reliant on pdfcrack itself and is simply a friendly front end to it.

Just double click pdfcrack-gui to launch, or to execute from the command line :

> ./pdfcrack-gui

If the program does not run after download, be sure to make both pdfcrack and pdfcrackgui are present in the same folder, and executable :

>chmod +x *

For a selection of downloadable wordlists, visit https://wiki.skullsecurity.org/Passwords

Release History
===============

v1.2
====

v1.2 Released May 28th 2020
Updated to include pdfcrack v0.19 which was released 24/04/20 (https://sourceforge.net/projects/pdfcrack/files/pdfcrack/)
Start and end timings moved to the activity log to reduce GUI real-estate usage and to enable saving.
Display of dates converted to the US convention of YYYY/MM/DD HH:MM:SS throughout. 
Added -o switch : Work with the ownerpassword
Added -u switch : Work with the userpassword
Added -p switch : Give userpassword to speed up breaking ownerpassword (implies -o)
Added -s switch : Try permutating the passwords (currently only supports switching first character to uppercase)
Results automatically saved to a log file in the folder where the program is being executed. 
Added Release History.txt
Added project to GitHub

TODO : Add ability to choose folder and work on files in bulk

v1.1
====

v1.1 released July 5th 2017:

1) User can now abort a decryption attempt and have the progress saved to 'savedstate.sav', as with pdfcrack itself.

2) Timers added

3) If the program is closed, any resources and running processes are now freed

4) Updated to include pdfcrack v0.16

v1.0
===
v1.0 released 10th May 2014. 
