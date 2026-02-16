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

dnf list installed nginx &>> $log_file
if [ $? -ne 0 ]; then
    #dnf module disable nginx -y &>> $log_file
    #dnf module enable nginx:1.24 -y &>> $log_file
    dnf module install nginx:1.24 -y &>> $log_file
    VALIDATE $? "Nginx version 1.24 ... installation"

else
    echo -e "nginx is already installed ... $Y skipping $N" | tee -a $log_file

fi

systemctl enable nginx
systemctl start nginx
VALIDATE $? "Nginx enabled and started"

#rm -rf /usr/share/nginx/html/*
#
#curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $log_file
#
#cd /usr/share/nginx/html
#unzip /tmp/frontend.zip
#VALIDATE $? "Nginx page unziped"
#
#rm -rf /etc/nginx/nginx.conf
#
#cp $Working_dir/nginx.conf /etc/nginx/nginx.conf
#VALIDATE $? "nginx.conf updated" &>> $log_file
#
#systemctl restart nginx
#VALIDATE $? "Nginx restart"

end_time=$(date +%s)
final_time=$(($end_time - $start_time))
echo "script executed at $final_time"