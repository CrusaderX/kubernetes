from kubernetes import client, config, watch
from kubernetes.client.rest import ApiException
from vars import *
from log import *

def approve_certificate(api_client,certificate,spec_username,spec_groups,metadata_name):
    certificate_status = certificate.status
    if certificate_status.conditions is None:
        logger.info("Found {} unapproval request. Validating ...".format(metadata_name))
        # add you certificate checks here
        if bool(set(api_groups) & set(spec_groups)) and spec_username not in api_username:
            logger.warning("Exception when validating certificate, groups not found: {} in {} or username is not correct - {}".format(spec_groups, api_groups, spec_username))
        else:
            certificate_status.conditions = [ { "type" : "Approved" } ]
            try:
                api_response = api_client.replace_certificate_signing_request_approval(metadata_name,certificate)
                logger.info("Certificate {} was approved.".format(metadata_name))
            except ApiException as e:
                logger.warning("Exception when calling Certificatesapi_clientbeta1Api->replace_certificate_signing_request_approval: %s\n" % e)
    else:
        logger.info("Certificate was already approved {}".format(metadata_name))


if __name__ == "__main__":
    if 'CLUSTER' in os.environ:
        config.load_incluster_config()
    else:
        config.load_kube_config()
    api_client = client.CertificatesV1beta1Api()
    w = watch.Watch()
    for event in w.stream(api_client.list_certificate_signing_request, watch=True):
        if event["type"] not in "DELETED":
            certificate = event["object"]
            try:
                metadata_name = event["object"].metadata.name
                spec_groups   = event["object"].spec.groups
                spec_username = event["object"].spec.username
                logger.info("Handling {} on {}".format(event["type"], metadata_name))
                approve_certificate(api_client, certificate, spec_username, spec_groups, metadata_name)
            except:
                logger.warning("{} Can't handle certificate".format(event["object"]))