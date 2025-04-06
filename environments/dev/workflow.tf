# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Context
# ----------------------------------------------------------------------------------------------------------------------

/*
  The workflow is used to avoid costs :
  - Cloud Composer is too expensive for this use case
  - Cloud NAT generate costs because Cloud Run Job lose internet access when connected to a Serverless VPC Connector
  - Serverless VPC Connector is expensive for this use case

  The workflow is used to create and delete resources for Cloud Run and trigger the Urls Scrapper Cloud Run Job.
*/

# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Service account and roles
# ----------------------------------------------------------------------------------------------------------------------

resource "google_service_account" "workflow_sa" {
  project      = var.project_id
  account_id   = "${var.project_name}-workflows-sa"
  display_name = "Workflows Service Account"
}

resource "google_project_iam_member" "workflow_sa_roles" {
  for_each = toset([
    "roles/vpcaccess.admin",
    "roles/vpcaccess.viewer",
    "roles/compute.networkAdmin",
    "roles/cloudbuild.builds.editor",
    "roles/iam.serviceAccountUser",
    "roles/logging.logWriter",
    "roles/run.developer",
    "roles/storage.objectViewer"
  ])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.workflow_sa.email}"
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Urls scrapper workflow
# ----------------------------------------------------------------------------------------------------------------------

resource "google_workflows_workflow" "urls_scrapper_workflow" {
  depends_on = [ google_service_account.workflow_sa ]

  name            = var.urls_scrapper_workflow_name
  project         = var.project_id
  region          = var.region
  description     = "Workflow used to generate resources for Cloud Run and trigger the Urls Scrapper Cloud Run Job"
  service_account = google_service_account.workflow_sa.id
  call_log_level  = "LOG_ALL_CALLS"

  deletion_protection = false # set to "true" in production

  labels = {
    env = var.env
  }

  source_contents = <<EOF
main:
  steps:
    - init:
        assign:
            - startTime: $${sys.now()}
            - maxWaitTime: 1800
            - pollingInterval: 15
            - projectId: ${var.project_id}
            - region: ${var.region}
            - routerName: ${var.router_name}
            - natName: ${var.nat_name}
            - urlsScrapperJobName: ${var.run_job_urls_scrapper_name}
            - jobsScrapperJobName: ${var.run_job_jobs_scrapper_name}
            - connectorName: ${var.serverless_connector_name}
            - networkName: ${google_compute_network.datastats_network.name}
            - networkLink: ${google_compute_network.datastats_network.self_link}
            - cloudRunSaEmail: ${module.run_job_urls_scrapper.service_account_email}
            - UtilsBucketName: ${module.utils_bucket.name}
            - JobsToScrapJson: ${google_storage_bucket_object.default_jobs_list.name}
            
    - createRouter:
        call: http.post
        args:
          url: $${"https://compute.googleapis.com/compute/v1/projects/" + projectId + "/regions/" + region + "/routers"}
          auth:
            type: OAuth2
          body:
            bgp:
              advertiseMode: "DEFAULT"
            description: "Router for Nat x Datastats Cloud Runs"
            encryptedInterconnectRouter: true
            kind: "compute#router"
            name: $${routerName}
            network: $${networkLink}
            region: projects/$${projectId}/regions/$${region}
        result: routerOperation
        next: checkRouterStatus

    - checkRouterStatus:
        call: waitForResource
        args:
            resourceUrl: $${routerOperation.body.selfLink}
            maxWait: $${maxWaitTime}
            interval: $${pollingInterval}
        result: routerStatus
        next: addNatToRouter

    - addNatToRouter:
        call: http.patch
        args:
          url: $${"https://compute.googleapis.com/compute/v1/projects/" + projectId + "/regions/" + region + "/routers/" + routerName}
          auth:
            type: OAuth2
          body:
            nats:
              - name: $${natName}
                natIpAllocateOption: "AUTO_ONLY"
                sourceSubnetworkIpRangesToNat: "ALL_SUBNETWORKS_ALL_IP_RANGES"
        result: natOperation
        next: createVpcConnector

    - createVpcConnector:
        call: http.post
        args:
          url: $${"https://vpcaccess.googleapis.com/v1/projects/" + projectId + "/locations/" + region + "/connectors?connectorId=" + connectorName}
          auth:
            type: OAuth2
          body:
            network: $${networkName}
            ipCidrRange: "10.10.0.0/28"
            minInstances: 2
            maxInstances: 3
            machineType: e2-micro
        result: vpcConnector
        next: waitForVpcConnector

    - waitForVpcConnector:
        call: waitForResource
        args:
          resourceUrl: $${"https://vpcaccess.googleapis.com/v1/" + vpcConnector.body.metadata.target}
          maxWait: $${maxWaitTime}
          interval: $${pollingInterval}
        result: vpcConnectoreReady
        next: getCloudRunJobConfig

    - getCloudRunJobConfig:
        call: http.get
        args:
          url: $${"https://run.googleapis.com/v2/projects/" + projectId + "/locations/" + region + "/jobs/" + urlsScrapperJobName}
          auth:
            type: OAuth2
        result: JobConfig
        next: AddConnectorUrlsRunJob

    - AddConnectorUrlsRunJob:
        call: http.patch
        args:
          url: $${"https://run.googleapis.com/v2/projects/" + projectId + "/locations/" + region + "/jobs/" + urlsScrapperJobName}
          auth:
            type: OAuth2
          body:
            template:
                template:
                  containers: $${JobConfig.body.template.template.containers}
                  serviceAccount: $${cloudRunSaEmail}
                  vpcAccess:
                    connector: $${"projects/" + projectId + "/locations/" + region + "/connectors/" + connectorName}
        result: updateJobResult
        next: getJsonFromBucket

    - getJsonFromBucket:
        call: googleapis.storage.v1.objects.get
        args:
          bucket: $${UtilsBucketName}
          object: $${JobsToScrapJson}
          alt: media
        result: objectData
        next: iterateOnJobs

    - iterateOnJobs:
        for:
          value: jobExtracted
          in: $${objectData.jobs_to_scrap}
          steps:
            - assign_var:
                assign:
                  - job: $${jobExtracted}
                next: triggerCloudRunJob

            - triggerCloudRunJob:
                call: googleapis.run.v1.namespaces.jobs.run
                args:
                  name: $${"namespaces/" + projectId + "/jobs/" + urlsScrapperJobName}
                  location: $${region}
                  body:
                    overrides:
                      containerOverrides:
                        env:
                          - name: JOB_TO_SCRAP
                            value: $${job}
        next: waitForLastJob

    - waitForLastJob:
        call: sys.sleep
        args:
          seconds: 30
        next: RemoveConnectorUrlsRunJob

    - RemoveConnectorUrlsRunJob:
        call: http.patch
        args:
            url: $${"https://run.googleapis.com/v2/projects/" + projectId + "/locations/" + region + "/jobs/" + urlsScrapperJobName}
            auth:
              type: OAuth2
            body:
              template:
                template:
                  containers: $${JobConfig.body.template.template.containers}
                  serviceAccount: $${cloudRunSaEmail}
        result: removeVpcResult
        next: AddConnectorJobsRunJob

    - AddConnectorJobsRunJob:
        call: http.patch
        args:
          url: $${"https://run.googleapis.com/v2/projects/" + projectId + "/locations/" + region + "/jobs/" + urlsScrapperJobName}
          auth:
            type: OAuth2
          body:
            template:
                template:
                  containers: $${JobConfig.body.template.template.containers}
                  serviceAccount: $${cloudRunSaEmail}
                  vpcAccess:
                    connector: $${"projects/" + projectId + "/locations/" + region + "/connectors/" + connectorName}
        result: updateJobResult
        next: triggerJobsRunJob

    - triggerJobsRunJob:
        call: googleapis.run.v1.namespaces.jobs.run
        args:
          name: $${"namespaces/" + projectId + "/jobs/" + jobsScrapperJobName}
          location: $${region}
        next: waitForJobsRunJob

    - waitForJobsRunJob:
        call: sys.sleep
        args:
          seconds: 240
        next: RemoveConnectorJobsRunJob

    - RemoveConnectorJobsRunJob:
        call: http.patch
        args:
            url: $${"https://run.googleapis.com/v2/projects/" + projectId + "/locations/" + region + "/jobs/" + jobsScrapperJobName}
            auth:
              type: OAuth2
            body:
              template:
                template:
                  containers: $${JobConfig.body.template.template.containers}
                  serviceAccount: $${cloudRunSaEmail}
        result: removeVpcResult
        next: deleteVpcConnector

    - deleteVpcConnector:
        call: http.delete
        args:
          url: $${"https://vpcaccess.googleapis.com/v1/" + vpcConnector.body.metadata.target}
          auth:
            type: OAuth2
        next: deleteRouter

    - deleteRouter:
        call: http.delete
        args:
            url: $${routerOperation.body.targetLink}
            auth:
              type: OAuth2

waitForResource:
  params: [resourceUrl, maxWait, interval]
  steps:
    - init:
        assign:
          - startTime: $${sys.now()}

    - checkResource:
        call: http.get
        args:
          url: $${resourceUrl}
          auth:
            type: OAuth2
        result: resourceStatus
        next: GetCorrectStatusValue

    - GetCorrectStatusValue:
        switch:
        - condition: $${"state" in resourceStatus.body}
          assign: 
            - statusValue: $${resourceStatus.body.state}
        - condition: $${"status" in resourceStatus.body}
          assign:
            - statusValue: $${resourceStatus.body.status}

    - checkResourceState:
        switch:
        - condition: $${statusValue == "READY" or statusValue == "DONE"}
          return: $${statusValue}
        next: waitAndRetry

    - waitAndRetry:
        call: sys.sleep
        args:
          seconds: $${interval}
        next: checkResource

gcloud:
  params: [args]
  steps:
  - create_build:
      call: googleapis.cloudbuild.v1.projects.builds.create
      args:
        projectId: ${var.project_id}
        parent: projects/${var.project_id}/locations/global
        body:
          serviceAccount: $${sys.get_env("GOOGLE_CLOUD_SERVICE_ACCOUNT_NAME")}
          options:
            logging: CLOUD_LOGGING_ONLY
          steps:
          - name: gcr.io/google.com/cloudsdktool/cloud-sdk
            entrypoint: /bin/bash
            args: $${["-c", "gcloud " + args + " > $$BUILDER_OUTPUT/output"]}
      result: result_builds_create
  - return_build_result:
      return: $${text.split(text.decode(base64.decode(result_builds_create.metadata.build.results.buildStepOutputs[0])), "\n")}
    EOF
}
