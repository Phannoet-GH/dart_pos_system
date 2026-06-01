const mongoose = require('mongoose');

// Define a sub-schema for individual line items inside the order array
const OrderItemSchema = new mongoose.Schema({
    product_id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product',
        required: true
    },
    quantity: {
        type: Number,
        required: true,
        min: [1, 'Quantity must be at least 1']
    },
    price_at_sale: {
        type: Number,
        required: true // Captures price history snapshot safely
    }
}, { _id: false }); // Prevents mongoose from creating an implicit _id for every sub-item

const OrderSchema = new mongoose.Schema({
    order_date: {
        type: Date,
        default: Date.now // Automatically stamps the exact time of purchase
    },
    sold_by: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    total_price: {
        type: Number,
        required: true
    },
    items: [OrderItemSchema] // Embeds the array stack directly into the document
}, { versionKey: false });

module.exports = mongoose.model('Order', OrderSchema, 'orders');