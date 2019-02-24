# Nightscout Reporter

A web app based on AngularDart to create PDF documents from nightscout data.

It uses the api from cgm-remote-monitor to access the nightscout data and 
creates some PDFs for handing out to diabetes doctors or coaches.  

## Local Installation
There may be better procedures, but lacking any knowledge of dart or angular, this is how I proceeded:

Nightscout Reporter needs [AngularDart](https://webdev.dartlang.org/angular).
After [installing dart](https://webdev.dartlang.org/guides/get-started#2-install-dart), I continued from the nightscout=reporter directory:
* `pub get`
* `pub global activate webdev`
* `webdev build`    
* `pub upgrade`
*  now point the browser at the local starting file located at `build/index.html`

For some strange reason, Chromium works well on the remote nightscout-reporter site, but not on the local file.
