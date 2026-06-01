const mongoose = require('mongoose');

const CategorySchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'Category name is required'],
        trim: true
    }
}, { versionKey: false });

module.exports = mongoose.model('Category', CategorySchema, 'categories');