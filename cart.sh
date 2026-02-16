#!/bin/shell

user=$(id -u)
logs_folder="/var/log/roboshop"
log_file="$logs_folder/$0.log"
command_type=$1
start_time=$(date +%s)
Working_dir="/home/ec2-user"
Mongodb_host="mongodb.learndaws88s.online"

#set -e
#trap 'echo "there is an error at $LINENO, command :: $BASH_COMMAND"' ERR

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


dnf module disable nodejs -y &>> $log_file
VALIDATE $? "nodejs disabled"

dnf module enable nodejs:20 -y &>> $log_file
VALIDATE $? "nodejs version 20 enabled"

dnf install nodejs -y&>> $log_file
VALIDATE $? "nodejs installed"

id roboshop &>> $log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop 
    VALIDATE $? "adding user"
else
    echo "Roboshop user already exists"
fi

mkdir -p /app 


curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>> $log_file
cd /app

rm -rf /app/*

unzip /tmp/cart.zip &>> $log_file

npm install &>> $log_file

cp $Working_dir/Roboshop/cart.service /etc/systemd/system/cart.service

systemctl daemon-reload

systemctl enable cart &>> $log_file

systemctl start cart &>> $log_file
VALIDATE $? "cart enabled ... started"

systemctl restart cart &>> $log_file
VALIDATE $? "cart restart"



end_time=$(date +%s)
final_time=$(($end_time - $start_time))
echo "script executed at $final_time"