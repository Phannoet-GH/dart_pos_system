const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    username: {
        type: String,
        required: [true, 'Username is required'],
        unique: true,
        trim: true
    },
    password: {
        type: String,
        required: [true, 'Password is required']
    },
    role: {
        type: String,
        required: [true, 'Role is required'],
        enum: ['Admin', 'Sale'] // Restricts input to only these two roles
    }
}, { versionKey: false }); // Disables the __v field for cleaner JSON responses in Dart

module.exports = mongoose.model('User', UserSchema, 'users');