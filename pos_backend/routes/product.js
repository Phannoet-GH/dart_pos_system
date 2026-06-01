const express = require('express');
const router = express.Router();
const Product = require('../models/Product');

// @route   GET /api/products
// @desc    Get all products (Used by both Admin & Sale)
router.get('/', async (req, res) => {
    try {
        const products = await Product.find();
        res.json(products);
    } catch (err) {
        res.status(500).json({ message: 'Error retrieving products collection' });
    }
});

// @route   GET /api/products/:id
// @desc    View single product details
router.get('/:id', async (req, res) => {
    try {
        const product = await Product.findById(req.params.id);
        if (!product) return res.status(404).json({ message: 'Product not found' });
        res.json(product);
    } catch (err) {
        res.status(500).json({ message: 'Invalid product ID format' });
    }
});

// @route   POST /api/products
// @desc    Add new product (Admin Only action on frontend)
router.post('/', async (req, res) => {
    const { title, price, stock_quantity, category_id } = req.body;
    try {
        const newProduct = new Product({ title, price, stock_quantity, category_id });
        const savedProduct = await newProduct.save();
        res.status(201).json(savedProduct);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// @route   PUT /api/products/:id
// @desc    Update product details / Manage stock quantity
router.put('/:id', async (req, res) => {
    try {
        const updatedProduct = await Product.findByIdAndUpdate(
            req.params.id,
            { $set: req.body },
            { new: true, runValidators: true }
        );
        if (!updatedProduct) return res.status(404).json({ message: 'Product not found' });
        res.json(updatedProduct);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// @route   DELETE /api/products/:id
// @desc    Delete product from collection
router.delete('/:id', async (req, res) => {
    try {
        const product = await Product.findByIdAndDelete(req.params.id);
        if (!product) return res.status(404).json({ message: 'Product not found' });
        res.json({ message: 'Product successfully removed' });
    } catch (err) {
        res.status(500).json({ message: 'Error deleting targeted product' });
    }
});

module.exports = router;