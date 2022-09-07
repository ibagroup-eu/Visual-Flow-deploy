#!/bin/bash

#SAVE ARGS
ACTION=$1
OPTION=$2

# # DEBUG
# APP_NAME=vf-app
# RELEASE_NAME=vf-app-dev
# BE_IMAGE_TAG=latest
# FE_IMAGE_TAG=latest
# SPARKJ_IMAGE_TAG=latest
# SLACKJ_IMAGE_TAG=latest
# CLUSTER_NAMESPACE=
# CD_ROLLBACK_VERSION=
# ACTION=
# OPTION=



# VARIABLES
CHART_PATH="./charts/$APP_NAME"
echo "APP_NAME=${APP_NAME}"
echo "RELEASE_NAME=${RELEASE_NAME}"
echo "BE_IMAGE_TAG=${BE_IMAGE_TAG}"
echo "FE_IMAGE_TAG=${FE_IMAGE_TAG}"
echo "SPARKJ_IMAGE_TAG=${SPARKJ_IMAGE_TAG}"
echo "SLACKJ_IMAGE_TAG=${SLACKJ_IMAGE_TAG}"
echo "CLUSTER_NAMESPACE=${CLUSTER_NAMESPACE}"
echo "CHART_PATH=${CHART_PATH}"
echo "CD_ROLLBACK_VERSION=${CD_ROLLBACK_VERSION}"
echo "ACTION=${ACTION}"
echo "OPTION=${OPTION}"



# RUN ACTION
if [[ "${ACTION}" = "help" ]]; then
    echo "Usage:
        $0 help - print this help
        $0 uninstall [-y] - uninstall release
        $0 rollback [revision_number] - rollback release to 'revision_number' version 
                                        or to \$CD_ROLLBACK_VERSION version
                                        or to previous version
        $0 - install/upgrade release
        "
elif [[ "${ACTION}" = "uninstall" ]]; then
    if [[ "${OPTION}" = "-y" ]]; then
        echo "Uninstalling '${RELEASE_NAME}' release"
        echo "helm uninstall --dry-run --debug ${RELEASE_NAME} --namespace ${CLUSTER_NAMESPACE}"
        helm uninstall --dry-run --debug ${RELEASE_NAME} --namespace ${CLUSTER_NAMESPACE}
        sleep 10
        echo "helm uninstall ${RELEASE_NAME} --namespace ${CLUSTER_NAMESPACE}"
        helm uninstall ${RELEASE_NAME} --namespace ${CLUSTER_NAMESPACE}
        echo "Done"
    else
        echo "Are you sure to uninstall '${RELEASE_NAME}'? If yes add '-y' option to command"
    fi


elif [[ "${ACTION}" = "rollback" ]]; then

    if [[ ${OPTION} ]]; then
        echo "Rolling back to '${OPTION}' revision for '${RELEASE_NAME}' release"
    elif [[ ${CD_ROLLBACK_VERSION} ]]; then
        OPTION=${CD_ROLLBACK_VERSION}
        echo "Rolling back to '${OPTION}' revision for '${RELEASE_NAME}' release"
    else
        OPTION=$(helm history --max 2 -o json ${RELEASE_NAME} | jq '.[0].revision')
        echo "Rolling back to '${OPTION}' revision for '${RELEASE_NAME}' release"
    fi

    echo "helm rollback --dry-run --debug ${RELEASE_NAME} ${OPTION} --namespace ${CLUSTER_NAMESPACE}"
    helm rollback --dry-run --debug ${RELEASE_NAME} ${OPTION} --namespace ${CLUSTER_NAMESPACE}
    sleep 10
    echo "helm rollback --wait ${RELEASE_NAME} ${OPTION} --namespace ${CLUSTER_NAMESPACE}"
    helm rollback --wait ${RELEASE_NAME} ${OPTION} --namespace ${CLUSTER_NAMESPACE}
    echo "Done"

    echo ""
    echo "=========================================================="
    echo "DEPLOYMENTS:"
    echo ""
    echo -e "Status for release: ${RELEASE_NAME}"
    helm status ${RELEASE_NAME} --namespace ${CLUSTER_NAMESPACE}

    echo ""
    echo -e "History for release: ${RELEASE_NAME}"
    helm history ${RELEASE_NAME} --max=5 --namespace ${CLUSTER_NAMESPACE}


else # install/upgrade
    echo "Installing/Upgrading '${RELEASE_NAME}' release. Collecting values..."
    VALUES="backend.deployment.image.tag=${BE_IMAGE_TAG},frontend.deployment.image.tag=${FE_IMAGE_TAG},backend.configFile.sparkJob.tag=${SPARKJ_IMAGE_TAG},backend.configFile.slackJob.tag=${SLACKJ_IMAGE_TAG}"
    echo "VALUES='${VALUES}'"
    echo "helm upgrade --install --dry-run --debug ${RELEASE_NAME} ${CHART_PATH} -f ${CHART_PATH}/values.yaml --set ${VALUES} --description ${CI_PIPELINE_ID} --namespace ${CLUSTER_NAMESPACE}"
    helm upgrade --install --dry-run --debug ${RELEASE_NAME} ${CHART_PATH} -f ${CHART_PATH}/values.yaml --set ${VALUES} --description ${CI_PIPELINE_ID} --namespace ${CLUSTER_NAMESPACE}
    sleep 10
    echo "helm upgrade --install --wait ${RELEASE_NAME} ${CHART_PATH} -f ${CHART_PATH}/values.yaml --set ${VALUES} --description ${CI_PIPELINE_ID} --namespace ${CLUSTER_NAMESPACE}"
    helm upgrade --install --wait ${RELEASE_NAME} ${CHART_PATH} -f ${CHART_PATH}/values.yaml --set ${VALUES} --description ${CI_PIPELINE_ID} --namespace ${CLUSTER_NAMESPACE}
  
    echo "CHECKING STATUS"
    echo "kubectl get pods --namespace ${CLUSTER_NAMESPACE}"
    kubectl get pods --namespace ${CLUSTER_NAMESPACE}
  
    # CHECK STATUS
    echo "=========================================================="
    echo -e "CHECKING deployment status of release ${RELEASE_NAME}"
    echo ""

    for ITERATION in {1..30}
    do
        DATA=$( kubectl get pods --namespace ${CLUSTER_NAMESPACE} -l app=${RELEASE_NAME} -o json )
        NOT_READY=$( echo $DATA | jq '.items[].status | select(.containerStatuses!=null) | .containerStatuses[] | select(.ready==false)  | .name ' )
        
        if [[ -z "$NOT_READY" ]]; then
            echo -e "All pods are ready:"
            echo $DATA | jq '.items[].status | select(.containerStatuses!=null) | .containerStatuses[] | select(.ready==true)  | .name'
            break # deployment succeeded
        fi

        REASON=$(echo $DATA | jq '.items[].status | select(.containerStatuses!=null) | .containerStatuses[] | .state.waiting.reason')
        echo -e "${ITERATION} : Deployment still pending..."
        echo -e "NOT_READY:${NOT_READY}"
        echo -e "REASON: ${REASON}"

        if [[ ${REASON} == *ErrImagePull* ]] || [[ ${REASON} == *ImagePullBackOff* ]]; then
            echo "Detected ErrImagePull or ImagePullBackOff failure. "
            echo "Please check image still exists in registry, and proper permissions from cluster to image registry (e.g. image pull secret)"
            break; # no need to wait longer, error is fatal
        elif [[ ${REASON} == *CrashLoopBackOff* ]]; then
            echo "Detected CrashLoopBackOff failure. "
            echo "Application is unable to start, check the application startup logs"
            break; # no need to wait longer, error is fatal
        fi

        sleep 10
    done

    if [[ ! -z "$NOT_READY" ]]; then
        echo ""
        echo "=========================================================="
        echo "DEPLOYMENT FAILED"
        #echo "Application Logs"
        #kubectl logs --selector app=${CHART_NAME} --namespace ${CLUSTER_NAMESPACE}
        echo "=========================================================="
        REVISION=$( helm history --max 2 -o json ${RELEASE_NAME} | jq '.[0].revision' )
        echo -e "Could rollback to previous revision (${REVISION}) using command:"
        echo -e "helm rollback --wait ${RELEASE_NAME} ${REVISION} --namespace ${CLUSTER_NAMESPACE}"
        exit 1
    fi

    echo ""
    echo "=========================================================="
    echo "DEPLOYMENTS:"
    echo ""
    echo -e "Status for release: ${RELEASE_NAME}"
    helm status ${RELEASE_NAME} --namespace ${CLUSTER_NAMESPACE}

    echo ""
    echo -e "History for release: ${RELEASE_NAME}"
    helm history ${RELEASE_NAME} --max=5 --namespace ${CLUSTER_NAMESPACE}

    echo "=========================================================="
    echo "DEPLOYMENT SUCCEEDED"
    ################### DEPLOYMENT STATUS <<<<<<<<<##############################################

fi
