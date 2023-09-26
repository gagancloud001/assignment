#!/bin/bash

# Add Docker's official GPG key
echo "Adding Docker's official GPG key..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

if [ $? -ne 0 ]; then
    echo "Error adding Docker's GPG key. Exiting..."
    exit 1
fi

# Add the repository to Apt sources
echo "Adding Docker repository to Apt sources..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

if [ $? -ne 0 ]; then
    echo "Error adding Docker repository. Exiting..."
    exit 1
fi

# Install Docker packages
echo "Installing Docker packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

if [ $? -ne 0 ]; then
    echo "Error installing Docker packages. Exiting..."
    exit 1
fi

echo "Docker installation completed successfully."


# Create the /data folder
echo "Creating /data folder..."
sudo mkdir /data

if [ $? -ne 0 ]; then
    echo "Error creating /data folder. Exiting..."
    exit 1
fi

# Set permissions for the /data folder (optional)
# Adjust permissions as needed based on your use case
# For example, to give your user ownership of the /data folder:
# sudo chown -R $USER:$USER /data

echo "/data folder created successfully."


# Clone the GitHub repository into the /data folder
echo "Cloning the GitHub repository into /data..."
git clone https://github.com/flexsurfer/conduitrn.git /data/conduitrn

if [ $? -ne 0 ]; then
    echo "Error cloning the GitHub repository. Exiting..."
    exit 1
fi

echo "GitHub repository cloned successfully into /data/conduitrn."

# Change the working directory to the cloned repository
echo "Changing directory to /data/conduitrn..."
cd /data/conduitrn

if [ $? -ne 0 ]; then
    echo "Error changing directory. Exiting..."
    exit 1
fi

# Generate the Dockerfile inside the cloned repo
echo "Generating Dockerfile..."
cat <<EOL > Dockerfile
# Use an official Node.js runtime as a parent image
FROM node:14

# Install OpenJDK (Java)
RUN apt-get update && apt-get install -y openjdk-11-jre

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json (or npm-shrinkwrap.json) to the working directory
COPY package*.json ./

# Install project dependencies using yarn if a yarn.lock file exists, otherwise use npm
RUN if [ -f yarn.lock ]; then yarn; else npm install; fi

# Copy the rest of the application code into the container
COPY . .

# Expose the port your application will run on (adjust as needed)
EXPOSE 9630

# Define the command to start your application using yarn if a yarn script exists, otherwise use npm
CMD [ "sh", "-c", "if [ -f yarn.lock ]; then yarn dev; else npm run dev; fi" ]
EOL

# Build the Docker image with the name demo:v1
echo "Building Docker image..."
docker build -t demo:v1 .

if [ $? -ne 0 ]; then
    echo "Error building Docker image. Exiting..."
    exit 1
fi

echo "Docker image built successfully."

# Run the Docker container
echo "Running Docker container..."
docker run -it -d -p 80:9630 demo:v1

if [ $? -ne 0 ]; then
    echo "Error running Docker container. Exiting..."
    exit 1
fi

echo "Docker container is now running."
