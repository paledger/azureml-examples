set -e
### Part of automated testing: only required when this script is called via vm run-command invoke inorder to gather the parameters ###
for args in "$@"
do
    keyname=$(echo $args | cut -d ':' -f 1)
    result=$(echo $args | cut -d ':' -f 2)
    export $keyname=$result
done

# login using the user assigned identity. 
az login --identity -u /subscriptions/$SUBSCRIPTION/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$IDENTITY_NAME
az account set --subscription $SUBSCRIPTION
az configure --defaults group=$RESOURCE_GROUP workspace=$WORKSPACE location=$LOCATION

# <create_vnet_deployment> 
cd /home/samples/azureml-examples/cli/
export AZURE_ML_CLI_PRIVATE_FEATURES_ENABLED=true
az ml online-endpoint create --name $ENDPOINT_NAME -f endpoints/online/managed/vnet/endpoint.yml
az ml online-deployment create --name blue --endpoint $ENDPOINT_NAME -f endpoints/online/managed/vnet/blue-deployment-vnet.yml --all-traffic --set environment.image="$ACR_NAME.azurecr.io/repo/img:v1" private_network_connection="true"
# </create_vnet_deployment> 

# <get_logs> 
az ml online-deployment get-logs -n blue --endpoint $ENDPOINT_NAME
# </get_logs>

# check if scoring works
az ml online-endpoint invoke --name $ENDPOINT_NAME --request-file endpoints/online/managed/vnet/sample-request.json
