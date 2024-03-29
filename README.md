![image](./ascii.png)

### "If you only get one.."

### Overview
This is a proof-of-concept script kit to assist in device code phishing during Azure/O365 testing. This tool was made to solve one problem - If you only get one chance, and then kicked out immediately, what would you hope you could do in that window? This tool will send a device code in one of the email templates, loot that users email and teams, then send an email as that user to whoever we choose. Use your first target to phish your second from a trusted address. It has optional modules for azurehound and some other recon steps. 

We import TokenTactics and AADInternals, then trigger an authentication flow for the graph and request a device code that is used to sign in. The device code gets replaced in a template and a sign in is prompted for the sending user. This is your pretext. This will give us an access token, and our refresh token. We use our access token with Outlook to send the template to the first user with the codethey need to use. When they enter this code, we get a set of tokens for them. The refresh token allows us to request new access tokens for various other Microsoft services. By refreshing new access tokens for Azure Core Management, MSTeams, Outlook, etc, we're able to move from service to service and pillage what we need without signing in multiple times on multiple sites. This allows for repid exfiltration of data from multiple avenues quicker than an analyst can triage any forthcoming alert. By minting an Outlook token, we can use the new account to send emails to additional targets and control the users mailbox.   

Script will check your OS (Windows or Linux) and install the required modules and Azurehound binary needed for post-exploitation activity automatically. That said, this may be buggy on linux, I haven't put it through it's paces there.

### Usage
You can use a *very* important project manager as your initial access vector, or someone else you'd like to use to map the tenant and send a link internally to a payload hosted elsewhere. Add modules you wish to run as arguments. You won't need Azurehound, etc, every time, but is a good way to start.

The variable $firstUser is the initial one you want to hijack, $targetUser is the eventual target you hope to reach. Template will be sent first in the background, if the user approves, the message passed here will be emailed to them as the first victim.

WARNING: When you get your first bite, SAVE THAT TOKEN LOG. Get the users tokens, and use them for your foothold. You should have a ton of recon, use this info with these tokens and az cli/AzureAD module to make your next moves. The TokenLog gets refreshed every time you run the script. You'll lose them if you arent mindful. There's a couple scripts to help with this. The first one creates a loot folder and backs up the loot files. It clears them for the next run. This loot folder is in the .gitignore but you should get in the habit of clearing after each run (or open a PR and add a switch case for it)

#### Stash loot in the 'loot' folder  
```powershell
.\LootStash.ps1
```

#### Clear all loot from current dir and that folder when you're done
```powershell
.\ClearLoot.ps1
```

#### Install requirements, perform full recon using azuread, AADInternals, and Azurehound modules, attempt to use payroll account to phish a particular accountant
```powershell
$targetUser = "accountant@corpomax.com"
$firstUser = "payroll@corpomax.com"
$messageContent = "Hey guys, <p> do you have any idea what this is? We need to pay it really soon, but we're having trouble accounting for it: https://collections.azurewebsites.net/invoice </p>  <p> Sincerely Yours.</p>"
$subject = "Invoice #3389 for Professional Services "
$template = "adobe" # or chatgpt, bluebeam, bbb, one of the secret ones 

.\wrapper.ps1 -targetUser $targetUser -firstUser $firstUser -messageContent $messageContent -subject $subject -template $template -azurehound -recon -azuread -install
```

#### With Azurehound and No Installation, phish a PM to phish IT for installation of required software
```powershell
$targetUser = "helpdesk@corpomax.com"
$firstUser = "MaxBedroom@corpomax.com"
$messageContent = "Hey guys, <p> our client is asking us to install an addin, something to do with the 'net' framework and PDFs, sounds lame, haha. Can you take a look and see if we can get it installed? Thy're really breathing down our necks https://pdfutil.azurewebsites.net/addin </p> <p> Thanks guys you're the best, they should pay you more! </p> <p> Sincerely Yours.</p>"
$subject = "Software for Project Management"
$template = "bluebeam" # or chatgpt, bluebeam, bbb, one of the secret ones 

.\wrapper.ps1 -targetUser $targetUser -firstUser $firstUser -messageContent $messageContent -subject $subject -template $template -azurehound
```

#### Phishing Only
Similar scenario, but trying  to use a new employee to get to a full administrator user via the 'chatgpt' template, a little quicker with no installation or Azurehound switch 

```powershell
$targetUser = "admin@corpomax.com"
$firstUser = "newemployee@corpomax.com"
$messageContent = "Hey guys, <p> the client is asking us to install an addin, something to do with the 'period net' framework and PDFs, sounds gross, haha. Can you take a look and see if we can get it installed? Thy're really breathing down our necks https://pdfutil.azurewebsites.net/addin </p> <p> Thanks guys you're the unsung heroes of CorpoMax, they should pay you more! </p> <p> Sincerely Yours.</p>"
$subject = "Software for Project Management"
$template = "chatgpt"

.\wrapper.ps1 -targetUser $targetUser -firstUser $firstUser -messageContent $messageContent -subject $subject -template $template
```

### Modules
It's modular, azurehound is one, AADInternals recon, AzureAD enumeration, etc. Recon.ps1, azuread.ps1, azurehound.ps1 are standalones that take access tokens or whatever params needed to do the thing. You can easily rip these out and use them in your own madness, if you want. I tried to make things as flexible as possible. Once you've mapped the tenant, performed recon and built your new lists you may as well as just use it for additional phishing and omit those switches. 

### Templates
Adding a template to this is really easy. Look at the ones here and Replace.ps1, you can see we're looking for and replacing '(((VERIFICATION)))' in the html body. This is the device code that gets generated. If you place one in a new template and add a couple lines of code to Replace.ps1 and Next.ps1 you can use your own.

For replace.ps1, create a new elseif statement for the new template and a template for Chipotle, name the template chipotleHTML.htm and make sure it's creating new version by providing a destination path/filename for what 'replace' creates. I have it creating it in the template folder, it could be a temp folder, you can do whatever you want, I just like to use the repo folder as a workspace. Htm/HTML doesnt matter, consistency does, though. 

```powershell
elseif($template -eq "chipotle"){
    $sourceFile = ".\Templates\chipotleHTML.htm"
    $destinationFile = ".\Templates\chipotle.htm"
}
```

For next.ps1, add a switch and a subject, we need to parse what you want from the command line. If it's 'chipotle', put chipotle, 
```powershell

switch ($template) {
# Add a block with path and subject inside the template switch case
...  
    "chipotle" { 
        $templatePath = ".\Templates\chipotle.htm"
        $subjects = @("Chipotle wants you back.")
        break 
    }
...

}
```

### Phase 1 - Recon
If modules are specified, once you receive an access token, the script will automatically perform requested recon of tenant, user and groups using AADInternals or Azurehound. Can generate a list of users with detailed information (SIDs, valid sessions, phone number, identities) is exported and useable user list for the spreader function is generated. Groups, users, internal recon, etc output to json in the same directory as the script.

![image](https://github.com/MelloSec/PhirstPhish/assets/65114647/01e9fd43-b20f-48c2-a8b3-9fdc1b5ae6ad)

![image](https://github.com/MelloSec/PhirstPhish/assets/65114647/83a3398c-bf41-47e3-bfa6-e480bddd0fc2)

Using the latest version of Azurehound for your platform, the Azure tenant will be mapped and output to a format you can load into Neo4j for graphing attack paths. This will show you what the newly compromised account has access to and possible ways you can escalate your privileges across the tenant to gain Global Administrator / whatever you desire.

![image](https://github.com/MelloSec/PhirstPhish/assets/65114647/ec598ff5-e82d-4a36-acfb-f887e9b18b55)


### Phase 2 - Loot
It will dump the compromised users last 200 emails from their inbox and all their teams messages by default. Optional modules include azureHound, azureAd and Recon. If the azureAd module is used, a user list is generated for further phishing attacks, as well as groups. if the recon module is used, AADInternals authenticated recon modules will run.  

<b><u>WARNING:</u></b> Just to re-iterate that last bit.. this will export a lot of sensitive information to the folder you run this from, as that is it's intended purpose. Please clean up your workspace / don't commit the loot to main 


### Phase 3 - Spread
Specifying "-targetUser" and "-messageContent" will let you pass an email address and phishing pretext to use the compromised account as an internal relay and attempt to move laterally or capitalize on a trusted relationship with an external third party.


### Extras

- **Scripts/TokenTormentor/TokenTormentor.py**  - Device Join using TokenTactics response and roadtx. TorkenTormentor converts $response to complete process

```powershell
$response | ConvertTo-Json -Depth 5 | Out-File -FilePath tokens.json
python .\Scripts\TokenTormentor\TokenTormentor.py .\tokens.json
# Navigate Menu 1, 4 to Join Device using roadtx
```

- **.\Scripts\devicecode2WHFB.py** - Device Join / Windows Hello for Business

Uses the refresh token to request PRT and Join Device, will attempt to create Windows Hello for Business persistence

```powershell
$rt = $response.refresh_token
$user = ""
python .\scripts\devicecode2WHFB.py -r $rt -w -u $user
```

- **TokenTacticsV2** - Included the V2 fork of TokenTactics in the repo, just so you know it exists. It has additional features but at the time I made this tool they weren't playing nice and it wasn't worth trying to make it work. I think that's mostly fixed, if you want to try this script with V2, modify PhirstPhish.ps1 and insert the URL to the V2 repo https://github.com/f-bader/TokenTacticsV2 and try it? Shouldn't take much to make that work, but will give you access to the extended Continus Access Evaluation tokens, if ya nasty: https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-continuous-access-evaluation

<br>

### Acknowledgements 

Big thanks to Bobby Cook https://github.com/boku7 and Beaux Bullock https://github.com/dafthack for all the Azure/O365 pentesting tools, resources and classes.

Shout-out to Steve Borosh https://github.com/rvrsh3ll for the rad TokenTactics module used in Refreshing tokens and certain post-ex activites here, picking apart your code was hugely helpful in understanding this stuff.

Shout-out to the venerable Dr Nestori Syynimaa (@DrAzureAD), too, for AADInternals https://github.com/Gerenios/AADInternals, used here extensively. Hell of a toolbox and his blog is like a free AzureAD pentesting e-book.
