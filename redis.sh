#!/bin/shell

user=$(id -u)
logs_folder="/var/log/roboshop"
log_file="$logs_folder/$0.log"
command_type=$1
start_time=$(date +%s)
Working_dir="/home/ec2-user/Roboshop"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

echo -e " script execution started now ... $B $command_type $N"

sudo mkdir -p $logs_folder


if [ $user -ne 0 ]; then 
     echo -e  "You need $Y sudo access $N to install packages." | tee -a $log_file
    exit 1

fi


VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$R $2 $N ... failure " | tee -a $log_file
        exit 1
    else
        echo -e "$2 ... success" | tee -a $log_file
    fi
}


dnf list installed redis
if [ $? -ne 0 ]; then
    dnf module disable redis -y
    dnf module enable redis:7 -y
    dnf install redis -y 
    VALIDATE $? "redis version 7 ... installation"

else
    echo -e "redis is already installed ... $Y skipping $N" | tee -a $log_file


sed -i '/s/127.0.0.1/0.0.0.0/g'

systemctl enable redis &>> $log_file
systemctl start redis &>> $log_file
VALIDATE $? "redis enabled and started"
