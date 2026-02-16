#!/bin/shell

user=$(id -u)
logs_folder="/var/log/roboshop"
log_file="$logs_folder/$0.log"
command_type=$1
start_time=$(date +%s)

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

dnf install mysql-server -y &>> $log_file
VALIDATE $? "Mysql server ... installation"

systemctl enable mysqld
VALIDATE $? "Mysql server ... enable" 

systemctl start mysqld 
VALIDATE $? "Mysql server ... start" 


mysql_secure_installation --set-root-pass RoboShop@1

#!/bin/bash

# Attempt to log in to MySQL root with NO password
# -e "exit" immediately quits after a successful connection
#mysql -u root --skip-RoboShop@1 -e "exit" &> /dev/null

#if [ $? -eq 0 ]; then
#    echo "STATUS: MySQL root password is still EMPTY (or NOT set)."
#else
#    echo "STATUS: MySQL root password is SET (Access Denied for empty password)."
#fi
