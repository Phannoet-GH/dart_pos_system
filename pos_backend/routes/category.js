// Example Node.js Backend Route handler (e.g., inside your server.js or routes/categoryRoutes.js)
const express = require('express');
const router = express.Router();
const Category = require('../models/Category'); // Path to your Mongoose Category schema

router.get('/category', async (req, res) => {
    try {
        const categories = await Category.find();
        // 🎯 IMPORTANT: Ensure the array returns records with fields matching '_id' and 'name'
        res.status(200).json(categories);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;