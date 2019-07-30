$webappname = "as-tst-gkim-as-01"
$gitrepo = "https://github.com/rudgh1027/mvc.git"
$rgname = "rg-tst-gkim-as-01"
az group create --location westus --name rg-tst-gkim-as-01 --tag "{creator = ghkim}"

az appservice plan create --name $webappname --resource-group $rgname --sku FREE
az webapp create --name $webappname --resource-group $rgname --plan $webappname
az webapp deployment source config --name $webappname --resource-group $rgname --repo-url $gitrepo --branch master --manual-integration
