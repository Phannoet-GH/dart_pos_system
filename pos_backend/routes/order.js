const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const Product = require('../models/Product');

// @route   POST /api/orders/checkout
// @desc    Create a new transaction order and deduct inventory stock balances
router.post('/checkout', async (req, res) => {
    const { sold_by, total_price, items } = req.body;

    try {
        if (!items || items.length === 0) {
            return res.status(400).json({ message: 'Cannot checkout an empty shopping cart' });
        }

        // 1. Operational Check: Loop to verify database stocks safely BEFORE making changes
        for (let item of items) {
            const product = await Product.findById(item.product_id);
            if (!product) {
                return res.status(404).json({ message: `Product reference ${item.product_id} is invalid` });
            }
            if (product.stock_quantity < item.quantity) {
                return res.status(400).json({ message: `Insufficient stock balance for: ${product.title}` });
            }
        }

        // 2. Update step: Deduct items from products stock quantities safely
        for (let item of items) {
            await Product.findByIdAndUpdate(item.product_id, {
                $inc: { stock_quantity: -item.quantity }
            });
        }

        // 3. Normalization Mapping: Ensure names align exactly with your Mongoose schema properties
        // If your Mongoose schema uses 'order_items' instead of 'items', change the property key below to match!
        const structuredOrderItems = items.map(item => ({
            product_id: item.product_id,
            quantity: parseInt(item.quantity),
            price_at_sale: parseFloat(item.price_at_sale || 0.00)
        }));

        const newOrder = new Order({
            sold_by: sold_by,
            total_price: parseFloat(total_price),
            items: structuredOrderItems // 💡 Note: Change to 'order_items: structuredOrderItems' if required by your schema
        });

        const savedOrder = await newOrder.save();
        res.status(201).json(savedOrder);

    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// @route   GET /api/orders
// @desc    Get complete purchase histories log data sequence
router.get('/', async (req, res) => {
    try {
        // Deep populate paths to unpack cashier username profiles and full product names automatically
        // This is perfectly parsed by your updated Dart order_item.dart .fromJson handler!
        const orderHistory = await Order.find()
            .populate('sold_by', 'username')
            .populate('items.product_id', 'title'); // 💡 Change to 'order_items.product_id' if your schema uses order_items

        res.json(orderHistory);
    } catch (err) {
        res.status(500).json({ message: 'Error retrieving system order histories' });
    }
});

module.exports = router;