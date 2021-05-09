# az login

$account = az ad sp create-for-rbac --scopes /subscriptions/2351fc7a-207c-4a7d-8104-d5fe21d7907f/resourcegroups/DeKreyDotNet/providers/Microsoft.ContainerRegistry/registries/dekreydotnet --role Reader --name http://homeassistant-k8s-reader | ConvertFrom-Json

# kubectl -n homeassistant-proxy delete secret homeassistant-proxy-registry
kubectl -n homeassistant-proxy create secret docker-registry homeassistant-proxy-registry --docker-server "dekreydotnet.azurecr.io" --docker-username="$($account.appId)" --docker-password="$($account.password)"
