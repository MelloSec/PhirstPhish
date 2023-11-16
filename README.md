## PhirstPhish

### "If you only get one.."

This is a script to assist in device code phishing O365 accounts.  It can take a $Token as a parameter if you already have an access token, otherwise, it will generate a device code that you or a user can use to bypass Multi-Factor Authentication from a signed in account.

The script will check your OS and install the required modules and binaries to post-exploitation activity.

Once you recieve an access token, the script will automatically perform tenant, user and group recon using AADInternals and Azurehound. Using the latest version of Azurehound, the Azure tenant will be mapped and output to a format you can load into Neo4j for attack path mapping.

It will dump the users last 200 emails from their inbox, dump all their teams messages, and set their status to 'Gone Phishin'"

A user list is generated for further phishing attacks. if you specify -targetUser you can specify an email address and with -messageContent a new phishing pretext. If you instead pass the word "all" for -targetUser you will be warned. If you proceed, your message will be sent to every user in the tenant using the compromised account.

#### Usage

No additional phishing, no Token

```powershell
.\PhirstPhish.ps1 
```

No additional phishing, have token

```powershell
.\PhirstPhish.ps1 -token $Token
```

Internal phishing an additional mailbox with compromised account

```powershell
.\PhirstPhish.ps1 -messageContent "Hey, did you see who they're letting go? Check it out https://notices.azurewebsites.net/terminations.pdf" -targetUser accounting@corpomax.com
```

Chaos Phishing the Tenant

```powershell
.\PhirstPhish.ps1 -messageContent "Hey, did you see who they're letting go? Check it out https://notices.azurewebsites.net/terminations.pdf" -targetUser all
```


