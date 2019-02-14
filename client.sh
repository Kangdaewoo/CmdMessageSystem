#!/bin/bash

SERVER='http://localhost:8888'
CURL_OPT='-s'
NAME=''

get_field () {
    echo $(echo $1 | grep -Po $(echo "\"$2\":.*}") | cut -d '"' -f 4)
}

send_request () {
    echo $(curl $CURL_OPT --header Content-Type:application/json \
        --request POST \
        --data "{\"$1\":\"$2\"}" \
        ${SERVER}/name)
}

set_up () {
    response=$(curl $CURL_OPT ${SERVER}/)
    if [ $? -eq 7 ] 
    then
        echo 'Server is down.\nPlease try again later.'
        exit
    fi
    echo $(get_field "$response" message)

    succeeded=false
    while [ $succeeded = false ]
    do
        read name
        response=$(send_request name "$name")
        echo $(get_field "$response" message)
        succeeded=$(get_field "$response" success)
    done
    NAME=$name
}

send_message () {
    echo $(curl $CURL_OPT --header Content-Type:application/json \
        --request POST \
        --data "{\"to\":\"$1\",\"message\":\"$2\"}" \
        ${SERVER}/${NAME}/message)
}

print_messages () {
    messages=$(echo $1 | grep -Po $(echo "\"messages\":\[.*\]") | cut -d ':' -f '2-')

    if [ "$messages" = "[]" ] 
    then
        return 0
    fi

    result=''
    message=$(echo $messages | cut -d '}' -f 1)
    rest="$messages"
    while [ "$message" != \] ]
    do
        result="${result}\n$(echo $message | cut -d '"' -f 4): $(echo $message | cut -d '"' -f 8)"
        rest=$(echo $rest | cut -d '}' -f '2-')
        message=$(echo $rest | cut -d '}' -f 1)
    done
    echo $result
}

load_messages () {
    while : 
    do
        response=`curl $CURL_OPT ${SERVER}/${NAME}/message`
        print_messages "$response"
        
        sleep 1
    done
}

logout () {
    echo $(curl $CURL_OPT \
        ${SERVER}/${NAME}/logout)
}

set_up
load_messages &
LOADER=$!

while :
do
    echo 'To?'
    read name

    if [ -z "$name" ] 
    then
        while :
        do
            echo 'Exit? (y/n)'
            read answer
            if [ "$answer" = y ]
            then
                kill '-9' $LOADER
                response=$(logout)
                echo $(get_field "$response" message)
                exit
            else
                break
            fi
        done
        continue
    fi

    echo "${name}: "
    read message

    response=$(send_message "$name" "$message")
    echo $(get_field "$response" message)
done