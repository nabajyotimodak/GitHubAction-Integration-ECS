# GitHubAction-Integration-ECS



name: Master Deployment

on:
  push:
    branches:
      - development

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
         
         
      - name: Determine branch name
        id: set-branch-name
        run: |
          if [[ "${{ github.ref }}" == "refs/heads/development" ]]; then
            echo "BRANCH_NAME=development" >> $GITHUB_ENV
          else
            echo "Invalid branch. Deployment aborted."
            exit 1
          fi
         
      - name: Build Docker image
        run: |
          docker build -t gitactions-ecs:${{ env.BRANCH_NAME }}-${{ github.run_number }} .
          docker tag gitactions-ecs:${{ env.BRANCH_NAME }}-${{ github.run_number }} 793229168581.dkr.ecr.us-east-1.amazonaws.com/demo-ecr-repo:${{ env.BRANCH_NAME }}-${{ github.run_number }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Push Docker image to Amazon ECR
        run: |
          docker push 793229168581.dkr.ecr.us-east-1.amazonaws.com/demo-deploy:${{ env.BRANCH_NAME }}-${{ github.run_number }}
      - name: Deploy to ECS
        run: |
             
             startECSDeploy() {
              # Command to create new td.
               sed -e "s;GIT_COMMIT;${IMAGE_VERSION};g" ${JSON_FILE}.json > ${JSON_FILE}-new-${{ github.run_number }}.json
               sed -e "s;task_role;${TASK_ROLE};g" ${JSON_FILE}-new-${{ github.run_number }}.json > ${JSON_FILE}-${{ github.run_number }}.json
               cat ${JSON_FILE}-${{ github.run_number }}.json

              aws ecs register-task-definition --family ${TASK_FAMILY} --cli-input-json file://${JSON_FILE}-${{ github.run_number }}.json --region us-east-1

             # Updating the service.
             TASK_REVISION=$(aws ecs describe-task-definition --task-definition ${TASK_FAMILY} --region us-east-1 --query "taskDefinition.revision" --output text)
             echo $TASK_REVISION
             DESIRED_COUNT=$(aws ecs describe-services --cluster ${CLUSTER} --services ${SERVICE_NAME} --region us-east-1 --query "services[0].desiredCount" --output text)
             echo $DESIRED_COUNT

             OLD_TASK_ID=$(aws ecs list-tasks --cluster ${CLUSTER} --desired-status RUNNING --family ${TASK_FAMILY} --region us-east-1 --query "taskArns[0]" --output text)
             echo $OLD_TASK_ID
            

             aws ecs update-service --cluster ${CLUSTER} --service ${SERVICE_NAME} --desired-count ${RUNNING_COUNT} --task-definition ${TASK_FAMILY}:${TASK_REVISION} --force-new-deployment --region us-east-1

             #Waiting for the service to be available in the cluster.
             aws ecs wait services-stable --cluster ${CLUSTER} --services ${SERVICE_NAME} --region us-east-1

             if [ $? -eq 0 ]; then
                echo "Build got deployed successfully"
             else
             echo "Build failed"
             exit 1
             fi
             rm -rf ${JSON_FILE}-${{ github.run_number }}.json
              }


             if [ "${{ github.ref }}" == "refs/heads/development" ]; then
             SERVICE_NAME="demo-deploy"
             IMAGE_VERSION="${{ env.BRANCH_NAME }}-${{ github.run_number }}"
             TASK_FAMILY="demo-deploy"
             CLUSTER="demo-deploy"
             TASK_ROLE="ecsTaskExecutionRole"
             JSON_FILE=".github/workflows/task-definition"
             RUNNING_COUNT=1
             startECSDeploy
             else
                  echo "Skipping deployment"
             fi