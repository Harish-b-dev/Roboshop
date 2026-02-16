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
        echo -e "$G $2 $N ... success" | tee -a $log_file
    fi
}

cp $Working_dir/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo

dnf install rabbitmq-server -y
VALIDATE $? "Installing ... rabbitmq-server"

systemctl enable rabbitmq-server
VALIDATE $? "rabbitmq-server enable"

systemctl start rabbitmq-server
VALIDATE $? "rabbitmq-server start"

sudo rabbitmqctl authenticate_user guest guest

if [ $? -eq 0 ]; then
    echo -e "rabbitmq-server user name and password is not changed ... $B changing $Y"
    rabbitmqctl add_user roboshop roboshop123
    VALIDATE $? "rabbitmq-server user name and password update"

    rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
    VALIDATE $? "rabbitmq-server permissions set up"

else
    echo "$Y Skipping ... user name, password, permissions $N set up are already updated in rabbitmq-server"

fi