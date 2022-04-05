#!/bin/bash

# Install curl and apt-transport-https
sudo apt install apt-transport-https curl

# Add Kubernetes signing key
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add

# Add Kubernetes repository
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> ~/kubernetes.list
sudo mv ~/kubernetes.list /etc/apt/sources.list.d

# Update the servers
sudo apt update

# Install kubeadm, kubelet, kubectl, and kubernetes-cni
sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni
# Verify installation:
kubectl version --client && kubeadm version

# Disable Swap Memory
sudo swapoff -a
sudo nano /etc/fstab # comment out swapfile line (if any)

# Setup unique hostname
sudo hostnamectl set-hostname kube-master
hostname

# Enable Bridge Traffic in IP Tables
sudo modprobe br_netfilter
sudo sysctl net.bridge.bridge-nf-call-iptables=1


# Setup Docker runtime and run with systemd
sudo apt update
sudo apt install -y gnupg2 apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
apt-cache policy docker-ce # confinm you are installing from the Docker repo instead of the default Ubuntu repo
sudo apt install -y containerd.io docker-ce docker-ce-cli

# Create required directory for docker service
sudo mkdir -p /etc/systemd/system/docker.service.d

# Create daemon json config file
sudo tee /etc/docker/daemon.json <<EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m"
    },
    "storage-driver": "overlay2"
}
EOF

# Start and enable services
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker

# Initialize Kubernetes Master Node
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 

The above command will output this:
``
Your Kubernetes control-plane has initialized successfully!

***
To start using your cluster, you need to run the following as a regular user:        

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

***
kubeadm join MASTER_IP:6443 --token joucxv.1yf5uhcrfkp0w3co \
--discovery-token-ca-cert-hash sha256:710b9bfa224be042e33dfec82055da99b02a86ae48541f829934ad0fab52cfb6
``

# Allow kubernetes port
sudo ufw allow 6443
sudo ufw allow 6443/tcp

# Setup Kubernetes pod networking with Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml
# Check Status
kubectl get pods --all-namespaces

# check component's health/status
kubectl get componentstatus (or kubectl get cs)

# Bonus if you forgot to copy the join token generated from the master node, we can solve that by creating a token from the master node
sudo kubeadm token create --print-join-command # Run the output of this command with sudo
