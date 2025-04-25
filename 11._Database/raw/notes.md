

# databases

## drivers

def: access to databases

fx.
- sqlite3
- jdbc

## sqlite



## DDL - Data Definition Language


example with sqlite3

```sqlite 
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER NOT NULL
);
```

```sqlite 
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER NOT NULL
);
```

games and game_types
```sqlite 
CREATE TABLE IF NOT EXISTS games (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    game_type_id INTEGER NOT NULL,
    FOREIGN KEY (game_type_id) REFERENCES game_types(id)
);

CREATE TABLE IF NOT EXISTS game_types (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);
```

js variables with sqlite queries

```js 
import sqlite3 from 'sqlite3';
import { open } from 'sqlite';
import { Database } from 'sqlite3';

const db = await open({
    filename: 'database.db',
    driver: sqlite3.Database
});

const createUsersTable = `
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER NOT NULL
);
`;

const createGamesTable = `
CREATE TABLE IF NOT EXISTS games (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    game_type_id INTEGER NOT NULL,
    FOREIGN KEY (game_type_id) REFERENCES game_types(id)
);
`;

// Create the tables
await db.exec(createUsersTable);
await db.exec(createGamesTable);

// Insert some data 
const insertUser = `
INSERT INTO users (name, age) VALUES (?, ?)`;

const insertGame = `
INSERT INTO games (name, game_type_id) VALUES (?, ?)`;
const user = { name: 'John Doe', age: 30 };
const game = { name: 'Chess', game_type_id: 1 };
await db.run(insertUser, [user.name, user.age]);



## package.json scripts

```json
{
  "scripts": {
    "create-db": "sqlite3 database.db < create_tables.sql",
    "insert-data": "sqlite3 database.db < insert_data.sql",
    "query-data": "sqlite3 database.db < query_data.sql"
  }
}

    "setupDB": "node ./database/setup.js",
    "resetDB": "node ./database/setup.js delete",

```


### args in terminal 


    "resetDB": "node ./database/setup.js --delete",

args in terminal 

    node, ./database/setup.js, --delete 


# Aynchronous

JavaScript is single-threaded, everthing runs on the main-thread

- single-threaded: 
  - only one thing can happen at a time
  - no parallelism
  - no concurrency

- main-thread 
  runs: 
  - JavaScript code
  - event loop
  - DOM
  - UI

- event-loop
  explanation: 
  - event loop is a queue of tasks that are waiting to be executed
  - it creates a loop that checks if there are any tasks in the queue
  makes 
  - JavaScript non-blocking

## evolution of js for asynchronous

use cases where non-blocking is needed
- database queries
- file handling
- network requests (HTTP, Fetch, WebSocket)
- user input

### first solution: Callback functions

- solved by: 
    - callback functions
        - functions that are passed as arguments to other functions

- problem:
    - callback hell
    - difficult to read and maintain
    - difficult to handle errors
    - difficult to handle multiple asynchronous tasks

### second solution: Promises (syntactactic sugar for callbacks)
- solved by: 
    - promises
        - objects that represent the eventual completion (or failure) of an asynchronous operation
        - can be in one of three states: pending, fulfilled, rejected
        - can be chained together
        - can be used with async/await

```JavaScript 
new Promise((resolve, reject) => {
    setTimeout(() => {
        resolve('Success');
    }, 1000);
})
.then(result => {
    console.log(result); // Success
})

// const of promise with success and error
const promise = new Promise((resolve, reject) => {
    // do something asynchronous
    if (success) {
        resolve(result);
    } else {
        reject(error);
    }
});






