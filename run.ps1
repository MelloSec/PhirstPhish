$targetUser = "admin@corpomax.com"
$firstUser = "newemployee@corpomax.com"
$messageContent = "Hey guys, <p> the client is asking us to install an addin, something to do with the 'net' framework and PDFs, sounds important. Can you take a look and see if we can get it installed? Thy're really breathing down our necks https://pdfutil.azurewebsites.net/addin </p> <p> Thanks guys you're the unsung heroes of CorpoMax, they should pay you more! </p> <p> Sincerely Yours.</p>"
$subject = "Software for Project Management"
$template = "chatgpt"

.\wrapper.ps1 -targetUser $targetUser -firstUser $firstUser -messageContent $messageContent -subject $subject -template $template