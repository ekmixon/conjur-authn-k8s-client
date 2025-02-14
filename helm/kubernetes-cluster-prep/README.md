# Helm Chart for Conjur Kubernetes Cluster Preparation

## Table of Contents

- [Helm Chart for Conjur Kubernetes Cluster Preparation](#helm-chart-for-conjur-kubernetes-cluster-preparation)
  * [Table of Contents](#table-of-contents)
  * [Overview](#overview)
    + [Objects Created](#objects-created)
  * [Preparing the Kubernetes Cluster for Conjur Authentication](#preparing-the-kubernetes-cluster-for-conjur-authentication)
  * [Examples: Running Helm Install](#examples-running-helm-install)
    + [Optional: Creating a Local Copy of This Helm Chart](#optional-creating-a-local-copy-of-this-helm-chart)
  * [Configuration](#configuration)

## Overview

This Helm chart is used to create per-cluster Kubernetes objects that are
necessary to support Conjur Kubernetes authentication on a Kubernetes cluster.

The objects that are created by this Helm chart do not include objects that
are required on a per-application-Namespace basis for Conjur Kubernetes
authentication support. Those objects are created using a separate
application Namespace preparation Helm chart as each Conjur-enabled
application is being deployed.

### Objects Created

The per-Kubernetes-cluster resources that are created by this Helm chart
include:

- __"Golden" ConfigMap__

  The Golden ConfigMap keeps a reference copy of Conjur
  connection/configuration information that can be used later for:

  - Running an automated test to validate the configured Conjur connection
    information by using various `openssl` and `curl` commands to check
    connectivity with the target Conjur instance, verify its SSL
    certificate, and optionally attempt to authenticate with the Conjur
    instance.
  - Creating Kubernetes objects in application Namespaces as required to
    support Conjur authentication for applications in those Namespaces.
    These objects are created via the Application Namespace Preparation
    Helm chart.
 
- __Conjur Authenticator ServiceAccount__

  This ServiceAccount is used as a Kubernetes identity by the Conjur
  authenticator plugin (also known as `authn-k8s`). This identity allows
  the Conjur Authenticator to authenticate with the Kubernetes
  API controller, so that it can validate the identity of applications.

- __A Conjur authenticator ClusterRole__

  This ClusterRole is used to provide a list of Kubernetes API access
  permissions that the Conjur authenticator will require in order to
  validate application identities.

## Preparing the Kubernetes Cluster for Conjur Authentication

This workflow is performed once per Conjur instance / per authn-k8s
authenticator, typically by a Kubernetes administrator. 
![Kubernetes Cluster Prep Workflow](assets/kube-cluster-prep.png)
The steps are as follows: 

1. __Gather Conjur configuration information.__
 
   Collect the following prerequisite information from your Conjur
   administrator:

   - Conjur appliance URL:\
     The URL of the Conjur Enterprise Follower
     or Conjur OSS server that will be used to authenticate your applications.
     The Conjur appliance URL could be an address that is either internal
     or external with respect to the Kubernetes cluster. Examples include:
     - https://conjur.example.com       (external address)
     - https://conjur-oss.conjur-oss.svc.cluster.local  (internal address)

   - Conjur account:\
     The conjur account to be used by the authenticator

   - Conjur authenticator ID:\
     The Conjur authenticator ID that was configured in Conjur security
     policy in order to enable Kubernetes authentication for the Conjur
     instance.

   - __(OPTIONAL)__ Existing ServiceAccount to reuse for Conjur authentication:\
     If a Conjur-related ServiceAccount already exists in the Namespace
     to which you intend to deploy this Helm chart (for example, if
     you're using the same Namespace to which Conjur OSS has been deployed,
     and you'd like to reuse the existing Conjur ServiceAccount), then you
     have the option of simply reusing that ServiceAccount.

   - __(OPTIONAL)__ Existing ClusterRole to reuse for Conjur authentication:\
     If a ClusterRole with the appropriate permissions for performing
     Conjur authentication already exists in the Kubernetes cluster,
     then you have the option of simply reusing that ClusterRole.

1. Retrieve the Conjur SSL certificate. 

   There is a script in the 'bin' directory called 'get-conjur-cert.sh' that can 
   be used to retrieve the certificate of a Conjur appliance based on its
   URL, and write the certificate to a local file.

   This script can also optionally verify the certificate after it has
   been retrieved by running a curl command to attempt to access the Conjur
   instance.

   This script can be used for Conjur instances that are either internal
   or external to the Kubernetes cluster. For external Conjur instances
   there is a requirement to have OpenSSL installed.

   The  syntax for this command is as follows:

     ```
     ./get-conjur-cert.sh -u <Conjur appliance URL> [Options]

     Options:
      -d <k8s test deployment name>  Kubernetes deployment name to use for
                                     an openssl test pod. This only applies
                                     if the '-i' command option is used. This
                                     defaults to 'openssl-test'.
      -f <destination filepath>      Destination file for writing certificate.
                                     If not set, certificate will be written
                                     to 'files/conjur-cert.pem'.
      -h                             Show help
      -i                             Conjur appliance URL is a Kubernetes
                                     cluster internal address.
      -u <Conjur appliance URL>      Conjur appliance URL (required)
      -v                             Verify the certificate

     ```

   For example:

   ```
   ./bin/get-conjur-cert.sh -v -u conjur.conjur-ns.svc.cluster.local -i
   ```

   A file conjur-cert.pem is created and the contents should look similar to
   below:

   ```
   -----BEGIN CERTIFICATE-----
   MIIDhDCCAmygAwIBAgIRAPyRtWiyww+YuzrNpXLmlEowDQYJKoZIhvcNAQELBQAw
   GDEWMBQGA1UEAxMNY29uanVyLW9zcy1jYTAeFw0yMTAyMTEyMjI1MDVaFw0yMjAy
   MTEyMjI1MDVaMBsxGTAXBgNVBAMTEGNvbmp1ci5teW9yZy5jb20wggEiMA0GCSqG
   SIb3DQEBAQUAA4IBDwAwggEKAoIBAQCuNZFGiCaaVNoz8Rrm4/aNYqPc12DuMsj2
   XTNoVsdxUQBGc5LHf7xCNt6WP5Urr8aG/xsON79rjpgv38n1zpp7Ct1rIzfUnZUo
   RJmth7SR1EgA+IVGjwsvbaLFRcASlhnO+r7ApI1YVd69XaXPzxzxZuPP9XpjBdTC
   AD2AKF3QnnSi7qruW/qzKOylLyBcJ1AQBYxDMgs1IoaLWg9nzyYUK0kdaXeYjxK7
   R3CQjmf21jfJL/cQJ2fdiYKgunAUmRc8ob21gWj4qnL4WFuujimreFlQtlaHttBm
   lfuiZY/2w8YUyd+Q9z2rNHDxmyRkG5YVitWJATRUQj5/elSIJwptAgMBAAGjgcUw
   gcIwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcD
   AjAMBgNVHRMBAf8EAjAAMIGCBgNVHREEezB5ghBjb25qdXIubXlvcmcuY29tggpj
   b25qdXItb3NzghVjb25qdXItb3NzLmNvbmp1ci1vc3OCGWNvbmp1ci1vc3MuY29u
   anVyLW9zcy5zdmOCJ2Nvbmp1ci1vc3MuY29uanVyLW9zcy5zdmMuY2x1c3Rlci5s
   b2NhbDANBgkqhkiG9w0BAQsFAAOCAQEAePH+5amKWGeW0r8lcLT9EuMk1pDcDceV
   4vOig9mMrlgy8hIMcBmcFL4VNrFoiac3vRRezGSq+QygfHSSM23NvbC6fgd4ocJe
   +AhSAvbLGN+3RgVQAdNe++73LgZNdmcjGSCxMMVftc+WUYuEaBLculLNF1N9zyY+
   DWW7jdzfPg2a1fAKY23K/r69Hv+mHhPHTMkhTOvzAK13wkM+yT+1FrMwGCGsQAL9
   GdlyLJsS00hBIiB6t6dEPrwmwnrz7QaXMCHnW/BMEm3lxHQapebZ0QdDUgFDxSmB
   eNc8amfRdvH0dVM+GZQ9fhBug1a/zBALnjuQzmi3tCsi+emCrVXIWw==
   -----END CERTIFICATE-----
   -----BEGIN CERTIFICATE-----
   MIIC/TCCAeWgAwIBAgIRAOUE8lp/AVpzxYaFAEU1U4MwDQYJKoZIhvcNAQELBQAw
   GDEWMBQGA1UEAxMNY29uanVyLW9zcy1jYTAeFw0yMTAyMTEyMjI1MDVaFw0yMjAy
   MTEyMjI1MDVaMBgxFjAUBgNVBAMTDWNvbmp1ci1vc3MtY2EwggEiMA0GCSqGSIb3
   DQEBAQUAA4IBDwAwggEKAoIBAQDwcuGKTt/jxQz0PsJiJhX1r54mR9Z6Gpqb1na9
   ChpSMY++MOK2hjZSCW5zzKq4kJPNTAkc2BLTHwW8agqHC630MECDUxr7bahPj6bV
   ihndwBvjBVWIiWAqliqXqnhLkKF9XO6CEw1/Of4JEaerq30cE3sCZsCXEIOLoPWf
   kOTuMIuD2aDbIEzVe9wHouV+SMD+ye0C4iKtacW2h07be1DxNmFrUO4Gqm79O5Dv
   7JNPjl1UmNIQLv24g4+MLiNfpB08++CBG3wulX8VgQigMWqWhHEnqDD21q0sKjWL
   OHBSX6r76Fo/DekK3CxBBFpBzTNhq+b8K7NJQgeSX1yDiT47AgMBAAGjQjBAMA4G
   A1UdDwEB/wQEAwICpDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDwYD
   VR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAhtsQ/Rr6HKaqZeWUcfIr
   1p2Wbm+LAmb0kUwzvpvvqynlB+O1vY0GSsMk6ipZdhwCLLhGiEo5y/sGQID8n/b9
   5njZAXePJsalc9R3TQc44NGnyRCoMrmmAKMnjXgAVdm+p3UA/C1JmyNUeKnnMAdX
   A2LoDL+WtYbK/NCfVL45jFPD4ygZhXWoJ+BVk33wudi+7GoEHpE0lXlcVyym4g6J
   1vdck2R84vaShDvh2vCrwlj+XnaIvOwLjZswTh2WPvMaRhnJ+QmDPpEcw5wdVlaa
   9gi8KwcJAxv0+CXPjL0gAH9dWrUmKXAQGzA2dnNCgIfVqgfPZwMqpxEwZt+GEEu8
   zA==
   -----END CERTIFICATE-----
   ```

1. Create a Namespace for the authn-k8s authenticator.

   __NOTE: If a Conjur Namespace already exists, and only one authn-k8s
     authenticator is being used in this cluster, then that Conjur Namespace
     can be reused as the authenticator Namespace).__

1. Run ‘helm install’ using Kubernetes Cluster Prep Helm chart.

   For examples of how you can the `helm install` command, see the
   "Examples: Running Helm Install" section below.

   When `helm install` command completes, you should see the following
   Kubernetes objects created in your current (authenticator) Namespace:
   - Golden ConfigMap 
   - Authenticator ServiceAccount 
   - Authenticator ClusterRole 

## Examples: Running Helm Install

### Optional: Creating a Local Copy of This Helm Chart

For brevity, the example commands below assume that the `helm install ...`
command is run using a local copy of the Helm chart. You can use
`git clone ...` to create a local copy of the Helm chart, e.g.:

  ```
  cd
  git clone https://github.com/cyberark/conjur-authn-k8s-client
  cd conjur-authn-k8s-client/deploy/charts/kubernetes-cluster-prep
  ```

- Helm Install Using A Conjur Certificate From a File

  ```
  helm install my-conjur-release . \
       --set conjur.applianceUrl="https://conjur.example.com" \
       --set conjur.certificateFilePath="files/conjur-cert.pem" \
       --set authnK8s.authenticatorID="my-authenticator-id"
  ```

- Helm Install Using A Base64-Encoded Conjur Certificate

  ```
  helm install my-conjur-release . \
       --set conjur.applianceUrl="https://conjur.example.com" \
       --set conjur.certificateBase64="<Base64-encoded Conjur Cert>" \
       --set authnK8s.authenticatorID="my-authenticator-id"
  ```

- Helm Install Reusing An Existing Conjur ClusterRole
  
  ```
  helm install my-conjur-release . \
       --set conjur.applianceUrl="https://conjur.example.com" \
       --set conjur.certificateFilePath="tests/test-cert.pem" \
       --set authnK8s.authenticatorID="my-authenticator-id" \
       --set authnK8s.clusterRole.create=false \
       --set authnK8s.clusterRole.name="existing-conjur-clusterrole"
  ```

- Helm Install Reusing An Existing Conjur ServiceAccount
  
  ```
  helm install my-conjur-release . \
       --set conjur.applianceUrl="https://conjur.example.com" \
       --set conjur.certificateFilePath="tests/test-cert.pem" \
       --set authnK8s.authenticatorID="my-authenticator-id" \
       --set authnK8s.serviceAccount.create=false \
       --set authnK8s.serviceAccount.name="existing-conjur-serviceaccount"
  ```

- Helm Install Using a Custom Values YAML File
  
  ```
  cat > my-custom-values.yaml << EOT
  conjur:
    account: "my-conjur-account"
    applianceUrl: "https://conjur-oss.conjur-oss.svc.cluster.local"
    certificateFilePath: "files/conjur-cert.pem"

  authnK8s:
    authenticatorID: "my-authenticator-id"
  EOT

  helm install my-conjur-release . -f my-custom-values.yaml 
  ```

## Configuration

The following table lists the configurable parameters of the Conjur OSS chart and their default values.

|Parameter|Description|Default|Mandatory|
|---------|-----------|-------|---------|
|`conjur.account`|Conjur account to be used by the Kubernetes authenticator|`"default"`||
|`conjur.applianceUrl:`|Conjur Appliance URL||Yes|
|`conjur.ssl.certificateFile`|Path to a Conjur certificate file||Either certificateFile or certificateBase64|
|`conjur.ssl.certificateBase64`|Base64-encoded Conjur certificate file||Either certificateFile or certificateBase64|
|`authnK8s.authenticatorID`|Conjur authn-k8s authenticator ID to use for authentication||Yes|
|`authnK8s.configMap.create`|Flag to generate the Golden ConfigMap |`true`||
|`authnK8s.configMap.name`|The name of the authenticator ConfigMap|`"authn-k8s-configmap"`||
|`authnK8s.clusterRole.create`|Flag to generate the ClusterRole |`true`||
|`authnK8s.clusterRole.name`|The name of the authenticator ClusterRole to use or create|`Defaults to authn-k8s-clusterrole when 'authnK8s.clusterRole.create' is set to 'true'`|Mandatory if authnK8s.clusterRole.create is set to 'false'|
|`authnK8s.serviceAccount.create`|Flag to generate the ServiceAccount |`true`||
|`authnK8s.serviceAccount.name`|The name of the authenticator ServiceAccount to use or create|`Defaults to authn-k8s-serviceaccount when 'authnK8s.ServiceAccount.create`|Mandatory if authnK8s.ServiceAccount.create is set to 'false'|

