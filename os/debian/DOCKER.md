# Installing Docker on Debian

Quick reference for installing Docker Engine + Docker Compose on a fresh Debian install, using Docker's official repository (more up to date than Debian's default repos).

Just copy-paste each block into your terminal, one at a time.

## 1. Install dependencies

```bash
# Refresh the list of available packages
sudo apt update

# Install tools needed to securely download and verify Docker's packages
sudo apt install ca-certificates curl gnupg -y
```

## 2. Add Docker's official GPG key

```bash
# Create the folder where trusted package signing keys are stored
sudo install -m 0755 -d /etc/apt/keyrings

# Download Docker's official signing key, to verify packages really come from Docker
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc

# Make the key file readable so apt can use it
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

## 3. Add Docker's repository

```bash
# Tell apt where to find Docker's packages, matched to your system automatically
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

## 4. Install Docker

```bash
# Refresh the package list again, now including Docker's repository
sudo apt update

# Install Docker, its CLI, the container runtime, and docker compose
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

## 5. Verify it works

```bash
# Download and run a tiny test container — should print "Hello from Docker!"
sudo docker run hello-world
```
