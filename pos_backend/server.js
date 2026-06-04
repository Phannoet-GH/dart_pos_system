// server.js updates
const express = require('express');
const connectDB = require('./config/db.js');

const app = express();
const PORT = 3000;

// Middleware
app.use(express.json());

// Establish Database connection
connectDB();

// Mount API Route Middleware Handlers
app.use('/api/auth', require('./routes/auth.js'));
app.use('/api', require('./routes/category.js'));
app.use('/api/product', require('./routes/product.js'));
app.use('/api/order', require('./routes/order.js'));

app.get('/', (req, res) => {
    res.send('POS Backend Server running with API routes mounted!');
});

app.listen(PORT, () => {
    console.log(`=== Server listening on HTTP port: http://localhost:${PORT} ===`);
});