#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo -e "\nEnter your username:"
read USERNAME

if [[ -z $USERNAME || $USERNAME =~ ^[0-9]+$ ]]
then
  echo "Please enter a username"
  exit
fi

RESULT=( $( $PSQL "INSERT INTO players(username) values ('$USERNAME') ON CONFLICT (username) DO UPDATE SET username = EXCLUDED.username RETURNING player_id, played, best;" ) )
PLAYER_INFO=(${RESULT//|/ })

PLAYER_ID=${PLAYER_INFO[0]}
PLAYED=${PLAYER_INFO[1]}
BEST=${PLAYER_INFO[2]}

if [[ PLAYED -eq 0 ]]
then
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
else
  echo -e "\nWelcome back, $USERNAME! You have played $PLAYED games, and your best game took $BEST guesses."
fi


NUMBER=$(( RANDOM % 1000 + 1 ))

GUESS() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  read GUESSED_NUMBER

  (( GUESSED_COUNTER++ ))

  if [[ ! $GUESSED_NUMBER || ! $GUESSED_NUMBER =~ ^[0-9]+$ ]]
  then
    GUESS "That is not an integer, guess again:"
    return 1
  fi

  if [[ $NUMBER < $GUESSED_NUMBER ]]
  then
    GUESS "It's lower than that, guess again:"
    return 1
  fi

  if [[ $NUMBER > $GUESSED_NUMBER ]]
  then
    GUESS "It's higher than that, guess again:"
    return 1
  fi

  echo -e "\nYou guessed it in $GUESSED_COUNTER tries. The secret number was $NUMBER. Nice job!"
}

GUESS "Guess the secret number between 1 and 1000:"

if [[ $BEST == 0 || $GUESSED_COUNTER < $BEST ]]
then
  BEST=$GUESSED_COUNTER
fi

(( PLAYED++ ))

RESULT=$($PSQL "UPDATE players SET played=$PLAYED, best=$BEST WHERE username='$USERNAME'")
