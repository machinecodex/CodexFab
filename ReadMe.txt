CodexFab
========

1. Description:
===============

CodexFab aims to make it simple for you to add automatic PotionStore licensing support to your Cocoa app.

This project demonstrates the code necessary to generate and validate a CocoaFob license code string. It also provides a 
class, XMDSAKeyGenerator, to wrap the task of generating DSA keys using openssl.

The CodexFab application is designed to generate and validate DSA keys to test your project's implementation of CocoaFob.

CodexFab is based on CocoaFob, an open source project by Gleb Dolgich that implements secure assymetric DSA key generation and validation in Cocoa and Ruby. 

CocoaFob and CodexFab are both designed to work with the PotionStore.
http://github.com/potionfactory/potionstore/tree/master

See the companion LicenseExample project for sample code implementing CocoaFob licensing within a Cocoa app. We have tried to make this as complete a solution as possible, and there is very little work left for you to do. We have outlined the necessary steps in the 
ReadMe file.

See the ReadMe.txt in the CocoaFob group folder for more information on setting up your PotionStore for use with 
CocoaFob.

3. DSA Key Notes:
=================

Never distribute your dsaparam.pem or privkey.pem file, and always obfuscate your pubkey.pem in your code (See XMAppDelegate+Licensing.m for an example).

Credits:
========

This project includes code from the following open source projects:
[1] CocoaFob Copyright 2009 by Gleb Dolgich
http://github.com/gbd/cocoafob/tree/master

License:

CodexFab is Copyright 2009 MachineCodex Software.
CodexFab is released under a Creative Commons Attribution 3.0 License.
http://creativecommons.org/licenses/by/3.0/