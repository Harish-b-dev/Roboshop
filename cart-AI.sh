#!/bin/bash

# 1. Setup Variables
user=$(id -u)
script_name=$(basename "$0")
logs_folder="/var/log/roboshop"
log_file="$logs_folder/$script_name.log"
Working_dir="/home/ec2-user/Roboshop" # Ensure this path is correct

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# 2. Pre-checks
sudo mkdir -p $logs_folder
sudo chown ec2-user:ec2-user $logs_folder

if [ $user -ne 0 ]; then 
    echo -e "You need ${Y}sudo access${N} to install packages." | tee -a $log_file
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "${R}$2 ... failure${N}" | tee -a $log_file
        exit 1
    else
        echo -e "${G}$2 ... success${N}" | tee -a $log_file
    fi
}

echo -e "Cart script execution started..." | tee -a $log_file

# 3. Install NodeJS
dnf module disable nodejs -y &>> $log_file
dnf module enable nodejs:20 -y &>> $log_file
dnf install nodejs -y &>> $log_file
VALIDATE $? "NodeJS installation"

# 4. Handle System User
id roboshop &>> $log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin roboshop 
    VALIDATE $? "Adding roboshop user"
else
    echo -e "User roboshop ${Y}already exists${N}. Skipping."
fi

# 5. Application Setup
mkdir -p /app 
curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>> $log_file
VALIDATE $? "Downloading Cart artifacts"

cd /app
rm -rf /app/*
unzip /tmp/cart.zip &>> $log_file
VALIDATE $? "Unzipping Cart"

# 6. NPM Install & Permissions (CRITICAL)
npm install &>> $log_file
VALIDATE $? "NPM dependencies installation"

# Ensure the roboshop user owns the app files
chown -R roboshop:roboshop /app
VALIDATE $? "Setting /app permissions"

# 7. Systemd Service Setup
cp $Working_dir/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Copying cart.service"

systemctl daemon-reload
systemctl enable cart &>> $log_file
systemctl restart cart &>> $log_file
VALIDATE $? "Cart service start/restart"

echo "Script completed successfully."
