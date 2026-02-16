#!/bin/shell

user=$(id -u)
logs_folder="/var/log/roboshop"
log_file="$logs_folder/$0.log"
command_type=$1
start_time=$(date +%s)
Working_dir="/home/ec2-user"

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

dnf install python3 gcc python3-devel -y &>> $log_file
VALIDATE $? "python3 gcc python3-devel installation"

id roboshop &>> $log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop 
    VALIDATE $? "adding user" &>> $log_file
else
    echo "Roboshop user already exists"
fi

mkdir -p /app 


curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>> $log_file
cd /app

rm -rf /app/*

unzip /tmp/payment.zip &>> $log_file

pip3 install -r requirements.txt &>> $log_file

cp $Working_dir/Roboshop/payment.service /etc/systemd/system/payment.service

systemctl daemon-reload

systemctl enable payment &>> $log_file

systemctl start payment &>> $log_file
VALIDATE $? "payment enabled ... started"

systemctl restart payment &>> $log_file
VALIDATE $? "payment restart"



end_time=$(date +%s)
final_time=$(($end_time - $start_time))
echo "script executed at $final_time"