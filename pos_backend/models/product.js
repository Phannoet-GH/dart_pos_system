const mongoose = require('mongoose');

const ProductSchema = new mongoose.Schema({
    title: {
        type: String,
        required: [true, 'Product title is required'],
        trim: true
    },
    price: {
        type: Number,
        required: [true, 'Product price is required']
    },
    stock_quantity: {
        type: Number,
        required: [true, 'Stock quantity is required'],
        min: [0, 'Stock cannot be negative']
    },
    category_id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category', // Links dynamically to our Category model
        required: [true, 'Category reference ID is required']
    }
}, { versionKey: false });

module.exports = mongoose.model('Product', ProductSchema, 'products');