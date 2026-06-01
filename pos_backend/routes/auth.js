const express = require('express');
const router = express.Router();
const User = require('../models/User');

// @route   POST /api/auth/login
// @desc    Authenticate user (Admin/Sale) & return profile details
router.post('/login', async (req, res) => {
    const { username, password } = req.body;

    try {
        // Validate presence of credentials
        if (!username || !password) {
            return res.status(400).json({ message: 'Please provide username and password' });
        }

        // Find user by username
        const user = await User.findOne({ username });
        if (!user) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Validate password (plain text check for simplicity, hash in real production code)
        if (user.password !== password) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Return user fields expected by your Dart User.fromJson factory constructor
        res.json({
            id: user.id,
            username: user.username,
            role: user.role
        });

    } catch (err) {
        console.error(err.message);
        res.status(500).json({ message: 'Server error during login processing' });
    }
});

module.exports = router;