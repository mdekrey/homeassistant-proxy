docker build . -t dekreydotnet.azurecr.io/ssh-public-proxy

az login
az acr login --subscription 2351fc7a-207c-4a7d-8104-d5fe21d7907f --name dekreydotnet
docker push dekreydotnet.azurecr.io/ssh-public-proxy
kubectl -n homeassistant-proxy set image deployment homeassistant-ssh ssh-proxy=$(docker inspect --format='{{index .RepoDigests 0}}' dekreydotnet.azurecr.io/ssh-public-proxy:latest)
