## PhirstPhish

![image](./ascii.png)


### "If you only get one.."

#### Overview

This is a proof-of-concept script kit to assist in device code phishing during Azure/O365 penetration tests. This tool was made to solve one problem - If you only get one chance, and then kicked out immediately, what would you hope you could do in that window? This tool will send a device code in one of the email templates, loot that users email and teams, then send an email as that user to whoever we choose. Use your first target to phish your second from a trusted address. It has optional modules for azurehound and some other recon steps. 

We trigger an authentication flow for the graph and request a device code that is used to sign in. This will give us an access token, and our refresh token. The refresh token allows us to request new access tokens for various other Microsoft services. By refreshing new access tokens for Azure Core Management, MSTeams, Outlook, etc, we're able to move from service to service and pillage what we need without signing in multiple times on multiple sites. This allows for repid exfiltration of data from multiple avenues quicker than an analyst can triage any forthcoming alert. By minting an Outlook token, we can use the account to send emails and control the users mailbox.   

Script will check your OS (Windows or Linux) and install the required modules and Azurehound binary needed for post-exploitation activity automatically. That said, this may be buggy on linux, I haven't put it through it's paces there.

#### Usage

Use a -very- important project manager as your initial access vector, use their organization account to run azurehound to map the tenant and send a send a link internally to a payload hosted elsewhere. Installs requirements, runs azurehound module. You won't need them every time, but is a good way to start.

The variable firstuser is the one you want to hijack, targetUser is the eventual target you hope to reach. Template will be sent first in the background, if the user approves, the message passed here will be emailed to them as the first victim.

```powershell
$targetUser = "helpdesk@corpomax.com"
$firstUser = "ClickamusMaximus@corpomax.com"
$messageContent = "Hey guys, <p> the client is asking us to install an addin, something to do with this 'period net' framework and PDFs. Can you take a look and see if we can get it installed? Thy're really breathing down our necks https://pdfutil.azurewebsites.net/addin </p> <p> Thanks guys you're the unsung heroes of CorpoMax, they should be paying you more! </p> <p> Sincerely Yours.</p>"
$subject = "Software for Project Management"
$template = "bluebeam" # or chatgpt, or one of the secret ones 

.\wrapper.ps1 -targetUser $targetUser -firstUser $firstUser -messageContent $messageContent -subject $subject -template $template -azurehound -install
```

Same scenario, but quicker with no installation or Azurehound. 

```powershell
$targetUser = "helpdesk@corpomax.com"
$firstUser = "ClickamusMaximus@corpomax.com"
$messageContent = "Hey guys, <p> the client is asking us to install an addin, something to do with this 'period net' framework and PDFs. Can you take a look and see if we can get it installed? Thy're really breathing down our necks https://pdfutil.azurewebsites.net/addin </p> <p> Thanks guys you're the unsung heroes of CorpoMax, they should be paying you more! </p> <p> Sincerely Yours.</p>"
$subject = "Software for Project Management"
$template = "bluebeam"

.\wrapper.ps1 -targetUser $targetUser -firstUser $firstUser -messageContent $messageContent -subject $subject -template $template
```


#### Phase 1 - Recon
If modules are specified, once you receive an access token, the script will automatically perform requested recon of tenant, user and groups using AADInternals or Azurehound. Can generate a list of users with detailed information (SIDs, valid sessions, phone number, identities) is exported and useable user list for the spreader function is generated. Groups, users, internal recon, etc output to json in the same directory as the script.

![image](https://github.com/MelloSec/PhirstPhish/assets/65114647/01e9fd43-b20f-48c2-a8b3-9fdc1b5ae6ad)

![image](https://github.com/MelloSec/PhirstPhish/assets/65114647/83a3398c-bf41-47e3-bfa6-e480bddd0fc2)

Using the latest version of Azurehound for your platform, the Azure tenant will be mapped and output to a format you can load into Neo4j for graphing attack paths. This will show you what the newly compromised account has access to and possible ways you can escalate your privileges across the tenant to gain Global Administrator / whatever you desire.

![image](https://github.com/MelloSec/PhirstPhish/assets/65114647/ec598ff5-e82d-4a36-acfb-f887e9b18b55)


#### Phase 2 - Loot
It will dump the compromised users last 200 emails from their inbox, dump all their teams messages, and set their status to 'Gone Phishin'" by default. A user list is generated for further phishing attacks, as well as groups, insider recon, etc, in the working directory of the script. 

<b><u>WARNING:</u></b> Just to re-iterate that last bit.. this will export a lot of sensitive information to the folder you run this from, as that is it's intended purpose. Please clean up your workspace / don't commit the loot to main 


#### Phase 3 - Spread
Specifying "-targetUser" and "-messageContent" will let you pass an email address and phishing pretext to use the compromised account as an internal relay and attempt to move laterally or capitalize on a trusted relationship with an external third party.


#### Extras

V2 - Included the V2 fork of TokenTactics in the repo, just so you know it exists. It has additional features but at the time I made this tool they weren't playing nice and it wasn't worth trying to make it work. I think that's mostly fixed, if you want to try this script with V2, modify PhirstPhish.ps1 and insert the URL to the V2 repo https://github.com/f-bader/TokenTacticsV2 and try it? Shouldn't take much to make that work, but will give you access to the extended Continus Access Evaluation tokens, if ya nasty: https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-continuous-access-evaluation

RoadTools.ps1 - proof of concept that uses TokenTactics to generate a token for RoadTools which will gather conditional access policy info and register a device that could bypass Conditonal Access. As is, play with it, make it your own.


#### Acknowledgements 

Huge thanks to Bobby Cook https://github.com/boku7 and Beaux Bullock https://github.com/dafthack for all the amazing Azure/O365 pentesting resources and classes that got me started 

Shout-out to Steve Borosh https://github.com/rvrsh3ll for the amazing TokenTactics module used in Refreshing tokens and certain post-ex activites here, picking apart your code was hugely helpful in understanding this stuff.

Shout-out to the venerable Dr Nestori Syynimaa (@DrAzureAD), too, for laying all the groundwork with AADInternals https://github.com/Gerenios/AADInternals, used here extensively. Hell of a toolbox and his blog is like a free AzureAD pentesting e-book.

PRs welcome!