// config/db.js
const mongoose = require('mongoose');

// Connection URI - Points to your local MongoDB instance using loopback IP
const MONGO_URI = 'mongodb://127.0.0.1:27017/dart_pos_system';

const connectDB = async () => {
    try {
        // Attempt an asynchronous connection to the MongoDB engine
        // Deprecated options removed; Mongoose now manages topology and parsing natively
        const conn = await mongoose.connect(MONGO_URI);

        console.log(`=== MongoDB Connected Successfully: ${conn.connection.host} ===`);
    } catch (error) {
        console.error(`!!! Database Connection Failure: ${error.message} !!!`);
        // Exit the backend system execution loop if the database fails to link
        process.exit(1);
    }
};

module.exports = connectDB;