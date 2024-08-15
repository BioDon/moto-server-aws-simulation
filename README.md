# Simulating AWS Services Locally with Moto for Development and Testing

This project demonstrates how to simulate AWS services locally by deploying a Moto server within a Kubernetes cluster on Docker Desktop. For this example, we use DynamoDB, but this approach is applicable to a wide range of AWS services supported by Moto. Using Terraform, we define and provision a DynamoDB table and populate it with dummy data on the Moto server. This setup enables comprehensive testing and development in a controlled environment without relying on real AWS resources, thereby avoiding associated costs and complexities. Whether you need to test DynamoDB, S3, SQS, or other AWS services, this method provides a flexible and cost-effective solution for local simulations.
```bash
+-----------------------------------------------------+
| Simulating AWS Services Locally with Moto           |
| Development and Testing                             |
|                                                     |
|  +---------------------------------------------+    |
|  |                                             |    |
|  |     [ Moto Server ] --> [ Kubernetes ] -->  |    |
|  |     [ Terraform ] --> [ DynamoDB Table ]    |    |
|  |                                             |    |
|  +---------------------------------------------+    |
|                                                     |
|                                                     |
| Local Development & Testing                         |
+-----------------------------------------------------+
```

## Introduction

[Moto](https://docs.getmoto.org/en/latest/index.html) is an open-source Python library that provides a mock AWS environment, enabling developers to simulate AWS services for testing purposes. By integrating Moto with Kubernetes and Helm, we create a local environment where AWS services can be mimicked accurately. Helm, a package manager for Kubernetes, simplifies the deployment and management of applications on Kubernetes, while Terraform is used to define infrastructure in code and provision resources. In this project, Moto simulates the AWS DynamoDB service, and Terraform is utilized to create and manage a DynamoDB table along with dummy data. This approach allows developers to test their applications against a local instance of DynamoDB without interacting with live AWS resources, ensuring that the application’s interaction with AWS services behaves as expected.

## Prerequisites

Before you begin, ensure you have the following installed:

- **[Docker Desktop](https://www.docker.com/products/docker-desktop/)**: To run Kubernetes locally on Windows. Helm will be used as package manager.
  **For Linux Users**: You can use [Docker Engine](https://docs.docker.com/engine/install/) and set up Kubernetes manually using [Minikube](https://minikube.sigs.k8s.io/docs/), [K3s](https://k3s.io/), or [MicroK8s](https://microk8s.io/) as alternatives.
- **[Terraform](https://developer.hashicorp.com/terraform/install)**: For infrastructure as code.
- **[kubectl](https://kubernetes.io/docs/tasks/tools/)**: Kubernetes command-line tool to interact with your Kubernetes cluster.
- **[AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)**: No configuration is required post installation as we are only simulating.

## Project Setup

1. **Create a Project Folder**

   First, create a directory for your project:

    ```bash
    mkdir moto-dynamodb-project
    cd moto-dynamodb-project
    ```

2. **Create an Infrastructure Folder**

   Within your project directory, create an `infrastructure` folder:

    ```bash
    mkdir infrastructure
    cd infrastructure
    ```

3. **Add Terraform Configuration**

   Inside the `infrastructure` folder, create a `main.tf` file with the following Terraform configuration:
   (This configuration sets up a DynamoDB table and populates it with dummy data using Terraform. It allows you to test and develop locally with a simulated DynamoDB instance (Moto server) without needing to interact with actual AWS resources. The items are predefined to provide a controlled dataset for testing.)

    ```hcl
    resource "aws_dynamodb_table" "SampleTable" {
      name         = "SampleTable"
      billing_mode = "PROVISIONED"
      hash_key     = "userId"
      read_capacity  = 1
      write_capacity = 1

      attribute {
        name = "userId"
        type = "S"
      }

      tags = {
        Name        = "User"
        Environment = "development"
      }
    }

    # Adding Dummy data for testing Moto
    resource "aws_dynamodb_table_item" "dummy_data_item1" {
      table_name = aws_dynamodb_table.SampleTable.name
      hash_key   = "userId"
      item = <<ITEM
    {
      "userId": {"S": "user1"},
      "name": {"S": "Alice"},
      "email": {"S": "alice@example.com"}
    }
    ITEM
    }

    resource "aws_dynamodb_table_item" "dummy_data_item2" {
      table_name = aws_dynamodb_table.SampleTable.name
      hash_key   = "userId"
      item = <<ITEM
    {
      "userId": {"S": "user2"},
      "name": {"S": "Bob"},
      "email": {"S": "bob@example.com"}
    }
    ITEM
    }
    ```
   
4. **Configure the Provider**

   Create a `providers.tf` file in the `infrastructure` folder with the following content:

    ```hcl
    terraform {
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 5.0"
        }
      }
    }

    provider "aws" {
      region                      = "eu-central-1"
      access_key                  = "fakeaccesskey"  # Moto requires dummy credentials
      secret_key                  = "fakesecretkey"  # Moto requires dummy credentials
      skip_credentials_validation = true
      skip_metadata_api_check     = true
      skip_requesting_account_id  = true

      endpoints {
        dynamodb = "http://localhost:30500"
      }
    }
    ```

   **Context**: The `providers.tf` file specifies the AWS provider configuration, including dummy credentials and custom endpoint settings for the Moto server. The Moto server simulates the AWS DynamoDB service, and it listens on port 30500. This setup allows you to interact with the mock DynamoDB service using the AWS CLI or other AWS tools, facilitating local development and testing without incurring costs or using actual AWS resources.

   **Port Explanation**: Port 30500 is used as the endpoint for the mock DynamoDB service provided by the Moto server. This port number is chosen to avoid conflicts with standard AWS service ports and can be configured in the Moto server setup to match your environment.


5. **Move Back to Project Directory**

   Navigate back to the root of your project directory:

    ```bash
    cd ..
    ```
   Before we can create a Helm Chart, make sure Kubernetes is enabled in Docker Desktop. This can be done in Settings. Apply and restart for it to take effect. (Applicable for Windows users only)


6. **Create a Helm Chart**

   Create a new Helm chart for deploying the Moto server:

    ```bash
    helm create aws-simulation
    ```

   This command generates a basic Helm chart structure under the `aws-simulation` directory.


7. **Configure the Helm Chart**

   Edit the generated Helm chart files to configure the Moto server deployment. Specifically, update the `values.yaml` file with the following configuration:

    ```yaml
    replicaCount: 1

    image:
      repository: moto/moto_server
      tag: latest
      pullPolicy: Always

    service:
      type: NodePort
      port: 5000
      nodePort: 30500

    resources: {}
    ```

   The `values.yaml` configuration sets the Docker image for Moto, specifies a single replica for simplicity, and exposes the service on port 5000 internally with a NodePort of 30500 externally. The port 30500 is used to map the service from the Kubernetes cluster to your local machine, allowing Terraform and AWS CLI commands to interact with the Moto server as if it were a real DynamoDB instance.

   Also ensure `service.yaml` inside the `templates` folder reflects NodePort details as follows:

    ```yaml
    ports:
      - port: {{ .Values.service.port }}
        targetPort: http
        protocol: TCP
        nodePort: {{ .Values.service.nodePort }}
        name: http
    ```


8. **Install the Helm Chart**

   Install the Helm chart to deploy the Moto server in your Kubernetes cluster:

    ```bash
    helm install my-aws-simulation ./aws-simulation
    ```

   This command deploys the Helm chart to your Kubernetes cluster, setting up the Moto server as specified in the `values.yaml` configuration.


9. **Verify the Deployment**

   To confirm that the Moto server is running correctly, use the following `kubectl` commands:

   Check the status of pods:

    ```bash
    kubectl get pods
    ```

   Look for a pod related to the Moto server deployment and ensure its status is Running.

   Check the status of services:

    ```bash
    kubectl get services
    ```

   Verify that the Moto server service is listed and correctly configured to listen on port 30500.


10. **Deploy Terraform Configuration**

    Change directory to the `infrastructure` folder and run Terraform commands to deploy the configuration:

    ```bash
    cd infrastructure
    terraform init
    terraform apply
    ```

    Wait for the DynamoDB table and dummy data to be deployed. After the deployment is complete, you can visit `http://localhost:30500/moto-api/` and check the DynamoDB header to see the table details as provisioned by Terraform.


11. **Export AWS Credentials**

    To ensure the AWS CLI can access the Moto server without errors, export dummy AWS credentials:

    ```bash
    export AWS_ACCESS_KEY_ID=fakeaccesskey
    export AWS_SECRET_ACCESS_KEY=fakesecretkey
    ```


12. **Verify Dummy Data**

    Use the AWS CLI to scan the DynamoDB table and verify that the dummy data has been successfully added:

    ```bash
    aws dynamodb scan --table-name SampleTable --endpoint-url http://localhost:30500
    ```

    This command should return the dummy items you added in your Terraform configuration.

---

## Conclusion

By following the steps outlined above, you have successfully:

1. **Set Up a Local DynamoDB Simulation:**
   - Deployed a Moto server in a Kubernetes cluster using Helm, simulating AWS DynamoDB services on your local machine.

2. **Provisioned a DynamoDB Table:**
   - Created and configured a DynamoDB table (`SampleTable`) using Terraform, complete with attributes and provisioning settings.

3. **Inserted Dummy Data:**
   - Added sample data items to the DynamoDB table for testing purposes, ensuring that your local simulation mirrors typical AWS usage.

4. **Verified Configuration and Connectivity:**
   - Applied Terraform configurations and checked the Moto server to confirm that the DynamoDB table and data were correctly deployed and accessible.

5. **Configured AWS CLI for Local Testing:**
   - Set up environment variables to ensure the AWS CLI could interact with the simulated DynamoDB service without encountering credential errors.

This setup provides a fully operational local environment for testing and developing applications that interact with AWS DynamoDB. While this guide focuses on DynamoDB, the principles and techniques used can be applied to simulate other AWS services as well. This flexibility allows you to adapt your local testing environment to match various AWS services as needed.

Furthermore, you can integrate this setup into your company's CI/CD pipelines to automate the testing and validation of AWS resource interactions. By simulating AWS services locally, you can streamline your development process, reduce costs, and ensure that your applications are thoroughly tested in a controlled environment before deploying to actual AWS infrastructure. This approach not only speeds up your development cycle but also ensures that your application behaves as expected across different AWS services.

---

13. **Cleanup**

      When you are done testing, you can clean up your environment by destroying the Terraform resources and uninstalling the Helm chart:
      
      ```bash
      terraform destroy --auto-approve
      helm uninstall my-aws-simulation  
      ```

---