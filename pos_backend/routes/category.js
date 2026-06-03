const express = require('express');
const router = express.Router();
const Category = require('../models/Category');
// GET /api/categories
router.get('/', async (req, res) => {
    try {
        const categories = await Category.find({}, 'name');
        res.json(categories);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});