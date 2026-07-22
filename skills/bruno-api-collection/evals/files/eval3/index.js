const express = require('express');
const app = express();
app.use(express.json());

// Simple auth middleware using an API key from the environment
function requireApiKey(req, res, next) {
  if (req.header('x-api-key') !== process.env.ORDERS_API_KEY) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  next();
}

// Public
app.get('/health', (req, res) => res.json({ status: 'ok' }));

// Orders resource (protected)
app.get('/api/orders', requireApiKey, (req, res) => res.json({ orders: [] }));
app.post('/api/orders', requireApiKey, (req, res) => {
  const { customer, items } = req.body;
  res.status(201).json({ id: 'ord_123', customer, items });
});
app.get('/api/orders/:id', requireApiKey, (req, res) => res.json({ id: req.params.id }));

// Outbound: this service charges cards via Stripe
async function chargeCard(amount, token) {
  return fetch('https://api.stripe.com/v1/charges', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.STRIPE_SECRET_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({ amount, currency: 'eur', source: token }),
  });
}

app.listen(3000);
