-- Keep a log of any SQL queries you execute as you solve the mystery.
-- I'm begining by searching for a report of crime scene report for the date  July 28, 2020
SELECT description
FROM crime_scene_reports
WHERE month = 7 AND day = 28 AND street = 'Chamberlin Street';
-- Theft: When 10:15am, Where: courthouse, Chamberlin Street.
-- I Think I have 3 interviews with phraze "courthouse" and date July 28, 2020, Let's try to find it:
SELECT day, month, year, name, transcript FROM interviews
WHERE transcript LIKE '%courthouse%' AND day = 28 AND month = 7 AND year = 2020;
-- We have 3 witnesses: Ruth, Eugene, Raymond.
-- 1) Check security footage from the courthouse parking lot - 10 minuts after theft (10:25(+-) - seek cars.
-- I find some license_plate which may belong to the thief 1106N58 0NTHK55 322W7JE L93JTIZ G412CB7 4328GD8 6P58WS2 94KL13X 5P2BI95
SELECT hour, minute, activity, license_plate FROM courthouse_security_logs
WHERE year = 2020 AND month = 7 AND day = 28 AND hour = 10;
-- 2) Check the ATM on Fifer street (date July 28, 2020 - Morning before theft, withdraw money)
-- I found 8 accounts, who withdraw some money
SELECT account_number FROM atm_transactions
WHERE year = 2020 AND month = 7 AND day = 28 AND atm_location = 'Fifer Street' AND transaction_type = 'withdraw';

-- 3) 10:15am July 28 Thief called someone. Short call less than a minute.
SELECT caller, receiver, duration FROM phone_calls
WHERE year = 2020 AND month = 7 AND day = 28;
-- I firured out that durations fixed in seconds and I found out and made a clarifying request. 9 phone numbers matching the description were found
SELECT caller, receiver, duration FROM phone_calls
WHERE year = 2020 AND month = 7 AND day = 28 AND duration < 60;
-- 4)They planning flite out -  29-07-2020/ Earlist flight. Another person bought plane tickets
-- I found out that there is only 1 airport in the city. This is a regional airport, you can't fly to another country from it
SELECT full_name, city FROM airports
WHERE city = 'Fiftyville';
-- Figured out names and abbreviation all airports exclude Fiftyville
SELECT full_name, abbreviation  FROM airports
WHERE city != 'Fiftyville';
-- I will try to find earliest flight out of Fiftyville tomorrow. It is a 8.20am to airport with id4.
--It is a Heathrow Airport | London. It doesn't fit, becoase it is another country. Next flight - 9.30 to ORD | O'Hare International Airport | Chicago
-- next | SFO | San Francisco International Airport | San Francisco and | BOS | Logan International Airport | Boston
-- I think they flew to Chicago.
SELECT * FROM flights
JOIN airports
ON flights.origin_airport_id = airports.id
WHERE year = 2020 AND month = 7 AND day = 29
ORDER BY hour, minute;
-- I get the list of passengers on the flight. According to this request, 6 passport numbers were found.
SELECT passport_number FROM passengers
WHERE flight_id = 43;

-- It's time to compare the data and find the main suspects among the residents of the city
-- First, we will find out which of the people withdrew cash
SELECT name FROM people
WHERE id IN (
SELECT person_id FROM bank_accounts
WHERE account_number IN (
SELECT account_number FROM atm_transactions
WHERE year = 2020 AND month = 7 AND day = 28 AND atm_location = 'Fifer Street' AND transaction_type = 'withdraw'));
--Founded: 8 names Bobby, Elizabeth, Victoria, Madison, Roy, Danielle, Russell, Ernest

-- I find out the names of those who left the parking lot
SELECT name FROM people
WHERE license_plate IN (
SELECT license_plate FROM courthouse_security_logs
WHERE year = 2020 AND month = 7 AND day = 28 AND hour = 10 AND minute >= 15 AND minute <= 30 AND activity = 'exit');
-- Hm, 8 names and there are a lot of intersections Patrick, Amber, Elizabeth, Roger, Danielle, Russell, Evelyn, Ernest

-- I identify the people who called according to the testimony
SELECT name FROM people
WHERE phone_number IN (
SELECT caller FROM phone_calls
WHERE year = 2020 AND month = 7 AND day = 28 AND duration < 60);
---Result: Bobby, Roger, Victoria, Madison, Russell, Evelyn, Ernest, Kimberly

--My hypothesis that it is impossible to fly to other countries from the airport has not been confirmed. I wil Check earlest flight to  Heathrow Airport -  London
SELECT name FROM people
WHERE passport_number IN (
SELECT passport_number FROM passengers
WHERE flight_id = 36);
-- Bobby Roger Madison Danielle Evelyn Edward Ernest Doris

-- I compare all 4 results and determine who is everywhere.
-- I See Bobby - but he didn't was on parking
-- I See Roger - but he didn't withdraw money
SELECT name FROM people
WHERE name IN (
SELECT name FROM people
WHERE id IN (
SELECT person_id FROM bank_accounts
WHERE account_number IN (
SELECT account_number FROM atm_transactions
WHERE year = 2020 AND month = 7 AND day = 28 AND atm_location = 'Fifer Street' AND transaction_type = 'withdraw'))
INTERSECT
SELECT name FROM people
WHERE license_plate IN (
SELECT license_plate FROM courthouse_security_logs
WHERE year = 2020 AND month = 7 AND day = 28 AND hour = 10 AND minute >= 15 AND minute <= 30 AND activity = 'exit')
INTERSECT
SELECT name FROM people
WHERE passport_number IN (
SELECT passport_number FROM passengers
WHERE flight_id = 36)
INTERSECT
SELECT name FROM people
WHERE phone_number IN (
SELECT caller FROM phone_calls
WHERE year = 2020 AND month = 7 AND day = 28 AND duration  < 60)
);
-- Ernest - - Full hit. The only one who is present at all inspections

-- Find receiver
SELECT name
FROM people
JOIN phone_calls
ON people.phone_number = phone_calls.receiver
WHERE  year = 2020 AND month = 7 AND day = 28 AND duration  < 60 AND caller = (
SELECT phone_number FROM people
WHERE name = 'Ernest'
);
--Berthold is an accomplice