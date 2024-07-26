#!/bin/bash

# generate a random number between _1_ and _1000_ for users to guess

PSQL="psql --username=postgres --dbname=number_guess -t --no-align -c"

SECRET_NUMBER=$(( 1 + $RANDOM % 1000 ))
GUESSES=0
username=""

while [[ -z $username ]]
do
  echo "Enter your username:"
  read username
done

# search for '$username' into the database
USERNAME_RESULT=$($PSQL "SELECT username FROM usernames WHERE username = '$username';")

# if it find
if [[ ! -z $USERNAME_RESULT ]]
then
  # it collect the others data
  DATA_RESULT=$($PSQL "
    SELECT COUNT(*), MIN(guesses)
    FROM games AS g
    FULL JOIN usernames AS u
    ON g.username_id = u.username_id
    WHERE u.username = '$USERNAME_RESULT';
  ")
  read GAMES_PLAYED BEST_GAME <<< $(echo $DATA_RESULT | sed 's/[|]/ /g')
  # and say a salutation to the user
  echo "Welcome back, $USERNAME_RESULT! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
else
  # else greet the new user
  echo Welcome, $username! It looks like this is your first time here.
fi

# and start the game
echo Guess the secret number between 1 and 1000:
read GUESS
GUESSES=$(( $GUESSES + 1 ))

# compare $GUESS with $SECRET_NUMBER until GUESS is right
while [[ $GUESS -ne $SECRET_NUMBER ]]
do
  # check for the $GUESS type (only integer numbers)
  if [[ ! $GUESS =~ ^[1-9][0-9]*$ ]]
  then
    echo That is not an integer, guess again:
  fi
  
  # check if greater
  if [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo It\'s lower than that, guess again:
  fi

  # or lower
  if [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    echo It\'s higher than that, guess again:
  fi

  read GUESS
  GUESSES=$(( $GUESSES + 1 ))
done

# right guess: save data into the db
# save username IF NOT PRESENT
if [[ -z $USERNAME_RESULT ]]
then
  SAVE_RESULT=$($PSQL "INSERT INTO usernames (username) VALUES ('$username');")
fi
# get username_id to save the game
USERNAME_ID=$($PSQL "
  SELECT username_id
  FROM usernames
  WHERE username = '$username';
")
# save game data
SAVE_RESULT=$($PSQL "
  INSERT INTO games
  (username_id, guesses, secret_number)
  VALUES
  ($USERNAME_ID, $GUESSES, $SECRET_NUMBER)
")
echo You guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!

exit 0