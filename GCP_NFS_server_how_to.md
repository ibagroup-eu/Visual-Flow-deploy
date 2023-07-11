## Steps to create NFS on Google Cloud Platform (GCP):

1. Create a Virtual Machine (VM) on GCP
     ```bash
     gcloud compute instances create vf-nfs-server \
     --boot-disk-size=20GB \
     --image=ubuntu-minimal-2204-jammy-v20230617 \
     --image-project=ubuntu-os-cloud \
     --machine-type=f1-micro \
     --tags=vf-nfs \
     --zone=us-central1-b
     ``` 

2. Connect via SSH. press yes for everything if asked about different zone press `n`, so it autodetects your vm zone
     ```bash
     gcloud compute ssh vf-nfs-server
     ```

3. Install NFS (inside VM)
     ```bash
     sudo apt update
     sudo apt install -y nfs-kernel-server
     ```

4. Create a folder for share
     ```bash
     sudo mkdir /share
     sudo chown nobody:nogroup /share
     sudo chmod 777 /share
     ```

5. Add this foulder to nfs exports

     Install vim (or any other tool for text edit) on your VM
     ```bash
     sudo apt install -y vim
     ```

     Edit exports
     ```bash
     sudo vim /etc/exports
     ```

     Add the next line to /etc/exports
     ```bash
     /share *(rw,sync,no_subtree_check)
     ```

7. Restart nfs-kernel-server
     ```bash
     sudo systemctl restart nfs-kernel-server
     ```
     
     Confirm the directory is being shared
     ```bash
     sudo exportfs
     ```
     Output should be like `/share world`.
   
     Done, log out from the machine
     ```bash
     exit
     ```

8. *(Optional)* if you want to use NFS outside of your google project. Add firewall rules
     ```bash
     gcloud compute firewall-rules create nfs \
     --allow=tcp:111,udp:111,tcp:2049,udp:2049 --target-tags=nfs
     ```
