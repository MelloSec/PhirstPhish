## PhirstPhish

### "If you only get one.."

This is a script to assist in device code phishing during Azure/O365 penetration tests. This tool was made to solve one problem - If you only get one chance, and then kicked out immediately, what would you hope you could get?

It can take a $Token as a parameter if you already have an access token, otherwise, it will generate a device code that you or a targeted user can use to bypass Multi-Factor Authentication from a signed in account.

Script will check your OS and install the required modules and binaries needed for post-exploitation activity automatically. 

Once you receive an access token, the script will automatically perform full recon of tenant, user and groups using AADInternals and Azurehound. Using the latest version of Azurehound, the Azure tenant will be mapped and output to a format you can load into Neo4j for graphing attack paths.

It will dump the compromised users last 200 emails from their inbox, dump all their teams messages, and set their status to 'Gone Phishin'" by default. A user list is generated for further phishing attacks, as well as groups, insider recon, etc, in the working directory of the script. 

<u>WARNING:</u> Just to re-iterate that last bit.. this will export a lot of sensitive information to the folder you run this from, as that was it's intended purpose. Please clean up your workspace / don't commit recon to main 

Specifying "-targetUser" and "-messageContent" will let you pass an email address and phishing pretext to use the compromised account as a relay and attempt to move laterally or capitalize on a trusted relationship with a third party. If you instead pass the word "all" for -targetUser you will be warned. If you proceed, your message will be sent to every user in the tenant using the compromised account.

#### Usage

No additional phishing targets, no access tokens

```powershell
.\PhirstPhish.ps1 
```

No additional phishing targets, using active access token

```powershell
.\PhirstPhish.ps1 -token $Token
```

Internal Phishing - Target additional mailbox with compromised account and a custom message

```powershell
.\PhirstPhish.ps1 -messageContent "Hey, did you see who they're letting go? Check it out https://notices.azurewebsites.net/terminations.pdf" -targetUser accounting@corpomax.com
```

Chaos Phishing - Blast the Whole Tenant using the generated users list and a custom messsage

```powershell
.\PhirstPhish.ps1 -messageContent "Hey, did you see who they're letting go? Check it out https://notices.azurewebsites.net/terminations.pdf" -targetUser all
```


#### Acknowledgements 

Huge thanks to Bobby Cook https://github.com/boku7 and Beaux Bullock https://github.com/dafthack for all the amazing Azure/O365 pentesting resources and classes that got me started 

Shout-out to Steve Borosh https://github.com/rvrsh3ll for the amazing TokenTactics module used in Refreshing tokens and certain post-ex activites here, picking apart your code was hugely helpful in understanding this stuff.

Shout-out to the venerable Dr Nestori Syynimaa (@DrAzureAD), too, for laying all the groundwork with AADInternals https://github.com/Gerenios/AADInternals, used here extensively. Hell of a toolbox and his blog is like a free AzureAD pentesting e-book.

PRs welcome!

