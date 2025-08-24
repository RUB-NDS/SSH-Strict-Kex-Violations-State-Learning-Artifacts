#!/bin/bash

echo "Flag order: host, port, user, password, command, print_output, print_error"
host=$1
port=$2
user=$3
password=$4
command=$5
print_output=$6
print_error=$7

if [ -z "$host" ]
then
      host="127.0.0.1"
fi

if [ -z "$port" ]
then
      port=22
fi

if [ -z "$user" ]
then
      user="sshattacker"
fi

if [ -z "$password" ]
then
      password="secret"
fi


if [ -z "$command" ]
then
      command="test"
fi

parameter="--host $host -P $port -u $user -p $password -c $command"

if [ "$print_output" == "true"  ]
then
      parameter+=" -o"
fi

if [ "$print_error" == "true"  ]
then
      parameter+=" -e"
fi

expect /usr/local/bin/login.exp $host $ip $port $user $password $command
exit 0
