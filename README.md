## PhirstPhish

### "If you only get one.."

#### Overview

This is a script kit to assist in device code phishing during Azure/O365 penetration tests. This tool was made to solve one problem - If you only get one chance, and then kicked out immediately, what would you hope you could get?

We trigger an authentication flow for the graph and request a device code that is used to sign in. This will give us an access token, and our refresh token. The refresh token allows us to request new access tokens for various other Microsoft services. By refreshing new access tokens for Azure Core Management, MSTeams, Outlook, etc, we're able to move from service to service and pillage what we need without signing in multiple times on multiple sites. This allows for repid exfiltration of data from multiple avenues quicker than an analyst can triage any forthcoming alert. By minting an Outlook token, we can use the account to send emails and control the users mailbox.   

It can take a $Token as a parameter if you already have an access token, otherwise, it will generate a device code that you or a targeted user can use to bypass Multi-Factor Authentication from a signed in account.

Script will check your OS (Windows or Linux) and install the required modules and Azurehound binary needed for post-exploitation activity automatically. 

#### Phase 1 - Recon
Once you receive an access token, the script will automatically perform full recon of tenant, user and groups using AADInternals and Azurehound. First, a list of users with detailed information (SIDs, valid sessions, phone number, identities) is exported and useable user list for the spreader function is generated. Groups, users, internal recon, etc output to json in the same directory as the script.

![image](https://github.com/MelloSec/PhirstPhish/assets/65114647/01e9fd43-b20f-48c2-a8b3-9fdc1b5ae6ad)

![image](https://github.com/MelloSec/PhirstPhish/assets/65114647/83a3398c-bf41-47e3-bfa6-e480bddd0fc2)

Using the latest version of Azurehound for your platform, the Azure tenant will be mapped and output to a format you can load into Neo4j for graphing attack paths. This will show you what the newly compromised account has access to and possible ways you can escalate your privileges across the tenant to gain Global Administrator / whatever you desire.

![image](https://github.com/MelloSec/PhirstPhish/assets/65114647/ec598ff5-e82d-4a36-acfb-f887e9b18b55)


#### Phase 2 - Loot
It will dump the compromised users last 200 emails from their inbox, dump all their teams messages, and set their status to 'Gone Phishin'" by default. A user list is generated for further phishing attacks, as well as groups, insider recon, etc, in the working directory of the script. 

<b><u>WARNING:</u></b> Just to re-iterate that last bit.. this will export a lot of sensitive information to the folder you run this from, as that is it's intended purpose. Please clean up your workspace / don't commit the loot to main 


#### Phase 3 - Spread (optional)
Specifying "-targetUser" and "-messageContent" will let you pass an email address and phishing pretext to use the compromised account as an internal relay and attempt to move laterally or capitalize on a trusted relationship with an external third party. If you instead pass the word "all" for -targetUser you will be warned. If you proceed, your message will be sent to every user in the tenant using the compromised account.


#### Extras

V2 - Included the V2 fork of TokenTactics in the repo, it has additional features but at the time I made this tool they weren't playing nice and it wasn't worth trying to make it work. I think that's mostly fixed, if you want to try this script with V2, modify PhirstPhish.ps1 and insert the URL to the V2 repo https://github.com/f-bader/TokenTacticsV2 and try it? Shouldn't take much to make that work, but will give you access to the extended Continus Access Evaluation tokens, if ya nasty: https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-continuous-access-evaluation

RoadTools.ps1 - proof of concept that uses TokenTactics to generate a token for RoadTools which will gather conditional access policy info and register a device that could bypass Conditonal Access. As is, play with it, make it your own.

Templates - Two Outlook template files for chatgpt and bluebeam "activation code" lures

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

#### Next.ps1 / Second.ps1

Can use Next.ps1 to take in the code, replace the value in a template and send the first email, using Second.ps1, ironically. You need the code from PhirstPhish, you feed it into the Next.ps1 script, which replaces the value, and uses second.ps1, a stripped down version of phirst w/ no loot functions.

### Quick Steps

#### Terminal One - Create insider lure device code for second step, this will loot user, run azurehound and send the internal phish
```powershell
# First Step, target privileged account with payload link this will go out as an internal user
$url = "https://invoicecity.azurewebsites.net/coolplans" 
$messageContent = "Hey, <p></p> this company used photos of some of our projects for their yearly calendar, they said 'hope you don't mind!! We wanted to give you final say and make sure you are happy with them before we go to print.' Can you believe that? <p></p> $url <p></p> Take a look and let me know before the boss gets involved. Thank you!"
$targetUser = "it@corpomax.com"
$subject = "'FW: Photos of your company's work used in our upcoming 2024 Calendar'"

.\PhirstPhish.ps1 -targetUser $targetUser -messageContent $messageContent -subject $subject
```

#### Terminal Two - Run Next.ps1 and enter the code from the first step, then use YOUR phishing account to authenticate and send from template
#### Replaces code in Bluebeam template and sends the initial email
#### If you want to use the other template, modify Next.ps1 and Replace.ps1 and open a Pull Request please :)

```powershell
.\Next.ps1 -firstUser scrub@copromax.com -subject "A DocuCloud user has shared a file with you"
```
OR simply to pick a random subject included. 

NOTE: You should replace these subjects from the string array in Next.ps1, they are meant to serve as indicators if you're lazy. Your subjects will say Adobe Cloud and have bizarre requests, you have been warned, down here all quiet like.
```
.\Next.ps1
```


#### Acknowledgements 

Huge thanks to Bobby Cook https://github.com/boku7 and Beaux Bullock https://github.com/dafthack for all the amazing Azure/O365 pentesting resources and classes that got me started 

Shout-out to Steve Borosh https://github.com/rvrsh3ll for the amazing TokenTactics module used in Refreshing tokens and certain post-ex activites here, picking apart your code was hugely helpful in understanding this stuff.

Shout-out to the venerable Dr Nestori Syynimaa (@DrAzureAD), too, for laying all the groundwork with AADInternals https://github.com/Gerenios/AADInternals, used here extensively. Hell of a toolbox and his blog is like a free AzureAD pentesting e-book.

PRs welcome!

