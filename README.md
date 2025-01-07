# GitHubAction-Integration-ECS

## Step-1
First create a private ECR repo
Save the URI of the ECR repo in a note pad.

## Step-2
### Then Create a task difinition:
1. Give task definition family name and then save the name in a note pad.
2. Launch type is amazon EC2 instance --> Linux/X86_64.
3. Network mode Bridge / Default.
4. cpu - 256 & Memory - 300
5. ecsTaskExecution role (Attach policies: AmazonECSTaskExecutionRolePolicy, and AmazonEC2ContainerServiceforEC2Role) with use case as "ecs-tasks"
The Trust relationships are as follows:
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}

Put the same IAM role in the 2 options here asking for IAM roles.

### 6. Container details:
Give the name of the container and save it in the note pad.
Then paste the Repo URI
Later Don't give the Host port, if we provide the host port, it will create an error in the 2nd deplyment onwards saying port is already occupied.
An arbitrary host post will be selected automaticaaly when the script runs.
Then uncheck the logging options if not needed.
others keep default.

7. Then Finally create the task-definition

8. Save the jasonfile of the task definition in your .github/workflow/ path and edit the image part of the jason file with uri folloed by ":GIT_Commit" as shown bellow:

"image": "793229168581.dkr.ecr.us-east-1.amazonaws.com/demoproject:GIT_COMMIT",

### Step-3
Now create a Dummy Target group with out any targets, and also Create a default Application Load balancer by using this Dummy target group. After the LOad balancer gets provisioned, just save the DNS and save in a note pad.

### Step-4
Now create an ECS cluster with EC2 based launching system, and in the autoiiscaling group create a new one
with Amazon Linux 2 or any other, then Instance type as needed, and others as required.
In networking select the security group which opens all the ports for not facing any error or else dafault can be kept as no host port has been given.

### Step-5
After the Cluster comes in Active state create a service inside the cluster
    Select Capacity Provider Strategy --> Use cluster default
    Select service, select task-definition family name. let the revision takes automatically.
    Then select for replica, if it is a normal container, if you need one at each node, then go for daemon
    Put the number of replica as "0". The number will be fetched from the sample.yaml file as given in the RUNNING_COUNT (there you can change as per your need)
    Then Go for load-balancing option and select Application Load balancer and target group that we created in the step 3.

### Step-6
Edit the sample.yaml file with the ECR repo URI
then Check the Region in the whole script.
Then edit the Service name, task family name, cluster name as per the need.
Then check the Task-definition.json file as well as we copied from the Console.
Then push the change in the branch as mentioned in the sample.yml file and before that don't forget to add or check the secrets in the GitHub-Repo settings.
