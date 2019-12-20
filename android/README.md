## NOTES

These scripts allows to automate several browsers (Brave, Chrome, Opera, and Firefox) across the following devices:": Samsung J7DUO, LG LM-X210, Samsung SMJ337A, and Motorola SM-J337A. Each device and browser can be automated to perform accurate battery, CPU, and bandwdith tests. This implies cleaning a device (disable notifications, set airplane mode, close background apps, set a target screen brightness value), and the browser under test (cache and config files, potentially automate the browser onboarding process). 

The automation consists in opening a series of URLs in sequence, i.e., each in a new tab. We currently support two simple automation: simple load (load a page for a duration T), and interact (load a page for a duration T and interact with the page for a duration T1). The sequence of URLs to be tested is defined in the file `workload.txt` where the first field is a workload identifier, the second field refers to which test this workload should be used with, and the third field is a comma-separated list of URLs to be loaded. 

Performance metrics like Page Load Time and SpeedIndex  are collected via separate measurements realized using lighthouse, similarly to as done for the desktop experiments. We ise ADB over USB — since no power measurements are collected — and we forward the the developer tool port used at the device (9222) to the Linux machine where lighthouse runs. 

These scripts are designed to work with Batterylab (https://batterylab.dev/), a testbed designed to enable remote power measurements on mobile devices. We invite potential users to contact us at varvello-at-brave-dot-com for information on how to access the platform and run the above scripts. 

