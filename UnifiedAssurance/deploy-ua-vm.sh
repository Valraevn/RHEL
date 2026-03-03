#!/bin/bash

# Configuration Variables
VM_NAME="oracle8-ua-manager"
VCPUS=4
RAM_MB=8192
DISK_SIZE="100G"
IMAGE_DIR="/mnt/user/domains"
BASE_IMAGE_URL="https://yum.oracle.com/templates/OracleLinux/OL8/u9/x86_64/OL8U9_x86_64-kvm-b217.qcow2"
IMAGE_NAME="OL8-cloud-base.qcow2"

echo "Downloading Oracle Linux 8 Cloud Image..."
if [ ! -f "$IMAGE_DIR/$IMAGE_NAME" ]; then
    sudo wget -O $IMAGE_DIR/$IMAGE_NAME $BASE_IMAGE_URL
else
    echo "Base image already exists. Skipping download."
fi

echo "Creating VM specific disk and resizing to $DISK_SIZE..."
sudo cp $IMAGE_DIR/$IMAGE_NAME $IMAGE_DIR/${VM_NAME}.qcow2
sudo qemu-img resize $IMAGE_DIR/${VM_NAME}.qcow2 $DISK_SIZE

echo "Generating cloud-init seed ISO..."
sudo cloud-localds $IMAGE_DIR/${VM_NAME}-seed.qcow2 user-data meta-data

echo "Deploying VM via virt-install..."
sudo virt-install \
    --name $VM_NAME \
    --memory $RAM_MB \
    --vcpus $VCPUS \
    --os-variant rhel8.0 \
    --disk path=$IMAGE_DIR/${VM_NAME}.qcow2,device=disk,bus=virtio,format=qcow2 \
    --disk path=$IMAGE_DIR/${VM_NAME}-seed.qcow2,device=cdrom \
    --network network=default,model=virtio \
    --import \
    --noautoconsole

echo "Deployment initiated. Finding IP address (this may take a minute or two)..."
sleep 15
while true; do
    MAC=$(sudo virsh domiflist $VM_NAME | awk '/network/ {print $5}')
    IP=$(arp -an | grep $MAC | awk '{print $2}' | tr -d '()')
    if [ ! -z "$IP" ]; then
        echo "VM IP Address: $IP"
        echo "You can connect using: ssh uaadmin@$IP"
        break
    fi
    sleep 5
done
